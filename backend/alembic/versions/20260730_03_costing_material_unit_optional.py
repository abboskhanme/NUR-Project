"""tannarx: material birligi ixtiyoriy (costing_materials.unit nullable)

Revision ID: 20260730_03
Revises: 20260730_02
Create Date: 2026-07-30

Birlik (dona/kg/metr/...) har doim ma'noli bo'lmaydi — masalan summa bilan
kiritiladigan materiallarda (kraska, bo'yoq ishi) birlik keraksiz. Shu sababli
ustun nullable qilindi va sukut qiymati olib tashlandi.

Idempotent: allaqachon nullable bo'lsa — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260730_03"
down_revision: Union[str, None] = "20260730_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    col = next(
        (c for c in sa.inspect(bind).get_columns("costing_materials") if c["name"] == "unit"),
        None,
    )
    if col is not None and not col["nullable"]:
        op.alter_column(
            "costing_materials", "unit",
            existing_type=sa.String(length=20),
            nullable=True,
            server_default=None,
        )


def downgrade() -> None:
    bind = op.get_bind()
    col = next(
        (c for c in sa.inspect(bind).get_columns("costing_materials") if c["name"] == "unit"),
        None,
    )
    if col is not None and col["nullable"]:
        op.execute("UPDATE costing_materials SET unit = 'dona' WHERE unit IS NULL")
        op.alter_column(
            "costing_materials", "unit",
            existing_type=sa.String(length=20),
            nullable=False,
            server_default="dona",
        )
