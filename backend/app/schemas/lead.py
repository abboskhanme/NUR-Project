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


class LeadMessageIn(BaseModel):
    """Bitta Instagram xabari — suhbat tarixini TO'LIQ saqlash uchun.

    Agent har bir kelgan/ketgan xabarni shu yerga yozadi (AI "qaynoq lead"
    demasa ham). Shunda AI keyingi safar butun suhbatni eslay oladi va
    xodim Leadlar bo'limida yozishmani boshidan ko'radi.
    """

    source: str = "instagram"
    ig_user_id: str
    ig_username: Optional[str] = None
    # user — mijoz, assistant — AI agent, operator — xodim qo'lda yozgan
    role: str = "user"
    text: str
    kind: str = "dm"                       # dm | comment
    ig_message_id: Optional[str] = None    # dublikatni oldini olish uchun
    comment_id: Optional[str] = None
    media_id: Optional[str] = None
    # Import qilinayotgan eski xabarning asl vaqti (bo'lmasa — hozir)
    sent_at: Optional[datetime] = None
    # False bo'lsa — lead mavjud bo'lmasa YANGI lead yaratilmaydi (izohlar uchun:
    # har bir "🔥" izohi Leadlar ro'yxatini to'ldirib yubormasin)
    create_lead: bool = True


class LeadMessageResult(BaseModel):
    logged: bool = False
    lead_id: Optional[uuid.UUID] = None
    duplicate: bool = False


class LeadContextMessage(BaseModel):
    role: str        # user | assistant | operator
    content: str
    at: Optional[datetime] = None


class LeadContextOut(BaseModel):
    """Agent uchun suhbat xotirasi — oxirgi xabarlar + ma'lum faktlar."""

    lead_id: Optional[uuid.UUID] = None
    ig_username: Optional[str] = None
    name: Optional[str] = None
    contact: Optional[str] = None
    product_interest: Optional[str] = None
    summary: Optional[str] = None
    status: Optional[str] = None
    messages: list[LeadContextMessage] = []


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
    meta: dict[str, Any] = {}
    created_at: datetime


class LeadNoteIn(BaseModel):
    """Xodim qo'shadigan izoh (bog'lanish jurnaliga yoziladi)."""

    text: str


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
# "Yozishmalar" (Instagram inbox) — ERP ichidan jonli yozishish
# ---------------------------------------------------------------------------
class LeadInboxItem(BaseModel):
    """Suhbatlar ro'yxatidagi bitta qator."""

    lead_id: uuid.UUID
    ig_user_id: Optional[str] = None
    ig_username: Optional[str] = None
    name: Optional[str] = None
    contact: Optional[str] = None
    status: str
    lead_score: int = 0
    source: str = "instagram"
    assigned_to_name: Optional[str] = None
    last_message: Optional[str] = None
    last_message_at: Optional[datetime] = None
    last_message_role: Optional[str] = None       # user | assistant | operator
    last_customer_at: Optional[datetime] = None   # javob oynasi shundan hisoblanadi
    unread: int = 0
    # open — 24 soat ichida erkin javob; human_agent — 7 kungacha faqat operator;
    # closed — Instagram javob berishga ruxsat bermaydi
    window: str = "closed"


class LeadReplyIn(BaseModel):
    text: str


class LeadReplyResult(BaseModel):
    sent: bool
    tag: Optional[str] = None        # HUMAN_AGENT ishlatilgan bo'lsa
    error: Optional[str] = None
    event: Optional[LeadEventOut] = None


class LeadBotIn(BaseModel):
    enabled: bool = True             # True — AI javob bersin


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
