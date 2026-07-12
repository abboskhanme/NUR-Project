"""HR: employees, attendance, advances, payroll."""
import calendar
import uuid
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, case, delete, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.hr import (
    Attendance, Department, Employee, EmployeeLoan, EmployeeLoanPayment,
    PayrollItem, PayrollRun, Position, SalaryAdjustment, SalaryAdvance,
    SalaryOverride, SalaryRate,
)
from app.schemas.common import Page
from app.schemas.hr import (
    AttendanceBatchIn, AttendanceOut,
    DepartmentCreate, DepartmentOut, DepartmentUpdate,
    EmployeeCreate, EmployeeLoanGroup, EmployeeLoanIn, EmployeeLoanOut,
    EmployeeLoanPaymentIn, EmployeeLoanPaymentOut, EmployeeLoanUpdate,
    EmployeeMonthSummary, EmployeeOut, EmployeeUpdate,
    LoanRepayFromSalaryIn, LoanRepayFromSalaryOut,
    MonthDebts, MonthHistoryItem, MonthlySummary,
    PayrollRunIn, PayrollRunOut,
    PositionCreate, PositionOut, PositionUpdate,
    SalaryAdjustmentIn, SalaryAdjustmentOut,
    SalaryAdvanceIn, SalaryAdvanceOut,
    SalaryOverrideIn, SalaryOverrideOut,
    SalaryRateOut,
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
                     rate_type: str, rate_amount: Decimal,
                     adj_delta: Decimal = Decimal(0),
                     override: Optional[Decimal] = None) -> Decimal:
    """Joriy oy uchun olinishi mumkin bo'lgan MAKSIMAL oylik (taxminiy).

    - override belgilangan bo'lsa: o'sha oyning oyligi qat'iy (almashtirilgan)
      summa + bonus/jarima tuzatishi (davomatga qarab proyeksiya qilinmaydi).
    - fixed: belgilangan oylik (o'zgarmas) + shu oy bonus/jarima tuzatishi.
    - soatbay (va boshqalar): o'tgan kunlardagi haqiqiy hisoblangan haq +
      qolgan ish kunlari to'liq kelganda hisoblanadigan haq.
      To'liq kun haqi = stavka × STANDARD_WORKDAY_HOURS.
      Qolgan kunlar = bugundan keyin oy oxirigacha bo'lgan ish kunlari (yakshanbasiz).
      Bu holatda `gross_actual` allaqachon bonus/jarima tuzatishini o'z ichiga oladi.

    `adj_delta` — shu oy bonus (musbat) va jarima (manfiy) yig'indisi.
    """
    # Muayyan oy oyligi belgilangan bo'lsa — proyeksiyasiz, qat'iy summa.
    if override is not None:
        return override + adj_delta
    # Shu oyning tarixiy tipiga tayanamiz (`rate_type`) — joriy emp.salary_type emas,
    # aks holda tip o'zgarган xodimda o'tgan oy noto'g'ri hisoblanardi.
    if rate_type == "fixed":
        return (rate_amount or emp.salary_amount or Decimal(0)) + adj_delta

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


async def _ensure_baseline_rate(db: AsyncSession, emp: Employee, before: date) -> None:
    """Yangi stavka qo'shishdan OLDIN — agar xodimning stavka tarixi umuman bo'lmasa,
    joriy (eski) stavkani tarixga "boshlang'ich" yozuv sifatida kiritadi.

    Busiz: birinchi marta stavka ko'tarilganda oldingi oylar `_rate_on` fallback
    orqali jonli `salary_amount`ga (ya'ni YANGI summaga) qaytib ketib, eski oylar
    ham o'zgarib qolar edi. Boshlang'ich yozuv effektiv sanasi — ish boshlagan sana,
    ammo har doim `before` (yangi stavka sanasi)'dan OLDIN bo'ladi, aks holda yangi
    stavka joriy oyda boshlang'ich yozuv bilan ustma-ust tushib qolardi.
    """
    exists = await db.execute(
        select(SalaryRate.id).where(SalaryRate.employee_id == emp.id).limit(1)
    )
    if exists.scalar_one_or_none():
        return
    eff = emp.hire_date or date(2000, 1, 1)
    if eff >= before:
        eff = before - timedelta(days=1)
    db.add(SalaryRate(
        employee_id=emp.id,
        effective_from=eff,
        salary_type=emp.salary_type,
        amount=emp.salary_amount or Decimal(0),
        currency=emp.currency,
    ))
    await db.flush()


