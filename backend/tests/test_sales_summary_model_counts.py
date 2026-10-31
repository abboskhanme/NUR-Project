"""Sotuv summary — model bo'yicha dona soni (GET /orders/summary → model_counts).

  - faqat yetkazilmagan (Navbatda/Tayyor) buyurtmalar sanaladi
  - yetkazilgan va rad etilgan buyurtma kirmaydi
  - qo'shimcha mahsulotlar hisobga olinmaydi
  - o'ng/chap yo'nalish alohida sanaladi

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db
from tests.test_queue_stage import _auth, _user

pytestmark = requires_db

API = "/api/v1/orders"
# Boshqa testlar bilan to'qnashmasligi uchun alohida davr
DAY = date(2031, 3, 15)


def _session(db_engine):
    return async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)


async def _seed(db_engine):
    from app.models.customer import Customer
    from app.models.order import Order, OrderItem
    from app.models.product import Product

    tag = uuid.uuid4().hex[:4].upper()
    async with _session(db_engine)() as db:
        big = Product(product_type="main", model=f"ULTRA-{tag}", kvm=300, status="active")
        small = Product(product_type="main", model=f"OPTIMA-{tag}", kvm=150, status="active")
        extra = Product(product_type="additional", name=f"Turba-{tag}", status="active")
        customer = Customer(full_name="Model test", phone=f"+9989{uuid.uuid4().int % 10**8:08d}")
        db.add_all([big, small, extra, customer])
        await db.flush()

        def order(status: str) -> Order:
            o = Order(code=f"2031-M{uuid.uuid4().hex[:6]}", customer_id=customer.id,
                      order_date=DAY, status=status,
                      delivered_at=DAY if status == "delivered" else None)
            db.add(o)
            return o

        o_new, o_ready = order("new"), order("ready")
        o_done, o_rej = order("delivered"), order("rejected")
        await db.flush()
        db.add_all([
            OrderItem(order_id=o_new.id, product_id=big.id, quantity=2,
                      bunker_direction="right", total_uzs=Decimal(1)),
            OrderItem(order_id=o_new.id, product_id=extra.id, quantity=5, total_uzs=Decimal(1)),
            OrderItem(order_id=o_ready.id, product_id=big.id, quantity=1,
                      bunker_direction="left", total_uzs=Decimal(1)),
            OrderItem(order_id=o_ready.id, product_id=small.id, quantity=1, total_uzs=Decimal(1)),
            OrderItem(order_id=o_done.id, product_id=big.id, quantity=7,
                      bunker_direction="left", total_uzs=Decimal(1)),
            OrderItem(order_id=o_done.id, product_id=small.id, quantity=3, total_uzs=Decimal(1)),
            OrderItem(order_id=o_rej.id, product_id=small.id, quantity=4, total_uzs=Decimal(1)),
        ])
        await db.commit()
        return big.display_name, small.display_name, extra.display_name


async def test_model_counts(client, db_engine):
    big, small, extra = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["orders:read"]))

    r = await c.get(f"{API}/summary", params={"date_from": DAY.isoformat(), "date_to": DAY.isoformat()})
    assert r.status_code == 200, r.text
    rows = {m["name"]: m for m in r.json()["model_counts"]}

    assert extra not in rows
    # Yetkazilgan (7 + 3) va rad etilgan (4) dona kirmaydi
    assert rows[big] == {"name": big, "count": 3, "right": 2, "left": 1}
    assert rows[small] == {"name": small, "count": 1, "right": 0, "left": 0}
    # Ko'pdan kamga
    names = [m["name"] for m in r.json()["model_counts"]]
    assert names.index(big) < names.index(small)
