"""servis: "0 dan" ariza (bazada yo'q mijoz) uchun maydonlar

Revision ID: 20260820_01
Revises: 20260811_03
Create Date: 2026-08-20

Dillerlardan yoki boshqa joydan olgan, bizning bazada buyurtmasi yo'q
mijozlarga ham servis arizasi yaratish mumkin bo'lsin. Bunday arizada
buyurtma (order_id) bo'lmaydi — mahsulot va sotib olingan sana qo'lda
kiritiladi, kafolat o'sha sanadan hisoblanadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260820_01"
down_revision: Union[str, None] = "20260811_03"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

NEW_COLS = {
    "is_external": sa.Column("is_external", sa.Boolean(), nullable=False,
                             server_default=sa.text("false")),
    "ext_product": sa.Column("ext_product", sa.String(120), nullable=True),
    "purchase_date": sa.Column("purchase_date", sa.Date(), nullable=True),
    "ext_seller": sa.Column("ext_seller", sa.String(120), nullable=True),
}


def _cols(bind, table: str) -> set[str]:
    return {c["name"] for c in sa.inspect(bind).get_columns(table)}


def upgrade() -> None:
    bind = op.get_bind()
    have = _cols(bind, "service_tickets")
    for name, col in NEW_COLS.items():
        if name not in have:
            op.add_column("service_tickets", col)


def downgrade() -> None:
    bind = op.get_bind()
    have = _cols(bind, "service_tickets")
    for name in NEW_COLS:
        if name in have:
            op.drop_column("service_tickets", name)
