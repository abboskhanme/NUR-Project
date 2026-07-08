"""add orders.queue_departure_date (navbat taxminiy chiqib-ketish sanasi)

Navbat bo'limida qo'lda kiritiladigan/tahrirlanadigan taxminiy chiqib-ketish
sanasi. Sotuv bo'limidagi pickup_date'dan mustaqil — faqat Navbat sahifasida
ko'rinadi va tahrirlanadi.

Revision ID: 20260708_01
Revises: 20260707_01
Create Date: 2026-07-08
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260708_01"
down_revision: Union[str, None] = "20260707_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("queue_departure_date", sa.Date(), nullable=True))
    op.create_index("ix_orders_queue_departure_date", "orders", ["queue_departure_date"])


def downgrade() -> None:
    op.drop_index("ix_orders_queue_departure_date", table_name="orders")
    op.drop_column("orders", "queue_departure_date")
