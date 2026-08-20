"""Warranty calculation utilities."""
from datetime import date, timedelta
from typing import Optional

from app.models.order import Order


def warranty_from_date(start: Optional[date]) -> dict:
    """Kafolat holati — boshlanish sanasi bo'yicha.

    1-yil (to'liq): ish + ehtiyot qism bepul.
    2-3-yil (faqat ish): ish bepul, ehtiyot qism mijoz hisobidan.

    Sana bo'lmasa "not_delivered" (buyurtmada — yetkazilmagan, "0 dan"
    arizada — sotib olingan sana ko'rsatilmagan).
    """
    if not start:
        return {
            "warranty_start": None,
            "year1_end": None,
            "year3_end": None,
            "days_remaining_year1": None,
            "days_remaining_year3": None,
            "current_status": "not_delivered",
        }

    year1_end = start + timedelta(days=365)
    year3_end = start + timedelta(days=365 * 3)
    today = date.today()

    days_y1 = (year1_end - today).days
    days_y3 = (year3_end - today).days

    if days_y1 > 0:
        status = "active_full"
    elif days_y3 > 0:
        status = "active_service_only"
    else:
        status = "expired"

    return {
        "warranty_start": start,
        "year1_end": year1_end,
        "year3_end": year3_end,
        "days_remaining_year1": max(0, days_y1),
        "days_remaining_year3": max(0, days_y3),
        "current_status": status,
    }


def calculate_warranty(order: Order) -> dict:
    """Return warranty info for an order (yetkazilgan sanadan hisoblanadi)."""
    return warranty_from_date(order.delivered_at)
