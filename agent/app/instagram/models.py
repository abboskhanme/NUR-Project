"""Instagram webhook payloadini normalizatsiya qilish.

Meta payloadi murakkab va o'zgaruvchan — uni bitta sodda `IncomingEvent` ga
aylantiramiz, pipeline faqat shu bilan ishlaydi.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass
class IncomingEvent:
    kind: str  # "comment" | "dm" | "echo"
    text: str
    sender_id: str  # Instagram user id (izoh/DM egasi; echo'da — mijoz)
    username: str | None = None
    comment_id: str | None = None
    media_id: str | None = None
    media_caption: str | None = None

    @property
    def dedup_key(self) -> str:
        if self.comment_id:
            return f"comment:{self.comment_id}"
        return f"{self.kind}:{self.sender_id}:{hash(self.text)}"


def parse_webhook(payload: dict[str, Any], self_ig_id: str) -> list[IncomingEvent]:
    """Meta 'instagram' webhook payloadidan hodisalarni ajratadi.

    self_ig_id — bizning IG User ID; o'z izoh/xabarlarimizni o'tkazib yuboramiz.
    """
    events: list[IncomingEvent] = []
    for entry in payload.get("entry", []):
        # --- Izohlar (changes[].field == "comments") ---
        for change in entry.get("changes", []):
            if change.get("field") != "comments":
                continue
            value = change.get("value", {}) or {}
            frm = value.get("from", {}) or {}
            if str(frm.get("id")) == str(self_ig_id):
                continue  # o'z izohimiz
            text = (value.get("text") or "").strip()
            if not text:
                continue
            media = value.get("media", {}) or {}
            events.append(
                IncomingEvent(
                    kind="comment",
                    text=text,
                    sender_id=str(frm.get("id", "")),
                    username=frm.get("username"),
                    comment_id=str(value.get("id")) if value.get("id") else None,
                    media_id=str(media.get("id")) if media.get("id") else None,
                    media_caption=media.get("caption"),
                )
            )

        # --- DM'lar (messaging[]) ---
        for msg in entry.get("messaging", []):
            sender = str((msg.get("sender", {}) or {}).get("id") or "")
            recipient = str((msg.get("recipient", {}) or {}).get("id") or "")
            message = msg.get("message", {}) or {}
            text = (message.get("text") or "").strip()
            if not text:
                continue

            # Echo — akkauntimizdan CHIQQAN xabar. Ikki manba bo'lishi mumkin:
            # botning o'zi yoki operator (telefondagi Instagram ilovasi).
            # Ikkinchisi bo'lsa botni o'sha suhbatda pauza qilamiz (pipeline hal qiladi).
            if message.get("is_echo") or (self_ig_id and sender == str(self_ig_id)):
                events.append(
                    IncomingEvent(kind="echo", text=text, sender_id=recipient)
                )
                continue

            events.append(IncomingEvent(kind="dm", text=text, sender_id=sender))
    return events
