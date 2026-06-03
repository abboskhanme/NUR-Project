"""Ta'minot: taminotchilar (vendors), mahsulotlar (items), kirimlar
(goods receipts), qarz to'lovlari (vendor payments) va ombor harakatlari.

Modul taminotchi-asosli: har bir taminotchi o'z login akkauntiga bog'lanishi
mumkin (Vendor.user_id). Taminotchi tizimga kirganda faqat o'z mahsulotlari va
kirimlarini ko'radi. Sektor tushunchasi (LAZER/CHUGUN/...) olib tashlangan.
"""
import uuid
from datetime import date
from decimal import Decimal
from typing import Optional

from sqlalchemy import Boolean, Date, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin  # noqa


class Vendor(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Taminotchi. Ixtiyoriy ravishda login akkauntiga (user) bog'lanadi."""
    __tablename__ = "vendors"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    # Login akkaunt — taminotchi o'z kabinetiga kirsa, faqat shu vendor ma'lumotlari ko'rinadi
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), unique=True, index=True
    )
    phone: Mapped[Optional[str]] = mapped_column(String(30))
    address: Mapped[Optional[str]] = mapped_column(Text)
    note: Mapped[Optional[str]] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")


class Item(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Material / ehtiyot qism. Har bir mahsulot bitta taminotchiga tegishli."""
    __tablename__ = "items"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    vendor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="SET NULL"), index=True
    )
    unit: Mapped[str] = mapped_column(String(20), default="dona")  # dona/kg/gr/metr/list
    # Belgilab qo'yilgan birlik narxi (so'm). Kirimda avtomatik taklif qilinadi.
    unit_price: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    stock_qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    min_qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    note: Mapped[Optional[str]] = mapped_column(Text)


class GoodsReceipt(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Kirim — taminotchi mahsulot olib keldi. Odatda qarzga olinadi:
    total = qty * unit_price, balance = total - paid (qolgan qarz)."""
    __tablename__ = "goods_receipts"

    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="RESTRICT"), index=True
    )
    item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("items.id", ondelete="RESTRICT")
    )
    qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    total: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    paid: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    balance: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)  # qolgan qarz
    status: Mapped[str] = mapped_column(String(20), default="open")  # open/partial/paid
    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class VendorPayment(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Qarz so'ndirish / to'lash. Taminotchining ochiq kirimlariga taqsimlanadi."""
    __tablename__ = "vendor_payments"

    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="CASCADE"), index=True
    )
    date: Mapped[date] = mapped_column(Date, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    # Ixtiyoriy — aniq bitta kirim qarzini yopish uchun
    receipt_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("goods_receipts.id", ondelete="SET NULL")
    )
    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class StockMovement(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Ombor harakati — kirim (+), chiqim (-) yoki qo'lda tuzatish."""
    __tablename__ = "stock_movements"

    item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("items.id", ondelete="CASCADE"), index=True
    )
    qty_change: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    reason: Mapped[str] = mapped_column(String(50))  # receipt/issue/adjust
    ref_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))
    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
