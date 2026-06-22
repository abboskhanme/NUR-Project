"""Order, OrderItem, Payment schemas."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field, computed_field

from app.schemas.common import ORMBase
from app.schemas.customer import CustomerOut


class OrderItemIn(BaseModel):
    product_id: uuid.UUID
    serial_id: Optional[str] = None
    bunker_direction: Optional[str] = None
    quantity: int = Field(default=1, ge=1)
    unit_price_usd: Decimal = Field(default=Decimal(0), ge=0)
    unit_price_uzs: Decimal = Field(default=Decimal(0), ge=0)
    # Chegirma DOLLARDA kiritiladi (asosiy manba). UZS ekvivalenti backend'da
    # discount_usd × exchange_rate orqali hisoblanadi. Manfiy bo'lishi mumkin emas;
    # yuqori chegara route'da tekshiriladi (narx $ × soni dan oshmasligi kerak).
    discount_usd: Decimal = Field(default=Decimal(0), ge=0)
    # Eski klientlar uchun (UZS chegirma) — qabul qilinadi, lekin backend qayta hisoblaydi
    discount: Decimal = Field(default=Decimal(0), ge=0)


class ProductMini(ORMBase):
    id: uuid.UUID
    product_type: str = "main"
    model: Optional[str] = None
    name: Optional[str] = None
    unit: Optional[str] = None
    sku: Optional[str] = None
    kvm: Optional[int] = None
    bunker_direction: Optional[str] = None

    @computed_field  # type: ignore[prop-decorator]
    @property
    def display_name(self) -> str:
        if self.product_type == "additional":
            return self.name or "—"
        parts = [self.model or "—"]
        if self.kvm:
            parts.append(f"{self.kvm} kvm")
        return " ".join(parts)


class OrderItemOut(ORMBase):
    id: uuid.UUID
    product_id: uuid.UUID
    serial_id: Optional[str] = None
    bunker_direction: Optional[str] = None
    quantity: int
    unit_price_usd: Decimal
    unit_price_uzs: Decimal
    discount_usd: Decimal = Decimal(0)
    discount: Decimal  # UZS ekvivalenti
    total_uzs: Decimal
    product: Optional[ProductMini] = None


class UnitUidUpdate(BaseModel):
    """ID raqamini qo'lda yozish uchun (ombor talab qilinmaydi, snapshot)."""
    unit_uid: Optional[str] = None


class SalespersonUpdate(BaseModel):
    """Buyurtma sotuvchisini qo'lda biriktirish (faqat super-admin)."""
    salesperson_id: Optional[uuid.UUID] = None


class OverrideAmounts(BaseModel):
    """Jami (so'm) va/yoki To'langan (so'm) ni qo'lda to'g'rilash — FAQAT super-admin.

    Eski (Google Sheets'dan ko'chgan) buyurtmalarda Jami/To'langan 0 bo'lib qolgan
    holatlarni tuzatish uchun. Yetkazilgan buyurtmalarda ham ishlaydi.
    Berilmagan maydon o'zgartirilmaydi.
    """
    total_uzs: Optional[Decimal] = Field(default=None, ge=0)
    paid_uzs: Optional[Decimal] = Field(default=None, ge=0)


class SalespersonOption(BaseModel):
    """Sotuvchi tanlovi (dropdown uchun) — aktiv foydalanuvchilar."""
    id: uuid.UUID
    full_name: str


class PaymentIn(BaseModel):
    date: date
    amount: Decimal
    currency: str = "UZS"
    amount_uzs_equiv: Decimal = Decimal(0)
    method: Optional[str] = None
    note: Optional[str] = None


class PaymentOut(ORMBase):
    id: uuid.UUID
    order_id: uuid.UUID
    date: date
    amount: Decimal
    currency: str
    amount_uzs_equiv: Decimal
    method: Optional[str] = None
    note: Optional[str] = None
    created_at: datetime


class OrderBase(BaseModel):
    customer_id: uuid.UUID
    order_date: date
    area_m2: Optional[int] = None
    bunker_direction: Optional[str] = None
    inventory_id: Optional[uuid.UUID] = None
    unit_uid: Optional[str] = None
    delivery_address: Optional[str] = None
    exchange_rate: Decimal = Decimal(0)
    payment_type: Optional[str] = None
    has_stamp_ruc: bool = False
    has_stamp_avt: bool = False
    has_online: bool = False
    has_video: bool = False
    note: Optional[str] = None
    additional_info: Optional[str] = None


