"""Telegram kanal postlarini WhatsApp'ga ko'chirish navbati

Revision ID: 20260821_02
Revises: 20260821_01
Create Date: 2026-08-21

Telegram kanalga tashlangan post belgilangan vaqtdan keyin kanal admini
bo'lgan xodimning WhatsApp raqamiga yuboriladi (u forward qilib kanalga
qo'yadi). Navbat holati shu jadvalda kuzatiladi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260821_02"
down_revision: Union[str, None] = "20260821_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    if "channel_posts" in set(sa.inspect(bind).get_table_names()):
        return
    op.create_table(
        "channel_posts",
        sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("tg_chat_id", sa.String(64), nullable=False),
        sa.Column("tg_message_id", sa.String(32), nullable=False),
        sa.Column("media_group_id", sa.String(64), nullable=True),
        sa.Column("posted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("kind", sa.String(20), nullable=False, server_default="text"),
        sa.Column("caption", sa.Text(), nullable=True),
        sa.Column("media", sa.LargeBinary(), nullable=True),
        sa.Column("media_mime", sa.String(80), nullable=True),
        sa.Column("media_name", sa.String(160), nullable=True),
        sa.Column("media_size", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("planned_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("error", sa.Text(), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_to", sa.String(255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.text("now()"), nullable=False),
        sa.UniqueConstraint("tg_chat_id", "tg_message_id", name="uq_channel_post_msg"),
    )
    op.create_index("ix_channel_posts_tg_chat_id", "channel_posts", ["tg_chat_id"])
    op.create_index("ix_channel_posts_status", "channel_posts", ["status"])
    op.create_index("ix_channel_posts_planned_at", "channel_posts", ["planned_at"])


def downgrade() -> None:
    bind = op.get_bind()
    if "channel_posts" in set(sa.inspect(bind).get_table_names()):
        op.drop_table("channel_posts")
