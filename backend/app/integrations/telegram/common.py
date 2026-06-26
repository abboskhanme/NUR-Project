"""Bot uchun umumiy yordamchilar: vaqt mintaqasi, formatlash, doimiylar."""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from zoneinfo import ZoneInfo

from app.core.config import settings

# --- Katalog (mijoz tanlovi) -------------------------------------------------
# Bunker modellari va kvadraturalar — Product katalogidagi qiymatlarga mos.
MODELS = ["PREMIUM 3", "PREMIUM 4", "ULTRA", "MAGNUM", "OPTIMA"]
KVMS = ["150", "200", "300", "400", "500"]
# Foydalanuvchiga ko'rinadigan yo'nalish -> bazadagi kod (right/left).
DIRECTIONS = {"O'NGA": "right", "CHAPGA": "left"}


def tz() -> ZoneInfo:
    """Sozlamadagi vaqt mintaqasi (xato bo'lsa Asia/Tashkent)."""
    try:
        return ZoneInfo(settings.TIMEZONE)
    except Exception:
        return ZoneInfo("Asia/Tashkent")


def today() -> date:
    """TIMEZONE bo'yicha 'bugun' sanasi."""
    return datetime.now(tz()).date()


def fmt_uzs(value) -> str:
    """123456 -> '123 456 so'm' (probel bilan ajratilgan)."""
    try:
        n = int(round(float(value or 0)))
    except (TypeError, ValueError):
        n = 0
    return f"{n:,}".replace(",", " ") + " so'm"


def fmt_usd(value) -> str:
    try:
        n = float(value or 0)
    except (TypeError, ValueError):
        n = 0.0
    return f"${n:,.0f}".replace(",", " ")


def to_decimal(text: str) -> Decimal | None:
    """Foydalanuvchi kiritgan narxni Decimal'ga aylantiradi (probel/vergulga toza)."""
    if text is None:
        return None
    cleaned = (
        text.strip()
        .replace(" ", "")
        .replace("$", "")
        .replace(",", ".")
    )
    try:
        val = Decimal(cleaned)
    except Exception:
        return None
    return val if val >= 0 else None


def normalize_phone(text: str) -> str:
    """Telefon raqamini taqqoslash uchun normallashtiradi (faqat raqamlar)."""
    if not text:
        return ""
    return (
        text.replace(" ", "")
        .replace("-", "")
        .replace("+", "")
        .replace("(", "")
        .replace(")", "")
    )
