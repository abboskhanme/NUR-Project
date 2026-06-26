"""Telegram bot jarayoni: dispatcher, kunlik hisobot rejasi, ishga tushirish.

Ishga tushirish:
    python -m app.integrations.telegram
"""
from __future__ import annotations

import asyncio
import logging

from aiogram import Bot, Dispatcher
from aiogram.fsm.storage.memory import MemoryStorage
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.core.config import settings

from . import admin_flow, customer_flow
from .common import tz
from .digest import build_digest, format_digest

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
log = logging.getLogger("telegram-bot")


def build_dispatcher() -> Dispatcher:
    dp = Dispatcher(storage=MemoryStorage())
    # Admin router avval — /id, /report buyruqlari mijoz fallback'idan oldin.
    dp.include_router(admin_flow.router)
    dp.include_router(customer_flow.router)
    return dp


def _parse_report_time() -> tuple[int, int]:
    """'HH:MM' -> (hour, minute). Xato bo'lsa 20:00."""
    raw = (settings.TELEGRAM_REPORT_TIME or "20:00").strip()
    try:
        hh, mm = raw.split(":")
        h, m = int(hh), int(mm)
        if 0 <= h <= 23 and 0 <= m <= 59:
            return h, m
    except Exception:  # noqa: BLE001
        pass
    log.warning("TELEGRAM_REPORT_TIME noto'g'ri (%r) — 20:00 ishlatiladi", raw)
    return 20, 0


async def _send_daily_report(bot: Bot) -> None:
    """Kunlik hisobotni barcha admin chat_id'larga yuboradi."""
    admins = settings.TELEGRAM_ADMIN_IDS
    if not admins:
        log.info("Kunlik hisobot: admin chat_id yo'q — o'tkazib yuborildi.")
        return
    try:
        text = format_digest(await build_digest())
    except Exception:  # noqa: BLE001
        log.exception("Kunlik hisobotni yig'ishda xato")
        return
    for chat_id in admins:
        try:
            await bot.send_message(chat_id, text, parse_mode="HTML")
            log.info("Kunlik hisobot yuborildi: %s", chat_id)
        except Exception:  # noqa: BLE001
            log.warning("Hisobot yuborilmadi: %s", chat_id)


def _setup_scheduler(bot: Bot) -> AsyncIOScheduler:
    hour, minute = _parse_report_time()
    scheduler = AsyncIOScheduler(timezone=tz())
    scheduler.add_job(
        _send_daily_report,
        trigger=CronTrigger(hour=hour, minute=minute),
        args=[bot],
        id="daily_report",
        replace_existing=True,
    )
    log.info("Kunlik hisobot rejaga solindi: har kuni %02d:%02d (%s)",
             hour, minute, settings.TIMEZONE)
    return scheduler


async def main() -> None:
    if not settings.TELEGRAM_BOT_TOKEN:
        log.error("TELEGRAM_BOT_TOKEN o'rnatilmagan — bot ishga tushmaydi. "
                  ".env(.prod) faylga TELEGRAM_BOT_TOKEN qo'shing.")
        return

    bot = Bot(settings.TELEGRAM_BOT_TOKEN)
    dp = build_dispatcher()
    scheduler = _setup_scheduler(bot)
    scheduler.start()

    log.info("Telegram bot ishga tushdi (polling).")
    try:
        await dp.start_polling(bot)
    finally:
        scheduler.shutdown(wait=False)
        await bot.session.close()


if __name__ == "__main__":
    asyncio.run(main())
