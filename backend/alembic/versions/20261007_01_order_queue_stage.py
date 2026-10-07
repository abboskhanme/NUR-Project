"""Navbat: buyurtma bosqichi (Yig'ilmoqda / Tayyor)

Revision ID: 20261007_01
Revises: 20260923_01
Create Date: 2026-10-07

orders'ga nullable queue_stage ustuni qo'shiladi (None = Kutilmoqda).
Faqat Navbat bo'limida ishlatiladi — mavjud yozuvlar o'zgarmaydi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20261007_01"
down_revision: Union[str, None] = "20260923_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("queue_stage", sa.String(20), nullable=True))


def downgrade() -> None:
    op.drop_column("orders", "queue_stage")
