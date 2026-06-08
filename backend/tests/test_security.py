"""JWT token va telefon normalizatsiyasi uchun unit testlar — DB kerak emas."""
import pytest

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    normalize_phone,
    phone_digits,
    verify_password,
)


def test_access_token_round_trip():
    token = create_access_token("user-123", version=2)
    data = decode_token(token)
    assert data["sub"] == "user-123"
    assert data["type"] == "access"
    assert data["ver"] == 2


def test_refresh_token_carries_version_and_type():
    token = create_refresh_token("u1", version=5)
    data = decode_token(token)
    assert data["type"] == "refresh"
    assert data["ver"] == 5


def test_access_token_default_version_zero():
    data = decode_token(create_access_token("u1"))
    assert data["ver"] == 0


def test_decode_invalid_token_raises_generic():
    with pytest.raises(ValueError) as exc:
        decode_token("not-a-real-token")
    # Kutubxona tafsilotlari sizib chiqmasligi kerak
    assert str(exc.value) == "Invalid token"


def test_password_hash_and_verify():
    hashed = hash_password("S3cret!pass")
    assert hashed != "S3cret!pass"
    assert verify_password("S3cret!pass", hashed)
    assert not verify_password("wrong", hashed)


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("+998 90 123 45 67", "998901234567"),
        ("998901234567", "998901234567"),
        ("(998) 90-123-45-67", "998901234567"),
        (None, ""),
        ("", ""),
    ],
)
def test_phone_digits(raw, expected):
    assert phone_digits(raw) == expected


def test_normalize_phone_adds_plus():
    assert normalize_phone("998 90 123 45 67") == "+998901234567"
    assert normalize_phone("") == ""
    assert normalize_phone(None) == ""
