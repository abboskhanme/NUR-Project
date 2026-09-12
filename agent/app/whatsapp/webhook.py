"""WhatsApp webhook — GET verify + POST (HMAC-SHA256 imzo tekshiruvi).

Meta 5 soniya ichida 200 kutadi, shuning uchun og'ir ish (AI + javob + ERP)
BackgroundTasks'ga topshiriladi va 200 DARHOL qaytariladi.

Meta sozlamasi: App → WhatsApp → Configuration
    Callback URL:  https://<domen>/agent/webhook/whatsapp
    Verify token:  «Tizim sozlamalari → WhatsApp AI yordamchisi» dagi qiymat
    Webhook fields: `messages` (kerak bo'lsa `message_echoes` ham)
"""
from __future__ import annotations

import hashlib
import hmac
import json
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Header, Request, Response
from loguru import logger

from app.config import settings
from app.processing.pipeline import process_event
from app.whatsapp.models import parse_webhook

router = APIRouter(prefix="/webhook", tags=["WhatsApp webhook"])


def _app_secret() -> str:
    """Imzo kaliti — o'ziniki bo'lmasa Instagram ilovasiniki (odatda bitta ilova)."""
    return settings.WA_APP_SECRET or settings.IG_APP_SECRET


def _verify_token() -> str:
    return settings.WA_VERIFY_TOKEN or settings.IG_VERIFY_TOKEN


@router.get("/whatsapp")
async def verify(request: Request):
    """Meta webhook tasdiqlash: hub.challenge ni qaytaramiz."""
    params = request.query_params
    expected = _verify_token()
    if params.get("hub.mode") == "subscribe" and expected and \
            params.get("hub.verify_token") == expected:
        logger.info("WhatsApp webhook tasdiqlandi")
        return Response(content=params.get("hub.challenge") or "",
                        media_type="text/plain")
    logger.warning("WhatsApp webhook tasdiqlash rad etildi (token mos emas)")
    return Response(content="forbidden", status_code=403)


def _valid_signature(raw: bytes, signature: Optional[str]) -> bool:
    secret = _app_secret()
    if not secret:
        # App secret sozlanmagan bo'lsa (lokal test), o'tkazamiz.
        logger.warning("WA_APP_SECRET yo'q — imzo tekshiruvi o'tkazib yuborildi")
        return True
    if not signature or not signature.startswith("sha256="):
        return False
    expected = hmac.new(secret.encode(), raw, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature.split("=", 1)[1], expected)


@router.post("/whatsapp")
async def receive(
    request: Request,
    background: BackgroundTasks,
    x_hub_signature_256: Optional[str] = Header(default=None),
):
    raw = await request.body()
    if not _valid_signature(raw, x_hub_signature_256):
        logger.warning("WhatsApp webhook imzosi noto'g'ri")
        return Response(content="invalid signature", status_code=403)

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return Response(content="bad json", status_code=400)

    # AI o'chirilgan bo'lsa ham xabar ERP jurnaliga yoziladi — xodim Leadlar
    # bo'limida ko'radi va o'zi javob beradi. Faqat AI javobi bermaydi.
    reply = bool(settings.WA_AI_ENABLED)

    for event in parse_webhook(payload):
        background.add_task(process_event, event, reply=reply)

    return Response(content="EVENT_RECEIVED", media_type="text/plain")
