"""Telegram → WhatsApp ko'prigi — sof unit testlar (DB va tarmoq kerak emas).

Eng muhim jihatlar: raqamlarni tozalash, Telegram postidan media ajratish,
WhatsApp javob oynasi xatosini tanish va fayl hajmi cheklovlari.
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone

import pytest

from app.integrations.wa_bridge.config import BridgeConfig, parse_numbers
from app.integrations.wa_bridge.sender import _deliver
from app.integrations.wa_bridge.telegram_source import extract_media
from app.integrations.whatsapp.client import (
    MAX_IMAGE_BYTES, SendResult, _parse_error, size_limit_for,
)
from app.models.wa_bridge import ChannelPost


# --------------------------------------------------------------------------- #
# Raqamlar
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize("raw,expected", [
    ("+998 90 111 22 33", ["998901112233"]),
    ("998901112233, +998901112244", ["998901112233", "998901112244"]),
    ("+998901112233; 998901112233", ["998901112233"]),      # dublikat tashlanadi
    ("", []),
    ("12345", []),                                          # juda qisqa
])
def test_parse_numbers(raw, expected):
    assert parse_numbers(raw) == expected


# --------------------------------------------------------------------------- #
# Telegram postidan media ajratish
# --------------------------------------------------------------------------- #
def test_extract_photo_takes_largest_size():
    kind, media = extract_media({"photo": [
        {"file_id": "small", "file_size": 1000},
        {"file_id": "big", "file_size": 90000},
    ]})
    assert kind == "photo" and media["file_id"] == "big"
    assert media["mime"] == "image/jpeg"


def test_extract_video_and_document():
    kind, media = extract_media({"video": {"file_id": "v1", "file_size": 5, "mime_type": "video/mp4"}})
    assert kind == "video" and media["file_id"] == "v1"

    kind, media = extract_media({"document": {"file_id": "d1", "file_name": "narx.pdf",
                                              "mime_type": "application/pdf"}})
    assert kind == "document" and media["name"] == "narx.pdf"


def test_extract_text_only():
    kind, media = extract_media({"text": "Salom"})
    assert kind == "text" and media is None


def test_animation_treated_as_video():
    kind, _ = extract_media({"animation": {"file_id": "a1"}})
    assert kind == "video"


# --------------------------------------------------------------------------- #
# WhatsApp xatolarini o'qish
# --------------------------------------------------------------------------- #
def test_window_error_is_recognized():
    _, closed = _parse_error({"error": {
        "code": 131047,
        "message": "Message failed to send because more than 24 hours have passed",
    }})
    assert closed is True


def test_other_error_is_not_window():
    message, closed = _parse_error({"error": {"code": 100, "message": "Invalid parameter"}})
    assert closed is False and "Invalid parameter" in message


def test_size_limits():
    assert size_limit_for("photo") == MAX_IMAGE_BYTES
    assert size_limit_for("video") > size_limit_for("photo")


# --------------------------------------------------------------------------- #
# Yuborish mantig'i (soxta klient bilan)
# --------------------------------------------------------------------------- #
class FakeClient:
    """WhatsApp klientining soxta o'rnini bosuvchi."""

    def __init__(self, *, send=True, window_closed=False, upload_ok=True):
        self.send_ok, self.window_closed, self.upload_ok = send, window_closed, upload_ok
        self.sent: list[tuple[str, str]] = []
        self.templates: list[str] = []
        self.uploads = 0

    async def upload_media(self, data, *, mime, filename):
        self.uploads += 1
        return ("media_1", "") if self.upload_ok else ("", "Yuklanmadi")

    async def send_media(self, to, *, kind, media_id, caption=""):
        self.sent.append((to, caption))
        return SendResult(sent=self.send_ok, error="" if self.send_ok else "Xato",
                          window_closed=self.window_closed)

    async def send_text(self, to, text):
        self.sent.append((to, text))
        return SendResult(sent=self.send_ok, error="" if self.send_ok else "Xato",
                          window_closed=self.window_closed)

    async def send_template(self, to):
        self.templates.append(to)
        return SendResult(sent=True)


def _post(kind="photo", media=b"x" * 100) -> ChannelPost:
    now = datetime.now(timezone.utc)
    return ChannelPost(
        tg_chat_id="-100", tg_message_id="1", posted_at=now, planned_at=now,
        kind=kind, caption="Yangi post", media=media, media_mime="image/jpeg",
        media_name="post.jpg", media_size=len(media or b""), status="pending",
    )


def _cfg(**kw) -> BridgeConfig:
    base = dict(enabled=True, phone_number_id="1", access_token="t",
                targets=["998901112233", "998901112244"], template_name="tpl")
    base.update(kw)
    return BridgeConfig(**base)


def test_media_sent_to_every_target():
    client = FakeClient()
    delivered, error, closed, fatal = asyncio.run(_deliver(client, _cfg(), _post()))
    assert delivered == ["998901112233", "998901112244"], delivered
    assert not error and not closed and not fatal
    assert client.uploads == 1, "media bir marta yuklanadi, keyin qayta ishlatiladi"
    assert [c for _, c in client.sent] == ["Yangi post", "Yangi post"]


def test_text_post_sent_without_upload():
    client = FakeClient()
    delivered, _, _, _ = asyncio.run(_deliver(client, _cfg(), _post(kind="text", media=None)))
    assert len(delivered) == 2 and client.uploads == 0


def test_oversized_file_is_fatal():
    client = FakeClient()
    big = b"x" * (MAX_IMAGE_BYTES + 1)
    delivered, error, closed, fatal = asyncio.run(_deliver(client, _cfg(), _post(media=big)))
    assert delivered == [] and fatal is True
    assert "MB" in error and client.uploads == 0


def test_window_closed_is_reported():
    client = FakeClient(send=False, window_closed=True)
    delivered, error, closed, fatal = asyncio.run(_deliver(client, _cfg(), _post()))
    assert delivered == [] and closed is True and fatal is False


def test_upload_failure_is_retryable():
    client = FakeClient(upload_ok=False)
    delivered, error, closed, fatal = asyncio.run(_deliver(client, _cfg(), _post()))
    assert delivered == [] and fatal is False and "Yuklanmadi" in error


# --------------------------------------------------------------------------- #
# Konfiguratsiya tayyorligi
# --------------------------------------------------------------------------- #
def test_config_readiness_flags():
    assert BridgeConfig().can_watch is False
    assert BridgeConfig(enabled=True, bot_token="t").can_watch is True
    # WhatsApp yuborish uchun raqamlar ham kerak
    assert BridgeConfig(enabled=True, phone_number_id="1", access_token="t").can_send is False
    assert _cfg().can_send is True
