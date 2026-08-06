"""ta'minot xarid spiskalari (draft ro'yxat -> qabul qilinganda tranzaksiya)

Revision ID: 20260806_02
Revises: 20260806_01
Create Date: 2026-08-06

Ta'minotchi ketishdan oldin kerakli mahsulotlarni ro'yxatga oladi va tizim
jami qancha pul kerakligini chiqaradi. Spiska `draft` holatida ombor
qoldig'iga ham, qarzga ham ta'sir qilmaydi — faqat «Qabul qilish» bosilganda
har bir qator uchun `purchase` tranzaksiyasi yaratiladi.

Idempotent: jadval allaqachon bo'lsa — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260806_02"
down_revision: Union[str, None] = "20260806_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    tables = set(sa.inspect(bind).get_table_names())

    if "taminot_purchase_lists" not in tables:
        op.create_table(
            "taminot_purchase_lists",
            sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True),
                      primary_key=True, server_default=sa.text("gen_random_uuid()")),
            sa.Column("scope", sa.String(10), nullable=False, index=True),
            sa.Column("title", sa.String(255)),
            sa.Column("status", sa.String(10), nullable=False, server_default="draft"),
            sa.Column("note", sa.Text()),
            sa.Column("applied_at", sa.DateTime(timezone=True)),
            sa.Column("created_by_id", sa.dialects.postgresql.UUID(as_uuid=True),
                      sa.ForeignKey("users.id", ondelete="SET NULL")),
            sa.Column("created_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
        )
        op.create_index("ix_taminot_lists_status", "taminot_purchase_lists", ["status"])

    if "taminot_purchase_list_items" not in tables:
        op.create_table(
            "taminot_purchase_list_items",
            sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True),
                      primary_key=True, server_default=sa.text("gen_random_uuid()")),
            sa.Column("list_id", sa.dialects.postgresql.UUID(as_uuid=True),
                      sa.ForeignKey("taminot_purchase_lists.id", ondelete="CASCADE"),
                      nullable=False, index=True),
            sa.Column("product_id", sa.dialects.postgresql.UUID(as_uuid=True),
                      sa.ForeignKey("taminot_products.id", ondelete="CASCADE"),
                      nullable=False, index=True),
            sa.Column("qty", sa.Numeric(14, 3), nullable=False, server_default="0"),
            sa.Column("unit_price", sa.Numeric(16, 2), nullable=False, server_default="0"),
            sa.Column("currency", sa.String(3), nullable=False, server_default="UZS"),
            sa.Column("created_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
        )


def downgrade() -> None:
    bind = op.get_bind()
    tables = set(sa.inspect(bind).get_table_names())
    if "taminot_purchase_list_items" in tables:
        op.drop_table("taminot_purchase_list_items")
    if "taminot_purchase_lists" in tables:
        op.drop_table("taminot_purchase_lists")
