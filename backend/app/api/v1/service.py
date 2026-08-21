"""Service tickets, visits, warranty."""
import re
import uuid
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core import settings_store
from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.customer import Customer
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.service import (
    ServiceCategory, ServicePart, ServiceTicket, ServiceTrip, ServiceVisit,
)
from app.schemas.common import Page
from app.schemas.service import (
    CustomerSearchHit, OrderMini, PartStat, ServiceCategoryIn, ServiceCategoryOut,
    ServiceCategoryReport, ServiceCategoryReportRow,
    ServiceRegionReport, ServiceRegionReportRow,
    ServiceExpenseItem, ServiceExternalTicketCreate, ServiceLocationIn,
    ServiceLocationRequestOut, ServicePartIn, ServicePartOut,
    ServiceSummary, ServiceTicketCreate, ServiceTicketOut, ServiceTicketUpdate,
    ServiceTripOut, ServiceTripUpdate, TripMoneyStat, ServiceVisitIn, ServiceVisitOut, WarrantyInfo,
)
from app.services import geo, service_location as loc
from app.services.warranty_service import calculate_warranty, warranty_from_date

router = APIRouter(dependencies=[Depends(module_guard("service"))])


def _gen_code(year: int, n: int) -> str:
    return f"SRV-{year}-{n:05d}"


async def _next_code(db: AsyncSession) -> str:
    """Navbatdagi ariza kodi (yil bo'yicha tartib raqami)."""
    year = datetime.now(timezone.utc).year
    n = ((await db.execute(
        select(func.count(ServiceTicket.id)).where(ServiceTicket.code.like(f"SRV-{year}-%"))
    )).scalar() or 0) + 1
    return _gen_code(year, n)


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


@router.get("/trips/stats", response_model=TripMoneyStat)
async def trips_stats(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                      date_from: Optional[date] = None, date_to: Optional[date] = None):
    """Servis safari moliyaviy statistikasi (yakunlangan safarlar bo'yicha).

    Vaqt filtri: safar yakunlangan sana (closed_at) bo'yicha.
    """
    ref = func.date(ServiceTrip.closed_at)
    q = select(
        func.coalesce(func.sum(ServiceTrip.collected), 0),
        func.coalesce(func.sum(ServiceTrip.spent), 0),
        func.count(ServiceTrip.id),
    ).where(ServiceTrip.status == "closed")
    if date_from:
        q = q.where(ref >= date_from)
    if date_to:
        q = q.where(ref <= date_to)
    collected, spent, cnt = (await db.execute(q)).one()

    # Har bir arizadagi "Servis xarajati" (client_cost) yig'indisi — ish bajarilgan
    # sana (closed_at, bo'lmasa opened_at) bo'yicha filtr (parts_stats bilan bir xil).
    tref = func.date(func.coalesce(ServiceTicket.closed_at, ServiceTicket.opened_at))
    sq = select(func.coalesce(func.sum(ServiceTicket.client_cost), 0))
    if date_from:
        sq = sq.where(tref >= date_from)
    if date_to:
        sq = sq.where(tref <= date_to)
    service_expenses = (await db.execute(sq)).scalar() or 0

    spent = spent or 0
    total_expenses = spent + service_expenses
    return TripMoneyStat(
        collected=collected, spent=spent,
        net=(collected or 0) - spent, trip_count=int(cnt),
        service_expenses=service_expenses, total_expenses=total_expenses,
    )


