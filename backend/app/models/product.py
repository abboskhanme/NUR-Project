"""Product catalog and inventory (SKLAD KATYOL)."""
import uuid
from datetime import date
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import Date, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Product(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "products"

    # main = asosiy mahsulot (isitish kotyoli), additional = qo'shimcha (turba, defizor, ...)
    product_type: Mapped[str] = mapped_column(
        String(20), default="main", server_default="main", nullable=False, index=True
    )

    # --- Asosiy (kotyol) maydonlari ---
    # Bunker model: PREMIUM 3 / PREMIUM 4 / ULTRA / MAGNUM / OPTIMA
    model: Mapped[Optional[str]] = mapped_column(String(50), index=True)
    # Kvadratura: 150 / 200 / 300 / 400 / 500
    kvm: Mapped[Optional[int]] = mapped_column()

    # --- Qo'shimcha mahsulot maydonlari ---
    # Erkin nom (turba, defizor, nasos, ...)
    name: Mapped[Optional[str]] = mapped_column(String(120))
    # O'lchov birligi: dona / metr / komplekt
    unit: Mapped[Optional[str]] = mapped_column(String(20))

    sku: Mapped[Optional[str]] = mapped_column(String(50), unique=True)
    # Yo'nalish endi catalogda ishlatilmaydi -- buyurtmada tanlanadi (legacy ustun)
    bunker_direction: Mapped[Optional[str]] = mapped_column(String(10))
    description: Mapped[Optional[str]] = mapped_column(Text)

    base_price_usd: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)

    specs: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="{}")
    status: Mapped[str] = mapped_column(String(20), default="active")  # active/archived

    inventory_items: Mapped[list["Inventory"]] = relationship(back_populates="product")

    @property
    def display_name(self) -> str:
        """Royxat/buyurtmalarda korsatish uchun yagona nom."""
        if self.product_type == "additional":
            return self.name or "-"
        parts = [self.model or "-"]
        if self.kvm:
            parts.append(f"{self.kvm} kvm")
        return " ".join(parts)


class Inventory(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Tayyor mahsulot omborida turgan har bir bunker -- unikal ID raqami bilan."""
    __tablename__ = "inventory"

    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), index=True
    )
    unique_id: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    # available / reserved / sold
    status: Mapped[str] = mapped_column(String(20), default="available", index=True)
    added_date: Mapped[date] = mapped_column(Date)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    # Bunker yo'nalishi: right (o'ngga) / left (chapga). Buyurtmadagi bilan bir xil kod.
    bunker_direction: Mapped[Optional[str]] = mapped_column(String(10))

    product: Mapped[Product] = relationship(back_populates="inventory_items")
