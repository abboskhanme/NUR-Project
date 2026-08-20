"""Leadlar / Marketing — mustaqil modul API.

Ikki xil kirish:
  • Xodim (RBAC `leads` moduli) — ro'yxat, detal, status/assign, konversiya, analitika.
  • Tashqi agent (`X-Agent-Key`) — faqat `POST /ingest` (yangi lead yozadi).

Boshqa bo'limlarга (moliya, savdo, ombor) hech qanday ta'sir qilmaydi.
"""
import hmac
import re
import uuid
from datetime import datetime, timedelta, timezone
from typing import Annotated, Optional
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import and_, case, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.agent_client import agent_request
from app.core.config import settings
from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.customer import Customer
from app.models.lead import LEAD_STATUSES, Lead, LeadEvent
from app.models.system import SystemSetting
from app.models.user import User
from app.schemas.lead import (
    LeadAnalytics,
    LeadBotIn,
    LeadInboxItem,
    LeadReplyIn,
    LeadReplyResult,
    LeadContextMessage,
    LeadContextOut,
    LeadConvert,
    LeadDetailOut,
    LeadEventOut,
    LeadIngest,
    LeadIngestResult,
    LeadMessageIn,
    LeadMessageResult,
    LeadNamedCount,
    LeadNoteIn,
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


# ===========================================================================
# YOZISHMALAR — Instagram bilan ERP ichidan jonli muloqot
#
# Kelayotgan xabarlar webhook orqali `lead_events` ga tushadi, javob esa agent
# orqali yuboriladi (Instagram tokeni faqat agentда). Instagram qoidasi:
# mijozning oxirgi xabaridan 24 soat ichida erkin, 7 kungacha faqat JONLI
# operator (HUMAN_AGENT), keyin umuman yozib bo'lmaydi.
# ===========================================================================
_WINDOW_FREE = timedelta(hours=24)
_WINDOW_HUMAN = timedelta(days=7)


def _window_of(last_customer_at: Optional[datetime]) -> str:
    if not last_customer_at:
        return "closed"
    age = datetime.now(timezone.utc) - last_customer_at
    if age <= _WINDOW_FREE:
        return "open"
    if age <= _WINDOW_HUMAN:
        return "human_agent"
    return "closed"


async def _agent_public_url(db: AsyncSession) -> Optional[str]:
    """Agentning tashqi manzili (ichki tarmoq ishlamasa zaxira yo'l)."""
    row = (await db.execute(
        select(SystemSetting.value).where(SystemSetting.key == "AGENT_PUBLIC_URL")
    )).scalar_one_or_none()
    return row or None


@router.get("/inbox", response_model=list[LeadInboxItem])
async def inbox(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    search: Optional[str] = None,
    only_unread: bool = False,
    limit: int = Query(50, ge=1, le=200),
):
    """Instagram suhbatlari ro'yxati — oxirgi xabar, o'qilmaganlar, javob oynasi."""
    # Har lead bo'yicha oxirgi xabar vaqti va oxirgi MIJOZ xabari vaqti
    msg_kinds = ("dm", "comment")
    agg = (
        select(
            LeadEvent.lead_id.label("lead_id"),
            func.max(LeadEvent.created_at).label("last_at"),
            func.max(
                case((LeadEvent.message_text.is_not(None), LeadEvent.created_at))
            ).label("last_customer_at"),
            func.count(
                case((
                    and_(
                        LeadEvent.message_text.is_not(None),
                        or_(
                            Lead.last_read_at.is_(None),
                            LeadEvent.created_at > Lead.last_read_at,
                        ),
                    ), 1,
                ))
            ).label("unread"),
        )
        .join(Lead, Lead.id == LeadEvent.lead_id)
        .where(LeadEvent.kind.in_(msg_kinds))
        .group_by(LeadEvent.lead_id)
        .subquery()
    )

    q = (
        select(Lead, agg.c.last_at, agg.c.last_customer_at, agg.c.unread)
        .join(agg, agg.c.lead_id == Lead.id)
    )
    if search:
        like = f"%{search.strip()}%"
        q = q.where(or_(
            Lead.ig_username.ilike(like), Lead.name.ilike(like), Lead.contact.ilike(like),
        ))
    if only_unread:
        q = q.where(agg.c.unread > 0)
    q = q.order_by(agg.c.last_at.desc()).limit(limit)

    rows = (await db.execute(q)).all()
    if not rows:
        return []

    names = await _assignee_names(db, [r[0].assigned_to_id for r in rows])

    # Har suhbatning oxirgi xabari matni
    lead_ids = [r[0].id for r in rows]
    last_events = (await db.execute(
        select(LeadEvent)
        .where(LeadEvent.lead_id.in_(lead_ids), LeadEvent.kind.in_(msg_kinds))
        .order_by(LeadEvent.lead_id, LeadEvent.created_at.desc())
    )).scalars().all()
    last_by_lead: dict[uuid.UUID, LeadEvent] = {}
    for ev in last_events:
        last_by_lead.setdefault(ev.lead_id, ev)

    items: list[LeadInboxItem] = []
    for lead, last_at, last_customer_at, unread in rows:
        ev = last_by_lead.get(lead.id)
        text = (ev.message_text or ev.agent_reply) if ev else None
        role = None
        if ev:
            role = "user" if ev.message_text else ("operator" if ev.actor == "operator" else "assistant")
        items.append(LeadInboxItem(
            lead_id=lead.id,
            ig_user_id=lead.ig_user_id,
            ig_username=lead.ig_username,
            name=lead.name,
            contact=lead.contact,
            status=lead.status,
            lead_score=lead.lead_score or 0,
            source=lead.source,
            assigned_to_name=names.get(lead.assigned_to_id),
            last_message=text,
            last_message_at=last_at,
            last_message_role=role,
            last_customer_at=last_customer_at,
            unread=int(unread or 0),
            window=_window_of(last_customer_at),
        ))
    return items


@router.post("/{lead_id}/read", status_code=204)
async def mark_read(lead_id: uuid.UUID, _: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    """Suhbatni o'qilgan deb belgilaydi."""
    lead = await _get_lead(db, lead_id)
    lead.last_read_at = datetime.now(timezone.utc)
    await db.commit()


@router.post("/{lead_id}/reply", response_model=LeadReplyResult)
async def reply_to_lead(
    lead_id: uuid.UUID, payload: LeadReplyIn, user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Operator yozgan xabarni Instagram'ga yuboradi va jurnalga yozadi.

    Yuborilgach AI o'sha suhbatda jim turadi — javobni operator berayotgan
    bo'lsa bot aralashmasligi kerak.
    """
    text = (payload.text or "").strip()
    if not text:
        raise HTTPException(400, "Xabar matni bo'sh")

    lead = await _get_lead(db, lead_id)
    if not lead.ig_user_id:
        raise HTTPException(400, "Bu leadда Instagram foydalanuvchisi yo'q")

    last_customer_at = (await db.execute(
        select(func.max(LeadEvent.created_at)).where(
            LeadEvent.lead_id == lead.id, LeadEvent.message_text.is_not(None)
        )
    )).scalar()
    window = _window_of(last_customer_at)
    if window == "closed":
        raise HTTPException(
            400,
            "Instagram javob oynasi yopilgan (mijozning oxirgi xabaridan 7 kun "
            "o'tgan). Instagram ilovasidan yoki telefon orqali bog'laning.",
        )

    result = await agent_request(
        "POST", "/admin/send-dm",
        json={
            "ig_user_id": lead.ig_user_id,
            "text": text,
            "human_agent": window == "human_agent",
        },
        public_url=await _agent_public_url(db),
    )
    if not result.get("sent"):
        return LeadReplyResult(sent=False, error=result.get("error") or "Yuborilmadi")

    event = LeadEvent(
        lead_id=lead.id, kind="dm", agent_reply=text, actor="operator",
        meta={"role": "operator", "by": str(user.id), "by_name": user.full_name,
              "tag": result.get("tag")},
    )
    db.add(event)
    lead.last_read_at = datetime.now(timezone.utc)
    # Operator javob bergan bo'lsa lead "bog'lanildi" holatiga o'tadi
    if lead.status == "new":
        lead.status = "contacted"
    await db.commit()
    await db.refresh(event)
    return LeadReplyResult(sent=True, tag=result.get("tag"),
                           event=LeadEventOut.model_validate(event))


@router.get("/{lead_id}/bot")
async def bot_state(lead_id: uuid.UUID, _: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    """AI shu suhbatda javob beryaptimi."""
    lead = await _get_lead(db, lead_id)
    if not lead.ig_user_id:
        return {"paused": False}
    data = await agent_request(
        "GET", "/admin/bot-state", params={"ig_user_id": lead.ig_user_id},
        public_url=await _agent_public_url(db),
    )
    return {"paused": bool(data.get("paused"))}


@router.post("/{lead_id}/bot")
async def set_bot_state(lead_id: uuid.UUID, payload: LeadBotIn, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    """Shu suhbatda AI javobini yoqish/o'chirish."""
    lead = await _get_lead(db, lead_id)
    if not lead.ig_user_id:
        raise HTTPException(400, "Bu leadда Instagram foydalanuvchisi yo'q")
    data = await agent_request(
        "POST", "/admin/bot-pause",
        json={"ig_user_id": lead.ig_user_id, "enabled": payload.enabled},
        public_url=await _agent_public_url(db),
    )
    return {"paused": bool(data.get("paused"))}


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


@router.post("/{lead_id}/notes", response_model=LeadEventOut, status_code=201)
async def add_note(
    lead_id: uuid.UUID,
    payload: LeadNoteIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Bog'lanish jurnaliga izoh qo'shadi (tarix — bir necha marta yozish mumkin)."""
    lead = await _get_lead(db, lead_id)
    text = (payload.text or "").strip()
    if not text:
        raise HTTPException(400, "Izoh bo'sh bo'lishi mumkin emas")
    event = LeadEvent(
        lead_id=lead.id,
        kind="note",
        message_text=text,
        actor="user",
        meta={"by": str(user.id), "by_name": user.full_name},
    )
    db.add(event)
    await db.commit()
    await db.refresh(event)
    return event


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
        # Raqam +998 emas bo'lsa (Rossiya, Qozog'iston...) — davlatni raqamdan olamiz
        country=_country_of(phone),
        source="instagram",
        note=payload.note or lead.summary,
        created_by_id=user.id,  # mijozni aylantirgan operator — sotuvchi/egasi
    )
    db.add(customer)
    await db.flush()  # customer.id kerak

    lead.customer_id = customer.id
    lead.status = "won"
    # Leadни ham shu operatorga biriktiramiz (uning akkountiga bog'lanadi)
    lead.assigned_to_id = user.id
    db.add(LeadEvent(
        lead_id=lead.id, kind="status", actor="user",
        meta={"to": "won", "customer_id": str(customer.id), "by": str(user.id),
              "by_name": user.full_name},
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


# ---------------------------------------------------------------------------
# SUHBAT XOTIRASI — agent har bir xabarni shu yerga yozadi, keyin shu yerdan
# o'qiydi. Instagram'ning o'zida tarix 30 kundan keyin API'dan yo'qoladi,
# shuning uchun yagona ishonchli manba — shu jadval.
# ---------------------------------------------------------------------------
# Telefon raqamini matndan ajratish. Mijozlar BOSHQA DAVLATLARDAN ham yozadi
# (Rossiya +7, Qozog'iston +7, Qirg'iziston +996, Tojikiston +992, Turkiya +90),
# shuning uchun faqat 998 bilan cheklanmaymiz. Ayni paytda narx ("150 000 000")
# raqam deb topilib qolmasligi uchun har bir nomzod qat'iy tekshiriladi.
_PHONE_CANDIDATE_RE = re.compile(r"(?<![\w+])(\+?\d[\d\s\-()]{6,20}\d)(?!\w)")

# O'zbek mobil/shahar kodlari — "+998"siz yozilgan 9 xonali raqam uchun
_UZ_CODES = {
    "20", "33", "50", "55", "71", "77", "78", "88",
    "90", "91", "93", "94", "95", "97", "98", "99",
}


def _extract_phone(text: str) -> Optional[str]:
    """Xabar matnidan telefon raqamini ajratadi (xalqaro formatda qaytaradi).

    Qabul qilinadigan ko'rinishlar:
      +79145895911 / +7 914 589-59-11  -> +79145895911   (Rossiya/Qozog'iston)
      +998 90 111 22 33                -> +998901112233
      998901112233 / 901112233         -> +998901112233
      89145895911                      -> +79145895911   (RF ichki formati)
    Narx va boshqa sonlar («150000000», «12 000 000») rad etiladi.
    """
    for m in _PHONE_CANDIDATE_RE.finditer(text or ""):
        raw = m.group(1).strip()
        digits = re.sub(r"\D", "", raw)
        has_plus = raw.startswith("+")

        # 1) Xalqaro yozuv ("+" bilan) — davlat kodidan qat'i nazar
        if has_plus and 10 <= len(digits) <= 15:
            return f"+{digits}"
        # 2) "+"siz, lekin tanish davlat kodi bilan
        if len(digits) == 12 and digits[:3] in ("998", "996", "992"):
            return f"+{digits}"
        if len(digits) == 11 and digits[0] in ("7", "8") and digits[1] == "9":
            return f"+7{digits[1:]}"          # RF/KZ mobil (8 yoki 7 bilan)
        if len(digits) == 10 and digits[0] == "9":
            return f"+7{digits}"              # davlat kodisiz RF mobil
        # 3) O'zbek raqami davlat kodisiz — faqat haqiqiy operator kodi bilan
        if len(digits) == 9 and digits[:2] in _UZ_CODES:
            return f"+998{digits}"
    return None


# Davlat kodidan mijoz davlatini aniqlash (chet eldan yozadiganlar uchun).
# Nomlar mijoz formasidagi qiymatlar bilan bir xil bo'lishi shart.
_DIAL_COUNTRY = (
    ("998", "Uzbekistan"),
    ("996", "Kyrgyzstan"),
    ("992", "Tajikistan"),
    ("993", "Turkmenistan"),
    ("90", "Turkey"),
)


def _country_of(phone: str) -> str:
    """+7 9xx -> Russia, +7 7xx -> Kazakhstan, +996 -> Kyrgyzstan va h.k.

    Noma'lum bo'lsa Uzbekistan (eng ko'p uchraydigan holat).
    """
    raw = (phone or "").strip()
    digits = re.sub(r"\D", "", raw)
    # Davlat kodisiz yozilgan mahalliy raqam ("90 111 22 33") — O'zbekiston.
    # Aks holda "90" Turkiya kodi deb o'qilib ketardi.
    if not raw.startswith("+") and len(digits) <= 9:
        return "Uzbekistan"
    if digits.startswith("7") and len(digits) >= 2:
        # Rossiya va Qozog'iston bitta kodni bo'lishadi: 7 7xx/7 6xx — Qozog'iston
        return "Kazakhstan" if digits[1] in ("6", "7") else "Russia"
    for dial, country in _DIAL_COUNTRY:
        if digits.startswith(dial):
            return country
    return "Uzbekistan"


async def _lead_for_conversation(
    db: AsyncSession, *, source: str, ig_user_id: str, ig_username: Optional[str],
    create: bool = True,
) -> Optional[Lead]:
    """Shu Instagram foydalanuvchisining ochiq leadini topadi.

    `create=False` bo'lsa va lead topilmasa — None (izohlardan har kim uchun
    lead ochilib ketmasligi uchun).
    """
    lead = (await db.execute(
        select(Lead)
        .where(Lead.ig_user_id == ig_user_id, Lead.status.notin_(["won", "lost"]))
        .order_by(Lead.created_at.desc())
        .limit(1)
    )).scalar_one_or_none()
    if lead is None:
        if not create:
            return None
        lead = Lead(source=source, ig_user_id=ig_user_id, ig_username=ig_username)
        db.add(lead)
        await db.flush()
    elif ig_username and not lead.ig_username:
        lead.ig_username = ig_username
    return lead


@ingest_router.post(
    "/ingest/message",
    response_model=LeadMessageResult,
    status_code=201,
    dependencies=[Depends(require_agent_key)],
    summary="Agent bitta Instagram xabarini jurnalga yozadi (X-Agent-Key)",
)
async def ingest_message(payload: LeadMessageIn, db: Annotated[AsyncSession, Depends(get_db)]):
    text = (payload.text or "").strip()
    if not text:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Xabar matni bo'sh")

    lead = await _lead_for_conversation(
        db, source=payload.source, ig_user_id=payload.ig_user_id,
        ig_username=payload.ig_username, create=payload.create_lead,
    )
    if lead is None:
        return LeadMessageResult(logged=False)

    # Dublikat — bir xil Instagram xabari ikki marta yozilmasin (import + webhook)
    if payload.ig_message_id:
        exists = (await db.execute(
            select(LeadEvent.id)
            .where(
                LeadEvent.lead_id == lead.id,
                LeadEvent.meta["ig_message_id"].astext == payload.ig_message_id,
            )
            .limit(1)
        )).scalar_one_or_none()
        if exists:
            await db.commit()
            return LeadMessageResult(logged=False, lead_id=lead.id, duplicate=True)

    is_customer = payload.role == "user"
    meta: dict = {"role": payload.role}
    if payload.ig_message_id:
        meta["ig_message_id"] = payload.ig_message_id
    if payload.comment_id:
        meta["comment_id"] = payload.comment_id

    event = LeadEvent(
        lead_id=lead.id,
        kind="comment" if payload.kind == "comment" else "dm",
        message_text=text if is_customer else None,
        agent_reply=None if is_customer else text,
        actor="user" if is_customer else payload.role,
        meta=meta,
    )
    if payload.sent_at:
        event.created_at = payload.sent_at
    db.add(event)

    # Mijoz xabaridan telefon raqami chiqsa — leadga yozib qo'yamiz (AI qayta so'ramasin)
    if is_customer and not lead.contact:
        phone = _extract_phone(text)
        if phone:
            lead.contact = phone
    if payload.media_id and not lead.media_id:
        lead.media_id = payload.media_id
    if payload.comment_id and not lead.comment_id:
        lead.comment_id = payload.comment_id

    await db.commit()
    return LeadMessageResult(logged=True, lead_id=lead.id, duplicate=False)


@ingest_router.get(
    "/ingest/context",
    response_model=LeadContextOut,
    dependencies=[Depends(require_agent_key)],
    summary="Agent suhbat tarixini va ma'lum faktlarni oladi (X-Agent-Key)",
)
async def ingest_context(
    db: Annotated[AsyncSession, Depends(get_db)],
    ig_user_id: str = Query(..., min_length=1),
    limit: int = Query(40, ge=1, le=200),
):
    """Shu Instagram foydalanuvchisi bilan bo'lgan BUTUN yozishma (oxirgi `limit` ta).

    Bir foydalanuvchida bir nechta lead bo'lishi mumkin (eskisi yopilgan bo'lsa) —
    xotira uzilib qolmasligi uchun hammasi birga qaytariladi.
    """
    leads = (await db.execute(
        select(Lead).where(Lead.ig_user_id == ig_user_id).order_by(Lead.created_at)
    )).scalars().all()
    if not leads:
        return LeadContextOut()

    lead_ids = [l.id for l in leads]
    rows = (await db.execute(
        select(LeadEvent)
        .where(LeadEvent.lead_id.in_(lead_ids), LeadEvent.kind.in_(["dm", "comment"]))
        .order_by(LeadEvent.created_at.desc())
        .limit(limit)
    )).scalars().all()

    messages: list[LeadContextMessage] = []
    for ev in reversed(rows):
        if ev.message_text:
            messages.append(LeadContextMessage(
                role="user", content=ev.message_text, at=ev.created_at))
        if ev.agent_reply:
            role = "operator" if ev.actor == "operator" else "assistant"
            messages.append(LeadContextMessage(
                role=role, content=ev.agent_reply, at=ev.created_at))

    # Faktlar — eng oxirgi to'ldirilgan qiymat ustun
    def _last(field: str) -> Optional[str]:
        for l in reversed(leads):
            val = getattr(l, field, None)
            if val:
                return val
        return None

    current = leads[-1]
    return LeadContextOut(
        lead_id=current.id,
        ig_username=_last("ig_username"),
        name=_last("name"),
        contact=_last("contact"),
        product_interest=_last("product_interest"),
        summary=_last("summary"),
        status=current.status,
        messages=messages,
    )