class OrderCreate(OrderBase):
    items: list[OrderItemIn] = Field(default_factory=list)


class OrderUpdate(BaseModel):
    customer_id: Optional[uuid.UUID] = None
    order_date: Optional[date] = None
    status: Optional[str] = None
    delivered_at: Optional[date] = None
    inventory_id: Optional[uuid.UUID] = None
    unit_uid: Optional[str] = None
    area_m2: Optional[int] = None
    bunker_direction: Optional[str] = None
    delivery_address: Optional[str] = None
    exchange_rate: Optional[Decimal] = None
    payment_type: Optional[str] = None
    has_stamp_ruc: Optional[bool] = None
    has_stamp_avt: Optional[bool] = None
    has_online: Optional[bool] = None
    has_video: Optional[bool] = None
    note: Optional[str] = None
    additional_info: Optional[str] = None
    salesperson_id: Optional[uuid.UUID] = None
    priority: Optional[int] = None
    # If provided, replaces the full item list
    items: Optional[list[OrderItemIn]] = None


class InventoryMini(ORMBase):
    id: uuid.UUID
    unique_id: str
    status: str


class OrderOut(ORMBase):
    id: uuid.UUID
    code: str
    customer_id: uuid.UUID
    salesperson_id: Optional[uuid.UUID] = None
    source: str
    order_date: date
    delivered_at: Optional[date] = None
    status: str
    priority: int = 0
    in_queue: bool = False
    pickup_date: Optional[date] = None
    inventory_id: Optional[uuid.UUID] = None
    unit_uid: Optional[str] = None
    area_m2: Optional[int] = None
    bunker_direction: Optional[str] = None
    delivery_address: Optional[str] = None
    exchange_rate: Decimal
    payment_type: Optional[str] = None
    has_stamp_ruc: bool
    has_stamp_avt: bool
    has_online: bool
    has_video: bool
    note: Optional[str] = None
    additional_info: Optional[str] = None
    items: list[OrderItemOut] = []
    payments: list[PaymentOut] = []
    customer: Optional[CustomerOut] = None
    inventory: Optional[InventoryMini] = None
    # Computed totals (Order model properties)
    items_total_uzs: Decimal = Decimal(0)
    paid_uzs: Decimal = Decimal(0)
    balance_uzs: Decimal = Decimal(0)
    created_at: datetime
    # Navbat raqami — faqat aktiv (new/ready) buyurtmalar uchun, boshqalarda None
    queue_position: Optional[int] = None
    # Sotuvchi ismi (ro'yxatda bosh harflar belgisi uchun) — list javobida to'ldiriladi
    salesperson_name: Optional[str] = None


class OrderStatusChange(BaseModel):
    status: str
    delivered_at: Optional[date] = None
    note: Optional[str] = None


class SalespersonCount(BaseModel):
    salesperson_id: Optional[uuid.UUID] = None
    name: str
    count: int = 0


class SalesSummary(BaseModel):
    total_orders: int = 0
    status_counts: dict[str, int] = Field(default_factory=dict)
    # Har bir sotuvchi nechta zakaz olgani (joriy filtr bo'yicha, ko'pdan kamga)
    salesperson_counts: list[SalespersonCount] = Field(default_factory=list)
    # Money (UZS)
    revenue_total: Decimal = Decimal(0)       # sum of all order item totals
    paid_total: Decimal = Decimal(0)          # sum of all payments
    outstanding_total: Decimal = Decimal(0)   # revenue - paid
    # This month
    month_orders: int = 0
    month_revenue: Decimal = Decimal(0)
    month_paid: Decimal = Decimal(0)


class QueueItemOut(OrderOut):
    """Navbatdagi buyurtma — tartib raqami bilan."""
    position: int = 0


class QueueAdd(BaseModel):
    # Navbatga o'tkazishda rejalashtirilgan chiqib-ketish sanasi (ixtiyoriy)
    pickup_date: Optional[date] = None


class QueueMove(BaseModel):
    # top = eng yuqoriga, up = bir pog'ona yuqori, down = bir pog'ona past
    action: str
