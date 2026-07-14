"""Leadlar — mustaqil modul (Instagram AI agenti manbai).

"Maqsadlar"/"Bizning qarzlar" kabi boshqa bo'limlardan MUSTAQIL ishlaydi. Tashqi
`nur-agent` (alohida Docker image) Instagram kommentlari/DM'laridan qiziqqan
mijozlarni topib, `POST /api/v1/leads/ingest` orqali shu yerga yozadi. ERP xodimlari
lead'ni "quvur" (new → contacted → qualified → won/lost) bo'ylab yuritadi va
kerak bo'lsa mijoz/buyurtmaga aylantiradi.

  - Lead        — bitta potentsial mijoz (Instagram foydalanuvchisi)
  - LeadEvent   — suhbat/hodisa jurnali (har xabar+javob yoki status o'zgarishi)
"""
import uuid
from typing import Any, Optional

from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


# Ish quvuri holatlari — ro'yxat UI va validatsiya uchun bir joyda
LEAD_STATUSES = ("new", "contacted", "qualified", "won", "lost")


class Lead(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Potentsial mijoz (odatda Instagram'dan)."""

    __tablename__ = "leads"

    source: Mapped[str] = mapped_column(String(30), default="instagram", index=True)

    # Instagram identifikatorlari (manba bilan bog'lash uchun)
    ig_user_id: Mapped[Optional[str]] = mapped_column(String(64), index=True)
    ig_username: Mapped[Optional[str]] = mapped_column(String(120), index=True)
    media_id: Mapped[Optional[str]] = mapped_column(String(64))   # qaysi post/reels
    comment_id: Mapped[Optional[str]] = mapped_column(String(64))

    # AI aniqlagan mazmun
    name: Mapped[Optional[str]] = mapped_column(String(255))
    contact: Mapped[Optional[str]] = mapped_column(String(64))    # tel/username
    product_interest: Mapped[Optional[str]] = mapped_column(String(255), index=True)
    language: Mapped[Optional[str]] = mapped_column(String(10))   # uz-Cyrl/uz-Latn/ru/en
    intent: Mapped[Optional[str]] = mapped_column(String(30))
    lead_score: Mapped[int] = mapped_column(Integer, default=0, index=True)  # 0..100
    summary: Mapped[Optional[str]] = mapped_column(Text)          # AI xulosasi (o'zbekcha)

    # Ish quvuri (ERP xodimlari boshqaradi)
    status: Mapped[str] = mapped_column(String(20), default="new", index=True)
    assigned_to_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    note: Mapped[Optional[str]] = mapped_column(Text)  # xodim izohi

    # Konversiya izlari — leaddan mijoz/buyurtma yaratilganda to'ladi
    customer_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("customers.id", ondelete="SET NULL")
    )
    order_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="SET NULL")
    )

    extra: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="{}")

    events: Mapped[list["LeadEvent"]] = relationship(
        back_populates="lead",
        cascade="all, delete-orphan",
        passive_deletes=True,
        order_by="LeadEvent.created_at",
    )


class LeadEvent(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Lead bilan bog'liq bitta hodisa — suhbat xabari yoki status o'zgarishi."""

    __tablename__ = "lead_events"

    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("leads.id", ondelete="CASCADE"), index=True
    )
    kind: Mapped[str] = mapped_column(String(20))  # comment / dm / reply / status / note
    message_text: Mapped[Optional[str]] = mapped_column(Text)   # mijoz yozgani
    agent_reply: Mapped[Optional[str]] = mapped_column(Text)    # agent javobi
    actor: Mapped[str] = mapped_column(String(20), default="agent")  # agent / user
    meta: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="{}")

    lead: Mapped["Lead"] = relationship(back_populates="events")
