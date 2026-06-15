"""Bizning qarzlar — mustaqil modul.

Boshqa bo'limlardan (moliya, savdo, ta'minot) MUTLAQO mustaqil ishlaydi.
Bu yerdagi tranzaksiyalar hech qaysi boshqa jadvalga ta'sir qilmaydi.

  - DebtProduct      — qarzga olinadigan ehtiyot qism (nom, birlik, narx, taminotchi)
  - DebtTransaction  — har bir harakat: olib kelish (purchase) yoki to'lov (payment)

Mahsulot qarzi = sum(purchase.amount) - sum(payment.amount).
"""
import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy import ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class DebtProduct(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Qarzga olib kelinadigan ehtiyot qism."""
    __tablename__ = "debt_products"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    unit: Mapped[str] = mapped_column(String(20), default="dona")  # kg/metr/dona/list
    unit_price: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")  # UZS / USD
    supplier: Mapped[Optional[str]] = mapped_column(String(255))
    note: Mapped[Optional[str]] = mapped_column(Text)

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    transactions: Mapped[list["DebtTransaction"]] = relationship(
        back_populates="product",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


class DebtTransaction(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Bitta harakat: 'purchase' (olib kelish, qarzni oshiradi) yoki
    'payment' (to'lov, qarzni kamaytiradi)."""
    __tablename__ = "debt_transactions"

    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("debt_products.id", ondelete="CASCADE"), index=True
    )
    kind: Mapped[str] = mapped_column(String(20), nullable=False)  # purchase / payment

    # Olib kelishda to'ldiriladi (to'lovda 0/null bo'lishi mumkin)
    qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    # Harakatning umumiy summasi (purchase = qty*unit_price, payment = to'langan summa)
    amount: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    # Valyuta — yaratilganda mahsulotdan nusxalanadi (keyin mahsulot o'zgarsa ham o'zgarmaydi)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")

    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    product: Mapped["DebtProduct"] = relationship(back_populates="transactions")
