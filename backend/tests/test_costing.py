"""Tannarx (costing) — tarkib asosida tannarx va foyda hisobi.

Tekshiriladi:
  - materiallar narxi tannarx katalogidan JONLI olinadi (katalogda narx o'zgarsa
    tannarx o'zi yangilanadi), qo'lda kiritilgan narx esa qat'iy qoladi
  - USD satrlar oxirgi kurs bo'yicha so'mga o'giriladi
  - ustama foizi, foyda va marja to'g'ri hisoblanadi
  - ruxsat: `costing` moduli bo'lmagan xodim ko'ra olmaydi
  - summa bilan kiritish (entry_mode="sum") va katalog CRUD

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
    """Mahsulot + tannarx katalogidagi materiallar + valyuta kursi yaratadi."""
    from app.models.costing import CostingMaterial
    from app.models.finance import ExchangeRate
    from app.models.product import Product

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        db.add(ExchangeRate(date=date.today(), usd_to_uzs=rate, source="manual"))
        product = Product(product_type="main", model="OPTIMA", kvm=200, year=2026,
                          base_price_usd=Decimal(1000), status="active")
        metal = CostingMaterial(name="Metall list 2mm", unit="list",
                                unit_price=Decimal(200_000), currency="UZS")
        datchik = CostingMaterial(name="Datchik", unit="dona",
                                  unit_price=Decimal(10), currency="USD")
        # Birligi/narxi yo'q — summa bilan kiritish uchun ("50 ming so'mlik kraska")
        kraska = CostingMaterial(name="Kraska", unit=None, unit_price=Decimal(0),
                                 currency="UZS")
        db.add_all([product, metal, datchik, kraska])
        await db.commit()
        for o in (product, metal, datchik, kraska):
            await db.refresh(o)
        return product, metal, datchik, kraska


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
    """Katalogda narx o'zgarsa tannarx o'zi yangilanadi; qo'lda narx qotib qoladi."""
    from app.models.costing import CostingMaterial
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

    # Katalogda narx ikki barobar oshdi
    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        m = (await db.execute(select(CostingMaterial).where(CostingMaterial.id == metal.id))).scalar_one()
        m.unit_price = Decimal(400_000)
        await db.commit()

    after = (await c.get(f"{API}/products/{product.id}")).json()["breakdown"]["cost_uzs"]
    # Jonli satr 200k → 400k ga oshdi, qo'lda kiritilgani 200k qoldi
    assert after == 600_000


async def test_sum_mode_line(client, db_engine):
    """Summa bilan kiritish: «50 ming so'mlik kraska sepildi»."""
    product, metal, _, kraska = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["costing:*"]))

    r = await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 0,
        "items": [
            {"kind": "material", "material_id": str(metal.id), "entry_mode": "qty", "qty": 2},
            {"kind": "material", "material_id": str(kraska.id), "entry_mode": "sum",
             "amount": 50_000},
        ],
    })
    assert r.status_code == 200, r.text
    b = r.json()["breakdown"]
    # 2 × 200 000 + 50 000 (summa) = 450 000
    assert b["materials_uzs"] == 450_000
    assert b["cost_uzs"] == 450_000

    sum_line = next(i for i in r.json()["items"] if i["label"] == "Kraska")
    assert sum_line["entry_mode"] == "sum"
    assert sum_line["amount"] == 50_000
    assert sum_line["line_total"] == 50_000

    # Summa rejimida summa bo'sh bo'lsa — rad etiladi
    bad = await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 0,
        "items": [{"kind": "material", "material_id": str(kraska.id), "entry_mode": "sum"}],
    })
    assert bad.status_code == 422
    assert "summa" in bad.json()["detail"].lower()


