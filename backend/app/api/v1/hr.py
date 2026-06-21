"""HR: employees, attendance, advances, payroll."""
import calendar
import uuid
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.hr import (
    Attendance, Department, Employee, EmployeeLoan, EmployeeLoanPayment,
    PayrollItem, PayrollRun, Position, SalaryAdvance, SalaryRate,
)
from app.schemas.common import Page
from app.schemas.hr import (
    AttendanceBatchIn, AttendanceOut,
    DepartmentCreate, DepartmentOut, DepartmentUpdate,
    EmployeeCreate, EmployeeLoanGroup, EmployeeLoanIn, EmployeeLoanOut,
    EmployeeLoanPaymentIn, EmployeeLoanPaymentOut, EmployeeLoanUpdate,
    EmployeeMonthSummary, EmployeeOut, EmployeeUpdate,
    MonthDebts, MonthHistoryItem, MonthlySummary,
    PayrollRunIn, PayrollRunOut,
    PositionCreate, PositionOut, PositionUpdate,
    SalaryAdvanceIn, SalaryAdvanceOut,
    SalaryRateCreate, SalaryRateOut,
)

router = APIRouter(dependencies=[Depends(module_guard("hr"))])

# Standart to'liq ish kuni (soat). Davomat default oynasi 08:30–18:00 ga mos keladi.
# Soatbay xodimning "to'liq kun"lik haqi shu soatga ko'ra taxminlanadi.
STANDARD_WORKDAY_HOURS = Decimal("9.5")


def _working_days(start: date, end: date) -> int:
    """[start, end] oralig'idagi ish kunlari soni (yakshanbalar dam — hisobga kirmaydi)."""
    if start > end:
        return 0
    total = (end - start).days + 1
    full_weeks, rem = divmod(total, 7)
    count = full_weeks * 6  # har 7 kunda 1 yakshanba
    for i in range(rem):
        if (start + timedelta(days=i)).weekday() != 6:  # 6 = yakshanba
            count += 1
    return count


def _max_month_gross(emp: Employee, year: int, month: int, gross_actual: Decimal,
                     rate_type: str, rate_amount: Decimal) -> Decimal:
    """Joriy oy uchun olinishi mumkin bo'lgan MAKSIMAL oylik (taxminiy).

    - fixed: belgilangan oylik (o'zgarmas).
    - soatbay (va boshqalar): o'tgan kunlardagi haqiqiy hisoblangan haq +
      qolgan ish kunlari to'liq kelganda hisoblanadigan haq.
      To'liq kun haqi = stavka × STANDARD_WORKDAY_HOURS.
      Qolgan kunlar = bugundan keyin oy oxirigacha bo'lgan ish kunlari (yakshanbasiz).
    """
    if emp.salary_type == "fixed" or rate_type == "fixed":
        return emp.salary_amount or Decimal(0)

    start = date(year, month, 1)
    end = date(year, month, calendar.monthrange(year, month)[1])
    eff_start = max(start, emp.hire_date) if emp.hire_date else start
    today = date.today()
    remaining_start = max(eff_start, today + timedelta(days=1))
    remaining_days = _working_days(remaining_start, end)

    if rate_type == "daily":
        full_day_pay = rate_amount or Decimal(0)
    else:  # hourly va h.k. — to'liq kun = stavka × standart soat
        full_day_pay = (rate_amount or Decimal(0)) * STANDARD_WORKDAY_HOURS

    return (gross_actual or Decimal(0)) + remaining_days * full_day_pay


async def _rate_on(db: AsyncSession, emp: Employee, on_date: date):
    """Berilgan sanada amal qilgan stavkani qaytaradi: (salary_type, amount).

    Eng oxirgi effective_from <= on_date bo'lgan yozuv. Tarix bo'lmasa — Employee'dagi
    joriy stavkaga qaytadi (orqaga moslik uchun).
    """
    res = await db.execute(
        select(SalaryRate)
        .where(and_(SalaryRate.employee_id == emp.id, SalaryRate.effective_from <= on_date))
        .order_by(SalaryRate.effective_from.desc(), SalaryRate.created_at.desc())
        .limit(1)
    )
    rate = res.scalar_one_or_none()
    if rate:
        return rate.salary_type, (rate.amount or Decimal(0))
    return emp.salary_type, (emp.salary_amount or Decimal(0))


