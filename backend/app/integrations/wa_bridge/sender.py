"""Navbatdagi postlarni xodimning WhatsApp raqamiga yuborish.

Oqim: `planned_at` kelgan post → media Meta serveriga yuklanadi → har bir
maqsadli raqamga rasm/video + caption yuboriladi → xodim uni WhatsApp
kanaliga **Forward** qiladi.

24 soatlik oyna yopiq bo'lsa: tasdiqlangan shablon yuboriladi ("javob yozing"),
post `pending` holatida qoladi va xodim javob yozishi bilan keyingi urinishda
o'zi ketadi. 24 soat davomida ham ketmasa — `failed`.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from loguru import logger
from sqlalchemy import select

from app.db.session import AsyncSessionLocal
from app.integrations.wa_bridge.config import BridgeConfig
from app.integrations.whatsapp.client import (
    SendResult, WhatsAppClient, WhatsAppConfig, guess_filename, size_limit_for,
)
from app.models.wa_bridge import ChannelPost

BATCH = 5                       # bitta siklda nechta post
GIVE_UP_AFTER = timedelta(hours=24)
# Shablon spam bo'lmasligi uchun: bitta post uchun necha marta yuborilsin
TEMPLATE_EVERY_N_ATTEMPTS = 12


def _client(cfg: BridgeConfig) -> WhatsAppClient:
    return WhatsAppClient(WhatsAppConfig(
        phone_number_id=cfg.phone_number_id,
        access_token=cfg.access_token,
        version=cfg.graph_version,
        template_name=cfg.template_name,
        template_lang=cfg.template_lang,
    ))


def _caption_for(post: ChannelPost) -> str:
    return (post.caption or "").strip()


async def _deliver(client: WhatsAppClient, cfg: BridgeConfig,
                   post: ChannelPost) -> tuple[list[str], str, bool, bool]:
    """Postni barcha raqamlarga yuboradi.

    Qaytaradi: (yuborilgan raqamlar, xato matni, oyna_yopiqmi, qaytarib
    bo'lmaydigan xatomi). Oxirgisi True bo'lsa qayta urinishning ma'nosi yo'q
    (masalan fayl WhatsApp cheklovidan katta) — post `skipped` qilinadi.
    """
    caption = _caption_for(post)
    media_id = ""

    if post.media:
        limit = size_limit_for(post.kind)
        if len(post.media) > limit:
            return [], (
                f"Fayl {round(len(post.media) / 1048576, 1)} MB — WhatsApp "
                f"{round(limit / 1048576)} MB gacha ruxsat beradi. Qo'lda joylang."
            ), False, True
        media_id, error = await client.upload_media(
            post.media,
            mime=post.media_mime or "application/octet-stream",
            filename=post.media_name or guess_filename(post.kind, post.media_mime or ""),
        )
        if not media_id:
            return [], error, False, False

    delivered: list[str] = []
    last_error, window_closed = "", False
    for number in cfg.targets:
        if media_id:
            result: SendResult = await client.send_media(
                number, kind=post.kind, media_id=media_id, caption=caption
            )
        else:
            result = await client.send_text(number, caption)

        if result.sent:
            delivered.append(number)
            continue
        last_error = result.error
        window_closed = window_closed or result.window_closed
        logger.warning("WhatsApp yuborilmadi ({}): {}", number, result.error)

    return delivered, last_error, window_closed, False


async def _notify_window(client: WhatsAppClient, cfg: BridgeConfig) -> None:
    """Oyna yopilgan raqamlarga shablon yuboradi (javob yozsin — oyna ochiladi)."""
    for number in cfg.targets:
        result = await client.send_template(number)
        if not result.sent:
            logger.warning("Shablon yuborilmadi ({}): {}", number, result.error)


async def send_due(cfg: BridgeConfig) -> int:
    """Vaqti kelgan postlarni yuboradi. Qaytaradi: yuborilganlar soni."""
    if not cfg.can_send:
        return 0

    client = _client(cfg)
    now = datetime.now(timezone.utc)
    sent_count = 0

    async with AsyncSessionLocal() as db:
        # SKIP LOCKED — bir nechta jarayon bo'lsa ham bitta post ikki marta ketmaydi
        posts = (await db.execute(
            select(ChannelPost)
            .where(ChannelPost.status == "pending", ChannelPost.planned_at <= now)
            .order_by(ChannelPost.planned_at)
            .limit(BATCH)
            .with_for_update(skip_locked=True)
        )).scalars().all()

        for post in posts:
            delivered, error, window_closed, fatal = await _deliver(client, cfg, post)
            post.attempts += 1

            if delivered:
                post.status = "sent"
                post.sent_at = datetime.now(timezone.utc)
                post.sent_to = ", ".join(delivered)
                post.error = error or None
                post.media = None            # joy egallamasin — yuborildi
                sent_count += 1
                logger.info("Post WhatsApp'ga yuborildi: {} -> {}",
                            post.tg_message_id, post.sent_to)
                continue

            post.error = error or "Yuborilmadi"
            if fatal:
                # Qayta urinish foydasiz — postni qo'lda joylash kerak
                post.status = "skipped"
                logger.warning("Post o'tkazib yuborildi: {} — {}",
                               post.tg_message_id, post.error)
                continue
            if window_closed:
                # Xodim javob yozsa oyna ochiladi — shablon bilan turtki beramiz
                if post.attempts == 1 or post.attempts % TEMPLATE_EVERY_N_ATTEMPTS == 0:
                    await _notify_window(client, cfg)
                post.error = (
                    "WhatsApp javob oynasi yopiq — xodimga eslatma yuborildi. "
                    "U javob yozishi bilan post avtomatik ketadi."
                )

            if now - post.planned_at > GIVE_UP_AFTER:
                post.status = "failed"
                logger.error("Post 24 soatda yuborilmadi: {}", post.tg_message_id)

        await db.commit()

    return sent_count
