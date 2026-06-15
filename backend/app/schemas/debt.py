"""Bizning qarzlar — Pydantic sxemalar."""
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase


# ---------------------------------------------------------------------------
# Ehtiyot qism (mahsulot)
# ---------------------------------------------------------------------------
class DebtProductCreate(BaseModel):
    name: str
    debt_type: str = "product"  # "product" yoki ixtiyoriy tur (credit/loan/custom)
    unit: str = "dona"
    unit_price: float = 0
    currency: str = "UZS"
    supplier: Optional[str] = None
    note: Optional[str] = None


class DebtProductUpdate(BaseModel):
    name: Optional[str] = None
    debt_type: Optional[str] = None
    unit: Optional[str] = None
    unit_price: Optional[float] = None
    currency: Optional[str] = None
    supplier: Optional[str] = None
    note: Optional[str] = None


class DebtProductOut(ORMBase):
    id: uuid.UUID
    name: str
    debt_type: str = "product"
    unit: str
    unit_price: float
    currency: str = "UZS"
    supplier: Optional[str] = None
    note: Optional[str] = None
    created_at: datetime
    # Hisoblangan qiymatlar
    total_purchased: float = 0
    total_paid: float = 0
    balance: float = 0
    last_purchase_at: Optional[datetime] = None
    tx_count: int = 0


# ---------------------------------------------------------------------------
# Tranzaksiyalar
# ---------------------------------------------------------------------------
class PurchaseCreate(BaseModel):
    """Qarzni oshirish.

    Mahsulot turida: qty (+ ixtiyoriy unit_price) → summa = qty × narx.
    Boshqa turlarda (kredit/qarz/custom): to'g'ridan-to'g'ri amount.
    """
    qty: Optional[float] = Field(default=None, gt=0)
    unit_price: Optional[float] = None  # bo'lmasa mahsulot narxi olinadi
    amount: Optional[float] = Field(default=None, gt=0)  # mahsulot bo'lmaganda
    note: Optional[str] = None


class PaymentCreate(BaseModel):
    """Qarz to'lash — qarzni kamaytiradi."""
    amount: float = Field(gt=0)
    note: Optional[str] = None


class DebtTransactionOut(ORMBase):
    id: uuid.UUID
    product_id: uuid.UUID
    kind: str
    qty: float
    unit_price: float
    amount: float
    currency: str = "UZS"
    note: Optional[str] = None
    created_at: datetime


# ---------------------------------------------------------------------------
# Umumiy hisob (card uchun) — har valyuta alohida
# ---------------------------------------------------------------------------
class CurrencyTotal(BaseModel):
    currency: str
    total_purchased: float = 0
    total_paid: float = 0
    total_balance: float = 0
    with_debt_count: int = 0


class DebtSummary(BaseModel):
    by_currency: list[CurrencyTotal] = []
    product_count: int = 0
