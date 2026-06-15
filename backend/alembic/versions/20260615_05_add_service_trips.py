"""servis safari (service_trips) jadvali

Barcha rejalashtirilgan arizalar bitta safar; safarga umumiy 3 ta summa
(olingan / sarflangan / umumiy harajat) qo'lda kiritiladi.

Revision ID: 20260615_05
Revises: 20260615_03
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "20260615_05"
down_revision: Union[str, None] = "20260615_03"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "service_trips",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="open"),
        sa.Column("collected", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("spent", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("total_cost", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("ticket_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("opened_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("closed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_by_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_service_trips_status", "service_trips", ["status"])


def downgrade() -> None:
    op.drop_index("ix_service_trips_status", table_name="service_trips")
    op.drop_table("service_trips")
