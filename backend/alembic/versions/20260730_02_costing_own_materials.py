"""tannarx: o'z material katalogi + summa bilan kiritish

Revision ID: 20260730_02
Revises: 20260730_01
Create Date: 2026-07-30

O'zgarishlar:
  1. `costing_materials` — tannarx modulining O'Z material ro'yxati (ta'minotdan
     mustaqil). `entry_mode` (qty|sum) materialning kalkulyatsiyada qanday
     kiritilishini belgilaydi.
  2. `product_recipe_items`:
     - `material_id` endi `costing_materials` ga ishora qiladi (avval
       `taminot_products` edi)
     - `entry_mode` (qty|sum) va `amount` ustunlari qo'shildi — summani
       to'g'ridan-to'g'ri kiritish uchun ("50 ming so'mlik kraska sepildi")

Ma'lumot yo'qolmasligi uchun: FK ko'chirishdan oldin kalkulyatsiyalarda
ISHLATILGAN ta'minot materiallari yangi katalogga AYNAN SHU id bilan
ko'chiriladi. Shunda mavjud satrlar buzilmaydi.

Idempotent: har qadam mavjudligini tekshiradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260730_02"
down_revision: Union[str, None] = "20260730_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

FK_OLD = "product_recipe_items_material_id_fkey"


def upgrade() -> None:
    bind = op.get_bind()
    insp = sa.inspect(bind)
    tables = set(insp.get_table_names())

    # 1) Yangi katalog jadvali
    if "costing_materials" not in tables:
        op.create_table(
            "costing_materials",
            sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column("name", sa.String(length=255), nullable=False),
            sa.Column("unit", sa.String(length=20), nullable=False, server_default="dona"),
            sa.Column("unit_price", sa.Numeric(16, 2), nullable=False, server_default="0"),
            sa.Column("currency", sa.String(length=3), nullable=False, server_default="UZS"),
            sa.Column("entry_mode", sa.String(length=10), nullable=False, server_default="qty"),
            sa.Column("note", sa.Text(), nullable=True),
            sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
            sa.Column(
                "created_by_id", sa.dialects.postgresql.UUID(as_uuid=True),
                sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True,
            ),
            sa.Column("created_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
        )
        op.create_index("ix_costing_materials_name", "costing_materials", ["name"])

    # 2) Yangi ustunlar
    cols = {c["name"] for c in insp.get_columns("product_recipe_items")}
    if "entry_mode" not in cols:
        op.add_column("product_recipe_items", sa.Column(
            "entry_mode", sa.String(length=10), nullable=False, server_default="qty"))
    if "amount" not in cols:
        op.add_column("product_recipe_items", sa.Column("amount", sa.Numeric(16, 2), nullable=True))

    # 3) Ishlatilgan ta'minot materiallarini yangi katalogga ko'chiramiz (aynan id bilan),
    #    shunda FK almashtirilganda mavjud satrlar buzilmaydi.
    if "taminot_products" in tables:
        op.execute("""
            INSERT INTO costing_materials
                (id, name, unit, unit_price, currency, entry_mode, is_active,
                 created_by_id, created_at, updated_at)
            SELECT DISTINCT tp.id, tp.name, tp.unit, tp.unit_price, tp.currency,
                   'qty', true, tp.created_by_id, now(), now()
            FROM taminot_products tp
            JOIN product_recipe_items pri ON pri.material_id = tp.id
            ON CONFLICT (id) DO NOTHING
        """)

    # 4) FK'ni costing_materials ga ko'chiramiz
    fks = {fk["name"] for fk in insp.get_foreign_keys("product_recipe_items")}
    if FK_OLD in fks:
        op.drop_constraint(FK_OLD, "product_recipe_items", type_="foreignkey")
    if "fk_recipe_items_costing_material" not in fks:
        op.create_foreign_key(
            "fk_recipe_items_costing_material", "product_recipe_items",
            "costing_materials", ["material_id"], ["id"], ondelete="SET NULL",
        )


def downgrade() -> None:
    bind = op.get_bind()
    insp = sa.inspect(bind)
    fks = {fk["name"] for fk in insp.get_foreign_keys("product_recipe_items")}
    if "fk_recipe_items_costing_material" in fks:
        op.drop_constraint("fk_recipe_items_costing_material", "product_recipe_items",
                           type_="foreignkey")
    cols = {c["name"] for c in insp.get_columns("product_recipe_items")}
    if "amount" in cols:
        op.drop_column("product_recipe_items", "amount")
    if "entry_mode" in cols:
        op.drop_column("product_recipe_items", "entry_mode")
    if "costing_materials" in set(insp.get_table_names()):
        op.drop_table("costing_materials")
