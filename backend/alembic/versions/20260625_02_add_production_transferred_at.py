"""add production_records.transferred_at (omborga o'tkazilgan belgisi)

Revision ID: 20260625_02
Revises: 20260625_01
Create Date: 2026-06-25

Kotyol ombor skladiga o'tkazilganda shu vaqt belgisi qo'yiladi va doimiy qoladi —
ombor birligi keyin sotilib o'chirilsa ham holat "o'tkazilgan" bo'lib turaveradi.
Backfill: hozir omborda (inventory) ID raqami mavjud bo'lgan kotyollar o'tkazilgan deb belgilanadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260625_02"
down_revision: Union[str, None] = "20260625_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "production_records",
        sa.Column("transferred_at", sa.DateTime(timezone=True), nullable=True),
    )
    # Backfill — allaqachon omborda turgan kotyollarni o'tkazilgan deb belgilaymiz.
    op.execute(
        """
        UPDATE production_records pr
        SET transferred_at = now()
        FROM inventory inv
        WHERE pr.unit_code IS NOT NULL
          AND pr.unit_code = inv.unique_id
          AND pr.transferred_at IS NULL
        """
    )


def downgrade() -> None:
    op.drop_column("production_records", "transferred_at")
