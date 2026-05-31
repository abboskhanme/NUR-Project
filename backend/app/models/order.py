"""Sales orders, items, payments."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


# Order statuses (soddalashtirilgan holat mashinasi)
ORDER_STATUSES = (
    "new",        # Navbatda
    "ready",      # Tayyor bo'ldi
    "delivered",  # Yetkazildi
    "rejected",   # Rad etildi
)


class Order(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "orders"

    code: Mapped[str] = mapped_column(String(30), unique=True, index=True, nullable=False)

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("customers.id", ondelete="RESTRICT"), index=True
    )
    salesperson_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), index=True
    )
    source: Mapped[str] = mapped_column(String(30), default="manual")  # manual/telegram_bot/import

    order_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    delivered_at: Mapped[Optional[date]] = mapped_column(Date, index=True)

    status: Mapped[str] = mapped_column(String(20), default="new", index=True)
    # Navbat ustuvorligi — yuqori qiymat navbatda oldinroq turadi
    priority: Mapped[int] = mapped_column(default=0, index=True)

    # Inventory linkage (optional — pick a unique unit from SKLAD KATYOL)
    inventory_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("inventory.id", ondelete="SET NULL")
    )

    # Bunker spec snapshot
    area_m2: Mapped[Optional[int]] = mapped_column()
    bunker_direction: Mapped[Optional[str]] = mapped_column(String(10))

    delivery_address: Mapped[Optional[str]] = mapped_column(Text)
    exchange_rate: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)  # USD->UZS snapshot

    payment_type: Mapped[Optional[str]] = mapped_column(String(20))
    # NUR Excel flags
    has_stamp_ruc: Mapped[bool] = mapped_column(Boolean, default=False)
    has_stamp_avt: Mapped[bool] = mapped_column(Boolean, default=False)
    has_online: Mapped[bool] = mapped_column(Boolean, default=False)
    has_video: Mapped[bool] = mapped_column(Boolean, default=False)

    note: Mapped[Optional[str]] = mapped_column(Text)
    additional_info: Mapped[Optional[str]] = mapped_column(Text)

    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order", cascade="all, delete-orphan", lazy="selectin"
    )
    payments: Mapped[list["Payment"]] = relationship(
        back_populates="order", cascade="all, delete-orphan", lazy="selectin"
    )
    customer: Mapped["Customer"] = relationship(lazy="selectin")  # noqa: F821
    inventory: Mapped[Optional["Inventory"]] = relationship(lazy="selectin")  # noqa: F821

    @property
    def items_total_uzs(self) -> Decimal:
        return sum((i.total_uzs or Decimal(0) for i in self.items), Decimal(0))

    @property
    def paid_uzs(self) -> Decimal:
        return sum(
            (p.amount_uzs_equiv or p.amount or Decimal(0) for p in self.payments),
            Decimal(0),
        )

    @property
    def balance_uzs(self) -> Decimal:
        return self.items_total_uzs - self.paid_uzs


class OrderItem(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "order_items"

    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="CASCADE"), index=True
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id", ondelete="RESTRICT")
    )
    serial_id: Mapped[Optional[str]] = mapped_column(String(50))
    # Yo'nalish har bir kotyol uchun alohida: right / left
    bunker_direction: Mapped[Optional[str]] = mapped_column(String(10))

    quantity: Mapped[int] = mapped_column(default=1)
    unit_price_usd: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    unit_price_uzs: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    discount: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    total_uzs: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)

    order: Mapped[Order] = relationship(back_populates="items")
    product: Mapped["Product"] = relationship(lazy="selectin")  # noqa: F821


class Payment(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "payments"

    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="CASCADE"), index=True
    )
    date: Mapped[date] = mapped_column(Date, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    amount_uzs_equiv: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    method: Mapped[Optional[str]] = mapped_column(String(20))  # cash/card/transfer
    doc_file_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))
    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    order: Mapped[Order] = relationship(back_populates="payments")
