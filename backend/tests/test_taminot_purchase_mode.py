"""Ta'minot: olib kelish turi — qarzga yoki naqd.

  - "debt" (sukut) — yetkazib beruvchining qarzi summa qadar oshadi
  - "cash"         — shu zahoti to'lov yoziladi, qarz qoldig'i o'zgarmaydi

Ikkala holatda ham mahsulotning ombor qoldig'i bir xil oshadi.

QARZ — MAHSULOTDA EMAS, YETKAZIB BERUVCHIDA: shuning uchun tekshiruvlar
`/suppliers` javobidagi valyuta kesimidagi qoldiq bo'yicha qilinadi.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/taminot"


async def _admin_client(client, db_engine):
    from app.core.dependencies import get_current_user
    from app.main import app
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}",
                    permissions={"permissions": ["supply_ichki:*", "supply_tashqi:*"]})
        db.add(role)
        await db.flush()
        user = User(phone=f"+9989{uuid.uuid4().int % 10**8:08d}", password_hash="x",
                    full_name="Test", is_active=True, token_version=0)
        user.roles = [role]
        db.add(user)
        await db.commit()
        await db.refresh(user)

    async def _override():
        return user

    app.dependency_overrides[get_current_user] = _override
    return client


async def _supplier(c, scope="ichki", name=None):
    r = await c.post(f"{API}/suppliers", json={
        "scope": scope, "name": name or f"Yetkazib beruvchi {uuid.uuid4().hex[:6]}",
    })
    assert r.status_code == 201, r.text
    return r.json()


async def _product(c, supplier, **kw):
    payload = {"scope": supplier["scope"], "supplier_id": supplier["id"],
               "name": "Profil 40x40", "unit": "metr",
               "unit_price": 1000, "currency": "UZS"}
    payload.update(kw)
    r = await c.post(f"{API}/products", json=payload)
    assert r.status_code == 201, r.text
    return r.json()


async def _get(c, pid, scope="ichki"):
    rows = (await c.get(f"{API}/products", params={"scope": scope})).json()
    return next(p for p in rows if p["id"] == pid)


async def _balance(c, supplier_id, currency="UZS", scope="ichki"):
    """Yetkazib beruvchining shu valyutadagi hisobi."""
    rows = (await c.get(f"{API}/suppliers", params={"scope": scope})).json()
    sp = next(s for s in rows if s["id"] == supplier_id)
    return next((t for t in sp["totals"] if t["currency"] == currency),
                {"total_purchased": 0, "total_paid": 0, "balance": 0})


async def test_debt_purchase_increases_supplier_balance(client, db_engine):
    """Qarzga olib kelish — yetkazib beruvchining qarzi va ombor qoldig'i oshadi."""
    c = await _admin_client(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp)

    r = await c.post(f"{API}/products/{p['id']}/purchase",
                     json={"qty": 10, "unit_price": 1000})
    assert r.status_code == 201

    fresh = await _get(c, p["id"])
    assert fresh["stock"] == 10
    assert fresh["total_purchased"] == 10000

    bal = await _balance(c, sp["id"])
    assert bal["total_purchased"] == 10000
    assert bal["total_paid"] == 0
    assert bal["balance"] == 10000


async def test_cash_purchase_leaves_no_debt(client, db_engine):
    """Naqd olib kelish — qoldiq oshadi, qarz qoldig'i 0 bo'lib qoladi."""
    c = await _admin_client(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp)

    r = await c.post(f"{API}/products/{p['id']}/purchase",
                     json={"qty": 10, "unit_price": 1000, "payment_mode": "cash"})
    assert r.status_code == 201

    fresh = await _get(c, p["id"])
    assert fresh["stock"] == 10           # ombor qoldig'i qarzga o'xshab oshadi

    bal = await _balance(c, sp["id"])
    assert bal["total_purchased"] == 10000
    assert bal["total_paid"] == 10000     # avtomatik to'lov
    assert bal["balance"] == 0            # qarz qolmaydi

    # Tarixda ikkita yozuv: olib kelish + naqd to'lov
    txs = (await c.get(f"{API}/products/{p['id']}/transactions")).json()
    kinds = sorted(t["kind"] for t in txs)
    assert kinds == ["payment", "purchase"]
    assert any("naqd" in (t["note"] or "").lower() for t in txs)


async def test_mixed_purchases_sum_correctly(client, db_engine):
    """Naqd va qarzga aralash olib kelinsa — faqat qarzgasi qarzda qoladi."""
    c = await _admin_client(client, db_engine)
    sp = await _supplier(c)
    p = await _product(c, sp)

    await c.post(f"{API}/products/{p['id']}/purchase",
                 json={"qty": 5, "unit_price": 1000, "payment_mode": "cash"})
    await c.post(f"{API}/products/{p['id']}/purchase",
                 json={"qty": 7, "unit_price": 1000, "payment_mode": "debt"})

    fresh = await _get(c, p["id"])
    assert fresh["stock"] == 12            # 5 + 7
    assert fresh["total_purchased"] == 12000

    bal = await _balance(c, sp["id"])
    assert bal["total_paid"] == 5000       # faqat naqd qismi
    assert bal["balance"] == 7000          # qarzga olingan qismi
