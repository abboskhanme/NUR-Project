"""Telegram bot jarayoni: dispatcher, kunlik hisobot rejasi, ishga tushirish.

Ishga tushirish:
    python -m app.integrations.telegram

Sozlamalar (token, bot nomi, hisobot oluvchilar va vaqti) super-admin UI'da —
«Tizim sozlamalari → ERP Telegram boti» — turadi, .env esa zaxira. Jarayon
ularni kuzatib boradi: token yoki hisobot vaqti o'zgarsa o'zi qayta ulanadi,
token hali kiritilmagan bo'lsa yiqilmasdan kutib turadi.
"""
from __future__ import annotations

import asyncio
import contextlib
import logging

from aiogram import Bot, Dispatcher
from aiogram.fsm.storage.memory import MemoryStorage
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.core.config import settings

from . import admin_flow, customer_flow, service_flow
from .common import tz
from .config_store import BotConfig, admin_chat_ids, load_config
from .digest import build_digest, format_digest

# Sozlama o'zgarganini qanchada bir tekshirish / xatodan keyin qayta urinish.
CONFIG_POLL_SECONDS = 30
RETRY_SECONDS = 30

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
log = logging.getLogger("telegram-bot")


def build_dispatcher() -> Dispatcher:
    dp = Dispatcher(storage=MemoryStorage())
    # Admin router avval — /id, /report buyruqlari mijoz fallback'idan oldin.
    dp.include_router(admin_flow.router)
    # Servis lokatsiyasi — xodim forward qilgan pin mijoz oqimiga tushmasin.
    dp.include_router(service_flow.router)
    dp.include_router(customer_flow.router)
    return dp


def _parse_report_time(raw: str) -> tuple[int, int]:
    """'HH:MM' -> (hour, minute). Xato bo'lsa 20:00."""
    raw = (raw or "20:00").strip()
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
    admins = await admin_chat_ids()
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


def _setup_scheduler(bot: Bot, cfg: BotConfig) -> AsyncIOScheduler:
    hour, minute = _parse_report_time(cfg.report_time)
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


async def _run_until_config_changes(cfg: BotConfig) -> None:
    """Botni ishga tushiradi va sozlama o'zgarguncha ishlatib turadi."""
    bot = Bot(cfg.token)
    dp = build_dispatcher()
    scheduler = _setup_scheduler(bot, cfg)
    scheduler.start()
    polling = asyncio.create_task(dp.start_polling(bot, handle_signals=False))
    log.info("Telegram bot ishga tushdi (polling).")

    try:
        while True:
            await asyncio.sleep(CONFIG_POLL_SECONDS)
            if polling.done():
                polling.result()          # xato bo'lsa — tashqariga uzatamiz
                return
            try:
                fresh = await load_config()
            except Exception:  # noqa: BLE001 — baza vaqtincha yo'q bo'lishi mumkin
                log.warning("Sozlamani o'qib bo'lmadi — eskisi bilan davom etamiz")
                continue
            if fresh.restart_key != cfg.restart_key:
                log.info("Sozlama o'zgardi — bot qayta ulanmoqda.")
                return
    finally:
        scheduler.shutdown(wait=False)
        if not polling.done():
            polling.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await polling
        await bot.session.close()


async def main() -> None:
    """Tokenni kutadi, o'zgarsa qayta ulanadi, xatodan keyin qayta urinadi."""
    warned = False
    while True:
        try:
            cfg = await load_config()
        except Exception:  # noqa: BLE001
            log.exception("Sozlamalarni o'qishda xato")
            await asyncio.sleep(RETRY_SECONDS)
            continue

        if not cfg.token:
            if not warned:
                log.warning(
                    "Bot tokeni yo'q — ERP'da «Tizim sozlamalari → ERP Telegram "
                    "boti» bo'limida kiriting. Kutib turibman."
                )
                warned = True
            await asyncio.sleep(RETRY_SECONDS)
            continue

        warned = False
        try:
            await _run_until_config_changes(cfg)
        except Exception:  # noqa: BLE001 — noto'g'ri token, tarmoq, va h.k.
            log.exception("Bot to'xtadi — %s soniyadan keyin qayta urinaman",
                          RETRY_SECONDS)
            await asyncio.sleep(RETRY_SECONDS)


if __name__ == "__main__":
    asyncio.run(main())
