"""leadlar: WhatsApp kanali (wa_user_id / wa_username)

Revision ID: 20260912_01
Revises: 20260821_02
Create Date: 2026-09-12

AI yordamchisi endi Instagram va Telegram bilan birga WhatsApp'ga yozganlarga
ham javob beradi. Lead qaysi kanaldan kelganini bilishi uchun WhatsApp
identifikatorlari alohida ustunlarda saqlanadi (boshqa ustunlar tegilmaydi).
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260912_01"
down_revision: Union[str, None] = "20260821_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _cols(bind, table: str) -> set:
    return {c["name"] for c in sa.inspect(bind).get_columns(table)}


def upgrade() -> None:
    bind = op.get_bind()
    have = _cols(bind, "leads")
    if "wa_user_id" not in have:
        op.add_column("leads", sa.Column("wa_user_id", sa.String(64), nullable=True))
        op.create_index("ix_leads_wa_user_id", "leads", ["wa_user_id"])
    if "wa_username" not in have:
        op.add_column("leads", sa.Column("wa_username", sa.String(120), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    have = _cols(bind, "leads")
    if "wa_username" in have:
        op.drop_column("leads", "wa_username")
    if "wa_user_id" in have:
        op.drop_index("ix_leads_wa_user_id", table_name="leads")
        op.drop_column("leads", "wa_user_id")
