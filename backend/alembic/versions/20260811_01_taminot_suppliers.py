"""ta'minot: yetkazib beruvchi (guruh) — qarz hisobi mahsulotdan guruhga ko'chdi

Revision ID: 20260811_01
Revises: 20260806_02
Create Date: 2026-08-11

Ilgari qarz HAR MAHSULOT uchun alohida hisoblanardi: bitta joydan 15 xil
mahsulot olinsa, 15 ta alohida qarz yozuvi paydo bo'lardi. Endi mahsulotlar
YETKAZIB BERUVCHI (`taminot_suppliers`) ostiga yig'iladi va pul hisobi aynan
shu daraja bo'yicha yuritiladi — bitta joyga nisbatan bitta qarz.

MA'LUMOT KO'CHIRISH (hech nima yo'qolmaydi):
  1. Har `scope` uchun mavjud `taminot_products.supplier` MATNLARIDAN yetkazib
     beruvchilar yaratiladi (bir xil nomlar bitta yozuvga birlashadi).
  2. Ta'minotchisi ko'rsatilmagan mahsulotlar shu scope'ning «Boshqa» guruhiga
     tushadi — keyin qo'lda kerakli joyga ko'chiriladi.
  3. Barcha tranzaksiyalar o'z mahsulotining yetkazib beruvchisiga biriktiriladi,
     shuning uchun guruh qarzi darhol to'g'ri chiqadi.
  4. Mavjud qoralama spiskalar birinchi qatoridagi mahsulotning yetkazib
     beruvchisiga biriktiriladi; begona qatorlar o'chiriladi (spiska endi bitta
     joyga tegishli). Spiska — faqat reja, shuning uchun bu hisobga ta'sir qilmaydi.
  5. Eski `taminot_products.supplier` matn ustuni o'chiriladi (ikki manba
     qolmasligi uchun). `downgrade` uni guruh nomlaridan qayta tiklaydi.

Idempotent: allaqachon bajarilgan bo'lsa — o'tkazib yuboriladi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20260811_01"
down_revision: Union[str, None] = "20260806_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

UUID = postgresql.UUID(as_uuid=True)


def _cols(bind, table: str) -> set[str]:
    return {c["name"] for c in sa.inspect(bind).get_columns(table)}


def upgrade() -> None:
    bind = op.get_bind()
    tables = set(sa.inspect(bind).get_table_names())

    # ---------------------------------------------------------------- 1) jadval
    if "taminot_suppliers" not in tables:
        op.create_table(
            "taminot_suppliers",
            sa.Column("id", UUID, primary_key=True,
                      server_default=sa.text("gen_random_uuid()")),
            sa.Column("scope", sa.String(10), nullable=False),
            sa.Column("name", sa.String(255), nullable=False),
            sa.Column("phone", sa.String(50)),
            sa.Column("note", sa.Text()),
            sa.Column("created_by_id", UUID,
                      sa.ForeignKey("users.id", ondelete="SET NULL")),
            sa.Column("created_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("now()"), nullable=False),
        )
        op.create_index("ix_taminot_suppliers_scope", "taminot_suppliers", ["scope"])
        op.create_index("ix_taminot_suppliers_name", "taminot_suppliers", ["name"])
        # Bir bo'lim ichida bir xil nom ikki marta bo'lmasin — aks holda qarz
        # ikkiga bo'linib ketadi. Registrga bog'liq emas: «Metall» = «METALL».
        op.execute(
            "CREATE UNIQUE INDEX uq_taminot_suppliers_scope_name "
            "ON taminot_suppliers (scope, lower(name))"
        )

    prod_cols = _cols(bind, "taminot_products")

    # ------------------------------------------------- 2) ustunlar (nullable holda)
    if "supplier_id" not in prod_cols:
        op.add_column("taminot_products", sa.Column("supplier_id", UUID, nullable=True))
    if "supplier_id" not in _cols(bind, "taminot_transactions"):
        op.add_column("taminot_transactions", sa.Column("supplier_id", UUID, nullable=True))
    if "supplier_id" not in _cols(bind, "taminot_purchase_lists"):
        op.add_column("taminot_purchase_lists", sa.Column("supplier_id", UUID, nullable=True))

    # -------------------------------------------------------- 3) ma'lumot ko'chirish
    has_supplier_text = "supplier" in prod_cols

    if has_supplier_text:
        # Mavjud ta'minotchi matnlaridan guruhlar (nom bo'yicha registrga
        # bog'liq emas — «Metall servis» va «METALL SERVIS» bitta joy)
        op.execute("""
            INSERT INTO taminot_suppliers (scope, name)
            SELECT scope, MIN(btrim(supplier))
            FROM taminot_products
            WHERE supplier IS NOT NULL AND btrim(supplier) <> ''
            GROUP BY scope, lower(btrim(supplier))
            ON CONFLICT DO NOTHING
        """)
        op.execute("""
            UPDATE taminot_products p
            SET supplier_id = s.id
            FROM taminot_suppliers s
            WHERE p.supplier_id IS NULL
              AND s.scope = p.scope
              AND lower(s.name) = lower(btrim(p.supplier))
        """)

    # Ta'minotchisi ko'rsatilmagan mahsulotlar uchun «Boshqa» guruhi —
    # faqat haqiqatan kerak bo'lgan scope'da yaratiladi
    op.execute("""
        INSERT INTO taminot_suppliers (scope, name, note)
        SELECT DISTINCT p.scope, 'Boshqa',
               'Avtomatik yaratildi: yetkazib beruvchisi ko''rsatilmagan mahsulotlar'
        FROM taminot_products p
        WHERE p.supplier_id IS NULL
        ON CONFLICT DO NOTHING
    """)
    op.execute("""
        UPDATE taminot_products p
        SET supplier_id = s.id
        FROM taminot_suppliers s
        WHERE p.supplier_id IS NULL AND s.scope = p.scope AND s.name = 'Boshqa'
    """)

    # Barcha harakatlar o'z mahsulotining guruhiga biriktiriladi
    op.execute("""
        UPDATE taminot_transactions t
        SET supplier_id = p.supplier_id
        FROM taminot_products p
        WHERE t.supplier_id IS NULL AND t.product_id = p.id
    """)
    # Mahsuloti yo'q (bog'lanmagan) harakat qolmasin
    op.execute("DELETE FROM taminot_transactions WHERE supplier_id IS NULL")

    # Spiskalar: birinchi qatordagi mahsulotning guruhiga biriktiriladi
    op.execute("""
        UPDATE taminot_purchase_lists pl
        SET supplier_id = sub.supplier_id
        FROM (
            SELECT DISTINCT ON (i.list_id) i.list_id, p.supplier_id
            FROM taminot_purchase_list_items i
            JOIN taminot_products p ON p.id = i.product_id
            ORDER BY i.list_id, i.created_at
        ) sub
        WHERE pl.supplier_id IS NULL AND pl.id = sub.list_id
    """)
    # Aralash spiskalarda begona qatorlar olib tashlanadi (spiska — faqat reja,
    # hisobga ta'sir qilmaydi)
    op.execute("""
        DELETE FROM taminot_purchase_list_items i
        USING taminot_purchase_lists pl, taminot_products p
        WHERE i.list_id = pl.id AND i.product_id = p.id
          AND pl.supplier_id IS NOT NULL AND p.supplier_id <> pl.supplier_id
    """)
    # Qatorsiz qolgan (yoki hech qachon qatori bo'lmagan) spiskalar o'chadi
    op.execute("DELETE FROM taminot_purchase_lists WHERE supplier_id IS NULL")

    # --------------------------------------------- 4) cheklovlar va FK'lar
    op.alter_column("taminot_products", "supplier_id", nullable=False)
    op.alter_column("taminot_transactions", "supplier_id", nullable=False)
    op.alter_column("taminot_purchase_lists", "supplier_id", nullable=False)
    # To'lov yetkazib beruvchiga qilinadi — mahsulotsiz yozuv bo'ladi
    op.alter_column("taminot_transactions", "product_id", nullable=True)

    op.create_foreign_key("fk_taminot_products_supplier", "taminot_products",
                          "taminot_suppliers", ["supplier_id"], ["id"], ondelete="RESTRICT")
    op.create_foreign_key("fk_taminot_tx_supplier", "taminot_transactions",
                          "taminot_suppliers", ["supplier_id"], ["id"], ondelete="CASCADE")
    op.create_foreign_key("fk_taminot_lists_supplier", "taminot_purchase_lists",
                          "taminot_suppliers", ["supplier_id"], ["id"], ondelete="CASCADE")
    op.create_index("ix_taminot_products_supplier_id", "taminot_products", ["supplier_id"])
    op.create_index("ix_taminot_tx_supplier_id", "taminot_transactions", ["supplier_id"])
    op.create_index("ix_taminot_lists_supplier_id", "taminot_purchase_lists", ["supplier_id"])

    # ------------------------------------------------- 5) eski matn ustuni
    if has_supplier_text:
        op.drop_column("taminot_products", "supplier")


def downgrade() -> None:
    bind = op.get_bind()
    tables = set(sa.inspect(bind).get_table_names())
    if "taminot_suppliers" not in tables:
        return

    # Matn ustunini guruh nomlaridan tiklash
    if "supplier" not in _cols(bind, "taminot_products"):
        op.add_column("taminot_products", sa.Column("supplier", sa.String(255)))
    op.execute("""
        UPDATE taminot_products p
        SET supplier = CASE WHEN s.name = 'Boshqa' THEN NULL ELSE s.name END
        FROM taminot_suppliers s
        WHERE p.supplier_id = s.id
    """)
    # Guruhga qilingan (mahsulotsiz) to'lovlar eski sxemaga sig'maydi
    op.execute("DELETE FROM taminot_transactions WHERE product_id IS NULL")

    op.drop_index("ix_taminot_lists_supplier_id", "taminot_purchase_lists")
    op.drop_index("ix_taminot_tx_supplier_id", "taminot_transactions")
    op.drop_index("ix_taminot_products_supplier_id", "taminot_products")
    op.drop_constraint("fk_taminot_lists_supplier", "taminot_purchase_lists", type_="foreignkey")
    op.drop_constraint("fk_taminot_tx_supplier", "taminot_transactions", type_="foreignkey")
    op.drop_constraint("fk_taminot_products_supplier", "taminot_products", type_="foreignkey")
    op.alter_column("taminot_transactions", "product_id", nullable=False)
    op.drop_column("taminot_purchase_lists", "supplier_id")
    op.drop_column("taminot_transactions", "supplier_id")
    op.drop_column("taminot_products", "supplier_id")
    op.drop_table("taminot_suppliers")
