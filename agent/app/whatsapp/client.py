"""WhatsApp Cloud API klienti — mijozga javob yuborish.

Instagram/Telegram klientlari bilan bir xil shaklda: `send_message()` natijani
lug'at qilib qaytaradi (`{"sent": bool, "error": str}`), shunda pipeline barcha
kanallar uchun bir xil ishlaydi.

24 soatlik oyna: mijozning oxirgi xabaridan 24 soat o'tgan bo'lsa Meta erkin
matnni rad etadi (131047). Bu holat AI uchun deyarli uchramaydi — biz faqat
mijoz endigina yozganida javob beramiz — lekin ERP'dan operator yozganda
bo'lishi mumkin, shuning uchun xato matni alohida belgilanadi.
"""
from __future__ import annotations

from typing import Any

import httpx
from loguru import logger

from app.config import settings

GRAPH_BASE = "https://graph.facebook.com"
TIMEOUT = 30.0

# Oyna yopilganini bildiruvchi Meta xato kodlari
WINDOW_ERROR_CODES = {131047, 131051, 131026, 470}
MAX_TEXT = 4096


class WhatsAppClient:
    """Sozlamalar ishlab turgan holda o'zgaradi — har chaqiruvda o'qiladi."""

    @property
    def enabled(self) -> bool:
        return bool(settings.WA_PHONE_NUMBER_ID and settings.WA_ACCESS_TOKEN)

    @property
    def _base(self) -> str:
        version = settings.WA_GRAPH_VERSION or "v23.0"
        return f"{GRAPH_BASE}/{version}/{settings.WA_PHONE_NUMBER_ID}"

    @property
    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {settings.WA_ACCESS_TOKEN}"}

    async def _post(self, payload: dict[str, Any]) -> dict:
        if not self.enabled:
            return {"sent": False, "error": "WhatsApp sozlanmagan"}
        body = {"messaging_product": "whatsapp", **payload}
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT) as client:
                resp = await client.post(
                    f"{self._base}/messages", headers=self._headers, json=body
                )
            data = resp.json() if resp.content else {}
        except httpx.HTTPError as exc:
            return {"sent": False, "error": f"Ulanish xatosi: {exc}"}

        if resp.status_code == 200:
            msgs = data.get("messages") or [{}]
            return {"sent": True, "message_id": str(msgs[0].get("id") or "")}

        err = (data or {}).get("error") or {}
        message = err.get("error_user_msg") or err.get("message") or str(data)[:200]
        closed = err.get("code") in WINDOW_ERROR_CODES
        if closed:
            message = (
                "WhatsApp javob oynasi yopiq — mijozning oxirgi xabaridan 24 "
                "soat o'tgan. Telefon orqali bog'laning."
            )
        return {"sent": False, "error": str(message), "window_closed": closed}

    async def send_message(self, to: str, text: str) -> dict:
        """Mijozga matn yuboradi."""
        text = (text or "").strip()
        if not text:
            return {"sent": False, "error": "Xabar matni bo'sh"}
        return await self._post({
            "to": to, "type": "text",
            "text": {"body": text[:MAX_TEXT], "preview_url": True},
        })

    async def mark_read(self, message_id: str) -> None:
        """Xabarni «o'qildi» qilib belgilaydi (mijoz ko'k belgini ko'radi)."""
        if not message_id or not self.enabled:
            return
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                await client.post(
                    f"{self._base}/messages",
                    headers=self._headers,
                    json={"messaging_product": "whatsapp", "status": "read",
                          "message_id": message_id},
                )
        except httpx.HTTPError as exc:
            logger.debug("WhatsApp «o'qildi» belgisi qo'yilmadi: {}", exc)


whatsapp = WhatsAppClient()
