"""Bizning qarzlar: boshqa valyutadagi (konvertatsiyali) to'lov

Revision ID: 20260923_01
Revises: 20260914_01
Create Date: 2026-09-23

Qarz o'z valyutasida yopiladi, lekin to'lov boshqa valyutada kiritilishi mumkin.
debt_transactions'ga uchta nullable ustun qo'shiladi — mavjud yozuvlar o'zgarmaydi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260923_01"
down_revision: Union[str, None] = "20260914_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("debt_transactions", sa.Column("paid_amount", sa.Numeric(16, 2), nullable=True))
    op.add_column("debt_transactions", sa.Column("paid_currency", sa.String(3), nullable=True))
    op.add_column("debt_transactions", sa.Column("exchange_rate", sa.Numeric(14, 2), nullable=True))


def downgrade() -> None:
    op.drop_column("debt_transactions", "exchange_rate")
    op.drop_column("debt_transactions", "paid_currency")
    op.drop_column("debt_transactions", "paid_amount")
