"""Telegram bot webhook + admin commands."""
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import settings_store
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
    if not await settings_store.get_value(db, "ERP_BOT_TOKEN"):
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
async def status(db: Annotated[AsyncSession, Depends(get_db)]):
    values = await settings_store.get_values(db, "ERP_BOT_TOKEN", "ERP_BOT_USERNAME")
    return {
        "bot_token_set": bool(values["ERP_BOT_TOKEN"]),
        "bot_username": values["ERP_BOT_USERNAME"] or None,
        "webhook_url": settings.TELEGRAM_WEBHOOK_URL or None,
    }
