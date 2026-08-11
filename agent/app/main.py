"""NUR Agent — FastAPI ilova (webhook + health + scheduler).

Ishga tushirish (lokal):  uvicorn app.main:app --reload --port 8020
"""
from __future__ import annotations

import sys
from contextlib import asynccontextmanager
from typing import Optional

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from fastapi import FastAPI
from loguru import logger
from pydantic import BaseModel

from app.agent import knowledge
from app.config import settings
from app.instagram.models import IncomingEvent
from app.instagram.oauth import refresh_token_if_due
from app.instagram.oauth import router as oauth_router
from app.instagram.webhook import router as webhook_router
from app.processing.pipeline import process_event
from app.remote_config import fetch_and_apply
from app.telegram.notifier import send_daily_report

# Logging
logger.remove()
logger.add(sys.stderr, level=settings.LOG_LEVEL)

_scheduler: AsyncIOScheduler | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _scheduler
    knowledge.get_knowledge()  # bilim bazasini oldindan yuklaymiz
    # ERP'dan sozlamalarni tortib olamiz (Tizim sozlamalari) — .env ustidan
    # qo'llanadi. Akkaunt ID/username ham shu ichida aniqlanadi: ERP hali
    # ko'tarilmagan bo'lsa keyingi sinxronlashda (5 daqiqada) qayta urinadi.
    await fetch_and_apply()
    logger.info("NUR Agent ishga tushdi (provider={})", settings.AI_PROVIDER)

    _scheduler = AsyncIOScheduler(timezone=settings.TIMEZONE)
    try:
        hour, minute = (int(x) for x in settings.DAILY_REPORT_TIME.split(":"))
        _scheduler.add_job(
            send_daily_report,
            CronTrigger(hour=hour, minute=minute),
            id="daily_report",
        )
        # Har 5 daqiqada ERP'dan config'ni yangilab olamiz (avtomatik yangilanish)
        _scheduler.add_job(
            fetch_and_apply,
            IntervalTrigger(minutes=5),
            id="remote_config",
        )
        # Instagram tokeni 60 kunlik — kuniga bir marta tekshirib, muddati
        # yaqinlashsa avtomatik yangilaymiz (qo'lda aralashish shart emas).
        _scheduler.add_job(
            refresh_token_if_due,
            IntervalTrigger(hours=24),
            id="ig_token_refresh",
        )
        _scheduler.start()
        logger.info("Kunlik hisobot rejalashtirildi: {}", settings.DAILY_REPORT_TIME)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Scheduler ishga tushmadi (DAILY_REPORT_TIME formatini tekshiring): {}", exc)

    yield

    if _scheduler:
        _scheduler.shutdown(wait=False)


app = FastAPI(title="NUR Agent", version="1.0.0", lifespan=lifespan)
app.include_router(webhook_router)
app.include_router(oauth_router)


@app.get("/health")
async def health():
    """Holat — Instagram ulanganmi, bilim bazasi bormi."""
    return {
        "status": "ok",
        "provider": settings.AI_PROVIDER,
        "instagram_connected": bool(settings.IG_ACCESS_TOKEN and settings.IG_USER_ID),
        "knowledge_chars": len(knowledge.get_knowledge()),
    }


@app.post("/reload-knowledge")
async def reload_knowledge():
    text = knowledge.reload()
    return {"reloaded": True, "chars": len(text)}


# --- Lokal test uchun (soxta webhook'siz) ---------------------------------
class SimulateIn(BaseModel):
    text: str
    kind: str = "comment"  # comment | dm
    username: Optional[str] = "test_user"
    sender_id: str = "test_sender_1"
    comment_id: Optional[str] = "test_comment_1"


@app.post("/simulate")
async def simulate(payload: SimulateIn):
    """AI + oqimni soxta hodisa bilan tekshirish (App Review kutilmasdan)."""
    event = IncomingEvent(
        kind=payload.kind,
        text=payload.text,
        sender_id=payload.sender_id,
        username=payload.username,
        comment_id=payload.comment_id if payload.kind == "comment" else None,
    )
    await process_event(event)
    return {"processed": True}
