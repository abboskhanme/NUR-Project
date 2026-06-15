"""servis ehtiyot qismlari katalogi + arizada ishlatilgan qismlar

service_parts (katalog) + service_tickets.parts_used (JSONB ro'yxat).

Revision ID: 20260615_08
Revises: 20260615_07
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision: str = "20260615_08"
down_revision: Union[str, None] = "20260615_07"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "service_parts",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_service_parts_name", "service_parts", ["name"], unique=True)
    op.add_column(
        "service_tickets",
        sa.Column("parts_used", JSONB(), nullable=False, server_default="[]"),
    )


def downgrade() -> None:
    op.drop_column("service_tickets", "parts_used")
    op.drop_index("ix_service_parts_name", table_name="service_parts")
    op.drop_table("service_parts")
