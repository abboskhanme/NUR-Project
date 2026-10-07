"""Xodim qarzlari: yumshoq o'chirish (to'liq tarix uchun)

Revision ID: 20261007_02
Revises: 20261007_01
Create Date: 2026-10-07

employee_loans va employee_loan_payments'ga deleted_at / deleted_by_id qo'shiladi.
O'chirilgan qarz/to'lov endi bazadan o'chmaydi — tarixda "o'chirilgan" bo'lib qoladi.
Mavjud yozuvlar o'zgarmaydi (ikkala ustun ham NULL).
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20261007_02"
down_revision: Union[str, None] = "20261007_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TABLES = ("employee_loans", "employee_loan_payments")


def upgrade() -> None:
    for table in TABLES:
        op.add_column(table, sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True))
        op.add_column(table, sa.Column("deleted_by_id", postgresql.UUID(as_uuid=True), nullable=True))
        op.create_foreign_key(
            f"fk_{table}_deleted_by_id_users", table, "users",
            ["deleted_by_id"], ["id"], ondelete="SET NULL",
        )


def downgrade() -> None:
    for table in TABLES:
        op.drop_constraint(f"fk_{table}_deleted_by_id_users", table, type_="foreignkey")
        op.drop_column(table, "deleted_by_id")
        op.drop_column(table, "deleted_at")
