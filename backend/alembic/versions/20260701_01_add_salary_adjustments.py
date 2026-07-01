"""add salary_adjustments table (jarima / bonus)

Revision ID: 20260701_01
Revises: 20260627_02
Create Date: 2026-07-01

Xodim oyligiga tuzatish: jarima (penalty — kamaytiradi) yoki bonus (oshiradi).
Naqd pul harakati emas — faqat tanlangan (year, month) oyning hisoblangan
oyligini o'zgartiradi. Yumshoq o'chirish: status active/void.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260701_01"
down_revision: Union[str, None] = "20260627_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "salary_adjustments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "employee_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("employees.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("year", sa.Integer(), nullable=False),
        sa.Column("month", sa.Integer(), nullable=False),
        sa.Column("kind", sa.String(length=10), nullable=False),
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
    op.create_index(
        "ix_salary_adjustments_employee_id", "salary_adjustments", ["employee_id"]
    )
    op.create_index("ix_salary_adjustments_year", "salary_adjustments", ["year"])
    op.create_index("ix_salary_adjustments_month", "salary_adjustments", ["month"])


def downgrade() -> None:
    op.drop_index("ix_salary_adjustments_month", table_name="salary_adjustments")
    op.drop_index("ix_salary_adjustments_year", table_name="salary_adjustments")
    op.drop_index("ix_salary_adjustments_employee_id", table_name="salary_adjustments")
    op.drop_table("salary_adjustments")
