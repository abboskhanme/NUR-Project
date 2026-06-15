"""Service tickets and visits (warranty)."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


SERVICE_STATUSES = ("new", "scheduled", "completed", "cancelled")


class ServiceTicket(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "service_tickets"

    code: Mapped[str] = mapped_column(String(30), unique=True, index=True)
    order_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="SET NULL"), index=True
    )
    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("customers.id", ondelete="RESTRICT"), index=True
    )
    serial_id: Mapped[Optional[str]] = mapped_column(String(50))
    address: Mapped[Optional[str]] = mapped_column(Text)
    problem: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[Optional[str]] = mapped_column(String(50))
    # Ishlatilgan ehtiyot qismlar nomlari (servisdan kelgach tanlanadi)
    parts_used: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")

    opened_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    closed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    status: Mapped[str] = mapped_column(String(20), default="new", index=True)
    in_warranty: Mapped[bool] = mapped_column(Boolean, default=False)
    resolution: Mapped[Optional[str]] = mapped_column(Text)
    client_cost: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)

    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    # Servis safari (yakunlanganda bog'lanadi) — yaxlit yozuv uchun
    trip_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("service_trips.id", ondelete="SET NULL"), index=True
    )

    visits: Mapped[list["ServiceVisit"]] = relationship(
        back_populates="ticket", cascade="all, delete-orphan", lazy="selectin"
    )
    customer: Mapped[Optional["Customer"]] = relationship(  # noqa: F821
        "Customer", lazy="selectin", viewonly=True
    )
    order: Mapped[Optional["Order"]] = relationship(  # noqa: F821
        "Order", lazy="selectin", viewonly=True
    )


class ServiceVisit(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "service_visits"

    ticket_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("service_tickets.id", ondelete="CASCADE"), index=True
    )
    planned_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    travel_cost: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    note: Mapped[Optional[str]] = mapped_column(Text)

    ticket: Mapped[ServiceTicket] = relationship(back_populates="visits")


class ServiceCategory(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Servis muammolari toifalari — ariza yaratishda dropdownda ishlatiladi."""
    __tablename__ = "service_categories"

    name: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class ServicePart(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Servis ehtiyot qismlari katalogi (timer, nasos, motor, ...)."""
    __tablename__ = "service_parts"

    name: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class ServiceTrip(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Servis safari — barcha rejalashtirilgan arizalar bitta safar hisoblanadi.
    Uchta umumiy summa qo'lda kiritiladi (moliyaga bog'lanmaydi):
      collected  — olingan pul (servisga ketishdan oldin)
      spent      — sarflangan pul (qaytib kelgandan keyin)
      total_cost — umumiy servis safari harajati
    """
    __tablename__ = "service_trips"

    name: Mapped[Optional[str]] = mapped_column(String(120))
    status: Mapped[str] = mapped_column(String(20), default="open", index=True)  # open / closed
    collected: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    spent: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    total_cost: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    note: Mapped[Optional[str]] = mapped_column(Text)
    ticket_count: Mapped[int] = mapped_column(default=0)
    opened_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    closed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
