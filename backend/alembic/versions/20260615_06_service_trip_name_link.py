"""servis safari nomi + arizani safarga bog'lash

service_trips.name (safar nomi) + service_tickets.trip_id (yakunlangan safar).

Revision ID: 20260615_06
Revises: 20260615_05
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "20260615_06"
down_revision: Union[str, None] = "20260615_05"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("service_trips", sa.Column("name", sa.String(length=120), nullable=True))
    op.add_column("service_tickets", sa.Column("trip_id", UUID(as_uuid=True), nullable=True))
    op.create_index("ix_service_tickets_trip_id", "service_tickets", ["trip_id"])
    op.create_foreign_key(
        "fk_service_tickets_trip_id", "service_tickets", "service_trips",
        ["trip_id"], ["id"], ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("fk_service_tickets_trip_id", "service_tickets", type_="foreignkey")
    op.drop_index("ix_service_tickets_trip_id", table_name="service_tickets")
    op.drop_column("service_tickets", "trip_id")
    op.drop_column("service_trips", "name")
