"""Service tickets, visits, warranty."""
import uuid
from datetime import datetime, timezone
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.order import Order, OrderItem
from app.models.service import ServiceCategory, ServiceTicket, ServiceTrip, ServiceVisit
from app.schemas.common import Page
from app.schemas.service import (
    OrderMini, ServiceCategoryIn, ServiceCategoryOut, ServiceSummary, ServiceTicketCreate,
    ServiceTicketOut, ServiceTicketUpdate, ServiceTripOut, ServiceTripUpdate,
    ServiceVisitIn, ServiceVisitOut, WarrantyInfo,
)
from app.services.warranty_service import calculate_warranty

router = APIRouter(dependencies=[Depends(module_guard("service"))])


def _gen_code(year: int, n: int) -> str:
    return f"SRV-{year}-{n:05d}"


async def _get_full(db: AsyncSession, ticket_id: uuid.UUID) -> Optional[ServiceTicket]:
    res = await db.execute(
        select(ServiceTicket)
        .where(ServiceTicket.id == ticket_id)
        .options(
            selectinload(ServiceTicket.visits),
            selectinload(ServiceTicket.customer),
            selectinload(ServiceTicket.order),
        )
    )
    return res.scalar_one_or_none()


@router.get("/summary", response_model=ServiceSummary)
async def summary(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    rows = (await db.execute(
        select(ServiceTicket.status, func.count(ServiceTicket.id)).group_by(ServiceTicket.status)
    )).all()
    counts = {s: c for s, c in rows}
    open_statuses = ("new", "scheduled")
    in_warranty_open = (await db.execute(
        select(func.count(ServiceTicket.id)).where(
            ServiceTicket.in_warranty.is_(True),
            ServiceTicket.status.in_(open_statuses),
        )
    )).scalar() or 0
    return ServiceSummary(
        total=sum(counts.values()),
        new=counts.get("new", 0),
        scheduled=counts.get("scheduled", 0),
        completed=counts.get("completed", 0),
        cancelled=counts.get("cancelled", 0),
        in_warranty_open=in_warranty_open,
        with_visit=counts.get("scheduled", 0),
    )


# --------------------------------------------------------------------------- #
# Servis safari — barcha rejalashtirilgan arizalar bitta safar (3 ta umumiy summa)
# --------------------------------------------------------------------------- #
async def _scheduled_count(db: AsyncSession) -> int:
    return (await db.execute(
        select(func.count(ServiceTicket.id)).where(ServiceTicket.status == "scheduled")
    )).scalar() or 0


async def _open_trip(db: AsyncSession, user) -> ServiceTrip:
    trip = (await db.execute(
        select(ServiceTrip).where(ServiceTrip.status == "open")
        .order_by(ServiceTrip.opened_at.desc())
    )).scalars().first()
    if not trip:
        trip = ServiceTrip(status="open", opened_at=datetime.now(timezone.utc),
                           created_by_id=user.id)
        db.add(trip)
        await db.commit()
        await db.refresh(trip)
    return trip


def _trip_out(trip: ServiceTrip, scheduled: int) -> ServiceTripOut:
    out = ServiceTripOut.model_validate(trip)
    out.scheduled_count = scheduled
    return out


@router.get("/trips/current", response_model=ServiceTripOut)
async def current_trip(db: Annotated[AsyncSession, Depends(get_db)], user: CurrentUser):
    trip = await _open_trip(db, user)
    return _trip_out(trip, await _scheduled_count(db))


@router.get("/trips", response_model=list[ServiceTripOut])
async def list_trips(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                     limit: int = Query(20, ge=1, le=100)):
    rows = (await db.execute(
        select(ServiceTrip).where(ServiceTrip.status == "closed")
        .order_by(ServiceTrip.closed_at.desc()).limit(limit)
    )).scalars().all()
    return [_trip_out(r, 0) for r in rows]


@router.patch("/trips/{trip_id}", response_model=ServiceTripOut)
async def update_trip(trip_id: uuid.UUID, payload: ServiceTripUpdate, _: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    trip = (await db.execute(
        select(ServiceTrip).where(ServiceTrip.id == trip_id))).scalar_one_or_none()
    if not trip:
        raise HTTPException(404, "Safar topilmadi")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(trip, k, v)
    await db.commit()
    await db.refresh(trip)
    return _trip_out(trip, await _scheduled_count(db))


@router.post("/trips/{trip_id}/close", response_model=ServiceTripOut)
async def close_trip(trip_id: uuid.UUID, user: CurrentUser,
                     db: Annotated[AsyncSession, Depends(get_db)]):
    trip = (await db.execute(
        select(ServiceTrip).where(ServiceTrip.id == trip_id))).scalar_one_or_none()
    if not trip:
        raise HTTPException(404, "Safar topilmadi")
    trip.status = "closed"
    trip.closed_at = datetime.now(timezone.utc)
    trip.ticket_count = await _scheduled_count(db)
    await db.commit()
    # Keyingi safar uchun yangi ochiq yozuv
    new_trip = await _open_trip(db, user)
    return _trip_out(new_trip, await _scheduled_count(db))


@router.get("/tickets", response_model=Page[ServiceTicketOut])
async def list_tickets(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                       page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
                       status: Optional[str] = None, in_warranty: Optional[bool] = None,
                       customer_id: Optional[uuid.UUID] = None, search: Optional[str] = None):
    q = select(ServiceTicket).options(
        selectinload(ServiceTicket.visits),
        selectinload(ServiceTicket.customer),
        selectinload(ServiceTicket.order),
    )
    if status:
        q = q.where(ServiceTicket.status == status)
    if in_warranty is not None:
        q = q.where(ServiceTicket.in_warranty == in_warranty)
    if customer_id:
        q = q.where(ServiceTicket.customer_id == customer_id)
    if search:
        like = f"%{search}%"
        q = q.where(or_(ServiceTicket.code.ilike(like), ServiceTicket.problem.ilike(like)))
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar() or 0
    res = await db.execute(q.order_by(ServiceTicket.opened_at.desc())
                           .offset((page - 1) * page_size).limit(page_size))
    return Page[ServiceTicketOut](
        items=[ServiceTicketOut.model_validate(t) for t in res.scalars().unique().all()],
        total=total, page=page, page_size=page_size,
    )


@router.get("/tickets/{ticket_id}", response_model=ServiceTicketOut)
async def get_ticket(ticket_id: uuid.UUID, _: CurrentUser,
                     db: Annotated[AsyncSession, Depends(get_db)]):
    t = await _get_full(db, ticket_id)
    if not t:
        raise HTTPException(404, "Ariza topilmadi")
    return t


@router.post("/tickets", response_model=ServiceTicketOut, status_code=201)
async def create_ticket(payload: ServiceTicketCreate, user: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    data = payload.model_dump()

    # Buyurtma tanlangan bo'lsa — kafolatni yetkazib berilgan sanaga qarab
    # avtomatik aniqlaymiz (1-yil to'liq, 2-3 yil faqat ish tekin).
    if data.get("order_id"):
        order = (await db.execute(
            select(Order).where(Order.id == data["order_id"])
        )).scalar_one_or_none()
        if order:
            info = calculate_warranty(order)
            data["in_warranty"] = info["current_status"] in ("active_full", "active_service_only")
            if not data.get("address") and order.delivery_address:
                data["address"] = order.delivery_address

    # Kod generatsiya (yil bo'yicha tartib raqami)
    year = datetime.now(timezone.utc).year
    n = ((await db.execute(
        select(func.count(ServiceTicket.id)).where(ServiceTicket.code.like(f"SRV-{year}-%"))
    )).scalar() or 0) + 1
    code = _gen_code(year, n)

    ticket = ServiceTicket(
        code=code,
        opened_at=datetime.now(timezone.utc),
        status="new",
        created_by_id=user.id,
        **data,
    )
    db.add(ticket)
    await db.commit()
    return await _get_full(db, ticket.id)


@router.patch("/tickets/{ticket_id}", response_model=ServiceTicketOut)
async def update_ticket(ticket_id: uuid.UUID, payload: ServiceTicketUpdate, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    t = await _get_full(db, ticket_id)
    if not t:
        raise HTTPException(404, "Ariza topilmadi")
    changes = payload.model_dump(exclude_unset=True)
    for k, v in changes.items():
        setattr(t, k, v)
    # Bajarildi / Bekor qilindi — yopilgan sanani avtomatik belgilaymiz
    if changes.get("status") in ("completed", "cancelled") and not t.closed_at:
        t.closed_at = datetime.now(timezone.utc)
    if changes.get("status") in ("new", "scheduled"):
        t.closed_at = None
    await db.commit()
    return await _get_full(db, ticket_id)


@router.post("/tickets/{ticket_id}/visits", response_model=ServiceVisitOut, status_code=201)
async def add_visit(ticket_id: uuid.UUID, payload: ServiceVisitIn, _: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    t = (await db.execute(
        select(ServiceTicket).where(ServiceTicket.id == ticket_id)
    )).scalar_one_or_none()
    if not t:
        raise HTTPException(404, "Ariza topilmadi")
    v = ServiceVisit(ticket_id=ticket_id, **payload.model_dump())
    db.add(v)
    await db.commit()
    await db.refresh(v)
    return v


def _product_summary(order: Order) -> str:
    """Buyurtma mahsuloti nomi (masalan: 'OPTIMA 400 kvm'). Asosiy (kotyol)
    mahsulot ustun; bir nechta bo'lsa '+N' qo'shiladi."""
    items = list(order.items or [])
    withp = [i for i in items if i.product is not None]
    mains = [i for i in withp if i.product.product_type == "main"]
    chosen = mains or withp
    if not chosen:
        return ""
    first = chosen[0].product.display_name
    extra = len(chosen) - 1
    return first if extra <= 0 else f"{first} +{extra}"


@router.get("/orders", response_model=list[OrderMini])
async def customer_orders(customer_id: uuid.UUID, _: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    """Mijozning BARCHA buyurtmalari — servis arizasi uchun.

    Sotuvchi cheklovi (own_orders_only) qo'llanmaydi: servis xodimi kim
    sotganidan qat'i nazar mijozning hamma zakazlarini ko'rishi kerak.
    Yetkazilganlari (kafolati bori) yuqorida.
    """
    res = await db.execute(
        select(Order).where(Order.customer_id == customer_id)
        .options(selectinload(Order.items).selectinload(OrderItem.product))
        .order_by(Order.delivered_at.is_(None), Order.order_date.desc())
    )
    orders = res.scalars().unique().all()
    return [
        OrderMini(
            id=o.id, code=o.code, delivered_at=o.delivered_at, status=o.status,
            delivery_address=o.delivery_address, product_summary=_product_summary(o),
        )
        for o in orders
    ]


@router.get("/categories", response_model=list[ServiceCategoryOut])
async def list_categories(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(
        select(ServiceCategory).where(ServiceCategory.is_active.is_(True))
        .order_by(ServiceCategory.name)
    )
    return [ServiceCategoryOut.model_validate(c) for c in res.scalars().all()]


@router.post("/categories", response_model=ServiceCategoryOut, status_code=201)
async def create_category(payload: ServiceCategoryIn, _: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    name = payload.name.strip()
    if not name:
        raise HTTPException(400, "Nomi bo'sh bo'lishi mumkin emas")
    # Mavjud (faolsizlantirilgan) bo'lsa qayta faollashtiramiz
    existing = (await db.execute(
        select(ServiceCategory).where(func.lower(ServiceCategory.name) == name.lower())
    )).scalar_one_or_none()
    if existing:
        existing.is_active = True
        await db.commit()
        await db.refresh(existing)
        return existing
    c = ServiceCategory(name=name)
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


@router.delete("/categories/{category_id}", status_code=204)
async def delete_category(category_id: uuid.UUID, _: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    c = (await db.execute(
        select(ServiceCategory).where(ServiceCategory.id == category_id)
    )).scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Toifa topilmadi")
    c.is_active = False  # soft delete — eski arizalardagi toifa nomi saqlanib qoladi
    await db.commit()


@router.get("/warranty/{order_id}", response_model=WarrantyInfo)
async def get_warranty(order_id: uuid.UUID, _: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Order).where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    info = calculate_warranty(o)
    return WarrantyInfo(order_id=order_id, **info)
