"""add salary_overrides table (muayyan oy uchun oylik)

Revision ID: 20260711_01
Revises: 20260710_01
Create Date: 2026-07-11

Muayyan bitta oy uchun oylikni absolute qiymatga belgilash. Jarima/bonusdan farqi:
delta emas, o'sha oyning asosiy oyligini to'g'ridan-to'g'ri almashtiradi. Faqat
tanlangan oy o'zgaradi — stavka tarixiga (salary_rates) tegmaydi.

Idempotent: jadval allaqachon mavjud bo'lsa (dev create_all) — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260711_01"
down_revision: Union[str, None] = "20260710_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    if sa.inspect(bind).has_table("salary_overrides"):
        return
    op.create_table(
        "salary_overrides",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "employee_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("employees.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("year", sa.Integer(), nullable=False),
        sa.Column("month", sa.Integer(), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(length=3), nullable=False, server_default="UZS"),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=10), nullable=False, server_default="active"),
        sa.Column(
            "created_by_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_salary_overrides_employee_id", "salary_overrides", ["employee_id"])
    op.create_index("ix_salary_overrides_year", "salary_overrides", ["year"])
    op.create_index("ix_salary_overrides_month", "salary_overrides", ["month"])


def downgrade() -> None:
    bind = op.get_bind()
    if not sa.inspect(bind).has_table("salary_overrides"):
        return
    op.drop_index("ix_salary_overrides_month", table_name="salary_overrides")
    op.drop_index("ix_salary_overrides_year", table_name="salary_overrides")
    op.drop_index("ix_salary_overrides_employee_id", table_name="salary_overrides")
    op.drop_table("salary_overrides")
