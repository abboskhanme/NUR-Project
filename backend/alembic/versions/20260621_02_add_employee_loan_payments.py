"""add employee_loan_payments table

Revision ID: 20260621_02
Revises: 20260621_01
Create Date: 2026-06-21

Xodim qarzini so'ndirish (qaytarish) tarixi. Qarz qoldig'i =
employee_loans.amount − shu qarzga tegishli to'lovlar yig'indisi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260621_02"
down_revision: Union[str, None] = "20260621_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "employee_loan_payments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "loan_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("employee_loans.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("pay_date", sa.Date(), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
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
        "ix_employee_loan_payments_loan_id", "employee_loan_payments", ["loan_id"]
    )
    op.create_index(
        "ix_employee_loan_payments_pay_date", "employee_loan_payments", ["pay_date"]
    )


def downgrade() -> None:
    op.drop_index("ix_employee_loan_payments_pay_date", table_name="employee_loan_payments")
    op.drop_index("ix_employee_loan_payments_loan_id", table_name="employee_loan_payments")
    op.drop_table("employee_loan_payments")
