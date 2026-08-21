"""WhatsApp Cloud API klienti (rasmiy Meta API).

Nima qila oladi: mijoz (bizning holatda — kanal admini bo'lgan XODIM) bilan
ochiq suhbatga matn/rasm/video yuborish va oyna yopilganda tasdiqlangan
shablon (template) yuborish.

Nima qila OLMAYDI: WhatsApp **Kanaliga** post tashlash — Meta buni API'ga
ochmagan. Shuning uchun post xodimga yuboriladi, u forward qiladi.

24 soatlik oyna: mijoz oxirgi 24 soatda yozmagan bo'lsa erkin xabar rad
etiladi (xato kodi 131047). Bunda shablon yuboriladi — xodim javob yozishi
bilan oyna ochiladi va navbatdagi post o'zi ketadi.
"""
from __future__ import annotations

import mimetypes
from dataclasses import dataclass
from typing import Any, Optional

import httpx
from loguru import logger

GRAPH_BASE = "https://graph.facebook.com"
DEFAULT_VERSION = "v23.0"
TIMEOUT = 60.0

# Oyna yopilganini bildiruvchi Meta xato kodlari
WINDOW_ERROR_CODES = {131047, 131051, 131026, 470}
WINDOW_HINTS = ("24 hours", "re-engagement", "outside", "message window")

# Cloud API cheklovlari (Meta hujjati)
MAX_IMAGE_BYTES = 5 * 1024 * 1024
MAX_VIDEO_BYTES = 16 * 1024 * 1024
MAX_DOC_BYTES = 100 * 1024 * 1024


@dataclass(frozen=True)
class WhatsAppConfig:
    phone_number_id: str = ""
    access_token: str = ""
    version: str = DEFAULT_VERSION
    template_name: str = ""
    template_lang: str = "uz"

    @property
    def ready(self) -> bool:
        return bool(self.phone_number_id and self.access_token)


@dataclass
class SendResult:
    sent: bool
    error: str = ""
    window_closed: bool = False
    message_id: str = ""


def _parse_error(data: dict[str, Any]) -> tuple[str, bool]:
    err = (data or {}).get("error") or {}
    code = err.get("code")
    message = err.get("error_user_msg") or err.get("message") or str(data)[:200]
    text = str(message).lower()
    closed = code in WINDOW_ERROR_CODES or any(h in text for h in WINDOW_HINTS)
    return str(message), closed


def size_limit_for(kind: str) -> int:
    return {
        "photo": MAX_IMAGE_BYTES,
        "video": MAX_VIDEO_BYTES,
        "document": MAX_DOC_BYTES,
    }.get(kind, MAX_DOC_BYTES)


class WhatsAppClient:
    def __init__(self, config: WhatsAppConfig) -> None:
        self.config = config

    @property
    def _base(self) -> str:
        return f"{GRAPH_BASE}/{self.config.version}/{self.config.phone_number_id}"

    @property
    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.config.access_token}"}

    async def upload_media(
        self, data: bytes, *, mime: str, filename: str
    ) -> tuple[str, str]:
        """Faylni Meta serveriga yuklaydi. Qaytaradi: (media_id, xato)."""
        files = {
            "file": (filename, data, mime or "application/octet-stream"),
            "messaging_product": (None, "whatsapp"),
            "type": (None, mime or "application/octet-stream"),
        }
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT) as client:
                resp = await client.post(
                    f"{self._base}/media", headers=self._headers, files=files
                )
            body = resp.json() if resp.content else {}
        except httpx.HTTPError as exc:
            return "", f"Ulanish xatosi: {exc}"
        if resp.status_code == 200 and body.get("id"):
            return str(body["id"]), ""
        message, _ = _parse_error(body)
        logger.warning("WhatsApp media yuklanmadi ({}): {}", resp.status_code, message)
        return "", message

    async def _send(self, payload: dict[str, Any]) -> SendResult:
        payload = {"messaging_product": "whatsapp", **payload}
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT) as client:
                resp = await client.post(
                    f"{self._base}/messages", headers=self._headers, json=payload
                )
            body = resp.json() if resp.content else {}
        except httpx.HTTPError as exc:
            return SendResult(sent=False, error=f"Ulanish xatosi: {exc}")

        if resp.status_code == 200:
            msgs = body.get("messages") or [{}]
            return SendResult(sent=True, message_id=str(msgs[0].get("id") or ""))

        message, closed = _parse_error(body)
        return SendResult(sent=False, error=message, window_closed=closed)

    async def send_text(self, to: str, text: str) -> SendResult:
        return await self._send({
            "to": to, "type": "text",
            "text": {"body": text[:4096], "preview_url": True},
        })

    async def send_media(
        self, to: str, *, kind: str, media_id: str, caption: str = "",
    ) -> SendResult:
        """kind: photo | video | document."""
        wa_type = {"photo": "image", "video": "video"}.get(kind, "document")
        body: dict[str, Any] = {"id": media_id}
        if caption:
            body["caption"] = caption[:1024]
        if wa_type == "document":
            body["filename"] = "post"
        return await self._send({"to": to, "type": wa_type, wa_type: body})

    async def send_template(self, to: str) -> SendResult:
        """Oyna yopilganda — tasdiqlangan shablon (xodim javob yozsin uchun)."""
        if not self.config.template_name:
            return SendResult(sent=False, error="Shablon nomi sozlanmagan")
        return await self._send({
            "to": to, "type": "template",
            "template": {
                "name": self.config.template_name,
                "language": {"code": self.config.template_lang or "uz"},
            },
        })


def guess_filename(kind: str, mime: str) -> str:
    ext = mimetypes.guess_extension(mime or "") or {
        "photo": ".jpg", "video": ".mp4"
    }.get(kind, ".bin")
    return f"nur-post{ext}"
