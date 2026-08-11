"""Ta'minot: ichki va tashqi bo'limlar to'liq alohida ishlashini tekshiradi.

Asosiy qoida — bir xil nomli material ikkala bo'limga kiritilsa ham ular IKKI
alohida mahsulot bo'ladi: qoldiq ham, qarz ham, hisobotlar ham hech qachon
aralashmaydi. Ruxsat ham har bo'lim uchun alohida (`supply_ichki:*` /
`supply_tashqi:*`).

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

NAME = "Profil truba 40x40"  # ikkala bo'limda ham bir xil nom


async def _make_user(db_engine, permissions: list[str]):
    """Berilgan ruxsatlarga ega foydalanuvchi yaratadi."""
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}", permissions={"permissions": permissions})
        db.add(role)
        await db.flush()
        user = User(
            phone=f"+9989{uuid.uuid4().int % 10**8:08d}",
            password_hash="x", full_name="Test", is_active=True, token_version=0,
        )
        user.roles = [role]
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user


def _auth(client, user):
    """Auth dependency'ni berilgan foydalanuvchiga almashtiradi."""
    from app.core.dependencies import get_current_user
    from app.main import app

    async def _override():
        return user

    app.dependency_overrides[get_current_user] = _override
    return client


API = "/api/v1/taminot"


async def _supplier(c, scope, name="Umumiy yetkazib beruvchi"):
    """Har bo'lim uchun alohida yetkazib beruvchi (nomi bir xil bo'lsa ham)."""
    r = await c.post(f"{API}/suppliers", json={"scope": scope, "name": name})
    assert r.status_code == 201, r.text
    return r.json()


async def _supplier_balance(c, supplier_id, scope, currency="UZS"):
    rows = (await c.get(f"{API}/suppliers", params={"scope": scope})).json()
    sp = next(s for s in rows if s["id"] == supplier_id)
    return next((t["balance"] for t in sp["totals"] if t["currency"] == currency), 0)


async def test_same_name_in_both_scopes_stays_separate(client, db_engine):
    """Bir xil nom ikki bo'limda — ikki alohida mahsulot, qoldiqlar aralashmaydi."""
    admin = await _make_user(db_engine, ["supply_ichki:*", "supply_tashqi:*"])
    c = _auth(client, admin)

    ids, sups = {}, {}
    for scope in ("ichki", "tashqi"):
        sups[scope] = await _supplier(c, scope)
        r = await c.post(f"{API}/products", json={
            "scope": scope, "supplier_id": sups[scope]["id"], "name": NAME,
            "unit": "metr", "unit_price": 1000, "currency": "UZS", "min_qty": 10,
        })
        assert r.status_code == 201, r.text
        ids[scope] = r.json()["id"]

    # Ikki alohida yozuv
    assert ids["ichki"] != ids["tashqi"]

    # Ichkiga 100 kirim + 90 sarf → qoldiq 10; tashqiga 5 kirim → qoldiq 5
    await c.post(f"{API}/products/{ids['ichki']}/purchase", json={"qty": 100, "unit_price": 1000})
    await c.post(f"{API}/products/{ids['ichki']}/consume", json={"qty": 90})
    await c.post(f"{API}/products/{ids['tashqi']}/purchase", json={"qty": 5, "unit_price": 1000})

    ichki = (await c.get(f"{API}/products", params={"scope": "ichki"})).json()
    tashqi = (await c.get(f"{API}/products", params={"scope": "tashqi"})).json()

    # Har bo'limda faqat o'ziniki ko'rinadi
    assert [p["id"] for p in ichki] == [ids["ichki"]]
    assert [p["id"] for p in tashqi] == [ids["tashqi"]]

    assert ichki[0]["stock"] == 10 and ichki[0]["in_qty"] == 100 and ichki[0]["out_qty"] == 90
    assert tashqi[0]["stock"] == 5 and tashqi[0]["out_qty"] == 0

    # Qarz ham alohida (yetkazib beruvchi darajasida): ichki 100 000, tashqi 5 000
    assert await _supplier_balance(c, sups["ichki"]["id"], "ichki") == 100000
    assert await _supplier_balance(c, sups["tashqi"]["id"], "tashqi") == 5000


