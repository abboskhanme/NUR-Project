"""Ta'minot — ichki va tashqi ta'minot bo'yicha qarzga olib kelinadigan mahsulotlar.

Modul ikki ta'minot turi (scope) bilan ajratiladi:
  - "ichki"  — ichki ta'minot
  - "tashqi" — tashqi ta'minot

  - TaminotSupplier     — YETKAZIB BERUVCHI: mahsulotlar olib kelinadigan joy
                          (firma, bozor, shaxs). Pul hisobi shu daraja bo'yicha.
  - TaminotProduct      — olib kelinadigan mahsulot (nom, birlik, narx). Har bir
                          mahsulot majburiy ravishda bitta yetkazib beruvchiga tegishli.
  - TaminotTransaction  — har bir harakat: olib kelish (purchase), to'lov (payment),
                          sarflash (consume) yoki qoldiqni to'g'rilash (adjust)

PUL HISOBI — YETKAZIB BERUVCHI DARAJASIDA:
    qarz = sum(purchase.amount) - sum(payment.amount)
bir yetkazib beruvchining BARCHA mahsulotlari bo'yicha birgalikda. Ya'ni bitta
joydan 15 xil mahsulot olinsa ham hisob-kitob bitta — o'sha joyga nisbatan.
Valyutalar hech qachon aralashtirilmaydi (har valyuta alohida hisoblanadi).

To'lov mahsulotga emas, yetkazib beruvchiga yoziladi — shuning uchun `payment`
harakatlarida `product_id` bo'sh bo'ladi, `supplier_id` esa doim to'ldiriladi.

OMBOR QOLDIG'I esa har mahsulot uchun alohida (miqdor bo'yicha, puldan mustaqil):
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


class TaminotSupplier(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Yetkazib beruvchi — mahsulotlar olib kelinadigan joy.

    Pul hisobi (olib kelingan / to'langan / qarz qoldig'i) aynan shu daraja
    bo'yicha yuritiladi: bitta joydan nechta mahsulot olinishidan qat'i nazar
    qarz bitta — o'sha joyga nisbatan.

    `scope` — "ichki" yoki "tashqi". Ichki va tashqi ta'minotning yetkazib
    beruvchilari hech qachon aralashmaydi (bir xil nomlisi ikkalasida ham
    bo'lishi mumkin — ular alohida yozuvlar).
    """
    __tablename__ = "taminot_suppliers"

    scope: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    phone: Mapped[Optional[str]] = mapped_column(String(50))
    note: Mapped[Optional[str]] = mapped_column(Text)

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    products: Mapped[list["TaminotProduct"]] = relationship(back_populates="supplier")


class TaminotProduct(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Ta'minot mahsuloti. `scope` — "ichki" yoki "tashqi".

    Har bir mahsulot majburiy ravishda bitta yetkazib beruvchiga tegishli —
    uning pul hisobi o'sha yetkazib beruvchining umumiy qarziga qo'shiladi.
    Mahsulot darajasida faqat OMBOR QOLDIG'I mustaqil yuritiladi.
    """
    __tablename__ = "taminot_products"

    # Ta'minot turi: "ichki" / "tashqi"
    scope: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    supplier_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("taminot_suppliers.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    unit: Mapped[str] = mapped_column(String(20), default="dona")  # dona/kg/metr/list
    unit_price: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")  # UZS / USD
    # Kam qoldi chegarasi: qoldiq shundan past bo'lsa ogohlantiriladi (0 — chegara yo'q)
    min_qty: Mapped[Decimal] = mapped_column(
        Numeric(14, 3), default=0, server_default="0", nullable=False
    )
    note: Mapped[Optional[str]] = mapped_column(Text)

    # Arxiv: harakatlari bo'lgan mahsulot o'chirilsa yo'q qilinmaydi, shu maydon
    # to'ldiriladi. U ro'yxatlarda ko'rinmaydi va hisobga qo'shilmaydi, lekin
    # tarixi saqlanib qoladi.
    deleted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    supplier: Mapped["TaminotSupplier"] = relationship(back_populates="products")
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

    `supplier_id` HAR DOIM to'ldiriladi — pul hisobi shu daraja bo'yicha.
    `product_id` esa faqat mahsulotga tegishli harakatlarda bo'ladi; yetkazib
    beruvchiga qilingan umumiy to'lovda u bo'sh (NULL) qoladi.
    """
    __tablename__ = "taminot_transactions"

    supplier_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("taminot_suppliers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    product_id: Mapped[Optional[uuid.UUID]] = mapped_column(
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

    # ARXIV. «O'chirish» bosilganda yozuv bazadan yo'qolmaydi — shu maydon
    # to'ldiriladi. Shu daqiqadan boshlab u qarz, to'lov va ombor qoldig'i
    # hisobiga QO'SHILMAYDI (summa to'g'ri ayiriladi), lekin tarixda ustidan
    # chizilgan holda ko'rinib turadi va kerak bo'lsa tiklanadi.
    deleted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    deleted_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    product: Mapped[Optional["TaminotProduct"]] = relationship(back_populates="transactions")


class TaminotPurchaseList(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Xarid spiskasi — bitta YETKAZIB BERUVCHI uchun reja ro'yxati.

    Ta'minotchi shu joyga borishdan oldin kerakli mahsulotlarni tanlab, har
    biridan qancha olib kelishini yozadi. Tizim jami qancha pul kerakligini
    chiqarib beradi (valyuta bo'yicha alohida) — shu bilan ketishdan oldin puli
    aniq bo'ladi. Spiskaga faqat shu yetkazib beruvchining mahsulotlari kiradi.

    `draft` holatida spiska FAQAT REJA: ombor qoldig'iga ham, qarzga ham ta'sir
    qilmaydi. Mahsulot haqiqatan olib kelinganda «Qabul qilish» bosiladi va har
    bir qator uchun `purchase` tranzaksiyasi yaratiladi — shundagina qoldiq va
    qarz hisoblanadi.
    """
    __tablename__ = "taminot_purchase_lists"

    scope: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    supplier_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("taminot_suppliers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
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
