"""To'lov (zaklad) tahrirlash/o'chirish — integration testlar (Postgres kerak).

Yangi PATCH /orders/{id}/payments/{payment_id} oqimini qoplaydi:
  - oddiy zaklad summasini tahrirlash (so'm ekvivalenti qayta hisoblanadi),
  - eski bazadan import qilingan (__import_correction__) summani super-admin tahrirlashi,
  - jamidan oshib ketadigan summa rad etilishi (400),
  - import yozuvini override'siz foydalanuvchi tahrirlay/ o'chira olmasligi (403).

TEST_DATABASE_URL berilmagan bo'lsa avtomatik skip qilinadi.
"""
from datetime import date
from decimal import Decimal

import pytest

from tests.conftest import requires_db

pytestmark = requires_db

IMPORT_CORRECTION_NOTE = "__import_correction__"

ADMIN_PHONE = "+998900000001"
STAFF_PHONE = "+998900000002"
PASS = "Test@12345"


async def _seed(client):
    """Super-admin, oddiy xodim, mijoz, mahsulot va bitta buyurtma yaratadi.

    Buyurtma: jami 10 000 000 so'm. Ikki to'lov:
      - real zaklad: 3 000 000 so'm
      - import yozuvi (__import_correction__): 2 000 000 so'm
    => to'langan 5 000 000, qoldiq 5 000 000.
    """
    from app.core.security import hash_password
    from app.models.customer import Customer
    from app.models.order import Order, OrderItem, Payment
    from app.models.product import Product
    from app.models.user import Role, User

    async with client._session_factory() as db:
        admin = User(phone=ADMIN_PHONE, password_hash=hash_password(PASS),
                     full_name="Super Admin", is_active=True, is_superadmin=True)
        staff_role = Role(name="sotuvchi",
                          permissions={"permissions": ["orders:read", "orders:write", "orders:delete"]})
        staff = User(phone=STAFF_PHONE, password_hash=hash_password(PASS),
                     full_name="Sotuvchi", is_active=True, roles=[staff_role])
        customer = Customer(full_name="Mijoz", phone="+998901234567")
        product = Product(product_type="bunker", model="NUR-100", base_price_usd=Decimal("1000"))
        db.add_all([admin, staff, customer, product])
        await db.flush()

        order = Order(code="TEST-0001", customer_id=customer.id, order_date=date(2024, 1, 1),
                      status="new", exchange_rate=Decimal("12000"))
        db.add(order)
        await db.flush()

        item = OrderItem(order_id=order.id, product_id=product.id, quantity=1,
                         unit_price_usd=Decimal("833.33"), unit_price_uzs=Decimal("10000000"),
                         total_uzs=Decimal("10000000"))
        real_pay = Payment(order_id=order.id, date=date(2024, 1, 2), amount=Decimal("3000000"),
                           currency="UZS", amount_uzs_equiv=Decimal("3000000"), method="cash")
        corr_pay = Payment(order_id=order.id, date=date(2024, 1, 1), amount=Decimal("2000000"),
                           currency="UZS", amount_uzs_equiv=Decimal("2000000"),
                           note=IMPORT_CORRECTION_NOTE)
        db.add_all([item, real_pay, corr_pay])
        await db.commit()
        return {
            "order_id": str(order.id),
            "real_pay_id": str(real_pay.id),
            "corr_pay_id": str(corr_pay.id),
            "admin_id": str(admin.id),
            "staff_id": str(staff.id),
        }


def _auth(user_id):
    """Login endpoint'ini (rate-limit) chetlab, to'g'ridan-to'g'ri access token yasaymiz."""
    from app.core.security import create_access_token

    return {"Authorization": f"Bearer {create_access_token(user_id, version=0)}"}


async def test_edit_real_payment_recomputes_paid(client):
    ids = await _seed(client)
    h = _auth(ids["admin_id"])

    # Boshlang'ich holat: to'langan 5 000 000, qoldiq 5 000 000
    o = (await client.get(f"/api/v1/orders/{ids['order_id']}", headers=h)).json()
    assert Decimal(o["paid_uzs"]) == Decimal("5000000")
    assert Decimal(o["balance_uzs"]) == Decimal("5000000")

    # Real zakladni 3M -> 4M ga oshiramiz (UZS) — to'langan 6M bo'ladi
    r = await client.patch(f"/api/v1/orders/{ids['order_id']}/payments/{ids['real_pay_id']}",
                           json={"amount": 4000000, "currency": "UZS"}, headers=h)
    assert r.status_code == 200, r.text
    assert Decimal(r.json()["amount_uzs_equiv"]) == Decimal("4000000")

    o = (await client.get(f"/api/v1/orders/{ids['order_id']}", headers=h)).json()
    assert Decimal(o["paid_uzs"]) == Decimal("6000000")
    assert Decimal(o["balance_uzs"]) == Decimal("4000000")


async def test_superadmin_edits_imported_amount(client):
    ids = await _seed(client)
    h = _auth(ids["admin_id"])

    # Eski import summasini 2M -> 1M ga tuzatamiz
    r = await client.patch(f"/api/v1/orders/{ids['order_id']}/payments/{ids['corr_pay_id']}",
                           json={"amount": 1000000, "currency": "UZS"}, headers=h)
    assert r.status_code == 200, r.text
    # Maxsus belgi (note) saqlanadi
    assert r.json()["note"] == IMPORT_CORRECTION_NOTE

    o = (await client.get(f"/api/v1/orders/{ids['order_id']}", headers=h)).json()
    assert Decimal(o["paid_uzs"]) == Decimal("4000000")  # 3M real + 1M import


async def test_edit_exceeding_total_rejected(client):
    ids = await _seed(client)
    h = _auth(ids["admin_id"])

    # Real zakladni 20M ga oshirish — jami 10M dan oshadi (boshqa 2M import bilan) -> 400
    r = await client.patch(f"/api/v1/orders/{ids['order_id']}/payments/{ids['real_pay_id']}",
                           json={"amount": 20000000, "currency": "UZS"}, headers=h)
    assert r.status_code == 400, r.text


async def test_usd_amount_uses_exchange_rate(client):
    ids = await _seed(client)
    h = _auth(ids["admin_id"])

    # 100$ × 12000 = 1 200 000 so'm ekvivalent
    r = await client.patch(f"/api/v1/orders/{ids['order_id']}/payments/{ids['real_pay_id']}",
                           json={"amount": 100, "currency": "USD"}, headers=h)
    assert r.status_code == 200, r.text
    assert Decimal(r.json()["amount_uzs_equiv"]) == Decimal("1200000")


async def test_staff_cannot_edit_imported(client):
    ids = await _seed(client)
    h = _auth(ids["staff_id"])

    # Oddiy xodim (override yo'q) import yozuvini tahrirlay olmaydi
    r = await client.patch(f"/api/v1/orders/{ids['order_id']}/payments/{ids['corr_pay_id']}",
                           json={"amount": 1000000, "currency": "UZS"}, headers=h)
    assert r.status_code == 403, r.text

    # Lekin oddiy real zakladni tahrirlay oladi (orders:write)
    r2 = await client.patch(f"/api/v1/orders/{ids['order_id']}/payments/{ids['real_pay_id']}",
                            json={"amount": 3500000, "currency": "UZS"}, headers=h)
    assert r2.status_code == 200, r2.text


async def test_staff_cannot_delete_imported(client):
    ids = await _seed(client)
    h = _auth(ids["staff_id"])

    r = await client.delete(f"/api/v1/orders/{ids['order_id']}/payments/{ids['corr_pay_id']}",
                            headers=h)
    assert r.status_code == 403, r.text
