"""User, Role, Permissions."""
import uuid
from typing import Any, Optional

from sqlalchemy import Boolean, ForeignKey, Integer, LargeBinary, String, Table, Column
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


# Many-to-many: User <-> Role
UserRole = Table(
    "user_roles",
    Base.metadata,
    Column("user_id", UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("role_id", UUID(as_uuid=True), ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
)


class Role(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "roles"

    name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(255))
    # Granular permissions: {"sales": {"read": true, "write": true}, ...}
    permissions: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="{}")

    users: Mapped[list["User"]] = relationship(secondary=UserRole, back_populates="roles")


class User(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "users"

    # Telefon raqam login identifikatori sifatida ishlatiladi (email o'rniga)
    phone: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    avatar_url: Mapped[Optional[str]] = mapped_column(String(500))
    position: Mapped[Optional[str]] = mapped_column(String(100))

    # Preferences
    locale: Mapped[str] = mapped_column(String(5), default="uz")
    theme: Mapped[str] = mapped_column(String(10), default="light")  # light/dark/auto

    # Status
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    is_superadmin: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")

    # Telegram
    telegram_chat_id: Mapped[Optional[str]] = mapped_column(String(50))

    # Notification preferences
    notification_settings: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="{}")

    roles: Mapped[list[Role]] = relationship(secondary=UserRole, back_populates="users", lazy="selectin")
    avatar: Mapped[Optional["UserAvatar"]] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan",
    )


class UserAvatar(TimestampMixin, Base):
    """User profil rasmini PostgreSQL BYTEA sifatida saqlaydi."""
    __tablename__ = "user_avatars"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    content_type: Mapped[str] = mapped_column(String(64), nullable=False)
    size_bytes: Mapped[int] = mapped_column(Integer, nullable=False)
    data: Mapped[bytes] = mapped_column(LargeBinary, nullable=False)

    user: Mapped["User"] = relationship(back_populates="avatar")