@router.get("/expenses", response_model=list[ServiceExpenseItem])
async def service_expenses_list(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
    limit: int = Query(500, ge=1, le=1000),
):
    """Har bir arizadagi 'Servis xarajati' (client_cost > 0) — hisobot ro'yxati.

    Vaqt filtri: ish bajarilgan sana (closed_at, bo'lmasa opened_at) — trips/stats
    dagi service_expenses bilan bir xil, shuning uchun ro'yxat yig'indisi umumiy
    'Servis xarajati' kartasiga to'liq mos keladi.
    """
    ref = func.date(func.coalesce(ServiceTicket.closed_at, ServiceTicket.opened_at))
    q = (
        select(ServiceTicket)
        .options(selectinload(ServiceTicket.customer))
        .where(ServiceTicket.client_cost > 0)
    )
    if date_from:
        q = q.where(ref >= date_from)
    if date_to:
        q = q.where(ref <= date_to)
    rows = (await db.execute(q.order_by(ref.desc()).limit(limit))).scalars().unique().all()
    out: list[ServiceExpenseItem] = []
    for t in rows:
        when = t.closed_at or t.opened_at
        out.append(ServiceExpenseItem(
            id=t.id, code=t.code,
            customer_name=t.customer.full_name if t.customer else None,
            customer_phone=t.customer.phone if t.customer else None,
            expense_date=when.date() if when else None,
            amount=t.client_cost, problem=t.problem, category=t.category,
            in_warranty=t.in_warranty,
        ))
    return out


# --------------------------------------------------------------------------- #
# Hisobot — barcha toifalar bo'yicha
# --------------------------------------------------------------------------- #
UNCATEGORIZED = "Toifasiz"
UNKNOWN_REGION = "Ko'rsatilmagan"


def _ticket_date_ref():
    """Ish bajarilgan sana (closed_at, bo'lmasa opened_at) — barcha servis
    hisobotlarida bir xil mezon ishlatiladi."""
    return func.date(func.coalesce(ServiceTicket.closed_at, ServiceTicket.opened_at))


def _region_expr():
    """Mijoz viloyati; bo'sh/NULL bo'lsa "Ko'rsatilmagan"."""
    return func.coalesce(func.nullif(func.btrim(Customer.region), ""), UNKNOWN_REGION)


def _category_expr():
    """Toifa nomi; bo'sh/NULL bo'lsa 'Toifasiz'."""
    return func.coalesce(func.nullif(func.btrim(ServiceTicket.category), ""), UNCATEGORIZED)


