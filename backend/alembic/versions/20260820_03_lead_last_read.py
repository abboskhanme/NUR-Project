"""leadlar: yozishma o'qilgan vaqti (Yozishmalar bo'limi uchun)

Revision ID: 20260820_03
Revises: 20260820_02
Create Date: 2026-08-20

"Yozishmalar" bo'limida o'qilmagan xabarlarni ko'rsatish uchun: shu vaqtdan
keyin kelgan mijoz xabarlari "o'qilmagan" hisoblanadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260820_03"
down_revision: Union[str, None] = "20260820_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _cols(bind, table: str) -> set[str]:
    return {c["name"] for c in sa.inspect(bind).get_columns(table)}


def upgrade() -> None:
    bind = op.get_bind()
    if "last_read_at" not in _cols(bind, "leads"):
        op.add_column(
            "leads",
            sa.Column("last_read_at", sa.DateTime(timezone=True), nullable=True),
        )


def downgrade() -> None:
    bind = op.get_bind()
    if "last_read_at" in _cols(bind, "leads"):
        op.drop_column("leads", "last_read_at")
