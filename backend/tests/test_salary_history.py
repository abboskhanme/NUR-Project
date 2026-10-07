"""Oylik tarixi — GET /hr/salary-history va /hr/salary-history/{employee_id}.

Asosiy kafolat: tarixdagi har oy hisobi (gross / berilgan / qoldiq) HR sahifasi
ishlatadigan `_month_aggregate` bilan AYNAN bir xil. Qo'shimcha: har bir to'lov
(bekor qilinganlari ham) kim kiritgani, naqd/karta, oylik/avans turi bilan chiqadi.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import date, time
from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/hr"


def _session(db_engine):
    return async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)


def _months_back(n: int) -> tuple[int, int]:
    t = date.today()
    y, m = t.year, t.month - n
    while m <= 0:
        y, m = y - 1, m + 12
    return y, m


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


async def _seed(db_engine, user):
    """Fixed xodim (oy o'rtasida ishga kirgan) + soatbay xodim, turli yozuvlar bilan."""
    from app.models.finance import FinanceCategory, FinanceTransaction
    from app.models.hr import (
        Attendance, Employee, SalaryAdjustment, SalaryAdvance, SalaryOverride, SalaryRate,
    )

    y2, m2 = _months_back(2)
    y1, m1 = _months_back(1)
    async with _session(db_engine)() as db:
        cat = FinanceCategory(name="Oylik", kind="expense", code="employee_salary")
        db.add(cat)
        fixed = Employee(full_name="Ramizxon", department_type="production",
                         salary_type="fixed", salary_amount=Decimal(6_000_000),
                         hire_date=date(y2, m2, 10))
        hourly = Employee(full_name="Akmal", department_type="assembly",
                          salary_type="hourly", salary_amount=Decimal(20_000),
                          hire_date=date(y2, m2, 1))
        db.add_all([fixed, hourly])
        await db.flush()

        # Stavka tarixi: 2 oy oldin 5 mln, o'tgan oydan 6 mln
        db.add_all([
            SalaryRate(employee_id=fixed.id, effective_from=date(y2, m2, 10),
                       salary_type="fixed", amount=Decimal(5_000_000), created_by_id=user.id),
            SalaryRate(employee_id=fixed.id, effective_from=date(y1, m1, 1),
                       salary_type="fixed", amount=Decimal(6_000_000), created_by_id=user.id),
        ])

        tx = FinanceTransaction(date=date(y2, m2, 28), type="expense", category_id=cat.id,
                                amount=Decimal(3_000_000), method="karta")
        db.add(tx)
        await db.flush()
        db.add_all([
            # Ishga kirishdan oldin (shu oy) — hisobga kirmaydi, lekin tarixda ko'rinadi
            SalaryAdvance(employee_id=fixed.id, advance_date=date(y2, m2, 5),
                          amount=Decimal(100_000), note="erta avans", created_by_id=user.id),
            SalaryAdvance(employee_id=fixed.id, advance_date=date(y2, m2, 28),
                          amount=Decimal(3_000_000), tx_id=tx.id,
                          note="Oylik to'lovi — Ramizxon", created_by_id=user.id),
            SalaryAdvance(employee_id=fixed.id, advance_date=date(y2, m2, 20),
                          amount=Decimal(999_000), status="void", note="xato",
                          created_by_id=user.id),
            SalaryAdvance(employee_id=fixed.id, advance_date=date(y1, m1, 15),
                          amount=Decimal(2_000_000), note="Qarzga to'landi", created_by_id=user.id),
            SalaryAdjustment(employee_id=fixed.id, year=y1, month=m1, kind="bonus",
                             amount=Decimal(500_000), note="mukofot", created_by_id=user.id),
            SalaryAdjustment(employee_id=fixed.id, year=y1, month=m1, kind="penalty",
                             amount=Decimal(200_000), note="kechikish", created_by_id=user.id),
            SalaryAdjustment(employee_id=fixed.id, year=y1, month=m1, kind="penalty",
                             amount=Decimal(1_000_000), status="void", created_by_id=user.id),
            SalaryOverride(employee_id=fixed.id, year=y2, month=m2, amount=Decimal(3_500_000),
                           note="yarim oy", created_by_id=user.id),
        ])
        for d in (3, 4, 5):
            db.add(Attendance(employee_id=hourly.id, work_date=date(y1, m1, d),
                              check_in=time(8, 30), check_out=time(18, 0),
                              hours_worked=Decimal("9.5"), daily_pay=Decimal(190_000)))
        db.add(SalaryAdvance(employee_id=hourly.id, advance_date=date(y1, m1, 20),
                             amount=Decimal(300_000), created_by_id=user.id))
        await db.commit()
        return fixed, hourly


# --------------------------------------------------------------------------- #
# RBAC
# --------------------------------------------------------------------------- #
async def test_history_requires_hr_permission(client, db_engine):
    c = _auth(client, await _user(db_engine, ["orders:read"]))
    assert (await c.get(f"{API}/salary-history")).status_code == 403
    assert (await c.get(f"{API}/salary-history/{uuid.uuid4()}")).status_code == 403


async def test_history_allowed_with_hr_read(client, db_engine):
    c = _auth(client, await _user(db_engine, ["hr:read"]))
    assert (await c.get(f"{API}/salary-history")).status_code == 200
    assert (await c.get(f"{API}/salary-history/{uuid.uuid4()}")).status_code == 404


# --------------------------------------------------------------------------- #
# Hisob HR sahifasi bilan bir xil
# --------------------------------------------------------------------------- #
async def test_months_match_month_aggregate(client, db_engine):
    from app.api.v1.hr import _month_aggregate
    from app.models.hr import Employee

    user = await _user(db_engine, ["hr:read"])
    fixed, hourly = await _seed(db_engine, user)
    c = _auth(client, user)

    for emp_id in (fixed.id, hourly.id):
        r = await c.get(f"{API}/salary-history/{emp_id}")
        assert r.status_code == 200, r.text
        months = r.json()["months"]
        assert months, "oylar bo'sh"
        async with _session(db_engine)() as db:
            emp = await db.get(Employee, emp_id)
            for mo in months:
                present, hours, gross, advance, net, bonus, penalty = await _month_aggregate(
                    db, emp, mo["year"], mo["month"])
                key = (emp.full_name, mo["year"], mo["month"])
                assert Decimal(mo["gross"]) == gross, key
                assert Decimal(mo["paid"]) == advance, key
                assert Decimal(mo["balance"]) == net, key
                assert mo["present_days"] == present, key
                assert Decimal(mo["bonus"]) == bonus and Decimal(mo["penalty"]) == penalty, key


async def test_payment_details_include_voided_and_metadata(client, db_engine):
    user = await _user(db_engine, ["hr:read"], name="Kassir")
    fixed, _ = await _seed(db_engine, user)
    c = _auth(client, user)
    y2, m2 = _months_back(2)
    y1, m1 = _months_back(1)

    d = (await c.get(f"{API}/salary-history/{fixed.id}")).json()
    by_month = {(mo["year"], mo["month"]): mo for mo in d["months"]}

    first = by_month[(y2, m2)]
    assert float(first["override"]) == 3_500_000
    assert float(first["gross"]) == 3_500_000
    assert float(first["paid"]) == 3_000_000      # erta avans va bekor qilingan kirmaydi
    pays = {p["note"]: p for p in first["payments"]}
    assert len(pays) == 3
    assert pays["Oylik to'lovi — Ramizxon"]["kind"] == "salary"
    assert pays["Oylik to'lovi — Ramizxon"]["method"] == "karta"
    assert pays["Oylik to'lovi — Ramizxon"]["in_finance"] is True
    assert pays["Oylik to'lovi — Ramizxon"]["created_by_name"] == "Kassir"
    assert pays["xato"]["status"] == "void" and pays["xato"]["voided_at"]
    assert pays["xato"]["counted"] is False
    assert pays["erta avans"]["counted"] is False   # ishga kirishdan oldin
    assert first["overrides"][0]["note"] == "yarim oy"

    second = by_month[(y1, m1)]
    # 6 mln (yangi stavka) + 500k bonus − 200k jarima (bekor qilingan jarima kirmaydi)
    assert float(second["rate_amount"]) == 6_000_000
    assert float(second["gross"]) == 6_300_000
    assert float(second["paid"]) == 2_000_000
    assert second["payments"][0]["kind"] == "advance"
    assert second["payments"][0]["in_finance"] is False
    assert len(second["adjustments"]) == 3
    assert [r["amount"] for r in d["rates"]] == ["6000000.00", "5000000.00"]
    # Yangi oydan eskisiga
    assert (d["months"][0]["year"], d["months"][0]["month"]) >= (d["months"][-1]["year"],
                                                                 d["months"][-1]["month"])


async def test_overview_totals_and_inactive_employee(client, db_engine):
    from app.models.hr import Employee, SalaryAdvance

    user = await _user(db_engine, ["hr:read"])
    fixed, hourly = await _seed(db_engine, user)
    y3, m3 = _months_back(3)
    async with _session(db_engine)() as db:
        # Ishdan ketgan fixed xodim: oxirgi yozuvi 3 oy oldin — keyingi oylar "hisoblanmaydi"
        gone = Employee(full_name="Ketgan", salary_type="fixed", status="inactive",
                        salary_amount=Decimal(4_000_000), hire_date=date(y3, m3, 1))
        db.add(gone)
        await db.flush()
        db.add(SalaryAdvance(employee_id=gone.id, advance_date=date(y3, m3, 25),
                             amount=Decimal(4_000_000)))
        # Hech qanday yozuvi yo'q xodim ro'yxatga tushmaydi
        db.add(Employee(full_name="Bo'sh", salary_type="hourly", salary_amount=0))
        await db.commit()
        gone_id = gone.id

    c = _auth(client, user)
    rows = (await c.get(f"{API}/salary-history")).json()
    names = [r["full_name"] for r in rows]
    assert "Bo'sh" not in names
    assert names[-1] == "Ketgan"           # ishlayotganlar birinchi

    g = next(r for r in rows if r["employee_id"] == str(gone_id))
    assert g["months_count"] == 1
    assert float(g["balance"]) == 0

    for r in rows:
        d = (await c.get(f"{API}/salary-history/{r['employee_id']}")).json()
        assert Decimal(r["total_gross"]) == sum(Decimal(m["gross"]) for m in d["months"])
        assert Decimal(r["total_paid"]) == sum(Decimal(m["paid"]) for m in d["months"])
        assert Decimal(r["balance"]) == Decimal(r["total_gross"]) - Decimal(r["total_paid"])
