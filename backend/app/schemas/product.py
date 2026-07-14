"""Product and inventory schemas."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, computed_field

from app.schemas.common import ORMBase


class ProductBase(BaseModel):
    product_type: str = "main"  # main | additional
    # asosiy (kotyol)
    model: Optional[str] = None
    kvm: Optional[int] = None
    year: Optional[int] = None  # ombor turi uchun ishlab chiqarilgan yil
    # qo'shimcha
    name: Optional[str] = None
    unit: Optional[str] = None

    sku: Optional[str] = None
    description: Optional[str] = None
    base_price_usd: Decimal = Decimal(0)
    status: str = "active"


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    product_type: Optional[str] = None
    model: Optional[str] = None
    kvm: Optional[int] = None
    year: Optional[int] = None
    name: Optional[str] = None
    unit: Optional[str] = None
    sku: Optional[str] = None
    description: Optional[str] = None
    base_price_usd: Optional[Decimal] = None
    status: Optional[str] = None


class ProductOut(ORMBase):
    id: uuid.UUID
    product_type: str
    model: Optional[str] = None
    kvm: Optional[int] = None
    year: Optional[int] = None
    name: Optional[str] = None
    unit: Optional[str] = None
    sku: Optional[str] = None
    bunker_direction: Optional[str] = None
    description: Optional[str] = None
    base_price_usd: Decimal
    status: str
    has_image: bool = False
    created_at: datetime

    @computed_field  # type: ignore[prop-decorator]
    @property
    def display_name(self) -> str:
        if self.product_type == "additional":
            return self.name or "—"
        parts = [self.model or "—"]
        if self.year:
            parts.append(str(self.year))
        if self.kvm:
            parts.append(f"{self.kvm} kvm")
        return " ".join(parts)


class InventoryCreate(BaseModel):
    product_id: uuid.UUID
    unique_id: str
    status: str = "available"
    added_date: date
    notes: Optional[str] = None


class InventoryOut(ORMBase):
    id: uuid.UUID
    product_id: uuid.UUID
    unique_id: str
    status: str
    added_date: date
    notes: Optional[str] = None
