"""config.validate_security() uchun unit testlar — DB kerak emas."""
import pytest

from app.core.config import Settings


def _settings(**over):
    base = dict(
        APP_ENV="production",
        DEBUG=False,
        SECRET_KEY="x" * 40,
        ALLOWED_ORIGINS_STR="https://app.example.com",
        INIT_ADMIN_PASSWORD="Str0ng#Changed",
    )
    base.update(over)
    return Settings(**base)


def test_production_with_good_config_passes():
    assert _settings().validate_security() == []


def test_production_rejects_weak_secret():
    with pytest.raises(RuntimeError):
        _settings(SECRET_KEY="change-me")


def test_production_rejects_short_secret():
    with pytest.raises(RuntimeError):
        _settings(SECRET_KEY="short")


def test_production_rejects_debug_true():
    with pytest.raises(RuntimeError):
        _settings(DEBUG=True)


def test_production_rejects_wildcard_cors():
    with pytest.raises(RuntimeError):
        _settings(ALLOWED_ORIGINS_STR="*")


def test_production_rejects_default_admin_password():
    with pytest.raises(RuntimeError):
        _settings(INIT_ADMIN_PASSWORD="Admin@12345")


def test_development_only_warns():
    # development'da xato ko'tarilmaydi, faqat ogohlantirish ro'yxati qaytadi
    s = Settings(APP_ENV="development", DEBUG=True, SECRET_KEY="change-me")
    warnings = s.validate_security()
    assert any("SECRET_KEY" in w for w in warnings)
