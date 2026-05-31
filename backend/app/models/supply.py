"""Supply: sectors, vendors, items, goods receipts, vendor payments, stock movements."""
import uuid
from datetime import date
from decimal import Decimal
from typing import Optional

from sqlalchemy import Date, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


# Sectors: LAZER, CHUGUN, ASOSIY (Umid Tokir), MARDON


class SupplySector(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "supply_sectors"

    name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    code: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    responsible_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class Vendor(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "vendors"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    sector_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("supply_sectors.id", ondelete="SET NULL")
    )
    phone: Mapped[Optional[str]] = mapped_column(String(30))
    address: Mapped[Optional[str]] = mapped_column(Text)
    note: Mapped[Optional[str]] = mapped_column(Text)


class Item(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Material / Komponent."""
    __tablename__ = "items"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    sector_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("supply_sectors.id", ondelete="SET NULL"), index=True
    )
    unit: Mapped[str] = mapped_column(String(20), default="dona")  # kg/m/dona/list
    stock_qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    min_qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    default_vendor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="SET NULL")
    )


class GoodsReceipt(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "goods_receipts"

    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="RESTRICT")
    )
    item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("items.id", ondelete="RESTRICT")
    )
    qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    total: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    paid: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    balance: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    status: Mapped[str] = mapped_column(String(20), default="open")  # open/partial/paid
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class VendorPayment(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "vendor_payments"

    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="CASCADE"), index=True
    )
    date: Mapped[date] = mapped_column(Date, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class StockMovement(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "stock_movements"

    item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("items.id", ondelete="CASCADE"), index=True
    )
    qty_change: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    reason: Mapped[str] = mapped_column(String(50))  # receipt/production/manual_adjust
    ref_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))
    note: Mapped[Optional[str]] = mapped_column(Text)
