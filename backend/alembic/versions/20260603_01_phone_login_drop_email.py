"""phone login: drop email, make phone unique not null

Revision ID: 20260603_01
Revises: 20260602_01
Create Date: 2026-06-03

Login endi email orqali emas, telefon raqam orqali bo'ladi. users.email
butunlay olib tashlanadi, users.phone esa unique + NOT NULL login
identifikatoriga aylanadi. Mavjud null phone'lar backfill qilinadi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260603_01"
down_revision: Union[str, None] = "20260602_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1) phone'siz (null/bo'sh) mavjud foydalanuvchilarga vaqtinchalik unikal qiymat —
    #    id'ning birinchi 12 ta hex belgisidan (umumiy uzunlik <= 20).
    op.execute(
        """
        UPDATE users
        SET phone = 'tmp+' || substr(replace(id::text, '-', ''), 1, 12)
        WHERE phone IS NULL OR btrim(phone) = ''
        """
    )

    # 2) ortib qolishi mumkin bo'lgan dublikat phone'larni unikal qilamiz
    op.execute(
        """
        UPDATE users u
        SET phone = u.phone || '-' || substr(replace(u.id::text, '-', ''), 1, 6)
        WHERE EXISTS (
            SELECT 1 FROM users u2
            WHERE u2.phone = u.phone AND u2.id <> u.id
        )
        """
    )

    # 3) phone -> NOT NULL + unique index
    op.alter_column("users", "phone", existing_type=sa.String(length=20), nullable=False)
    op.create_index("ix_users_phone", "users", ["phone"], unique=True)

    # 4) email index va ustunini olib tashlaymiz (index nomi farq qilishi mumkin —
    #    IF EXISTS bilan; ustun drop bo'lganda bog'liq index/constraint ham ketadi)
    op.execute("DROP INDEX IF EXISTS ix_users_email")
    op.drop_column("users", "email")


def downgrade() -> None:
    # email ustunini qaytaramiz (ma'lumot tiklanmaydi — nullable)
    op.add_column("users", sa.Column("email", sa.String(length=255), nullable=True))
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.drop_index("ix_users_phone", table_name="users")
    op.alter_column("users", "phone", existing_type=sa.String(length=20), nullable=True)
