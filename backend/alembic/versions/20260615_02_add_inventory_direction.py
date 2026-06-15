"""ombor birligiga bunker yo'nalishi (right/left) qo'shish

Revision ID: 20260615_02
Revises: 20260615_01
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260615_02"
down_revision: Union[str, None] = "20260615_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("inventory", sa.Column("bunker_direction", sa.String(length=10), nullable=True))


def downgrade() -> None:
    op.drop_column("inventory", "bunker_direction")
