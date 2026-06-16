"""Yuk chiqarish — yetkazib berilgan yuklar jurnali (mustaqil modul).

To'liq mustaqil: savdo/buyurtma bo'limiga bog'liq emas. Barcha qatorlar shu
bo'limda qo'lda kiritiladi (Excel kabi joyida tahrirlanadi). Manzil — davlat,
viloyat va aniq manzil (matn) sifatida saqlanadi.
"""
import uuid
from datetime import date
from decimal import Decimal
from typing import Optional

from sqlalchemy import Date, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Shipment(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Bitta yuk chiqarish yozuvi (eski Google Sheet ustunlariga mos)."""
    __tablename__ = "shipments"

    date: Mapped[Optional[date]] = mapped_column(Date, index=True)        # SANA
    qty: Mapped[int] = mapped_column(Integer, default=1)                  # SONI
    country: Mapped[Optional[str]] = mapped_column(String(40), index=True)  # DAVLAT
    region: Mapped[Optional[str]] = mapped_column(String(60), index=True)   # VILOYAT
    destination: Mapped[Optional[str]] = mapped_column(String(255))       # MANZIL (aniq)
    kvm: Mapped[Optional[int]] = mapped_column(Integer)                   # KVM (m2)
    direction: Mapped[Optional[str]] = mapped_column(String(20))          # UNG / CHAP / ORQA
    product_name: Mapped[Optional[str]] = mapped_column(String(120))      # MAHSULOT (turi/nomi)
    product_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 2))  # MAHSULOT NARXI (UZS)
    driver_name: Mapped[Optional[str]] = mapped_column(String(120))       # SHOPIR (ism)
    driver_phone: Mapped[Optional[str]] = mapped_column(String(40))       # SHOPIR TEL
    freight: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 2))    # YUL KIRA
    card_number: Mapped[Optional[str]] = mapped_column(String(40))        # KARTA RAQAMI
    card_holder: Mapped[Optional[str]] = mapped_column(String(120))       # KARTA EGASI
    reason: Mapped[Optional[str]] = mapped_column(Text)                   # SABABI

    # Eski (dekuplingdan oldingi) qatorlar uchun saqlanadi — yangi yozuvlarda ishlatilmaydi.
    order_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="SET NULL"), index=True
    )
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
