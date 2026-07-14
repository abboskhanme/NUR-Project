"""Leadlar / Marketing — mustaqil modul API.

Ikki xil kirish:
  • Xodim (RBAC `leads` moduli) — ro'yxat, detal, status/assign, konversiya, analitika.
  • Tashqi agent (`X-Agent-Key`) — faqat `POST /ingest` (yangi lead yozadi).

Boshqa bo'limlarга (moliya, savdo, ombor) hech qanday ta'sir qilmaydi.
"""
import hmac
import uuid
from datetime import datetime
from typing import Annotated, Optional
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.customer import Customer
from app.models.lead import LEAD_STATUSES, Lead, LeadEvent
from app.models.user import User
from app.schemas.lead import (
    LeadAnalytics,
    LeadConvert,
    LeadDetailOut,
    LeadIngest,
    LeadIngestResult,
    LeadNamedCount,
    LeadOut,
    LeadStatusCount,
    LeadUpdate,
)

router = APIRouter(dependencies=[Depends(module_guard("leads"))])


# ===========================================================================
# Yordamchilar
# ===========================================================================
async def _get_lead(db: AsyncSession, lead_id: uuid.UUID) -> Lead:
    lead = (await db.execute(select(Lead).where(Lead.id == lead_id))).scalar_one_or_none()
    if not lead:
        raise HTTPException(404, "Lead topilmadi")
    return lead


async def _assignee_names(db: AsyncSession, ids: list[uuid.UUID]) -> dict[uuid.UUID, str]:
    ids = [i for i in ids if i]
    if not ids:
        return {}
    res = await db.execute(select(User.id, User.full_name).where(User.id.in_(ids)))
    return {row.id: row.full_name for row in res.all()}


def _to_out(lead: Lead, names: dict[uuid.UUID, str], event_count: int = 0) -> LeadOut:
    return LeadOut(
        **{
            k: getattr(lead, k)
            for k in (
                "id", "source", "ig_user_id", "ig_username", "media_id", "comment_id",
                "name", "contact", "product_interest", "language", "intent",
                "lead_score", "summary", "status", "assigned_to_id", "note",
                "customer_id", "order_id", "created_at", "updated_at",
            )
        },
        assigned_to_name=names.get(lead.assigned_to_id),
        event_count=event_count,
    )


def _today_start() -> datetime:
    tz = ZoneInfo(settings.TIMEZONE)
    now = datetime.now(tz)
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