async def _month_aggregate(db: AsyncSession, emp: Employee, year: int, month: int):
    """Bir oy uchun: kelgan kunlar, jami soat, gross, avans, net.

    Ish boshlagan sana (hire_date)'dan oldingi kunlar hisobga olinmaydi.
    """
    start = date(year, month, 1)
    end = date(year, month, calendar.monthrange(year, month)[1])
    eff_start = max(start, emp.hire_date) if emp.hire_date else start
    if eff_start > end:
        return 0, Decimal(0), Decimal(0), Decimal(0), Decimal(0)

    att_res = await db.execute(
        select(
            func.count(Attendance.id),
            func.coalesce(func.sum(Attendance.hours_worked), 0),
            func.coalesce(func.sum(Attendance.daily_pay), 0),
        ).where(and_(
            Attendance.employee_id == emp.id,
            Attendance.work_date >= eff_start,
            Attendance.work_date <= end,
            Attendance.hours_worked > 0,
        ))
    )
    present_days, hours, gross = att_res.one()
    gross = Decimal(gross or 0)
    if emp.salary_type == "fixed":
        gross = emp.salary_amount or Decimal(0)

    adv_res = await db.execute(
        select(func.coalesce(func.sum(SalaryAdvance.amount), 0)).where(and_(
            SalaryAdvance.employee_id == emp.id,
            SalaryAdvance.advance_date >= eff_start,
            SalaryAdvance.advance_date <= end,
            SalaryAdvance.status == "active",
        ))
    )
    advance = Decimal(adv_res.scalar() or 0)
    net = gross - advance
    return int(present_days or 0), Decimal(hours or 0), gross, advance, net


async def advance_cap(db: AsyncSession, emp: Employee, year: int, month: int):
    """Avans limiti uchun: (tahminiy oylik max_gross, joriy faol avanslar yig'indisi).

    Ro'yxatdagi `month_summary.max_gross` bilan bir xil hisob — bittadan manba."""
    _, _, gross, advance, _ = await _month_aggregate(db, emp, year, month)
    eom = date(year, month, calendar.monthrange(year, month)[1])
    rate_type, rate_amount = await _rate_on(db, emp, eom)
    max_gross = _max_month_gross(emp, year, month, gross, rate_type, rate_amount)
    return max_gross, advance


@router.get("/salary-debts", response_model=list[MonthDebts])
async def salary_debts(_: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
                       year: Optional[int] = None):
    """Xodimlar oldidagi oylik qarzlarimiz — har oy uchun alohida (yangi → eski).

    Bir oy uchun bitta xodim qarzi = hisoblangan oylik (gross) − berilgan summa
    (avans + oylik to'lovlari). Faqat qarz > 0 bo'lgan xodimlar ro'yxatga kiradi.
    Hisob `_month_aggregate` bilan bir xil mantiqда, lekin butun yil 2 ta guruh
    so'rovida olinadi (har xodim-oyga alohida so'rovsiz)."""
    today = date.today()
    year = year or today.year
    if year > today.year:
        return []
    last_month = 12 if year < today.year else today.month

    emps = (await db.execute(
        select(Employee).where(Employee.status == "active").order_by(Employee.full_name)
    )).scalars().all()
    if not emps:
        return []
    emp_ids = [e.id for e in emps]

    ystart = date(year, 1, 1)
    yend = date(year, 12, 31)

    # Soatbay gross: attendance.daily_pay yig'indisi (emp, oy) bo'yicha
    m_att = func.extract("month", Attendance.work_date)
    att_rows = (await db.execute(
        select(Attendance.employee_id, m_att.label("m"),
               func.coalesce(func.sum(Attendance.daily_pay), 0))
        .where(and_(
            Attendance.employee_id.in_(emp_ids),
            Attendance.work_date >= ystart, Attendance.work_date <= yend,
            Attendance.hours_worked > 0,
        )).group_by(Attendance.employee_id, m_att)
    )).all()
    gross_map = {(r[0], int(r[1])): Decimal(r[2] or 0) for r in att_rows}

    # Berilgan summa: faol avans/oylik to'lovlari (emp, oy) bo'yicha
    m_adv = func.extract("month", SalaryAdvance.advance_date)
    adv_rows = (await db.execute(
        select(SalaryAdvance.employee_id, m_adv.label("m"),
               func.coalesce(func.sum(SalaryAdvance.amount), 0))
        .where(and_(
            SalaryAdvance.employee_id.in_(emp_ids),
            SalaryAdvance.advance_date >= ystart, SalaryAdvance.advance_date <= yend,
            SalaryAdvance.status == "active",
        )).group_by(SalaryAdvance.employee_id, m_adv)
    )).all()
    paid_map = {(r[0], int(r[1])): Decimal(r[2] or 0) for r in adv_rows}

    result: list[MonthDebts] = []
    for m in range(last_month, 0, -1):  # yangi oydan eskisiga
        month_end = date(year, m, calendar.monthrange(year, m)[1])
        items = []
        total = Decimal(0)
        for e in emps:
            if e.hire_date and e.hire_date > month_end:
                continue  # bu oyda hali ishlamagan
            if e.salary_type == "fixed":
                gross = e.salary_amount or Decimal(0)
            else:
                gross = gross_map.get((e.id, m), Decimal(0))
            paid = paid_map.get((e.id, m), Decimal(0))
            debt = gross - paid
            if debt > 0:
                items.append({
                    "employee_id": e.id, "full_name": e.full_name,
                    "department_type": e.department_type,
                    "gross": gross, "paid": paid, "debt": debt,
                })
                total += debt
        result.append(MonthDebts(year=year, month=m, total=total, items=items))
    return result


