"""Telegram webhook — shaxsiy chatlar (Business ulanishi yoki bot chati).

Telegram 60 soniya kutadi, lekin biz Instagram bilan bir xil qoidaga amal
qilamiz: og'ir ish (AI + javob + ERP) fon vazifasiga topshiriladi va 200
DARHOL qaytariladi.

Business ulanishi qanday ishlaydi:
  1. Foydalanuvchi Telegram → Sozlamalar → Business → Chatbots'da botni ulaydi.
  2. Telegram `business_connection` update yuboradi — unda ulanish `id` va
     akkaunt egasining `user.id` bo'ladi. Shuni saqlab qo'yamiz:
       - `tgconn:<connection_id>` → egasining user id
       - `tgchat:<chat_id>`       → connection id (javob yuborishda kerak)
  3. Mijoz yozganda `business_message` keladi va javob AYNAN shu
     `business_connection_id` bilan yuboriladi — mijoz javobni akkaunt
     egasidan (sizdan) kelgan deb ko'radi.
"""
from __future__ import annotations

import hmac
import json
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Header, Request, Response
from loguru import logger

from app.config import settings
from app.processing.pipeline import process_event
from app.state.store import store
from app.telegram_business.models import parse_update

router = APIRouter(prefix="/webhook", tags=["Telegram webhook"])

CONN_KEY = "tgconn:{}"      # ulanish -> egasi
CHAT_KEY = "tgchat:{}"      # chat -> ulanish


async def remember_connection(conn: dict) -> None:
    """`business_connection` update'ini saqlaymiz (egasi va holati)."""
    conn_id = str(conn.get("id") or "")
    user = conn.get("user") or {}
    owner_id = str(user.get("id") or "")
    if not conn_id or not owner_id:
        return
    enabled = conn.get("is_enabled", True)
    await store.set_value(CONN_KEY.format(conn_id), owner_id if enabled else "")
    logger.info(
        "Telegram Business ulanishi {}: conn={} egasi={}",
        "yoqildi" if enabled else "o'chirildi", conn_id, owner_id,
    )


async def owner_of(conn_id: Optional[str]) -> Optional[int]:
    if not conn_id:
        return None
    raw = await store.get_value(CONN_KEY.format(conn_id))
    return int(raw) if raw and raw.isdigit() else None


async def connection_for_chat(chat_id: str) -> Optional[str]:
    """Shu chatga javob yozishda ishlatiladigan Business ulanishi."""
    return await store.get_value(CHAT_KEY.format(chat_id))


def _valid_secret(secret: Optional[str]) -> bool:
    expected = settings.TG_WEBHOOK_SECRET
    if not expected:
        logger.warning("TG_WEBHOOK_SECRET yo'q — tekshiruv o'tkazib yuborildi")
        return True
    return bool(secret and hmac.compare_digest(secret, expected))


@router.post("/telegram")
async def receive(
    request: Request,
    background: BackgroundTasks,
    x_telegram_bot_api_secret_token: Optional[str] = Header(default=None),
):
    if not _valid_secret(x_telegram_bot_api_secret_token):
        logger.warning("Telegram webhook maxfiy sarlavhasi noto'g'ri")
        return Response(content="forbidden", status_code=403)

    try:
        update = json.loads(await request.body())
    except json.JSONDecodeError:
        return Response(content="bad json", status_code=400)

    if not settings.TG_SALES_ENABLED:
        return Response(content="disabled", media_type="text/plain")

    # 1) Ulanish o'zgarishi (ulandi/uzildi)
    conn = update.get("business_connection")
    if isinstance(conn, dict):
        await remember_connection(conn)

    # 2) Xabarlar
    msg = update.get("business_message") or {}
    conn_id = msg.get("business_connection_id") if isinstance(msg, dict) else None
    owner_id = await owner_of(conn_id)

    for event in parse_update(update, owner_id=owner_id):
        if event.business_connection_id and event.chat_id:
            # Javob yozishda kerak bo'ladi
            await store.set_value(
                CHAT_KEY.format(event.chat_id), event.business_connection_id
            )
        background.add_task(process_event, event)

    return Response(content="OK", media_type="text/plain")
