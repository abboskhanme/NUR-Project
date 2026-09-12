"""Yopilgan servis arizasini qayta ochish — ruxsat tekshiruvi.

Bajarilgan/bekor qilingan arizani «yangi»ga qaytarish hisobot raqamlarini
o'zgartiradi, shuning uchun u `system:service_reopen` maxsus ruxsatiga bog'langan:
  - oddiy `service:write` xodimi qaytara OLMAYDI (403)
  - maxsus ruxsat egasi va super-admin qaytara OLADI (closed_at ham tozalanadi)
  - arizani YOPISH (yangi → bajarildi) hammaga ochiq qoladi

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/service"


async def _user(db_engine, permissions: list[str], *, superadmin: bool = False):
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
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


async def _ticket(db_engine, *, status: str = "completed"):
    """Yopilgan ariza yaratadi (mijoz bilan)."""
    from datetime import datetime, timezone

    from app.models.customer import Customer
    from app.models.service import ServiceTicket

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        customer = Customer(full_name="Nabijon", phone=f"+9989{uuid.uuid4().int % 10**8:08d}")
        db.add(customer)
        await db.flush()
        closed = status in ("completed", "cancelled")
        ticket = ServiceTicket(
            code=f"SRV-TEST-{uuid.uuid4().hex[:6]}",
            customer_id=customer.id,
            problem="suv oqyapti",
            status=status,
            opened_at=datetime.now(timezone.utc),
            closed_at=datetime.now(timezone.utc) if closed else None,
        )
        db.add(ticket)
        await db.commit()
        await db.refresh(ticket)
        return ticket


# --------------------------------------------------------------------------- #
# Ruxsatsiz — qayta ocholmaydi
# --------------------------------------------------------------------------- #
async def test_plain_staff_cannot_reopen_closed_ticket(client, db_engine):
    ticket = await _ticket(db_engine, status="completed")
    user = await _user(db_engine, ["service:read", "service:write"])
    c = _auth(client, user)

    r = await c.patch(f"{API}/tickets/{ticket.id}", json={"status": "new"})
    assert r.status_code == 403, r.text
    assert "qayta ochish" in r.json()["detail"]

    # Holat o'zgarmagan bo'lishi kerak
    got = await c.get(f"{API}/tickets/{ticket.id}")
    assert got.json()["status"] == "completed"


async def test_plain_staff_cannot_reopen_cancelled_ticket(client, db_engine):
    ticket = await _ticket(db_engine, status="cancelled")
    c = _auth(client, await _user(db_engine, ["service:write"]))

    r = await c.patch(f"{API}/tickets/{ticket.id}", json={"status": "scheduled"})
    assert r.status_code == 403, r.text


# --------------------------------------------------------------------------- #
# Ruxsat bilan — qayta ochadi
# --------------------------------------------------------------------------- #
async def test_special_permission_reopens_ticket(client, db_engine):
    ticket = await _ticket(db_engine, status="completed")
    user = await _user(db_engine, ["service:write", "system:service_reopen"])
    c = _auth(client, user)

    r = await c.patch(f"{API}/tickets/{ticket.id}", json={"status": "new"})
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["status"] == "new"
    assert body["closed_at"] is None, "qayta ochilganda yopilgan sana tozalanishi kerak"


async def test_superadmin_reopens_ticket(client, db_engine):
    ticket = await _ticket(db_engine, status="completed")
    c = _auth(client, await _user(db_engine, [], superadmin=True))

    r = await c.patch(f"{API}/tickets/{ticket.id}", json={"status": "new"})
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "new"


async def test_wildcard_alone_is_not_enough(client, db_engine):
    """Oddiy "*" wildcard maxsus ruxsatni BERMAYDI (tizim qoidasi)."""
    ticket = await _ticket(db_engine, status="completed")
    c = _auth(client, await _user(db_engine, ["*"]))

    r = await c.patch(f"{API}/tickets/{ticket.id}", json={"status": "new"})
    assert r.status_code == 403, r.text


# --------------------------------------------------------------------------- #
# Yopish yo'nalishi — o'zgarishsiz
# --------------------------------------------------------------------------- #
async def test_closing_ticket_needs_no_special_permission(client, db_engine):
    ticket = await _ticket(db_engine, status="new")
    c = _auth(client, await _user(db_engine, ["service:write"]))

    r = await c.patch(f"{API}/tickets/{ticket.id}", json={"status": "completed"})
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "completed"
    assert r.json()["closed_at"] is not None


async def test_editing_resolution_of_closed_ticket_still_allowed(client, db_engine):
    """Status tegilmasa — yopilgan arizaning yechimi/xarajati tahrirlanaveradi."""
    ticket = await _ticket(db_engine, status="completed")
    c = _auth(client, await _user(db_engine, ["service:write"]))

    r = await c.patch(f"{API}/tickets/{ticket.id}",
                      json={"resolution": "Zichlagich almashtirildi"})
    assert r.status_code == 200, r.text
    assert r.json()["resolution"] == "Zichlagich almashtirildi"
