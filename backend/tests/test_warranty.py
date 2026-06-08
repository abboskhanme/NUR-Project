"""Kafolat hisoblash logikasi uchun unit testlar — DB kerak emas."""
from datetime import date, timedelta
from types import SimpleNamespace

from app.services.warranty_service import calculate_warranty


def _order(delivered_at):
    return SimpleNamespace(delivered_at=delivered_at)


def test_not_delivered():
    result = calculate_warranty(_order(None))
    assert result["current_status"] == "not_delivered"
    assert result["warranty_start"] is None


def test_active_full_within_year_one():
    delivered = date.today() - timedelta(days=30)
    result = calculate_warranty(_order(delivered))
    assert result["current_status"] == "active_full"
    assert result["days_remaining_year1"] > 0
    assert result["year1_end"] == delivered + timedelta(days=365)


def test_active_service_only_year_two():
    delivered = date.today() - timedelta(days=400)  # > 1 yil, < 3 yil
    result = calculate_warranty(_order(delivered))
    assert result["current_status"] == "active_service_only"
    assert result["days_remaining_year1"] == 0
    assert result["days_remaining_year3"] > 0


def test_expired_after_three_years():
    delivered = date.today() - timedelta(days=365 * 3 + 10)
    result = calculate_warranty(_order(delivered))
    assert result["current_status"] == "expired"
    assert result["days_remaining_year3"] == 0