@router.get("/report", response_model=ServiceCategoryReport)
async def category_report(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    """Servis hisoboti — har bir toifa kesimida arizalar, holatlar, kafolat,
    servis xarajati va sarflangan ehtiyot qismlar.

    Arizasi yo'q (faol) toifalar ham nol qiymatlar bilan qaytariladi — hisobot
    «barcha toifalari bo'yicha» to'liq bo'lishi uchun.

    Vaqt filtri: ish bajarilgan sana (closed_at, bo'lmasa opened_at) — parts/stats
    va expenses bilan bir xil, shuning uchun summalar mos keladi.
    """
    ref = _ticket_date_ref()
    cat = _category_expr()
    conds = []
    if date_from:
        conds.append(ref >= date_from)
    if date_to:
        conds.append(ref <= date_to)

    parts_len = func.coalesce(func.jsonb_array_length(ServiceTicket.parts_used), 0)
    q = select(
        cat.label("category"),
        func.count(ServiceTicket.id).label("total"),
        func.count(ServiceTicket.id).filter(ServiceTicket.status == "new").label("new"),
        func.count(ServiceTicket.id).filter(ServiceTicket.status == "scheduled").label("scheduled"),
        func.count(ServiceTicket.id).filter(ServiceTicket.status == "completed").label("completed"),
        func.count(ServiceTicket.id).filter(ServiceTicket.status == "cancelled").label("cancelled"),
        func.count(ServiceTicket.id).filter(ServiceTicket.in_warranty.is_(True)).label("in_warranty"),
        func.coalesce(func.sum(ServiceTicket.client_cost), 0).label("client_cost"),
        func.coalesce(func.sum(parts_len), 0).label("parts_count"),
    ).group_by(cat)
    if conds:
        q = q.where(*conds)
    agg_rows = (await db.execute(q)).all()

    # Toifa × ehtiyot qism kesimi
    pbase = select(
        cat.label("category"),
        func.jsonb_array_elements_text(ServiceTicket.parts_used).label("name"),
    )
    if conds:
        pbase = pbase.where(*conds)
    psub = pbase.subquery()
    part_rows = (await db.execute(
        select(psub.c.category, psub.c.name, func.count().label("cnt"))
        .group_by(psub.c.category, psub.c.name)
        .order_by(func.count().desc(), psub.c.name)
    )).all()
    parts_by_cat: dict[str, list[PartStat]] = {}
    for c, n, cnt in part_rows:
        parts_by_cat.setdefault(c, []).append(PartStat(name=n, count=int(cnt)))

    rows: dict[str, ServiceCategoryReportRow] = {}
    for r in agg_rows:
        total = int(r.total)
        in_w = int(r.in_warranty)
        rows[r.category] = ServiceCategoryReportRow(
            category=r.category, total=total,
            new=int(r.new), scheduled=int(r.scheduled),
            completed=int(r.completed), cancelled=int(r.cancelled),
            in_warranty=in_w, out_warranty=total - in_w,
            client_cost=r.client_cost, parts_count=int(r.parts_count),
            parts=parts_by_cat.get(r.category, []),
        )

    # Arizasi yo'q faol toifalar ham ro'yxatda ko'rinsin
    active_names = (await db.execute(
        select(ServiceCategory.name).where(ServiceCategory.is_active.is_(True))
    )).scalars().all()
    for name in active_names:
        rows.setdefault(name, ServiceCategoryReportRow(category=name))

    # Ko'p arizali toifa yuqorida; "Toifasiz" doim oxirida
    ordered = sorted(
        rows.values(),
        key=lambda r: (r.category == UNCATEGORIZED, -r.total, r.category.lower()),
    )

    return ServiceCategoryReport(
        date_from=date_from, date_to=date_to,
        total=sum(r.total for r in ordered),
        new=sum(r.new for r in ordered),
        scheduled=sum(r.scheduled for r in ordered),
        completed=sum(r.completed for r in ordered),
        cancelled=sum(r.cancelled for r in ordered),
        in_warranty=sum(r.in_warranty for r in ordered),
        out_warranty=sum(r.out_warranty for r in ordered),
        client_cost=sum((r.client_cost for r in ordered), Decimal(0)),
        parts_count=sum(r.parts_count for r in ordered),
        rows=ordered,
    )


@router.get("/report/regions", response_model=ServiceRegionReport)
async def region_report(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    """Servis hisoboti — VILOYATLAR kesimida: qayerga ko'p chiqilyapti,
    qancha xarajat va qism ketyapti, qaysi muammo ustun.

    Viloyat mijoz kartochkasidan olinadi (ko'rsatilmagan bo'lsa alohida qator).
    Vaqt filtri toifalar hisoboti bilan bir xil — ish bajarilgan sana bo'yicha,
    shuning uchun ikkala hisobotdagi summalar mos keladi.
    """
    ref = _ticket_date_ref()
    reg = _region_expr()
    cat = _category_expr()
    conds = []
    if date_from:
        conds.append(ref >= date_from)
    if date_to:
        conds.append(ref <= date_to)

    parts_len = func.coalesce(func.jsonb_array_length(ServiceTicket.parts_used), 0)
    q = (
        select(
            reg.label("region"),
            func.count(ServiceTicket.id).label("total"),
            func.count(ServiceTicket.id).filter(ServiceTicket.status == "new").label("new"),
            func.count(ServiceTicket.id).filter(ServiceTicket.status == "scheduled").label("scheduled"),
            func.count(ServiceTicket.id).filter(ServiceTicket.status == "completed").label("completed"),
            func.count(ServiceTicket.id).filter(ServiceTicket.status == "cancelled").label("cancelled"),
            func.count(ServiceTicket.id).filter(ServiceTicket.in_warranty.is_(True)).label("in_warranty"),
            func.coalesce(func.sum(ServiceTicket.client_cost), 0).label("client_cost"),
            func.coalesce(func.sum(parts_len), 0).label("parts_count"),
            func.count(func.distinct(ServiceTicket.customer_id)).label("customers"),
        )
        .select_from(ServiceTicket)
        .join(Customer, Customer.id == ServiceTicket.customer_id)
        .group_by(reg)
    )
    if conds:
        q = q.where(*conds)
    agg_rows = (await db.execute(q)).all()

    # Har viloyatda eng ko'p uchragan muammo turi
    tq = (
        select(reg.label("region"), cat.label("category"), func.count().label("cnt"))
        .select_from(ServiceTicket)
        .join(Customer, Customer.id == ServiceTicket.customer_id)
        .group_by(reg, cat)
        # Teng bo'lsa alifbo bo'yicha — har so'rovda bir xil natija chiqsin
        .order_by(func.count().desc(), cat)
    )
    if conds:
        tq = tq.where(*conds)
    top_by_region: dict[str, str] = {}
    for region, category, _cnt in (await db.execute(tq)).all():
        top_by_region.setdefault(region, category)

    rows: list[ServiceRegionReportRow] = []
    for r in agg_rows:
        total = int(r.total)
        in_w = int(r.in_warranty)
        rows.append(ServiceRegionReportRow(
            region=r.region, total=total,
            new=int(r.new), scheduled=int(r.scheduled),
            completed=int(r.completed), cancelled=int(r.cancelled),
            in_warranty=in_w, out_warranty=total - in_w,
            client_cost=r.client_cost, parts_count=int(r.parts_count),
            customers=int(r.customers),
            top_category=top_by_region.get(r.region),
        ))

    # Ko'p arizali viloyat yuqorida; "Ko'rsatilmagan" doim oxirida
    rows.sort(key=lambda r: (r.region == UNKNOWN_REGION, -r.total, r.region.lower()))

    # Mijozlar sonini viloyatlar bo'yicha qo'shib bo'lmaydi (bitta mijoz bitta
    # viloyatda), lekin umumiy son alohida hisoblanadi — aniqroq bo'lsin.
    cq = select(func.count(func.distinct(ServiceTicket.customer_id)))
    if conds:
        cq = cq.where(*conds)
    total_customers = (await db.execute(cq)).scalar() or 0

    return ServiceRegionReport(
        date_from=date_from, date_to=date_to,
        total=sum(r.total for r in rows),
        completed=sum(r.completed for r in rows),
        in_warranty=sum(r.in_warranty for r in rows),
        out_warranty=sum(r.out_warranty for r in rows),
        client_cost=sum((r.client_cost for r in rows), Decimal(0)),
        parts_count=sum(r.parts_count for r in rows),
        customers=int(total_customers),
        rows=rows,
    )


@router.get("/trips", response_model=list[ServiceTripOut])
async def list_trips(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                     date_from: Optional[date] = None, date_to: Optional[date] = None,
                     limit: int = Query(200, ge=1, le=500)):
    q = select(ServiceTrip).where(ServiceTrip.status == "closed")
    ref = func.date(ServiceTrip.closed_at)
    if date_from:
        q = q.where(ref >= date_from)
    if date_to:
        q = q.where(ref <= date_to)
    rows = (await db.execute(
        q.order_by(ServiceTrip.closed_at.desc()).limit(limit)
    )).scalars().all()
    return [_trip_out(r, 0) for r in rows]


@router.get("/trips/{trip_id}/tickets", response_model=list[ServiceTicketOut])
async def trip_tickets(trip_id: uuid.UUID, _: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    """Shu safarda borilgan (bog'langan) arizalar ro'yxati."""
    q = (
        select(ServiceTicket)
        .options(
            selectinload(ServiceTicket.visits),
            selectinload(ServiceTicket.customer),
            selectinload(ServiceTicket.order),
        )
        .where(ServiceTicket.trip_id == trip_id)
        .order_by(ServiceTicket.opened_at.desc())
    )
    rows = (await db.execute(q)).scalars().unique().all()
    return [ServiceTicketOut.model_validate(t) for t in rows]


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
    now = datetime.now(timezone.utc)
    # Shu safardagi BARCHA rejalashtirilgan arizalar avtomatik "bajarildi" ga o'tadi
    # va safarga bog'lanadi (yaxlit yozuv uchun).
    scheduled = (await db.execute(
        select(ServiceTicket).where(ServiceTicket.status == "scheduled"))).scalars().all()
    for tk in scheduled:
        tk.status = "completed"
        tk.trip_id = trip.id
        if not tk.closed_at:
            tk.closed_at = now
    trip.status = "closed"
    trip.closed_at = now
    trip.ticket_count = len(scheduled)
    await db.commit()
    # Keyingi safar uchun yangi ochiq yozuv
    new_trip = await _open_trip(db, user)
    return _trip_out(new_trip, await _scheduled_count(db))


@router.get("/tickets", response_model=Page[ServiceTicketOut])
async def list_tickets(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                       page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
                       status: Optional[str] = None, in_warranty: Optional[bool] = None,
                       customer_id: Optional[uuid.UUID] = None, search: Optional[str] = None,
                       has_location: Optional[bool] = None):
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
    if has_location is not None:
        q = q.where(ServiceTicket.lat.isnot(None) if has_location
                    else ServiceTicket.lat.is_(None))
    if search:
        like = f"%{search}%"
        q = q.where(or_(ServiceTicket.code.ilike(like), ServiceTicket.problem.ilike(like),
                        ServiceTicket.ext_product.ilike(like)))
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


async def _apply_new_location(ticket: ServiceTicket, raw: str, note: str, user_id) -> None:
    """Ariza ochilayotganda kiritilgan lokatsiya (ixtiyoriy).

    Koordinata topilmasa ham ariza yaratilaveradi — kiritilgan matn/havola
    `location_url` da saqlanadi va kartochkada qayta urinish mumkin. Ariza
    yo'qolishidan ko'ra lokatsiyasiz ochilgani afzal.
    """
    raw = (raw or "").strip()
    note = (note or "").strip()
    if not raw and not note:
        return
    coords = await geo.resolve_coords(raw) if raw else None
    if coords:
        loc.set_location(
            ticket, coords,
            source=loc.SOURCE_LINK if raw.lower().startswith("http") else loc.SOURCE_MANUAL,
            url=raw if raw.lower().startswith("http") else None,
            note=note or None, user_id=user_id,
        )
    else:
        ticket.location_url = raw or None
        ticket.location_note = note or None


@router.post("/tickets", response_model=ServiceTicketOut, status_code=201)
async def create_ticket(payload: ServiceTicketCreate, user: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    data = payload.model_dump()
    location_raw = data.pop("location_raw", None)
    location_note = data.pop("location_note", None)

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

    code = await _next_code(db)

    ticket = ServiceTicket(
        code=code,
        opened_at=datetime.now(timezone.utc),
        status="new",
        created_by_id=user.id,
        **data,
    )
    await _apply_new_location(ticket, location_raw, location_note, user.id)
    db.add(ticket)
    await db.commit()
    return await _get_full(db, ticket.id)


@router.post("/tickets/external", response_model=ServiceTicketOut, status_code=201)
async def create_external_ticket(payload: ServiceExternalTicketCreate, user: CurrentUser,
                                 db: Annotated[AsyncSession, Depends(get_db)]):
    """"0 dan" ariza — buyurtmasiz servis arizasi.

    Mijoz ikki yo'l bilan aniqlanadi:
      * `customer_id` berilsa — mavjud mijoz (oddiy modaldagi "buyurtmasiz
        ariza" oqimi), ma'lumotlari o'zgartirilmaydi;
      * aks holda telefon raqami (faqat raqamlar solishtiriladi) bo'yicha
        qidiriladi — topilsa o'shanga bog'lanadi, topilmasa yangi mijoz
        yaratiladi (source='dealer_client' — dillerdan olgan mijoz).
    """
    full_name = (payload.full_name or "").strip()
    phone = (payload.phone or "").strip()
    problem = (payload.problem or "").strip()
    if not problem and not payload.category:
        raise HTTPException(400, "Muammo yozing yoki toifani tanlang")

    customer: Optional[Customer] = None

    if payload.customer_id:
        # 1a) Mavjud mijoz — buyurtmasiz ariza
        customer = (await db.execute(
            select(Customer).where(Customer.id == payload.customer_id)
        )).scalar_one_or_none()
        if customer is None:
            raise HTTPException(404, "Mijoz topilmadi")
    else:
        # 1b) Yangi mijoz — telefon raqami bo'yicha mavjudini topamiz (dublikat bo'lmasin)
        if not full_name:
            raise HTTPException(400, "Ism-familiya majburiy")
        if not phone:
            raise HTTPException(400, "Telefon raqami majburiy")
        digits = re.sub(r"\D", "", phone)
        if digits:
            customer = (await db.execute(
                select(Customer).where(
                    func.regexp_replace(Customer.phone, "[^0-9]", "", "g") == digits
                ).order_by(Customer.created_at).limit(1)
            )).scalars().first()

    if customer is None:
        customer = Customer(
            full_name=full_name,
            phone=phone,
            phone2=(payload.phone2 or "").strip() or None,
            country=(payload.country or "Uzbekistan").strip() or "Uzbekistan",
            region=(payload.region or "").strip() or None,
            city=(payload.city or "").strip() or None,
            address=(payload.address or "").strip() or None,
            source="dealer_client",
            note=(payload.note or "").strip() or None,
            created_by_id=user.id,
        )
        db.add(customer)
        await db.flush()
    elif not payload.customer_id:
        # Telefon bo'yicha topilgan mijozning bo'sh maydonlarini to'ldiramiz
        # (mavjud ma'lumot o'chmaydi). customer_id berilganda tegilmaydi.
        if not customer.address and payload.address:
            customer.address = payload.address.strip()
        if not customer.region and payload.region:
            customer.region = payload.region.strip()
        if not customer.city and payload.city:
            customer.city = payload.city.strip()
        if not customer.phone2 and payload.phone2:
            customer.phone2 = payload.phone2.strip()

    # 2) Kafolat — sotib olingan sanadan avtomatik (qo'lda belgilangan bo'lsa — o'sha)
    if payload.in_warranty is None:
        info = warranty_from_date(payload.purchase_date)
        in_warranty = info["current_status"] in ("active_full", "active_service_only")
    else:
        in_warranty = payload.in_warranty

    ticket = ServiceTicket(
        code=await _next_code(db),
        customer_id=customer.id,
        order_id=None,
        serial_id=(payload.serial_id or "").strip() or None,
        address=(payload.address or "").strip() or customer.address,
        problem=problem or (payload.category or ""),
        category=payload.category or None,
        opened_at=datetime.now(timezone.utc),
        status="new",
        in_warranty=in_warranty,
        is_external=True,
        ext_product=(payload.ext_product or "").strip() or None,
        purchase_date=payload.purchase_date,
        ext_seller=(payload.ext_seller or "").strip() or None,
        created_by_id=user.id,
    )
    await _apply_new_location(ticket, payload.location_raw, payload.location_note, user.id)
    db.add(ticket)
    await db.commit()
    return await _get_full(db, ticket.id)


@router.get("/product-models", response_model=list[str])
async def product_models(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    """Katalogdagi asosiy mahsulot modellari — "0 dan" arizada tanlash uchun.

    (/products endpointi alohida ruxsat talab qilgani uchun servis moduli
    o'zining yengil ro'yxatini beradi.)
    """
    rows = (await db.execute(
        select(Product.model, Product.kvm)
        .where(Product.product_type == "main", Product.status == "active",
               Product.model.is_not(None))
        .distinct()
        .order_by(Product.model, Product.kvm)
    )).all()
    names: list[str] = []
    for model, kvm in rows:
        name = f"{model} {kvm} kvm" if kvm else str(model)
        if name not in names:
            names.append(name)
    return names


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


# --------------------------------------------------------------------------- #
# Borish lokatsiyasi — har arizaga alohida (mijozga doimiy biriktirilmaydi)
# --------------------------------------------------------------------------- #
@router.patch("/tickets/{ticket_id}/location", response_model=ServiceTicketOut)
async def set_ticket_location(ticket_id: uuid.UUID, payload: ServiceLocationIn,
                              user: CurrentUser,
                              db: Annotated[AsyncSession, Depends(get_db)]):
    """Lokatsiyani biriktirish/almashtirish.

    Kiritish mumkin: xarita havolasi (Google/Yandex/2GIS/Apple, qisqartirilgani
    ham), "41.311, 69.240" ko'rinishidagi koordinata yoki tayyor lat/lon.
    """
    t = await _get_full(db, ticket_id)
    if not t:
        raise HTTPException(404, "Ariza topilmadi")

    coords = None
    source = loc.SOURCE_MANUAL
    url = None

    if payload.lat is not None and payload.lon is not None:
        if not geo.valid_coords(payload.lat, payload.lon):
            raise HTTPException(400, "Koordinata noto'g'ri")
        coords = geo.Coords(lat=round(payload.lat, 7), lon=round(payload.lon, 7))
    elif payload.raw and payload.raw.strip():
        raw = payload.raw.strip()
        coords = await geo.resolve_coords(raw)
        if not coords:
            raise HTTPException(
                400,
                "Havoladan lokatsiya topilmadi. Havolani xaritada ochib, uzun "
                "(to'liq) havolani nusxalang yoki koordinatani yozing: 41.311, 69.240",
            )
        if raw.lower().startswith("http"):
            source, url = loc.SOURCE_LINK, raw
    elif t.lat is None:
        raise HTTPException(400, "Lokatsiya havolasi yoki koordinatani kiriting")

    if coords:
        loc.set_location(t, coords, source=source, url=url,
                         note=payload.note, user_id=user.id)
    elif payload.note is not None:
        # Faqat mo'ljalni tahrirlash (lokatsiya allaqachon bor)
        t.location_note = payload.note.strip() or None

    await db.commit()
    return await _get_full(db, ticket_id)


@router.delete("/tickets/{ticket_id}/location", response_model=ServiceTicketOut)
async def delete_ticket_location(ticket_id: uuid.UUID, _: CurrentUser,
                                 db: Annotated[AsyncSession, Depends(get_db)]):
    t = await _get_full(db, ticket_id)
    if not t:
        raise HTTPException(404, "Ariza topilmadi")
    loc.clear_location(t)
    await db.commit()
    return await _get_full(db, ticket_id)


@router.post("/tickets/{ticket_id}/location-request", response_model=ServiceLocationRequestOut)
async def request_ticket_location(ticket_id: uuid.UUID, user: CurrentUser,
                                  db: Annotated[AsyncSession, Depends(get_db)]):
    """"Lokatsiya kutilmoqda" oynasini ochadi.

    Shundan keyin xodim botga forward qilgan birinchi lokatsiya aynan shu
    arizaga tushadi — botda ariza tanlash shart emas.
    """
    t = (await db.execute(
        select(ServiceTicket).where(ServiceTicket.id == ticket_id)
    )).scalar_one_or_none()
    if not t:
        raise HTTPException(404, "Ariza topilmadi")
    if not user.telegram_chat_id:
        raise HTTPException(
            400,
            "Telegram akkauntingiz profilingizga bog'lanmagan. Botga /id yozing "
            "va chiqqan raqamni Foydalanuvchilar bo'limida profilingizga qo'shing.",
        )
    req = await loc.create_request(db, t.id, user.id)
    # Bot nomi — Tizim sozlamalaridan (bo'sh bo'lsa .env zaxirasi)
    username = (await settings_store.get_value(db, "ERP_BOT_USERNAME")).strip().lstrip("@")
    return ServiceLocationRequestOut(
        ticket_id=t.id, ticket_code=t.code, expires_at=req.expires_at,
        bot_username=username or None,
        deep_link=f"https://t.me/{username}?start=loc" if username else None,
    )


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


@router.get("/customer-search", response_model=list[CustomerSearchHit])
async def customer_search(
    _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
    q: str = Query(..., min_length=1), limit: int = Query(8, ge=1, le=20),
):
    """Servis arizasi uchun kengaytirilgan qidiruv: mijoz ismi, telefon raqami
    (ajratgichlardan qat'i nazar — faqat raqamlar solishtiriladi, masalan "2233"
    ham "22 33" ham topadi) yoki buyurtma ID (kodi) bo'yicha.

    Buyurtma kodi bo'yicha topilganda natijaga o'sha buyurtma biriktiriladi —
    modalда mijoz + buyurtma avtomatik tanlanadi.
    """
    term = q.strip()
    if not term:
        return []
    like = f"%{term}%"
    digits = re.sub(r"\D", "", term)

    hits: list[CustomerSearchHit] = []
    seen: set[uuid.UUID] = set()

    # 1) Buyurtma kodi bo'yicha — mos buyurtma va uning egasi (avtomatik tanlash uchun)
    order_rows = (await db.execute(
        select(Order)
        .options(selectinload(Order.items).selectinload(OrderItem.product))
        .where(Order.code.ilike(like))
        .order_by(Order.order_date.desc())
        .limit(limit)
    )).scalars().unique().all()
    cust_ids = {o.customer_id for o in order_rows}
    cust_map: dict[uuid.UUID, Customer] = {}
    if cust_ids:
        crows = (await db.execute(
            select(Customer).where(Customer.id.in_(cust_ids))
        )).scalars().all()
        cust_map = {c.id: c for c in crows}
    for o in order_rows:
        c = cust_map.get(o.customer_id)
        if not c or c.id in seen:
            continue
        hits.append(CustomerSearchHit(
            customer_id=c.id, full_name=c.full_name, phone=c.phone, address=c.address,
            order_id=o.id, order_code=o.code, product_summary=_product_summary(o),
        ))
        seen.add(c.id)

    # 2) Mijoz ismi yoki telefon raqami (raqamlar bo'yicha) — buyurtmasiz
    conds = [Customer.full_name.ilike(like)]
    if digits:
        conds.append(
            func.regexp_replace(Customer.phone, "[^0-9]", "", "g").ilike(f"%{digits}%")
        )
    crows = (await db.execute(
        select(Customer).where(or_(*conds))
        .order_by(Customer.created_at.desc()).limit(limit)
    )).scalars().all()
    for c in crows:
        if c.id in seen:
            continue
        hits.append(CustomerSearchHit(
            customer_id=c.id, full_name=c.full_name, phone=c.phone, address=c.address,
        ))
        seen.add(c.id)

    return hits


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


# --------------------------------------------------------------------------- #
# Ehtiyot qismlar katalogi (timer, nasos, motor, ...)
# --------------------------------------------------------------------------- #
@router.get("/parts", response_model=list[ServicePartOut])
async def list_parts(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(
        select(ServicePart).where(ServicePart.is_active.is_(True))
        .order_by(ServicePart.name)
    )
    return [ServicePartOut.model_validate(p) for p in res.scalars().all()]


@router.get("/parts/stats", response_model=list[PartStat])
async def parts_stats(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                      date_from: Optional[date] = None, date_to: Optional[date] = None):
    """Ehtiyot qismlar statistikasi — qaysi qismdan jami nechta sarflangan.

    Vaqt filtri: ish bajarilgan sana (closed_at, bo'lmasa opened_at) bo'yicha.
    """
    ref = func.date(func.coalesce(ServiceTicket.closed_at, ServiceTicket.opened_at))
    base = select(func.jsonb_array_elements_text(ServiceTicket.parts_used).label("name"))
    if date_from:
        base = base.where(ref >= date_from)
    if date_to:
        base = base.where(ref <= date_to)
    sub = base.subquery()
    rows = (await db.execute(
        select(sub.c.name, func.count().label("cnt"))
        .group_by(sub.c.name).order_by(func.count().desc(), sub.c.name)
    )).all()
    return [PartStat(name=n, count=int(c)) for n, c in rows]


@router.post("/parts", response_model=ServicePartOut, status_code=201)
async def create_part(payload: ServicePartIn, _: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    name = payload.name.strip()
    if not name:
        raise HTTPException(400, "Nomi bo'sh bo'lishi mumkin emas")
    existing = (await db.execute(
        select(ServicePart).where(func.lower(ServicePart.name) == name.lower())
    )).scalar_one_or_none()
    if existing:
        existing.is_active = True
        await db.commit()
        await db.refresh(existing)
        return existing
    p = ServicePart(name=name)
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return p


@router.delete("/parts/{part_id}", status_code=204)
async def delete_part(part_id: uuid.UUID, _: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    p = (await db.execute(
        select(ServicePart).where(ServicePart.id == part_id)
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Ehtiyot qism topilmadi")
    p.is_active = False  # soft delete — eski arizalardagi qism nomi saqlanib qoladi
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
