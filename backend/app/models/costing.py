"""Tannarx (kalkulyatsiya) — asosiy mahsulot tarkibi va foyda hisobi.

Har bir mahsulot uchun BITTA kalkulyatsiya (ProductRecipe) bo'ladi va u
satrlardan (ProductRecipeItem) tashkil topadi:

  - kind="material" — tannarxning o'z katalogidan material (CostingMaterial).
    Narx sukut bo'yicha katalogdagi JORIY narxdan olinadi, ya'ni katalogda narx
    o'zgarsa tannarx o'zi yangilanadi. `unit_price` to'ldirilsa — shu satr uchun
    qat'iy narx ishlatiladi.
  - kind="expense" — qo'lda kiritiladigan xarajat (ish haqi, payvandlash, ...).

Har satr ikki xil kiritiladi (`entry_mode`):
  - "qty" — miqdor × birlik narxi
  - "sum" — summa to'g'ridan-to'g'ri ("50 ming so'mlik kraska sepildi")

Ustiga `overhead_percent` (umumiy ustama: elektr, amortizatsiya, transport)
qo'shiladi. Sotish narxi `target_price_usd` yoki mahsulotning
`base_price_usd`idan olinadi — foyda va marja shundan hisoblanadi.

Hisob-kitob API tomonida (api/v1/costing.py) bajariladi; bu yerda faqat
kiritilgan ma'lumot saqlanadi.
"""
import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy import Boolean, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class CostingMaterial(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Tannarx modulining O'Z material ro'yxati (ta'minotdan mustaqil).

    `entry_mode` — kalkulyatsiyada bu material qanday kiritilishi:
      - "qty" — miqdor × birlik narxi (masalan 3 list × 200 000)
      - "sum" — to'g'ridan-to'g'ri summa (masalan "50 ming so'mlik kraska sepildi").
        Bunda birlik narxi shart emas.

    Narx shu ro'yxatda o'zgartirilsa, uni ishlatgan barcha kalkulyatsiyalar
    tannarxi o'zi yangilanadi (satrga narx qo'lda qotirilgan bo'lmasa).
    """
    __tablename__ = "costing_materials"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    # Birlik ixtiyoriy — summa bilan kiritiladigan materiallarda ma'nosi yo'q
    unit: Mapped[Optional[str]] = mapped_column(String(20))
    unit_price: Mapped[Decimal] = mapped_column(
        Numeric(16, 2), default=0, server_default="0", nullable=False
    )
    currency: Mapped[str] = mapped_column(String(3), default="UZS", nullable=False)
    # qty | sum
    entry_mode: Mapped[str] = mapped_column(
        String(10), default="qty", server_default="qty", nullable=False
    )
    note: Mapped[Optional[str]] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default="true", nullable=False
    )

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class ProductRecipe(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Bitta mahsulotning tannarx kalkulyatsiyasi (1 mahsulot — 1 kalkulyatsiya)."""
    __tablename__ = "product_recipes"

    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"),
        unique=True, index=True, nullable=False,
    )
    # Umumiy ustama foizi (elektr, amortizatsiya, transport va h.k.)
    overhead_percent: Mapped[Decimal] = mapped_column(
        Numeric(6, 2), default=0, server_default="0", nullable=False
    )
    # Sotish narxi (USD). Bo'sh bo'lsa mahsulotning base_price_usd olinadi.
    target_price_usd: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    note: Mapped[Optional[str]] = mapped_column(Text)

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    items: Mapped[list["ProductRecipeItem"]] = relationship(
        back_populates="recipe",
        cascade="all, delete-orphan",
        passive_deletes=True,
        lazy="selectin",
        order_by="ProductRecipeItem.sort_order",
    )


class ProductRecipeItem(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Kalkulyatsiya satri: material yoki qo'shimcha xarajat."""
    __tablename__ = "product_recipe_items"

    recipe_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("product_recipes.id", ondelete="CASCADE"), index=True
    )
    # material / expense
    kind: Mapped[str] = mapped_column(String(20), default="material", nullable=False)

    # Tannarx katalogidagi material. O'chirilsa satr saqlanadi (label bo'yicha).
    material_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("costing_materials.id", ondelete="SET NULL"), index=True
    )
    # Ko'rsatiladigan nom: expense uchun majburiy, material uchun nusxa (zaxira)
    label: Mapped[Optional[str]] = mapped_column(String(255))

    # Kiritish usuli: "qty" — miqdor × narx, "sum" — to'g'ridan-to'g'ri summa
    entry_mode: Mapped[str] = mapped_column(
        String(10), default="qty", server_default="qty", nullable=False
    )
    qty: Mapped[Decimal] = mapped_column(Numeric(14, 3), default=1, nullable=False)
    # entry_mode="sum" bo'lganda satr summasi shu yerdan olinadi
    amount: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    unit: Mapped[Optional[str]] = mapped_column(String(20))
    # Bo'sh bo'lsa — materialning joriy narxi olinadi (jonli narx)
    unit_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(16, 2))
    currency: Mapped[str] = mapped_column(String(3), default="UZS", nullable=False)

    sort_order: Mapped[int] = mapped_column(Integer, default=0, server_default="0", nullable=False)

    recipe: Mapped["ProductRecipe"] = relationship(back_populates="items")
