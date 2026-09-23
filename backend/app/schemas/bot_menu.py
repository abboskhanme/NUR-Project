"""Telegram bot menyusi sxemalari."""
import re
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator

from app.models.bot_menu import MAX_TEXT_LENGTH, RESERVED_COMMANDS
from app.schemas.common import ORMBase

_COMMAND_RE = re.compile(r"^[a-z0-9_]{1,32}$")


def _normalize_command(value: str) -> str:
    """`/Narxlar` -> `narxlar`. Telegram faqat kichik lotin harf, raqam va `_` qabul qiladi."""
    cmd = (value or "").strip().lstrip("/").lower()
    if not _COMMAND_RE.fullmatch(cmd):
        raise ValueError(
            "Buyruq 1-32 belgi bo'lsin: faqat lotin kichik harf, raqam va _ "
            "(masalan: narxlar, manzil, yetkazib_berish)"
        )
    if cmd in RESERVED_COMMANDS:
        raise ValueError(f"/{cmd} buyrug'i bot uchun band — boshqa nom tanlang")
    return cmd


def tg_len(text: str) -> int:
    """Telegram matn uzunligini UTF-16 birliklarida sanaydi (emoji — 2 ta)."""
    return len(text.encode("utf-16-le")) // 2


def _check_tg_length(value: Optional[str]) -> Optional[str]:
    if value is not None and tg_len(value) > MAX_TEXT_LENGTH:
        raise ValueError(
            f"Matn Telegram chegarasidan uzun ({MAX_TEXT_LENGTH} belgi; emoji 2 belgi hisoblanadi)"
        )
    return value


def _normalize_title(value: str) -> str:
    title = (value or "").strip()
    if not title:
        raise ValueError("Tugma nomi bo'sh bo'lmasin")
    return title


class BotMenuImageOut(ORMBase):
    id: uuid.UUID
    content_type: str
    size_bytes: int
    sort_order: int = 0


class BotMenuItemOut(ORMBase):
    id: uuid.UUID
    command: str
    title: str
    text: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True
    images: list[BotMenuImageOut] = []
    created_at: datetime
    updated_at: datetime


class BotMenuItemCreate(BaseModel):
    command: str
    title: str = Field(max_length=64)
    text: Optional[str] = Field(default=None, max_length=MAX_TEXT_LENGTH)
    is_active: bool = True

    @field_validator("command")
    @classmethod
    def _cmd(cls, v: str) -> str:
        return _normalize_command(v)

    @field_validator("title")
    @classmethod
    def _title(cls, v: str) -> str:
        return _normalize_title(v)

    @field_validator("text")
    @classmethod
    def _text(cls, v: Optional[str]) -> Optional[str]:
        return _check_tg_length(v)


class BotMenuItemUpdate(BaseModel):
    command: Optional[str] = None
    title: Optional[str] = Field(default=None, max_length=64)
    text: Optional[str] = Field(default=None, max_length=MAX_TEXT_LENGTH)
    is_active: Optional[bool] = None

    @field_validator("command")
    @classmethod
    def _cmd(cls, v: Optional[str]) -> Optional[str]:
        return None if v is None else _normalize_command(v)

    @field_validator("title")
    @classmethod
    def _title(cls, v: Optional[str]) -> Optional[str]:
        return None if v is None else _normalize_title(v)

    @field_validator("text")
    @classmethod
    def _text(cls, v: Optional[str]) -> Optional[str]:
        return _check_tg_length(v)


class BotMenuOut(BaseModel):
    greeting: str = ""
    items: list[BotMenuItemOut] = []


class GreetingIn(BaseModel):
    greeting: Optional[str] = Field(default=None, max_length=MAX_TEXT_LENGTH)

    @field_validator("greeting")
    @classmethod
    def _greeting(cls, v: Optional[str]) -> Optional[str]:
        return _check_tg_length(v)


class ReorderIn(BaseModel):
    ids: list[uuid.UUID]


# --- Agent uchun (X-Agent-Key) ---
class AgentMenuImage(BaseModel):
    id: uuid.UUID
    sha256: str
    content_type: str


class AgentMenuItem(BaseModel):
    id: uuid.UUID
    command: str
    title: str
    text: str = ""
    images: list[AgentMenuImage] = []


class AgentMenuOut(BaseModel):
    greeting: str = ""
    items: list[AgentMenuItem] = []
