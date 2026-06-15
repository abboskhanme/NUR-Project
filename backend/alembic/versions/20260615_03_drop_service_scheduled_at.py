"""service_tickets.scheduled_at ustunini o'chirish

Rejalashtirish endi faqat status='scheduled' orqali (borish sana/vaqti yo'q).

Revision ID: 20260615_03
Revises: 20260615_02
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260615_03"
down_revision: Union[str, None] = "20260615_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column("service_tickets", "scheduled_at")


def downgrade() -> None:
    op.add_column(
        "service_tickets",
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
    )
