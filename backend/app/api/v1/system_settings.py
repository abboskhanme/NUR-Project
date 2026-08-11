"""Tizim sozlamalari — Instagram AI agenti (.env) ni UI'dan boshqarish.

Ikki xil kirish:
  • Super-admin (`require_superadmin`) — katalog + qiymatlar (sirlar maskalangan),
    yangilash.
  • Tashqi agent (`X-Agent-Key`) — `GET /agent-config` orqali HAQIQIY qiymatlarni
    oladi va ishlab turgan holda qo'llaydi (avtomatik yangilanadi).

Qiymat manbai: FAQAT `system_settings` (DB). Bo'sh bo'lsa agent O'Z .env qiymatini
ishlatadi (fallback agent tomonda). Faqat katalogdagi kalitlar qabul qilinadi.
"""
from __future__ import annotations

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.leads import require_agent_key
from app.core.dependencies import CurrentUser
from app.core.permissions import is_superadmin
from app.core.crypto import decrypt_secret, encrypt_secret
from app.core.system_settings import ALLOWED_KEYS, CATALOG, CATALOG_BY_KEY, GROUPS
from app.db.session import get_db
from app.models.system import SystemSetting


async def require_superadmin(user: CurrentUser) -> None:
    if not is_superadmin(user):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Faqat super-admin uchun")


# Odam (super-admin) uchun
router = APIRouter(dependencies=[Depends(require_superadmin)])
# Tashqi agent uchun (servis kaliti bilan)
agent_router = APIRouter()


# ===========================================================================
# Yordamchilar
# ===========================================================================
async def _db_values(db: AsyncSession) -> dict[str, str]:
    """DB qiymatlari — maxfiylari shifrdan ochilgan holda."""
    rows = (await db.execute(select(SystemSetting))).scalars().all()
    return {
        r.key: decrypt_secret(r.value)
        for r in rows
        if r.value is not None
    }


def _store_value(key: str, plain: str) -> str:
    """Bazaga yozishdan oldin: maxfiy kalit bo'lsa shifrlaymiz."""
    item = CATALOG_BY_KEY.get(key)
    return encrypt_secret(plain) if (item and item.secret) else plain


async def _upsert(db: AsyncSession, key: str, plain: str) -> None:
    row = await db.get(SystemSetting, key)
    value = _store_value(key, plain)
    if row:
        row.value = value
    else:
        db.add(SystemSetting(key=key, value=value))


def _resolve(key: str, db_values: dict[str, str]) -> str:
    """Qiymat manbai — FAQAT DB.

    Bo'sh bo'lsa "" qaytadi va agent O'Z .env qiymatini ishlatadi (fallback
    agent tomonda). ERP'ning o'z .env'iga (masalan ERP Telegram boti) qaytmaymiz
    — bu kalitlar agentники, ERP'ники emas.
    """
    return db_values.get(key) or ""


def _mask(value: str) -> str:
    if not value:
        return ""
    return "••••" + value[-4:] if len(value) > 4 else "••••"


# ===========================================================================
# Super-admin: ko'rish
# ===========================================================================
@router.get("")
async def get_settings(db: Annotated[AsyncSession, Depends(get_db)]):
    dbv = await _db_values(db)
    groups = []
    for gid, gtitle in GROUPS.items():
        items = []
        for item in CATALOG:
            # hidden — «Ulash» tugmasi avtomatik to'ldiradigan yoki texnik
            # kalitlar. Agent ularni oladi, lekin ekranda ko'rsatmaymiz.
            if item.group != gid or item.hidden:
                continue
            resolved = _resolve(item.key, dbv)
            in_db = item.key in dbv
            entry: dict = {
                "key": item.key,
                "label": item.label,
                "type": item.type,
                "secret": item.secret,
                "options": list(item.options),
                "placeholder": item.placeholder,
                "help": item.help,
                "is_set": bool(resolved),
                "from_env": bool(resolved) and not in_db,  # .env dan kelgan (DB'da yo'q)
            }
            if item.secret:
                entry["value"] = ""            # sirni qaytarmaymiz
                entry["masked"] = _mask(resolved)
            else:
                entry["value"] = resolved
            items.append(entry)
        groups.append({"id": gid, "title": gtitle, "items": items})
    # Instagram ulanganmi — token/ID yashirin bo'lgani uchun alohida bayroq
    # (UI shu asosda «Ulash» / «Qayta ulash» ni ko'rsatadi).
    connected = bool(_resolve("IG_ACCESS_TOKEN", dbv) and _resolve("IG_USER_ID", dbv))
    return {"groups": groups, "instagram_connected": connected}


# ===========================================================================
# Super-admin: yangilash
# ===========================================================================
class UpdateIn(BaseModel):
    # {key: value}. Bo'sh/None qiymat — qatorni o'chiradi (.env fallback qoladi).
    values: dict[str, Optional[str]]


@router.put("")
async def update_settings(
    payload: UpdateIn, db: Annotated[AsyncSession, Depends(get_db)]
):
    unknown = set(payload.values) - ALLOWED_KEYS
    if unknown:
        raise HTTPException(400, f"Noma'lum kalit(lar): {', '.join(sorted(unknown))}")

    for key, val in payload.values.items():
        if val is None or val == "":
            await db.execute(delete(SystemSetting).where(SystemSetting.key == key))
            continue
        await _upsert(db, key, val)
    await db.commit()
    return await get_settings(db)


# ===========================================================================
# Tashqi agent: haqiqiy qiymatlar (X-Agent-Key bilan)
# ===========================================================================
@agent_router.get("/agent-config", dependencies=[Depends(require_agent_key)])
async def agent_config(db: Annotated[AsyncSession, Depends(get_db)]):
    dbv = await _db_values(db)
    return {item.key: _resolve(item.key, dbv) for item in CATALOG}


# Agent OAuth orqali olgan qiymatlarni ERP'ga qaytarib yozadi (Instagram ulash
# va 60 kunlik tokenni avtomatik yangilash). Boshqa kalitlarga tegolmaydi —
# ro'yxat ataylab tor, aks holda servis kaliti butun sozlamani boshqarardi.
AGENT_WRITABLE_KEYS = frozenset(
    {"IG_ACCESS_TOKEN", "IG_USER_ID", "IG_ACCOUNT_ID", "IG_USERNAME",
     "IG_TOKEN_ISSUED_AT"}
)


@agent_router.put("/agent-config", dependencies=[Depends(require_agent_key)])
async def agent_config_write(
    payload: UpdateIn, db: Annotated[AsyncSession, Depends(get_db)]
):
    unknown = set(payload.values) - AGENT_WRITABLE_KEYS
    if unknown:
        raise HTTPException(
            403, f"Agent bu kalitlarni yoza olmaydi: {', '.join(sorted(unknown))}"
        )
    for key, val in payload.values.items():
        if not val:
            continue
        await _upsert(db, key, val)
    await db.commit()
    return {"saved": sorted(payload.values)}
