"""Ta'minot (ichki/tashqi): taminot_products va taminot_transactions jadvallari.

Qarzga olib kelinadigan mahsulotlar va ularning harakatlari (olib kelish/to'lov).
"Bizning qarzlar" jadvallariga o'xshash, lekin `scope` (ichki/tashqi) bilan.

Revision ID: 20260627_01
Revises: 20260626_01
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision = "20260627_01"
down_revision = "20260626_01"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "taminot_products",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("scope", sa.String(10), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("unit", sa.String(20), nullable=False, server_default="dona"),
        sa.Column("unit_price", sa.Numeric(16, 2), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(3), nullable=False, server_default="UZS"),
        sa.Column("supplier", sa.String(255), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_by_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_taminot_products_scope", "taminot_products", ["scope"])
    op.create_index("ix_taminot_products_name", "taminot_products", ["name"])

    op.create_table(
        "taminot_transactions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("product_id", UUID(as_uuid=True),
                  sa.ForeignKey("taminot_products.id", ondelete="CASCADE"), nullable=False),
        sa.Column("kind", sa.String(20), nullable=False),
        sa.Column("qty", sa.Numeric(14, 3), nullable=False, server_default="0"),
        sa.Column("unit_price", sa.Numeric(16, 2), nullable=False, server_default="0"),
        sa.Column("amount", sa.Numeric(16, 2), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(3), nullable=False, server_default="UZS"),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_by_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_taminot_transactions_product_id", "taminot_transactions", ["product_id"])


def downgrade() -> None:
    op.drop_index("ix_taminot_transactions_product_id", "taminot_transactions")
    op.drop_table("taminot_transactions")
    op.drop_index("ix_taminot_products_name", "taminot_products")
    op.drop_index("ix_taminot_products_scope", "taminot_products")
    op.drop_table("taminot_products")
