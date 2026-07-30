"""Tannarx (costing) — tarkib asosida tannarx va foyda hisobi.

Tekshiriladi:
  - materiallar narxi ichki ta'minotdan JONLI olinadi (ta'minotda narx o'zgarsa
    tannarx o'zi yangilanadi), qo'lda kiritilgan narx esa qat'iy qoladi
  - USD satrlar oxirgi kurs bo'yicha so'mga o'giriladi
  - ustama foizi, foyda va marja to'g'ri hisoblanadi
  - ruxsat: `costing` moduli bo'lmagan xodim ko'ra olmaydi
  - faqat ichki ta'minot materiallari qo'shiladi (tashqi rad etiladi)

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/costing"


async def _user(db_engine, permissions: list[str]):
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


async def _seed(db_engine, *, rate: Decimal = Decimal(12000)):
    """Mahsulot + ichki/tashqi material + valyuta kursi yaratadi."""
    from app.models.finance import ExchangeRate
    from app.models.product import Product
    from app.models.taminot import TaminotProduct

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        db.add(ExchangeRate(date=date.today(), usd_to_uzs=rate, source="manual"))
        product = Product(product_type="main", model="OPTIMA", kvm=200, year=2026,
                          base_price_usd=Decimal(1000), status="active")
        metal = TaminotProduct(scope="ichki", name="Metall list 2mm", unit="list",
                               unit_price=Decimal(200_000), currency="UZS")
        datchik = TaminotProduct(scope="ichki", name="Datchik", unit="dona",
                                 unit_price=Decimal(10), currency="USD")
        tashqi = TaminotProduct(scope="tashqi", name="Tashqi profil", unit="metr",
                                unit_price=Decimal(50_000), currency="UZS")
        db.add_all([product, metal, datchik, tashqi])
        await db.commit()
        for o in (product, metal, datchik, tashqi):
            await db.refresh(o)
        return product, metal, datchik, tashqi


async def test_cost_from_live_material_prices(client, db_engine):
    """Tannarx = materiallar (jonli narx) + xarajat + ustama; foyda/marja."""
    product, metal, datchik, _ = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["costing:*"]))

    r = await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 10,
        "target_price_usd": 1000,
        "items": [
            # 3 list × 200 000 = 600 000 so'm
            {"kind": "material", "material_id": str(metal.id), "qty": 3},
            # 2 dona × $10 = $20 → 240 000 so'm (kurs 12 000)
            {"kind": "material", "material_id": str(datchik.id), "qty": 2},
            # qo'lda kiritilgan xarajat: 1 × 160 000
            {"kind": "expense", "label": "Payvandlash ishi", "qty": 1,
             "unit_price": 160_000, "currency": "UZS"},
        ],
    })
    assert r.status_code == 200, r.text
    b = r.json()["breakdown"]

    assert b["materials_uzs"] == 840_000        # 600k + 240k
    assert b["expenses_uzs"] == 160_000
    assert b["overhead_uzs"] == 100_000         # (840k + 160k) × 10%
    assert b["cost_uzs"] == 1_100_000           # TANNARX
    assert b["price_uzs"] == 12_000_000         # $1000 × 12 000
    assert b["profit_uzs"] == 10_900_000
    assert round(b["margin_percent"], 1) == 90.8

    # Satrlar: narx materialdan jonli olingani belgilanadi
    items = r.json()["items"]
    live = [i for i in items if i["kind"] == "material"]
    assert all(i["price_from_material"] for i in live)


async def test_material_price_change_updates_cost(client, db_engine):
    """Ta'minotda narx o'zgarsa tannarx o'zi yangilanadi; qo'lda narx qotib qoladi."""
    from app.models.taminot import TaminotProduct
    from sqlalchemy import select

    product, metal, _, _ = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["costing:*"]))

    await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 0,
        "items": [
            {"kind": "material", "material_id": str(metal.id), "qty": 1},          # jonli
            {"kind": "material", "material_id": str(metal.id), "qty": 1,
             "unit_price": 200_000, "currency": "UZS"},                            # qo'lda
        ],
    })
    before = (await c.get(f"{API}/products/{product.id}")).json()["breakdown"]["cost_uzs"]
    assert before == 400_000

    # Ta'minotda narx ikki barobar oshdi
    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        m = (await db.execute(select(TaminotProduct).where(TaminotProduct.id == metal.id))).scalar_one()
        m.unit_price = Decimal(400_000)
        await db.commit()

    after = (await c.get(f"{API}/products/{product.id}")).json()["breakdown"]["cost_uzs"]
    # Jonli satr 200k → 400k ga oshdi, qo'lda kiritilgani 200k qoldi
    assert after == 600_000


async def test_only_ichki_materials_allowed(client, db_engine):
    """Tashqi ta'minot materialini tarkibga qo'shib bo'lmaydi."""
    product, _, _, tashqi = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["costing:*"]))

    r = await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 0,
        "items": [{"kind": "material", "material_id": str(tashqi.id), "qty": 1}],
    })
    assert r.status_code == 422
    assert "ichki" in r.json()["detail"].lower()

    # Materiallar ro'yxatida ham faqat ichki bo'ladi
    mats = (await c.get(f"{API}/materials")).json()
    assert all(m["name"] != "Tashqi profil" for m in mats)


async def test_permissions_read_write_delete(client, db_engine):
    """`costing` ruxsati yo'q xodim ko'rmaydi; read-only saqlay olmaydi."""
    product, metal, _, _ = await _seed(db_engine)

    # Butunlay begona modul ruxsati
    c = _auth(client, await _user(db_engine, ["orders:read"]))
    assert (await c.get(f"{API}/products")).status_code == 403
    assert (await c.get(f"{API}/products/{product.id}")).status_code == 403

    # Faqat o'qish — saqlash va o'chirish rad etiladi
    c = _auth(client, await _user(db_engine, ["costing:read"]))
    assert (await c.get(f"{API}/products")).status_code == 200
    body = {"overhead_percent": 0,
            "items": [{"kind": "material", "material_id": str(metal.id), "qty": 1}]}
    assert (await c.put(f"{API}/products/{product.id}", json=body)).status_code == 403
    assert (await c.delete(f"{API}/products/{product.id}")).status_code == 403

    # write bo'lsa saqlaydi
    c = _auth(client, await _user(db_engine, ["costing:read", "costing:write"]))
    assert (await c.put(f"{API}/products/{product.id}", json=body)).status_code == 200


async def test_summary_and_list(client, db_engine):
    """Ro'yxat va KPI: kalkulyatsiya kiritilgan/kiritilmagan, marja."""
    product, metal, _, _ = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["costing:*"]))

    rows = (await c.get(f"{API}/products", params={"product_type": "main"})).json()
    assert len(rows) == 1 and rows[0]["has_recipe"] is False
    assert rows[0]["display_name"] == "OPTIMA 2026 200 kvm"

    await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 0, "target_price_usd": 1000,
        "items": [{"kind": "material", "material_id": str(metal.id), "qty": 1}],
    })
    s = (await c.get(f"{API}/summary", params={"product_type": "main"})).json()
    assert s["usd_rate"] == 12000
    assert s["with_recipe"] == 1 and s["without_recipe"] == 0
    assert s["loss_count"] == 0
    assert s["avg_margin_percent"] is not None

    # Faqat kiritilmaganlar filtri
    assert (await c.get(f"{API}/products", params={"only_missing": True})).json() == []
