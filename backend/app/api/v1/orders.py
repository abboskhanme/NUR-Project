"""Sales orders, items, payments."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import select, func, or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import CurrentUser
from app.core.permissions import has_special, module_guard, require_permission
from app.db.session import get_db
from app.models.customer import Customer
from app.models.order import Order, OrderItem, Payment
from app.models.product import Inventory
from app.models.user import User
from app.schemas.common import Page
from app.schemas.order import (
    OrderCreate, OrderOut, OrderStatusChange, OrderUpdate, UnitUidUpdate,
    SalespersonUpdate, SalespersonOption, OverrideAmounts,
    PaymentIn, PaymentOut, SalesSummary, SalespersonCount, QueueItemOut, QueueMove, QueueAdd,
)
from app.services.order_service import generate_order_code, is_valid_transition
from app.services import pdf_service
from app.services import excel_service

XLSX_MEDIA = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

router = APIRouter(dependencies=[Depends(module_guard("orders", exempt=("/payments",)))])

# Navbatdagi (hali yopilmagan) buyurtma statuslari
ACTIVE_QUEUE_STATUSES = ("new", "ready")


def _own_only(current) -> bool:
    # QURISH BOSQICHI: hozircha hamma foydalanuvchi barcha buyurtmalarni ko'radi,
    # kim sotganidan qat'i nazar. Rolelar tayyor bo'lgach, pastdagi qatorni
    # o'chirib, "own_orders_only" ruxsati orqali cheklovni qayta yoqish mumkin.
    return False
    role_perms: dict = {}  # noqa: F841 (kelajakda rolelar uchun)
    for r in (current.roles or []):
        role_perms.update(r.permissions or {})
    return bool(role_perms.get("own_orders_only"))


def _discount_uzs(discount_usd: Decimal, rate: Decimal) -> Decimal:
    """Chegirmaning UZS ekvivalenti — dollar chegirma × valyuta kursi."""
    return (discount_usd or Decimal(0)) * (rate or Decimal(0))


def _check_discount(price_usd: Decimal, qty: int, discount_usd: Decimal, idx: int = 0) -> None:
    """Chegirma ($) mahsulot summasidan ($ × soni) oshmasligi kerak."""
    discount_usd = discount_usd or Decimal(0)
    if discount_usd < 0:
        raise HTTPException(422, "Chegirma manfiy bo'lishi mumkin emas")
    subtotal = (price_usd or Decimal(0)) * (qty or 1)
    if discount_usd > subtotal:
        raise HTTPException(
            422,
            f"Chegirma mahsulot summasidan oshib ketdi ({idx + 1}-qator): "
            f"chegirma ${discount_usd:,.2f}, mahsulot summasi ${subtotal:,.2f}",
        )


async def _set_inventory_status(db: AsyncSession, inventory_id: Optional[uuid.UUID], status: str):
    """Move a SKLAD KATYOL unit to a new status (available/reserved/sold)."""
    if not inventory_id:
        return
    res = await db.execute(select(Inventory).where(Inventory.id == inventory_id))
    inv = res.scalar_one_or_none()
    if inv:
        inv.status = status


# "berilmagan" va "bo'sh (None)" ni ajratish uchun sentinel — unit_uid=None
# bog'lanishni uzish degani, yo'qligi esa o'zgartirmaslik.
_UNSET = object()


async def _find_unit_by_uid(db: AsyncSession, uid: Optional[str]) -> Optional[Inventory]:
    if not uid:
        return None
    return (await db.execute(
        select(Inventory).where(Inventory.unique_id == uid))).scalar_one_or_none()


async def _free_unit_by_uid(db: AsyncSession, uid: Optional[str]) -> None:
    """Ombor birligini (ID raqami bo'yicha) «bo'sh» holatga qaytaradi."""
    inv = await _find_unit_by_uid(db, uid)
    if inv and inv.status != "available":
        inv.status = "available"


async def _link_unit(db: AsyncSession, order: Order, uid: Optional[str]) -> None:
    """Buyurtmani ombor birligiga FAQAT ID raqami orqali bog'laydi.

    uid bo'sh -> bog'lanish uziladi (eski birlik bo'shaydi). Aks holda
    ombor birligi mavjud va bo'sh bo'lishi shart (model mosligi tekshirilmaydi).
    """
    new_uid = (uid or "").strip() or None
    old_uid = order.unit_uid
    if new_uid == old_uid:
        return
    # Eski birlikni bo'shatamiz
    if old_uid:
        await _free_unit_by_uid(db, old_uid)
    if not new_uid:
        order.unit_uid = None
        order.inventory_id = None
        return
    inv = await _find_unit_by_uid(db, new_uid)
    if not inv:
        raise HTTPException(422, f"«{new_uid}» ID ombor ro'yxatida yo'q")
    # Boshqa aktiv buyurtma allaqachon band qilgan bo'lsa
    other = (await db.execute(
        select(Order.code).where(
            Order.unit_uid == new_uid, Order.id != order.id,
            Order.status.notin_(("delivered", "rejected"))).limit(1)
    )).scalar_one_or_none()
    if other:
        raise HTTPException(400, f"«{new_uid}» ID allaqachon band ({other})")
    order.unit_uid = new_uid
    order.inventory_id = inv.id
    inv.status = "reserved"


async def _delete_linked_unit(db: AsyncSession, order: Order) -> None:
    """Yetkazilganda — bog'langan ombor birligini o'chiradi.

    unit_uid snapshot buyurtmada qoladi (ID raqami ko'rinib turishi uchun),
    faqat inventory_id NULL bo'ladi.
    """
    inv = None
    if order.inventory_id:
        inv = (await db.execute(
            select(Inventory).where(Inventory.id == order.inventory_id))).scalar_one_or_none()
    if inv is None and order.unit_uid:
        inv = await _find_unit_by_uid(db, order.unit_uid)
    if inv is not None:
        await db.delete(inv)
    order.inventory_id = None


def _order_query():
    return select(Order).options(
        selectinload(Order.items).selectinload(OrderItem.product),
        selectinload(Order.payments),
        selectinload(Order.customer),
        selectinload(Order.inventory),
    )


def _apply_filters(q, current, status, salesperson_id, customer_id, date_from, date_to, search):
    """list_orders va summary uchun bir xil filtrlar."""
    if _own_only(current):
        q = q.where(Order.salesperson_id == current.id)
    if status:
        q = q.where(Order.status == status)
    if salesperson_id:
        q = q.where(Order.salesperson_id == salesperson_id)
    if customer_id:
        q = q.where(Order.customer_id == customer_id)
    if date_from:
        q = q.where(Order.order_date >= date_from)
    if date_to:
        q = q.where(Order.order_date <= date_to)
    if search:
        # Kod, mijoz ismi va telefon raqami bo'yicha qidiruv.
        # Telefon uchun ikkala tomondan ham bo'shliq/+/- belgilarini olib tashlab solishtiramiz,
        # shunda "907008090" ham, "+998 90 700 80 90" ham topiladi.
        s = f"%{search.strip()}%"

        def _norm(col):
            return func.replace(func.replace(func.replace(
                func.coalesce(col, ""), " ", ""), "-", ""), "+", "")

        conds = [Order.code.ilike(s), Customer.full_name.ilike(s)]
        digits = "".join(ch for ch in search if ch.isdigit())
        if digits:
            conds.append(_norm(Customer.phone).like(f"%{digits}%"))
            conds.append(_norm(Customer.phone2).like(f"%{digits}%"))
        q = q.outerjoin(Customer, Order.customer_id == Customer.id).where(or_(*conds))
    return q


@router.get("", response_model=Page[OrderOut])
async def list_orders(
    db: Annotated[AsyncSession, Depends(get_db)], current: CurrentUser,
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = None,
    salesperson_id: Optional[uuid.UUID] = None,
    customer_id: Optional[uuid.UUID] = None,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
    search: Optional[str] = None,
):
    q = _apply_filters(_order_query(), current, status, salesperson_id,
                       customer_id, date_from, date_to, search)
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar() or 0
    res = await db.execute(q.order_by(Order.order_date.desc(), Order.created_at.desc())
                            .offset((page - 1) * page_size).limit(page_size))
    items = res.scalars().unique().all()

    # Navbat pozitsiyalari: FAQAT "new" (navbatda) statusdagi buyurtmalar uchun.
    # "Tayyor bo'ldi" va boshqa statuslar navbatda hisoblanmaydi.
    pos_map: dict[uuid.UUID, int] = {}
    if any(o.in_queue for o in items):
        qq = select(Order.id).where(Order.in_queue.is_(True)).where(
            Order.status.notin_(("delivered", "rejected")))
        if _own_only(current):
            qq = qq.where(Order.salesperson_id == current.id)
        qq = qq.order_by(Order.priority.desc(), Order.pickup_date.asc().nulls_last(),
                         Order.order_date.asc(), Order.created_at.asc())
        queue_ids = (await db.execute(qq)).scalars().all()
        pos_map = {oid: i for i, oid in enumerate(queue_ids, start=1)}

    # Sotuvchi ismlarini bir so'rovda yuklab, embed qilamiz (ro'yxatda bosh harflar uchun)
    sp_ids = {o.salesperson_id for o in items if o.salesperson_id}
    sp_names: dict[uuid.UUID, str] = {}
    if sp_ids:
        sr = await db.execute(select(User.id, User.full_name).where(User.id.in_(sp_ids)))
        sp_names = {i: n for i, n in sr.all()}

    out = []
    for o in items:
        m = OrderOut.model_validate(o)
        m.queue_position = pos_map.get(o.id)
        m.salesperson_name = sp_names.get(o.salesperson_id)
        out.append(m)
    return Page[OrderOut](items=out, total=total, page=page, page_size=page_size)


@router.get("/summary", response_model=SalesSummary)
async def sales_summary(
    db: Annotated[AsyncSession, Depends(get_db)], current: CurrentUser,
    status: Optional[str] = None,
    salesperson_id: Optional[uuid.UUID] = None,
    customer_id: Optional[uuid.UUID] = None,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
    search: Optional[str] = None,
):
    # Tanlangan filtrga mos asosiy so'rov — barcha ko'rsatkichlar shunga qarab hisoblanadi
    base = _apply_filters(select(Order), current, status, salesperson_id,
                          customer_id, date_from, date_to, search)
    order_ids = select(base.with_only_columns(Order.id).subquery().c.id)

    status_rows = (await db.execute(
        _apply_filters(select(Order.status, func.count(Order.id)), current, status,
                       salesperson_id, customer_id, date_from, date_to, search)
        .group_by(Order.status)
    )).all()
    status_counts = {s: c for s, c in status_rows}
    total_orders = sum(status_counts.values())

    paid_expr = func.coalesce(func.sum(func.coalesce(func.nullif(Payment.amount_uzs_equiv, 0), Payment.amount)), 0)

    revenue_total = (await db.execute(
        select(func.coalesce(func.sum(OrderItem.total_uzs), 0)).where(OrderItem.order_id.in_(order_ids))
    )).scalar() or Decimal(0)

    paid_total = (await db.execute(
        select(paid_expr).where(Payment.order_id.in_(order_ids))
    )).scalar() or Decimal(0)

    today = date.today()
    month_start = today.replace(day=1)
    month_base = base.where(Order.order_date >= month_start)
    month_ids = select(month_base.with_only_columns(Order.id).subquery().c.id)
    month_orders = (await db.execute(select(func.count()).select_from(month_base.subquery()))).scalar() or 0
    month_revenue = (await db.execute(
        select(func.coalesce(func.sum(OrderItem.total_uzs), 0)).where(OrderItem.order_id.in_(month_ids))
    )).scalar() or Decimal(0)
    month_paid = (await db.execute(
        select(paid_expr).where(Payment.order_id.in_(month_ids)).where(Payment.date >= month_start)
    )).scalar() or Decimal(0)

    # Sotuvchilar bo'yicha zakaz soni (joriy filtr) — ko'pdan kamga
    sp_q = _apply_filters(
        select(User.id, User.full_name, func.count(Order.id))
        .select_from(Order).join(User, User.id == Order.salesperson_id),
        current, status, salesperson_id, customer_id, date_from, date_to, search,
    ).group_by(User.id, User.full_name)
    sp_rows = (await db.execute(sp_q)).all()
    salesperson_counts = sorted(
        (SalespersonCount(salesperson_id=i, name=n, count=int(c)) for i, n, c in sp_rows),
        key=lambda r: r.count, reverse=True,
    )

    return SalesSummary(
        total_orders=total_orders,
        status_counts=status_counts,
        salesperson_counts=salesperson_counts,
        revenue_total=revenue_total,
        paid_total=paid_total,
        outstanding_total=(revenue_total or Decimal(0)) - (paid_total or Decimal(0)),
        month_orders=month_orders,
        month_revenue=month_revenue,
        month_paid=month_paid,
    )


# ---- Excel eksport (declared before /{order_id}) ----
@router.get("/export.xlsx")
async def export_orders_xlsx(
    db: Annotated[AsyncSession, Depends(get_db)], current: CurrentUser,
    status: Optional[str] = None,
    salesperson_id: Optional[uuid.UUID] = None,
    customer_id: Optional[uuid.UUID] = None,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
    search: Optional[str] = None,
):
    """Joriy filtrlarga mos buyurtmalar ro'yxatini Excel (xlsx) ga chiqaradi."""
    q = _apply_filters(_order_query(), current, status, salesperson_id,
                       customer_id, date_from, date_to, search)
    q = q.order_by(Order.order_date.desc(), Order.created_at.desc()).limit(5000)
    res = await db.execute(q)
    orders = res.scalars().unique().all()
    data = excel_service.orders_workbook(orders)
    today = date.today().strftime("%Y-%m-%d")
    return Response(
        content=data, media_type=XLSX_MEDIA,
        headers={"Content-Disposition": f'attachment; filename="buyurtmalar-{today}.xlsx"'},
    )


# ---- Queue (Navbat) ----  (declared before /{order_id})
async def _load_queue(db: AsyncSession, current) -> list[Order]:
    q = _order_query().where(Order.in_queue.is_(True)).where(
        Order.status.notin_(("delivered", "rejected")))
    if _own_only(current):
        q = q.where(Order.salesperson_id == current.id)
    q = q.order_by(Order.priority.desc(), Order.pickup_date.asc().nulls_last(),
                   Order.order_date.asc(), Order.created_at.asc())
    res = await db.execute(q)
    return list(res.scalars().unique().all())


def _queue_out(orders: list[Order]) -> list[QueueItemOut]:
    """Navbat raqami FAQAT "new" statusdagilar uchun beriladi —
    sotuv jadvalidagi queue_position bilan bir xil.
    "Tayyor bo'ldi" buyurtmalar navbatda hisoblanmaydi (position = 0)."""
    out = []
    n = 0
    for o in orders:
        item = QueueItemOut.model_validate(o)
        n += 1
        item.position = n
        item.queue_position = n
        out.append(item)
    return out


@router.get("/queue", response_model=list[QueueItemOut])
async def order_queue(db: Annotated[AsyncSession, Depends(get_db)], current: CurrentUser):
    return _queue_out(await _load_queue(db, current))


@router.post("/{order_id}/queue-move", response_model=list[QueueItemOut])
async def queue_move(order_id: uuid.UUID, payload: QueueMove, current: CurrentUser,
                     db: Annotated[AsyncSession, Depends(get_db)]):
    orders = await _load_queue(db, current)
    ids = [o.id for o in orders]
    if order_id not in ids:
        raise HTTPException(404, "Buyurtma navbatda topilmadi")
    target = orders[ids.index(order_id)]
    # Navbatdagilar yagona ro'yxat — barchasi orasida ko'chiriladi.
    group = list(orders)
    gidx = group.index(target)
    if payload.action == "up" and gidx > 0:
        group[gidx - 1], group[gidx] = group[gidx], group[gidx - 1]
    elif payload.action == "down" and gidx < len(group) - 1:
        group[gidx + 1], group[gidx] = group[gidx], group[gidx + 1]
    elif payload.action == "top":
        o = group.pop(gidx)
        group.insert(0, o)
    elif payload.action not in ("up", "down"):
        raise HTTPException(400, "Noma'lum amal")
    # Ustuvorliklarni faqat shu guruh ichida qayta normallashtiramiz (yuqori = katta qiymat)
    n = len(group)
    for pos, o in enumerate(group):
        o.priority = n - pos
    await db.commit()
    return _queue_out(await _load_queue(db, current))


@router.post("/{order_id}/to-queue", response_model=OrderOut)
async def add_to_queue(order_id: uuid.UUID, payload: QueueAdd, current: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    """Buyurtmani sotuvdan navbatga o'tkazish (chiqib-ketish sanasi bilan)."""
    res = await db.execute(_order_query().where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    if o.status in ("delivered", "rejected"):
        raise HTTPException(400, "Yakunlangan buyurtmani navbatga qo'shib bo'lmaydi")
    o.in_queue = True
    if payload.pickup_date is not None:
        o.pickup_date = payload.pickup_date
    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order_id))
    return res.scalar_one()


@router.post("/{order_id}/from-queue", response_model=OrderOut)
async def remove_from_queue(order_id: uuid.UUID, current: CurrentUser,
                            db: Annotated[AsyncSession, Depends(get_db)]):
    """Buyurtmani navbatdan chiqarish (sotuvda qoladi)."""
    res = await db.execute(_order_query().where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    o.in_queue = False
    o.priority = 0
    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order_id))
    return res.scalar_one()


@router.get("/salespeople", response_model=list[SalespersonOption])
async def list_salespeople(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    """Sotuvchi tanlovi (dropdown) uchun aktiv foydalanuvchilar — ID + ism."""
    rows = (await db.execute(
        select(User.id, User.full_name)
        .where(User.is_active.is_(True)).order_by(User.full_name)
    )).all()
    return [SalespersonOption(id=i, full_name=n) for i, n in rows]


@router.post("", response_model=OrderOut, status_code=201)
async def create_order(payload: OrderCreate, user: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    rate = payload.exchange_rate or Decimal(0)
    # Chegirma tekshiruvi — to'qnashuv retry'sidan oldin bir marta.
    for _i, _it in enumerate(payload.items):
        _check_discount(_it.unit_price_usd, _it.quantity, _it.discount_usd, _i)

    # Manzil kiritilmasa — mijozning manzilini avtomatik olamiz
    # (avval to'liq manzil, bo'lmasa viloyat + shahar/tuman).
    delivery_address = payload.delivery_address
    if not (delivery_address or "").strip():
        cust = (await db.execute(
            select(Customer).where(Customer.id == payload.customer_id)
        )).scalar_one_or_none()
        if cust:
            delivery_address = (
                (cust.address or "").strip()
                or ", ".join(p for p in (cust.region, cust.city) if p)
                or None
            )

    # Kod UNIQUE — bir vaqtda yaratilgan ikki buyurtma bir xil kod olib qolsa
    # (race), DB IntegrityError beradi. Shunda rollback qilib, kodni qaytadan
    # generatsiya qilib qayta urinamiz — foydalanuvchi 500 ko'rmaydi.
    for _attempt in range(5):
        code = await generate_order_code(db)
        # unit_uid/inventory_id alohida ishlanadi (_link_unit orqali band qilinadi)
        order = Order(
            code=code, salesperson_id=user.id, status="new",
            **payload.model_dump(
                exclude={"items", "unit_uid", "inventory_id", "delivery_address"}),
        )
        order.delivery_address = delivery_address
        for it in payload.items:
            disc_uzs = _discount_uzs(it.discount_usd, rate)
            total_uzs = (it.unit_price_uzs or Decimal(0)) * (it.quantity or 1) - disc_uzs
            order.items.append(OrderItem(
                product_id=it.product_id, serial_id=it.serial_id,
                bunker_direction=it.bunker_direction, quantity=it.quantity,
                unit_price_usd=it.unit_price_usd, unit_price_uzs=it.unit_price_uzs,
                discount_usd=it.discount_usd, discount=disc_uzs, total_uzs=total_uzs,
            ))
        db.add(order)
        # Ombor birligini FAQAT qo'lda kiritilgan ID raqami orqali band qilamiz
        if payload.unit_uid:
            await _link_unit(db, order, payload.unit_uid)
        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            continue
        res = await db.execute(_order_query().where(Order.id == order.id))
        return res.scalar_one()

    raise HTTPException(
        409, "Buyurtma kodini yaratib bo'lmadi, iltimos qayta urinib ko'ring")


@router.get("/{order_id}", response_model=OrderOut)
async def get_order(order_id: uuid.UUID, _: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(_order_query().where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    return o


# ---- PDF hujjatlar (faktura / kafolat / to'lov kvitansiyasi) ----
def _pdf_response(data: bytes, filename: str) -> Response:
    return Response(
        content=data,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="{filename}"'},
    )


async def _load_order_for_pdf(db: AsyncSession, order_id: uuid.UUID) -> Order:
    res = await db.execute(_order_query().where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    return o


@router.get("/{order_id}/invoice.pdf")
async def order_invoice(order_id: uuid.UUID, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    o = await _load_order_for_pdf(db, order_id)
    return _pdf_response(pdf_service.order_invoice_pdf(o), f"faktura-{o.code}.pdf")


@router.get("/{order_id}/warranty.pdf")
async def order_warranty(order_id: uuid.UUID, _: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    o = await _load_order_for_pdf(db, order_id)
    return _pdf_response(pdf_service.warranty_certificate_pdf(o), f"kafolat-{o.code}.pdf")


@router.get("/{order_id}/payments/{payment_id}/receipt.pdf")
async def payment_receipt(order_id: uuid.UUID, payment_id: uuid.UUID, _: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    o = await _load_order_for_pdf(db, order_id)
    pay = next((p for p in o.payments if p.id == payment_id), None)
    if not pay:
        raise HTTPException(404, "To'lov topilmadi")
    return _pdf_response(
        pdf_service.payment_receipt_pdf(o, pay), f"kvitansiya-{o.code}.pdf")


@router.patch("/{order_id}", response_model=OrderOut)
async def update_order(order_id: uuid.UUID, payload: OrderUpdate, _: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(_order_query().where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")

    data = payload.model_dump(exclude_unset=True)
    new_items = data.pop("items", None)
    # Status o'zgarishi maxsus ishlanadi (delivered_at, inventar, tranzitsiya)
    new_status = data.pop("status", None)
    # ID raqami (unit_uid) alohida ishlanadi; bog'lanish endi faqat shu orqali.
    new_uid = data.pop("unit_uid", _UNSET)
    data.pop("inventory_id", None)  # bog'lanish unit_uid orqali boshqariladi

    # Yetkazilgan buyurtmani o'zgartirib bo'lmaydi — summalar va inventar
    # allaqachon yakunlangan. (Rad etilganlar hozircha ochiq qoladi.)
    if o.status in ("delivered", "cancelled"):
        raise HTTPException(400, "Yetkazilgan buyurtmani o'zgartirib bo'lmaydi")

    if new_uid is not _UNSET:
        await _link_unit(db, o, new_uid)

    for k, v in data.items():
        setattr(o, k, v)

    if new_items is not None:
        rate = o.exchange_rate or Decimal(0)
        for _i, _it in enumerate(new_items):
            _check_discount(
                _it.get("unit_price_usd") or Decimal(0),
                _it.get("quantity", 1) or 1,
                _it.get("discount_usd") or Decimal(0), _i,
            )
        o.items.clear()
        for it in new_items:
            qty = it.get("quantity", 1) or 1
            disc_uzs = _discount_uzs(it.get("discount_usd") or Decimal(0), rate)
            total_uzs = (it.get("unit_price_uzs") or Decimal(0)) * qty - disc_uzs
            o.items.append(OrderItem(
                product_id=it["product_id"], serial_id=it.get("serial_id"),
                bunker_direction=it.get("bunker_direction"), quantity=qty,
                unit_price_usd=it.get("unit_price_usd") or Decimal(0),
                unit_price_uzs=it.get("unit_price_uzs") or Decimal(0),
                discount_usd=it.get("discount_usd") or Decimal(0),
                discount=disc_uzs, total_uzs=total_uzs,
            ))

    # Status o'zgarishi — /status endpointi bilan bir xil qoidalar:
    # tranzitsiya tekshiruvi, to'liq to'lov sharti, delivered_at avtomatik yoziladi
    if new_status and new_status != o.status:
        if not is_valid_transition(o.status, new_status):
            raise HTTPException(400, f"O'tish ruxsat etilmaydi: {o.status} -> {new_status}")
        if new_status == "delivered" and o.balance_uzs > 0 and not (o.customer and o.customer.is_dealer):
            raise HTTPException(400, "Buyurtma to'liq to'lanmagan — avval qoldiq to'lovni yoping")
        o.status = new_status
        if new_status == "delivered":
            # Yetkazilgan sana avtomatik — bugungi kun (agar oldindan berilmagan bo'lsa)
            if not o.delivered_at:
                o.delivered_at = date.today()
            # Yetkazildi — kotyol ombordan chiqib ketdi, birlikni o'chiramiz
            await _delete_linked_unit(db, o)
        if new_status == "rejected":
            await _free_unit_by_uid(db, o.unit_uid)

    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order_id))
    return res.scalar_one()


@router.patch("/{order_id}/unit-uid", response_model=OrderOut)
async def set_order_unit_uid(order_id: uuid.UUID, payload: UnitUidUpdate, user: CurrentUser,
                             db: Annotated[AsyncSession, Depends(get_db)]):
    """ID raqamini qo'lda yozish — holatdan qat'i nazar (yetkazilgan buyurtmalar uchun ham)
    va ombor ro'yxatida bo'lishini TALAB QILMAYDI (snapshot). FAQAT super-admin uchun.

    Boshqa buyurtmada o'sha ID band bo'lsa — rad etiladi (takrordan saqlanish).
    """
    if not has_special(user, "system:order_override"):
        raise HTTPException(403, "Bu amal uchun ruxsat yo'q (super-admin darajasidagi).")
    res = await db.execute(select(Order).where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    new_uid = (payload.unit_uid or "").strip() or None
    if new_uid:
        taken = (await db.execute(
            select(Order.code).where(Order.unit_uid == new_uid, Order.id != order_id).limit(1)
        )).scalar_one_or_none()
        if taken:
            raise HTTPException(400, f"«{new_uid}» ID allaqachon band ({taken})")
    # Eski bog'langan ombor birligi (agar bo'lsa) bo'shaydi; yangi ID faqat yozuv sifatida
    # saqlanadi — ombor bilan bog'lanmaydi (inventory_id NULL).
    if o.unit_uid and o.unit_uid != new_uid:
        await _free_unit_by_uid(db, o.unit_uid)
    o.unit_uid = new_uid
    o.inventory_id = None
    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order_id))
    return res.scalar_one()


@router.patch("/{order_id}/salesperson", response_model=OrderOut)
async def set_order_salesperson(order_id: uuid.UUID, payload: SalespersonUpdate, user: CurrentUser,
                                db: Annotated[AsyncSession, Depends(get_db)]):
    """Buyurtma sotuvchisini qo'lda biriktirish — holatdan qat'i nazar (yetkazilganda ham).
    `system:order_override` ruxsati kerak (sotuvchi hisobiga ta'sir qiladi).
    """
    if not has_special(user, "system:order_override"):
        raise HTTPException(403, "Bu amal uchun ruxsat yo'q (super-admin darajasidagi).")
    res = await db.execute(select(Order).where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    sp_id = payload.salesperson_id
    if sp_id is not None:
        ok = (await db.execute(
            select(User.id).where(User.id == sp_id, User.is_active.is_(True))
        )).scalar_one_or_none()
        if not ok:
            raise HTTPException(422, "Sotuvchi topilmadi yoki aktiv emas")
    o.salesperson_id = sp_id
    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order_id))
    return res.scalar_one()


# Import tuzatish to'lovini belgilash uchun maxsus izoh (qayta tahrirda topib yangilanadi)
_IMPORT_CORRECTION_NOTE = "__import_correction__"


@router.patch("/{order_id}/override-amounts", response_model=OrderOut)
async def override_order_amounts(order_id: uuid.UUID, payload: OverrideAmounts, user: CurrentUser,
                                 db: Annotated[AsyncSession, Depends(get_db)]):
    """Jami (so'm) va/yoki To'langan (so'm) ni qo'lda to'g'rilash — FAQAT super-admin.

    Eski (Google Sheets'dan ko'chgan) buyurtmalarda Jami/To'langan 0 bo'lib qolgan.
    Holatdan qat'i nazar ishlaydi (yetkazilgan buyurtmada ham).

    - total_uzs: asosiy (additional bo'lmagan) mahsulot satrini shunday sozlaymizki,
      buyurtma jami (items_total_uzs) aynan shu qiymatga teng bo'lsin. Dollar narxi
      (unit_price_usd) o'zgarmaydi — faqat so'mdagi qiymat tiklanadi.
    - paid_uzs: bitta "import tuzatish" to'lovi orqali umumiy to'langan summani shu
      qiymatga keltiramiz (haqiqiy, qo'lda kiritilgan to'lovlar saqlanadi).
    """
    if not has_special(user, "system:order_override"):
        raise HTTPException(403, "Bu amal uchun ruxsat yo'q (super-admin darajasidagi).")
    o = (await db.execute(_order_query().where(Order.id == order_id))).scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")

    # --- Jami (so'm) ni to'g'rilash ---
    if payload.total_uzs is not None:
        target = payload.total_uzs
        # Asosiy satr — frontend bilan bir xil (birinchi additional bo'lmagan)
        main = next((i for i in o.items if (not i.product or i.product.product_type != "additional")), None)
        if main is None:
            main = o.items[0] if o.items else None
        if main is None:
            raise HTTPException(400, "Buyurtmada mahsulot yo'q — jamini o'rnatib bo'lmaydi")
        others_total = sum(((i.total_uzs or Decimal(0)) for i in o.items if i is not main), Decimal(0))
        main_target = target - others_total
        if main_target < 0:
            raise HTTPException(
                400, f"Jami juda kichik — qo'shimcha mahsulotlar yig'indisi {others_total:,.0f} so'm".replace(",", " "))
        qty = main.quantity or 1
        disc_uzs = main.discount or Decimal(0)
        # total_uzs = unit_price_uzs*qty - disc_uzs  =>  unit_price_uzs = (target + disc)/qty
        main.unit_price_uzs = (main_target + disc_uzs) / qty
        main.total_uzs = main_target

    # --- To'langan (so'm) ni to'g'rilash ---
    if payload.paid_uzs is not None:
        target_paid = payload.paid_uzs
        # Haqiqiy (import tuzatishidan boshqa) to'lovlar yig'indisi
        real_payments = [p for p in o.payments if (p.note or "") != _IMPORT_CORRECTION_NOTE]
        real_paid = sum(((p.amount_uzs_equiv or p.amount or Decimal(0)) for p in real_payments), Decimal(0))
        # Eski import tuzatish to'lovi(lari)ni topamiz
        corrections = [p for p in o.payments if (p.note or "") == _IMPORT_CORRECTION_NOTE]
        delta = target_paid - real_paid  # tuzatish to'lovi qancha bo'lishi kerak
        if delta < 0:
            raise HTTPException(
                400, f"To'langan summa haqiqiy to'lovlardan kam — haqiqiy: {real_paid:,.0f} so'm".replace(",", " "))
        # Avvalgi tuzatishlarni olib tashlaymiz, kerak bo'lsa bittasini qayta yaratamiz
        for c in corrections:
            await db.delete(c)
        if delta > 0:
            db.add(Payment(
                order_id=o.id, date=o.order_date or date.today(),
                amount=delta, currency="UZS", amount_uzs_equiv=delta,
                method=None, note=_IMPORT_CORRECTION_NOTE, created_by_id=user.id,
            ))

    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order_id))
    return res.scalar_one()


@router.post("/{order_id}/status", response_model=OrderOut)
async def change_status(order_id: uuid.UUID, payload: OrderStatusChange,
                        _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(_order_query().where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    if not is_valid_transition(o.status, payload.status):
        raise HTTPException(400, f"O'tish ruxsat etilmaydi: {o.status} -> {payload.status}")
    # To'liq to'lanmagan buyurtmani "Yetkazildi"ga o'tkazib bo'lmaydi (diller bundan mustasno)
    if payload.status == "delivered" and o.balance_uzs > 0 and not (o.customer and o.customer.is_dealer):
        raise HTTPException(400, "Buyurtma to'liq to'lanmagan — avval qoldiq to'lovni yoping")
    o.status = payload.status
    if payload.status == "delivered":
        o.delivered_at = payload.delivered_at or date.today()
        # Yetkazildi — kotyol ombordan chiqib ketdi, birlikni o'chiramiz
        await _delete_linked_unit(db, o)
    if payload.status == "rejected":
        await _free_unit_by_uid(db, o.unit_uid)
    if payload.note:
        o.note = (o.note or "") + f"\n[status change] {payload.note}"
    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order_id))
    return res.scalar_one()


@router.post("/{order_id}/payments", response_model=PaymentOut, status_code=201,
             dependencies=[Depends(require_permission("orders:write"))])
async def add_payment(order_id: uuid.UUID, payload: PaymentIn, user: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Order).where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    # To'liq to'langan buyurtmaga yana to'lov qo'shib bo'lmaydi
    if o.balance_uzs <= 0:
        raise HTTPException(400, "Buyurtma allaqachon to'liq to'langan")
    data = payload.model_dump()
    if not data.get("amount_uzs_equiv"):
        if data.get("currency", "UZS") == "UZS":
            data["amount_uzs_equiv"] = data["amount"]
        elif o.exchange_rate:
            data["amount_uzs_equiv"] = data["amount"] * o.exchange_rate
    # To'lov qoldiqdan oshib ketmasligi kerak
    equiv = Decimal(str(data.get("amount_uzs_equiv") or data["amount"]))
    if equiv > o.balance_uzs:
        raise HTTPException(
            400, f"To'lov qoldiqdan oshib ketdi — qoldiq: {o.balance_uzs:,.0f} so'm".replace(",", " "))
    p = Payment(order_id=order_id, created_by_id=user.id, **data)
    db.add(p)

    # MUHIM: savdo to'lovi MOLIYAGA bog'lanmaydi — moliya bo'limi alohida, qo'lda
    # yuritiladi. To'lov faqat savdo bo'limi hisobida (Savdo/To'langan/Qoldiq)
    # aks etadi; kassa balansi va moliya hisobotlariga ta'sir qilmaydi.
    await db.commit()
    await db.refresh(p)
    return p


@router.get("/{order_id}/payments", response_model=list[PaymentOut],
            dependencies=[Depends(require_permission("orders:read"))])
async def list_payments(order_id: uuid.UUID, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Payment).where(Payment.order_id == order_id)
                           .order_by(Payment.date.desc()))
    return [PaymentOut.model_validate(p) for p in res.scalars().all()]


@router.delete("/{order_id}/payments/{payment_id}", status_code=204,
               dependencies=[Depends(require_permission("orders:delete"))])
async def delete_payment(order_id: uuid.UUID, payment_id: uuid.UUID, _: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Payment).where(
        Payment.id == payment_id, Payment.order_id == order_id))
    p = res.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "To'lov topilmadi")

    # Yetkazilgan buyurtmaning to'lovini o'chirib bo'lmaydi
    o = (await db.execute(select(Order).where(Order.id == order_id))).scalar_one_or_none()
    if o and o.status == "delivered":
        raise HTTPException(400, "Yetkazilgan buyurtma to'lovini o'chirib bo'lmaydi")

    # Savdo va moliya ajratilgan — to'lovni o'chirish moliyaga tegmaydi.
    await db.delete(p)
    await db.commit()


@router.delete("/{order_id}", status_code=204,
               dependencies=[Depends(require_permission("orders:delete"))])
async def delete_order(order_id: uuid.UUID, _: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    """Buyurtmani to'liq o'chirish (test ma'lumotlarini tozalash uchun).

    Oddiy o'chirish yetarli emas — shu sabab qo'lda quyidagilarni qaytaramiz:
      1) income/expense moliya tranzaksiyalarini teskari qo'llaymiz (balans tiklanadi)
         va o'chiramiz (aks holda hisobotlar shishib qoladi),
      2) bog'langan SKLAD KATYOL birligini "available" ga qaytaramiz,
      3) buyurtmani o'chiramiz (cascade order_items + payments ni oladi).
    """
    res = await db.execute(select(Order).where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")

    # Savdo va moliya ajratilgan — buyurtmani o'chirish moliyaga tegmaydi.
    # Eski (avval yaratilgan) moliya yozuvi bo'lsa, u saqlanadi; related_order_id
    # esa FK (ondelete=SET NULL) orqali avtomatik NULL bo'ladi.

    # Inventar birligini bo'shatamiz (band qilingan bo'lsa)
    if o.inventory_id:
        await _set_inventory_status(db, o.inventory_id, "available")
        o.inventory_id = None
    elif o.unit_uid and o.status not in ("delivered", "rejected"):
        await _free_unit_by_uid(db, o.unit_uid)

    await db.delete(o)  # cascade: order_items + payments
    await db.commit()

