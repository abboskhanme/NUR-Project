"""Finance schemas."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class AccountBase(BaseModel):
    name: str
    currency: str = "UZS"
    ledger: str = "operational"


class AccountCreate(AccountBase):
    balance: Decimal = Decimal(0)


class AccountOut(ORMBase):
    id: uuid.UUID
    name: str
    currency: str
    ledger: str
    balance: Decimal


class CategoryBase(BaseModel):
    name: str
    kind: str = "expense"  # income/expense
    parent_id: Optional[uuid.UUID] = None
    code: Optional[str] = None


class CategoryCreate(CategoryBase):
    pass


class CategoryOut(ORMBase):
    id: uuid.UUID
    name: str
    kind: str
    parent_id: Optional[uuid.UUID] = None
    code: Optional[str] = None


class TransactionBase(BaseModel):
    date: date
    type: str  # income/expense/transfer
    category_id: Optional[uuid.UUID] = None
    amount: Decimal
    currency: str = "UZS"
    amount_other_curr: Decimal = Decimal(0)
    account_id: Optional[uuid.UUID] = None
    related_order_id: Optional[uuid.UUID] = None
    note: Optional[str] = None


class TransactionCreate(TransactionBase):
    pass


class TransactionOut(ORMBase):
    id: uuid.UUID
    date: date
    type: str
    category_id: Optional[uuid.UUID] = None
    amount: Decimal
    currency: str
    amount_other_curr: Decimal
    account_id: Optional[uuid.UUID] = None
    related_order_id: Optional[uuid.UUID] = None
    note: Optional[str] = None
    status: str = "active"
    created_at: datetime
    # embed qilingan nomlar (ro'yxat jadvali uchun)
    category_name: Optional[str] = None
    account_name: Optional[str] = None


class ExchangeRateBase(BaseModel):
    date: date
    usd_to_uzs: Decimal
    source: str = "manual"


class ExchangeRateOut(ORMBase):
    id: uuid.UUID
    date: date
    usd_to_uzs: Decimal
    source: str


class BalanceSummary(BaseModel):
    uzs: Decimal
    usd: Decimal
    gazna: Decimal
    last_updated: datetime


class EmployeePaymentIn(BaseModel):
    employee_id: uuid.UUID
    kind: str  # 'advance' (avans) | 'salary' (oylik)
    amount: Optional[Decimal] = None  # avans uchun majburiy; oylikda backend hisoblaydi
    year: int
    month: int
    date: Optional[date] = None  # ko'rsatilmasa: oyga mos sana
    currency: str = "UZS"
    note: Optional[str] = None


class CategoryBreakdown(BaseModel):
    type: str
    category_name: str
    total: Decimal


class FinanceSummary(BaseModel):
    year: int
    month: int
    income_total: Decimal
    expense_total: Decimal
    net: Decimal
    usd_income_total: Decimal = Decimal(0)
    usd_expense_total: Decimal = Decimal(0)
    by_category: list[CategoryBreakdown]
