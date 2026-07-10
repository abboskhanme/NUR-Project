"""Maqsadlar — mustaqil modul.

"Bizning qarzlar" kabi boshqa bo'limlardan (moliya, savdo, ta'minot) MUTLAQO
mustaqil ishlaydi. Bu yerdagi yozuvlar hech qaysi boshqa jadvalga ta'sir qilmaydi.

  - Target              — maqsad (nomi + yig'ilishi kerak bo'lgan summa)
  - TargetContribution  — maqsadga sekin-asta qo'shib boriladigan summa

Yig'ilgan summa = sum(contribution.amount);  qolgan = target_amount - yig'ilgan.
"""
import uuid
from datetime import date
from decimal import Decimal
from typing import Optional

from sqlalchemy import Date, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Target(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Maqsad: nomi va unga yig'ilishi kerak bo'lgan summa."""

    __tablename__ = "targets"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    target_amount: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")  # UZS / USD
    # Ixtiyoriy muddat — belgilansa, UI "necha kun qoldi" ni ko'rsatadi
    deadline: Mapped[Optional[date]] = mapped_column(Date)
    note: Mapped[Optional[str]] = mapped_column(Text)

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    contributions: Mapped[list["TargetContribution"]] = relationship(
        back_populates="target",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


class TargetContribution(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Maqsadga qo'shilgan summa (bir marta qo'shish)."""

    __tablename__ = "target_contributions"

    target_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("targets.id", ondelete="CASCADE"), index=True
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    # Valyuta — qo'shilganda maqsaddan nusxalanadi (keyin maqsad o'zgarsa ham o'zgarmaydi)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")

    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    target: Mapped["Target"] = relationship(back_populates="contributions")
