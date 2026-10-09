"""Bosh sahifa uchun alohida ruxsat: dashboard:read.

Avval Bosh sahifa `reports` moduliga bog'langan edi. Endi u rol matritsasida
alohida qator. Hozir Bosh sahifani ko'radiganlar (rolida istalgan `reports:<verb>`
bor) undan ayrilmasligi uchun ularga `dashboard:read` qo'shiladi. Wildcard
(`*`, `*:*`, `*:read`) rollar avtomatik qamrab olinadi — ularga tegilmaydi.

Revision ID: 20261009_01
Revises: 20261007_02
"""
import json

import sqlalchemy as sa
from alembic import op

revision = "20261009_01"
down_revision = "20261007_02"
branch_labels = None
depends_on = None

DASHBOARD_READ = "dashboard:read"


def _load(perms):
    """JSONB qiymatdan ruxsatlar ro'yxati va konteyner shaklini ajratish."""
    if perms is None:
        return [], None
    data = perms
    if isinstance(data, str):
        data = json.loads(data)
    if isinstance(data, dict):
        return list(data.get("permissions") or []), data
    if isinstance(data, list):
        return list(data), None
    return [], None


def _save(conn, rid, items, container):
    if container is not None:
        container = dict(container)
        container["permissions"] = items
        newval = container
    else:
        newval = items
    conn.execute(
        sa.text("UPDATE roles SET permissions = CAST(:p AS jsonb) WHERE id = CAST(:id AS uuid)"),
        {"p": json.dumps(newval), "id": str(rid)},
    )


def upgrade() -> None:
    conn = op.get_bind()
    for rid, perms in conn.execute(sa.text("SELECT id, permissions FROM roles")).fetchall():
        items, container = _load(perms)
        has_reports = any(isinstance(p, str) and p.startswith("reports:") for p in items)
        if has_reports and DASHBOARD_READ not in items:
            _save(conn, rid, items + [DASHBOARD_READ], container)


def downgrade() -> None:
    conn = op.get_bind()
    for rid, perms in conn.execute(sa.text("SELECT id, permissions FROM roles")).fetchall():
        items, container = _load(perms)
        kept = [p for p in items if not (isinstance(p, str) and p.startswith("dashboard:"))]
        if len(kept) != len(items):
            _save(conn, rid, kept, container)
