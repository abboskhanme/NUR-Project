"""Telegram bildirishnoma — qaynoq lead alerti + kunlik jamlanma + xato ogohlantirish.

Bu agentning ALOHIDA boti (ERP botidan boshqa token). Faqat bildirishnoma —
suhbat yuritmaydi. Kunlik statistika xotirada yig'iladi va DAILY_REPORT_TIME da
yuboriladi (main.py dagi APScheduler chaqiradi).
"""
from __future__ import annotations

import httpx
from loguru import logger

from app.config import settings
from app.models import AgentOutput, LeadPayload

# Kunlik hisoblagichlar (xotirada)
_stats = {"total": 0, "hot": 0, "escalated": 0, "ingest_failed": 0}


def bump(key: str) -> None:
    _stats[key] = _stats.get(key, 0) + 1


async def _send(text: str) -> None:
    if not settings.TELEGRAM_BOT_TOKEN or not settings.TELEGRAM_CHAT_ID:
        logger.debug("Telegram sozlanmagan — xabar yuborilmadi")
        return
    url = f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/sendMessage"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                url,
                json={
                    "chat_id": settings.TELEGRAM_CHAT_ID,
                    "text": text,
                    "parse_mode": "HTML",
                    "disable_web_page_preview": True,
                },
            )
        if resp.status_code != 200:
            logger.warning("Telegram {}: {}", resp.status_code, resp.text[:200])
    except httpx.HTTPError as exc:
        logger.warning("Telegram ulanish xatosi: {}", exc)


async def notify_hot_lead(username: str | None, out: AgentOutput) -> None:
    who = f"@{username}" if username else "Instagram foydalanuvchi"
    lines = [
        "🔥 <b>Qaynoq lead!</b>",
        f"Kimdan: {who}",
        f"Ball: {out.lead_score}/100 · niyat: {out.intent}",
    ]
    if out.lead.product_interest:
        lines.append(f"Mahsulot: {out.lead.product_interest}")
    if out.lead.contact:
        lines.append(f"Kontakt: {out.lead.contact}")
    if out.lead.summary:
        lines.append(f"Izoh: {out.lead.summary}")
    if out.escalate_to_human:
        lines.append("⚠️ Operator aralashuvi kerak")
    await _send("\n".join(lines))


async def notify_ingest_failed(payload: LeadPayload) -> None:
    bump("ingest_failed")
    who = f"@{payload.ig_username}" if payload.ig_username else payload.ig_user_id
    await _send(
        "❌ <b>ERP'ga lead yozib bo'lmadi</b> (qo'lda kiriting)\n"
        f"Kimdan: {who}\n"
        f"Xabar: {payload.message_text or '-'}\n"
        f"Kontakt: {payload.contact or '-'}"
    )


async def notify_token_problem(detail: str) -> None:
    """Instagram tokenini yangilab bo'lmadi — akkauntni qayta ulash kerak."""
    await _send(
        "⚠️ <b>Instagram tokenini yangilab bo'lmadi</b>\n"
        "Akkauntni qayta ulang: ERP → Tizim sozlamalari → Instagram → «Ulash».\n"
        f"Tafsilot: <code>{detail}</code>"
    )


async def send_daily_report() -> None:
    text = (
        "📊 <b>Instagram agent — kunlik hisobot</b>\n"
        f"Jami suhbat: {_stats['total']}\n"
        f"🔥 Qaynoq lead: {_stats['hot']}\n"
        f"⚠️ Operatorga: {_stats['escalated']}\n"
        f"❌ ERP xatosi: {_stats['ingest_failed']}"
    )
    await _send(text)
    for k in _stats:
        _stats[k] = 0
