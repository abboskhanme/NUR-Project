"""Ta'minot: qarz YETKAZIB BERUVCHI darajasida hisoblanadi.

Asosiy qoida — bitta joydan nechta mahsulot olinishidan qat'i nazar hisob-kitob
bitta: 15 xil mahsulot olib kelinsa ham qarz o'sha joyga nisbatan yagona
summa bo'ladi, to'lov ham bitta marta qilinadi.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/taminot"


async def _make_user(db_engine, permissions: list[str]):
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}", permissions={"permissions": permissions})
        db.add(role)
        await db.flush()
        user = User(phone=f"+9989{uuid.uuid4().int % 10**8:08d}", password_hash="x",
                    full_name="Test", is_active=True, token_version=0)
        user.roles = [role]
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user


def _auth(client, user):
    from app.core.dependencies import get_current_user
    from app.main import app

    async def _override():
        return user

    app.dependency_overrides[get_current_user] = _override
    return client


async def _admin(client, db_engine):
    return _auth(client, await _make_user(db_engine, ["supply_ichki:*", "supply_tashqi:*"]))


async def _supplier(c, scope="tashqi", name="Metall Servis"):
    r = await c.post(f"{API}/suppliers", json={"scope": scope, "name": name})
    assert r.status_code == 201, r.text
    return r.json()


async def _product(c, sp, name, price=1000, currency="UZS"):
    r = await c.post(f"{API}/products", json={
        "scope": sp["scope"], "supplier_id": sp["id"], "name": name,
        "unit": "dona", "unit_price": price, "currency": currency,
    })
    assert r.status_code == 201, r.text
    return r.json()


async def _fetch(c, supplier_id, scope="tashqi"):
    rows = (await c.get(f"{API}/suppliers", params={"scope": scope})).json()
    return next(s for s in rows if s["id"] == supplier_id)


def _cur(sp, currency="UZS"):
    return next(t for t in sp["totals"] if t["currency"] == currency)


async def test_many_products_one_debt(client, db_engine):
    """Bir joydan 3 xil mahsulot olinsa — qarz bitta umumiy summa bo'ladi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    a = await _product(c, sp, "Profil 40x40", 1000)
    b = await _product(c, sp, "List 2mm", 2000)
    d = await _product(c, sp, "Elektrod", 500)

    for p, qty in ((a, 10), (b, 5), (d, 4)):
        r = await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": qty})
        assert r.status_code == 201, r.text

    fresh = await _fetch(c, sp["id"])
    assert fresh["product_count"] == 3
    # 10*1000 + 5*2000 + 4*500 = 22 000 — bitta umumiy qarz
    assert _cur(fresh)["total_purchased"] == 22000
    assert _cur(fresh)["balance"] == 22000


async def test_single_payment_covers_whole_group(client, db_engine):
    """Bitta to'lov butun guruhning qarzini kamaytiradi (mahsulotlarga bo'linmaydi)."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    a = await _product(c, sp, "Profil", 1000)
    b = await _product(c, sp, "List", 2000)
    await c.post(f"{API}/products/{a['id']}/purchase", json={"qty": 10})   # 10 000
    await c.post(f"{API}/products/{b['id']}/purchase", json={"qty": 5})    # 10 000

    r = await c.post(f"{API}/suppliers/{sp['id']}/payment",
                     json={"amount": 15000, "currency": "UZS"})
    assert r.status_code == 201, r.text
    # To'lov mahsulotga biriktirilmaydi
    assert r.json()["product_id"] is None
    assert r.json()["supplier_id"] == sp["id"]

    fresh = await _fetch(c, sp["id"])
    assert _cur(fresh)["total_paid"] == 15000
    assert _cur(fresh)["balance"] == 5000

    # Mahsulotlarning ombor qoldig'iga to'lov ta'sir qilmaydi
    rows = (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()
    assert {p["name"]: p["stock"] for p in rows} == {"Profil": 10, "List": 5}


async def test_currencies_never_mix(client, db_engine):
    """Bir joyda so'm va dollar hisobi bo'lsa — ular alohida yuritiladi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    uzs = await _product(c, sp, "Profil", 1000, "UZS")
    usd = await _product(c, sp, "Nasos", 50, "USD")
    await c.post(f"{API}/products/{uzs['id']}/purchase", json={"qty": 10})  # 10 000 so'm
    await c.post(f"{API}/products/{usd['id']}/purchase", json={"qty": 2})   # 100 dollar

    # So'mga to'lov qilinsa dollar qarzi tegilmaydi
    await c.post(f"{API}/suppliers/{sp['id']}/payment",
                 json={"amount": 10000, "currency": "UZS"})

    fresh = await _fetch(c, sp["id"])
    assert _cur(fresh, "UZS")["balance"] == 0
    assert _cur(fresh, "USD")["balance"] == 100