def _emp_out(e: Employee, pos_name: Optional[str]) -> EmployeeOut:
    out = EmployeeOut.model_validate(e)
    out.position_name = pos_name
    return out


async def _positions_map(db: AsyncSession) -> dict:
    res = await db.execute(select(Position.id, Position.name))
    return {pid: name for pid, name in res.all()}


# ---- Departments (bo'limlar) ----
@router.get("/departments", response_model=list[DepartmentOut])
async def list_departments(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(select(Department).order_by(Department.name))
    return [DepartmentOut.model_validate(d) for d in res.scalars().all()]


@router.post("/departments", response_model=DepartmentOut, status_code=201)
async def create_department(payload: DepartmentCreate, db: Annotated[AsyncSession, Depends(get_db)]):
    exists = await db.execute(select(Department).where(Department.name == payload.name))
    if exists.scalar_one_or_none():
        raise HTTPException(409, "Bunday bo'lim allaqachon mavjud")
    d = Department(name=payload.name)
    db.add(d)
    await db.commit()
    await db.refresh(d)
    return d


@router.patch("/departments/{department_id}", response_model=DepartmentOut)
async def update_department(department_id: uuid.UUID, payload: DepartmentUpdate,
                            db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Department).where(Department.id == department_id))
    d = res.scalar_one_or_none()
    if not d:
        raise HTTPException(404, "Bo'lim topilmadi")
    if payload.name is not None:
        d.name = payload.name
    await db.commit()
    await db.refresh(d)
    return d


@router.delete("/departments/{department_id}", status_code=204)
async def delete_department(department_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Department).where(Department.id == department_id))
    d = res.scalar_one_or_none()
    if not d:
        raise HTTPException(404, "Bo'lim topilmadi")
    await db.delete(d)
    await db.commit()


# ---- Positions (lavozimlar) ----
@router.get("/positions", response_model=list[PositionOut])
async def list_positions(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(select(Position).order_by(Position.name))
    return [PositionOut.model_validate(p) for p in res.scalars().all()]


@router.post("/positions", response_model=PositionOut, status_code=201)
async def create_position(payload: PositionCreate, db: Annotated[AsyncSession, Depends(get_db)]):
    exists = await db.execute(select(Position).where(Position.name == payload.name))
    if exists.scalar_one_or_none():
        raise HTTPException(409, "Bunday lavozim allaqachon mavjud")
    p = Position(name=payload.name, department_id=payload.department_id)
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return p


@router.patch("/positions/{position_id}", response_model=PositionOut)
async def update_position(position_id: uuid.UUID, payload: PositionUpdate,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Position).where(Position.id == position_id))
    p = res.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Lavozim topilmadi")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(p, k, v)
    await db.commit()
    await db.refresh(p)
    return p


@router.delete("/positions/{position_id}", status_code=204)
async def delete_position(position_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Position).where(Position.id == position_id))
    p = res.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Lavozim topilmadi")
    await db.delete(p)
    await db.commit()


