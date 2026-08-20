"""ERP'ning o'z sozlamalarini `system_settings` (DB) dan o'qish.

Nega alohida modul: `app.core.config.settings` — jarayon ishga tushganda .env
dan bir marta o'qiladi va o'zgarmaydi. Super-admin UI'dan o'zgartiradigan
qiymatlar esa bazada turadi va ishlab turgan holda yangilanishi kerak.

Ustuvorlik: **DB > .env**. Ya'ni sozlama UI'da to'ldirilgan bo'lsa — o'sha,
bo'lmasa eski .env qiymati ishlaydi (mavjud o'rnatmalar buzilmaydi).

Maxfiy qiymatlar bazada shifrlangan — bu yerda ochib beriladi.
"""
from __future__ import annotations

from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings as env_settings
from app.core.crypto import decrypt_secret
from app.core.system_settings import CATALOG_BY_KEY
from app.db.session import AsyncSessionLocal
from app.models.system import SystemSetting

# Sozlama kaliti -> eski .env nomi (orqaga moslik uchun zaxira qiymat).
ENV_FALLBACK: dict[str, str] = {
    "ERP_BOT_TOKEN": "TELEGRAM_BOT_TOKEN",
    "ERP_BOT_USERNAME": "TELEGRAM_BOT_USERNAME",
    "ERP_BOT_ADMIN_CHAT_IDS": "TELEGRAM_ADMIN_CHAT_IDS",
    "ERP_BOT_REPORT_TIME": "TELEGRAM_REPORT_TIME",
    "ERP_BOT_NOTIFY_NEW_ORDER": "TELEGRAM_NOTIFY_NEW_ORDER",
}

_TRUE = {"ha", "true", "1", "yes", "on"}


def env_value(key: str) -> str:
    """Kalitning .env dagi zaxira qiymati ("" — yo'q bo'lsa)."""
    name = ENV_FALLBACK.get(key)
    if not name:
        return ""
    raw = getattr(env_settings, name, "")
    if isinstance(raw, bool):
        return "ha" if raw else "yo'q"
    return str(raw or "")


async def get_values(db: AsyncSession, *keys: str) -> dict[str, str]:
    """Berilgan kalitlar: DB qiymati, bo'lmasa .env zaxirasi."""
    if not keys:
        return {}
    rows = (await db.execute(
        select(SystemSetting).where(SystemSetting.key.in_(keys))
    )).scalars().all()
    stored = {r.key: decrypt_secret(r.value) for r in rows if r.value}
    return {k: (stored.get(k) or env_value(k)) for k in keys}


async def get_value(db: AsyncSession, key: str) -> str:
    return (await get_values(db, key))[key]


async def read_values(*keys: str) -> dict[str, str]:
    """Xuddi `get_values`, lekin o'z sessiyasini ochadi.

    Bot kabi FastAPI'dan tashqarida ishlaydigan jarayonlar uchun.
    """
    async with AsyncSessionLocal() as db:
        return await get_values(db, *keys)


def as_bool(value: str, default: bool = False) -> bool:
    value = (value or "").strip().lower()
    if not value:
        return default
    return value in _TRUE


def as_chat_ids(value: str) -> list[int]:
    """"123, 456" -> [123, 456] (noto'g'ri bo'laklar tashlab yuboriladi)."""
    out: list[int] = []
    for part in (value or "").replace(";", ",").split(","):
        part = part.strip()
        if not part:
            continue
        try:
            out.append(int(part))
        except ValueError:
            continue
    return out


def is_local_key(key: str) -> bool:
    item: Optional[object] = CATALOG_BY_KEY.get(key)
    return bool(getattr(item, "local", False))
