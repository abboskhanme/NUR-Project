"""ERP lead ingest klienti — POST /api/v1/leads/ingest (X-Agent-Key, retry).

ERP tushib qolsa lead yo'qolmasin: 3 marta urinamiz, so'ng Telegram'ga
"ingest failed" ogohlantirishi yuboramiz.
"""
from __future__ import annotations

import asyncio

import httpx
from loguru import logger

from app.config import settings
from app.models import LeadPayload


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
