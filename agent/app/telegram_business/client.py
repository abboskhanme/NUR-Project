"""Telegram Bot API klienti — shaxsiy chatlarga AI javob berish uchun.

Instagram klientidan farqi: bu yerda javob oynasi cheklovi YO'Q, ya'ni
istalgan vaqtda yozish mumkin. Business ulanishida xabar
`business_connection_id` bilan yuboriladi — shunda mijoz javobni "bot"dan
emas, AKKAUNT EGASIDAN (sizdan) kelgan deb ko'radi.
"""
from __future__ import annotations

import asyncio
import json
from typing import Union

import httpx
from loguru import logger

from app.config import settings

_TIMEOUT = 20.0
# Rasm yuklash sekinroq bo'lishi mumkin (albomda 10 tagacha rasm)
_UPLOAD_TIMEOUT = 60.0

# Rasm: Telegram'dagi `file_id` (qayta yuklamasdan) yoki (baytlar, MIME turi)
PhotoInput = Union[str, tuple[bytes, str]]

_EXT = {"image/png": "png", "image/webp": "webp"}


def _as_upload(name: str, photo: tuple[bytes, str]) -> tuple[str, bytes, str]:
    data, content_type = photo
    return (f"{name}.{_EXT.get(content_type, 'jpg')}", data, content_type)


