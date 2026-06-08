"""add order_items.discount_usd (chegirma dollarda)

Revision ID: 20260608_01
Revises: 20260606_01
Create Date: 2026-06-08

Sotuvdagi chegirma endi dollarda kiritiladi va hisoblanadi. `discount` ustuni
UZS ekvivalenti sifatida qoladi (discount_usd × order.exchange_rate), shunda
jami summalar va hisobotlar UZS'da o'zgarishsiz ishlaydi.

Mavjud qatorlar uchun discount_usd ni eski UZS chegirmasidan kursga bo'lib
to'ldiramiz (kurs > 0 bo'lganda).
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260608_01"
down_revision: Union[str, None] = "20260606_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "order_items",
        sa.Column(
            "discount_usd",
            sa.Numeric(10, 2),
            nullable=False,
            server_default="0",
        ),
    )
    # Eski UZS chegirmalarini dollarga aylantirib to'ldiramiz
    op.execute(
        """
        UPDATE order_items AS oi
        SET discount_usd = ROUND(oi.discount / o.exchange_rate, 2)
        FROM orders AS o
        WHERE oi.order_id = o.id
          AND o.exchange_rate > 0
          AND oi.discount > 0
        """
    )


def downgrade() -> None:
    op.drop_column("order_items", "discount_usd")
