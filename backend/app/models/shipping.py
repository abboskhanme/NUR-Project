"""Yuk chiqarish — yetkazib berilgan yuklar jurnali (mustaqil modul).

Buyurtma "yetkazildi" holatiga o'tganda bu yerga avtomatik bitta qator tushadi
(sana, manzil, KVM, yo'nalish). Qolgan ustunlar — haydovchi, yo'l kira, to'lov,
muammo sababi — Excel kabi joyida qo'lda to'ldiriladi.
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
    destination: Mapped[Optional[str]] = mapped_column(String(255))       # MANZIL
    kvm: Mapped[Optional[int]] = mapped_column(Integer)                   # KVM (m2)
    direction: Mapped[Optional[str]] = mapped_column(String(20))          # UNG / CHAP / ORQA
    driver_phone: Mapped[Optional[str]] = mapped_column(String(40))       # SHOPIR TEL
    freight: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 2))    # YUL KIRA
    kimdan: Mapped[Optional[str]] = mapped_column(String(40))             # KIMDAN (foiz/izoh)
    card_number: Mapped[Optional[str]] = mapped_column(String(40))        # KARTA RAQAMI
    card_holder: Mapped[Optional[str]] = mapped_column(String(120))       # KARTA EGASI
    paid: Mapped[Optional[str]] = mapped_column(String(60))               # TO'LANDI
    pause: Mapped[Optional[str]] = mapped_column(String(60))              # PAUZA
    reason: Mapped[Optional[str]] = mapped_column(Text)                   # SABABI

    # Avtomatik yaratilgan bo'lsa — manba buyurtma (dublikatdan saqlanish uchun)
    order_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="SET NULL"), index=True
    )
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
