"""HR: employees, departments, positions, attendance, payroll."""
import uuid
from datetime import date, time
from decimal import Decimal
from typing import Optional

from sqlalchemy import Boolean, Date, ForeignKey, Numeric, String, Text, Time, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Department(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "departments"

    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)


class Position(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "positions"

    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    department_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("departments.id", ondelete="SET NULL")
    )


class Employee(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "employees"

    full_name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    phone: Mapped[Optional[str]] = mapped_column(String(30))
    secondary_phone: Mapped[Optional[str]] = mapped_column(String(30))
    birth_date: Mapped[Optional[date]] = mapped_column(Date)
    address: Mapped[Optional[str]] = mapped_column(Text)

    position_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("positions.id", ondelete="SET NULL")
    )

    hire_date: Mapped[Optional[date]] = mapped_column(Date)
    # office/worker
    employment_type: Mapped[str] = mapped_column(String(20), default="worker")
    # Xodim turi/bo'limi: office (ofis xodimi) / assembly (yig'uv) / production (ishlab chiqarish)
    department_type: Mapped[str] = mapped_column(
        String(20), default="production", server_default="production"
    )
    # hourly/daily/fixed/kpi
    salary_type: Mapped[str] = mapped_column(String(20), default="hourly")
    salary_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")

    # active/terminated/leave
    status: Mapped[str] = mapped_column(String(20), default="active")
    has_account: Mapped[bool] = mapped_column(Boolean, default=False)
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class SalaryRate(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Xodim oylik stavkasi tarixi — qaysi sanadan qancha.

    Hisob-kitob har bir kun uchun o'sha kunda amal qilgan stavka bilan bajariladi,
    shuning uchun stavka ko'tarilsa eski oylarning hisobi o'zgarmaydi.
    """
    __tablename__ = "salary_rates"

    employee_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), index=True
    )
    effective_from: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    salary_type: Mapped[str] = mapped_column(String(20), default="hourly")
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class Attendance(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "attendance"
    __table_args__ = (UniqueConstraint("employee_id", "work_date", name="uq_employee_date"),)

    employee_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), index=True
    )
    work_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    check_in: Mapped[Optional[time]] = mapped_column(Time)
    check_out: Mapped[Optional[time]] = mapped_column(Time)
    hours_worked: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=0)
    daily_pay: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    note: Mapped[Optional[str]] = mapped_column(Text)

    entered_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class SalaryAdvance(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "salary_advances"

    employee_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), index=True
    )
    advance_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    note: Mapped[Optional[str]] = mapped_column(Text)
    # "active" yoki "void" (noto'g'ri kiritilgan — bekor qilingan, lekin tarixda qoladi)
    status: Mapped[str] = mapped_column(String(10), default="active", server_default="active")
    # Bog'liq moliya tranzaksiyasi (bekor qilinganda teskari qaytarish uchun)
    tx_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), nullable=True)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class PayrollRun(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "payroll_runs"

    period_start: Mapped[date] = mapped_column(Date, nullable=False)
    period_end: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="draft")  # draft/approved/paid
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    approved_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class PayrollItem(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "payroll_items"

    run_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("payroll_runs.id", ondelete="CASCADE"), index=True
    )
    employee_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("employees.id", ondelete="RESTRICT")
    )
    hours: Mapped[Decimal] = mapped_column(Numeric(7, 2), default=0)
    gross: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    advance: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    net: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