# ===========================================================================
# Analitika
# ===========================================================================
@router.get("/analytics", response_model=LeadAnalytics)
async def lead_analytics(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    # Status bo'yicha
    st_res = await db.execute(
        select(Lead.status, func.count(Lead.id)).group_by(Lead.status)
    )
    by_status_map: dict[str, int] = {row[0]: row[1] for row in st_res.all()}
    total = sum(by_status_map.values())
    won = by_status_map.get("won", 0)
    lost = by_status_map.get("lost", 0)
    conversion = round(won / (won + lost) * 100, 1) if (won + lost) > 0 else 0.0

    new_today = (
        await db.execute(
            select(func.count(Lead.id)).where(Lead.created_at >= _today_start())
        )
    ).scalar_one()
    hot = (
        await db.execute(select(func.count(Lead.id)).where(Lead.lead_score >= 70))
    ).scalar_one()
    avg_score = (await db.execute(select(func.avg(Lead.lead_score)))).scalar_one() or 0

    prod_res = await db.execute(
        select(Lead.product_interest, func.count(Lead.id).label("c"))
        .where(Lead.product_interest.is_not(None), Lead.product_interest != "")
        .group_by(Lead.product_interest)
        .order_by(func.count(Lead.id).desc())
        .limit(5)
    )
    lang_res = await db.execute(
        select(Lead.language, func.count(Lead.id).label("c"))
        .where(Lead.language.is_not(None), Lead.language != "")
        .group_by(Lead.language)
        .order_by(func.count(Lead.id).desc())
    )

    return LeadAnalytics(
        total=total,
        new_today=new_today or 0,
        hot_leads=hot or 0,
        by_status=[LeadStatusCount(status=s, count=c) for s, c in by_status_map.items()],
        conversion_rate=conversion,
        avg_score=round(float(avg_score), 1),
        top_products=[LeadNamedCount(name=p, count=c) for p, c in prod_res.all()],
        by_language=[LeadNamedCount(name=l, count=c) for l, c in lang_res.all()],
    )


@router.get("/assignees")
async def list_assignees(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    """Lead biriktirish uchun faol foydalanuvchilar (id + ism)."""
    res = await db.execute(
        select(User.id, User.full_name).where(User.is_active.is_(True)).order_by(User.full_name)
    )
    return [{"id": str(row.id), "full_name": row.full_name} for row in res.all()]


# ===========================================================================
# Ro'yxat + detal
# ===========================================================================
@router.get("", response_model=list[LeadOut])
async def list_leads(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: CurrentUser,
    search: Optional[str] = None,
    status_filter: str = Query("all", alias="status"),
    source: Optional[str] = None,
    assigned_to_id: Optional[uuid.UUID] = None,
    limit: int = Query(100, le=500),
):
    q = select(Lead)
    if status_filter and status_filter != "all":
        q = q.where(Lead.status == status_filter)
    if source:
        q = q.where(Lead.source == source)
    if assigned_to_id:
        q = q.where(Lead.assigned_to_id == assigned_to_id)
    if search:
        like = f"%{search.strip()}%"
        q = q.where(
            or_(
                Lead.name.ilike(like),
                Lead.ig_username.ilike(like),
                Lead.contact.ilike(like),
                Lead.product_interest.ilike(like),
                Lead.summary.ilike(like),
            )
        )
    q = q.order_by(Lead.created_at.desc()).limit(limit)
    leads = (await db.execute(q)).scalars().all()

    names = await _assignee_names(db, [l.assigned_to_id for l in leads])
    # Har lead uchun hodisa soni
    counts: dict[uuid.UUID, int] = {}
    if leads:
        cnt_res = await db.execute(
            select(LeadEvent.lead_id, func.count(LeadEvent.id))
            .where(LeadEvent.lead_id.in_([l.id for l in leads]))
            .group_by(LeadEvent.lead_id)
        )
        counts = {row[0]: row[1] for row in cnt_res.all()}
    return [_to_out(l, names, counts.get(l.id, 0)) for l in leads]


@router.get("/{lead_id}", response_model=LeadDetailOut)
async def get_lead(
    lead_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser
):
    lead = (
        await db.execute(
            select(Lead).where(Lead.id == lead_id).options(selectinload(Lead.events))
        )
    ).scalar_one_or_none()
    if not lead:
        raise HTTPException(404, "Lead topilmadi")
    names = await _assignee_names(db, [lead.assigned_to_id])
    base = _to_out(lead, names, len(lead.events))
    return LeadDetailOut(**base.model_dump(), events=list(lead.events))


# ===========================================================================
# Yangilash / o'chirish / konversiya
# ===========================================================================
@router.patch("/{lead_id}", response_model=LeadOut)
async def update_lead(
    lead_id: uuid.UUID,
    payload: LeadUpdate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    lead = await _get_lead(db, lead_id)
    data = payload.model_dump(exclude_unset=True)

    if "status" in data and data["status"] is not None:
        if data["status"] not in LEAD_STATUSES:
            raise HTTPException(400, f"Noto'g'ri status. Ruxsat: {', '.join(LEAD_STATUSES)}")
        if data["status"] != lead.status:
            db.add(LeadEvent(
                lead_id=lead.id, kind="status", actor="user",
                meta={"from": lead.status, "to": data["status"], "by": str(user.id)},
            ))

    for k, v in data.items():
        setattr(lead, k, v)
    await db.commit()
    await db.refresh(lead)
    names = await _assignee_names(db, [lead.assigned_to_id])
    return _to_out(lead, names)


@router.delete("/{lead_id}", status_code=204)
async def delete_lead(
    lead_id: uuid.UUID, _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    lead = await _get_lead(db, lead_id)
    await db.delete(lead)  # events cascade bilan o'chadi
    await db.commit()


@router.post("/{lead_id}/convert", response_model=LeadOut)
async def convert_lead(
    lead_id: uuid.UUID,
    payload: LeadConvert,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Leaddan mijoz yaratadi va lead'ni 'won' holatiga o'tkazadi.

    Telefon raqami majburiy (mijoz uchun). Lead kontaktida raqam bo'lmasa,
    frontend uni so'raydi va shu yerга yuboradi.
    """
    lead = await _get_lead(db, lead_id)
    if lead.customer_id:
        raise HTTPException(400, "Bu lead allaqachon mijozga aylantirilgan")

    phone = (payload.phone or lead.contact or "").strip()
    if not phone:
        raise HTTPException(400, "Telefon raqami kerak (lead kontaktida yo'q)")

    customer = Customer(
        full_name=(payload.full_name or lead.name or lead.ig_username or "Instagram lead").strip(),
        phone=phone,
        region=payload.region,
        source="instagram",
        note=payload.note or lead.summary,
        created_by_id=user.id,
    )
    db.add(customer)
    await db.flush()  # customer.id kerak

    lead.customer_id = customer.id
    lead.status = "won"
    db.add(LeadEvent(
        lead_id=lead.id, kind="status", actor="user",
        meta={"to": "won", "customer_id": str(customer.id), "by": str(user.id)},
    ))
    await db.commit()
    await db.refresh(lead)
    names = await _assignee_names(db, [lead.assigned_to_id])
    return _to_out(lead, names)


# ===========================================================================
# INGEST — tashqi agent uchun (X-Agent-Key bilan, JWT emas)
# ===========================================================================
ingest_router = APIRouter()


async def require_agent_key(x_agent_key: Annotated[str | None, Header()] = None) -> None:
    if not settings.AGENT_INGEST_KEY:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Lead ingest sozlanmagan (AGENT_INGEST_KEY yo'q)",
        )
    if not x_agent_key or not hmac.compare_digest(x_agent_key, settings.AGENT_INGEST_KEY):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Agent kaliti noto'g'ri")


@ingest_router.post(
    "/ingest",
    response_model=LeadIngestResult,
    status_code=201,
    dependencies=[Depends(require_agent_key)],
    summary="Tashqi agent lead yozadi (X-Agent-Key)",
)
async def ingest_lead(payload: LeadIngest, db: Annotated[AsyncSession, Depends(get_db)]):
    # Ochiq lead'ni topamiz (bir foydalanuvchining takroriy xabari yangi lead yaratmasin)
    existing: Optional[Lead] = None
    if payload.ig_user_id:
        existing = (
            await db.execute(
                select(Lead)
                .where(
                    Lead.source == payload.source,
                    Lead.ig_user_id == payload.ig_user_id,
                    Lead.status.notin_(["won", "lost"]),
                )
                .order_by(Lead.created_at.desc())
                .limit(1)
            )
        ).scalar_one_or_none()

    duplicate = existing is not None
    if existing:
        lead = existing
        # Bo'sh bo'lmagan yangi ma'lumot bilan yangilaymiz
        for field in ("name", "contact", "product_interest", "language", "intent",
                      "summary", "media_id", "comment_id", "ig_username"):
            val = getattr(payload, field, None)
            if val:
                setattr(lead, field, val)
        lead.lead_score = max(lead.lead_score or 0, payload.lead_score or 0)
    else:
        lead = Lead(
            source=payload.source,
            ig_user_id=payload.ig_user_id,
            ig_username=payload.ig_username,
            media_id=payload.media_id,
            comment_id=payload.comment_id,
            name=payload.name,
            contact=payload.contact,
            product_interest=payload.product_interest,
            language=payload.language,
            intent=payload.intent,
            lead_score=payload.lead_score or 0,
            summary=payload.summary,
            extra=payload.extra or {},
        )
        db.add(lead)
        await db.flush()

    # Suhbat qadamini jurnalga yozamiz
    if payload.message_text or payload.agent_reply:
        db.add(LeadEvent(
            lead_id=lead.id,
            kind="comment" if payload.comment_id else "dm",
            message_text=payload.message_text,
            agent_reply=payload.agent_reply,
            actor="agent",
            meta={"comment_id": payload.comment_id} if payload.comment_id else {},
        ))

    await db.commit()
    await db.refresh(lead)
    return LeadIngestResult(id=lead.id, status=lead.status, duplicate=duplicate)
