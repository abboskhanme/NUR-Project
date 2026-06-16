"""yuk chiqarish — keraksiz ustunlarni olib tashlash + mahsulot narxi

kimdan / pause / paid ustunlari olib tashlandi (kerak emas), product_price
(mahsulot narxi) qo'shildi.

Revision ID: 20260616_15
Revises: 20260616_14
Create Date: 2026-06-16
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260616_15"
down_revision: Union[str, None] = "20260616_14"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("shipments", sa.Column("product_price", sa.Numeric(14, 2), nullable=True))
    op.drop_column("shipments", "kimdan")
    op.drop_column("shipments", "pause")
    op.drop_column("shipments", "paid")


def downgrade() -> None:
    op.add_column("shipments", sa.Column("paid", sa.String(60), nullable=True))
    op.add_column("shipments", sa.Column("pause", sa.String(60), nullable=True))
    op.add_column("shipments", sa.Column("kimdan", sa.String(40), nullable=True))
    op.drop_column("shipments", "product_price")
