"""Bizning qarzlar: boshqa valyutadagi (konvertatsiyali) to'lov.

Qarz o'z valyutasida yopiladi — dollar qarzi so'mda to'lansa, kurs bo'yicha
dollarga aylantirib qarzdan ayriladi; to'langan summa/valyuta/kurs saqlanadi.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/debts"


async def _make_user(db_engine, permissions: list[str]):
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


async def _debt(c, currency: str, amount: float):
    r = await c.post(f"{API}/products", json={"name": "Kredit", "debt_type": "credit",
                                              "currency": currency})
    assert r.status_code == 201, r.text
    p = r.json()
    r = await c.post(f"{API}/products/{p['id']}/purchase", json={"amount": amount})
    assert r.status_code == 201, r.text
    return p


async def _balance(c, pid):
    r = await c.get(f"{API}/products")
    assert r.status_code == 200, r.text
    return next(x for x in r.json() if x["id"] == pid)["balance"]


async def test_usd_debt_paid_in_uzs(client, db_engine):
    c = _auth(client, await _make_user(db_engine, ["debts:*"]))
    p = await _debt(c, "USD", 1000)

    r = await c.post(f"{API}/products/{p['id']}/payment", json={
        "paid_amount": 1_265_000, "paid_currency": "UZS", "exchange_rate": 12650})
    assert r.status_code == 201, r.text
    tx = r.json()
    assert tx["currency"] == "USD"
    assert tx["amount"] == 100
    assert tx["paid_amount"] == 1_265_000
    assert tx["paid_currency"] == "UZS"
    assert tx["exchange_rate"] == 12650
    assert await _balance(c, p["id"]) == 900


async def test_uzs_debt_paid_in_usd(client, db_engine):
    c = _auth(client, await _make_user(db_engine, ["debts:*"]))
    p = await _debt(c, "UZS", 10_000_000)

    r = await c.post(f"{API}/products/{p['id']}/payment", json={
        "paid_amount": 100, "paid_currency": "USD", "exchange_rate": 12650})
    assert r.status_code == 201, r.text
    assert r.json()["amount"] == 1_265_000
    assert await _balance(c, p["id"]) == 10_000_000 - 1_265_000


async def test_same_currency_payment_unchanged(client, db_engine):
    c = _auth(client, await _make_user(db_engine, ["debts:*"]))
    p = await _debt(c, "USD", 500)

    r = await c.post(f"{API}/products/{p['id']}/payment", json={"amount": 200})
    assert r.status_code == 201, r.text
    tx = r.json()
    assert tx["amount"] == 200
    assert tx["paid_amount"] is None and tx["paid_currency"] is None and tx["exchange_rate"] is None
    assert await _balance(c, p["id"]) == 300


async def test_converted_payment_requires_paid_amount(client, db_engine):
    c = _auth(client, await _make_user(db_engine, ["debts:*"]))
    p = await _debt(c, "USD", 500)

    r = await c.post(f"{API}/products/{p['id']}/payment", json={
        "paid_currency": "UZS", "exchange_rate": 12650})
    assert r.status_code == 400
    assert await _balance(c, p["id"]) == 500


async def test_payment_requires_debts_permission(client, db_engine):
    admin = _auth(client, await _make_user(db_engine, ["debts:*"]))
    p = await _debt(admin, "USD", 500)

    c = _auth(client, await _make_user(db_engine, ["orders:read"]))
    r = await c.post(f"{API}/products/{p['id']}/payment", json={
        "paid_amount": 1_265_000, "paid_currency": "UZS", "exchange_rate": 12650})
    assert r.status_code == 403
