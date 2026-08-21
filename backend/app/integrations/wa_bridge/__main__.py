"""Telegram → WhatsApp ko'prigi jarayoni.

Ishga tushirish:
    python -m app.integrations.wa_bridge

Ikki halqa parallel ishlaydi:
  • kuzatuvchi — Telegram kanalidagi yangi postlarni navbatga yozadi
  • yuboruvchi — vaqti kelgan postlarni xodim WhatsApp'iga uzatadi

Sozlamalar «Tizim sozlamalari → Telegram → WhatsApp» da; jarayon ularni
ishlab turgan holda kuzatadi (o'chirilgan bo'lsa kutib turadi, yiqilmaydi).
"""
from __future__ import annotations

import asyncio
import logging
import sys

from loguru import logger

from app.integrations.wa_bridge.config import load_config
from app.integrations.wa_bridge.sender import send_due
from app.integrations.wa_bridge.telegram_source import poll_once

IDLE_SECONDS = 30          # sozlanmagan bo'lsa shuncha kutamiz
SEND_INTERVAL = 60         # navbatni shuncha vaqtda tekshiramiz
ERROR_BACKOFF = 30

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger.remove()
logger.add(sys.stderr, level="INFO")


async def watcher_loop() -> None:
    """Telegram kanalidan postlarni o'qish (uzun so'rov)."""
    while True:
        try:
            cfg = await load_config()
            if not cfg.can_watch:
                await asyncio.sleep(IDLE_SECONDS)
                continue
            await poll_once(cfg)
        except asyncio.CancelledError:
            raise
        except Exception as exc:  # noqa: BLE001
            logger.exception("Kuzatuvchi xatosi: {}", exc)
            await asyncio.sleep(ERROR_BACKOFF)


async def sender_loop() -> None:
    """Vaqti kelgan postlarni WhatsApp'ga yuborish."""
    while True:
        try:
            cfg = await load_config()
            if cfg.can_send:
                await send_due(cfg)
        except asyncio.CancelledError:
            raise
        except Exception as exc:  # noqa: BLE001
            logger.exception("Yuboruvchi xatosi: {}", exc)
        await asyncio.sleep(SEND_INTERVAL)


async def main() -> None:
    logger.info("NUR WhatsApp ko'prigi ishga tushdi")
    await asyncio.gather(watcher_loop(), sender_loop())


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("To'xtatildi")
