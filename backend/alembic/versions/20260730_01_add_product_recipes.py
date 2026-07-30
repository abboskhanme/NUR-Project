"""tannarx moduli: product_recipes + product_recipe_items

Revision ID: 20260730_01
Revises: 20260727_01
Create Date: 2026-07-30

Asosiy mahsulotning tarkibi (ichki materiallar + qo'shimcha xarajatlar) va shu
asosda tannarx/foyda hisobi uchun jadvallar. Har mahsulotga bitta kalkulyatsiya
(product_id unikal), satrlar cascade bilan o'chadi.

Idempotent: jadval allaqachon mavjud bo'lsa — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260730_01"
down_revision: Union[str, None] = "20260727_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    tables = set(sa.inspect(bind).get_table_names())

    if "product_recipes" not in tables:
        op.create_table(
            "product_recipes",
            sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column(
                "product_id", sa.dialects.postgresql.UUID(as_uuid=True),
                sa.ForeignKey("products.id", ondelete="CASCADE"), nullable=False, unique=True,
            ),
            sa.Column("overhead_percent", sa.Numeric(6, 2), nullable=False, server_default="0"),
            sa.Column("target_price_usd", sa.Numeric(12, 2), nullable=True),
            sa.Column("note", sa.Text(), nullable=True),
            sa.Column(
                "created_by_id", sa.dialects.postgresql.UUID(as_uuid=True),
                sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True,
            ),
            sa.Column("created_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
        )
        op.create_index("ix_product_recipes_product_id", "product_recipes", ["product_id"])

    if "product_recipe_items" not in tables:
        op.create_table(
            "product_recipe_items",
            sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column(
                "recipe_id", sa.dialects.postgresql.UUID(as_uuid=True),
                sa.ForeignKey("product_recipes.id", ondelete="CASCADE"), nullable=False,
            ),
            sa.Column("kind", sa.String(length=20), nullable=False, server_default="material"),
            sa.Column(
                "material_id", sa.dialects.postgresql.UUID(as_uuid=True),
                sa.ForeignKey("taminot_products.id", ondelete="SET NULL"), nullable=True,
            ),
            sa.Column("label", sa.String(length=255), nullable=True),
            sa.Column("qty", sa.Numeric(14, 3), nullable=False, server_default="1"),
            sa.Column("unit", sa.String(length=20), nullable=True),
            sa.Column("unit_price", sa.Numeric(16, 2), nullable=True),
            sa.Column("currency", sa.String(length=3), nullable=False, server_default="UZS"),
            sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("created_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
        )
        op.create_index("ix_product_recipe_items_recipe_id", "product_recipe_items", ["recipe_id"])
        op.create_index("ix_product_recipe_items_material_id", "product_recipe_items", ["material_id"])


def downgrade() -> None:
    bind = op.get_bind()
    tables = set(sa.inspect(bind).get_table_names())
    if "product_recipe_items" in tables:
        op.drop_table("product_recipe_items")
    if "product_recipes" in tables:
        op.drop_table("product_recipes")
