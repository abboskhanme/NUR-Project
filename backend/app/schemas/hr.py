"""HR schemas."""
import uuid
from datetime import date, datetime, time
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


# ---- Departments ----
class DepartmentCreate(BaseModel):
    name: str


class DepartmentUpdate(BaseModel):
    name: Optional[str] = None


class DepartmentOut(ORMBase):
    id: uuid.UUID
    name: str


# ---- Positions (lavozimlar) ----
class PositionCreate(BaseModel):
    name: str
    department_id: Optional[uuid.UUID] = None


class PositionUpdate(BaseModel):
    name: Optional[str] = None
    department_id: Optional[uuid.UUID] = None


class PositionOut(ORMBase):
    id: uuid.UUID
    name: str
    department_id: Optional[uuid.UUID] = None


# ---- Salary rates (stavka tarixi) ----
class SalaryRateCreate(BaseModel):
    effective_from: date
    salary_type: str = "hourly"
    amount: Decimal
    currency: str = "UZS"
    note: Optional[str] = None


class SalaryRateOut(ORMBase):
    id: uuid.UUID
    employee_id: uuid.UUID
    effective_from: date
    salary_type: str
    amount: Decimal
    currency: str
    note: Optional[str] = None
    created_at: datetime


class EmployeeBase(BaseModel):
    full_name: str
    phone: Optional[str] = None
    secondary_phone: Optional[str] = None
    birth_date: Optional[date] = None
    address: Optional[str] = None
    position_id: Optional[uuid.UUID] = None
    hire_date: Optional[date] = None
    employment_type: str = "worker"
    department_type: str = "production"
    salary_type: str = "hourly"
    salary_amount: Decimal = Decimal(0)
    currency: str = "UZS"
    status: str = "active"
    has_account: bool = False


class EmployeeCreate(EmployeeBase):
    pass


class EmployeeUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    secondary_phone: Optional[str] = None
    birth_date: Optional[date] = None
    address: Optional[str] = None
    position_id: Optional[uuid.UUID] = None
    hire_date: Optional[date] = None
    employment_type: Optional[str] = None
    department_type: Optional[str] = None
    salary_type: Optional[str] = None
    salary_amount: Optional[Decimal] = None
    status: Optional[str] = None


class EmployeeMonthSummary(BaseModel):
    """Ro'yxatda ko'rsatish uchun joriy oy bo'yicha qisqacha hisob."""
    year: int
    month: int
    present_days: int
    total_hours: Decimal
    gross: Decimal
    advance: Decimal
    net: Decimal
    salary_type: str


class EmployeeOut(ORMBase):
    id: uuid.UUID
    full_name: str
    phone: Optional[str] = None
    secondary_phone: Optional[str] = None
    birth_date: Optional[date] = None
    address: Optional[str] = None
    position_id: Optional[uuid.UUID] = None
    position_name: Optional[str] = None
    hire_date: Optional[date] = None
    employment_type: str
    department_type: str = "production"
    salary_type: str
    salary_amount: Decimal
    currency: str
    status: str
    has_account: bool
    user_id: Optional[uuid.UUID] = None
    created_at: datetime
    # Ro'yxatda yig'ma ko'rsatkichlar (with_summary=true bo'lganda to'ldiriladi)
    month_summary: Optional[EmployeeMonthSummary] = None


class AttendanceIn(BaseModel):
    employee_id: uuid.UUID
    work_date: date
    check_in: Optional[time] = None
    check_out: Optional[time] = None
    note: Optional[str] = None


class AttendanceBatchIn(BaseModel):
    entries: list[AttendanceIn]


class AttendanceOut(ORMBase):
    id: uuid.UUID
    employee_id: uuid.UUID
    work_date: date
    check_in: Optional[time] = None
    check_out: Optional[time] = None
    hours_worked: Decimal
    daily_pay: Decimal
    note: Optional[str] = None


class SalaryAdvanceIn(BaseModel):
    employee_id: uuid.UUID
    advance_date: date
    amount: Decimal
    currency: str = "UZS"
    note: Optional[str] = None


class SalaryAdvanceOut(ORMBase):
    id: uuid.UUID
    employee_id: uuid.UUID
    advance_date: date
    amount: Decimal
    currency: str
    note: Optional[str] = None
    status: str = "active"


class PayrollRunIn(BaseModel):
    period_start: date
    period_end: date


class PayrollItemOut(ORMBase):
    id: uuid.UUID
    employee_id: uuid.UUID
    hours: Decimal
    gross: Decimal
    advance: Decimal
    net: Decimal


class PayrollRunOut(ORMBase):
    id: uuid.UUID
    period_start: date
    period_end: date
    status: str
    items: list[PayrollItemOut] = []


# ---- Monthly summary / history (xodim detal sahifasi uchun) ----
class MonthlySummary(BaseModel):
    year: int
    month: int
    present_days: int
    total_hours: Decimal
    gross: Decimal
    advance: Decimal
    net: Decimal
    salary_type: str
    hourly_rate: Decimal


class MonthHistoryItem(BaseModel):
    year: int
    month: int
    present_days: int
    total_hours: Decimal
    gross: Decimal
    advance: Decimal
    net: Decimal
