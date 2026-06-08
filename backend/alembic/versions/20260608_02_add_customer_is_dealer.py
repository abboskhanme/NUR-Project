"""add customers.is_dealer (diller mijoz)

Diller mijozlar to'liq to'lamasa ham buyurtmani "yetkazildi"ga o'tkazishi mumkin.

Revision ID: 20260608_02
Revises: 20260608_01
Create Date: 2026-06-08
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260608_02"
down_revision: Union[str, None] = "20260608_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "customers",
        sa.Column("is_dealer", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )


def downgrade() -> None:
    op.drop_column("customers", "is_dealer")
