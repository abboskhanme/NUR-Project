"""Telegram AI botining menyusi (bo'limlar + rasmlar)

Revision ID: 20260914_01
Revises: 20260912_01
Create Date: 2026-09-14

Mijoz botda «Narxlar» kabi tugmani bosganda yoki `/narxlar` yozganda AI'siz
yuboriladigan tayyor javoblar. Faqat yangi jadvallar — mavjudlariga tegmaydi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20260914_01"
down_revision: Union[str, None] = "20260912_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _timestamps() -> list[sa.Column]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.text("now()"), nullable=False),
    ]


def upgrade() -> None:
    tables = set(sa.inspect(op.get_bind()).get_table_names())

    if "bot_menu_items" not in tables:
        op.create_table(
            "bot_menu_items",
            sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column("command", sa.String(32), nullable=False),
            sa.Column("title", sa.String(64), nullable=False),
            sa.Column("text", sa.Text(), nullable=True),
            sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
            *_timestamps(),
            sa.UniqueConstraint("command", name="uq_bot_menu_items_command"),
        )

    if "bot_menu_images" not in tables:
        op.create_table(
            "bot_menu_images",
            sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column("item_id", postgresql.UUID(as_uuid=True),
                      sa.ForeignKey("bot_menu_items.id", ondelete="CASCADE"),
                      nullable=False),
            sa.Column("content_type", sa.String(64), nullable=False),
            sa.Column("size_bytes", sa.Integer(), nullable=False),
            sa.Column("sha256", sa.String(64), nullable=False),
            sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("data", sa.LargeBinary(), nullable=False),
            *_timestamps(),
        )
        op.create_index("ix_bot_menu_images_item_id", "bot_menu_images", ["item_id"])


def downgrade() -> None:
    tables = set(sa.inspect(op.get_bind()).get_table_names())
    if "bot_menu_images" in tables:
        op.drop_table("bot_menu_images")
    if "bot_menu_items" in tables:
        op.drop_table("bot_menu_items")
