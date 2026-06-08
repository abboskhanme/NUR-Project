"""Security utilities: JWT, password hashing, telefon normalizatsiyasi."""
import re
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def phone_digits(raw: str | None) -> str:
    """Telefon raqamdan faqat raqamlarni qaytaradi (format/bo'shliqni e'tiborsiz qoldiradi)."""
    return re.sub(r"\D", "", raw or "")


def normalize_phone(raw: str | None) -> str:
    """Kanonik login formati: '+' + raqamlar (masalan '+998 90 123 45 67' -> '+998901234567').
    Bo'sh bo'lsa bo'sh satr qaytaradi."""
    d = phone_digits(raw)
    return f"+{d}" if d else ""


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(
    subject: str | int, version: int = 0, extra: Optional[dict] = None
) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload: dict[str, Any] = {
        "sub": str(subject), "exp": expire, "type": "access", "ver": version,
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(subject: str | int, version: int = 0) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    payload = {"sub": str(subject), "exp": expire, "type": "refresh", "ver": version}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError as e:
        # Tashqariga JWT kutubxonasi tafsilotlarini chiqarmaymiz
        raise ValueError("Invalid token") from e
