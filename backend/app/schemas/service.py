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


class ServiceExternalTicketCreate(BaseModel):
    """"0 dan" ariza — bizning bazada buyurtmasi yo'q mijoz (diller orqali olgan).

    Ikki xil ishlatiladi:
      1) Yangi mijoz — `full_name` + `phone` kiritiladi. Telefon raqami bazada
         topilsa o'sha mijozga bog'lanadi, aks holda yangi mijoz yaratiladi.
      2) Mavjud mijoz — `customer_id` beriladi (buyurtmasiz ariza), mijoz
         ma'lumotlari o'zgartirilmaydi.
    """
    # Mijoz — yo customer_id, yo full_name + phone
    customer_id: Optional[uuid.UUID] = None
    full_name: Optional[str] = None
    phone: Optional[str] = None
    phone2: Optional[str] = None
    country: str = "Uzbekistan"
    region: Optional[str] = None
    city: Optional[str] = None
    address: Optional[str] = None
    # Mahsulot
    ext_product: Optional[str] = None      # qanday model olgan
    serial_id: Optional[str] = None
    purchase_date: Optional[date] = None   # kafolat shu sanadan hisoblanadi
    ext_seller: Optional[str] = None       # qayerdan/kimdan olgan (diller nomi)
    # Ariza
    problem: str
    category: Optional[str] = None
    # Bo'sh bo'lsa — purchase_date bo'yicha avtomatik aniqlanadi
    in_warranty: Optional[bool] = None
    note: Optional[str] = None             # mijoz kartochkasiga izoh


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
    # "0 dan" ariza (bazada buyurtmasi yo'q mijoz)
    is_external: bool = False
    ext_product: Optional[str] = None
    purchase_date: Optional[date] = None
    ext_seller: Optional[str] = None
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


class PartStat(BaseModel):
    name: str
    count: int


class ServiceCategoryReportRow(BaseModel):
    """Bitta toifa bo'yicha hisobot qatori."""
    category: str
    total: int = 0
    new: int = 0
    scheduled: int = 0
    completed: int = 0
    cancelled: int = 0
    in_warranty: int = 0
    out_warranty: int = 0
    client_cost: Decimal = Decimal(0)   # shu toifadagi "Servis xarajati" yig'indisi
    parts_count: int = 0                # ishlatilgan ehtiyot qismlar (dona)
    parts: list[PartStat] = []          # qaysi qismdan nechta


class ServiceCategoryReport(BaseModel):
    """Servis hisoboti — BARCHA toifalar bo'yicha (arizasi yo'qlari ham)."""
    date_from: Optional[date] = None
    date_to: Optional[date] = None
    total: int = 0
    new: int = 0
    scheduled: int = 0
    completed: int = 0
    cancelled: int = 0
    in_warranty: int = 0
    out_warranty: int = 0
    client_cost: Decimal = Decimal(0)
    parts_count: int = 0
    rows: list[ServiceCategoryReportRow] = []


class TripMoneyStat(BaseModel):
    collected: Decimal = Decimal(0)         # olingan
    spent: Decimal = Decimal(0)             # safar sarflangani (trip.spent yig'indisi)
    net: Decimal = Decimal(0)               # sof (olingan - safar sarflangani) — eski hisob saqlanadi
    trip_count: int = 0
    # Har bir arizadagi "Servis xarajati" (client_cost) yig'indisi — davр bo'yicha
    service_expenses: Decimal = Decimal(0)
    # Servislar uchun ketgan barcha xarajat = safar sarflangani + servis xarajatlari
    total_expenses: Decimal = Decimal(0)


class ServiceExpenseItem(BaseModel):
    """Bitta arizadagi 'Servis xarajati' (client_cost) — hisobot ro'yxati uchun."""
    id: uuid.UUID
    code: str
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    expense_date: Optional[date] = None    # ish bajarilgan sana (closed_at, bo'lmasa opened_at)
    amount: Decimal
    problem: Optional[str] = None
    category: Optional[str] = None
    in_warranty: bool = False


class CustomerSearchHit(ORMBase):
    """Servis arizasida qidiruv natijasi — mijoz (ixtiyoriy mos kelgan buyurtma bilan).

    Buyurtma ID (kod) bo'yicha topilганда `order_id`/`order_code` to'ldiriladi va
    modalда o'sha buyurtma avtomatik tanlanadi.
    """
    customer_id: uuid.UUID
    full_name: str
    phone: str
    address: Optional[str] = None
    order_id: Optional[uuid.UUID] = None
    order_code: Optional[str] = None
    product_summary: Optional[str] = None


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
