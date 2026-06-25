"""add body_size to production_records (kotyol tanasi)

Revision ID: 20260625_04
Revises: 20260625_03
Create Date: 2026-06-25

Ishlab chiqarishga "tana" (kotyol tanasi) bo'limi qo'shildi — base ishlab
chiqarishdan keladigan kotyol tanalari faqat o'lcham + yo'nalish + soni bilan
hisoblanadi. O'lcham uchun yangi `body_size` ustuni.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260625_04"
down_revision: Union[str, None] = "20260625_03"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("production_records",
                  sa.Column("body_size", sa.String(length=50), nullable=True))


def downgrade() -> None:
    op.drop_column("production_records", "body_size")