async def _month_adjustments(db: AsyncSession, emp: Employee, year: int, month: int):
    """Shu oy uchun faol bonus va jarima yig'indilari: (bonus, penalty). Ikkalasi ham musbat."""
    res = await db.execute(
        select(
            func.coalesce(func.sum(
                case((SalaryAdjustment.kind == "bonus", SalaryAdjustment.amount), else_=0)), 0),
            func.coalesce(func.sum(
                case((SalaryAdjustment.kind == "penalty", SalaryAdjustment.amount), else_=0)), 0),
        ).where(and_(
            SalaryAdjustment.employee_id == emp.id,
            SalaryAdjustment.year == year,
            SalaryAdjustment.month == month,
            SalaryAdjustment.status == "active",
        ))
    )
    bonus, penalty = res.one()
    return Decimal(bonus or 0), Decimal(penalty or 0)


async def _month_override(db: AsyncSession, emp: Employee, year: int, month: int) -> Optional[Decimal]:
    """Shu oy uchun belgilangan qat'iy oylik (agar bor bo'lsa) — aks holda None.

    Faqat status='active' yozuv hisobga olinadi. Har (xodim, oy) uchun bitta faol
    yozuv bo'lishi kutiladi; ehtiyot uchun eng oxirgi yaratilgani olinadi."""
    res = await db.execute(
        select(SalaryOverride.amount).where(and_(
            SalaryOverride.employee_id == emp.id,
            SalaryOverride.year == year,
            SalaryOverride.month == month,
            SalaryOverride.status == "active",
        )).order_by(SalaryOverride.created_at.desc()).limit(1)
    )
    val = res.scalar_one_or_none()
    return Decimal(val) if val is not None else None


async def _month_aggregate(db: AsyncSession, emp: Employee, year: int, month: int):
    """Bir oy uchun: kelgan kunlar, jami soat, gross, avans, net, bonus, jarima.

    Ish boshlagan sana (hire_date)'dan oldingi kunlar hisobga olinmaydi. Gross
    hisoblangan haqqa shu oy bonus qo'shilib, jarima ayirilgan holda qaytariladi.
    """
    start = date(year, month, 1)
    end = date(year, month, calendar.monthrange(year, month)[1])
    eff_start = max(start, emp.hire_date) if emp.hire_date else start
    if eff_start > end:
        return 0, Decimal(0), Decimal(0), Decimal(0), Decimal(0), Decimal(0), Decimal(0)

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
    # Shu oyda amal qilgan stavka (oy oxiriga ko'ra) — jonli salary_amount emas.
    # Shu sabab stavkani ko'targanda faqat shu oy va keyingilar o'zgaradi.
    # Tip HAM shu oyники (tarixiy) — xodim o'tmishda soatbay bo'lgan bo'lsa,
    # o'sha oy summasi davomatdan (daily_pay) olinadi, fixed sifatida emas.
    rate_type, rate_amount = await _rate_on(db, emp, end)
    if rate_type == "fixed":
        gross = rate_amount

    # Muayyan oy oyligi belgilangan bo'lsa — asosiy oylikni butunlay almashtiradi
    # (soatbayda ham davomat haqi o'rniga shu summa olinadi). Bonus/jarima esa
    # baribir ustiga qo'shiladi/ayiriladi.
    override = await _month_override(db, emp, year, month)
    if override is not None:
        gross = override

    # Bonus/jarima tuzatishi — hisoblangan oylikka qo'shiladi/ayiriladi
    bonus, penalty = await _month_adjustments(db, emp, year, month)
    gross = gross + bonus - penalty

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
    return int(present_days or 0), Decimal(hours or 0), gross, advance, net, bonus, penalty


