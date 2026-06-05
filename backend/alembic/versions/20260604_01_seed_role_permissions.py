"""Mavjud rollarga standart modul ruxsatlarini berish.

Permission tizimi endi backend routelarda majburiy bo'lgani uchun,
permissions bo'sh bo'lgan eski rollarga hozirgi xulq-atvoriga mos
standart ruxsatlar yoziladi. Qo'lda o'zgartirilgan rollar tegilmaydi.

Revision ID: 20260604_01
Revises: 20260603_01
"""
import json

import sqlalchemy as sa
from alembic import op

revision = "20260604_01"
down_revision = "20260603_01"
branch_labels = None
depends_on = None


DEFAULT_PERMISSIONS: dict[str, list[str]] = {
    # Bosh direktor — hamma modulga to'liq (lekin tahrirlash mumkin bo'lgan rol)
    "director": ["*"],
    # Moliya menejeri — moliya to'liq, hisobot/sotuv/mijoz/xodimlarni ko'rish
    "finance_manager": [
        "finance:*", "reports:read", "reports:export",
        "orders:read", "customers:read", "hr:read", "products:read",
    ],
    # HR menejeri — xodimlar to'liq, hisobotlarni ko'rish
    "hr_manager": ["hr:*", "reports:read"],
    # Sotuv menejeri — sotuv/mijozlar to'liq, mahsulot/servis/hisobotni ko'rish
    "sales_manager": [
        "orders:*", "customers:*",
        "products:read", "service:read", "reports:read",
    ],
    # Sotuvchi — buyurtma va mijoz yaratish/ko'rish
    "salesperson": [
        "orders:read", "orders:write",
        "customers:read", "customers:write", "products:read",
    ],
    # Servis menejeri — servis to'liq, mijoz/mahsulot/sotuvni ko'rish
    "service_manager": [
        "service:*", "customers:read", "products:read",
        "orders:read", "reports:read",
    ],
    # Servis ustasi — arizalarni ko'rish/yuritish
    "service_technician": ["service:read", "service:write", "customers:read"],
    # Taminotchi — ta'minot bo'limi
    "supplier": ["supply:read", "supply:write"],
}


def upgrade() -> None:
    conn = op.get_bind()
    for name, perms in DEFAULT_PERMISSIONS.items():
        conn.execute(
            sa.text(
                """
                UPDATE roles
                SET permissions = CAST(:perms AS jsonb)
                WHERE name = :name
                  AND (
                    permissions IS NULL
                    OR permissions = '{}'::jsonb
                    OR COALESCE(jsonb_array_length(permissions->'permissions'), 0) = 0
                  )
                """
            ),
            {"perms": json.dumps({"permissions": perms}), "name": name},
        )


def downgrade() -> None:
    # Seed'ni qaytarish shart emas — ruxsatlar UI orqali boshqariladi
    pass
