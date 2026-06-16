"""yuk chiqarish — mahsulot turi ustuni

Yuk chiqarish jurnaliga tanlangan mahsulot nomi (snapshot) uchun ustun.
Narx (product_price) mahsulotdan avtomatik to'ldiriladi (USD × kurs = UZS).

Revision ID: 20260616_16
Revises: 20260616_15
Create Date: 2026-06-16
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260616_16"
down_revision: Union[str, None] = "20260616_15"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("shipments", sa.Column("product_name", sa.String(120), nullable=True))


def downgrade() -> None:
    op.drop_column("shipments", "product_name")
