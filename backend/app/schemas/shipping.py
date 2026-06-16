"""Yuk chiqarish — Pydantic sxemalar."""
import uuid
# "date" nomli maydon datetime.date tipini soya qilmasligi uchun alias bilan
from datetime import date as date_type, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class ShipmentCreate(BaseModel):
    """Yangi qator — barchasi ixtiyoriy (bo'sh qator qo'shib, joyida to'ldiriladi)."""
    date: Optional[date_type] = None
    qty: int = 1
    country: Optional[str] = None
    region: Optional[str] = None
    destination: Optional[str] = None
    kvm: Optional[int] = None
    direction: Optional[str] = None
    product_name: Optional[str] = None
    product_price: Optional[Decimal] = None
    driver_name: Optional[str] = None
    driver_phone: Optional[str] = None
    freight: Optional[Decimal] = None
    card_number: Optional[str] = None
    card_holder: Optional[str] = None
    reason: Optional[str] = None


class ShipmentUpdate(BaseModel):
    """Joyida tahrirlash — yuborilgan maydonlargina yangilanadi."""
    date: Optional[date_type] = None
    qty: Optional[int] = None
    country: Optional[str] = None
    region: Optional[str] = None
    destination: Optional[str] = None
    kvm: Optional[int] = None
    direction: Optional[str] = None
    product_name: Optional[str] = None
    product_price: Optional[Decimal] = None
    driver_name: Optional[str] = None
    driver_phone: Optional[str] = None
    freight: Optional[Decimal] = None
    card_number: Optional[str] = None
    card_holder: Optional[str] = None
    reason: Optional[str] = None


class ShipmentOut(ORMBase):
    id: uuid.UUID
    date: Optional[date_type] = None
    qty: int = 1
    country: Optional[str] = None
    region: Optional[str] = None
    destination: Optional[str] = None
    kvm: Optional[int] = None
    direction: Optional[str] = None
    product_name: Optional[str] = None
    product_price: Optional[Decimal] = None
    driver_name: Optional[str] = None
    driver_phone: Optional[str] = None
    freight: Optional[Decimal] = None
    card_number: Optional[str] = None
    card_holder: Optional[str] = None
    reason: Optional[str] = None
    order_id: Optional[uuid.UUID] = None
    created_at: datetime


class DriverOut(BaseModel):
    """Avtomatik to'ldirish uchun — ilgari ishlatilgan shofyorlar (ism + oxirgi tel)."""
    name: str
    phone: Optional[str] = None


class ShipProductOut(BaseModel):
    """Yuk chiqarish uchun mahsulot tanlovi — nom + USD narx (kurs bilan UZS ga o'tkaziladi)."""
    name: str
    price_usd: Decimal


# --- Statistika -------------------------------------------------------------

class ShipmentStatRow(BaseModel):
    """Bitta guruh bo'yicha yig'ma: qayerga/kimga qancha ketgani."""
    key: str            # guruh qiymati (viloyat nomi, oy raqami, shofyor va h.k.)
    count: int          # qatorlar soni
    qty: int            # jami dona (SONI)
    kvm: int            # jami KVM (m2)
    freight: Decimal    # jami fraht (yo'l kira)


class ShipmentStats(BaseModel):
    group_by: str
    total: ShipmentStatRow
    rows: list[ShipmentStatRow]
