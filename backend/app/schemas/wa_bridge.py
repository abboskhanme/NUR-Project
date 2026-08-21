"""Telegram → WhatsApp navbati sxemalari."""
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class ChannelPostOut(ORMBase):
    id: uuid.UUID
    tg_chat_id: str
    tg_message_id: str
    kind: str                       # text | photo | video | document
    caption: Optional[str] = None
    media_mime: Optional[str] = None
    media_size: int = 0
    has_media: bool = False
    posted_at: datetime
    planned_at: datetime
    status: str
    attempts: int = 0
    error: Optional[str] = None
    sent_at: Optional[datetime] = None
    sent_to: Optional[str] = None


class BridgeSummary(BaseModel):
    """Navbat holati + sozlamalar tayyorligi (UI'da ogohlantirish uchun)."""

    pending: int = 0
    sent: int = 0
    posted: int = 0
    failed: int = 0
    skipped: int = 0
    enabled: bool = False
    watching: bool = False          # Telegram boti sozlanganmi
    sending: bool = False           # WhatsApp sozlanganmi
    targets: int = 0
    delay_minutes: int = 60
