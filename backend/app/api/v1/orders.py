"""Sales orders, items, payments."""
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard, require_permission
from app.db.session import get_db
from app.models.customer import Customer
from app.models.finance import Account, FinanceCategory, FinanceTransaction
from app.models.order import Order, OrderItem, Payment
from app.models.product import Inventory
from app.schemas.common import Page
from app.schemas.order import (
    OrderCreate, OrderOut, OrderStatusChange, OrderUpdate,
    PaymentIn, PaymentOut, SalesSummary, QueueItemOut, QueueMove,
)
from app.services.finance_service import apply_transaction
from app.services.order_service import generate_order_code, is_valid_transition

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


def _item_total(it) -> Decimal:
    return (it.unit_price_uzs or Decimal(0)) * (it.quantity or 1) - (it.discount or Decimal(0))


def _check_discount(price_uzs: Decimal, qty: int, discount: Decimal, idx: int = 0) -> None:
    """Chegirma mahsulot summasidan (narx * soni) oshmasligi kerak."""
    discount = discount or Decimal(0)
    if discount < 0:
        raise HTTPException(422, "Chegirma manfiy bo'lishi mumkin emas")
    subtotal = (price_uzs or Decimal(0)) * (qty or 1)
    if discount > subtotal:
        raise HTTPException(
            422,
            f"Chegirma mahsulot summasidan oshib ketdi ({idx + 1}-qator): "
            f"chegirma {discount:,.0f} so'm, mahsulot summasi {subtotal:,.0f} so'm",
        )


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
    if any(o.status == "new" for o in items):
        qq = select(Order.id).where(Order.status == "new")
        if _own_only(current):
            qq = qq.where(Order.salesperson_id == current.id)
        qq = qq.order_by(Order.priority.desc(), Order.order_date.asc(), Order.created_at.asc())
        queue_ids = (await db.execute(qq)).scalars().all()
        pos_map = {oid: i for i, oid in enumerate(queue_ids, start=1)}

    out = []
    for o in items:
        m = OrderOut.model_validate(o)
        m.queue_position = pos_map.get(o.id)
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


def _queue_out(orders: list[Order]) -> list[QueueItemOut]:
    """Navbat raqami FAQAT "new" statusdagilar uchun beriladi —
    sotuv jadvalidagi queue_position bilan bir xil.
    "Tayyor bo'ldi" buyurtmalar navbatda hisoblanmaydi (position = 0)."""
    out = []
    n = 0
    for o in orders:
        item = QueueItemOut.model_validate(o)
        if o.status == "new":
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
    return _queue_out(await _load_queue(db, current))


