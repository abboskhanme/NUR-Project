"""Bizning qarzlar moduli — debt_products va debt_transactions jadvallari

Boshqa bo'limlardan mustaqil. Hech qaysi mavjud jadvalga ta'sir qilmaydi.

Revision ID: 20260615_07
Revises: 20260615_06
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "20260615_07"
down_revision: Union[str, None] = "20260615_06"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "debt_products",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("unit", sa.String(20), nullable=True),
        sa.Column("unit_price", sa.Numeric(16, 2), nullable=True),
        sa.Column("currency", sa.String(3), nullable=False, server_default="UZS"),
        sa.Column("supplier", sa.String(255), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_by_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_debt_products_name", "debt_products", ["name"])

    op.create_table(
        "debt_transactions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("product_id", UUID(as_uuid=True),
                  sa.ForeignKey("debt_products.id", ondelete="CASCADE"), nullable=False),
        sa.Column("kind", sa.String(20), nullable=False),
        sa.Column("qty", sa.Numeric(14, 3), nullable=True),
        sa.Column("unit_price", sa.Numeric(16, 2), nullable=True),
        sa.Column("amount", sa.Numeric(16, 2), nullable=True),
        sa.Column("currency", sa.String(3), nullable=False, server_default="UZS"),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_by_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_debt_transactions_product_id", "debt_transactions", ["product_id"])


def downgrade() -> None:
    op.drop_index("ix_debt_transactions_product_id", table_name="debt_transactions")
    op.drop_table("debt_transactions")
    op.drop_index("ix_debt_products_name", table_name="debt_products")
    op.drop_table("debt_products")
