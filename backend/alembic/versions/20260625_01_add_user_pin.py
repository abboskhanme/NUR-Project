"""add user inactivity PIN-lock columns

Revision ID: 20260625_01
Revises: 20260624_01
Create Date: 2026-06-25

Harakatsizlik PIN-qulfi: foydalanuvchi belgilangan vaqt davomida harakatsiz
bo'lsa sayt qulflanadi va 4 xonali PIN so'raydi. PIN bcrypt bilan hash'lanadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260625_01"
down_revision: Union[str, None] = "20260624_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("pin_hash", sa.String(length=255), nullable=True))
    op.add_column(
        "users",
        sa.Column("pin_enabled", sa.Boolean(), server_default="false", nullable=False),
    )
    op.add_column(
        "users",
        sa.Column("pin_timeout_minutes", sa.Integer(), server_default="5", nullable=False),
    )


def downgrade() -> None:
    op.drop_column("users", "pin_timeout_minutes")
    op.drop_column("users", "pin_enabled")
    op.drop_column("users", "pin_hash")
