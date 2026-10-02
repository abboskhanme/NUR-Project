"""Yopilgan buyurtmani «Navbatda»ga qaytarish — ruxsat va yon ta'sirlar.

Adashib «Yetkazildi»/«Rad etildi» qilingan buyurtmani tuzatish uchun
POST /orders/{id}/status {"status": "new"} faqat `system:order_override` bilan:
  - oddiy `orders:write` xodimi qaytara OLMAYDI (403)
  - maxsus ruxsat egasi va super-admin qaytara OLADI (delivered_at tozalanadi)
  - ID raqami boshqa aktiv buyurtmada band bo'lsa — 400
  - rad etilganda bo'shagan ombor birligi qayta band qilinadi

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/orders"


def _session(db_engine):
    return async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)


async def _user(db_engine, permissions: list[str], *, superadmin: bool = False):
    from app.models.user import Role, User

    async with _session(db_engine)() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}", permissions={"permissions": permissions})
        db.add(role)
        await db.flush()
        user = User(phone=f"+9989{uuid.uuid4().int % 10**8:08d}", password_hash="x",
                    full_name="Test", is_active=True, token_version=0,
                    is_superadmin=superadmin)
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


async def _order(db_engine, *, status: str = "delivered", unit_uid: str | None = None):
    from app.models.customer import Customer
    from app.models.order import Order

    async with _session(db_engine)() as db:
        customer = Customer(full_name="Nabijon", phone=f"+9989{uuid.uuid4().int % 10**8:08d}")
        db.add(customer)
        await db.flush()
        order = Order(
            code=f"2026-T{uuid.uuid4().hex[:6]}", customer_id=customer.id,
            order_date=date(2026, 9, 1), status=status, unit_uid=unit_uid,
            delivered_at=date(2026, 9, 30) if status == "delivered" else None,
        )
        db.add(order)
        await db.commit()
        await db.refresh(order)
        return order


async def _unit(db_engine, uid: str, *, status: str = "available"):
    from app.models.product import Inventory, Product

    async with _session(db_engine)() as db:
        product = Product(product_type="warehouse", model=f"M-{uuid.uuid4().hex[:4]}")
        db.add(product)
        await db.flush()
        inv = Inventory(product_id=product.id, unique_id=uid, status=status,
                        added_date=date(2026, 8, 1))
        db.add(inv)
        await db.commit()
        await db.refresh(inv)
        return inv


# --------------------------------------------------------------------------- #
# Ruxsatsiz — qaytara olmaydi
# --------------------------------------------------------------------------- #
async def test_plain_staff_cannot_revert_delivered(client, db_engine):
    order = await _order(db_engine, status="delivered")
    c = _auth(client, await _user(db_engine, ["orders:read", "orders:write"]))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "new"})
    assert r.status_code == 403, r.text

    got = await c.get(f"{API}/{order.id}")
    assert got.json()["status"] == "delivered"


async def test_wildcard_alone_is_not_enough(client, db_engine):
    """Oddiy "*" wildcard maxsus ruxsatni BERMAYDI (tizim qoidasi)."""
    order = await _order(db_engine, status="delivered")
    c = _auth(client, await _user(db_engine, ["*"]))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "new"})
    assert r.status_code == 403, r.text


async def test_override_cannot_jump_closed_to_other_status(client, db_engine):
    """Qaytarish faqat «new» ga — delivered -> ready kabi o'tishlar yopiqligicha."""
    order = await _order(db_engine, status="delivered")
    c = _auth(client, await _user(db_engine, ["orders:write", "system:order_override"]))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "ready"})
    assert r.status_code == 400, r.text


# --------------------------------------------------------------------------- #
# Ruxsat bilan — qaytaradi
# --------------------------------------------------------------------------- #
async def test_special_permission_reverts_delivered(client, db_engine):
    order = await _order(db_engine, status="delivered")
    c = _auth(client, await _user(db_engine, ["orders:write", "system:order_override"]))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "new", "note": "adashib bosildi"})
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["status"] == "new"
    assert body["delivered_at"] is None, "qaytarilganda yetkazilgan sana tozalanishi kerak"
    assert "[status revert] delivered -> new: adashib bosildi" in body["note"]


async def test_superadmin_reverts_rejected(client, db_engine):
    order = await _order(db_engine, status="rejected")
    c = _auth(client, await _user(db_engine, [], superadmin=True))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "new"})
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "new"


# --------------------------------------------------------------------------- #
# ID raqami (ombor birligi)
# --------------------------------------------------------------------------- #
async def test_revert_rereserves_freed_unit(client, db_engine):
    from app.models.product import Inventory

    inv = await _unit(db_engine, "K-100", status="available")
    order = await _order(db_engine, status="rejected", unit_uid="K-100")
    c = _auth(client, await _user(db_engine, [], superadmin=True))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "new"})
    assert r.status_code == 200, r.text
    assert r.json()["unit_uid"] == "K-100"

    async with _session(db_engine)() as db:
        got = (await db.execute(select(Inventory).where(Inventory.id == inv.id))).scalar_one()
        assert got.status == "reserved"


async def test_revert_keeps_snapshot_when_unit_deleted(client, db_engine):
    """Yetkazilganda ombor birligi o'chgan — ID snapshot qoladi, xato bermaydi."""
    order = await _order(db_engine, status="delivered", unit_uid="K-200")
    c = _auth(client, await _user(db_engine, [], superadmin=True))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "new"})
    assert r.status_code == 200, r.text
    assert r.json()["unit_uid"] == "K-200"


async def test_revert_blocked_when_uid_taken_by_active_order(client, db_engine):
    await _order(db_engine, status="new", unit_uid="K-300")
    order = await _order(db_engine, status="delivered", unit_uid="K-300")
    c = _auth(client, await _user(db_engine, [], superadmin=True))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "new"})
    assert r.status_code == 400, r.text
    assert "band" in r.json()["detail"]


# --------------------------------------------------------------------------- #
# Oddiy oqim — o'zgarishsiz
# --------------------------------------------------------------------------- #
async def test_normal_forward_transition_needs_no_special(client, db_engine):
    order = await _order(db_engine, status="new")
    c = _auth(client, await _user(db_engine, ["orders:write"]))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "rejected"})
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "rejected"