# ---- Employees ----
@router.get("/employees", response_model=Page[EmployeeOut])
async def list_employees(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    page: int = Query(1, ge=1), page_size: int = Query(50, ge=1, le=200),
    status: Optional[str] = "active", employment_type: Optional[str] = None,
    department_type: Optional[str] = None,
    q: Optional[str] = Query(None, description="Ism bo'yicha qidiruv"),
    with_summary: bool = Query(False, description="Joriy oy bo'yicha yig'ma hisobni qo'shish"),
    year: Optional[int] = Query(None, ge=2000, le=2100),
    month: Optional[int] = Query(None, ge=1, le=12),
):
    query = select(Employee)
    if status:
        query = query.where(Employee.status == status)
    if employment_type:
        query = query.where(Employee.employment_type == employment_type)
    if department_type:
        query = query.where(Employee.department_type == department_type)
    if q:
        query = query.where(func.lower(Employee.full_name).like(f"%{q.lower()}%"))
    total = (await db.execute(select(func.count()).select_from(query.subquery()))).scalar() or 0
    res = await db.execute(query.order_by(Employee.full_name)
                            .offset((page - 1) * page_size).limit(page_size))
    employees = res.scalars().all()
    pos_map = await _positions_map(db)

    items = []
    today = date.today()
    sy = year or today.year
    sm = month or today.month
    for e in employees:
        out = _emp_out(e, pos_map.get(e.position_id))
        if with_summary:
            present, hours, gross, advance, net = await _month_aggregate(db, e, sy, sm)
            eom = date(sy, sm, calendar.monthrange(sy, sm)[1])
            rate_type, rate_amount = await _rate_on(db, e, eom)
            max_gross = _max_month_gross(e, sy, sm, gross, rate_type, rate_amount)
            out.month_summary = EmployeeMonthSummary(
                year=sy, month=sm, present_days=present, total_hours=hours,
                gross=gross, advance=advance, net=net, salary_type=rate_type,
                max_gross=max_gross,
            )
        items.append(out)
    return Page[EmployeeOut](
        items=items, total=total, page=page, page_size=page_size,
    )


@router.post("/employees", response_model=EmployeeOut, status_code=201)
async def create_employee(payload: EmployeeCreate, db: Annotated[AsyncSession, Depends(get_db)]):
    data = payload.model_dump()
    # Ish boshlagan sana ko'rsatilmasa — bugundan hisoblanadi
    if not data.get("hire_date"):
        data["hire_date"] = date.today()
    e = Employee(**data)
    db.add(e)
    await db.flush()
    # Boshlang'ich stavka — ish boshlagan sanadan
    db.add(SalaryRate(
        employee_id=e.id, effective_from=e.hire_date or date.today(),
        salary_type=e.salary_type, amount=e.salary_amount or Decimal(0), currency=e.currency,
    ))
    await db.commit()
    await db.refresh(e)
    pos_map = await _positions_map(db)
    return _emp_out(e, pos_map.get(e.position_id))


@router.get("/employees/{employee_id}", response_model=EmployeeOut)
async def get_employee(employee_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)],
                       _: CurrentUser):
    res = await db.execute(select(Employee).where(Employee.id == employee_id))
    e = res.scalar_one_or_none()
    if not e:
        raise HTTPException(404, "Xodim topilmadi")
    pos_map = await _positions_map(db)
    return _emp_out(e, pos_map.get(e.position_id))


@router.get("/employees/{employee_id}/summary", response_model=MonthlySummary)
async def employee_month_summary(
    employee_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    year: int = Query(..., ge=2000, le=2100), month: int = Query(..., ge=1, le=12),
):
    res = await db.execute(select(Employee).where(Employee.id == employee_id))
    e = res.scalar_one_or_none()
    if not e:
        raise HTTPException(404, "Xodim topilmadi")
    present, hours, gross, advance, net = await _month_aggregate(db, e, year, month)
    # O'sha oyda amal qilgan stavka (oy oxiriga ko'ra)
    eom = date(year, month, calendar.monthrange(year, month)[1])
    rate_type, rate_amount = await _rate_on(db, e, eom)
    return MonthlySummary(
        year=year, month=month, present_days=present, total_hours=hours,
        gross=gross, advance=advance, net=net,
        salary_type=rate_type, hourly_rate=rate_amount,
    )


@router.get("/employees/{employee_id}/history", response_model=list[MonthHistoryItem])
async def employee_history(
    employee_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    months: int = Query(12, ge=1, le=36),
):
    res = await db.execute(select(Employee).where(Employee.id == employee_id))
    e = res.scalar_one_or_none()
    if not e:
        raise HTTPException(404, "Xodim topilmadi")
    today = date.today()
    out: list[MonthHistoryItem] = []
    y, m = today.year, today.month
    for _i in range(months):
        present, hours, gross, advance, net = await _month_aggregate(db, e, y, m)
        out.append(MonthHistoryItem(
            year=y, month=m, present_days=present, total_hours=hours,
            gross=gross, advance=advance, net=net,
        ))
        m -= 1
        if m == 0:
            m = 12
            y -= 1
    return out


