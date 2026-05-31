"""Sales orders, items, payments."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import CurrentUser
from app.db.session import get_db
from app.models.order import Order, OrderItem, Payment
from app.models.product import Inventory
from app.schemas.common import Page
from app.schemas.order import (
    OrderCreate, OrderOut, OrderStatusChange, OrderUpdate,
    PaymentIn, PaymentOut, SalesSummary, QueueItemOut, QueueMove,
)
from app.services.order_service import generate_order_code, is_valid_transition

router = APIRouter()

# Navbatdagi (hali yopilmagan) buyurtma statuslari
ACTIVE_QUEUE_STATUSES = ("new", "ready")


def _own_only(current) -> bool:
    role_perms: dict = {}
    for r in (current.roles or []):
        role_perms.update(r.permissions or {})
    return bool(role_perms.get("own_orders_only"))


def _item_total(it) -> Decimal:
    return (it.unit_price_uzs or Decimal(0)) * (it.quantity or 1) - (it.discount or Decimal(0))


async def _set_inventory_status(db: AsyncSession, inventory_id: Optional[uuid.UUID], status: str):
    """Move a SKLAD KATYOL unit to a new status (available/reserved/sold)."""
    if not inventory_id:
        return
    res = await db.execute(select(Inventory).where(Inventory.id == inventory_id))
    inv = res.scalar_one_or_none()
    if inv:
        inv.status = status


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
        q = q.where(Order.code.ilike(f"%{search}%"))
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
    return Page[OrderOut](items=[OrderOut.model_validate(o) for o in items],
                          total=total, page=page, page_size=page_size)


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

    return SalesSummary(
        total_orders=total_orders,
        status_counts=status_counts,
        revenue_total=revenue_total,
        paid_total=paid_total,
        outstanding_total=(revenue_total or Decimal(0)) - (paid_total or Decimal(0)),
        month_orders=month_orders,
        month_revenue=month_revenue,
        month_paid=month_paid,
    )


# ---- Queue (Navbat) ----  (declared before /{order_id})
async def _load_queue(db: AsyncSession, current) -> list[Order]:
    q = _order_query().where(Order.status.in_(ACTIVE_QUEUE_STATUSES))
    if _own_only(current):
        q = q.where(Order.salesperson_id == current.id)
    q = q.order_by(Order.priority.desc(), Order.order_date.asc(), Order.created_at.asc())
    res = await db.execute(q)
    return list(res.scalars().unique().all())


@router.get("/queue", response_model=list[QueueItemOut])
async def order_queue(db: Annotated[AsyncSession, Depends(get_db)], current: CurrentUser):
    orders = await _load_queue(db, current)
    out = []
    for pos, o in enumerate(orders, start=1):
        item = QueueItemOut.model_validate(o)
        item.position = pos
        out.append(item)
    return out


@router.post("/{order_id}/queue-move", response_model=list[QueueItemOut])
async def queue_move(order_id: uuid.UUID, payload: QueueMove, current: CurrentUser,
                     db: Annotated[AsyncSession, Depends(get_db)]):
    orders = await _load_queue(db, current)
    ids = [o.id for o in orders]
    if order_id not in ids:
        raise HTTPException(404, "Buyurtma navbatda topilmadi")
    target = orders[ids.index(order_id)]
    # Ko'chirish faqat bir xil statusdagilar (masalan "new") orasida bo'ladi —
    # "ready" buyurtmalar alohida ro'yxat sifatida ko'rsatiladi.
    group = [o for o in orders if o.status == target.status]
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
    orders = await _load_queue(db, current)
    out = []
    for pos, o in enumerate(orders, start=1):
        item = QueueItemOut.model_validate(o)
        item.position = pos
        out.append(item)
    return out


@router.post("", response_model=OrderOut, status_code=201)
async def create_order(payload: OrderCreate, user: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    code = await generate_order_code(db)
    order = Order(code=code, salesperson_id=user.id, status="new",
                  **payload.model_dump(exclude={"items"}))
    for it in payload.items:
        order.items.append(OrderItem(
            product_id=it.product_id, serial_id=it.serial_id,
            bunker_direction=it.bunker_direction, quantity=it.quantity,
            unit_price_usd=it.unit_price_usd, unit_price_uzs=it.unit_price_uzs,
            discount=it.discount, total_uzs=_item_total(it),
        ))
    await _set_inventory_status(db, order.inventory_id, "reserved")
    db.add(order)
    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order.id))
    return res.scalar_one()


@router.get("/{order_id}", response_model=OrderOut)
async def get_order(order_id: uuid.UUID, _: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(_order_query().where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")
    return o


@router.patch("/{order_id}", response_model=OrderOut)
async def update_order(order_id: uuid.UUID, payload: OrderUpdate, _: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(_order_query().where(Order.id == order_id))
    o = res.scalar_one_or_none()
    if not o:
        raise HTTPException(404, "Buyurtma topilmadi")

    data = payload.model_dump(exclude_unset=True)
    new_items = data.pop("items", None)

    if "inventory_id" in data and data["inventory_id"] != o.inventory_id:
        if o.inventory_id:
            await _set_inventory_status(db, o.inventory_id, "available")
        if data["inventory_id"] and o.status not in ("cancelled", "rejected"):
            await _set_inventory_status(db, data["inventory_id"], "reserved")

    for k, v in data.items():
        setattr(o, k, v)

    if new_items is not None:
        o.items.clear()
        for it in new_items:
            qty = it.get("quantity", 1) or 1
            total_uzs = (it.get("unit_price_uzs") or Decimal(0)) * qty - (it.get("discount") or Decimal(0))
            o.items.append(OrderItem(
                product_id=it["product_id"], serial_id=it.get("serial_id"),
                bunker_direction=it.get("bunker_direction"), quantity=qty,
                unit_price_usd=it.get("unit_price_usd") or Decimal(0),
                unit_price_uzs=it.get("unit_price_uzs") or Decimal(0),
                discount=it.get("discount") or Decimal(0), total_uzs=total_uzs,
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
    # To'liq to'lanmagan buyurtmani "Yetkazildi" holatiga o'tkazib bo'lmaydi
    if payload.status == "delivered" and o.balance_uzs > 0:
        raise HTTPException(400, "Buyurtma to'liq to'lanmagan — avval qoldiq to'lovni yoping")
    o.status = payload.status
    if payload.status == "delivered":
        o.delivered_at = payload.delivered_at or date.today()
        await _set_inventory_status(db, o.inventory_id, "sold")
    if payload.status == "rejected":
        await _set_inventory_status(db, o.inventory_id, "available")
    if payload.note:
        o.note = (o.note or "") + f"\n[status change] {payload.note}"
    await db.commit()
    res = await db.execute(_order_query().where(Order.id == order_id))
    return res.scalar_one()


@router.post("/{order_id}/payments", response_model=PaymentOut, status_code=201)
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
    p = Payment(order_id=order_id, created_by_id=user.id, **data)
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return p


@router.get("/{order_id}/payments", response_model=list[PaymentOut])
async def list_payments(order_id: uuid.UUID, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Payment).where(Payment.order_id == order_id)
                           .order_by(Payment.date.desc()))
    return [PaymentOut.model_validate(p) for p in res.scalars().all()]


@router.delete("/{order_id}/payments/{payment_id}", status_code=204)
async def delete_payment(order_id: uuid.UUID, payment_id: uuid.UUID, _: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Payment).where(
        Payment.id == payment_id, Payment.order_id == order_id))
    p = res.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "To'lov topilmadi")
    await db.delete(p)
    await db.commit()
