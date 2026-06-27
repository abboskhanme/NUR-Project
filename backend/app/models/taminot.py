"""Ta'minot — ichki va tashqi ta'minot bo'yicha qarzga olib kelinadigan mahsulotlar.

Modul "Bizning qarzlar" (debt) mantig'iga asoslanadi, lekin ikki ta'minot turi
(scope) bilan ajratiladi:
  - "ichki"  — ichki ta'minot
  - "tashqi" — tashqi ta'minot

  - TaminotProduct      — olib kelinadigan mahsulot (nom, birlik, narx, taminotchi)
  - TaminotTransaction  — har bir harakat: olib kelish (purchase) yoki to'lov (payment)

Mahsulot qarzi = sum(purchase.amount) - sum(payment.amount). Valyutalar
hech qachon aralashtirilmaydi (har valyuta alohida hisoblanadi).
"""
import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy import ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class TaminotProduct(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Ta'minot mahsuloti. `scope` — "ichki" yoki "tashqi"."""
    __tablename__ = "taminot_products"

    # Ta'minot turi: "ichki" / "tashqi"
    scope: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    unit: Mapped[str] = mapped_column(String(20), default="dona")  # dona/kg/metr/list
    unit_price: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")  # UZS / USD
    supplier: Mapped[Optional[str]] = mapped_column(String(255))
    note: Mapped[Optional[str]] = mapped_column(Text)

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    transactions: Mapped[list["TaminotTransaction"]] = relationship(
        back_populates="product",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


class TaminotTransaction(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Bitta harakat: 'purchase' (olib kelish, qarzni oshiradi) yoki
    'payment' (to'lov, qarzni kamaytiradi)."""
    __tablename__ = "taminot_transactions"

    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("taminot_products.id", ondelete="CASCADE"), index=True
    )
    kind: Mapped[str] = mapped_column(String(20), nullable=False)  # purchase / payment

    # Olib kelishda to'ldiriladi (to'lovda 0 bo'lishi mumkin)
    qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    # Harakat summasi (purchase = qty*unit_price, payment = to'langan summa)
    amount: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    # Valyuta — yaratilganda mahsulotdan nusxalanadi
    currency: Mapped[str] = mapped_column(String(3), default="UZS")

    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    product: Mapped["TaminotProduct"] = relationship(back_populates="transactions")
