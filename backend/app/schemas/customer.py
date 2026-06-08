"""Customer schemas."""
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class CustomerBase(BaseModel):
    full_name: str
    phone: str
    phone2: Optional[str] = None
    country: str = "Uzbekistan"
    region: Optional[str] = None
    city: Optional[str] = None
    address: Optional[str] = None
    source: Optional[str] = "manual"
    note: Optional[str] = None
    is_dealer: bool = False


class CustomerCreate(CustomerBase):
    pass


class CustomerUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    phone2: Optional[str] = None
    country: Optional[str] = None
    region: Optional[str] = None
    city: Optional[str] = None
    address: Optional[str] = None
    note: Optional[str] = None
    is_dealer: Optional[bool] = None


class CustomerOut(ORMBase):
    id: uuid.UUID
    full_name: str
    phone: str
    phone2: Optional[str] = None
    country: str
    region: Optional[str] = None
    city: Optional[str] = None
    address: Optional[str] = None
    source: Optional[str] = None
    note: Optional[str] = None
    is_dealer: bool = False
    created_at: datetime