async def test_material_catalog_crud(client, db_engine):
    """Katalog tannarx bo'limining o'zida boshqariladi (ta'minotdan mustaqil)."""
    product, metal, _, _ = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["costing:*"]))

    # Qo'shish
    r = await c.post(f"{API}/materials", json={
        "name": "Payvand simi", "unit": "kg", "unit_price": 35_000, "currency": "UZS",
    })
    assert r.status_code == 201, r.text
    new_id = r.json()["id"]

    # Bir xil nom — rad etiladi
    dup = await c.post(f"{API}/materials", json={"name": "payvand simi", "unit": "kg"})
    assert dup.status_code == 422 and "allaqachon" in dup.json()["detail"]

    # Tahrirlash: narx o'zgarsa kalkulyatsiya o'zi yangilanadi
    await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 0,
        "items": [{"kind": "material", "material_id": new_id, "qty": 2}],
    })
    assert (await c.get(f"{API}/products/{product.id}")).json()["breakdown"]["cost_uzs"] == 70_000
    upd = await c.patch(f"{API}/materials/{new_id}", json={
        "name": "Payvand simi", "unit": "kg", "unit_price": 50_000, "currency": "UZS",
    })
    assert upd.status_code == 200 and upd.json()["used_in"] == 1
    assert (await c.get(f"{API}/products/{product.id}")).json()["breakdown"]["cost_uzs"] == 100_000

    # Ishlatilgan materialni o'chirib bo'lmaydi (tarix buzilmasin)
    dele = await c.delete(f"{API}/materials/{new_id}")
    assert dele.status_code == 422 and "arxivlang" in dele.json()["detail"]

    # Birlik IXTIYORIY — ko'rsatilmasa bo'sh qoladi
    no_unit = await c.post(f"{API}/materials", json={"name": "Birligi yo'q", "unit_price": 1000})
    assert no_unit.status_code == 201 and no_unit.json()["unit"] is None

    # Ishlatilmagani o'chadi
    free = (await c.post(f"{API}/materials", json={"name": "Ishlatilmagan", "unit": "dona"})).json()
    assert (await c.delete(f"{API}/materials/{free['id']}")).status_code == 204


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

    rows = (await c.get(f"{API}/products")).json()
    assert len(rows) == 1 and rows[0]["has_recipe"] is False
    assert rows[0]["display_name"] == "OPTIMA 2026 200 kvm"

    await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 0, "target_price_usd": 1000,
        "items": [{"kind": "material", "material_id": str(metal.id), "qty": 1}],
    })
    s = (await c.get(f"{API}/summary")).json()
    assert s["usd_rate"] == 12000
    assert s["with_recipe"] == 1 and s["without_recipe"] == 0
    assert s["loss_count"] == 0
    assert s["avg_margin_percent"] is not None

    # Faqat kiritilmaganlar filtri
    assert (await c.get(f"{API}/products", params={"only_missing": True})).json() == []


async def test_matrix_view_and_bulk_save(client, db_engine):
    """Jadval (matritsa): ustunlar — materiallar, kataklar — miqdor.

    Eng muhimi: jadvalni saqlash FAQAT material satrlarini almashtiradi —
    qo'shimcha xarajatlar, ustama foizi va sotish narxi tegilmasligi kerak.
    """
    product, metal, datchik, _ = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["costing:*"]))

    # Avval mahsulot sahifasi orqali xarajat + ustama + narx kiritamiz
    await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 10,
        "target_price_usd": 1000,
        "note": "qo'lda kiritilgan izoh",
        "items": [
            {"kind": "material", "material_id": str(metal.id), "qty": 1},
            {"kind": "expense", "label": "Payvandlash", "qty": 1,
             "unit_price": 100_000, "currency": "UZS"},
        ],
    })

    # Jadval ko'rinishi: kataklar to'ldirilgan bo'lishi kerak
    m = (await c.get(f"{API}/matrix")).json()
    assert m["usd_rate"] == 12000
    assert {x["name"] for x in m["materials"]} == {"Metall list 2mm", "Datchik", "Kraska"}
    row = next(r for r in m["rows"] if r["product_id"] == str(product.id))
    assert row["display_name"] == "OPTIMA 2026 200 kvm"
    assert row["cells"] == {str(metal.id): 1.0}
    assert row["expense_count"] == 1
    assert row["overhead_percent"] == 10

    # Jadval orqali miqdorlarni o'zgartiramiz: metall 3 ta, datchik 2 ta
    r = await c.put(f"{API}/matrix", json={"rows": [{
        "product_id": str(product.id),
        "cells": [
            {"material_id": str(metal.id), "value": 3},
            {"material_id": str(datchik.id), "value": 2},
        ],
    }]})
    assert r.status_code == 200, r.text
    row = next(x for x in r.json()["rows"] if x["product_id"] == str(product.id))
    assert row["cells"] == {str(metal.id): 3.0, str(datchik.id): 2.0}
    # 3×200 000 + 2×$10×12 000 = 840 000
    assert row["materials_uzs"] == 840_000

    # Xarajat, ustama, narx va izoh SAQLANGAN bo'lishi kerak
    d = (await c.get(f"{API}/products/{product.id}")).json()
    assert d["overhead_percent"] == 10
    assert d["target_price_usd"] == 1000
    assert d["note"] == "qo'lda kiritilgan izoh"
    assert [i["label"] for i in d["items"] if i["kind"] == "expense"] == ["Payvandlash"]
    # Tannarx: 840k materiallar + 100k xarajat + 10% ustama = 1 034 000
    assert d["breakdown"]["cost_uzs"] == 1_034_000

    # Katakni bo'shatish (ro'yxatdan olib tashlash) — material satri o'chadi
    await c.put(f"{API}/matrix", json={"rows": [{
        "product_id": str(product.id),
        "cells": [{"material_id": str(metal.id), "value": 3}],
    }]})
    d = (await c.get(f"{API}/products/{product.id}")).json()
    assert [i["label"] for i in d["items"] if i["kind"] == "material"] == ["Metall list 2mm"]
    assert [i["label"] for i in d["items"] if i["kind"] == "expense"] == ["Payvandlash"]


