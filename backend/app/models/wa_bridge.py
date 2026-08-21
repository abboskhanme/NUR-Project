"""Telegram kanal posti → WhatsApp kanaliga ko'chirish navbati.

Nima uchun navbat: WhatsApp Kanallariga to'g'ridan-to'g'ri yozadigan RASMIY API
yo'q. Shuning uchun tizim postni belgilangan vaqtdan keyin kanal admini bo'lgan
xodimning shaxsiy WhatsApp raqamiga yuboradi — xodim uni bir marta "Forward"
qilib kanalga qo'yadi.

Media BYTEA sifatida saqlanadi (ProductImage/UserAvatar bilan bir xil naqsh):
navbatda odatda bir necha post turadi va yuborilgach bayt-ma'lumot o'chiriladi,
shuning uchun alohida disk/volume kerak emas.
"""
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Integer, LargeBinary, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

# pending — vaqti kutilmoqda / yuborilmagan
# sent    — xodim WhatsApp'iga yuborildi (kanalga qo'yish uning zimmasida)
# posted  — xodim "kanalga qo'ydim" deb belgiladi
# failed  — bir necha urinishdan keyin ham yuborilmadi
# skipped — o'tkazib yuborildi (juda katta fayl yoki qo'lda bekor qilingan)
POST_STATUSES = ("pending", "sent", "posted", "failed", "skipped")


class ChannelPost(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "channel_posts"
    __table_args__ = (
        UniqueConstraint("tg_chat_id", "tg_message_id", name="uq_channel_post_msg"),
    )

    # --- Manba (Telegram kanali) ---
    tg_chat_id: Mapped[str] = mapped_column(String(64), index=True)
    tg_message_id: Mapped[str] = mapped_column(String(32))
    media_group_id: Mapped[Optional[str]] = mapped_column(String(64))  # albom
    posted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    # --- Mazmun ---
    kind: Mapped[str] = mapped_column(String(20), default="text")  # text|photo|video|document
    caption: Mapped[Optional[str]] = mapped_column(Text)
    media: Mapped[Optional[bytes]] = mapped_column(LargeBinary)
    media_mime: Mapped[Optional[str]] = mapped_column(String(80))
    media_name: Mapped[Optional[str]] = mapped_column(String(160))
    media_size: Mapped[int] = mapped_column(Integer, default=0)

    # --- Navbat holati ---
    planned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    status: Mapped[str] = mapped_column(String(20), default="pending", index=True)
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    error: Mapped[Optional[str]] = mapped_column(Text)
    sent_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    sent_to: Mapped[Optional[str]] = mapped_column(String(255))
