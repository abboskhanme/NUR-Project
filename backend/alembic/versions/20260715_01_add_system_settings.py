"""add system_settings (Instagram agenti .env ni UI'dan boshqarish)

Revision ID: 20260715_01
Revises: 20260714_01
Create Date: 2026-07-15

Key-value jadval — super-admin Instagram AI agentining sozlamalarini (AI kalit,
IG token, Telegram) UI'dan boshqaradi. Agent qiymatlarni ERP'dan avtomatik oladi.

Idempotent: jadval allaqachon mavjud bo'lsa — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260715_01"
down_revision: Union[str, None] = "20260714_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "system_settings" not in inspector.get_table_names():
        op.create_table(
            "system_settings",
            sa.Column("key", sa.String(length=64), primary_key=True),
            sa.Column("value", sa.Text(), nullable=True),
            sa.Column(
                "created_at", sa.DateTime(timezone=True),
                server_default=sa.text("now()"), nullable=False,
            ),
            sa.Column(
                "updated_at", sa.DateTime(timezone=True),
                server_default=sa.text("now()"), nullable=False,
            ),
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "system_settings" in inspector.get_table_names():
        op.drop_table("system_settings")