async def test_matrix_preserves_sum_lines(client, db_engine):
    """Jadval faqat MIQDOR satrlarini almashtiradi — summa satrlari saqlanadi."""
    product, metal, _, kraska = await _seed(db_engine)

    c = _auth(client, await _user(db_engine, ["costing:*"]))
    # Mahsulot sahifasida summa satri kiritamiz
    await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 0,
        "items": [{"kind": "material", "material_id": str(kraska.id),
                   "entry_mode": "sum", "amount": 50_000}],
    })

    # Jadvalda summa satri KATAK sifatida ko'rinmaydi, faqat sanaladi
    m = (await c.get(f"{API}/matrix")).json()
    row = next(x for x in m["rows"] if x["product_id"] == str(product.id))
    assert row["cells"] == {} and row["sum_line_count"] == 1

    # Jadval orqali miqdor saqlaymiz — summa satri joyida qolishi kerak
    r = await c.put(f"{API}/matrix", json={"rows": [{
        "product_id": str(product.id),
        "cells": [{"material_id": str(metal.id), "value": 2}],
    }]})
    assert r.status_code == 200, r.text
    row = next(x for x in r.json()["rows"] if x["product_id"] == str(product.id))
    assert row["cells"] == {str(metal.id): 2.0}
    assert row["sum_line_count"] == 1
    assert row["materials_uzs"] == 450_000     # 2×200k (jadval) + 50k (summa satri)

    d = (await c.get(f"{API}/products/{product.id}")).json()
    labels = sorted(i["label"] for i in d["items"])
    assert labels == ["Kraska", "Metall list 2mm"]

    # Katalogda yo'q material — rad etiladi
    bad = await c.put(f"{API}/matrix", json={"rows": [{
        "product_id": str(product.id),
        "cells": [{"material_id": str(uuid.uuid4()), "value": 1}],
    }]})
    assert bad.status_code == 422

    c = _auth(client, await _user(db_engine, ["costing:read"]))
    assert (await c.get(f"{API}/matrix")).status_code == 200
    r = await c.put(f"{API}/matrix", json={"rows": [{
        "product_id": str(product.id),
        "cells": [{"material_id": str(metal.id), "value": 1}],
    }]})
    assert r.status_code == 403


async def _sell(db_engine, product_id, *, qty: int, total_uzs: int,
                order_date=None, status: str = "delivered"):
    """Buyurtma yaratadi (mijoz bilan) — foyda hisoboti uchun sotuv manbai."""
    from app.models.customer import Customer
    from app.models.order import Order, OrderItem

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        customer = Customer(full_name="Mijoz", phone=f"+9989{uuid.uuid4().int % 10**8:08d}")
        db.add(customer)
        await db.flush()
        order = Order(code=f"ORD-{uuid.uuid4().hex[:6]}", customer_id=customer.id,
                      order_date=order_date or date.today(), status=status)
        db.add(order)
        await db.flush()
        db.add(OrderItem(order_id=order.id, product_id=product_id, quantity=qty,
                         total_uzs=Decimal(total_uzs)))
        await db.commit()


