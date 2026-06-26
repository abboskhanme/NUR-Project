"""Moliya: to'lov turi (naqd/karta) + ichki o'tkazma belgisi + kassalarni 3 taga birlashtirish.

- finance_transactions ga `method` (naqd/karta) ustuni qo'shiladi.
- Eski yozuvlar `method='naqd'` deb belgilanadi.
- Operatsion UZS hisobvaraqlari -> bitta "Kassa UZS",
  operatsion USD -> "Kassa USD", gazna -> "G'azna" ga birlashtiriladi.
  Tranzaksiyalar yagona kassaga ko'chiriladi, balanslar yig'iladi, ortiqchalari o'chiriladi.

Revision ID: 20260626_01
Revises: 20260625_05
"""
import sqlalchemy as sa
from alembic import op

revision = "20260626_01"
down_revision = "20260625_05"
branch_labels = None
depends_on = None


def _consolidate(conn, currency: str, ledger: str, target_name: str) -> None:
    """Bir xil (currency, ledger) guruhdagi hisobvaraqlarni bittaga birlashtiradi.

    DIQQAT: faqat AYNAN bir xil valyuta birlashtiriladi — turli valyutalar
    hech qachon qo'shilmaydi (balans buzilmasligi uchun)."""
    rows = conn.execute(
        sa.text(
            "SELECT id, balance FROM accounts WHERE currency = :c AND ledger = :l "
            "ORDER BY balance DESC NULLS LAST, name"
        ),
        {"c": currency, "l": ledger},
    ).fetchall()

    if not rows:
        # Bo'sh baza (yangi o'rnatish) — standart kassani yaratamiz
        conn.execute(
            sa.text(
                "INSERT INTO accounts (id, name, currency, ledger, balance) "
                "VALUES (gen_random_uuid(), :n, :c, :l, 0)"
            ),
            {"n": target_name, "c": currency, "l": ledger},
        )
        return

    canon_id = rows[0][0]
    total = sum((r[1] or 0) for r in rows)
    other_ids = [r[0] for r in rows[1:]]

    # Har bir ortiqcha kassani yakka-yakka ko'chirib o'chiramiz (driver-betaraf)
    for oid in other_ids:
        conn.execute(
            sa.text("UPDATE finance_transactions SET account_id = :cid WHERE account_id = :oid"),
            {"cid": canon_id, "oid": oid},
        )
        conn.execute(sa.text("DELETE FROM accounts WHERE id = :oid"), {"oid": oid})

    conn.execute(
        sa.text("UPDATE accounts SET balance = :b, name = :n, currency = :c, ledger = :l WHERE id = :cid"),
        {"b": total, "n": target_name, "c": currency, "l": ledger, "cid": canon_id},
    )


def upgrade() -> None:
    # 1) Yangi ustun
    op.add_column("finance_transactions", sa.Column("method", sa.String(length=10), nullable=True))

    conn = op.get_bind()

    # 2) Eski yozuvlar uchun standart to'lov turi
    conn.execute(sa.text("UPDATE finance_transactions SET method = 'naqd' WHERE method IS NULL"))

    # 3) G'azna faqat USD bo'ladi. Agar xato bilan USD bo'lmagan "gazna" hisob bo'lsa,
    #    u aslida oddiy operatsion pul — uni operatsionga o'tkazamiz (so'm g'aznada qolmasin).
    conn.execute(sa.text("UPDATE accounts SET ledger = 'operational' WHERE ledger = 'gazna' AND currency <> 'USD'"))

    # 4) Kassalarni birlashtirish (har biri AYNAN bir valyuta)
    _consolidate(conn, "UZS", "operational", "Kassa UZS")
    _consolidate(conn, "USD", "operational", "Kassa USD")
    _consolidate(conn, "USD", "gazna", "G'azna")


def downgrade() -> None:
    # Birlashtirilgan kassalarni qaytarib bo'lmaydi; faqat ustun olib tashlanadi.
    op.drop_column("finance_transactions", "method")
