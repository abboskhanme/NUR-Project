"""Servis arizasi lokatsiyasi — ERP va Telegram bot uchun umumiy mantiq.

Lokatsiya AYNAN arizaga yoziladi (mijoz kartochkasiga emas): mijoz keyingi
safar boshqa manzilga chaqirishi mumkin, shuning uchun har ariza o'z nuqtasi
bilan yuradi.

Ikki oqim bir xil funksiyalarga tayanadi:
  * ERP — xodim havola/koordinatani modalga qo'yadi;
  * bot — mijozdan kelgan pin forward qilinadi.
"""
from __future__ import annotations

import re
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.customer import Customer
from app.models.service import ServiceLocationRequest, ServiceTicket
from app.models.user import User
from app.services.geo import Coords

# "Lokatsiya kutilmoqda" oynasi — ERP'dan botga o'tib forward qilishga yetadi.
REQUEST_TTL_MINUTES = 30

OPEN_STATUSES = ("new", "scheduled")

SOURCE_TELEGRAM = "telegram"   # botga forward qilingan Telegram pin
SOURCE_LINK = "link"           # xarita havolasidan
SOURCE_MANUAL = "manual"       # koordinata qo'lda kiritilgan


def _now() -> datetime:
    return datetime.now(timezone.utc)


def set_location(
    ticket: ServiceTicket,
    coords: Coords,
    *,
    source: str,
    url: Optional[str] = None,
    note: Optional[str] = None,
    user_id: Optional[uuid.UUID] = None,
) -> None:
    """Arizaga lokatsiyani yozadi (commit chaqiruvchi tomonda)."""
    ticket.lat = coords.lat
    ticket.lon = coords.lon
    ticket.location_url = (url or None)
    ticket.location_source = source
    ticket.location_added_at = _now()
    ticket.location_added_by_id = user_id
    if note is not None:
        ticket.location_note = note.strip() or None


def clear_location(ticket: ServiceTicket) -> None:
    ticket.lat = None
    ticket.lon = None
    ticket.location_url = None
    ticket.location_note = None
    ticket.location_source = None
    ticket.location_added_at = None
    ticket.location_added_by_id = None


# --------------------------------------------------------------------------- #
# "Lokatsiya kutilmoqda" oynasi
# --------------------------------------------------------------------------- #
async def create_request(
    db: AsyncSession, ticket_id: uuid.UUID, user_id: uuid.UUID,
    ttl_minutes: int = REQUEST_TTL_MINUTES,
) -> ServiceLocationRequest:
    """Xodim uchun yangi oyna ochadi; o'sha xodimning eskilarini yopadi.

    Bir vaqtda faqat bitta ariza kutishi mumkin — aks holda forward qilingan
    pin qaysi arizaga tushgani noaniq bo'lib qoladi.
    """
    for old in await _open_requests(db, user_id):
        old.consumed_at = _now()
    req = ServiceLocationRequest(
        ticket_id=ticket_id, user_id=user_id,
        expires_at=_now() + timedelta(minutes=ttl_minutes),
    )
    db.add(req)
    await db.commit()
    await db.refresh(req)
    return req


async def _open_requests(db: AsyncSession, user_id: uuid.UUID) -> list[ServiceLocationRequest]:
    return list((await db.execute(
        select(ServiceLocationRequest).where(
            ServiceLocationRequest.user_id == user_id,
            ServiceLocationRequest.consumed_at.is_(None),
        )
    )).scalars().all())


async def active_request(db: AsyncSession, user_id: uuid.UUID) -> Optional[ServiceLocationRequest]:
    """Xodimning kuchdagi (muddati o'tmagan) oynasi."""
    return (await db.execute(
        select(ServiceLocationRequest).where(
            ServiceLocationRequest.user_id == user_id,
            ServiceLocationRequest.consumed_at.is_(None),
            ServiceLocationRequest.expires_at > _now(),
        ).order_by(ServiceLocationRequest.created_at.desc())
    )).scalars().first()


def consume(req: ServiceLocationRequest) -> None:
    req.consumed_at = _now()


# --------------------------------------------------------------------------- #
# Bot uchun qidiruvlar
# --------------------------------------------------------------------------- #
async def user_by_chat_id(db: AsyncSession, chat_id: int | str) -> Optional[User]:
    return (await db.execute(
        select(User).where(User.telegram_chat_id == str(chat_id), User.is_active.is_(True))
    )).scalars().first()


def _with_customer(stmt):
    return stmt.options(selectinload(ServiceTicket.customer))


async def ticket_by_id(db: AsyncSession, ticket_id: uuid.UUID) -> Optional[ServiceTicket]:
    return (await db.execute(
        _with_customer(select(ServiceTicket).where(ServiceTicket.id == ticket_id))
    )).scalars().first()


async def tickets_needing_location(db: AsyncSession, limit: int = 8) -> list[ServiceTicket]:
    """Ochiq, lokatsiyasi yo'q arizalar — botdagi tanlov tugmalari uchun."""
    return list((await db.execute(
        _with_customer(
            select(ServiceTicket).where(
                ServiceTicket.status.in_(OPEN_STATUSES),
                ServiceTicket.lat.is_(None),
            ).order_by(ServiceTicket.opened_at.desc()).limit(limit)
        )
    )).scalars().unique().all())


async def search_tickets(db: AsyncSession, query: str, limit: int = 8) -> list[ServiceTicket]:
    """Ariza kodi, mijoz ismi yoki telefon raqami bo'yicha qidiruv (bot uchun)."""
    term = (query or "").strip()
    if not term:
        return []
    like = f"%{term}%"
    digits = re.sub(r"\D", "", term)

    conds = [ServiceTicket.code.ilike(like), Customer.full_name.ilike(like)]
    if len(digits) >= 3:
        conds.append(func.regexp_replace(Customer.phone, "[^0-9]", "", "g").ilike(f"%{digits}%"))

    return list((await db.execute(
        _with_customer(
            select(ServiceTicket)
            .join(Customer, Customer.id == ServiceTicket.customer_id)
            .where(or_(*conds))
            .order_by(ServiceTicket.opened_at.desc())
            .limit(limit)
        )
    )).scalars().unique().all())
