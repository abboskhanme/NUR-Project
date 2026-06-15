"""Yuk chiqarish — Pydantic sxemalar."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class ShipmentCreate(BaseModel):
    """Yangi qator — barchasi ixtiyoriy (bo'sh qator qo'shib, joyida to'ldiriladi)."""
    date: Optional[date] = None
    qty: int = 1
    destination: Optional[str] = None
    kvm: Optional[int] = None
    direction: Optional[str] = None
    driver_phone: Optional[str] = None
    freight: Optional[Decimal] = None
    kimdan: Optional[str] = None
    card_number: Optional[str] = None
    card_holder: Optional[str] = None
    paid: Optional[str] = None
    pause: Optional[str] = None
    reason: Optional[str] = None


class ShipmentUpdate(BaseModel):
    """Joyida tahrirlash — yuborilgan maydonlargina yangilanadi."""
    date: Optional[date] = None
    qty: Optional[int] = None
    destination: Optional[str] = None
    kvm: Optional[int] = None
    direction: Optional[str] = None
    driver_phone: Optional[str] = None
    freight: Optional[Decimal] = None
    kimdan: Optional[str] = None
    card_number: Optional[str] = None
    card_holder: Optional[str] = None
    paid: Optional[str] = None
    pause: Optional[str] = None
    reason: Optional[str] = None


class ShipmentOut(ORMBase):
    id: uuid.UUID
    date: Optional[date] = None
    qty: int = 1
    destination: Optional[str] = None
    kvm: Optional[int] = None
    direction: Optional[str] = None
    driver_phone: Optional[str] = None
    freight: Optional[Decimal] = None
    kimdan: Optional[str] = None
    card_number: Optional[str] = None
    card_holder: Optional[str] = None
    paid: Optional[str] = None
    pause: Optional[str] = None
    reason: Optional[str] = None
    order_id: Optional[uuid.UUID] = None
    created_at: datetime
