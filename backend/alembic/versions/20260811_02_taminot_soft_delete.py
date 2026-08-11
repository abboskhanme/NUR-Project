"""ta'minot: harakatlar o'chirilganda yo'qolmaydi — arxivga o'tadi

Revision ID: 20260811_02
Revises: 20260811_01
Create Date: 2026-08-11

Ilgari «O'chirish» bosilganda tranzaksiya bazadan butunlay yo'q bo'lardi va
nima bo'lganini keyin tekshirib bo'lmasdi. Endi u ARXIVGA o'tadi:

  - `deleted_at` to'ldiriladi — shu daqiqadan boshlab yozuv barcha hisob-kitobga
    (qarz, to'langan, ombor qoldig'i) QO'SHILMAYDI, ya'ni summa to'g'ri ayiriladi;
  - lekin tarixda ustidan chizilgan holda ko'rinib turadi va kerak bo'lsa
    tiklanadi.

Mahsulot uchun ham shunday: harakatlari bo'lgan mahsulot o'chirilsa, u va uning
yozuvlari arxivga o'tadi — pul tarixi hech qachon yo'qolmaydi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20260811_02"
down_revision: Union[str, None] = "20260811_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

UUID = postgresql.UUID(as_uuid=True)


def _cols(bind, table: str) -> set[str]:
    return {c["name"] for c in sa.inspect(bind).get_columns(table)}


def upgrade() -> None:
    bind = op.get_bind()

    tx_cols = _cols(bind, "taminot_transactions")
    if "deleted_at" not in tx_cols:
        op.add_column("taminot_transactions",
                      sa.Column("deleted_at", sa.DateTime(timezone=True)))
        op.add_column("taminot_transactions",
                      sa.Column("deleted_by_id", UUID,
                                sa.ForeignKey("users.id", ondelete="SET NULL")))
        # Hisob-kitob deyarli doim FAQAT arxivlanmagan yozuvlar bo'yicha ketadi,
        # shuning uchun qisman indeks — kichik va tez
        op.execute(
            "CREATE INDEX ix_taminot_tx_active ON taminot_transactions (supplier_id) "
            "WHERE deleted_at IS NULL"
        )

    prod_cols = _cols(bind, "taminot_products")
    if "deleted_at" not in prod_cols:
        op.add_column("taminot_products",
                      sa.Column("deleted_at", sa.DateTime(timezone=True)))
        op.execute(
            "CREATE INDEX ix_taminot_products_active ON taminot_products (scope) "
            "WHERE deleted_at IS NULL"
        )


def downgrade() -> None:
    bind = op.get_bind()
    # Arxivdagilar eski sxemada o'rin topmaydi — ular haqiqatan o'chiriladi
    op.execute("DELETE FROM taminot_transactions WHERE deleted_at IS NOT NULL")
    op.execute("DELETE FROM taminot_products WHERE deleted_at IS NOT NULL")

    if "deleted_at" in _cols(bind, "taminot_products"):
        op.execute("DROP INDEX IF EXISTS ix_taminot_products_active")
        op.drop_column("taminot_products", "deleted_at")
    if "deleted_at" in _cols(bind, "taminot_transactions"):
        op.execute("DROP INDEX IF EXISTS ix_taminot_tx_active")
        op.drop_column("taminot_transactions", "deleted_by_id")
        op.drop_column("taminot_transactions", "deleted_at")
