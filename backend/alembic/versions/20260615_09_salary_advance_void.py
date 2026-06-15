"""avanslarni yumshoq o'chirish (void) + moliya tranzaksiyasi bog'lanishi

salary_advances.status ("active"/"void") va tx_id (bog'liq moliya tranzaksiyasi).

Revision ID: 20260615_09
Revises: 20260615_08
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "20260615_09"
down_revision: Union[str, None] = "20260615_08"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "salary_advances",
        sa.Column("status", sa.String(length=10), nullable=False, server_default="active"),
    )
    op.add_column(
        "salary_advances",
        sa.Column("tx_id", UUID(as_uuid=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("salary_advances", "tx_id")
    op.drop_column("salary_advances", "status")
