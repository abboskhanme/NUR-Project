"""Ishlab chiqarish (production) Pydantic sxemalari."""
import uuid
from datetime import date
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase

CATEGORIES = ("kotyol", "bunker", "garelka", "tana")


class RecordCreate(BaseModel):
    category: str
    production_date: Optional[date] = None
    quantity: int = Field(1, ge=1)
    # Faqat kotyol uchun
    product_id: Optional[uuid.UUID] = None
    bunker_direction: Optional[str] = None
    unit_code: Optional[str] = None
    # Faqat tana (kotyol tanasi) uchun
    body_size: Optional[str] = None
    notes: Optional[str] = None


class RecordUpdate(BaseModel):
    production_date: Optional[date] = None
    quantity: Optional[int] = Field(None, ge=1)
    product_id: Optional[uuid.UUID] = None
    bunker_direction: Optional[str] = None
    unit_code: Optional[str] = None
    body_size: Optional[str] = None
    notes: Optional[str] = None


class RecordOut(ORMBase):
    id: uuid.UUID
    category: str
    production_date: date
    quantity: int
    product_id: Optional[uuid.UUID] = None
    bunker_direction: Optional[str] = None
    unit_code: Optional[str] = None
    body_size: Optional[str] = None
    notes: Optional[str] = None
    # Model ma'lumotlari (kotyol uchun, product orqali)
    model: Optional[str] = None
    kvm: Optional[int] = None
    # Ushbu kotyol ombor skladiga o'tkazilganmi (bir marta o'tkazilгач doimiy)
    transferred: bool = False


class RecordTransfer(BaseModel):
    """Kotyolni omborga o'tkazish payloadi — maydonlar berilmasa yozuvdan olinadi."""
    product_id: Optional[uuid.UUID] = None
    unique_id: Optional[str] = None
    bunker_direction: Optional[str] = None
    added_date: Optional[date] = None
    notes: Optional[str] = None


class DaySummary(BaseModel):
    production_date: date
    kotyol: int = 0
    bunker: int = 0
    garelka: int = 0
    tana: int = 0


class ProductionSummary(BaseModel):
    days: list[DaySummary]
    total_kotyol: int = 0
    total_bunker: int = 0
    total_garelka: int = 0
    total_tana: int = 0
