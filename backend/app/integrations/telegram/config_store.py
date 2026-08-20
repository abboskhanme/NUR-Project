"""Bot sozlamalari — Tizim sozlamalari (DB) dan o'qiladi, .env zaxira bo'ladi.

Token, bot nomi, hisobot oluvchilar va vaqti super-admin UI'da boshqariladi
(«Tizim sozlamalari → ERP Telegram boti»). Bot ularni ishlab turgan holda
kuzatib boradi: token yoki hisobot vaqti o'zgarsa — o'zi qayta ulanadi.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from app.core.settings_store import as_bool, as_chat_ids, read_values

KEY_TOKEN = "ERP_BOT_TOKEN"
KEY_USERNAME = "ERP_BOT_USERNAME"
KEY_ADMINS = "ERP_BOT_ADMIN_CHAT_IDS"
KEY_REPORT_TIME = "ERP_BOT_REPORT_TIME"
KEY_NOTIFY = "ERP_BOT_NOTIFY_NEW_ORDER"

ALL_KEYS = (KEY_TOKEN, KEY_USERNAME, KEY_ADMINS, KEY_REPORT_TIME, KEY_NOTIFY)


@dataclass(frozen=True)
class BotConfig:
    token: str = ""
    username: str = ""
    admin_ids: list[int] = field(default_factory=list)
    report_time: str = "20:00"
    notify_new_order: bool = True

    @property
    def restart_key(self) -> tuple:
        """Shu qiymatlar o'zgarsa botni qayta ulash kerak.

        Qolganlari (adminlar ro'yxati, xabar bayrog'i) har safar ishlatishdan
        oldin o'qiladi — qayta ulash shart emas.
        """
        return (self.token, self.report_time)


async def load_config() -> BotConfig:
    values = await read_values(*ALL_KEYS)
    return BotConfig(
        token=(values[KEY_TOKEN] or "").strip(),
        username=(values[KEY_USERNAME] or "").strip().lstrip("@"),
        admin_ids=as_chat_ids(values[KEY_ADMINS]),
        report_time=(values[KEY_REPORT_TIME] or "20:00").strip(),
        notify_new_order=as_bool(values[KEY_NOTIFY], default=True),
    )


async def admin_chat_ids() -> list[int]:
    """Kunlik hisobot va yangi buyurtma xabarini oluvchilar."""
    return as_chat_ids((await read_values(KEY_ADMINS))[KEY_ADMINS])


async def notify_new_order_enabled() -> bool:
    return as_bool((await read_values(KEY_NOTIFY))[KEY_NOTIFY], default=True)
