"""System: notifications, audit log, files, telegram orders, monthly goals."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Notification(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "notifications"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    channel: Mapped[str] = mapped_column(String(20), default="in_app")  # in_app/email/sms/telegram
    type: Mapped[str] = mapped_column(String(50))  # new_order/warranty_expiring/...
    title: Mapped[str] = mapped_column(String(255))
    body: Mapped[Optional[str]] = mapped_column(Text)
    payload: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="{}")
    read_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


class AuditLog(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "audit_logs"

    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), index=True
    )
    entity: Mapped[str] = mapped_column(String(50), index=True)
    entity_id: Mapped[Optional[str]] = mapped_column(String(100), index=True)
    action: Mapped[str] = mapped_column(String(50))  # create/update/delete/login/logout
    before: Mapped[Optional[dict[str, Any]]] = mapped_column(JSONB)
    after: Mapped[Optional[dict[str, Any]]] = mapped_column(JSONB)
    ip: Mapped[Optional[str]] = mapped_column(String(45))
    user_agent: Mapped[Optional[str]] = mapped_column(String(500))


class FileRecord(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "files"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    mime: Mapped[Optional[str]] = mapped_column(String(100))
    size: Mapped[int] = mapped_column(Integer, default=0)
    storage_key: Mapped[str] = mapped_column(String(500), nullable=False)
    uploaded_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class MonthlyGoal(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Oylik maqsad — sotuv soni va tushum (UZS) bo'yicha.

    Har oy uchun bitta yozuv (period_month — oyning 1-kuni, unikal). Bosh
    sahifada hammaga ko'rinadi, lekin faqat `system:goals_manage` ruxsatli
    foydalanuvchi belgilaydi/o'zgartiradi.
    """
    __tablename__ = "monthly_goals"

    period_month: Mapped[date] = mapped_column(Date, unique=True, index=True)
    target_orders: Mapped[Optional[int]] = mapped_column(Integer)
    target_revenue_uzs: Mapped[Optional[Decimal]] = mapped_column(Numeric(18, 2))
    set_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class TelegramOrder(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "telegram_orders"

    telegram_chat_id: Mapped[str] = mapped_column(String(50), index=True)
    telegram_message_id: Mapped[Optional[str]] = mapped_column(String(50))
    raw_data: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="{}")
    order_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="SET NULL")
    )
    processed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
