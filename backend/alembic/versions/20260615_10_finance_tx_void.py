"""moliya tranzaksiyalarini yumshoq o'chirish (void) — status ustuni

finance_transactions.status ("active"/"void"). Void tranzaksiya tarixda qoladi,
lekin balans/KPI/hisobotlardan chiqarib tashlanadi.

Revision ID: 20260615_10
Revises: 20260615_09
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260615_10"
down_revision: Union[str, None] = "20260615_09"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "finance_transactions",
        sa.Column("status", sa.String(length=10), nullable=False, server_default="active"),
    )


def downgrade() -> None:
    op.drop_column("finance_transactions", "status")