# ---- Salary rates (stavka tarixi) ----
@router.get("/employees/{employee_id}/salary-rates", response_model=list[SalaryRateOut])
async def list_salary_rates(employee_id: uuid.UUID,
                            db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(
        select(SalaryRate).where(SalaryRate.employee_id == employee_id)
        .order_by(SalaryRate.effective_from.desc(), SalaryRate.created_at.desc())
    )
    return [SalaryRateOut.model_validate(r) for r in res.scalars().all()]


@router.post("/employees/{employee_id}/salary-rates", response_model=SalaryRateOut, status_code=201)
async def add_salary_rate(employee_id: uuid.UUID, payload: SalaryRateCreate, user: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    emp_res = await db.execute(select(Employee).where(Employee.id == employee_id))
    emp = emp_res.scalar_one_or_none()
    if not emp:
        raise HTTPException(404, "Xodim topilmadi")
    rate = SalaryRate(
        employee_id=emp.id, created_by_id=user.id, **payload.model_dump(),
    )
    db.add(rate)
    await db.flush()
    # Employee'dagi "joriy" stavka — bugungi kunga ko'ra amaldagi stavka
    cur_type, cur_amount = await _rate_on(db, emp, date.today())
    emp.salary_type = cur_type
    emp.salary_amount = cur_amount
    await db.commit()
    await db.refresh(rate)
    return rate


@router.patch("/employees/{employee_id}", response_model=EmployeeOut)
async def update_employee(employee_id: uuid.UUID, payload: EmployeeUpdate,
                          user: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Employee).where(Employee.id == employee_id))
    e = res.scalar_one_or_none()
    if not e:
        raise HTTPException(404, "Xodim topilmadi")
    old_amount = e.salary_amount or Decimal(0)
    old_type = e.salary_type
    fields = payload.model_dump(exclude_unset=True)
    for k, v in fields.items():
        setattr(e, k, v)
    # Stavka o'zgargan bo'lsa — tarixga bugundan yoziladi (eski oylar o'zgarmaydi).
    # Aniq sanali o'zgartirish uchun /salary-rates endpointidan foydalaning.
    salary_changed = (
        ("salary_amount" in fields and (e.salary_amount or Decimal(0)) != old_amount)
        or ("salary_type" in fields and e.salary_type != old_type)
    )
    if salary_changed:
        db.add(SalaryRate(
            employee_id=e.id, effective_from=date.today(),
            salary_type=e.salary_type, amount=e.salary_amount or Decimal(0),
            currency=e.currency, created_by_id=user.id,
        ))
    await db.commit()
    await db.refresh(e)
    pos_map = await _positions_map(db)
    return _emp_out(e, pos_map.get(e.position_id))


# ---- Attendance ----
@router.get("/attendance", response_model=list[AttendanceOut])
async def list_attendance(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    employee_id: Optional[uuid.UUID] = None,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    q = select(Attendance)
    if employee_id:
        q = q.where(Attendance.employee_id == employee_id)
    if date_from:
        q = q.where(Attendance.work_date >= date_from)
    if date_to:
        q = q.where(Attendance.work_date <= date_to)
    res = await db.execute(q.order_by(Attendance.work_date.desc()).limit(1000))
    return [AttendanceOut.model_validate(a) for a in res.scalars().all()]


@router.post("/attendance/batch", response_model=list[AttendanceOut])
async def upsert_attendance_batch(payload: AttendanceBatchIn, user: CurrentUser,
                                  db: Annotated[AsyncSession, Depends(get_db)]):
    out = []
    for entry in payload.entries:
        # Calculate hours
        hours = Decimal(0)
        if entry.check_in and entry.check_out:
            t_in = datetime.combine(entry.work_date, entry.check_in)
            t_out = datetime.combine(entry.work_date, entry.check_out)
            hours = Decimal(str((t_out - t_in).total_seconds() / 3600)).quantize(Decimal("0.01"))

        # O'sha kundagi (work_date) stavka bilan hisoblaymiz — eski oylar o'zgarmaydi
        emp_res = await db.execute(select(Employee).where(Employee.id == entry.employee_id))
        emp = emp_res.scalar_one_or_none()
        daily_pay = Decimal(0)
        if emp:
            rate_type, rate_amount = await _rate_on(db, emp, entry.work_date)
            if rate_type == "hourly":
                daily_pay = rate_amount * hours

        # Upsert
        existing_res = await db.execute(
            select(Attendance).where(
                and_(Attendance.employee_id == entry.employee_id,
                     Attendance.work_date == entry.work_date)
            )
        )
        rec = existing_res.scalar_one_or_none()
        if rec:
            rec.check_in = entry.check_in
            rec.check_out = entry.check_out
            rec.hours_worked = hours
            rec.daily_pay = daily_pay
            rec.note = entry.note
            rec.entered_by_id = user.id
        else:
            rec = Attendance(
                employee_id=entry.employee_id, work_date=entry.work_date,
                check_in=entry.check_in, check_out=entry.check_out,
                hours_worked=hours, daily_pay=daily_pay, note=entry.note,
                entered_by_id=user.id,
            )
            db.add(rec)
        out.append(rec)
    await db.commit()
    for r in out:
        await db.refresh(r)
    return [AttendanceOut.model_validate(r) for r in out]


# ---- Salary advances ----
@router.get("/advances", response_model=list[SalaryAdvanceOut])
async def list_advances(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    employee_id: Optional[uuid.UUID] = None,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    q = select(SalaryAdvance)
    if employee_id:
        q = q.where(SalaryAdvance.employee_id == employee_id)
    if date_from:
        q = q.where(SalaryAdvance.advance_date >= date_from)
    if date_to:
        q = q.where(SalaryAdvance.advance_date <= date_to)
    res = await db.execute(q.order_by(SalaryAdvance.advance_date.desc()).limit(500))
    return [SalaryAdvanceOut.model_validate(a) for a in res.scalars().all()]


@router.post("/advances", response_model=SalaryAdvanceOut, status_code=201)
async def create_advance(payload: SalaryAdvanceIn, user: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    adv = SalaryAdvance(created_by_id=user.id, **payload.model_dump())
    db.add(adv)
    await db.commit()
    await db.refresh(adv)
    return adv


@router.delete("/advances/{advance_id}", response_model=SalaryAdvanceOut)
async def void_advance(advance_id: uuid.UUID, _user: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    """Avans/oylik to'lovini bekor qiladi (yumshoq o'chirish).

    Yozuv tarixda 'void' statusi bilan qoladi (real holatga ta'sir qilmaydi).
    Bog'liq moliya chiqim tranzaksiyasi teskari qaytariladi va o'chiriladi.
    """
    from app.models.finance import FinanceTransaction
    from app.services.finance_service import apply_transaction

    res = await db.execute(select(SalaryAdvance).where(SalaryAdvance.id == advance_id))
    adv = res.scalar_one_or_none()
    if not adv:
        raise HTTPException(404, "Avans topilmadi")
    if adv.status == "void":
        return SalaryAdvanceOut.model_validate(adv)

    adv.status = "void"
    # Moliya tranzaksiyasini teskari qaytarib o'chiramiz (balans tiklanadi)
    if adv.tx_id:
        tx_res = await db.execute(
            select(FinanceTransaction).where(FinanceTransaction.id == adv.tx_id)
        )
        tx = tx_res.scalar_one_or_none()
        if tx:
            await apply_transaction(db, tx, reverse=True)
            await db.delete(tx)
        adv.tx_id = None
    await db.commit()
    await db.refresh(adv)
    return SalaryAdvanceOut.model_validate(adv)


# ---- Employee loans (bizdan qarzdor xodimlar) ----
def _loan_out(loan: EmployeeLoan, payments: list[EmployeeLoanPayment]) -> EmployeeLoanOut:
    """Qarzni qoldiq va to'lov tarixi bilan chiqarish obyektiga aylantiradi."""
    paid = sum((p.amount or Decimal(0) for p in payments), Decimal(0))
    out = EmployeeLoanOut.model_validate(loan)
    out.paid = paid
    out.balance = (loan.amount or Decimal(0)) - paid
    out.payments = [
        EmployeeLoanPaymentOut.model_validate(p)
        for p in sorted(payments, key=lambda x: x.pay_date, reverse=True)
    ]
    return out


@router.get("/employee-loans", response_model=list[EmployeeLoanGroup])
async def list_employee_loans(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
):
    """Bizdan qarzdor xodimlar — har bir xodim ostida qarzlari va so'ndirish tarixi.

    Faqat status='active' qarzlar; jami qoldig'i > 0 bo'lgan xodimlar ko'rsatiladi,
    jami qoldiq bo'yicha kamayuvchi tartibda.
    """
    res = await db.execute(
        select(EmployeeLoan, Employee.full_name, Employee.department_type)
        .join(Employee, Employee.id == EmployeeLoan.employee_id)
        .where(EmployeeLoan.status == "active")
        .order_by(EmployeeLoan.loan_date.desc())
    )
    rows = res.all()
    loan_ids = [loan.id for loan, _, _ in rows]

    # Barcha to'lovlarni bitta so'rovda olib, qarz bo'yicha guruhlaymiz (N+1 dan qochish)
    payments_by_loan: dict[uuid.UUID, list[EmployeeLoanPayment]] = {}
    if loan_ids:
        pres = await db.execute(
            select(EmployeeLoanPayment).where(EmployeeLoanPayment.loan_id.in_(loan_ids))
        )
        for p in pres.scalars().all():
            payments_by_loan.setdefault(p.loan_id, []).append(p)

    groups: dict[uuid.UUID, EmployeeLoanGroup] = {}
    for loan, full_name, dept in rows:
        item = _loan_out(loan, payments_by_loan.get(loan.id, []))
        g = groups.get(loan.employee_id)
        if g is None:
            g = EmployeeLoanGroup(
                employee_id=loan.employee_id, full_name=full_name,
                department_type=dept or "production", total=Decimal(0), items=[],
            )
            groups[loan.employee_id] = g
        g.items.append(item)
        g.total += item.balance

    # Faqat hozir qarzi bor (qoldiq > 0) xodimlar
    result = [g for g in groups.values() if g.total > 0]
    return sorted(result, key=lambda x: x.total, reverse=True)


@router.post("/employee-loans", response_model=EmployeeLoanOut, status_code=201)
async def create_employee_loan(payload: EmployeeLoanIn, user: CurrentUser,
                               db: Annotated[AsyncSession, Depends(get_db)]):
    emp = (await db.execute(
        select(Employee.id).where(Employee.id == payload.employee_id)
    )).scalar_one_or_none()
    if not emp:
        raise HTTPException(404, "Xodim topilmadi")
    if payload.amount is None or payload.amount <= 0:
        raise HTTPException(422, "Summa 0 dan katta bo'lishi kerak")
    data = payload.model_dump()
    data["loan_date"] = data.get("loan_date") or date.today()
    loan = EmployeeLoan(created_by_id=user.id, **data)
    db.add(loan)
    await db.commit()
    await db.refresh(loan)
    return _loan_out(loan, [])


@router.patch("/employee-loans/{loan_id}", response_model=EmployeeLoanOut)
async def update_employee_loan(loan_id: uuid.UUID, payload: EmployeeLoanUpdate,
                               _user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(EmployeeLoan).where(EmployeeLoan.id == loan_id))
    loan = res.scalar_one_or_none()
    if not loan:
        raise HTTPException(404, "Qarz topilmadi")
    for field in ("amount", "source", "loan_date", "note", "status"):
        val = getattr(payload, field, None)
        if val is not None:
            setattr(loan, field, val)
    await db.commit()
    await db.refresh(loan)
    pres = await db.execute(
        select(EmployeeLoanPayment).where(EmployeeLoanPayment.loan_id == loan.id)
    )
    return _loan_out(loan, list(pres.scalars().all()))


@router.delete("/employee-loans/{loan_id}", status_code=204)
async def delete_employee_loan(loan_id: uuid.UUID, _user: CurrentUser,
                               db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(EmployeeLoan).where(EmployeeLoan.id == loan_id))
    loan = res.scalar_one_or_none()
    if loan:
        await db.delete(loan)  # to'lovlar CASCADE bilan o'chadi
        await db.commit()


# ---- Qarzni so'ndirish (qaytarish) — ichki tarix ----
@router.post("/employee-loans/{loan_id}/payments",
             response_model=EmployeeLoanPaymentOut, status_code=201)
async def add_loan_payment(loan_id: uuid.UUID, payload: EmployeeLoanPaymentIn,
                           user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]):
    """Qarzga so'ndirish (to'lov) yozadi. Qoldiqdan ortiq to'lov rad etiladi."""
    res = await db.execute(select(EmployeeLoan).where(EmployeeLoan.id == loan_id))
    loan = res.scalar_one_or_none()
    if not loan:
        raise HTTPException(404, "Qarz topilmadi")
    if payload.amount is None or payload.amount <= 0:
        raise HTTPException(422, "Summa 0 dan katta bo'lishi kerak")

    pres = await db.execute(
        select(func.coalesce(func.sum(EmployeeLoanPayment.amount), 0))
        .where(EmployeeLoanPayment.loan_id == loan_id)
    )
    paid = pres.scalar() or Decimal(0)
    balance = (loan.amount or Decimal(0)) - paid
    if payload.amount > balance:
        raise HTTPException(
            400, f"To'lov qoldiqdan oshib ketdi. Qoldiq: {balance:,.0f}".replace(",", " "))

    pay = EmployeeLoanPayment(
        loan_id=loan_id,
        amount=payload.amount,
        pay_date=payload.pay_date or date.today(),
        note=payload.note,
        created_by_id=user.id,
    )
    db.add(pay)
    # To'liq so'ndirilsa — qarzni yopilgan deb belgilaymiz (ro'yxatdan tushadi, tarix qoladi)
    if payload.amount >= balance:
        loan.status = "closed"
    await db.commit()
    await db.refresh(pay)
    return pay


@router.delete("/employee-loans/{loan_id}/payments/{payment_id}", status_code=204)
async def delete_loan_payment(loan_id: uuid.UUID, payment_id: uuid.UUID,
                              _user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]):
    """So'ndirishni bekor qiladi (o'chiradi). Qarz qaytadan ochiq (active) bo'ladi."""
    res = await db.execute(
        select(EmployeeLoanPayment).where(
            EmployeeLoanPayment.id == payment_id,
            EmployeeLoanPayment.loan_id == loan_id,
        )
    )
    pay = res.scalar_one_or_none()
    if not pay:
        return
    await db.delete(pay)
    # Qarz yopilgan bo'lsa, to'lov o'chgach qoldiq paydo bo'ladi — qayta ochamiz
    loan_res = await db.execute(select(EmployeeLoan).where(EmployeeLoan.id == loan_id))
    loan = loan_res.scalar_one_or_none()
    if loan and loan.status == "closed":
        loan.status = "active"
    await db.commit()


# ---- Payroll ----
@router.post("/payroll/runs", response_model=PayrollRunOut, status_code=201)
async def create_payroll_run(payload: PayrollRunIn, user: CurrentUser,
                             db: Annotated[AsyncSession, Depends(get_db)]):
    run = PayrollRun(created_by_id=user.id, **payload.model_dump())
    db.add(run)
    await db.flush()

    # For each employee, calculate gross/advance/net for the period
    emps_res = await db.execute(select(Employee).where(Employee.status == "active"))
    employees = emps_res.scalars().all()
    for e in employees:
        # Sum hours and daily pay from attendance in period
        att_res = await db.execute(
            select(func.coalesce(func.sum(Attendance.hours_worked), 0),
                   func.coalesce(func.sum(Attendance.daily_pay), 0))
            .where(and_(
                Attendance.employee_id == e.id,
                Attendance.work_date >= payload.period_start,
                Attendance.work_date <= payload.period_end,
            ))
        )
        hours, gross = att_res.one()
        if e.salary_type == "fixed":
            gross = e.salary_amount

        adv_res = await db.execute(
            select(func.coalesce(func.sum(SalaryAdvance.amount), 0))
            .where(and_(
                SalaryAdvance.employee_id == e.id,
                SalaryAdvance.advance_date >= payload.period_start,
                SalaryAdvance.advance_date <= payload.period_end,
                SalaryAdvance.status == "active",
            ))
        )
        advance = adv_res.scalar() or Decimal(0)
        net = Decimal(gross or 0) - Decimal(advance or 0)
        db.add(PayrollItem(
            run_id=run.id, employee_id=e.id,
            hours=hours or Decimal(0),
            gross=Decimal(gross or 0), advance=advance, net=net,
        ))
    await db.commit()
    await db.refresh(run)

    # Eager load items
    items_res = await db.execute(select(PayrollItem).where(PayrollItem.run_id == run.id))
    items = items_res.scalars().all()
    return PayrollRunOut(
        id=run.id, period_start=run.period_start, period_end=run.period_end,
        status=run.status, items=[
            __import__("app.schemas.hr", fromlist=["PayrollItemOut"]).PayrollItemOut.model_validate(i)
            for i in items
        ],
    )