async def advance_cap(db: AsyncSession, emp: Employee, year: int, month: int):
    """Avans limiti uchun: (tahminiy oylik max_gross, joriy faol avanslar yig'indisi).

    Ro'yxatdagi `month_summary.max_gross` bilan bir xil hisob — bittadan manba."""
    _, _, gross, advance, _, bonus, penalty = await _month_aggregate(db, emp, year, month)
    eom = date(year, month, calendar.monthrange(year, month)[1])
    rate_type, rate_amount = await _rate_on(db, emp, eom)
    override = await _month_override(db, emp, year, month)
    max_gross = _max_month_gross(emp, year, month, gross, rate_type, rate_amount,
                                 bonus - penalty, override)
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

    # Bonus/jarima tuzatishlari (emp, oy) bo'yicha — grossga qo'shiladi/ayiriladi
    adj_rows = (await db.execute(
        select(
            SalaryAdjustment.employee_id, SalaryAdjustment.month,
            func.coalesce(func.sum(
                case((SalaryAdjustment.kind == "bonus", SalaryAdjustment.amount), else_=0)), 0),
            func.coalesce(func.sum(
                case((SalaryAdjustment.kind == "penalty", SalaryAdjustment.amount), else_=0)), 0),
        ).where(and_(
            SalaryAdjustment.employee_id.in_(emp_ids),
            SalaryAdjustment.year == year,
            SalaryAdjustment.status == "active",
        )).group_by(SalaryAdjustment.employee_id, SalaryAdjustment.month)
    )).all()
    adj_map = {(r[0], int(r[1])): Decimal(r[2] or 0) - Decimal(r[3] or 0) for r in adj_rows}

    # Muayyan oy oyligi (override) — o'sha oyning asosiy oyligini almashtiradi.
    ov_rows = (await db.execute(
        select(SalaryOverride.employee_id, SalaryOverride.month, SalaryOverride.amount)
        .where(and_(
            SalaryOverride.employee_id.in_(emp_ids),
            SalaryOverride.year == year,
            SalaryOverride.status == "active",
        ))
    )).all()
    ov_map = {(r[0], int(r[1])): Decimal(r[2] or 0) for r in ov_rows}

    # Stavka tarixi (fixed xodimlar uchun) — har oy o'sha oyda amal qilgan stavka.
    # emp_id -> effective_from bo'yicha KAMAYUVCHI tartibda (eng yangisi birinchi).
    rate_rows = (await db.execute(
        select(SalaryRate.employee_id, SalaryRate.effective_from,
               SalaryRate.salary_type, SalaryRate.amount)
        .where(SalaryRate.employee_id.in_(emp_ids))
        .order_by(SalaryRate.effective_from.desc(), SalaryRate.created_at.desc())
    )).all()
    rates_map: dict = {}
    for emp_id, eff, rtype, amt in rate_rows:
        rates_map.setdefault(emp_id, []).append((eff, rtype, Decimal(amt or 0)))

    def _rate_on_batch(e: Employee, on_date: date):
        """`_rate_on` ning batch (DB'siz) varianti — (tip, summa) shu sanaга ko'ra."""
        for eff, rtype, amt in rates_map.get(e.id, ()):  # yangidan eskiga
            if eff <= on_date:
                return rtype, amt
        return e.salary_type, (e.salary_amount or Decimal(0))  # tarix bo'lmasa — jonli

    result: list[MonthDebts] = []
    for m in range(last_month, 0, -1):  # yangi oydan eskisiga
        month_end = date(year, m, calendar.monthrange(year, m)[1])
        items = []
        total = Decimal(0)
        for e in emps:
            if e.hire_date and e.hire_date > month_end:
                continue  # bu oyda hali ishlamagan
            rtype, ramount = _rate_on_batch(e, month_end)
            if rtype == "fixed":
                gross = ramount
            else:
                gross = gross_map.get((e.id, m), Decimal(0))
            ov = ov_map.get((e.id, m))
            if ov is not None:
                gross = ov
            gross += adj_map.get((e.id, m), Decimal(0))
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
            present, hours, gross, advance, net, bonus, penalty = await _month_aggregate(db, e, sy, sm)
            eom = date(sy, sm, calendar.monthrange(sy, sm)[1])
            rate_type, rate_amount = await _rate_on(db, e, eom)
            override = await _month_override(db, e, sy, sm)
            max_gross = _max_month_gross(e, sy, sm, gross, rate_type, rate_amount,
                                         bonus - penalty, override)
            out.month_summary = EmployeeMonthSummary(
                year=sy, month=sm, present_days=present, total_hours=hours,
                gross=gross, advance=advance, net=net, salary_type=rate_type,
                bonus=bonus, penalty=penalty, max_gross=max_gross,
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
    present, hours, gross, advance, net, bonus, penalty = await _month_aggregate(db, e, year, month)
    # O'sha oyda amal qilgan stavka (oy oxiriga ko'ra)
    eom = date(year, month, calendar.monthrange(year, month)[1])
    rate_type, rate_amount = await _rate_on(db, e, eom)
    return MonthlySummary(
        year=year, month=month, present_days=present, total_hours=hours,
        gross=gross, advance=advance, net=net,
        salary_type=rate_type, hourly_rate=rate_amount,
        bonus=bonus, penalty=penalty,
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
        present, hours, gross, advance, net, bonus, penalty = await _month_aggregate(db, e, y, m)
        out.append(MonthHistoryItem(
            year=y, month=m, present_days=present, total_hours=hours,
            gross=gross, advance=advance, net=net, bonus=bonus, penalty=penalty,
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
    # Stavka o'zgaradimi — mutatsiyadan OLDIN aniqlaymiz (payloadga qarab).
    salary_changed = (
        ("salary_amount" in fields and (fields["salary_amount"] or Decimal(0)) != old_amount)
        or ("salary_type" in fields and fields["salary_type"] != old_type)
    )
    # Yangi stavka JORIY OYNING BOSHIDAN amal qiladi — butun joriy oy yangi
    # summada, oldingi oylar esa avvalgi stavkada qoladi.
    month_start = date.today().replace(day=1)
    # Stavka o'zgarsa — avval ESKI stavkani boshlang'ich yozuv sifatida saqlab
    # qolamiz (tarix bo'sh bo'lsa), so'ng jonli qiymatlarni yangilaymiz.
    if salary_changed:
        await _ensure_baseline_rate(db, e, month_start)
    for k, v in fields.items():
        setattr(e, k, v)
    # Stavka o'zgargan bo'lsa — tarixga joriy oy boshidan yoziladi (eski oylar
    # o'zgarmaydi). Bu yozuvlar "Oylik tarixi" kartasida ko'rinadi.
    if salary_changed:
        # Joriy oy (va undan keyingi) mavjud stavka yozuvlarini o'chirib, bitta
        # toza yozuv qoldiramiz. Aks holda: (a) shu oyda yaratilgan xodimning
        # yaratilish-yozuvi (effective_from > oy boshi) tahrirni "yutib" yuborardi;
        # (b) bir oyda bir necha tahrir dublikat yozuvlar yaratardi.
        await db.execute(delete(SalaryRate).where(and_(
            SalaryRate.employee_id == e.id,
            SalaryRate.effective_from >= month_start,
        )))
        db.add(SalaryRate(
            employee_id=e.id, effective_from=month_start,
            salary_type=e.salary_type, amount=e.salary_amount or Decimal(0),
            currency=e.currency, created_by_id=user.id,
        ))
        # Soatbay/kunbay: joriy oyda allaqachon kiritilgan davomat haqini yangi
        # stavka bilan qayta hisoblaymiz (fixed uchun daily_pay ishlatilmaydi).
        if e.salary_type == "hourly":
            rate = e.salary_amount or Decimal(0)
            att = (await db.execute(select(Attendance).where(and_(
                Attendance.employee_id == e.id,
                Attendance.work_date >= month_start,
            )))).scalars().all()
            for a in att:
                a.daily_pay = rate * (a.hours_worked or Decimal(0))
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


# ---- Salary adjustments (jarima / bonus) ----
@router.get("/adjustments", response_model=list[SalaryAdjustmentOut])
async def list_adjustments(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    employee_id: Optional[uuid.UUID] = None,
    year: Optional[int] = None, month: Optional[int] = None,
    kind: Optional[str] = None,
):
    q = select(SalaryAdjustment)
    if employee_id:
        q = q.where(SalaryAdjustment.employee_id == employee_id)
    if year:
        q = q.where(SalaryAdjustment.year == year)
    if month:
        q = q.where(SalaryAdjustment.month == month)
    if kind:
        q = q.where(SalaryAdjustment.kind == kind)
    res = await db.execute(q.order_by(SalaryAdjustment.created_at.desc()).limit(500))
    return [SalaryAdjustmentOut.model_validate(a) for a in res.scalars().all()]


@router.post("/adjustments", response_model=SalaryAdjustmentOut, status_code=201)
async def create_adjustment(payload: SalaryAdjustmentIn, user: CurrentUser,
                            db: Annotated[AsyncSession, Depends(get_db)]):
    if payload.kind not in ("penalty", "bonus"):
        raise HTTPException(422, "Tur 'penalty' yoki 'bonus' bo'lishi kerak")
    if not (1 <= payload.month <= 12):
        raise HTTPException(422, "Oy 1–12 oralig'ida bo'lishi kerak")
    if not (2000 <= payload.year <= 2100):
        raise HTTPException(422, "Yil noto'g'ri")
    if (payload.amount or Decimal(0)) <= 0:
        raise HTTPException(422, "Summa noldan katta bo'lishi kerak")
    emp = (await db.execute(
        select(Employee).where(Employee.id == payload.employee_id)
    )).scalar_one_or_none()
    if not emp:
        raise HTTPException(404, "Xodim topilmadi")
    adj = SalaryAdjustment(created_by_id=user.id, **payload.model_dump())
    db.add(adj)
    await db.commit()
    await db.refresh(adj)
    return SalaryAdjustmentOut.model_validate(adj)


@router.delete("/adjustments/{adjustment_id}", response_model=SalaryAdjustmentOut)
async def void_adjustment(adjustment_id: uuid.UUID, _user: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    """Jarima/bonusni bekor qiladi (yumshoq o'chirish — tarixda 'void' bo'lib qoladi).

    Bekor qilingach o'sha oyning hisoblangan oyligiga ta'sir qilmaydi.
    """
    res = await db.execute(select(SalaryAdjustment).where(SalaryAdjustment.id == adjustment_id))
    adj = res.scalar_one_or_none()
    if not adj:
        raise HTTPException(404, "Yozuv topilmadi")
    if adj.status == "void":
        return SalaryAdjustmentOut.model_validate(adj)
    adj.status = "void"
    await db.commit()
    await db.refresh(adj)
    return SalaryAdjustmentOut.model_validate(adj)


# ---- Salary overrides (muayyan oy uchun oylik) ----
@router.get("/salary-overrides", response_model=list[SalaryOverrideOut])
async def list_salary_overrides(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    employee_id: Optional[uuid.UUID] = None,
    year: Optional[int] = None, month: Optional[int] = None,
    status: Optional[str] = "active",
):
    q = select(SalaryOverride)
    if employee_id:
        q = q.where(SalaryOverride.employee_id == employee_id)
    if year:
        q = q.where(SalaryOverride.year == year)
    if month:
        q = q.where(SalaryOverride.month == month)
    if status:
        q = q.where(SalaryOverride.status == status)
    res = await db.execute(
        q.order_by(SalaryOverride.year.desc(), SalaryOverride.month.desc(),
                   SalaryOverride.created_at.desc()).limit(500)
    )
    return [SalaryOverrideOut.model_validate(o) for o in res.scalars().all()]


@router.post("/salary-overrides", response_model=SalaryOverrideOut, status_code=201)
async def create_salary_override(payload: SalaryOverrideIn, user: CurrentUser,
                                 db: Annotated[AsyncSession, Depends(get_db)]):
    """Muayyan bir oy uchun oylikni belgilaydi (absolute). Faqat o'sha oy o'zgaradi.

    Shu (xodim, yil, oy) uchun faol yozuv allaqachon bo'lsa — o'rniga yangilanadi
    (bitta faol yozuv qoladi). Stavka tarixiga tegmaydi."""
    if not (1 <= payload.month <= 12):
        raise HTTPException(422, "Oy 1–12 oralig'ida bo'lishi kerak")
    if not (2000 <= payload.year <= 2100):
        raise HTTPException(422, "Yil noto'g'ri")
    if payload.amount is None or payload.amount < 0:
        raise HTTPException(422, "Summa manfiy bo'lishi mumkin emas")
    emp = (await db.execute(
        select(Employee).where(Employee.id == payload.employee_id)
    )).scalar_one_or_none()
    if not emp:
        raise HTTPException(404, "Xodim topilmadi")

    # Shu oy uchun mavjud faol override bo'lsa — o'rnini yangilaymiz (bitta faol yozuv)
    existing = (await db.execute(
        select(SalaryOverride).where(and_(
            SalaryOverride.employee_id == payload.employee_id,
            SalaryOverride.year == payload.year,
            SalaryOverride.month == payload.month,
            SalaryOverride.status == "active",
        ))
    )).scalars().all()
    if existing:
        ov = existing[0]
        ov.amount = payload.amount
        ov.currency = payload.currency
        ov.note = payload.note
        ov.created_by_id = user.id
        for extra in existing[1:]:  # ehtiyot: dublikat faol yozuvlarni yopamiz
            extra.status = "void"
    else:
        ov = SalaryOverride(created_by_id=user.id, **payload.model_dump())
        db.add(ov)
    await db.commit()
    await db.refresh(ov)
    return SalaryOverrideOut.model_validate(ov)


@router.delete("/salary-overrides/{override_id}", response_model=SalaryOverrideOut)
async def void_salary_override(override_id: uuid.UUID, _user: CurrentUser,
                               db: Annotated[AsyncSession, Depends(get_db)]):
    """Muayyan oy oyligini bekor qiladi (yumshoq o'chirish — tarixda 'void' bo'lib qoladi).

    Bekor qilingach o'sha oy yana standart stavka/davomat bo'yicha hisoblanadi.
    """
    res = await db.execute(select(SalaryOverride).where(SalaryOverride.id == override_id))
    ov = res.scalar_one_or_none()
    if not ov:
        raise HTTPException(404, "Yozuv topilmadi")
    if ov.status == "void":
        return SalaryOverrideOut.model_validate(ov)
    ov.status = "void"
    await db.commit()
    await db.refresh(ov)
    return SalaryOverrideOut.model_validate(ov)


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


# ---- Qarzni oylikdan so'ndirish (moliyaga tegmaydi) ----
@router.post("/employees/{employee_id}/repay-loan-from-salary",
             response_model=LoanRepayFromSalaryOut, status_code=201)
async def repay_loan_from_salary(employee_id: uuid.UUID, payload: LoanRepayFromSalaryIn,
                                 user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]):
    """Xodim qarzini uning oyligidan so'ndiradi — naqd pul harakati YO'Q, moliyaga tegmaydi.

    Kiritilgan summa:
    1) xodimning faol qarzlaridan eng eskisidan boshlab taqsimlab so'ndiriladi — har biri
       uchun qarz to'lovi (EmployeeLoanPayment) yoziladi, to'liq yopilsa qarz "closed" bo'ladi;
    2) o'sha summa xodim avansi sifatida qo'shiladi ("Qarzga to'landi" izohi bilan) — shunda
       joriy oyning qolgan oyligidan ayiriladi va avans ro'yxatida ko'rinadi.
    Moliya balansiga umuman ta'sir qilmaydi (avans tx_id'siz yoziladi).
    """
    amount = payload.amount or Decimal(0)
    if amount <= 0:
        raise HTTPException(422, "Summa 0 dan katta bo'lishi kerak")
    emp = (await db.execute(
        select(Employee).where(Employee.id == employee_id)
    )).scalar_one_or_none()
    if not emp:
        raise HTTPException(404, "Xodim topilmadi")

    loans = (await db.execute(
        select(EmployeeLoan).where(and_(
            EmployeeLoan.employee_id == employee_id,
            EmployeeLoan.status == "active",
        )).order_by(EmployeeLoan.loan_date, EmployeeLoan.created_at)
    )).scalars().all()
    if not loans:
        raise HTTPException(400, "Xodimda faol qarz yo'q")

    loan_ids = [ln.id for ln in loans]
    paid_rows = (await db.execute(
        select(EmployeeLoanPayment.loan_id,
               func.coalesce(func.sum(EmployeeLoanPayment.amount), 0))
        .where(EmployeeLoanPayment.loan_id.in_(loan_ids))
        .group_by(EmployeeLoanPayment.loan_id)
    )).all()
    paid_map = {lid: Decimal(s or 0) for lid, s in paid_rows}
    balances = {ln.id: (ln.amount or Decimal(0)) - paid_map.get(ln.id, Decimal(0)) for ln in loans}
    total_balance = sum(balances.values(), Decimal(0))
    if total_balance <= 0:
        raise HTTPException(400, "Xodimda so'ndiriladigan qarz yo'q")
    if amount > total_balance:
        raise HTTPException(
            400, f"Summa jami qarzdan oshib ketdi. Qoldiq: {total_balance:,.0f}".replace(",", " "))

    pay_date = payload.pay_date or date.today()
    remaining = amount
    count = 0
    for loan in loans:
        bal = balances[loan.id]
        if bal <= 0:
            continue
        pay_amt = min(bal, remaining)
        db.add(EmployeeLoanPayment(
            loan_id=loan.id, amount=pay_amt, pay_date=pay_date,
            note="Oylikdan so'ndirildi", created_by_id=user.id,
        ))
        count += 1
        if pay_amt >= bal:  # to'liq so'ndirildi — qarz yopiladi
            loan.status = "closed"
        remaining -= pay_amt
        if remaining <= 0:
            break

    # Oylikdan ayirish uchun avans yozuvi — moliyaga tegmaydi (tx_id yo'q)
    adv = SalaryAdvance(
        employee_id=employee_id, advance_date=pay_date, amount=amount,
        currency=emp.currency or "UZS", note=payload.note or "Qarzga to'landi",
        status="active", tx_id=None, created_by_id=user.id,
    )
    db.add(adv)
    await db.flush()
    advance_id = adv.id
    await db.commit()
    return LoanRepayFromSalaryOut(
        paid=amount, remaining_debt=total_balance - amount,
        advance_id=advance_id, payments_count=count,
    )


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
