"""WhatsApp Cloud API webhook payloadini `IncomingEvent` ga aylantirish.

Instagram va Telegram bilan BITTA `IncomingEvent` ishlatiladi — shunda pipeline
(dedup, xotira, AI, lead, operator pauzasi) uchala kanal uchun bir xil bo'ladi.

Meta payloadi:
    entry[].changes[].value.messages[]        — mijoz yozgan xabar
    entry[].changes[].value.contacts[]        — mijoz profili (ismi, wa_id)
    entry[].changes[].value.statuses[]        — yetkazildi/o'qildi (e'tibor bermaymiz)
    entry[].changes[].value.message_echoes[]  — biz (yoki operator) yuborgan xabar
"""
from __future__ import annotations

from typing import Any, Optional

from app.instagram.models import IncomingEvent

# Matnsiz xabarlar — mazmunini o'qiy olmaymiz, lekin tarixda ko'rinishi kerak
_ATTACHMENT_LABELS: dict[str, str] = {
    "image": "rasm",
    "video": "video",
    "audio": "ovozli xabar",
    "voice": "ovozli xabar",
    "document": "fayl",
    "sticker": "stiker",
    "location": "lokatsiya",
    "contacts": "kontakt",
    "order": "buyurtma",
}


def message_text(msg: dict[str, Any]) -> tuple[str, bool]:
    """Xabar matni va matnsiz (media) ekanligi.

    Matn/caption bo'lsa — o'sha; aks holda "[Mijoz rasm yubordi]" kabi
    o'rinbosar (Instagram/Telegramdagi bilan bir xil uslub).
    """
    kind = str(msg.get("type") or "").lower()

    if kind == "text":
        return str((msg.get("text") or {}).get("body") or "").strip(), False
    # Tugma / ro'yxat javoblari — mijoz aslida matn tanlagan
    if kind == "button":
        return str((msg.get("button") or {}).get("text") or "").strip(), False
    if kind == "interactive":
        inter = msg.get("interactive") or {}
        reply = inter.get("button_reply") or inter.get("list_reply") or {}
        return str(reply.get("title") or "").strip(), False
    if kind == "reaction":
        emoji = str((msg.get("reaction") or {}).get("emoji") or "").strip()
        return (f"[Mijoz {emoji} reaksiya qo'ydi]" if emoji else ""), True

    # Media — caption bo'lsa o'sha matn ishlatiladi
    caption = str((msg.get(kind) or {}).get("caption") or "").strip()
    if caption:
        return caption, True

    label = _ATTACHMENT_LABELS.get(kind)
    return (f"[Mijoz {label} yubordi]" if label else ""), True


def _profile_name(contacts: list[dict], wa_id: str) -> Optional[str]:
    """Mijozning WhatsApp profil nomi (bo'lsa)."""
    for c in contacts:
        if str(c.get("wa_id") or "") == wa_id:
            name = str((c.get("profile") or {}).get("name") or "").strip()
            return name or None
    return None


def _event(msg: dict[str, Any], contacts: list[dict], *, echo: bool) -> Optional[IncomingEvent]:
    # echo — biz yuborgan xabar: suhbatdosh `to`, mijoz xabarida esa `from`
    peer = str((msg.get("to") if echo else msg.get("from")) or "").strip()
    if not peer:
        return None

    text, has_attachment = message_text(msg)
    if not text:
        return None

    return IncomingEvent(
        kind="echo" if echo else "dm",
        text=text,
        sender_id=peer,
        channel="whatsapp",
        chat_id=peer,
        username=None if echo else _profile_name(contacts, peer),
        message_id=str(msg.get("id") or "") or None,
        has_attachment=has_attachment,
    )


def parse_webhook(payload: dict[str, Any]) -> list[IncomingEvent]:
    """Webhook payloadidan barcha hodisalarni ajratib oladi."""
    events: list[IncomingEvent] = []
    for entry in payload.get("entry") or []:
        for change in (entry or {}).get("changes") or []:
            value = (change or {}).get("value") or {}
            contacts = value.get("contacts") or []
            for msg in value.get("messages") or []:
                ev = _event(msg, contacts, echo=False)
                if ev:
                    events.append(ev)
            for msg in value.get("message_echoes") or []:
                ev = _event(msg, contacts, echo=True)
                if ev:
                    events.append(ev)
    return events
