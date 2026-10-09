"""Servis KPI kartalari ro'yxat filtrlariga bo'ysunadi.

`/service/summary` ga viloyat, lokatsiyasiz va qidiruv filtrlari beriladi —
kartadagi son ro'yxatdagi arizalar soni bilan bir xil bo'lishi kerak.
Filtrsiz chaqiruv avvalgidek hamma arizani sanaydi.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/service"


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


async def _ticket(db_engine, *, region: str | None, status: str, problem: str = "suv oqyapti",
                  lat: float | None = None, in_warranty: bool = False):
    from app.models.customer import Customer
    from app.models.service import ServiceTicket

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        customer = Customer(full_name="Mijoz", phone=f"+9989{uuid.uuid4().int % 10**8:08d}",
                            region=region)
        db.add(customer)
        await db.flush()
        closed = status in ("completed", "cancelled")
        db.add(ServiceTicket(
            code=f"SRV-TEST-{uuid.uuid4().hex[:6]}",
            customer_id=customer.id,
            problem=problem,
            status=status,
            in_warranty=in_warranty,
            lat=lat, lon=lat,
            opened_at=datetime.now(timezone.utc),
            closed_at=datetime.now(timezone.utc) if closed else None,
        ))
        await db.commit()


async def _seed(db_engine):
    # Farg'ona: 2 ochiq (1 tasi kafolatda, 1 tasi lokatsiyali) + 1 bajarilgan
    await _ticket(db_engine, region="Farg'ona", status="new", in_warranty=True)
    await _ticket(db_engine, region="Farg'ona", status="scheduled", lat=40.38)
    await _ticket(db_engine, region="Farg'ona", status="completed", problem="eshik singan")
    # Namangan: 1 ochiq + 2 bajarilgan
    await _ticket(db_engine, region="Namangan", status="new", problem="eshik singan")
    await _ticket(db_engine, region="Namangan", status="completed", lat=41.0)
    await _ticket(db_engine, region="Namangan", status="completed", lat=41.0)
    # Viloyati yo'q mijoz
    await _ticket(db_engine, region=None, status="cancelled")


async def test_summary_without_filters_counts_everything(client, db_engine):
    await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    r = await c.get(f"{API}/summary")
    assert r.status_code == 200, r.text
    s = r.json()
    assert (s["total"], s["new"], s["scheduled"], s["completed"], s["cancelled"]) == (7, 2, 1, 3, 1)
    assert s["with_visit"] == 1
    assert s["in_warranty_open"] == 1


async def test_summary_follows_region_filter(client, db_engine):
    await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    s = (await c.get(f"{API}/summary", params={"region": "Namangan"})).json()
    assert (s["total"], s["new"], s["scheduled"], s["completed"]) == (3, 1, 0, 2)
    assert s["in_warranty_open"] == 0

    s = (await c.get(f"{API}/summary", params={"region": "Farg'ona"})).json()
    assert (s["total"], s["new"], s["scheduled"], s["completed"]) == (3, 1, 1, 1)
    assert s["in_warranty_open"] == 1


async def test_summary_matches_ticket_list_for_same_filters(client, db_engine):
    """Kartalar yig'indisi ro'yxatdagi arizalar soni bilan bir xil."""
    await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    for params in ({"region": "Farg'ona"}, {"has_location": "false"},
                   {"search": "eshik"}, {"region": "Namangan", "has_location": "false"}):
        s = (await c.get(f"{API}/summary", params=params)).json()
        listed = (await c.get(f"{API}/tickets", params={**params, "page_size": 100})).json()
        assert s["total"] == listed["total"], params


async def test_summary_combines_filters(client, db_engine):
    await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    # Lokatsiyasiz Farg'ona: new + completed (scheduled'da lokatsiya bor)
    s = (await c.get(f"{API}/summary",
                     params={"region": "Farg'ona", "has_location": "false"})).json()
    assert (s["total"], s["new"], s["scheduled"], s["completed"]) == (2, 1, 0, 1)

    # Qidiruv: "eshik" — Farg'ona completed + Namangan new
    s = (await c.get(f"{API}/summary", params={"search": "eshik"})).json()
    assert (s["total"], s["new"], s["completed"]) == (2, 1, 1)


async def test_summary_requires_service_permission(client, db_engine):
    c = _auth(client, await _user(db_engine, ["orders:read"]))

    r = await c.get(f"{API}/summary", params={"region": "Namangan"})
    assert r.status_code == 403, r.text
