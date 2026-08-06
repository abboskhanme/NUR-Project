"""accounts.payment_type + karta kassalari (naqd/karta aylanmasini ajratish)

Revision ID: 20260806_01
Revises: 20260730_03
Create Date: 2026-08-06

Ilgari moliya faqat NAQD aylanmani yuritardi: tranzaksiyadagi `method`
("naqd"/"karta") faqat filtr uchun edi va ikkalasi ham bitta kassa balansiga
tushardi. Endi har bir kassa `payment_type` ga ega va karta aylanmasi alohida
hisoblanadi.

Nima qiladi:
  1. `accounts.payment_type` ustunini qo'shadi (default "naqd") — mavjud
     kassalar naqd bo'lib qoladi, balanslari o'zgarmaydi.
  2. Har bir valyuta uchun karta kassasini yaratadi (balans 0 dan boshlanadi).
     G'azna bundan mustasno — u naqd dollar jamg'armasi bo'lib qoladi.

Idempotent: ustun/kassa allaqachon bo'lsa — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260806_01"
down_revision: Union[str, None] = "20260730_03"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# (nom, valyuta) — yaratiladigan karta kassalari
CARD_ACCOUNTS = (("Karta UZS", "UZS"), ("Karta USD", "USD"))


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    cols = {c["name"] for c in inspector.get_columns("accounts")}

    if "payment_type" not in cols:
        op.add_column(
            "accounts",
            sa.Column("payment_type", sa.String(length=10),
                      nullable=False, server_default="naqd"),
        )

    # Mavjud kassalar naqd bo'lib qoladi (server_default allaqachon shunday,
    # lekin ustun ilgari qo'lda qo'shilgan bo'lsa ham to'g'ri bo'lsin).
    bind.execute(sa.text(
        "UPDATE accounts SET payment_type = 'naqd' WHERE payment_type IS NULL"
    ))

    # Karta kassalarini yaratamiz (faqat yo'q bo'lsa)
    for name, currency in CARD_ACCOUNTS:
        exists = bind.execute(sa.text(
            "SELECT 1 FROM accounts "
            "WHERE ledger <> 'gazna' AND currency = :c AND payment_type = 'karta' "
            "LIMIT 1"
        ), {"c": currency}).first()
        if exists:
            continue
        bind.execute(sa.text(
            "INSERT INTO accounts (id, name, currency, ledger, payment_type, balance, "
            "created_at, updated_at) "
            "VALUES (gen_random_uuid(), :n, :c, 'operational', 'karta', 0, now(), now())"
        ), {"n": name, "c": currency})


def downgrade() -> None:
    bind = op.get_bind()
    # Faqat bo'sh (harakatsiz) karta kassalarini olib tashlaymiz
    bind.execute(sa.text(
        "DELETE FROM accounts WHERE payment_type = 'karta' AND balance = 0 "
        "AND id NOT IN (SELECT account_id FROM finance_transactions "
        "WHERE account_id IS NOT NULL)"
    ))
    inspector = sa.inspect(bind)
    cols = {c["name"] for c in inspector.get_columns("accounts")}
    if "payment_type" in cols:
        op.drop_column("accounts", "payment_type")
