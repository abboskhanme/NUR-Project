"""ombor turlarini sotuv mahsulotlaridan ajratish (product_type='warehouse')

Ombor (SKLAD KATYOL) endi o'zining alohida turlar katalogiga ega — sotuvdagi
va "Mahsulotlar" menyusidagi (main/additional) mahsulotlar bilan aralashmaydi.

Mavjud ma'lumotlar:
  * Faqat omborda ishlatilgan (buyurtmada hech qachon ishlatilmagan) mahsulot
    to'g'ridan-to'g'ri 'warehouse' turiga o'tkaziladi.
  * Ham sotuvda (order_items), ham omborda ishlatilgan mahsulot uchun 'warehouse'
    nusxasi yaratiladi va inventory shu nusxaga qayta bog'lanadi — sotuv katalogi
    o'zgarmaydi.

Revision ID: 20260615_01
Revises: 20260613_01
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260615_01"
down_revision: Union[str, None] = "20260613_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    rows = bind.execute(sa.text(
        "SELECT DISTINCT product_id FROM inventory WHERE product_id IS NOT NULL"
    )).fetchall()
    for (pid,) in rows:
        used_in_sales = bind.execute(sa.text(
            "SELECT 1 FROM order_items WHERE product_id = CAST(:pid AS uuid) LIMIT 1"
        ), {"pid": str(pid)}).first()
        if used_in_sales:
            # Sotuvda ham ishlatiladi — alohida 'warehouse' nusxasini yaratamiz
            new_id = bind.execute(sa.text(
                """
                INSERT INTO products
                  (id, product_type, model, kvm, name, unit, sku, bunker_direction,
                   description, base_price_usd, specs, status)
                SELECT gen_random_uuid(), 'warehouse', model, kvm, name, unit, NULL,
                       bunker_direction, description, base_price_usd, specs, status
                FROM products WHERE id = CAST(:pid AS uuid)
                RETURNING id
                """
            ), {"pid": str(pid)}).scalar()
            bind.execute(sa.text(
                "UPDATE inventory SET product_id = CAST(:new AS uuid) "
                "WHERE product_id = CAST(:pid AS uuid)"
            ), {"new": str(new_id), "pid": str(pid)})
        else:
            # Faqat omborda — joyida qayta turlaymiz
            bind.execute(sa.text(
                "UPDATE products SET product_type = 'warehouse' "
                "WHERE id = CAST(:pid AS uuid)"
            ), {"pid": str(pid)})


def downgrade() -> None:
    # Eng yaxshi harakat: ombor turlarini yana 'main' ga qaytaramiz
    # (yaratilgan nusxalar saqlanib qoladi).
    op.execute("UPDATE products SET product_type = 'main' WHERE product_type = 'warehouse'")
