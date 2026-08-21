"""leadlar: Telegram kanali (tg_user_id / tg_username)

Revision ID: 20260821_01
Revises: 20260820_03
Create Date: 2026-08-21

AI yordamchisi endi Instagram bilan birga Telegram shaxsiy chatlariga ham
javob beradi. Lead qaysi kanaldan kelganini bilishi uchun Telegram
identifikatorlari alohida ustunlarda saqlanadi (Instagram ustunlari tegilmaydi).
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260821_01"
down_revision: Union[str, None] = "20260820_03"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _cols(bind, table: str) -> set:
    return {c["name"] for c in sa.inspect(bind).get_columns(table)}


def upgrade() -> None:
    bind = op.get_bind()
    have = _cols(bind, "leads")
    if "tg_user_id" not in have:
        op.add_column("leads", sa.Column("tg_user_id", sa.String(64), nullable=True))
        op.create_index("ix_leads_tg_user_id", "leads", ["tg_user_id"])
    if "tg_username" not in have:
        op.add_column("leads", sa.Column("tg_username", sa.String(120), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    have = _cols(bind, "leads")
    if "tg_username" in have:
        op.drop_column("leads", "tg_username")
    if "tg_user_id" in have:
        op.drop_index("ix_leads_tg_user_id", "leads")
        op.drop_column("leads", "tg_user_id")
