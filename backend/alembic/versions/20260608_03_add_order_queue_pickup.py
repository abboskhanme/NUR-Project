"""add orders.in_queue + orders.pickup_date (navbat tizimi)

Buyurtma endi avtomatik navbatga tushmaydi — sotuv sifatida boshlanadi va
"Navbatga o'tkazish" tugmasi bilan navbatga (in_queue=true) chiqib-ketish
sanasi (pickup_date) bilan o'tkaziladi.

Revision ID: 20260608_03
Revises: 20260608_02
Create Date: 2026-06-08
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260608_03"
down_revision: Union[str, None] = "20260608_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "orders",
        sa.Column("in_queue", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )
    op.add_column("orders", sa.Column("pickup_date", sa.Date(), nullable=True))
    op.create_index("ix_orders_in_queue", "orders", ["in_queue"])
    op.create_index("ix_orders_pickup_date", "orders", ["pickup_date"])


def downgrade() -> None:
    op.drop_index("ix_orders_pickup_date", table_name="orders")
    op.drop_index("ix_orders_in_queue", table_name="orders")
    op.drop_column("orders", "pickup_date")
    op.drop_column("orders", "in_queue")
