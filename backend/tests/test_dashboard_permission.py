"""Bosh sahifa — alohida `dashboard` ruxsati.

Bosh sahifa endi rol matritsasida o'z qatoriga ega:
  - faqat `dashboard:read` berilgan rol Bosh sahifa endpoint'larini ochadi,
    lekin Hisobotlar bo'limining qolgan endpoint'lari unga YOPIQ
  - `reports` ruxsati bor eski rollar Bosh sahifadan ayrilmaydi
  - ikkalasi ham yo'q rol — 403

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

DASHBOARD_ENDPOINTS = (
    "/api/v1/reports/dashboard",
    "/api/v1/reports/sales/income-expense",
    "/api/v1/goals/current",
)


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


async def test_dashboard_permission_opens_dashboard_endpoints(client, db_engine):
    c = _auth(client, await _user(db_engine, ["dashboard:read"]))
    for url in DASHBOARD_ENDPOINTS:
        r = await c.get(url)
        assert r.status_code == 200, (url, r.text)


async def test_dashboard_permission_does_not_open_reports(client, db_engine):
    """Bosh sahifa ruxsati Hisobotlar bo'limini ochib yubormasligi kerak."""
    c = _auth(client, await _user(db_engine, ["dashboard:read"]))
    for url in ("/api/v1/reports/service/summary", "/api/v1/reports/production/summary",
                "/api/v1/reports/sales/kpi", "/api/v1/reports/sales/trend"):
        r = await c.get(url)
        assert r.status_code == 403, (url, r.text)


async def test_reports_role_keeps_dashboard(client, db_engine):
    c = _auth(client, await _user(db_engine, ["reports:read"]))
    for url in DASHBOARD_ENDPOINTS:
        r = await c.get(url)
        assert r.status_code == 200, (url, r.text)


async def test_reports_export_only_role_keeps_dashboard_reports(client, db_engine):
    """Avval reports modulida istalgan verb Bosh sahifani ochardi — shunday qoladi."""
    c = _auth(client, await _user(db_engine, ["reports:export"]))
    for url in DASHBOARD_ENDPOINTS[:2]:
        r = await c.get(url)
        assert r.status_code == 200, (url, r.text)


async def test_no_dashboard_no_reports_is_forbidden(client, db_engine):
    c = _auth(client, await _user(db_engine, ["orders:read", "service:read"]))
    for url in DASHBOARD_ENDPOINTS:
        r = await c.get(url)
        assert r.status_code == 403, (url, r.text)


def test_dashboard_is_in_module_catalog():
    from app.core.permissions import MODULES, permission_catalog

    assert "dashboard" in MODULES
    assert "dashboard" in permission_catalog()["modules"]
