"""Telegram kanal → WhatsApp navbati (ERP sahifasi uchun).

Postlarni ko'rish, qayta yuborish, o'tkazib yuborish va "kanalga qo'ydim" deb
belgilash. Yuborishning o'zi alohida jarayonda (`app.integrations.wa_bridge`).
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import defer

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.integrations.wa_bridge.config import load_config
from app.models.wa_bridge import POST_STATUSES, ChannelPost
from app.schemas.wa_bridge import BridgeSummary, ChannelPostOut

# Ko'prik Telegram boti bilan ishlaydi — o'sha modul ruxsatidan foydalanamiz
router = APIRouter(dependencies=[Depends(module_guard("telegram"))])


def _to_out(post: ChannelPost, has_media: bool) -> ChannelPostOut:
    out = ChannelPostOut.model_validate(post)
    out.has_media = has_media
    return out


async def _get_post(db: AsyncSession, post_id: uuid.UUID) -> ChannelPost:
    post = (await db.execute(
        select(ChannelPost).where(ChannelPost.id == post_id).options(defer(ChannelPost.media))
    )).scalar_one_or_none()
    if not post:
        raise HTTPException(404, "Post topilmadi")
    return post


@router.get("/summary", response_model=BridgeSummary)
async def summary(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    rows = (await db.execute(
        select(ChannelPost.status, func.count(ChannelPost.id)).group_by(ChannelPost.status)
    )).all()
    counts = {status: count for status, count in rows}
    cfg = await load_config()
    return BridgeSummary(
        pending=counts.get("pending", 0),
        sent=counts.get("sent", 0),
        posted=counts.get("posted", 0),
        failed=counts.get("failed", 0),
        skipped=counts.get("skipped", 0),
        enabled=cfg.enabled,
        watching=cfg.can_watch,
        sending=cfg.can_send,
        targets=len(cfg.targets),
        delay_minutes=cfg.delay_minutes,
    )


@router.get("/posts", response_model=list[ChannelPostOut])
async def list_posts(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    status: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
):
    q = select(ChannelPost).options(defer(ChannelPost.media))
    if status and status in POST_STATUSES:
        q = q.where(ChannelPost.status == status)
    q = q.order_by(ChannelPost.posted_at.desc()).limit(limit)
    posts = (await db.execute(q)).scalars().all()
    return [_to_out(p, bool(p.media_size)) for p in posts]


@router.get("/posts/{post_id}/media")
async def post_media(post_id: uuid.UUID, _: CurrentUser,
                     db: Annotated[AsyncSession, Depends(get_db)]):
    """Media ko'rinishi (rasm/video) — navbatda turgan post uchun."""
    post = (await db.execute(
        select(ChannelPost).where(ChannelPost.id == post_id)
    )).scalar_one_or_none()
    if not post or not post.media:
        raise HTTPException(404, "Media topilmadi (yuborilgach o'chiriladi)")
    return Response(
        content=post.media,
        media_type=post.media_mime or "application/octet-stream",
        headers={"Cache-Control": "private, max-age=300"},
    )


@router.post("/posts/{post_id}/retry", response_model=ChannelPostOut)
async def retry_post(post_id: uuid.UUID, _: CurrentUser,
                     db: Annotated[AsyncSession, Depends(get_db)]):
    """Postni qayta navbatga qo'yadi (darhol yuborishga urinadi)."""
    post = await _get_post(db, post_id)
    if not post.media_size and post.kind != "text" and post.status in ("sent", "posted"):
        raise HTTPException(400, "Media o'chirilgan — postni qayta yuborib bo'lmaydi")
    post.status = "pending"
    post.attempts = 0
    post.error = None
    post.planned_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(post)
    return _to_out(post, bool(post.media_size))


@router.post("/posts/{post_id}/skip", response_model=ChannelPostOut)
async def skip_post(post_id: uuid.UUID, _: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    """Postni o'tkazib yuborish (WhatsApp'ga kerak emas)."""
    post = await _get_post(db, post_id)
    post.status = "skipped"
    post.error = None
    await db.commit()
    await db.refresh(post)
    return _to_out(post, bool(post.media_size))


@router.post("/posts/{post_id}/posted", response_model=ChannelPostOut)
async def mark_posted(post_id: uuid.UUID, _: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    """Xodim "WhatsApp kanaliga qo'ydim" deb belgilaydi."""
    post = await _get_post(db, post_id)
    if post.status not in ("sent", "posted"):
        raise HTTPException(400, "Avval post xodimga yuborilishi kerak")
    post.status = "posted"
    await db.commit()
    await db.refresh(post)
    return _to_out(post, bool(post.media_size))
