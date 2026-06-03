"""add service_tickets and service_visits tables

Revision ID: 20260601_02
Revises: 20260529_02
Create Date: 2026-06-01

Servis (kafolat) moduli jadvallari:
  - service_tickets : mijoz arizasi (muammo, kafolat holati, sana, status, xarajat)
  - service_visits  : ariza bo'yicha tashriflar / izohlar jurnali

Eslatma: seed.py `Base.metadata.create_all` orqali bu jadvallarni avtomatik
yaratadi; ushbu migratsiya alembic'ni boshqaradigan muhitlar uchun schema-as-code
to'liqligini ta'minlaydi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260601_02"
down_revision: Union[str, None] = "20260529_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "service_tickets",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("code", sa.String(length=30), nullable=False),
        sa.Column(
            "order_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("orders.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "customer_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("customers.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("serial_id", sa.String(length=50), nullable=True),
        sa.Column("address", sa.Text(), nullable=True),
        sa.Column("problem", sa.Text(), nullable=False),
        sa.Column("category", sa.String(length=50), nullable=True),
        sa.Column("opened_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("closed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="new"),
        sa.Column("in_warranty", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("resolution", sa.Text(), nullable=True),
        sa.Column("client_cost", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column(
            "created_by_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_service_tickets_code", "service_tickets", ["code"], unique=True)
    op.create_index("ix_service_tickets_order_id", "service_tickets", ["order_id"])
    op.create_index("ix_service_tickets_customer_id", "service_tickets", ["customer_id"])
    op.create_index("ix_service_tickets_status", "service_tickets", ["status"])

    op.create_table(
        "service_visits",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "ticket_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("service_tickets.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("planned_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("finished_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("travel_cost", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_service_visits_ticket_id", "service_visits", ["ticket_id"])


def downgrade() -> None:
    op.drop_index("ix_service_visits_ticket_id", table_name="service_visits")
    op.drop_table("service_visits")
    op.drop_index("ix_service_tickets_status", table_name="service_tickets")
    op.drop_index("ix_service_tickets_customer_id", table_name="service_tickets")
    op.drop_index("ix_service_tickets_order_id", table_name="service_tickets")
    op.drop_index("ix_service_tickets_code", table_name="service_tickets")
    op.drop_table("service_tickets")
