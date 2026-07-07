"""add salary_rates table (stavka tarixi)

Revision ID: 20260707_01
Revises: 20260701_01
Create Date: 2026-07-07

Xodim oylik stavkasi tarixi — qaysi sanadan qancha. Hisob har oy o'sha oyda
amal qilgan stavka bilan bajariladi, shuning uchun stavka ko'tarilsa eski
oylarning oyligi o'zgarmaydi. Bu jadval ilgari faqat dev'da create_all orqali
yaratilar edi — migratsiyasi yo'q edi; shu sabab prod'da "stavka qo'shish"
ishlamas edi.

Idempotent: jadval allaqachon mavjud bo'lsa (dev create_all) — o'tkazib yuboradi.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "20260707_01"
down_revision: Union[str, None] = "20260701_01"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    if sa.inspect(bind).has_table("salary_rates"):
        return
    op.create_table(
        "salary_rates",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "employee_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("employees.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("effective_from", sa.Date(), nullable=False),
        sa.Column("salary_type", sa.String(length=20), nullable=False, server_default="hourly"),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(length=3), nullable=False, server_default="UZS"),
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
    op.create_index("ix_salary_rates_employee_id", "salary_rates", ["employee_id"])
    op.create_index("ix_salary_rates_effective_from", "salary_rates", ["effective_from"])


def downgrade() -> None:
    bind = op.get_bind()
    if not sa.inspect(bind).has_table("salary_rates"):
        return
    op.drop_index("ix_salary_rates_effective_from", table_name="salary_rates")
    op.drop_index("ix_salary_rates_employee_id", table_name="salary_rates")
    op.drop_table("salary_rates")
