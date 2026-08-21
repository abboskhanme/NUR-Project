"""Telegram Bot API klienti — shaxsiy chatlarga AI javob berish uchun.

Instagram klientidan farqi: bu yerda javob oynasi cheklovi YO'Q, ya'ni
istalgan vaqtda yozish mumkin. Business ulanishida xabar
`business_connection_id` bilan yuboriladi — shunda mijoz javobni "bot"dan
emas, AKKAUNT EGASIDAN (sizdan) kelgan deb ko'radi.
"""
from __future__ import annotations

import asyncio

import httpx
from loguru import logger

from app.config import settings

_TIMEOUT = 20.0


class TelegramClient:
    @property
    def _base(self) -> str:
        # Qiymatlar har chaqiruvda o'qiladi — ERP sozlamani o'zgartirsa
        # agent restartsiz yangi tokenga o'tadi.
        base = settings.TG_API_BASE.rstrip("/")
        return f"{base}/bot{settings.TG_SALES_BOT_TOKEN}"

    @property
    def enabled(self) -> bool:
        return bool(settings.TG_SALES_ENABLED and settings.TG_SALES_BOT_TOKEN)

    async def _call(self, method: str, payload: dict) -> tuple[bool, dict]:
        """Bitta so'rov: (muvaffaqiyat, javob/xato)."""
        if not settings.TG_SALES_BOT_TOKEN:
            return False, {"description": "TG_SALES_BOT_TOKEN sozlanmagan"}
        url = f"{self._base}/{method}"
        delay = 1.0
        for attempt in range(3):
            try:
                async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
                    resp = await client.post(url, json=payload)
                data = resp.json() if resp.content else {}
                if resp.status_code == 200 and data.get("ok"):
                    return True, data.get("result") or {}
                # 429 / 5xx — kutib qayta urinamiz
                if resp.status_code in (429, 500, 502, 503):
                    wait = float(
                        (data.get("parameters") or {}).get("retry_after") or delay
                    )
                    logger.warning("TG {} {} ({}-urinish), {}s kutamiz: {}",
                                   method, resp.status_code, attempt + 1, wait,
                                   str(data)[:200])
                    await asyncio.sleep(wait)
                    delay *= 2
                    continue
                return False, data
            except httpx.HTTPError as exc:
                logger.warning("TG {} ulanish xatosi ({}): {}", method, attempt + 1, exc)
                await asyncio.sleep(delay)
                delay *= 2
        return False, {"description": "Telegram javob bermadi (3 urinish)"}

    async def send_message(
        self, chat_id: str | int, text: str, *, business_connection_id: str | None = None
    ) -> dict:
        """Xabar yuboradi. Natija: {"sent": bool, "error": str|None}."""
        payload: dict = {"chat_id": chat_id, "text": text}
        if business_connection_id:
            payload["business_connection_id"] = business_connection_id
        ok, data = await self._call("sendMessage", payload)
        if ok:
            return {"sent": True, "message_id": str(data.get("message_id") or "")}
        error = data.get("description") or "Yuborilmadi"
        logger.warning("Telegram xabar yuborilmadi: {}", error)
        return {"sent": False, "error": error}

    async def get_me(self) -> dict:
        ok, data = await self._call("getMe", {})
        return data if ok else {}

    async def set_webhook(self, url: str, secret: str) -> bool:
        """Webhook o'rnatadi (Business va oddiy chat xabarlari uchun)."""
        ok, data = await self._call("setWebhook", {
            "url": url,
            "secret_token": secret,
            "allowed_updates": [
                "message", "edited_message",
                "business_connection", "business_message", "edited_business_message",
            ],
            "drop_pending_updates": False,
        })
        if ok:
            logger.info("Telegram webhook o'rnatildi: {}", url)
            return True
        logger.error("Telegram webhook o'rnatilmadi: {}", data.get("description"))
        return False


telegram = TelegramClient()