async def test_purchase_document_adds_many_at_once(client, db_engine):
    """Kirim hujjati — bir yo'la bir necha mahsulot, summasi guruh qarziga."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    a = await _product(c, sp, "Profil", 1000)
    b = await _product(c, sp, "List", 2000)

    r = await c.post(f"{API}/suppliers/{sp['id']}/purchase", json={
        "items": [
            {"product_id": a["id"], "qty": 3},
            {"product_id": b["id"], "qty": 2, "unit_price": 2500},  # narx o'zgargan
        ],
        "payment_mode": "debt",
    })
    assert r.status_code == 201, r.text
    # 3*1000 + 2*2500 = 8 000
    assert _cur(r.json())["balance"] == 8000

    rows = (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()
    assert {p["name"]: p["stock"] for p in rows} == {"Profil": 3, "List": 2}


async def test_cash_purchase_document_leaves_no_debt(client, db_engine):
    """Naqd kirim hujjati — ombor to'ladi, qarz oshmaydi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    a = await _product(c, sp, "Profil", 1000)

    r = await c.post(f"{API}/suppliers/{sp['id']}/purchase", json={
        "items": [{"product_id": a["id"], "qty": 4}], "payment_mode": "cash",
    })
    assert r.status_code == 201
    tot = _cur(r.json())
    assert tot["total_purchased"] == 4000 and tot["total_paid"] == 4000
    assert tot["balance"] == 0


async def test_foreign_product_rejected_in_document(client, db_engine):
    """Kirim hujjatiga boshqa joyning mahsuloti qo'shilmaydi."""
    c = await _admin(client, db_engine)
    sp1 = await _supplier(c, name="Metall Servis")
    sp2 = await _supplier(c, name="Bozor")
    other = await _product(c, sp2, "Bolt", 100)

    r = await c.post(f"{API}/suppliers/{sp1['id']}/purchase", json={
        "items": [{"product_id": other["id"], "qty": 1}],
    })
    assert r.status_code == 422
    assert "boshqa yetkazib beruvchiga" in r.json()["detail"]


async def test_duplicate_name_rejected(client, db_engine):
    """Bir bo'limda bir xil nomli ikkita joy bo'lmaydi — qarz bo'linib ketmasin."""
    c = await _admin(client, db_engine)
    await _supplier(c, name="Metall Servis")
    r = await c.post(f"{API}/suppliers", json={"scope": "tashqi", "name": "metall servis"})
    assert r.status_code == 409
    # Boshqa bo'limda esa bemalol bo'ladi — ular butunlay alohida
    r = await c.post(f"{API}/suppliers", json={"scope": "ichki", "name": "Metall Servis"})
    assert r.status_code == 201


async def test_supplier_with_products_cannot_be_deleted(client, db_engine):
    """Mahsuloti bor joy o'chirilmaydi — qarz tarixi yo'qolmasligi kerak."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil")

    r = await c.delete(f"{API}/suppliers/{sp['id']}")
    assert r.status_code == 400

    # Mahsulot o'chirilgach — o'chsa bo'ladi
    assert (await c.delete(f"{API}/products/{p['id']}")).status_code == 204
    assert (await c.delete(f"{API}/suppliers/{sp['id']}")).status_code == 204


async def test_moving_product_moves_its_history(client, db_engine):
    """Mahsulot boshqa joyga ko'chirilsa — kirimlari ham o'sha joyning qarziga o'tadi."""
    c = await _admin(client, db_engine)
    old = await _supplier(c, name="Eski joy")
    new = await _supplier(c, name="Yangi joy")
    p = await _product(c, old, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 10})  # 10 000

    r = await c.patch(f"{API}/products/{p['id']}", json={"supplier_id": new["id"]})
    assert r.status_code == 200, r.text
    assert r.json()["supplier_id"] == new["id"]

    assert _cur(await _fetch(c, old["id"]))["balance"] == 0
    assert _cur(await _fetch(c, new["id"]))["balance"] == 10000


