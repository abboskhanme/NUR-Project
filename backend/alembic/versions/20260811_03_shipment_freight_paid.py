"""yuk chiqarish: yo'l kira to'langan/to'lanmaganligi

Revision ID: 20260811_03
Revises: 20260811_02
Create Date: 2026-08-11

Shofyorga beriladigan yo'l kira to'langanmi yoki hali qarzmi — shuni bilib
turish uchun. Mavjud qatorlar «to'lanmagan» holatida qoladi (false), chunki
ular haqida aniq ma'lumot yo'q — kerakligi qo'lda belgilanadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260811_03"
down_revision: Union[str, None] = "20260811_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _cols(bind, table: str) -> set[str]:
    return {c["name"] for c in sa.inspect(bind).get_columns(table)}


def upgrade() -> None:
    bind = op.get_bind()
    if "freight_paid" not in _cols(bind, "shipments"):
        op.add_column(
            "shipments",
            sa.Column("freight_paid", sa.Boolean(), nullable=False,
                      server_default=sa.text("false")),
        )
        op.create_index("ix_shipments_freight_paid", "shipments", ["freight_paid"])


def downgrade() -> None:
    bind = op.get_bind()
    if "freight_paid" in _cols(bind, "shipments"):
        op.drop_index("ix_shipments_freight_paid", "shipments")
        op.drop_column("shipments", "freight_paid")
