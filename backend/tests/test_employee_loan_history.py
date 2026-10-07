"""Xodim qarzlari — to'liq tarix va yumshoq o'chirish.

GET /hr/employee-loans/history hamma narsani ko'rsatadi: faol, yopilgan va
o'chirilgan qarzlar, o'chirilgan so'ndirishlar va tahrirlar. O'chirish endi
yozuvni bazadan o'chirmaydi — faqat belgilaydi, va qoldiqqa ta'sir qilmaydi.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/hr"


def _session(db_engine):
    return async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)


async def _user(db_engine, permissions: list[str], *, name: str = "Test"):
    from app.models.user import Role, User

    async with _session(db_engine)() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}", permissions={"permissions": permissions})
        db.add(role)
        await db.flush()
        user = User(phone=f"+9989{uuid.uuid4().int % 10**8:08d}", password_hash="x",
                    full_name=name, is_active=True, token_version=0)
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


async def _employee(db_engine, name: str = "Ramizxon"):
    from app.models.hr import Employee

    async with _session(db_engine)() as db:
        emp = Employee(full_name=name, department_type="production")
        db.add(emp)
        await db.commit()
        await db.refresh(emp)
        return emp


async def _loan(c, emp, amount: int, note: str = "MOTOSKIL") -> dict:
    r = await c.post(f"{API}/employee-loans", json={
        "employee_id": str(emp.id), "amount": amount, "source": "director",
        "loan_date": "2026-06-22", "note": note,
    })
    assert r.status_code == 201, r.text
    return r.json()


async def _pay(c, loan_id: str, amount: int, pay_date: str) -> dict:
    r = await c.post(f"{API}/employee-loans/{loan_id}/payments",
                     json={"amount": amount, "pay_date": pay_date})
    assert r.status_code == 201, r.text
    return r.json()


async def _history_of(c, emp) -> dict:
    r = await c.get(f"{API}/employee-loans/history")
    assert r.status_code == 200, r.text
    return next(g for g in r.json() if g["employee_id"] == str(emp.id))


def _active_ids(r) -> set[str]:
    return {item["id"] for g in r.json() for item in g["items"]}


# --------------------------------------------------------------------------- #
# RBAC
# --------------------------------------------------------------------------- #
async def test_history_requires_hr_permission(client, db_engine):
    c = _auth(client, await _user(db_engine, ["orders:read"]))
    r = await c.get(f"{API}/employee-loans/history")
    assert r.status_code == 403, r.text


async def test_history_allowed_with_hr_read(client, db_engine):
    c = _auth(client, await _user(db_engine, ["hr:read"]))
    r = await c.get(f"{API}/employee-loans/history")
    assert r.status_code == 200, r.text


# --------------------------------------------------------------------------- #
# Yopilgan qarz faol ro'yxatdan tushadi, tarixda qoladi
# --------------------------------------------------------------------------- #
async def test_closed_loan_stays_in_history(client, db_engine):
    emp = await _employee(db_engine)
    c = _auth(client, await _user(db_engine, ["hr:*"], name="Kassir"))
    loan = await _loan(c, emp, 5_000_000)
    await _pay(c, loan["id"], 2_000_000, "2026-07-03")
    await _pay(c, loan["id"], 3_000_000, "2026-07-31")

    assert loan["id"] not in _active_ids(await c.get(f"{API}/employee-loans"))

    g = await _history_of(c, emp)
    assert float(g["total_taken"]) == 5_000_000
    assert float(g["total_paid"]) == 5_000_000
    assert float(g["balance"]) == 0
    item = g["items"][0]
    assert item["status"] == "closed"
    assert item["created_by_name"] == "Kassir"
    assert [p["pay_date"] for p in item["payments"]] == ["2026-07-03", "2026-07-31"]
    assert all(p["created_by_name"] == "Kassir" for p in item["payments"])


# --------------------------------------------------------------------------- #
# O'chirish — yumshoq
# --------------------------------------------------------------------------- #
async def test_deleted_loan_kept_in_history_but_not_in_totals(client, db_engine):
    emp = await _employee(db_engine)
    c = _auth(client, await _user(db_engine, ["hr:*"], name="Admin"))
    keep = await _loan(c, emp, 1_000_000, note="avans")
    gone = await _loan(c, emp, 9_000_000, note="xato kiritilgan")

    r = await c.delete(f"{API}/employee-loans/{gone['id']}")
    assert r.status_code == 204, r.text
    assert _active_ids(await c.get(f"{API}/employee-loans")) == {keep["id"]}

    g = await _history_of(c, emp)
    by_id = {i["id"]: i for i in g["items"]}
    assert by_id[gone["id"]]["status"] == "deleted"
    assert by_id[gone["id"]]["deleted_at"] is not None
    assert by_id[gone["id"]]["deleted_by_name"] == "Admin"
    # Jamilarga o'chirilgan qarz kirmaydi
    assert float(g["total_taken"]) == 1_000_000
    assert float(g["balance"]) == 1_000_000

    # O'chirilgan qarzga to'lov ham, tahrir ham yo'q
    r = await c.post(f"{API}/employee-loans/{gone['id']}/payments",
                     json={"amount": 100_000})
    assert r.status_code == 404, r.text
    r = await c.patch(f"{API}/employee-loans/{gone['id']}", json={"amount": 1})
    assert r.status_code == 404, r.text


async def test_deleted_payment_kept_and_balance_restored(client, db_engine):
    emp = await _employee(db_engine)
    c = _auth(client, await _user(db_engine, ["hr:*"], name="Admin"))
    loan = await _loan(c, emp, 3_000_000)
    pay = await _pay(c, loan["id"], 3_000_000, "2026-08-01")   # to'liq yopadi

    r = await c.delete(f"{API}/employee-loans/{loan['id']}/payments/{pay['id']}")
    assert r.status_code == 204, r.text

    # Qarz qayta ochildi, qoldiq tiklandi
    active = (await c.get(f"{API}/employee-loans")).json()
    item = next(i for g in active for i in g["items"] if i["id"] == loan["id"])
    assert float(item["balance"]) == 3_000_000
    assert item["payments"] == []

    g = await _history_of(c, emp)
    h = g["items"][0]
    assert h["status"] == "active"
    assert float(h["paid"]) == 0
    assert len(h["payments"]) == 1
    assert h["payments"][0]["deleted_at"] is not None
    assert h["payments"][0]["deleted_by_name"] == "Admin"

    # O'chirilgan to'lov qoldiqni band qilmaydi — to'liq summani yana to'lash mumkin
    await _pay(c, loan["id"], 3_000_000, "2026-08-02")


async def test_repay_from_salary_ignores_deleted_payments(client, db_engine):
    emp = await _employee(db_engine)
    c = _auth(client, await _user(db_engine, ["hr:*"]))
    loan = await _loan(c, emp, 2_000_000)
    pay = await _pay(c, loan["id"], 1_500_000, "2026-08-01")
    await c.delete(f"{API}/employee-loans/{loan['id']}/payments/{pay['id']}")

    r = await c.post(f"{API}/employees/{emp.id}/repay-loan-from-salary",
                     json={"amount": 2_000_000, "pay_date": "2026-09-05"})
    assert r.status_code == 201, r.text
    assert float(r.json()["remaining_debt"]) == 0


# --------------------------------------------------------------------------- #
# Tahrir tarixda
# --------------------------------------------------------------------------- #
async def test_edit_is_recorded_in_history(client, db_engine):
    emp = await _employee(db_engine)
    c = _auth(client, await _user(db_engine, ["hr:*"], name="Buxgalter"))
    loan = await _loan(c, emp, 10_000_000)

    r = await c.patch(f"{API}/employee-loans/{loan['id']}",
                      json={"amount": 11_545_000, "note": "MOTOSKIL"})
    assert r.status_code == 200, r.text

    g = await _history_of(c, emp)
    edits = g["items"][0]["edits"]
    assert len(edits) == 1   # note o'zgarmadi — faqat summa yozildi
    assert edits[0]["by_name"] == "Buxgalter"
    before, after = edits[0]["changes"]["amount"]
    assert float(before) == 10_000_000 and float(after) == 11_545_000
    assert "note" not in edits[0]["changes"]


async def test_edit_rejects_unknown_status(client, db_engine):
    emp = await _employee(db_engine)
    c = _auth(client, await _user(db_engine, ["hr:*"]))
    loan = await _loan(c, emp, 1_000_000)
    r = await c.patch(f"{API}/employee-loans/{loan['id']}", json={"status": "deleted"})
    assert r.status_code == 422, r.text
