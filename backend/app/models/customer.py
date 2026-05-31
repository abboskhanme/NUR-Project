"""Customer model."""
import uuid
from typing import Optional

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Customer(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "customers"

    full_name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    phone: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    phone2: Mapped[Optional[str]] = mapped_column(String(30))

    country: Mapped[str] = mapped_column(String(50), default="Uzbekistan")
    region: Mapped[Optional[str]] = mapped_column(String(100))  # Viloyat
    city: Mapped[Optional[str]] = mapped_column(String(100))    # Shahar/tuman
    address: Mapped[Optional[str]] = mapped_column(Text)

    source: Mapped[Optional[str]] = mapped_column(String(50))   # manual, telegram_bot, import
    note: Mapped[Optional[str]] = mapped_column(Text)

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
