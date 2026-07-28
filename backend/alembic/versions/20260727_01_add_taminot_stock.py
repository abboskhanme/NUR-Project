"""taminot ombor qoldig'i: taminot_products.min_qty (kam qoldi chegarasi)

Revision ID: 20260727_01
Revises: 20260715_01
Create Date: 2026-07-27

Ta'minot mahsulotlari uchun ombor qoldig'i hisobi qo'shildi:
  qoldiq = sum(purchase.qty) − sum(consume.qty) + sum(adjust.qty)

`consume` (sarflandi) va `adjust` (qoldiqni to'g'rilash) — TaminotTransaction.kind
ning yangi qiymatlari, ustun String bo'lgani uchun migratsiya talab qilmaydi.
Bu yerda faqat `min_qty` (kam qoldi chegarasi) ustuni qo'shiladi: qoldiq shu
chegaradan pasayganda mahsulot qizil bilan ajratiladi. 0 — chegara yo'q.

Idempotent: ustun allaqachon mavjud bo'lsa — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260727_01"
down_revision: Union[str, None] = "20260715_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    cols = {c["name"] for c in inspector.get_columns("taminot_products")}
    if "min_qty" not in cols:
        op.add_column(
            "taminot_products",
            sa.Column("min_qty", sa.Numeric(14, 3), nullable=False, server_default="0"),
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    cols = {c["name"] for c in inspector.get_columns("taminot_products")}
    if "min_qty" in cols:
        op.drop_column("taminot_products", "min_qty")
