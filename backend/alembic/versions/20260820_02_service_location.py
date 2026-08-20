"""servis: ariza lokatsiyasi (koordinata) + "lokatsiya kutilmoqda" oynasi

Revision ID: 20260820_02
Revises: 20260820_01
Create Date: 2026-08-20

Mijoz Telegramga tashlagan pin har safar chat tarixidan izlanmasin: lokatsiya
aynan ARIZAGA yoziladi (mijozga doimiy biriktirilmaydi — keyingi safar boshqa
manzilga chaqirishi mumkin). `service_location_requests` — ERP'da "Lokatsiya
biriktirish" bosilganda ochiladigan qisqa oyna: shu muddat ichida xodim botga
yuborgan lokatsiya to'g'ridan-to'g'ri o'sha arizaga tushadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260820_02"
down_revision: Union[str, None] = "20260820_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

NEW_COLS = {
    "lat": sa.Column("lat", sa.Float(), nullable=True),
    "lon": sa.Column("lon", sa.Float(), nullable=True),
    "location_url": sa.Column("location_url", sa.Text(), nullable=True),
    "location_note": sa.Column("location_note", sa.String(255), nullable=True),
    "location_source": sa.Column("location_source", sa.String(20), nullable=True),
    "location_added_at": sa.Column("location_added_at", sa.DateTime(timezone=True),
                                   nullable=True),
    "location_added_by_id": sa.Column(
        "location_added_by_id", sa.dialects.postgresql.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True,
    ),
}


def _cols(bind, table: str) -> set:
    return {c["name"] for c in sa.inspect(bind).get_columns(table)}


def _tables(bind) -> set:
    return set(sa.inspect(bind).get_table_names())


def upgrade() -> None:
    bind = op.get_bind()
    have = _cols(bind, "service_tickets")
    for name, col in NEW_COLS.items():
        if name not in have:
            op.add_column("service_tickets", col)

    if "service_location_requests" not in _tables(bind):
        op.create_table(
            "service_location_requests",
            sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True),
                      primary_key=True, server_default=sa.text("gen_random_uuid()")),
            sa.Column("ticket_id", sa.dialects.postgresql.UUID(as_uuid=True),
                      sa.ForeignKey("service_tickets.id", ondelete="CASCADE"),
                      nullable=False),
            sa.Column("user_id", sa.dialects.postgresql.UUID(as_uuid=True),
                      sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("consumed_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
        )
        op.create_index("ix_service_location_requests_ticket_id",
                        "service_location_requests", ["ticket_id"])
        op.create_index("ix_service_location_requests_user_id",
                        "service_location_requests", ["user_id"])


def downgrade() -> None:
    bind = op.get_bind()
    if "service_location_requests" in _tables(bind):
        op.drop_table("service_location_requests")
    have = _cols(bind, "service_tickets")
    for name in NEW_COLS:
        if name in have:
            op.drop_column("service_tickets", name)