async def test_profit_report(client, db_engine):
    """Foyda hisoboti: tushum − (sotilgan dona × tannarx) − xarajat = sof foyda."""
    from app.models.finance import FinanceTransaction
    from app.models.product import Product

    product, metal, datchik, _ = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["costing:*"]))

    # Tannarx = 1 100 000 (birinchi testdagi tarkib bilan bir xil)
    await c.put(f"{API}/products/{product.id}", json={
        "overhead_percent": 10,
        "target_price_usd": 1000,
        "items": [
            {"kind": "material", "material_id": str(metal.id), "qty": 3},
            {"kind": "material", "material_id": str(datchik.id), "qty": 2},
            {"kind": "expense", "label": "Payvandlash ishi", "qty": 1,
             "unit_price": 160_000, "currency": "UZS"},
        ],
    })

    # Kalkulyatsiyasi YO'Q ikkinchi mahsulot
    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        other = Product(product_type="main", model="BAZA", kvm=100, year=2026,
                        base_price_usd=Decimal(500), status="active")
        db.add(other)
        db.add(FinanceTransaction(date=date.today(), type="expense", amount=Decimal(3_000_000),
                                  currency="UZS", status="active"))
        # Bekor qilingan chiqim va USD chiqim — hisobga kirmasligi kerak
        db.add(FinanceTransaction(date=date.today(), type="expense", amount=Decimal(9_000_000),
                                  currency="UZS", status="void"))
        db.add(FinanceTransaction(date=date.today(), type="expense", amount=Decimal(500),
                                  currency="USD", status="active"))
        await db.commit()
        await db.refresh(other)

    await _sell(db_engine, product.id, qty=2, total_uzs=24_000_000)
    await _sell(db_engine, other.id, qty=1, total_uzs=6_000_000)
    # Rad etilgan buyurtma — hisobga kirmaydi
    await _sell(db_engine, product.id, qty=5, total_uzs=60_000_000, status="rejected")

    r = await c.get(f"{API}/profit-report", params={
        "date_from": str(date.today()), "date_to": str(date.today()), "granularity": "day",
    })
    assert r.status_code == 200, r.text
    d = r.json()

    assert d["units_sold"] == 3                      # 2 + 1 (rad etilgani emas)
    assert d["revenue_uzs"] == 30_000_000
    assert d["covered_revenue_uzs"] == 24_000_000    # faqat kalkulyatsiyalisi
    assert d["cogs_uzs"] == 2_200_000                # 2 × 1 100 000
    assert d["gross_profit_uzs"] == 21_800_000
    assert d["opex_uzs"] == 3_000_000                # void va USD chiqimlarsiz
    # Xarajat tarkibi ko'rinib turadi (moliyaga nima kiritilgani tekshirilsin)
    assert d["opex_count"] == 1
    assert d["opex_by_category"] == [
        {"category": "Boshqa", "amount_uzs": 3_000_000, "count": 1},
    ]
    assert d["net_profit_uzs"] == 18_800_000
    assert d["uncovered_count"] == 1 and d["uncovered_revenue_uzs"] == 6_000_000
    assert d["coverage_percent"] == 80.0

    # Tushum tarkibi: materiallar + xarajat + ustama = tannarx
    s = d["structure"]
    assert s["materials_uzs"] == 1_680_000 and s["expenses_uzs"] == 320_000
    assert s["overhead_uzs"] == 200_000
    assert s["profit_uzs"] == d["gross_profit_uzs"]

    # Mahsulotlar kesimi
    row = next(x for x in d["products"] if x["product_id"] == str(product.id))
    assert row["units"] == 2 and row["unit_cost_uzs"] == 1_100_000
    assert row["profit_uzs"] == 21_800_000
    missing = next(x for x in d["products"] if x["product_id"] == str(other.id))
    assert missing["has_recipe"] is False and missing["profit_uzs"] is None

    # Dinamika: bugungi nuqtada tushum va tannarx (kalkulyatsiyasizlarsiz)
    today_point = next(p for p in d["trend"] if p["date"] == str(date.today()))
    assert today_point["revenue_uzs"] == 24_000_000
    assert today_point["cogs_uzs"] == 2_200_000
    assert today_point["profit_uzs"] == 21_800_000

    # Ruxsat: costing moduli yo'q xodim ko'ra olmaydi
    c2 = _auth(client, await _user(db_engine, ["reports:read"]))
    assert (await c2.get(f"{API}/profit-report")).status_code == 403
