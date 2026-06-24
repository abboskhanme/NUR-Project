"""Ishlab chiqarish (PRODUCTION) — kunlik ishlab chiqarilgan mahsulotlar jurnali.

Ishlab chiqarish menejeri har kuni nechta kotyol / bunker / garelka chiqqanini
qayd etadi:
  - kotyol  — har bir dona alohida yozuv: model (ombor modelidan), o'lcham (kvm),
              yo'nalish (o'ng/chap), ID raqami (unit_code), sana.
  - bunker  — sana + soni.
  - garelka — sana + soni.

Kotyol yozuvi ombor birligi (Inventory) bilan deyarli bir xil tuzilishga ega —
shu sabab kelajakda "Omborga yuborish" amalini bir tugma bilan qo'shish mumkin.
"""
import uuid
from datetime import date
from typing import Optional

from sqlalchemy import Date, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class ProductionRecord(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "production_records"

    # kotyol | bunker | garelka
    category: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    production_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    # bunker/garelka uchun soni; kotyol uchun doim 1 (har yozuv = 1 dona)
    quantity: Mapped[int] = mapped_column(default=1, server_default="1", nullable=False)

    # --- Faqat kotyol uchun ---
    # Model + o'lcham (kvm) ombor modelidan (products.product_type == "warehouse") keladi
    product_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id", ondelete="SET NULL"), index=True
    )
    # Bunker yo'nalishi: right (o'ngga) / left (chapga) — ombor kodi bilan bir xil
    bunker_direction: Mapped[Optional[str]] = mapped_column(String(10))
    # ID raqami — kotyol uchun unikal
    unit_code: Mapped[Optional[str]] = mapped_column(String(50), unique=True, index=True)

    notes: Mapped[Optional[str]] = mapped_column(Text)

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
