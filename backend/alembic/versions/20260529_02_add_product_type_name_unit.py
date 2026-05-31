"""add product_type, name, unit to products; model nullable

Revision ID: 20260529_02
Revises: 20260529_01
Create Date: 2026-05-29

Mahsulotlar ikki turga bo'linadi: main (asosiy kotyol) va additional
(qo'shimcha — turba, defizor). Qo'shimcha uchun name + unit, asosiy uchun
model + kvm. Eski qatorlar 'main' bo'ladi va model endi nullable.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260529_02"
down_revision: Union[str, None] = "20260529_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "products",
        sa.Column("product_type", sa.String(length=20), nullable=False, server_default="main"),
    )
    op.create_index("ix_products_product_type", "products", ["product_type"])
    op.add_column("products", sa.Column("name", sa.String(length=120), nullable=True))
    op.add_column("products", sa.Column("unit", sa.String(length=20), nullable=True))
    # model endi nullable (qo'shimcha mahsulotlarda bo'lmaydi)
    op.alter_column("products", "model", existing_type=sa.String(length=50), nullable=True)


def downgrade() -> None:
    op.alter_column("products", "model", existing_type=sa.String(length=50), nullable=False)
    op.drop_column("products", "unit")
    op.drop_column("products", "name")
    op.drop_index("ix_products_product_type", table_name="products")
    op.drop_column("products", "product_type")
