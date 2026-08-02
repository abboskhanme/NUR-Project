"""ERP'dan agent konfiguratsiyasini olish va ishlab turgan holda qo'llash.

Startup'da va davriy (interval) `GET /system-settings/agent-config` (X-Agent-Key)
chaqiriladi. Kelgan qiymatlar `settings` ga yoziladi va AI provayder keshi
tozalanadi — shunda foydalanuvchi ERP UI'da (Tizim sozlamalari) biror kalit/token/
modelni o'zgartirsa, agent RESTARTSIZ avtomatik yangilanadi.

Eslatma: DAILY_REPORT_TIME o'zgarishi keyingi qayta ishga tushirishда qo'llanadi
(scheduler startup'da bir marta rejalashtiriladi).
"""
from __future__ import annotations

import httpx
from loguru import logger

from app.ai.factory import get_provider
from app.config import settings

# ERP satr sifatida qaytaradi — bularni int ga o'giramiz
_INT_KEYS = {"AI_MAX_TOKENS", "DEDUP_TTL", "BOT_PAUSE_HOURS"}


def _config_url() -> str:
    # ".../api/v1/leads/ingest" -> ".../api/v1/system-settings/agent-config"
    base = settings.ERP_INGEST_URL.rsplit("/leads/ingest", 1)[0]
    return f"{base}/system-settings/agent-config"


def _apply(data: dict) -> None:
    changed: list[str] = []
    for key, raw in data.items():
        if not hasattr(settings, key) or raw is None or raw == "":
            continue  # bo'sh qiymat .env fallbackни bekor qilmasin
        value: object = raw
        if key in _INT_KEYS:
            try:
                value = int(raw)
            except (TypeError, ValueError):
                continue
        if value != getattr(settings, key):
            setattr(settings, key, value)
            changed.append(key)
    if changed:
        logger.info("Agent konfiguratsiyasi yangilandi: {}", ", ".join(changed))
        # AI provayder keshini tozalaymiz — kalit/model/provayder o'zgargan bo'lishi mumkin
        try:
            get_provider.cache_clear()
        except Exception:  # noqa: BLE001
            pass


async def push_config(values: dict[str, str]) -> bool:
    """Agent o'zi olgan qiymatlarni (IG token va h.k.) ERP'ga qaytarib yozadi.

    Faqat OAuth ulash va token yangilashda ishlatiladi — shunda konteyner qayta
    ishga tushsa ham token yo'qolmaydi va super-admin uni UI'da ko'radi.
    """
    if not settings.AGENT_INGEST_KEY:
        logger.warning("AGENT_INGEST_KEY yo'q — ERP'ga config yozilmadi")
        return False
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.put(
                _config_url(),
                headers={"X-Agent-Key": settings.AGENT_INGEST_KEY},
                json={"values": values},
            )
        if resp.status_code == 200:
            logger.info("ERP'ga saqlandi: {}", ", ".join(sorted(values)))
            return True
        logger.error("ERP config yozish {} : {}", resp.status_code, resp.text[:150])
    except httpx.HTTPError as exc:
        logger.error("ERP config yozishda xato: {}", exc)
    return False


async def fetch_and_apply() -> bool:
    if not settings.AGENT_INGEST_KEY:
        logger.warning("AGENT_INGEST_KEY yo'q — ERP'dan config olinmadi (.env ishlatiladi)")
        return False
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                _config_url(), headers={"X-Agent-Key": settings.AGENT_INGEST_KEY}
            )
        if resp.status_code == 200:
            _apply(resp.json())
            return True
        logger.warning("ERP config {} : {}", resp.status_code, resp.text[:150])
    except httpx.HTTPError as exc:
        logger.warning("ERP config olishда xato (.env bilan davom etamiz): {}", exc)
    return False
