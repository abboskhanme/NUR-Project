"""yuk chiqarish — davlat/viloyat/shofyor ustunlari

Yuk chiqarish jurnalini savdodan ajratish: manzilni davlat + viloyat + aniq
manzil sifatida saqlash va shofyor ismi uchun alohida ustun qo'shish.

Revision ID: 20260616_14
Revises: 20260615_13
Create Date: 2026-06-16
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260616_14"
down_revision: Union[str, None] = "20260615_13"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("shipments", sa.Column("country", sa.String(40), nullable=True))
    op.add_column("shipments", sa.Column("region", sa.String(60), nullable=True))
    op.add_column("shipments", sa.Column("driver_name", sa.String(120), nullable=True))
    op.create_index("ix_shipments_country", "shipments", ["country"])
    op.create_index("ix_shipments_region", "shipments", ["region"])


def downgrade() -> None:
    op.drop_index("ix_shipments_region", table_name="shipments")
    op.drop_index("ix_shipments_country", table_name="shipments")
    op.drop_column("shipments", "driver_name")
    op.drop_column("shipments", "region")
    op.drop_column("shipments", "country")
