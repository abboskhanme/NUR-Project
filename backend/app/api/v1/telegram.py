"""Telegram bot webhook + admin commands."""
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_db
from app.models.system import TelegramOrder

router = APIRouter()


@router.post("/webhook")
async def webhook(request: Request, db: Annotated[AsyncSession, Depends(get_db)]):
    """Receive Telegram updates.

    Bot conversation flow is implemented in app/integrations/telegram.py.
    Here we save raw update and dispatch to handler.
    """
    if not settings.TELEGRAM_BOT_TOKEN:
        raise HTTPException(503, "Telegram bot sozlanmagan")
    payload: dict[str, Any] = await request.json()

    chat_id = ""
    msg = payload.get("message") or payload.get("callback_query", {}).get("message") or {}
    if "chat" in msg:
        chat_id = str(msg["chat"]["id"])

    rec = TelegramOrder(
        telegram_chat_id=chat_id,
        telegram_message_id=str(msg.get("message_id", "")),
        raw_data=payload,
    )
    db.add(rec)
    await db.commit()

    # In a full implementation, dispatch to integrations.telegram handler
    return {"ok": True}


@router.get("/status")
async def status():
    return {
        "bot_token_set": bool(settings.TELEGRAM_BOT_TOKEN),
        "webhook_url": settings.TELEGRAM_WEBHOOK_URL or None,
    }
