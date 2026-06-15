"""qarz turi — debt_products.debt_type ("product"/"credit"/"loan"/ixtiyoriy)

"product" turida birlik va birlik narxi bo'ladi; boshqa turlarda yo'q
(harakatlar to'g'ridan-to'g'ri summa bo'yicha).

Revision ID: 20260615_11
Revises: 20260615_10
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260615_11"
down_revision: Union[str, None] = "20260615_10"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "debt_products",
        sa.Column("debt_type", sa.String(length=50), nullable=False, server_default="product"),
    )


def downgrade() -> None:
    op.drop_column("debt_products", "debt_type")
