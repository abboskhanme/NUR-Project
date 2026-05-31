"""In-app notifications."""
import uuid
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.db.session import get_db
from app.models.system import Notification

router = APIRouter()


@router.get("")
async def list_my_notifications(user: CurrentUser,
                                db: Annotated[AsyncSession, Depends(get_db)],
                                unread_only: bool = False):
    q = select(Notification).where(Notification.user_id == user.id)
    if unread_only:
        q = q.where(Notification.read_at.is_(None))
    res = await db.execute(q.order_by(Notification.created_at.desc()).limit(100))
    items = res.scalars().all()
    return [{
        "id": str(n.id),
        "type": n.type,
        "title": n.title,
        "body": n.body,
        "payload": n.payload,
        "read_at": n.read_at,
        "created_at": n.created_at,
    } for n in items]


@router.post("/{notif_id}/read")
async def mark_read(notif_id: uuid.UUID, user: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(
        update(Notification)
        .where(Notification.id == notif_id, Notification.user_id == user.id)
        .values(read_at=datetime.utcnow())
    )
    await db.commit()
    return {"updated": res.rowcount}


@router.post("/read-all")
async def mark_all_read(user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(
        update(Notification)
        .where(Notification.user_id == user.id, Notification.read_at.is_(None))
        .values(read_at=datetime.utcnow())
    )
    await db.commit()
    return {"updated": res.rowcount}


@router.get("/unread-count")
async def unread_count(user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(
        select(func.count(Notification.id))
        .where(Notification.user_id == user.id, Notification.read_at.is_(None))
    )
    return {"count": res.scalar() or 0}
