"""add service_categories table

Revision ID: 20260601_03
Revises: 20260601_02
Create Date: 2026-06-01

Servis muammolari toifalari (ariza yaratishda dropdown). seed.py create_all bilan
ham yaratiladi; bu migratsiya alembic uchun schema-as-code to'liqligini ta'minlaydi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260601_03"
down_revision: Union[str, None] = "20260601_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "service_categories",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_service_categories_name", "service_categories", ["name"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_service_categories_name", table_name="service_categories")
    op.drop_table("service_categories")
