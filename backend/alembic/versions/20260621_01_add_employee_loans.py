"""add employee_loans table

Revision ID: 20260621_01
Revises: 20260620_01
Create Date: 2026-06-21

Bizdan qarzdor xodimlar reyestri — xodimning kompaniya/direktor oldidagi
alohida qarzi (oylikdan tashqari). Joriy summa qo'lda yuritiladi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260621_01"
down_revision: Union[str, None] = "20260620_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "employee_loans",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "employee_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("employees.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(length=3), nullable=False, server_default="UZS"),
        sa.Column("source", sa.String(length=20), nullable=False, server_default="firma"),
        sa.Column("loan_date", sa.Date(), nullable=False),
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
    op.create_index("ix_employee_loans_employee_id", "employee_loans", ["employee_id"])
    op.create_index("ix_employee_loans_loan_date", "employee_loans", ["loan_date"])


def downgrade() -> None:
    op.drop_index("ix_employee_loans_loan_date", table_name="employee_loans")
    op.drop_index("ix_employee_loans_employee_id", table_name="employee_loans")
    op.drop_table("employee_loans")
