"""add monthly_goals table

Revision ID: 20260625_03
Revises: 20260625_02
Create Date: 2026-06-25

Oylik maqsad — har oy uchun sotuv soni va tushum (UZS) bo'yicha bitta yozuv.
Bosh sahifada hammaga ko'rinadi; faqat `system:goals_manage` ruxsatli belgilaydi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260625_03"
down_revision: Union[str, None] = "20260625_02"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "monthly_goals",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("period_month", sa.Date(), nullable=False),
        sa.Column("target_orders", sa.Integer(), nullable=True),
        sa.Column("target_revenue_uzs", sa.Numeric(18, 2), nullable=True),
        sa.Column(
            "set_by_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_monthly_goals_period_month", "monthly_goals",
                    ["period_month"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_monthly_goals_period_month", table_name="monthly_goals")
    op.drop_table("monthly_goals")