async def test_supplier_permissions_follow_scope(client, db_engine):
    """Faqat ichkiga ruxsati bor xodim tashqi guruhga umuman tegolmaydi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c, scope="tashqi")

    c = _auth(client, await _make_user(db_engine, ["supply_ichki:read", "supply_ichki:write"]))
    assert (await c.get(f"{API}/suppliers", params={"scope": "tashqi"})).status_code == 403
    assert (await c.get(f"{API}/suppliers/{sp['id']}")).status_code == 403
    assert (await c.post(f"{API}/suppliers/{sp['id']}/payment",
                         json={"amount": 1})).status_code == 403
    assert (await c.post(f"{API}/suppliers/{sp['id']}/purchase",
                         json={"items": []})).status_code == 403
    assert (await c.patch(f"{API}/suppliers/{sp['id']}",
                          json={"name": "X"})).status_code == 403
    assert (await c.delete(f"{API}/suppliers/{sp['id']}")).status_code == 403


async def test_debts_module_sees_read_only_view(client, db_engine):
    """«Bizning qarzlar» bo'limi ta'minot ruxsatisiz ham manzarani ko'radi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c, scope="tashqi", name="Metall Servis")
    p = await _product(c, sp, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 10})

    # Faqat `debts` ruxsati — ta'minot ruxsati yo'q
    c = _auth(client, await _make_user(db_engine, ["debts:read"]))
    r = await c.get("/api/v1/debts/taminot-suppliers")
    assert r.status_code == 200, r.text
    row = next(x for x in r.json() if x["supplier_id"] == sp["id"])
    assert row["scope"] == "tashqi" and row["product_count"] == 1
    assert next(t for t in row["totals"] if t["currency"] == "UZS")["balance"] == 10000

    # Ta'minot bo'limining o'ziga esa baribir kira olmaydi
    assert (await c.get(f"{API}/suppliers", params={"scope": "tashqi"})).status_code == 403


# ===========================================================================
# ARXIV — o'chirilgan harakatlar yo'qolmaydi
# ===========================================================================
async def test_deleted_tx_leaves_history_but_not_balance(client, db_engine):
    """O'chirilgan harakat hisobdan chiqadi, lekin tarixda arxiv bo'lib qoladi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 10})   # 10 000
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 3})    # 3 000

    txs = (await c.get(f"{API}/suppliers/{sp['id']}/transactions")).json()
    victim = next(t for t in txs if t["amount"] == 3000)

    assert (await c.delete(f"{API}/transactions/{victim['id']}")).status_code == 204

    # Summa to'g'ri ayirildi
    fresh = await _fetch(c, sp["id"])
    assert _cur(fresh)["total_purchased"] == 10000
    assert _cur(fresh)["balance"] == 10000
    # Ombor qoldig'i ham
    rows = (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()
    assert next(x for x in rows if x["id"] == p["id"])["stock"] == 10

    # Lekin yozuv tarixda qoldi — arxiv belgisi bilan
    txs = (await c.get(f"{API}/suppliers/{sp['id']}/transactions")).json()
    archived = next(t for t in txs if t["id"] == victim["id"])
    assert archived["deleted_at"] is not None

    # Ikkinchi marta o'chirib bo'lmaydi
    assert (await c.delete(f"{API}/transactions/{victim['id']}")).status_code == 400


async def test_archived_tx_can_be_restored(client, db_engine):
    """Arxivdagi yozuv tiklansa — summa yana hisobga qaytadi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 10})
    tx = (await c.get(f"{API}/suppliers/{sp['id']}/transactions")).json()[0]

    await c.delete(f"{API}/transactions/{tx['id']}")
    assert _cur(await _fetch(c, sp["id"]))["balance"] == 0

    r = await c.post(f"{API}/transactions/{tx['id']}/restore")
    assert r.status_code == 200, r.text
    assert r.json()["deleted_at"] is None
    assert _cur(await _fetch(c, sp["id"]))["balance"] == 10000
    # Arxivda bo'lmaganini qayta tiklab bo'lmaydi
    assert (await c.post(f"{API}/transactions/{tx['id']}/restore")).status_code == 400