def _largest_file_id(message: dict) -> str:
    sizes = message.get("photo") or []
    return str(sizes[-1].get("file_id") or "") if sizes else ""


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

    async def _call(
        self, method: str, payload: dict, *, files: dict | None = None
    ) -> tuple[bool, dict]:
        """Bitta so'rov: (muvaffaqiyat, javob/xato).

        `files` berilsa so'rov multipart bo'ladi (rasm yuklash) — murakkab
        maydonlar (klaviatura, albom ro'yxati) JSON satr sifatida ketadi.
        """
        if not settings.TG_SALES_BOT_TOKEN:
            return False, {"description": "TG_SALES_BOT_TOKEN sozlanmagan"}
        url = f"{self._base}/{method}"
        delay = 1.0
        for attempt in range(3):
            try:
                if files:
                    form = {k: v if isinstance(v, str) else json.dumps(v)
                            for k, v in payload.items() if v is not None}
                    async with httpx.AsyncClient(timeout=_UPLOAD_TIMEOUT) as client:
                        resp = await client.post(url, data=form, files=files)
                else:
                    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
                        resp = await client.post(url, json=payload)
                data = resp.json() if resp.content else {}
                if resp.status_code == 200 and data.get("ok"):
                    result = data.get("result")
                    return True, result if result is not None else {}
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
                # Rasm yuklashda javob kutish vaqti tugasa Telegram rasmni
                # allaqachon yuborgan bo'lishi mumkin — qayta urinsak mijoz
                # albomni ikki marta oladi. Faqat so'rov umuman yetib bormagan
                # (ulanish xatosi) holatda qayta urinamiz.
                if files and not isinstance(exc, (httpx.ConnectError, httpx.ConnectTimeout)):
                    logger.warning("TG {} javobi kelmadi, qayta yuborilmaydi: {}", method, exc)
                    return False, {"description": f"Telegram javob bermadi: {exc}"}
                logger.warning("TG {} ulanish xatosi ({}): {}", method, attempt + 1, exc)
                await asyncio.sleep(delay)
                delay *= 2
        return False, {"description": "Telegram javob bermadi (3 urinish)"}

    async def send_message(
        self, chat_id: str | int, text: str, *, business_connection_id: str | None = None,
        reply_markup: dict | None = None,
    ) -> dict:
        """Xabar yuboradi. Natija: {"sent": bool, "error": str|None}."""
        payload: dict = {"chat_id": chat_id, "text": text}
        if business_connection_id:
            payload["business_connection_id"] = business_connection_id
        if reply_markup:
            payload["reply_markup"] = reply_markup
        ok, data = await self._call("sendMessage", payload)
        if ok:
            return {"sent": True, "message_id": str(data.get("message_id") or "")}
        error = data.get("description") or "Yuborilmadi"
        logger.warning("Telegram xabar yuborilmadi: {}", error)
        return {"sent": False, "error": error}

    async def send_photo(
        self, chat_id: str | int, photo: PhotoInput, *, caption: str | None = None,
        business_connection_id: str | None = None, reply_markup: dict | None = None,
    ) -> dict:
        """Bitta rasm. Natija: {"sent": bool, "file_ids": [..], "error": str|None}."""
        payload: dict = {"chat_id": chat_id}
        if caption:
            payload["caption"] = caption
        if business_connection_id:
            payload["business_connection_id"] = business_connection_id
        if reply_markup:
            payload["reply_markup"] = reply_markup
        files = None
        if isinstance(photo, str):
            payload["photo"] = photo
        else:
            files = {"photo": _as_upload("photo", photo)}
        ok, data = await self._call("sendPhoto", payload, files=files)
        if ok:
            return {"sent": True, "file_ids": [_largest_file_id(data)]}
        error = data.get("description") or "Rasm yuborilmadi"
        logger.warning("Telegram rasm yuborilmadi: {}", error)
        return {"sent": False, "error": error}

    async def send_media_group(
        self, chat_id: str | int, photos: list[PhotoInput], *, caption: str | None = None,
        business_connection_id: str | None = None,
    ) -> dict:
        """Albom (2-10 rasm). Izoh birinchi rasmga qo'yiladi — albom ostida ko'rinadi."""
        media: list[dict] = []
        files: dict = {}
        for index, photo in enumerate(photos):
            entry: dict = {"type": "photo"}
            if isinstance(photo, str):
                entry["media"] = photo
            else:
                name = f"photo{index}"
                entry["media"] = f"attach://{name}"
                files[name] = _as_upload(name, photo)
            if index == 0 and caption:
                entry["caption"] = caption
            media.append(entry)
        payload: dict = {"chat_id": chat_id, "media": media}
        if business_connection_id:
            payload["business_connection_id"] = business_connection_id
        ok, data = await self._call("sendMediaGroup", payload, files=files or None)
        if ok and isinstance(data, list):
            return {"sent": True, "file_ids": [_largest_file_id(m) for m in data]}
        error = (data.get("description") if isinstance(data, dict) else None) or "Albom yuborilmadi"
        logger.warning("Telegram albom yuborilmadi: {}", error)
        return {"sent": False, "error": error}

    async def set_my_commands(self, commands: list[dict]) -> bool:
        """Botning «Menu» tugmasidagi buyruqlar ro'yxati (shaxsiy chatlar uchun)."""
        ok, data = await self._call("setMyCommands", {
            "commands": commands, "scope": {"type": "all_private_chats"},
        })
        if not ok:
            logger.warning("Bot buyruqlari o'rnatilmadi: {}", data.get("description"))
        return ok

    async def delete_my_commands(self) -> bool:
        ok, _ = await self._call("deleteMyCommands", {"scope": {"type": "all_private_chats"}})
        return ok

    async def answer_callback_query(self, callback_query_id: str) -> bool:
        """Tugma bosilgach Telegram'dagi «yuklanmoqda» belgisini o'chiradi."""
        ok, _ = await self._call("answerCallbackQuery", {"callback_query_id": callback_query_id})
        return ok

    async def get_me(self) -> dict:
        ok, data = await self._call("getMe", {})
        return data if ok else {}

    async def set_webhook(self, url: str, secret: str) -> bool:
        """Webhook o'rnatadi (Business va oddiy chat xabarlari uchun)."""
        ok, data = await self._call("setWebhook", {
            "url": url,
            "secret_token": secret,
            "allowed_updates": [
                "message", "edited_message", "callback_query",
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
