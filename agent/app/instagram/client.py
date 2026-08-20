"""Instagram Graph API klienti — kommentga javob, private reply, DM.

**"Instagram API with Instagram Login"** ishlatiladi (graph.instagram.com), ya'ni
Facebook Page ulash SHART EMAS va o'z akkauntimiz uchun App Review kerak emas.

Endpointlar:
  • ochiq javob      -> POST /{comment-id}/replies
  • private reply/DM -> POST /me/messages
Ruxsatlar: instagram_business_basic, ..._manage_messages, ..._manage_comments.

Yuborishlar global throttle bilan cheklanadi (soniyasiga ~1 ta) — Instagram
rate limitiga urilmaslik va "spam" belgisidan qochish uchun.
"""
from __future__ import annotations

import asyncio
import time

import httpx
from loguru import logger

from app.config import settings

# Global throttle: ketma-ket ikki so'rov orasida kamida shuncha soniya
_MIN_INTERVAL = 1.0
_throttle_lock = asyncio.Lock()
_last_call = 0.0


async def _throttle() -> None:
    global _last_call
    async with _throttle_lock:
        wait = _MIN_INTERVAL - (time.monotonic() - _last_call)
        if wait > 0:
            await asyncio.sleep(wait)
        _last_call = time.monotonic()


class InstagramClient:
    # Qiymatlarni HAR chaqiruvda settings'dan o'qiymiz — shunda remote config
    # (ERP'dan) token/versiya/ID ni yangilaganda darrov qo'llanadi (restartsiz).
    @property
    def _base(self) -> str:
        return f"{settings.IG_API_BASE.rstrip('/')}/{settings.GRAPH_API_VERSION}"

    async def _post(self, path: str, *, params=None, json=None) -> dict:
        params = {**(params or {}), "access_token": settings.IG_ACCESS_TOKEN}
        url = f"{self._base}/{path}"
        delay = 1.0
        for attempt in range(3):
            await _throttle()
            try:
                async with httpx.AsyncClient(timeout=15.0) as client:
                    resp = await client.post(url, params=params, json=json)
                if resp.status_code == 200:
                    return resp.json()
                # rate-limit / vaqtinchalik xatoliklar — backoff
                if resp.status_code in (429, 500, 503):
                    logger.warning(
                        "IG API {} ({}-urinish), backoff {}s: {}",
                        resp.status_code, attempt + 1, delay, resp.text[:200],
                    )
                    await asyncio.sleep(delay)
                    delay *= 2
                    continue
                logger.error("IG API xato {}: {}", resp.status_code, resp.text[:300])
                return {}
            except httpx.HTTPError as exc:
                logger.warning("IG API ulanish xatosi ({}): {}", attempt + 1, exc)
                await asyncio.sleep(delay)
                delay *= 2
        logger.error("IG API 3 urinishdan keyin ham muvaffaqiyatsiz: {}", path)
        return {}

    async def _get(self, path: str, *, params=None) -> dict:
        """GET so'rov (throttle + backoff bilan). Xatoda bo'sh dict."""
        params = {**(params or {}), "access_token": settings.IG_ACCESS_TOKEN}
        url = path if path.startswith("http") else f"{self._base}/{path}"
        delay = 1.0
        for attempt in range(3):
            await _throttle()
            try:
                async with httpx.AsyncClient(timeout=20.0) as client:
                    resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    return resp.json()
                if resp.status_code in (429, 500, 503):
                    logger.warning(
                        "IG API GET {} ({}-urinish), backoff {}s: {}",
                        resp.status_code, attempt + 1, delay, resp.text[:200],
                    )
                    await asyncio.sleep(delay)
                    delay *= 2
                    continue
                logger.error("IG API GET xato {}: {}", resp.status_code, resp.text[:300])
                return {}
            except httpx.HTTPError as exc:
                logger.warning("IG API GET ulanish xatosi ({}): {}", attempt + 1, exc)
                await asyncio.sleep(delay)
                delay *= 2
        logger.error("IG API GET 3 urinishdan keyin ham muvaffaqiyatsiz: {}", path)
        return {}

    async def list_conversations(self, after: str | None = None) -> dict:
        """Suhbatlar ro'yxati (Requests papkasidagilar ham, 30 kun ichida faol).

        Nested `messages{...}` bilan bitta so'rovda xabar matnlarini ham
        olishga urinamiz — bo'lmasa importer har xabarni alohida so'raydi.
        """
        params: dict[str, str] = {
            "platform": "instagram",
            "fields": (
                "id,updated_time,participants,"
                "messages.limit(50){id,created_time,from,to,message}"
            ),
            "limit": "50",
        }
        if after:
            params["after"] = after
        return await self._get("me/conversations", params=params)

    async def get_message(self, message_id: str) -> dict:
        """Bitta xabar tafsiloti (nested so'rov ishlamasa zaxira yo'l)."""
        return await self._get(
            message_id, params={"fields": "id,created_time,from,to,message"}
        )

    async def reply_to_comment(self, comment_id: str, message: str) -> dict:
        """Ochiq kommentga ochiq javob yozadi."""
        return await self._post(f"{comment_id}/replies", params={"message": message})

    async def send_private_reply(self, comment_id: str, message: str) -> dict:
        """Kommentga shaxsiy (DM) javob — har komment uchun faqat BIR marta."""
        return await self._post(
            "me/messages",
            json={"recipient": {"comment_id": comment_id}, "message": {"text": message}},
        )

    async def send_dm(self, recipient_id: str, message: str) -> dict:
        """Foydalanuvchiga DM yuboradi (24 soatlik oyna qoidasi)."""
        return await self._post(
            "me/messages",
            json={"recipient": {"id": recipient_id}, "message": {"text": message}},
        )

    async def subscribe_webhooks(self) -> dict:
        """Akkauntni webhook maydonlariga obuna qiladi (/connect oqimida chaqiriladi).

        FAQAT `comments` va `messages`. Ilgari uchinchi bo'lib `message_echoes`
        ham yuborilardi — Instagram API'da bunday maydon YO'Q va u butun so'rovni
        rad etardi (400: "Param subscribed_fields[2] must be one of ..."), ya'ni
        akkaunt hech qaysi maydonga obuna bo'lmay qolardi va webhook umuman
        kelmasdi. Akkauntdan chiqqan xabarlar (echo) baribir `messages` orqali
        `is_echo` bayrog'i bilan keladi — alohida maydon shart emas.
        """
        return await self._post(
            "me/subscribed_apps",
            params={"subscribed_fields": "comments,messages"},
        )


instagram = InstagramClient()
