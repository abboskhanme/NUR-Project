"""add orders.unit_uid (ombor ID raqami orqali bog'lash)

Buyurtma endi omborga FAQAT ID raqami (unit_uid) bir xilligi orqali bog'lanadi.
unit_uid — band qilingan kotyolning ombor ID raqami snapshot'i; yetkazilganda
ombor birligi o'chsa ham buyurtmada ID ko'rinib turishi uchun saqlanadi.

Mavjud (inventory_id bilan bog'langan) buyurtmalarga ombordagi unique_id backfill qilinadi.

Revision ID: 20260613_01
Revises: 20260608_03
Create Date: 2026-06-13
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260613_01"
down_revision: Union[str, None] = "20260608_03"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("unit_uid", sa.String(length=50), nullable=True))
    op.create_index("ix_orders_unit_uid", "orders", ["unit_uid"])
    # Backfill: bog'langan ombor birligining ID raqamini snapshot qilamiz
    op.execute(
        """
        UPDATE orders o
        SET unit_uid = i.unique_id
        FROM inventory i
        WHERE o.inventory_id = i.id AND o.unit_uid IS NULL
        """
    )


def downgrade() -> None:
    op.drop_index("ix_orders_unit_uid", table_name="orders")
    op.drop_column("orders", "unit_uid")