@router.post("", response_model=OrderOut, status_code=201)
async def create_order(payload: OrderCreate, user: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    code = await generate_order_code(db)
    order = Order(code=code, salesperson_id=user.id, status="new",
                  **payload.model_dump(exclude={"items"}))
    for _i, _it in enumerate(payload.items):
        _check_discount(_it.unit_price_uzs, _it.quantity, _it.discount, _i)

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
    # Status o'zgarishi maxsus ishlanadi (delivered_at, inventar, tranzitsiya)
    new_status = data.pop("status", None)

    # Yetkazilgan buyurtmani o'zgartirib bo'lmaydi — summalar va inventar
    # allaqachon yakunlangan. (Rad etilganlar hozircha ochiq qoladi.)
    if o.status in ("delivered", "cancelled"):
        raise HTTPException(400, "Yetkazilgan buyurtmani o'zgartirib bo'lmaydi")

    if "inventory_id" in data and data["inventory_id"] != o.inventory_id:
        if o.inventory_id:
            await _set_inventory_status(db, o.inventory_id, "available")
        if data["inventory_id"] and o.status not in ("cancelled", "rejected"):
            await _set_inventory_status(db, data["inventory_id"], "reserved")

    for k, v in data.items():
        setattr(o, k, v)

    if new_items is not None:
        for _i, _it in enumerate(new_items):
            _check_discount(
                _it.get("unit_price_uzs") or Decimal(0),
                _it.get("quantity", 1) or 1,
                _it.get("discount") or Decimal(0), _i,
            )
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

    # Status o'zgarishi — /status endpointi bilan bir xil qoidalar:
    # tranzitsiya tekshiruvi, to'liq to'lov sharti, delivered_at avtomatik yoziladi
    if new_status and new_status != o.status:
        if not is_valid_transition(o.status, new_status):
            raise HTTPException(400, f"O'tish ruxsat etilmaydi: {o.status} -> {new_status}")
        if new_status == "delivered" and o.balance_uzs > 0:
            raise HTTPException(400, "Buyurtma to'liq to'lanmagan — avval qoldiq to'lovni yoping")
        o.status = new_status
        if new_status == "delivered":
            # Yetkazilgan sana avtomatik — bugungi kun (agar oldindan berilmagan bo'lsa)
            if not o.delivered_at:
                o.delivered_at = date.today()
            await _set_inventory_status(db, o.inventory_id, "sold")
        if new_status == "rejected":
            await _set_inventory_status(db, o.inventory_id, "available")

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


@router.post("/{order_id}/payments", response_model=PaymentOut, status_code=201,
             dependencies=[Depends(require_permission("finance:write"))])
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
    await db.flush()

    # ---- Moliya: avtomatik kirim tranzaksiyasi (qaysi valyutada bo'lsa ham) ----
    currency = data.get("currency") or "UZS"
    # Kategoriya: "Buyurtma to'lovi" (yo'q bo'lsa yaratiladi)
    cat = (await db.execute(
        select(FinanceCategory).where(FinanceCategory.code == "order_payment")
    )).scalar_one_or_none()
    if not cat:
        cat = FinanceCategory(name="Buyurtma to'lovi", kind="income", code="order_payment")
        db.add(cat)
        await db.flush()
    # Valyutaga mos operatsion hisobvaraq
    acc = (await db.execute(
        select(Account).where(Account.currency == currency,
                              Account.ledger == "operational").limit(1)
    )).scalar_one_or_none()
    method_labels = {"cash": "naqd", "card": "karta", "transfer": "o'tkazma"}
    tx = FinanceTransaction(
        date=data.get("date") or date.today(),
        type="income",
        category_id=cat.id,
        amount=data["amount"],
        currency=currency,
        # USD to'lovda UZS ekvivalentini ham saqlaymiz
        amount_other_curr=(data.get("amount_uzs_equiv") or Decimal(0)) if currency == "USD" else Decimal(0),
        account_id=acc.id if acc else None,
        related_order_id=order_id,
        note=f"Buyurtma {o.code} — to'lov ({method_labels.get(data.get('method', ''), data.get('method') or '—')})",
        created_by_id=user.id,
    )
    db.add(tx)
    await db.flush()
    await apply_transaction(db, tx)  # hisobvaraq balansiga qo'shiladi

    await db.commit()
    await db.refresh(p)
    return p


@router.get("/{order_id}/payments", response_model=list[PaymentOut],
            dependencies=[Depends(require_permission("orders:read", "finance:read"))])
async def list_payments(order_id: uuid.UUID, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Payment).where(Payment.order_id == order_id)
                           .order_by(Payment.date.desc()))
    return [PaymentOut.model_validate(p) for p in res.scalars().all()]


@router.delete("/{order_id}/payments/{payment_id}", status_code=204,
               dependencies=[Depends(require_permission("finance:delete"))])
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

    # Moliyadagi mos kirim tranzaksiyasini ham qaytaramiz (balans tiklanadi)
    tx = (await db.execute(select(FinanceTransaction).where(
        FinanceTransaction.related_order_id == order_id,
        FinanceTransaction.type == "income",
        FinanceTransaction.amount == p.amount,
        FinanceTransaction.currency == (p.currency or "UZS"),
        FinanceTransaction.date == p.date,
    ).limit(1))).scalar_one_or_none()
    if tx:
        await apply_transaction(db, tx, reverse=True)
        await db.delete(tx)

    await db.delete(p)
    await db.commit()

