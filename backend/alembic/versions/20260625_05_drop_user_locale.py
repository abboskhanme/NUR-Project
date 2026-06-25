"""drop locale column from users (faqat o'zbek tili)

Revision ID: 20260625_05
Revises: 20260625_04
Create Date: 2026-06-25

Tizim ko'p tilli rejimdan faqat o'zbek tiliga o'tkazildi. Foydalanuvchi
`locale` ustuni endi kerak emas — olib tashlanadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260625_05"
down_revision: Union[str, None] = "20260625_04"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column("users", "locale")


def downgrade() -> None:
    op.add_column(
        "users",
        sa.Column("locale", sa.String(length=5), nullable=False, server_default="uz"),
    )
