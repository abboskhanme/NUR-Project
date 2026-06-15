"""xodim turi — employees.department_type ("office"/"assembly"/"production")

Ofis bo'limi (office), yig'uv bo'limi (assembly) va ishlab chiqarish (production)
bo'limlarini ajratish uchun. Mavjud ofis xodimlari avtomatik "office" deb belgilanadi.

Revision ID: 20260615_13
Revises: 20260615_12
Create Date: 2026-06-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260615_13"
down_revision: Union[str, None] = "20260615_12"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "employees",
        sa.Column("department_type", sa.String(length=20), nullable=False,
                  server_default="production"),
    )
    # Mavjud ofis xodimlarini "office" deb belgilaymiz
    op.execute(
        "UPDATE employees SET department_type = 'office' "
        "WHERE employment_type = 'office'"
    )


def downgrade() -> None:
    op.drop_column("employees", "department_type")
