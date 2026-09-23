"""Telegram AI botining menyusi — mijoz tugma/buyruq tanlasa tayyor javob.

Masalan mijoz «💰 Narxlar» tugmasini bosadi yoki `/narxlar` yozadi — bot AI'ga
murojaat qilmasdan shu bo'limning matni va rasmlarini darhol yuboradi.
Bo'limlar ERP'da (Bot menyusi sahifasi) boshqariladi, agent ularni
`/bot-menu/agent` orqali oladi.

Rasmlar BYTEA sifatida saqlanadi (ProductImage bilan bir xil naqsh). Agent
ularni Telegram'ga bir marta yuklaydi va `file_id` ni `sha256` bo'yicha
keshlaydi — shuning uchun rasm almashsa xesh ham o'zgaradi va kesh eskirmaydi.
"""
import uuid
from typing import Optional

from sqlalchemy import Boolean, ForeignKey, Integer, LargeBinary, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

# Telegram albomi (sendMediaGroup) 10 tadan ortiq rasm qabul qilmaydi
MAX_IMAGES_PER_ITEM = 10
MAX_IMAGE_BYTES = 5 * 1024 * 1024
ALLOWED_IMAGE_TYPES = frozenset({"image/jpeg", "image/png", "image/webp"})
# Telegram xabar matni chegarasi
MAX_TEXT_LENGTH = 4096
# Bular bot o'zi ishlatadigan buyruqlar — bo'lim nomi sifatida band qilib bo'lmaydi
RESERVED_COMMANDS = frozenset({"start", "menu"})
# Salomlashish matni `system_settings` jadvalida shu kalit bilan saqlanadi
GREETING_KEY = "TG_MENU_GREETING"


class BotMenuItem(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "bot_menu_items"
    __table_args__ = (UniqueConstraint("command", name="uq_bot_menu_items_command"),)

    # Telegram buyrug'i: `/narxlar` -> "narxlar" (1-32 belgi, a-z 0-9 _)
    command: Mapped[str] = mapped_column(String(32), nullable=False)
    # Tugma matni (masalan «💰 Narxlar») — buyruqlar ro'yxatida tavsif ham shu
    title: Mapped[str] = mapped_column(String(64), nullable=False)
    text: Mapped[Optional[str]] = mapped_column(Text)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")

    images: Mapped[list["BotMenuImage"]] = relationship(
        back_populates="item",
        cascade="all, delete-orphan",
        order_by="BotMenuImage.sort_order",
        lazy="selectin",
    )


class BotMenuImage(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "bot_menu_images"

    item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("bot_menu_items.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    content_type: Mapped[str] = mapped_column(String(64), nullable=False)
    size_bytes: Mapped[int] = mapped_column(Integer, nullable=False)
    sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    # Ro'yxat so'rovlarida og'ir bayt-ma'lumot yuklanmasin
    data: Mapped[bytes] = mapped_column(LargeBinary, nullable=False, deferred=True)

    item: Mapped[BotMenuItem] = relationship(back_populates="images")
