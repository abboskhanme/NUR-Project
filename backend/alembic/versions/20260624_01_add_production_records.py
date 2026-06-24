"""add production_records table

Revision ID: 20260624_01
Revises: 20260621_02
Create Date: 2026-06-24

Ishlab chiqarish jurnali — har kuni ishlab chiqarilgan kotyol / bunker / garelka.
Kotyol yozuvi model (ombor modeli), o'lcham, yo'nalish va ID raqami bilan;
bunker/garelka faqat sana + soni.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260624_01"
down_revision: Union[str, None] = "20260621_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "production_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("category", sa.String(length=20), nullable=False),
        sa.Column("production_date", sa.Date(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False, server_default="1"),
        sa.Column(
            "product_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("products.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("bunker_direction", sa.String(length=10), nullable=True),
        sa.Column("unit_code", sa.String(length=50), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_by_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_production_records_category", "production_records", ["category"])
    op.create_index("ix_production_records_production_date", "production_records",
                    ["production_date"])
    op.create_index("ix_production_records_product_id", "production_records", ["product_id"])
    op.create_index("ix_production_records_unit_code", "production_records",
                    ["unit_code"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_production_records_unit_code", table_name="production_records")
    op.drop_index("ix_production_records_product_id", table_name="production_records")
    op.drop_index("ix_production_records_production_date", table_name="production_records")
    op.drop_index("ix_production_records_category", table_name="production_records")
    op.drop_table("production_records")
