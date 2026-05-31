"""Supply schemas."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class SectorOut(ORMBase):
    id: uuid.UUID
    name: str
    code: str
    responsible_user_id: Optional[uuid.UUID] = None


class VendorBase(BaseModel):
    name: str
    sector_id: Optional[uuid.UUID] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    note: Optional[str] = None


class VendorCreate(VendorBase):
    pass


class VendorOut(ORMBase):
    id: uuid.UUID
    name: str
    sector_id: Optional[uuid.UUID] = None
    phone: Optional[str] = None
    note: Optional[str] = None


class ItemBase(BaseModel):
    name: str
    sector_id: Optional[uuid.UUID] = None
    unit: str = "dona"
    stock_qty: Decimal = Decimal(0)
    min_qty: Decimal = Decimal(0)
    default_vendor_id: Optional[uuid.UUID] = None


class ItemCreate(ItemBase):
    pass


class ItemOut(ORMBase):
    id: uuid.UUID
    name: str
    sector_id: Optional[uuid.UUID] = None
    unit: str
    stock_qty: Decimal
    min_qty: Decimal
    default_vendor_id: Optional[uuid.UUID] = None


class GoodsReceiptIn(BaseModel):
    date: date
    vendor_id: uuid.UUID
    item_id: uuid.UUID
    qty: Decimal
    unit_price: Decimal
    currency: str = "UZS"
    paid: Decimal = Decimal(0)
    note: Optional[str] = None


class GoodsReceiptOut(ORMBase):
    id: uuid.UUID
    date: date
    vendor_id: uuid.UUID
    item_id: uuid.UUID
    qty: Decimal
    unit_price: Decimal
    currency: str
    total: Decimal
    paid: Decimal
    balance: Decimal
    status: str


class VendorPaymentIn(BaseModel):
    vendor_id: uuid.UUID
    date: date
    amount: Decimal
    currency: str = "UZS"
    note: Optional[str] = None


class VendorPaymentOut(ORMBase):
    id: uuid.UUID
    vendor_id: uuid.UUID
    date: date
    amount: Decimal
    currency: str
    note: Optional[str] = None
