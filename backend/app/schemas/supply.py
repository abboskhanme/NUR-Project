"""Ta'minot sxemalari (taminotchi-asosli)."""
import uuid
from datetime import date
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


# --------------------------------------------------------------------------- #
# Taminotchi (Vendor)
# --------------------------------------------------------------------------- #
class VendorBase(BaseModel):
    name: str
    user_id: Optional[uuid.UUID] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    note: Optional[str] = None
    is_active: bool = True


class VendorCreate(VendorBase):
    pass


class VendorUpdate(BaseModel):
    name: Optional[str] = None
    user_id: Optional[uuid.UUID] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    note: Optional[str] = None
    is_active: Optional[bool] = None


class VendorOut(ORMBase):
    id: uuid.UUID
    name: str
    user_id: Optional[uuid.UUID] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    note: Optional[str] = None
    is_active: bool = True
    # Hisoblanadigan maydonlar
    open_debt: Decimal = Decimal(0)       # qolgan qarz
    items_count: int = 0
    low_stock_count: int = 0


# --------------------------------------------------------------------------- #
# Mahsulot (Item)
# --------------------------------------------------------------------------- #
class ItemBase(BaseModel):
    name: str
    vendor_id: Optional[uuid.UUID] = None
    unit: str = "dona"
    unit_price: Decimal = Decimal(0)
    stock_qty: Decimal = Decimal(0)
    min_qty: Decimal = Decimal(0)
    note: Optional[str] = None


class ItemCreate(ItemBase):
    pass


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    vendor_id: Optional[uuid.UUID] = None
    unit: Optional[str] = None
    unit_price: Optional[Decimal] = None
    stock_qty: Optional[Decimal] = None
    min_qty: Optional[Decimal] = None
    note: Optional[str] = None


class ItemOut(ORMBase):
    id: uuid.UUID
    name: str
    vendor_id: Optional[uuid.UUID] = None
    unit: str
    unit_price: Decimal
    stock_qty: Decimal
    min_qty: Decimal
    note: Optional[str] = None
    is_low: bool = False  # stock_qty < min_qty (va min belgilangan)


# --------------------------------------------------------------------------- #
# Kirim (Goods Receipt)
# --------------------------------------------------------------------------- #
class GoodsReceiptIn(BaseModel):
    date: date
    vendor_id: Optional[uuid.UUID] = None   # taminotchi akkauntida avtomatik to'ladi
    item_id: uuid.UUID
    qty: Decimal
    unit_price: Optional[Decimal] = None    # bo'sh bo'lsa item.unit_price olinadi
    paid: Decimal = Decimal(0)
    note: Optional[str] = None


class GoodsReceiptOut(ORMBase):
    id: uuid.UUID
    date: date
    vendor_id: uuid.UUID
    item_id: uuid.UUID
    qty: Decimal
    unit_price: Decimal
    total: Decimal
    paid: Decimal
    balance: Decimal
    status: str
    note: Optional[str] = None
    item_name: Optional[str] = None
    vendor_name: Optional[str] = None
    unit: Optional[str] = None


# --------------------------------------------------------------------------- #
# Qarz to'lash (Vendor Payment)
# --------------------------------------------------------------------------- #
class VendorPaymentIn(BaseModel):
    vendor_id: uuid.UUID
    date: date
    amount: Decimal
    receipt_id: Optional[uuid.UUID] = None  # aniq bitta kirimni yopish uchun
    note: Optional[str] = None


class VendorPaymentOut(ORMBase):
    id: uuid.UUID
    vendor_id: uuid.UUID
    date: date
    amount: Decimal
    receipt_id: Optional[uuid.UUID] = None
    note: Optional[str] = None


# --------------------------------------------------------------------------- #
# Ombor chiqimi (Stock Issue)
# --------------------------------------------------------------------------- #
class StockIssueIn(BaseModel):
    item_id: uuid.UUID
    qty: Decimal           # musbat son — shu miqdor ombordan chiqariladi
    note: Optional[str] = None


# --------------------------------------------------------------------------- #
# Umumiy balans / KPI
# --------------------------------------------------------------------------- #
class SupplySummary(BaseModel):
    total_debt: Decimal = Decimal(0)        # umumiy qolgan qarz
    total_received: Decimal = Decimal(0)    # umumiy kirim qiymati (so'm)
    total_paid: Decimal = Decimal(0)        # umumiy to'langan
    stock_value: Decimal = Decimal(0)       # ombordagi zaxira qiymati
    items_count: int = 0
    low_stock_count: int = 0
    vendors_count: int = 0
