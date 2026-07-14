"""Leadlar — Pydantic sxemalar."""
import uuid
from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase


# ---------------------------------------------------------------------------
# Agent → ERP: ingest (X-Agent-Key bilan)
# ---------------------------------------------------------------------------
class LeadIngest(BaseModel):
    """Tashqi agent yuboradigan lead. Barcha maydonlar ixtiyoriy (AI to'ldiradi)."""

    source: str = "instagram"
    ig_user_id: Optional[str] = None
    ig_username: Optional[str] = None
    media_id: Optional[str] = None
    comment_id: Optional[str] = None

    name: Optional[str] = None
    contact: Optional[str] = None
    product_interest: Optional[str] = None
    language: Optional[str] = None
    intent: Optional[str] = None
    lead_score: int = 0
    summary: Optional[str] = None

    # Suhbatning shu qadamidagi xabar/javob — LeadEvent sifatida saqlanadi
    message_text: Optional[str] = None
    agent_reply: Optional[str] = None
    extra: dict[str, Any] = Field(default_factory=dict)


class LeadIngestResult(BaseModel):
    id: uuid.UUID
    status: str
    duplicate: bool = False  # mavjud lead'ga ulanган-yo'qligi


# ---------------------------------------------------------------------------
# Xodim uchun: yangilash (status/assign/note)
# ---------------------------------------------------------------------------
class LeadUpdate(BaseModel):
    status: Optional[str] = None
    assigned_to_id: Optional[uuid.UUID] = None
    note: Optional[str] = None
    lead_score: Optional[int] = Field(default=None, ge=0, le=100)


class LeadConvert(BaseModel):
    """Leaddan mijoz yaratish uchun (yetishmayotgan maydonlarni to'ldirish)."""

    full_name: Optional[str] = None
    phone: Optional[str] = None
    region: Optional[str] = None
    note: Optional[str] = None


# ---------------------------------------------------------------------------
# Chiqish sxemalari
# ---------------------------------------------------------------------------
class LeadEventOut(ORMBase):
    id: uuid.UUID
    kind: str
    message_text: Optional[str] = None
    agent_reply: Optional[str] = None
    actor: str
    created_at: datetime


class LeadOut(ORMBase):
    id: uuid.UUID
    source: str
    ig_user_id: Optional[str] = None
    ig_username: Optional[str] = None
    media_id: Optional[str] = None
    comment_id: Optional[str] = None
    name: Optional[str] = None
    contact: Optional[str] = None
    product_interest: Optional[str] = None
    language: Optional[str] = None
    intent: Optional[str] = None
    lead_score: int = 0
    summary: Optional[str] = None
    status: str
    assigned_to_id: Optional[uuid.UUID] = None
    assigned_to_name: Optional[str] = None
    note: Optional[str] = None
    customer_id: Optional[uuid.UUID] = None
    order_id: Optional[uuid.UUID] = None
    created_at: datetime
    updated_at: datetime
    event_count: int = 0


class LeadDetailOut(LeadOut):
    events: list[LeadEventOut] = []


# ---------------------------------------------------------------------------
# Analitika
# ---------------------------------------------------------------------------
class LeadStatusCount(BaseModel):
    status: str
    count: int


class LeadNamedCount(BaseModel):
    name: str
    count: int


class LeadAnalytics(BaseModel):
    total: int
    new_today: int
    hot_leads: int  # lead_score >= 70
    by_status: list[LeadStatusCount]
    conversion_rate: float  # won / (won+lost), 0..100
    avg_score: float
    top_products: list[LeadNamedCount]
    by_language: list[LeadNamedCount]