async def test_summary_and_log_never_mix_scopes(client, db_engine):
    """KPI hisobi va harakatlar jurnali ham faqat o'z bo'limini ko'rsatadi."""
    admin = await _make_user(db_engine, ["supply_ichki:*", "supply_tashqi:*"])
    c = _auth(client, admin)

    sup_ich = await _supplier(c, "ichki")
    sup_tash = await _supplier(c, "tashqi")
    ich = (await c.post(f"{API}/products", json={
        "scope": "ichki", "supplier_id": sup_ich["id"], "name": NAME,
        "unit": "metr", "unit_price": 1000, "min_qty": 50,
    })).json()
    tash = (await c.post(f"{API}/products", json={
        "scope": "tashqi", "supplier_id": sup_tash["id"], "name": NAME,
        "unit": "metr", "unit_price": 2000,
    })).json()
    await c.post(f"{API}/products/{ich['id']}/purchase", json={"qty": 10, "unit_price": 1000})
    await c.post(f"{API}/products/{tash['id']}/purchase", json={"qty": 3, "unit_price": 2000})

    s_ich = (await c.get(f"{API}/summary", params={"scope": "ichki"})).json()
    s_tash = (await c.get(f"{API}/summary", params={"scope": "tashqi"})).json()

    assert s_ich["product_count"] == 1 and s_tash["product_count"] == 1
    # Ichki: 10 metr qoldiq, chegara 50 → kam qoldi; qiymati 10 000
    assert s_ich["low_stock_count"] == 1 and s_ich["out_of_stock_count"] == 0
    assert s_ich["by_currency"][0]["stock_value"] == 10000
    # Tashqi: chegara yo'q → yetarli; qiymati 6 000 (ichkinikidan mustaqil)
    assert s_tash["low_stock_count"] == 0 and s_tash["ok_stock_count"] == 1
    assert s_tash["by_currency"][0]["stock_value"] == 6000

    log_ich = (await c.get(f"{API}/transactions", params={"scope": "ichki"})).json()
    log_tash = (await c.get(f"{API}/transactions", params={"scope": "tashqi"})).json()
    assert {t["product_id"] for t in log_ich} == {ich["id"]}
    assert {t["product_id"] for t in log_tash} == {tash["id"]}


async def test_scope_permissions_are_independent(client, db_engine):
    """Faqat ichkiga ruxsati bor xodim tashqi ma'lumotga umuman kira olmaydi."""
    admin = await _make_user(db_engine, ["supply_ichki:*", "supply_tashqi:*"])
    c = _auth(client, admin)
    sup = await _supplier(c, "tashqi")
    tash = (await c.post(f"{API}/products", json={
        "scope": "tashqi", "supplier_id": sup["id"], "name": NAME,
        "unit": "metr", "unit_price": 1000,
    })).json()

    ichki_only = await _make_user(db_engine, ["supply_ichki:read", "supply_ichki:write"])
    c = _auth(client, ichki_only)

    # Ro'yxat/KPI/jurnal — tashqi bo'yicha 403
    assert (await c.get(f"{API}/products", params={"scope": "tashqi"})).status_code == 403
    assert (await c.get(f"{API}/summary", params={"scope": "tashqi"})).status_code == 403
    assert (await c.get(f"{API}/transactions", params={"scope": "tashqi"})).status_code == 403

    # ID orqali ham tegib bo'lmaydi — ruxsat mahsulotning o'z scope'idan olinadi
    assert (await c.get(f"{API}/products/{tash['id']}/transactions")).status_code == 403
    assert (await c.post(f"{API}/products/{tash['id']}/purchase",
                         json={"qty": 1})).status_code == 403
    assert (await c.post(f"{API}/products/{tash['id']}/consume",
                         json={"qty": 1})).status_code == 403
    assert (await c.post(f"{API}/products/{tash['id']}/stock",
                         json={"qty": 1})).status_code == 403
    assert (await c.patch(f"{API}/products/{tash['id']}",
                          json={"name": "o'zgardi"})).status_code == 403
    assert (await c.delete(f"{API}/products/{tash['id']}")).status_code == 403


async def test_scope_cannot_be_changed_or_faked(client, db_engine):
    """Mahsulot bo'limi yaratilgandan keyin o'zgarmaydi; noto'g'ri scope rad etiladi."""
    admin = await _make_user(db_engine, ["supply_ichki:*", "supply_tashqi:*"])
    c = _auth(client, admin)
    sup_ich = await _supplier(c, "ichki")
    sup_tash = await _supplier(c, "tashqi")
    p = (await c.post(f"{API}/products", json={
        "scope": "ichki", "supplier_id": sup_ich["id"], "name": NAME,
        "unit": "metr", "unit_price": 1000,
    })).json()

    # PATCH orqali scope yuborilsa — e'tiborsiz qoldiriladi (sxemada bunday maydon yo'q)
    r = await c.patch(f"{API}/products/{p['id']}", json={"scope": "tashqi", "name": "Yangi nom"})
    assert r.status_code == 200
    assert r.json()["scope"] == "ichki"
    assert (await c.get(f"{API}/products", params={"scope": "tashqi"})).json() == []

    # Boshqa bo'limning yetkazib beruvchisiga ko'chirib bo'lmaydi
    r = await c.patch(f"{API}/products/{p['id']}", json={"supplier_id": sup_tash["id"]})
    assert r.status_code == 422

    # Mavjud bo'lmagan bo'lim — 422
    assert (await c.get(f"{API}/products", params={"scope": "boshqa"})).status_code == 422
    assert (await c.post(f"{API}/products", json={
        "scope": "boshqa", "supplier_id": sup_ich["id"], "name": "X",
    })).status_code == 422
    assert (await c.get(f"{API}/suppliers", params={"scope": "boshqa"})).status_code == 422
