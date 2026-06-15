"""Service module schemas."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class ServiceTicketBase(BaseModel):
    order_id: Optional[uuid.UUID] = None
    customer_id: uuid.UUID
    serial_id: Optional[str] = None
    address: Optional[str] = None
    problem: str
    category: Optional[str] = None
    in_warranty: bool = False


class ServiceTicketCreate(ServiceTicketBase):
    pass


class ServiceTicketUpdate(BaseModel):
    status: Optional[str] = None
    resolution: Optional[str] = None
    client_cost: Optional[Decimal] = None
    closed_at: Optional[datetime] = None
    in_warranty: Optional[bool] = None
    parts_used: Optional[list[str]] = None


class ServiceVisitIn(BaseModel):
    planned_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    finished_at: Optional[datetime] = None
    travel_cost: Decimal = Decimal(0)
    note: Optional[str] = None


class ServiceVisitOut(ORMBase):
    id: uuid.UUID
    ticket_id: uuid.UUID
    planned_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    finished_at: Optional[datetime] = None
    travel_cost: Decimal
    note: Optional[str] = None
    created_at: datetime


class CustomerMini(ORMBase):
    id: uuid.UUID
    full_name: str
    phone: str
    address: Optional[str] = None


class OrderMini(ORMBase):
    id: uuid.UUID
    code: str
    delivered_at: Optional[date] = None
    status: str
    delivery_address: Optional[str] = None
    product_summary: Optional[str] = None  # masalan: "OPTIMA 400 kvm"


class ServiceTicketOut(ORMBase):
    id: uuid.UUID
    code: str
    order_id: Optional[uuid.UUID] = None
    customer_id: uuid.UUID
    serial_id: Optional[str] = None
    address: Optional[str] = None
    problem: str
    category: Optional[str] = None
    opened_at: datetime
    closed_at: Optional[datetime] = None
    status: str
    in_warranty: bool
    resolution: Optional[str] = None
    client_cost: Decimal
    parts_used: list[str] = []
    visits: list[ServiceVisitOut] = []
    customer: Optional[CustomerMini] = None
    order: Optional[OrderMini] = None


class WarrantyInfo(BaseModel):
    order_id: uuid.UUID
    warranty_start: Optional[date] = None
    year1_end: Optional[date] = None
    year3_end: Optional[date] = None
    days_remaining_year1: Optional[int] = None
    days_remaining_year3: Optional[int] = None
    current_status: str  # active_full / active_service_only / expired / not_delivered


class ServiceCategoryIn(BaseModel):
    name: str


class ServiceCategoryOut(ORMBase):
    id: uuid.UUID
    name: str
    is_active: bool = True


class ServicePartIn(BaseModel):
    name: str


class ServicePartOut(ORMBase):
    id: uuid.UUID
    name: str
    is_active: bool = True


class ServiceSummary(BaseModel):
    total: int
    new: int
    scheduled: int
    completed: int
    cancelled: int
    in_warranty_open: int
    # Rejalashtirilgan (status='scheduled') arizalar soni — ✅ znachok kartasi
    with_visit: int = 0


class ServiceTripUpdate(BaseModel):
    name: Optional[str] = None
    collected: Optional[Decimal] = None
    spent: Optional[Decimal] = None
    note: Optional[str] = None


class ServiceTripOut(ORMBase):
    id: uuid.UUID
    name: Optional[str] = None
    status: str
    collected: Decimal
    spent: Decimal
    note: Optional[str] = None
    ticket_count: int = 0
    scheduled_count: int = 0   # joriy rejalashtirilgan arizalar soni (live)
    opened_at: datetime
    closed_at: Optional[datetime] = None
