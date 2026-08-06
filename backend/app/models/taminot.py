"""Ta'minot — ichki va tashqi ta'minot bo'yicha qarzga olib kelinadigan mahsulotlar.

Modul "Bizning qarzlar" (debt) mantig'iga asoslanadi, lekin ikki ta'minot turi
(scope) bilan ajratiladi:
  - "ichki"  — ichki ta'minot
  - "tashqi" — tashqi ta'minot

  - TaminotProduct      — olib kelinadigan mahsulot (nom, birlik, narx, taminotchi)
  - TaminotTransaction  — har bir harakat: olib kelish (purchase), to'lov (payment),
                          sarflash (consume) yoki qoldiqni to'g'rilash (adjust)

Mahsulot qarzi = sum(purchase.amount) - sum(payment.amount). Valyutalar
hech qachon aralashtirilmaydi (har valyuta alohida hisoblanadi).

Ombor qoldig'i (miqdor bo'yicha, puldan mustaqil):
    qoldiq = sum(purchase.qty) - sum(consume.qty) + sum(adjust.qty)
Qoldiq `min_qty` chegarasidan pastga tushsa mahsulot "kam qoldi" hisoblanadi.
"""
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text
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
    # Kam qoldi chegarasi: qoldiq shundan past bo'lsa ogohlantiriladi (0 — chegara yo'q)
    min_qty: Mapped[Decimal] = mapped_column(
        Numeric(14, 3), default=0, server_default="0", nullable=False
    )
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
    """Bitta harakat. `kind` qiymatlari:
      - 'purchase' — olib kelish: qarzni ham, ombor qoldig'ini ham oshiradi
      - 'payment'  — to'lov: faqat qarzni kamaytiradi (qty = 0)
      - 'consume'  — sarflash: faqat qoldiqni kamaytiradi (amount = 0)
      - 'adjust'   — qoldiqni to'g'rilash (inventarizatsiya): qty musbat yoki
                     manfiy bo'lishi mumkin, pulga ta'sir qilmaydi (amount = 0)
    """
    __tablename__ = "taminot_transactions"

    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("taminot_products.id", ondelete="CASCADE"), index=True
    )
    # purchase / payment / consume / adjust
    kind: Mapped[str] = mapped_column(String(20), nullable=False)

    # Miqdor: purchase/consume/adjust uchun to'ldiriladi (to'lovda 0)
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


class TaminotPurchaseList(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Xarid spiskasi — ta'minotchi uchun reja ro'yxati.

    Ta'minotchi kerakli mahsulotlarni tanlab, har biridan qancha olib kelishini
    yozadi. Tizim jami qancha pul kerakligini chiqarib beradi (valyuta bo'yicha
    alohida) — shu bilan ta'minotchi ketishdan oldin puli aniq bo'ladi.

    `draft` holatida spiska FAQAT REJA: ombor qoldig'iga ham, qarzga ham ta'sir
    qilmaydi. Mahsulot haqiqatan olib kelinganda «Qabul qilish» bosiladi va har
    bir qator uchun `purchase` tranzaksiyasi yaratiladi — shundagina qoldiq va
    qarz hisoblanadi.
    """
    __tablename__ = "taminot_purchase_lists"

    scope: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    title: Mapped[Optional[str]] = mapped_column(String(255))
    # draft — reja; applied — qabul qilingan (tranzaksiyalar yaratilgan)
    status: Mapped[str] = mapped_column(
        String(10), default="draft", server_default="draft", nullable=False, index=True
    )
    note: Mapped[Optional[str]] = mapped_column(Text)
    applied_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    items: Mapped[list["TaminotPurchaseListItem"]] = relationship(
        back_populates="plist", cascade="all, delete-orphan", passive_deletes=True,
    )


class TaminotPurchaseListItem(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Spiskadagi bitta qator: mahsulot + miqdor.

    `unit_price` va `currency` spiska tuzilgan paytdagi narxdan nusxalanadi —
    keyin mahsulot narxi o'zgarsa ham spiskadagi hisob o'zgarmaydi.
    """
    __tablename__ = "taminot_purchase_list_items"

    list_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("taminot_purchase_lists.id", ondelete="CASCADE"),
        index=True,
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("taminot_products.id", ondelete="CASCADE"), index=True
    )
    qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=0)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")

    plist: Mapped["TaminotPurchaseList"] = relationship(back_populates="items")
