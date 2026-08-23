"""Kunlik Telegram hisoboti — qaysi kun uchun yig'iladi va vaqt tahlili.

Muammo: hisobot kechasi 01:00 da yuborilsa, "bugun" endigina boshlangan
bo'ladi va hisobot NOL bo'lib chiqadi. Shu sabab yarim tundan keyingi
ishga tushishlarda endigina tugagan kun olinadi.
"""
from datetime import date, datetime
from zoneinfo import ZoneInfo

import pytest

from app.integrations.telegram.bot import _parse_report_time, _report_day

TZ = ZoneInfo("Asia/Tashkent")


@pytest.mark.parametrize("raw,expected", [
    ("23:50", (23, 50)),
    ("09:05", (9, 5)),
    ("00:00", (0, 0)),
    ("", (23, 50)),           # bo'sh -> kun yakuni
    ("xato", (23, 50)),       # noto'g'ri format -> kun yakuni
    ("25:00", (23, 50)),      # mavjud bo'lmagan soat
    ("12:70", (23, 50)),      # mavjud bo'lmagan daqiqa
])
def test_parse_report_time(raw, expected):
    assert _parse_report_time(raw) == expected


@pytest.mark.parametrize("now,expected_day", [
    # Kun yakunida ishga tushsa — o'sha kunning o'zi
    (datetime(2026, 8, 22, 23, 50, tzinfo=TZ), date(2026, 8, 22)),
    (datetime(2026, 8, 22, 20, 0, tzinfo=TZ), date(2026, 8, 22)),
    (datetime(2026, 8, 22, 5, 0, tzinfo=TZ), date(2026, 8, 22)),
    # Yarim tundan keyin — endigina tugagan kun (nol hisobot bo'lmasin)
    (datetime(2026, 8, 23, 0, 5, tzinfo=TZ), date(2026, 8, 22)),
    (datetime(2026, 8, 23, 1, 0, tzinfo=TZ), date(2026, 8, 22)),
    (datetime(2026, 8, 23, 4, 59, tzinfo=TZ), date(2026, 8, 22)),
    # Oy boshida ham to'g'ri ishlashi kerak
    (datetime(2026, 9, 1, 1, 0, tzinfo=TZ), date(2026, 8, 31)),
])
def test_report_day(monkeypatch, now, expected_day):
    class FrozenDatetime(datetime):
        @classmethod
        def now(cls, tz=None):
            return now

    monkeypatch.setattr("app.integrations.telegram.bot.datetime", FrozenDatetime)
    assert _report_day() == expected_day
