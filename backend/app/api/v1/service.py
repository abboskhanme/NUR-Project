"""Service tickets, visits, warranty."""
import uuid
from datetime import datetime
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import CurrentUser
from app.db.session import get_db
from app.models.order import Order
from app.models.service import ServiceTicket, ServiceVisit
from app.schemas.common import Page
from app.schemas.service import (
    ServiceTicketCreate, ServiceTicketOut, ServiceTicketUpdate,
    ServiceVisitIn, ServiceVisitOut, WarrantyInfo,
)
from app.services.warranty_service import calculate_warranty

router = APIRouter()


def _gen_code(year: int, n: int) -> str:
    return f"SRV-{year}-{n:05d}"


@router.get("/tickets", response_model=Page[ServiceTicketOut])
async def list_tickets(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                       page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
                       status: Optional[str] = None, in_warranty: Optional[bool] = None):
    q = select(ServiceTicket).options(selectinload(ServiceTicket.visits))
    if status:
        q = q.where(ServiceTicket.status == status)
    if in_warranty is not None:
        q = q.where(ServiceTicket.in_warranty == in_warranty)
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar() or 0
    res = await db.execute(q.order_by(ServiceTicket.opened_at.desc())
                           .offset((page - 1) * page_size).limit(page_size))
    return Page[ServiceTicketOut](
        items=[ServiceTicketOut.model_validate(t) for t in res.scalars().unique().all()],
        total=total, page=page, page_size=page_size,
    )


@router.post("/tickets", response_model=ServiceTicketOut, status_code=201)
async def create_ticket(payload: ServiceTicketCreate, user: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    # Generate code
    res = await db.execute(select(func.count(ServiceTicket.id)))
    n = (res.scalar() or 0) + 1
    code = _gen_code(datetime.utcnow().year, n)

    ticket = ServiceTicket(
        code=code,
        opened_at=datetime.utcnow(),
        created_by_id=user.id,
        **payload.model_dump(),
    )
    db.add(ticket)
    await db.commit()
    await db.refresh(ticket)
    return ticket


@router.patch("/tickets/{ticket_id}", response_model=ServiceTicketOut)
async def update_ticket(ticket_id: uuid.UUID, payload: ServiceTicketUpdate, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(ServiceTicket).where(ServiceTicket.id == ticket_id))
    t = res.scalar_one_or_none()
    if not t:
        raise HTTPException(404, "Ariza topilmadi")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(t, k, v)
    await db.commit()
    await db.refresh(t)
    return t


@router.post("/tickets/{ticket_id}/visits", response_model=ServiceVisitOut, status_code=201)
async def add_visit(ticket_id: uuid.UUID, payload: ServiceVisitIn, _: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    v = ServiceVisit(ticket_id=ticket_id, **payload.model_dump())
    db.add(v)
    await db.commit()
    await db.refresh(v)
    return v


@router.get("/warranty/{order_id}", response_model=WarrantyInfo)
async def get_warranty(order_id: uuid.UUID, _: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Order).where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    info = calculate_warranty(o)
    return WarrantyInfo(order_id=order_id, **info)
