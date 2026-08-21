"""Ko'prik sozlamalari — «Tizim sozlamalari» (DB) dan o'qiladi.

Barcha kalitlar `local=True`: ular ERP'ning O'Z sozlamasi, tashqi Instagram
agentiga yuborilmaydi.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from app.core.settings_store import as_bool, read_values

KEY_ENABLED = "WA_ENABLED"
KEY_BOT_TOKEN = "WA_BRIDGE_BOT_TOKEN"
KEY_CHANNEL_ID = "WA_SOURCE_CHANNEL_ID"
KEY_PHONE_ID = "WA_PHONE_NUMBER_ID"
KEY_TOKEN = "WA_ACCESS_TOKEN"
KEY_TARGETS = "WA_TARGET_NUMBERS"
KEY_DELAY = "WA_DELAY_MINUTES"
KEY_TEMPLATE = "WA_TEMPLATE_NAME"
KEY_TEMPLATE_LANG = "WA_TEMPLATE_LANG"
KEY_VERSION = "WA_GRAPH_VERSION"
KEY_TG_API = "WA_TG_API_BASE"

ALL_KEYS = (
    KEY_ENABLED, KEY_BOT_TOKEN, KEY_CHANNEL_ID, KEY_PHONE_ID, KEY_TOKEN,
    KEY_TARGETS, KEY_DELAY, KEY_TEMPLATE, KEY_TEMPLATE_LANG, KEY_VERSION, KEY_TG_API,
)

DEFAULT_DELAY_MINUTES = 60


def parse_numbers(raw: str) -> list[str]:
    """"+998 90 111 22 33, 998901112244" -> ["998901112233", "998901112244"].

    WhatsApp Cloud API raqamni faqat raqamlardan iborat, davlat kodi bilan
    kutadi ("+" va bo'shliqlar tashlanadi).
    """
    out: list[str] = []
    for part in (raw or "").replace(";", ",").split(","):
        digits = "".join(ch for ch in part if ch.isdigit())
        if len(digits) >= 9 and digits not in out:
            out.append(digits)
    return out


@dataclass(frozen=True)
class BridgeConfig:
    enabled: bool = False
    bot_token: str = ""
    channel_id: str = ""            # bo'sh — bot admin bo'lgan HAR QANDAY kanal
    phone_number_id: str = ""
    access_token: str = ""
    targets: list[str] = field(default_factory=list)
    delay_minutes: int = DEFAULT_DELAY_MINUTES
    template_name: str = ""
    template_lang: str = "uz"
    graph_version: str = "v23.0"
    tg_api_base: str = "https://api.telegram.org"

    @property
    def can_watch(self) -> bool:
        return bool(self.enabled and self.bot_token)

    @property
    def can_send(self) -> bool:
        return bool(self.enabled and self.phone_number_id and self.access_token
                    and self.targets)


async def load_config() -> BridgeConfig:
    values = await read_values(*ALL_KEYS)
    try:
        delay = int(values.get(KEY_DELAY) or DEFAULT_DELAY_MINUTES)
    except ValueError:
        delay = DEFAULT_DELAY_MINUTES
    return BridgeConfig(
        enabled=as_bool(values.get(KEY_ENABLED, ""), default=False),
        bot_token=values.get(KEY_BOT_TOKEN, "").strip(),
        channel_id=values.get(KEY_CHANNEL_ID, "").strip(),
        phone_number_id=values.get(KEY_PHONE_ID, "").strip(),
        access_token=values.get(KEY_TOKEN, "").strip(),
        targets=parse_numbers(values.get(KEY_TARGETS, "")),
        delay_minutes=max(0, delay),
        template_name=values.get(KEY_TEMPLATE, "").strip(),
        template_lang=(values.get(KEY_TEMPLATE_LANG, "").strip() or "uz"),
        graph_version=(values.get(KEY_VERSION, "").strip() or "v23.0"),
        tg_api_base=(values.get(KEY_TG_API, "").strip() or "https://api.telegram.org"),
    )
