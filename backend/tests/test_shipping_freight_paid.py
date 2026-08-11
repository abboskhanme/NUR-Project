"""Yuk chiqarish: yo'l kira to'langan/to'lanmaganligi.

Shofyorga beriladigan yo'l kira to'langanmi yoki hali qarzmi — shu holat
jurnalda belgilanadi va ro'yxat shu bo'yicha filtrlanadi.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/shipping"


async def _admin(client, db_engine):
    from app.core.dependencies import get_current_user
    from app.main import app
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}",
                    permissions={"permissions": ["shipping:*"]})
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


async def _row(c, **kw):
    payload = {"date": "2026-08-05", "qty": 1, "freight": 500000}
    payload.update(kw)
    r = await c.post(API, json=payload)
    assert r.status_code == 201, r.text
    return r.json()


async def test_new_row_is_unpaid_by_default(client, db_engine):
    """Yangi qator sukut bo'yicha «to'lanmagan» — ya'ni qarz."""
    c = await _admin(client, db_engine)
    row = await _row(c)
    assert row["freight_paid"] is False


async def test_mark_paid_and_back(client, db_engine):
    """Holat ikki tomonlama o'zgaradi: to'landi ↔ to'lanmadi."""
    c = await _admin(client, db_engine)
    row = await _row(c)

    r = await c.patch(f"{API}/{row['id']}", json={"freight_paid": True})
    assert r.status_code == 200 and r.json()["freight_paid"] is True

    r = await c.patch(f"{API}/{row['id']}", json={"freight_paid": False})
    assert r.status_code == 200 and r.json()["freight_paid"] is False


async def test_other_fields_do_not_reset_status(client, db_engine):
    """Boshqa katakni tahrirlash holatni o'zgartirmasligi kerak."""
    c = await _admin(client, db_engine)
    row = await _row(c)
    await c.patch(f"{API}/{row['id']}", json={"freight_paid": True})

    r = await c.patch(f"{API}/{row['id']}", json={"driver_name": "Aziz"})
    assert r.status_code == 200
    assert r.json()["freight_paid"] is True and r.json()["driver_name"] == "Aziz"


async def test_list_filters_by_status(client, db_engine):
    """Ro'yxat holat bo'yicha filtrlanadi; filtrsiz hammasi qaytadi."""
    c = await _admin(client, db_engine)
    paid = await _row(c, freight=300000)
    due = await _row(c, freight=700000)
    await c.patch(f"{API}/{paid['id']}", json={"freight_paid": True})

    params = {"year": 2026, "month": 8}
    all_rows = (await c.get(API, params=params)).json()
    assert {r["id"] for r in all_rows} == {paid["id"], due["id"]}

    only_paid = (await c.get(API, params={**params, "freight_paid": "true"})).json()
    assert [r["id"] for r in only_paid] == [paid["id"]]

    only_due = (await c.get(API, params={**params, "freight_paid": "false"})).json()
    assert [r["id"] for r in only_due] == [due["id"]]
