"""Navbat bosqichi (Kutilmoqda / Yig'ilmoqda / Tayyor) — POST /orders/{id}/queue-stage.

  - faqat navbatdagi faol buyurtma uchun (aks holda 404)
  - noma'lum qiymat — 400
  - `orders:write` kerak (faqat o'qish ruxsati — 403)
  - buyurtma statusiga ta'sir qilmaydi
  - navbatdan chiqarilganda / «Navbatda»ga qaytarilganda bosqich tozalanadi

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import date

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


async def _order(db_engine, *, status: str = "new", in_queue: bool = True,
                 queue_stage: str | None = None):
    from app.models.customer import Customer
    from app.models.order import Order

    async with _session(db_engine)() as db:
        customer = Customer(full_name="Nabijon", phone=f"+9989{uuid.uuid4().int % 10**8:08d}")
        db.add(customer)
        await db.flush()
        order = Order(
            code=f"2026-Q{uuid.uuid4().hex[:6]}", customer_id=customer.id,
            order_date=date(2026, 9, 1), status=status, in_queue=in_queue,
            queue_stage=queue_stage,
            delivered_at=date(2026, 9, 30) if status == "delivered" else None,
        )
        db.add(order)
        await db.commit()
        await db.refresh(order)
        return order


def _queue_row(rows: list[dict], order_id) -> dict:
    return next(r for r in rows if r["id"] == str(order_id))


# --------------------------------------------------------------------------- #
# Asosiy oqim
# --------------------------------------------------------------------------- #
async def test_set_stage_assembling_then_ready_then_clear(client, db_engine):
    order = await _order(db_engine)
    c = _auth(client, await _user(db_engine, ["orders:read", "orders:write"]))

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": "assembling"})
    assert r.status_code == 200, r.text
    assert r.json()["queue_stage"] == "assembling"

    q = await c.get(f"{API}/queue")
    assert _queue_row(q.json(), order.id)["queue_stage"] == "assembling"

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": "ready"})
    assert r.status_code == 200, r.text
    assert r.json()["queue_stage"] == "ready"

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": None})
    assert r.status_code == 200, r.text
    assert r.json()["queue_stage"] is None


async def test_empty_string_means_waiting(client, db_engine):
    order = await _order(db_engine, queue_stage="ready")
    c = _auth(client, await _user(db_engine, ["orders:write"]))

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": ""})
    assert r.status_code == 200, r.text
    assert r.json()["queue_stage"] is None


async def test_stage_does_not_change_order_status(client, db_engine):
    """«Tayyor» bosqichi — buyurtma statusi (sotuv/hisobot) emas."""
    order = await _order(db_engine)
    c = _auth(client, await _user(db_engine, ["orders:read", "orders:write"]))

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": "ready"})
    assert r.status_code == 200, r.text

    got = await c.get(f"{API}/{order.id}")
    assert got.json()["status"] == "new"
    assert got.json()["queue_stage"] == "ready"


# --------------------------------------------------------------------------- #
# Validatsiya
# --------------------------------------------------------------------------- #
async def test_unknown_stage_rejected(client, db_engine):
    order = await _order(db_engine)
    c = _auth(client, await _user(db_engine, ["orders:write"]))

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": "delivered"})
    assert r.status_code == 400, r.text


async def test_order_not_in_queue_is_404(client, db_engine):
    order = await _order(db_engine, in_queue=False)
    c = _auth(client, await _user(db_engine, ["orders:write"]))

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": "assembling"})
    assert r.status_code == 404, r.text


async def test_closed_order_is_404(client, db_engine):
    order = await _order(db_engine, status="delivered")
    c = _auth(client, await _user(db_engine, ["orders:write"]))

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": "ready"})
    assert r.status_code == 404, r.text


# --------------------------------------------------------------------------- #
# RBAC
# --------------------------------------------------------------------------- #
async def test_read_only_user_cannot_set_stage(client, db_engine):
    order = await _order(db_engine)
    c = _auth(client, await _user(db_engine, ["orders:read"]))

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": "ready"})
    assert r.status_code == 403, r.text


async def test_user_without_orders_module_cannot_set_stage(client, db_engine):
    order = await _order(db_engine)
    c = _auth(client, await _user(db_engine, ["finance:write"]))

    r = await c.post(f"{API}/{order.id}/queue-stage", json={"stage": "ready"})
    assert r.status_code == 403, r.text


# --------------------------------------------------------------------------- #
# Tozalanish
# --------------------------------------------------------------------------- #
async def test_removing_from_queue_clears_stage(client, db_engine):
    order = await _order(db_engine, queue_stage="ready")
    c = _auth(client, await _user(db_engine, ["orders:read", "orders:write"]))

    r = await c.post(f"{API}/{order.id}/from-queue")
    assert r.status_code == 200, r.text
    assert r.json()["queue_stage"] is None


async def test_revert_to_new_clears_stage(client, db_engine):
    order = await _order(db_engine, status="delivered", queue_stage="ready")
    c = _auth(client, await _user(db_engine, [], superadmin=True))

    r = await c.post(f"{API}/{order.id}/status", json={"status": "new"})
    assert r.status_code == 200, r.text
    assert r.json()["queue_stage"] is None
