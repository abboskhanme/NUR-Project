"""add users.token_version for token revocation

Revision ID: 20260606_01
Revises: 20260604_01
Create Date: 2026-06-06

Logout / parol almashtirishda eski JWT tokenlarni bekor qilish uchun
foydalanuvchiga `token_version` hisoblagichi qo'shiladi. Token'dagi `ver`
ushbu qiymatga mos kelmasa, token yaroqsiz hisoblanadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260606_01"
down_revision: Union[str, None] = "20260604_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "token_version",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
    )


def downgrade() -> None:
    op.drop_column("users", "token_version")
