"""ERP klienti — lead ingest + suhbat xotirasi (X-Agent-Key).

Uch funksiya:
  push()          — qaynoq lead (POST /leads/ingest), 3 marta urinadi
  log_message()   — HAR bir xabarni jurnalga yozadi (POST /leads/ingest/message)
  fetch_context() — suhbat tarixi + ma'lum faktlar (GET /leads/ingest/context)

Suhbat xotirasi ERP'da saqlanadi: Instagram API'da tarix 30 kundan keyin
yo'qoladi, Redis esa vaqtinchalik kesh. Yagona ishonchli manba — ERP.
"""
from __future__ import annotations

import asyncio

import httpx
from loguru import logger

from app.config import settings
from app.models import LeadPayload


def _url(suffix: str = "") -> str:
    """ERP_INGEST_URL asosida qo'shimcha yo'l (".../leads/ingest" + suffix)."""
    return settings.ERP_INGEST_URL.rstrip("/") + suffix


def _headers() -> dict[str, str]:
    return {"X-Agent-Key": settings.AGENT_INGEST_KEY}


async def push(payload: LeadPayload) -> bool:
    headers = {"X-Agent-Key": settings.AGENT_INGEST_KEY}
    delay = 1.0
    for attempt in range(3):
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.post(
                    settings.ERP_INGEST_URL,
                    json=payload.model_dump(),
                    headers=headers,
                )
            if resp.status_code in (200, 201):
                data = resp.json()
                logger.info(
                    "Lead ERP'ga yozildi: id={} status={} duplicate={}",
                    data.get("id"), data.get("status"), data.get("duplicate"),
                )
                return True
            if resp.status_code == 401:
                logger.error("ERP ingest 401 — AGENT_INGEST_KEY mos emas")
                break  # retry foydasiz
            logger.warning(
                "ERP ingest {} ({}-urinish): {}",
                resp.status_code, attempt + 1, resp.text[:200],
            )
        except httpx.HTTPError as exc:
            logger.warning("ERP ingest ulanish xatosi ({}): {}", attempt + 1, exc)
        await asyncio.sleep(delay)
        delay *= 2

    # Muvaffaqiyatsiz — Telegram'ga ogohlantirish (lead yo'qolmasin)
    from app.telegram.notifier import notify_ingest_failed

    await notify_ingest_failed(payload)
    return False


async def log_message(
    *,
    user_id: str,
    text: str,
    role: str = "user",
    username: str | None = None,
    channel: str = "instagram",
    kind: str = "dm",
    ig_message_id: str | None = None,
    comment_id: str | None = None,
    media_id: str | None = None,
    sent_at: str | None = None,
    source: str = "instagram",
    create_lead: bool = True,
) -> bool:
    """Bitta xabarni ERP suhbat jurnaliga yozadi (xotira uchun).

    Bu "eng yaxshi harakat" (best effort) chaqiruv: xato bo'lsa ham javob
    berish to'xtamaydi, faqat log yoziladi.
    """
    if not text or not user_id:
        return False
    payload = {
        "source": source if source != "instagram" else channel,
        "channel": channel,
        "user_id": user_id,
        "username": username,
        # Eski maydonlar — ERP'ning oldingi versiyasi bilan moslik uchun
        "ig_user_id": user_id if channel == "instagram" else None,
        "ig_username": username if channel == "instagram" else None,
        "role": role,
        "text": text,
        "kind": kind,
        "ig_message_id": ig_message_id,
        "comment_id": comment_id,
        "media_id": media_id,
        "sent_at": sent_at,
        "create_lead": create_lead,
    }
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(_url("/message"), json=payload, headers=_headers())
        if resp.status_code in (200, 201):
            return True
        logger.warning("Xabarni ERP'ga yozib bo'lmadi ({}): {}", resp.status_code, resp.text[:200])
    except httpx.HTTPError as exc:
        logger.warning("Xabarni ERP'ga yozishda ulanish xatosi: {}", exc)
    return False


async def fetch_context(
    user_id: str, limit: int = 40, *, channel: str = "instagram"
) -> dict | None:
    """Suhbat tarixi + ma'lum faktlar (raqam, qiziqish). Xato bo'lsa None."""
    if not user_id:
        return None
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                _url("/context"),
                params={"user_id": user_id, "channel": channel, "limit": limit},
                headers=_headers(),
            )
        if resp.status_code == 200:
            return resp.json()
        logger.warning("Kontekstni olib bo'lmadi ({}): {}", resp.status_code, resp.text[:200])
    except httpx.HTTPError as exc:
        logger.warning("Kontekstni olishda ulanish xatosi: {}", exc)
    return None
