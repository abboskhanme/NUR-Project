"""Maqsadlar — Pydantic sxemalar."""
import uuid
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase


# ---------------------------------------------------------------------------
# Maqsad
# ---------------------------------------------------------------------------
class TargetCreate(BaseModel):
    name: str
    target_amount: float = Field(gt=0)
    currency: str = "UZS"
    deadline: Optional[date] = None
    note: Optional[str] = None


class TargetUpdate(BaseModel):
    name: Optional[str] = None
    target_amount: Optional[float] = Field(default=None, gt=0)
    currency: Optional[str] = None
    deadline: Optional[date] = None
    note: Optional[str] = None


class TargetOut(ORMBase):
    id: uuid.UUID
    name: str
    target_amount: float
    currency: str = "UZS"
    deadline: Optional[date] = None
    note: Optional[str] = None
    created_at: datetime
    # Hisoblangan qiymatlar
    saved_amount: float = 0
    remaining: float = 0
    progress: float = 0  # 0..100
    is_completed: bool = False
    last_contribution_at: Optional[datetime] = None
    contribution_count: int = 0


# ---------------------------------------------------------------------------
# Qo'shimchalar (summa qo'shish)
# ---------------------------------------------------------------------------
class ContributionCreate(BaseModel):
    """Maqsadga summa qo'shish."""
    amount: float = Field(gt=0)
    note: Optional[str] = None


class TargetContributionOut(ORMBase):
    id: uuid.UUID
    target_id: uuid.UUID
    amount: float
    currency: str = "UZS"
    note: Optional[str] = None
    created_at: datetime


# ---------------------------------------------------------------------------
# Umumiy hisob (card uchun) — har valyuta alohida
# ---------------------------------------------------------------------------
class TargetCurrencyTotal(BaseModel):
    currency: str
    total_target: float = 0
    total_saved: float = 0
    total_remaining: float = 0
    target_count: int = 0
    completed_count: int = 0


class TargetSummary(BaseModel):
    by_currency: list[TargetCurrencyTotal] = []
    target_count: int = 0
