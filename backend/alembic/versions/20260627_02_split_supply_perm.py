"""Ta'minot ruxsatini ikkiga ajratish: supply -> supply_ichki + supply_tashqi.

Ichki va tashqi ta'minot endi alohida lavozim sifatida beriladi. Mavjud rollarda
`supply:<verb>` bo'lsa, u HAR IKKALA yangi ruxsatga (`supply_ichki:<verb>` va
`supply_tashqi:<verb>`) ko'chiriladi — shunda hozirgi ta'minotchilar kirishdan
ayrilmaydi (keyin kerakmasini rol tahririda olib tashlash mumkin).

Revision ID: 20260627_02
Revises: 20260627_01
"""
import json

import sqlalchemy as sa
from alembic import op

revision = "20260627_02"
down_revision = "20260627_01"
branch_labels = None
depends_on = None


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


def _rewrite(map_one):
    conn = op.get_bind()
    rows = conn.execute(sa.text("SELECT id, permissions FROM roles")).fetchall()
    for rid, perms in rows:
        items, container = _load(perms)
        if not items:
            continue
        out: list[str] = []
        seen: set[str] = set()
        changed = False
        for p in items:
            replacements = map_one(p) if isinstance(p, str) else None
            if replacements is None:
                if p not in seen:
                    out.append(p); seen.add(p)
            else:
                changed = True
                for np in replacements:
                    if np not in seen:
                        out.append(np); seen.add(np)
        if changed:
            _save(conn, rid, out, container)


def upgrade() -> None:
    def m(p: str):
        if p.startswith("supply:"):
            verb = p.split(":", 1)[1]
            return [f"supply_ichki:{verb}", f"supply_tashqi:{verb}"]
        return None
    _rewrite(m)


def downgrade() -> None:
    def m(p: str):
        if p.startswith("supply_ichki:") or p.startswith("supply_tashqi:"):
            verb = p.split(":", 1)[1]
            return [f"supply:{verb}"]
        return None
    _rewrite(m)
