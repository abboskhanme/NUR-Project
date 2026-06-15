"""yuk chiqarish jurnali — shipments jadvali

Yetkazib berilgan yuklar tarixi (eski Google Sheet o'rniga). Buyurtma
"yetkazildi" bo'lganda avtomatik qator qo'shiladi.

Revision ID: 20260615_12
Revises: 20260615_11
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "20260615_12"
down_revision: Union[str, None] = "20260615_11"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "shipments",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("date", sa.Date(), nullable=True),
        sa.Column("qty", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("destination", sa.String(255), nullable=True),
        sa.Column("kvm", sa.Integer(), nullable=True),
        sa.Column("direction", sa.String(20), nullable=True),
        sa.Column("driver_phone", sa.String(40), nullable=True),
        sa.Column("freight", sa.Numeric(14, 2), nullable=True),
        sa.Column("kimdan", sa.String(40), nullable=True),
        sa.Column("card_number", sa.String(40), nullable=True),
        sa.Column("card_holder", sa.String(120), nullable=True),
        sa.Column("paid", sa.String(60), nullable=True),
        sa.Column("pause", sa.String(60), nullable=True),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("order_id", UUID(as_uuid=True),
                  sa.ForeignKey("orders.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_by_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_shipments_date", "shipments", ["date"])
    op.create_index("ix_shipments_order_id", "shipments", ["order_id"])


def downgrade() -> None:
    op.drop_index("ix_shipments_order_id", table_name="shipments")
    op.drop_index("ix_shipments_date", table_name="shipments")
    op.drop_table("shipments")
