"""add targets + target_contributions (Maqsadlar moduli)

Revision ID: 20260710_01
Revises: 20260708_01
Create Date: 2026-07-10

Maqsadlar — mustaqil modul: nomi va yig'ilishi kerak bo'lgan summa. Summa
sekin-asta `target_contributions` orqali qo'shib boriladi.

Idempotent: jadval allaqachon mavjud bo'lsa (dev create_all) — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260710_01"
down_revision: Union[str, None] = "20260708_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not inspector.has_table("targets"):
        op.create_table(
            "targets",
            sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column("name", sa.String(length=255), nullable=False),
            sa.Column("target_amount", sa.Numeric(16, 2), nullable=False, server_default="0"),
            sa.Column("currency", sa.String(length=3), nullable=False, server_default="UZS"),
            sa.Column("deadline", sa.Date(), nullable=True),
            sa.Column("note", sa.Text(), nullable=True),
            sa.Column(
                "created_by_id",
                postgresql.UUID(as_uuid=True),
                sa.ForeignKey("users.id", ondelete="SET NULL"),
                nullable=True,
            ),
            sa.Column(
                "created_at", sa.DateTime(timezone=True),
                server_default=sa.func.now(), nullable=False,
            ),
            sa.Column(
                "updated_at", sa.DateTime(timezone=True),
                server_default=sa.func.now(), nullable=False,
            ),
        )
        op.create_index("ix_targets_name", "targets", ["name"])

    if not inspector.has_table("target_contributions"):
        op.create_table(
            "target_contributions",
            sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column(
                "target_id",
                postgresql.UUID(as_uuid=True),
                sa.ForeignKey("targets.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column("amount", sa.Numeric(16, 2), nullable=False, server_default="0"),
            sa.Column("currency", sa.String(length=3), nullable=False, server_default="UZS"),
            sa.Column("note", sa.Text(), nullable=True),
            sa.Column(
                "created_by_id",
                postgresql.UUID(as_uuid=True),
                sa.ForeignKey("users.id", ondelete="SET NULL"),
                nullable=True,
            ),
            sa.Column(
                "created_at", sa.DateTime(timezone=True),
                server_default=sa.func.now(), nullable=False,
            ),
            sa.Column(
                "updated_at", sa.DateTime(timezone=True),
                server_default=sa.func.now(), nullable=False,
            ),
        )
        op.create_index(
            "ix_target_contributions_target_id", "target_contributions", ["target_id"]
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if inspector.has_table("target_contributions"):
        op.drop_index("ix_target_contributions_target_id", table_name="target_contributions")
        op.drop_table("target_contributions")
    if inspector.has_table("targets"):
        op.drop_index("ix_targets_name", table_name="targets")
        op.drop_table("targets")
