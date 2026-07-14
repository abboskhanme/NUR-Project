"""add products.year (ombor turi ishlab chiqarilgan yili)

Revision ID: 20260714_01
Revises: 20260713_01
Create Date: 2026-07-14

Ombor turlari (product_type='warehouse') uchun ishlab chiqarilgan yil. Ombor
hisobotida bir xil o'lcham har yil uchun alohida hisoblanadi. Nullable — eski
yozuvlar (va main/additional mahsulotlar) uchun bo'sh qoladi.

Idempotent: ustun allaqachon mavjud bo'lsa — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260714_01"
down_revision: Union[str, None] = "20260713_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    cols = {c["name"] for c in inspector.get_columns("products")}
    if "year" not in cols:
        op.add_column("products", sa.Column("year", sa.Integer(), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    cols = {c["name"] for c in inspector.get_columns("products")}
    if "year" in cols:
        op.drop_column("products", "year")
