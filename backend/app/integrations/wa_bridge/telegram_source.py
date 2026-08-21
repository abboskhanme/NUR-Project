"""Telegram kanalidagi postlarni o'qib navbatga yozish.

Bot kanalga ADMIN qilinishi kerak — shundagina `channel_post` yangilanishlari
keladi. Har bir post navbatga yoziladi va `planned_at` (post vaqti + kechikish)
kelganda WhatsApp'ga uzatiladi.

Dublikat bo'lmasligi ikki qavatli: `offset` saqlanadi va (chat, message_id)
juftligi bazada unikal.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import httpx
from loguru import logger
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.db.session import AsyncSessionLocal
from app.integrations.wa_bridge.config import BridgeConfig
from app.models.system import SystemSetting
from app.models.wa_bridge import ChannelPost

# Bot API orqali yuklab olish chegarasi (local Bot API server bilan kattaroq)
BOT_API_FILE_LIMIT = 20 * 1024 * 1024
OFFSET_KEY = "WA_TG_OFFSET"          # katalogda yo'q — faqat ichki holat
LONG_POLL_SECONDS = 25


async def _get_offset() -> int:
    async with AsyncSessionLocal() as db:
        raw = (await db.execute(
            select(SystemSetting.value).where(SystemSetting.key == OFFSET_KEY)
        )).scalar_one_or_none()
    try:
        return int(raw or 0)
    except (TypeError, ValueError):
        return 0


async def _set_offset(value: int) -> None:
    async with AsyncSessionLocal() as db:
        row = (await db.execute(
            select(SystemSetting).where(SystemSetting.key == OFFSET_KEY)
        )).scalar_one_or_none()
        if row is None:
            db.add(SystemSetting(key=OFFSET_KEY, value=str(value)))
        else:
            row.value = str(value)
        await db.commit()


def _api(cfg: BridgeConfig, method: str) -> str:
    return f"{cfg.tg_api_base.rstrip('/')}/bot{cfg.bot_token}/{method}"


def extract_media(post: dict[str, Any]) -> tuple[str, Optional[dict]]:
    """Post turini va yuklab olinadigan fayl ma'lumotini aniqlaydi.

    Qaytaradi: (kind, {"file_id", "size", "mime", "name"} yoki None)
    """
    if post.get("photo"):
        # Telegram bir necha o'lchamda beradi — eng kattasi oxirida
        biggest = sorted(post["photo"], key=lambda p: p.get("file_size") or 0)[-1]
        return "photo", {
            "file_id": biggest.get("file_id"),
            "size": biggest.get("file_size") or 0,
            "mime": "image/jpeg",
            "name": "post.jpg",
        }
    for key, kind in (("video", "video"), ("animation", "video")):
        item = post.get(key)
        if item:
            return kind, {
                "file_id": item.get("file_id"),
                "size": item.get("file_size") or 0,
                "mime": item.get("mime_type") or "video/mp4",
                "name": item.get("file_name") or "post.mp4",
            }
    doc = post.get("document")
    if doc:
        return "document", {
            "file_id": doc.get("file_id"),
            "size": doc.get("file_size") or 0,
            "mime": doc.get("mime_type") or "application/octet-stream",
            "name": doc.get("file_name") or "post.bin",
        }
    return "text", None


async def download_file(cfg: BridgeConfig, file_id: str) -> tuple[bytes, str]:
    """Faylni Telegram'dan yuklab oladi. Qaytaradi: (bayt, xato)."""
    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            info = await client.get(_api(cfg, "getFile"), params={"file_id": file_id})
            data = info.json() if info.content else {}
            if not data.get("ok"):
                return b"", str(data.get("description") or "getFile xatosi")
            path = (data.get("result") or {}).get("file_path")
            if not path:
                return b"", "Fayl yo'li topilmadi"
            url = f"{cfg.tg_api_base.rstrip('/')}/file/bot{cfg.bot_token}/{path}"
            resp = await client.get(url)
            if resp.status_code != 200:
                return b"", f"Yuklab olinmadi ({resp.status_code})"
            return resp.content, ""
    except httpx.HTTPError as exc:
        return b"", f"Ulanish xatosi: {exc}"


async def save_post(cfg: BridgeConfig, post: dict[str, Any]) -> Optional[str]:
    """Kanal postini navbatga yozadi. Qaytaradi: holat (yoki None — o'tkazildi)."""
    chat = post.get("chat") or {}
    chat_id = str(chat.get("id") or "")
    msg_id = str(post.get("message_id") or "")
    if not chat_id or not msg_id:
        return None
    if cfg.channel_id and chat_id != cfg.channel_id.strip():
        return None                      # boshqa kanal — bizni qiziqtirmaydi

    caption = (post.get("caption") or post.get("text") or "").strip()
    kind, media = extract_media(post)
    if kind == "text" and not caption:
        return None                      # bo'sh/qo'llab-quvvatlanmaydigan post

    posted_at = datetime.fromtimestamp(int(post.get("date") or 0), tz=timezone.utc)
    planned_at = posted_at + timedelta(minutes=cfg.delay_minutes)

    status, error, blob = "pending", None, b""
    if media and media.get("file_id"):
        if (media.get("size") or 0) > BOT_API_FILE_LIMIT:
            status = "skipped"
            error = (
                f"Fayl {round((media['size'] or 0) / 1048576, 1)} MB — Telegram Bot API "
                f"20 MB gacha yuklab olishga ruxsat beradi. Postni qo'lda joylang."
            )
        else:
            blob, error = await download_file(cfg, str(media["file_id"]))
            if error:
                status = "failed"

    async with AsyncSessionLocal() as db:
        db.add(ChannelPost(
            tg_chat_id=chat_id,
            tg_message_id=msg_id,
            media_group_id=post.get("media_group_id"),
            posted_at=posted_at,
            kind=kind,
            caption=caption or None,
            media=blob or None,
            media_mime=(media or {}).get("mime"),
            media_name=(media or {}).get("name"),
            media_size=len(blob) if blob else int((media or {}).get("size") or 0),
            planned_at=planned_at,
            status=status,
            error=error,
        ))
        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            return None                  # allaqachon yozilgan (dublikat)

    logger.info("Kanal posti navbatga qo'shildi: {} ({}), holat={}", msg_id, kind, status)
    return status


async def poll_once(cfg: BridgeConfig) -> int:
    """Bitta getUpdates sikli. Qaytaradi: qayta ishlangan postlar soni."""
    offset = await _get_offset()
    # Bo'sh `offset=` yubormaymiz — ba'zi serverlar (va local Bot API) buni
    # noto'g'ri deb rad etadi. Birinchi ishga tushishda parametr umuman ketmaydi.
    params: dict[str, object] = {
        "timeout": LONG_POLL_SECONDS,
        "allowed_updates": '["channel_post"]',
    }
    if offset:
        params["offset"] = offset
    try:
        async with httpx.AsyncClient(timeout=LONG_POLL_SECONDS + 10) as client:
            resp = await client.get(_api(cfg, "getUpdates"), params=params)
        data = resp.json() if resp.content else {}
    except httpx.HTTPError as exc:
        logger.warning("Telegram getUpdates xatosi: {}", exc)
        return 0

    if not data.get("ok"):
        logger.warning("Telegram getUpdates rad etdi: {}", data.get("description"))
        return 0

    handled = 0
    last_id = offset - 1
    for update in data.get("result") or []:
        last_id = int(update.get("update_id") or last_id)
        post = update.get("channel_post")
        if isinstance(post, dict) and await save_post(cfg, post):
            handled += 1
    if data.get("result"):
        await _set_offset(last_id + 1)
    return handled
