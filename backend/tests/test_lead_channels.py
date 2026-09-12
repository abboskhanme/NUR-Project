"""Lead kanallari — Instagram / Telegram / WhatsApp yo'naltirishi.

Sof unit testlar (DB va tarmoq kerak emas). Eng muhimi: lead qaysi kanalga
tegishli ekanini to'g'ri aniqlash — noto'g'ri aniqlansa operator javobi
boshqa platformaga ketadi yoki umuman ketmaydi.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest

from app.api.v1.leads import (
    CHANNELS, _channel_of, _channel_username, _columns_for, _user_key, _window_for,
)


def _lead(**kwargs):
    base = dict(ig_user_id=None, ig_username=None, tg_user_id=None,
                tg_username=None, wa_user_id=None, wa_username=None)
    base.update(kwargs)
    return SimpleNamespace(**base)


# --------------------------------------------------------------------------- #
# Kanalni aniqlash
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize("lead,expected", [
    (_lead(ig_user_id="178414158"), "instagram"),
    (_lead(tg_user_id="424242"), "telegram"),
    (_lead(wa_user_id="998901112233"), "whatsapp"),
    (_lead(), "instagram"),                                  # hech narsa yo'q
])
def test_channel_of(lead, expected):
    assert _channel_of(lead) == expected


def test_whatsapp_lead_is_not_mistaken_for_instagram():
    """Eski leadlarda ig_user_id bo'lishi mumkin — WhatsApp ustuni ustun emas."""
    lead = _lead(wa_user_id="998901112233")
    assert _channel_of(lead) == "whatsapp"
    assert _user_key(lead) == "wa:998901112233"


def test_user_key_per_channel():
    assert _user_key(_lead(ig_user_id="178414158")) == "178414158"
    assert _user_key(_lead(tg_user_id="424242")) == "tg:424242"
    assert _user_key(_lead(wa_user_id="998901112233")) == "wa:998901112233"
    assert _user_key(_lead()) == ""


def test_channel_username():
    assert _channel_username(_lead(wa_user_id="9989", wa_username="Ali")) == "Ali"
    assert _channel_username(_lead(tg_user_id="1", tg_username="ali_tg")) == "ali_tg"
    assert _channel_username(_lead(ig_user_id="1", ig_username="ali_ig")) == "ali_ig"


def test_columns_for_unknown_channel_falls_back_to_instagram():
    assert _columns_for("boshqa") == ("ig_user_id", "ig_username")
    assert _columns_for("whatsapp") == ("wa_user_id", "wa_username")


def test_whatsapp_is_a_known_channel():
    assert "whatsapp" in CHANNELS


# --------------------------------------------------------------------------- #
# Javob oynasi
# --------------------------------------------------------------------------- #
def _ago(**kwargs) -> datetime:
    return datetime.now(timezone.utc) - timedelta(**kwargs)


def test_telegram_window_is_always_open():
    assert _window_for("telegram", None) == "open"
    assert _window_for("telegram", _ago(days=30)) == "open"


def test_whatsapp_window_closes_after_24h():
    """WhatsAppda 24 soatdan keyin erkin matn yuborib bo'lmaydi (faqat shablon)."""
    assert _window_for("whatsapp", _ago(hours=2)) == "open"
    assert _window_for("whatsapp", _ago(hours=25)) == "closed"
    assert _window_for("whatsapp", None) == "closed"
    # Instagramdagi 7 kunlik "operator" bosqichi WhatsAppda YO'Q
    assert _window_for("whatsapp", _ago(days=3)) == "closed"


def test_instagram_window_keeps_human_agent_stage():
    assert _window_for("instagram", _ago(hours=2)) == "open"
    assert _window_for("instagram", _ago(days=3)) == "human_agent"
    assert _window_for("instagram", _ago(days=8)) == "closed"