async def test_deleting_product_with_history_archives_it(client, db_engine):
    """Harakati bor mahsulot o'chirilsa — u va yozuvlari arxivga o'tadi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    a = await _product(c, sp, "Profil", 1000)
    b = await _product(c, sp, "List", 2000)
    await c.post(f"{API}/products/{a['id']}/purchase", json={"qty": 10})  # 10 000
    await c.post(f"{API}/products/{b['id']}/purchase", json={"qty": 5})   # 10 000
    # Qoldiq bor mahsulot o'chirilmaydi — avval sarflanadi
    await c.post(f"{API}/products/{a['id']}/consume", json={"qty": 10})

    assert (await c.delete(f"{API}/products/{a['id']}")).status_code == 204

    # Ro'yxatdan chiqdi va qarzdan ayirildi
    rows = (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()
    assert [x["id"] for x in rows] == [b["id"]]
    assert _cur(await _fetch(c, sp["id"]))["balance"] == 10000

    # Lekin tarixda arxiv sifatida turibdi
    txs = (await c.get(f"{API}/suppliers/{sp['id']}/transactions")).json()
    assert any(t["product_id"] == a["id"] and t["deleted_at"] for t in txs)

    # Arxiv ro'yxatida ko'rinadi va tiklansa hammasi qaytadi
    arch = (await c.get(f"{API}/products",
                        params={"scope": "tashqi", "archived": True})).json()
    assert [x["id"] for x in arch] == [a["id"]]
    # Nechta yozuv saqlangani ko'rinib turadi (kirim + sarf)
    assert arch[0]["tx_count"] == 2

    r = await c.post(f"{API}/products/{a['id']}/restore")
    assert r.status_code == 200, r.text
    assert _cur(await _fetch(c, sp["id"]))["balance"] == 20000


async def test_product_without_history_is_deleted_outright(client, db_engine):
    """Harakati yo'q mahsulot oddiy o'chadi — saqlanadigan tarix yo'q."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil", 1000)

    assert (await c.delete(f"{API}/products/{p['id']}")).status_code == 204
    assert (await c.get(f"{API}/products",
                        params={"scope": "tashqi", "archived": True})).json() == []
    assert (await c.post(f"{API}/products/{p['id']}/purchase",
                         json={"qty": 1})).status_code == 404


async def test_archived_product_rejects_new_operations(client, db_engine):
    """Arxivdagi mahsulotga kirim ham, spiska ham qo'shib bo'lmaydi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 1})
    await c.post(f"{API}/products/{p['id']}/consume", json={"qty": 1})
    assert (await c.delete(f"{API}/products/{p['id']}")).status_code == 204

    assert (await c.post(f"{API}/products/{p['id']}/purchase",
                         json={"qty": 1})).status_code == 400
    r = await c.post(f"{API}/suppliers/{sp['id']}/purchase",
                     json={"items": [{"product_id": p["id"], "qty": 1}]})
    assert r.status_code == 422 and "arxivda" in r.json()["detail"]
    r = await c.post(f"{API}/lists", json={
        "scope": "tashqi", "supplier_id": sp["id"],
        "items": [{"product_id": p["id"], "qty": 1}],
    })
    assert r.status_code == 422 and "arxivda" in r.json()["detail"]


async def test_product_with_stock_cannot_be_deleted(client, db_engine):
    """Omborda qoldig'i bor mahsulot o'chirilmaydi — u jismonan turibdi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 10})

    r = await c.delete(f"{API}/products/{p['id']}")
    assert r.status_code == 400
    assert "qoldiq bor" in r.json()["detail"]

    # Sarflangach — o'chsa bo'ladi (arxivga o'tadi)
    await c.post(f"{API}/products/{p['id']}/consume", json={"qty": 10})
    assert (await c.delete(f"{API}/products/{p['id']}")).status_code == 204
    arch = (await c.get(f"{API}/products",
                        params={"scope": "tashqi", "archived": True})).json()
    assert [x["id"] for x in arch] == [p["id"]]


