"""add leads + lead_events (Leadlar / Marketing moduli)

Revision ID: 20260713_01
Revises: 20260711_01
Create Date: 2026-07-13

Leadlar — mustaqil modul: Instagram AI agenti (tashqi `nur-agent` image) topgan
potentsial mijozlar. Xodimlar ularni quvur (new→won/lost) bo'ylab yuritadi va
mijozga aylantiradi. Boshqa bo'limlarga ta'sir qilmaydi.

Idempotent: jadval allaqachon mavjud bo'lsa (dev create_all) — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260713_01"
down_revision: Union[str, None] = "20260711_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not inspector.has_table("leads"):
        op.create_table(
            "leads",
            sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column("source", sa.String(length=30), nullable=False, server_default="instagram"),
            sa.Column("ig_user_id", sa.String(length=64), nullable=True),
            sa.Column("ig_username", sa.String(length=120), nullable=True),
            sa.Column("media_id", sa.String(length=64), nullable=True),
            sa.Column("comment_id", sa.String(length=64), nullable=True),
            sa.Column("name", sa.String(length=255), nullable=True),
            sa.Column("contact", sa.String(length=64), nullable=True),
            sa.Column("product_interest", sa.String(length=255), nullable=True),
            sa.Column("language", sa.String(length=10), nullable=True),
            sa.Column("intent", sa.String(length=30), nullable=True),
            sa.Column("lead_score", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("summary", sa.Text(), nullable=True),
            sa.Column("status", sa.String(length=20), nullable=False, server_default="new"),
            sa.Column(
                "assigned_to_id", postgresql.UUID(as_uuid=True),
                sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True,
            ),
            sa.Column("note", sa.Text(), nullable=True),
            sa.Column(
                "customer_id", postgresql.UUID(as_uuid=True),
                sa.ForeignKey("customers.id", ondelete="SET NULL"), nullable=True,
            ),
            sa.Column(
                "order_id", postgresql.UUID(as_uuid=True),
                sa.ForeignKey("orders.id", ondelete="SET NULL"), nullable=True,
            ),
            sa.Column("extra", postgresql.JSONB(), nullable=False, server_default="{}"),
            sa.Column(
                "created_at", sa.DateTime(timezone=True),
                server_default=sa.func.now(), nullable=False,
            ),
            sa.Column(
                "updated_at", sa.DateTime(timezone=True),
                server_default=sa.func.now(), nullable=False,
            ),
        )
        op.create_index("ix_leads_source", "leads", ["source"])
        op.create_index("ix_leads_ig_user_id", "leads", ["ig_user_id"])
        op.create_index("ix_leads_ig_username", "leads", ["ig_username"])
        op.create_index("ix_leads_product_interest", "leads", ["product_interest"])
        op.create_index("ix_leads_lead_score", "leads", ["lead_score"])
        op.create_index("ix_leads_status", "leads", ["status"])

    if not inspector.has_table("lead_events"):
        op.create_table(
            "lead_events",
            sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column(
                "lead_id", postgresql.UUID(as_uuid=True),
                sa.ForeignKey("leads.id", ondelete="CASCADE"), nullable=False,
            ),
            sa.Column("kind", sa.String(length=20), nullable=False),
            sa.Column("message_text", sa.Text(), nullable=True),
            sa.Column("agent_reply", sa.Text(), nullable=True),
            sa.Column("actor", sa.String(length=20), nullable=False, server_default="agent"),
            sa.Column("meta", postgresql.JSONB(), nullable=False, server_default="{}"),
            sa.Column(
                "created_at", sa.DateTime(timezone=True),
                server_default=sa.func.now(), nullable=False,
            ),
            sa.Column(
                "updated_at", sa.DateTime(timezone=True),
                server_default=sa.func.now(), nullable=False,
            ),
        )
        op.create_index("ix_lead_events_lead_id", "lead_events", ["lead_id"])


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if inspector.has_table("lead_events"):
        op.drop_index("ix_lead_events_lead_id", table_name="lead_events")
        op.drop_table("lead_events")
    if inspector.has_table("leads"):
        for ix in (
            "ix_leads_status", "ix_leads_lead_score", "ix_leads_product_interest",
            "ix_leads_ig_username", "ix_leads_ig_user_id", "ix_leads_source",
        ):
            op.drop_index(ix, table_name="leads")
        op.drop_table("leads")
