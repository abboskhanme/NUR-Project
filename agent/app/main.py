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
from fastapi import BackgroundTasks, FastAPI, Header, HTTPException
from loguru import logger
from pydantic import BaseModel

from app.agent import knowledge
from app.config import settings
from app.instagram.client import instagram
from app.instagram.importer import import_and_notify
from app.instagram.models import IncomingEvent
from app.instagram.oauth import refresh_token_if_due
from app.instagram.oauth import router as oauth_router
from app.instagram.webhook import router as webhook_router
from app.processing.pipeline import process_event
from app.remote_config import fetch_and_apply
from app.state.store import store
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


# --- Eski suhbatlarni ERP'ga import qilish ---------------------------------
@app.post("/admin/import-conversations")
async def import_conversations_endpoint(
    background: BackgroundTasks,
    x_agent_key: Optional[str] = Header(default=None),
):
    """Instagram'dagi mavjud suhbatlarni (Requests papkasidagilarni ham) ERP'ga
    ko'chiradi. Uzoq davom etishi mumkin — fon rejimida ishlaydi, natija
    Telegram'ga yuboriladi.

    Chaqirish:
      curl -X POST https://<domen>/agent/admin/import-conversations \
           -H "X-Agent-Key: <AGENT_INGEST_KEY>"
    """
    _check_key(x_agent_key)
    background.add_task(import_and_notify)
    return {"started": True, "note": "Natija Telegram'ga yuboriladi"}


# --- ERP "Yozishmalar" bo'limi uchun ------------------------------------- #
def _check_key(key: Optional[str]) -> None:
    if not settings.AGENT_INGEST_KEY or key != settings.AGENT_INGEST_KEY:
        raise HTTPException(status_code=401, detail="Agent kaliti noto'g'ri")


class SendDmIn(BaseModel):
    ig_user_id: str
    text: str
    # 24 soatlik oyna yopilgan, lekin 7 kun ichida — jonli operator sifatida
    human_agent: bool = False


@app.post("/admin/send-dm")
async def send_dm_endpoint(
    payload: SendDmIn, x_agent_key: Optional[str] = Header(default=None)
):
    """ERP'dagi operator yozgan xabarni Instagram'ga yuboradi.

    Yuborilgach o'sha suhbatda AI jim turadi (operator o'zi javob beryapti)
    va xabar echo bo'lib qaytganda jurnalga ikkinchi marta yozilmaydi.
    """
    _check_key(x_agent_key)
    text = (payload.text or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="Xabar matni bo'sh")
    if not settings.IG_ACCESS_TOKEN:
        raise HTTPException(status_code=503, detail="Instagram ulanmagan")

    result = await instagram.send_dm_result(
        payload.ig_user_id, text, human_agent=payload.human_agent
    )
    if result.get("sent"):
        try:
            await store.mark_sent(payload.ig_user_id, text)
            await store.pause(payload.ig_user_id, settings.BOT_PAUSE_HOURS)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Pauza/izni belgilashda xato: {}", exc)
    return result


class BotPauseIn(BaseModel):
    ig_user_id: str
    enabled: bool = True     # True — AI javob bersin, False — jim tursin


@app.post("/admin/bot-pause")
async def bot_pause_endpoint(
    payload: BotPauseIn, x_agent_key: Optional[str] = Header(default=None)
):
    """Bitta suhbatda AI javobini yoqish/o'chirish (ERP tugmasi)."""
    _check_key(x_agent_key)
    if payload.enabled:
        await store.unpause(payload.ig_user_id)
    else:
        await store.pause(payload.ig_user_id, settings.BOT_PAUSE_HOURS)
    return {"enabled": payload.enabled, "paused": await store.is_paused(payload.ig_user_id)}


@app.get("/admin/bot-state")
async def bot_state_endpoint(
    ig_user_id: str, x_agent_key: Optional[str] = Header(default=None)
):
    """AI shu suhbatda javob beryaptimi (pauzada emasmi)."""
    _check_key(x_agent_key)
    return {"paused": await store.is_paused(ig_user_id)}