# ===========================================================================
# SARFLASH — ombor amali butun modulga to'g'ri ta'sir qiladimi
# ===========================================================================
async def test_consume_updates_every_view_consistently(client, db_engine):
    """Sarflash: qoldiq kamayadi, QARZ TEGILMAYDI, hamma ko'rinish yangilanadi.

    Ombor tabidan qilingan sarf ham xuddi shu endpointga boradi, shuning uchun
    bu test butun modul bo'ylab bog'lanishni tekshiradi: mahsulot ro'yxati,
    yetkazib beruvchi hisobi, umumiy KPI va harakatlar jurnali.
    """
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 10})  # 10 000 qarz

    r = await c.post(f"{API}/products/{p['id']}/consume", json={"qty": 4})
    assert r.status_code == 201, r.text

    # 1) Mahsulot ro'yxati — qoldiq kamaydi, sarf qayd etildi
    row = next(x for x in (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()
               if x["id"] == p["id"])
    assert row["stock"] == 6 and row["out_qty"] == 4
    assert row["stock_value"] == 6000          # 6 × 1000
    assert row["total_purchased"] == 10000      # sarf kirimga tegmaydi

    # 2) Yetkazib beruvchi — QARZ O'ZGARMAYDI, qoldiq qiymati esa kamayadi
    sup = await _fetch(c, sp["id"])
    assert _cur(sup)["balance"] == 10000
    assert _cur(sup)["stock_value"] == 6000

    # 3) Umumiy KPI (summary) ham shu raqamni ko'rsatadi
    summary = (await c.get(f"{API}/summary", params={"scope": "tashqi"})).json()
    assert summary["by_currency"][0]["stock_value"] == 6000
    assert summary["by_currency"][0]["total_balance"] == 10000

    # 4) Yetkazib beruvchi tarixi va bo'lim jurnalida ko'rinadi
    sup_txs = (await c.get(f"{API}/suppliers/{sp['id']}/transactions")).json()
    consume = next(t for t in sup_txs if t["kind"] == "consume")
    assert consume["qty"] == 4 and consume["amount"] == 0
    assert consume["product_name"] == "Profil"

    log = (await c.get(f"{API}/transactions", params={"scope": "tashqi"})).json()
    assert any(t["kind"] == "consume" and t["product_id"] == p["id"] for t in log)


async def test_consume_beyond_stock_is_rejected(client, db_engine):
    """Qoldiqdan ko'p sarflab bo'lmaydi — qoldiq manfiy bo'lib ketmaydi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 3})

    r = await c.post(f"{API}/products/{p['id']}/consume", json={"qty": 5})
    assert r.status_code == 422
    row = next(x for x in (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()
               if x["id"] == p["id"])
    assert row["stock"] == 3  # o'zgarmadi


async def test_archived_consume_returns_stock(client, db_engine):
    """Sarf yozuvi arxivga o'tsa — qoldiq joyiga qaytadi, qarz tegilmaydi."""
    c = await _admin(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp, "Profil", 1000)
    await c.post(f"{API}/products/{p['id']}/purchase", json={"qty": 10})
    await c.post(f"{API}/products/{p['id']}/consume", json={"qty": 4})

    txs = (await c.get(f"{API}/suppliers/{sp['id']}/transactions")).json()
    consume = next(t for t in txs if t["kind"] == "consume")
    assert (await c.delete(f"{API}/transactions/{consume['id']}")).status_code == 204

    row = next(x for x in (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()
               if x["id"] == p["id"])
    assert row["stock"] == 10 and row["out_qty"] == 0
    assert _cur(await _fetch(c, sp["id"]))["balance"] == 10000

    # Tiklansa yana kamayadi
    assert (await c.post(f"{API}/transactions/{consume['id']}/restore")).status_code == 200
    row = next(x for x in (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()
               if x["id"] == p["id"])
    assert row["stock"] == 6


async def test_consume_never_crosses_scopes(client, db_engine):
    """Ichki va tashqi ta'minot omborlari hech qachon aralashmaydi."""
    c = await _admin(client, db_engine)
    tash = await _supplier(c, scope="tashqi", name="Tashqi joy")
    ich = await _supplier(c, scope="ichki", name="Ichki joy")
    pt = await _product(c, tash, "Profil", 1000)
    pi = await _product(c, ich, "Profil", 1000)
    await c.post(f"{API}/products/{pt['id']}/purchase", json={"qty": 10})
    await c.post(f"{API}/products/{pi['id']}/purchase", json={"qty": 10})

    await c.post(f"{API}/products/{pt['id']}/consume", json={"qty": 7})

    t_row = (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()[0]
    i_row = (await c.get(f"{API}/products", params={"scope": "ichki"})).json()[0]
    assert t_row["stock"] == 3 and i_row["stock"] == 10
