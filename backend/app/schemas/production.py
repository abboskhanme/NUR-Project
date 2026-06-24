"""Ishlab chiqarish (production) Pydantic sxemalari."""
import uuid
from datetime import date
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase

CATEGORIES = ("kotyol", "bunker", "garelka")


class RecordCreate(BaseModel):
    category: str
    production_date: Optional[date] = None
    quantity: int = Field(1, ge=1)
    # Faqat kotyol uchun
    product_id: Optional[uuid.UUID] = None
    bunker_direction: Optional[str] = None
    unit_code: Optional[str] = None
    notes: Optional[str] = None


class RecordUpdate(BaseModel):
    production_date: Optional[date] = None
    quantity: Optional[int] = Field(None, ge=1)
    product_id: Optional[uuid.UUID] = None
    bunker_direction: Optional[str] = None
    unit_code: Optional[str] = None
    notes: Optional[str] = None


class RecordOut(ORMBase):
    id: uuid.UUID
    category: str
    production_date: date
    quantity: int
    product_id: Optional[uuid.UUID] = None
    bunker_direction: Optional[str] = None
    unit_code: Optional[str] = None
    notes: Optional[str] = None
    # Model ma'lumotlari (kotyol uchun, product orqali)
    model: Optional[str] = None
    kvm: Optional[int] = None


class DaySummary(BaseModel):
    production_date: date
    kotyol: int = 0
    bunker: int = 0
    garelka: int = 0


class ProductionSummary(BaseModel):
    days: list[DaySummary]
    total_kotyol: int = 0
    total_bunker: int = 0
    total_garelka: int = 0
