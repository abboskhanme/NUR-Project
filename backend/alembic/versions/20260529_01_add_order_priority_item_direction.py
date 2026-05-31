"""add order priority + order_item bunker_direction

Revision ID: 20260529_01
Revises: 20260528_01
Create Date: 2026-05-29

Navbat ustuvorligi (orders.priority) va har bir kotyol uchun alohida
yo'nalish (order_items.bunker_direction) uchun ustunlar.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260529_01"
down_revision: Union[str, None] = "20260528_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "orders",
        sa.Column("priority", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_index("ix_orders_priority", "orders", ["priority"])
    op.add_column(
        "order_items",
        sa.Column("bunker_direction", sa.String(length=10), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("order_items", "bunker_direction")
    op.drop_index("ix_orders_priority", table_name="orders")
    op.drop_column("orders", "priority")
