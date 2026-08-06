"""Ta'minot — ichki/tashqi ta'minot bo'yicha qarzga olinadigan mahsulotlar API.

"Bizning qarzlar" moduli mantig'iga asoslanadi, lekin har bir yozuv `scope`
(ichki/tashqi) bilan ajratiladi. RUXSATLAR HAR SCOPE UCHUN ALOHIDA:
  - ichki  -> `supply_ichki:read|write|delete`
  - tashqi -> `supply_tashqi:read|write|delete`
Shu sabab ichki va tashqi ta'minot turli odamlarga alohida lavozim sifatida
biriktirilishi mumkin.

Pul hisobidan tashqari har bir mahsulotning OMBOR QOLDIG'I ham yuritiladi:
    qoldiq = olib kelingan (purchase.qty) − sarflangan (consume.qty)
             + to'g'rilashlar (adjust.qty)
Qoldiq mahsulotning `min_qty` chegarasidan past bo'lsa — "kam qoldi" (low),
0 va past bo'lsa — "tugadi" (out) holati qaytariladi.
"""
import uuid
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import case, delete as sa_delete, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import CurrentUser
from app.core.permissions import has_permission
from app.db.session import get_db
from app.models.taminot import (
    TaminotProduct, TaminotPurchaseList, TaminotPurchaseListItem, TaminotTransaction,
)
from app.schemas.taminot import (
    PurchaseListApplyIn, PurchaseListCreate, PurchaseListItemIn, PurchaseListItemOut,
    PurchaseListOut, PurchaseListTotal, PurchaseListUpdate,
    SCOPES,
    ConsumeCreate,
    CurrencyTotal,
    PaymentCreate,
    PurchaseCreate,
    StockSetCreate,
    TaminotProductCreate,
    TaminotProductOut,
    TaminotProductUpdate,
    TaminotSummary,
    TaminotTransactionOut,
    TaminotTxLogOut,
)

# Router darajasidagi yagona modul-guard YO'Q — ruxsat har endpointda scope
# bo'yicha tekshiriladi (ichki/tashqi alohida). Autentifikatsiya CurrentUser orqali.
router = APIRouter()


def _q(v) -> float:
    return float(v or 0)


def _check_scope(scope: str) -> str:
    if scope not in SCOPES:
        raise HTTPException(422, "Noto'g'ri ta'minot turi (ichki/tashqi)")
    return scope


def _require_scope(user, scope: str, verb: str) -> str:
    """Scope bo'yicha ruxsatni tekshiradi: `supply_<scope>:<verb>`.

    Masalan ichki ta'minotga yozish uchun `supply_ichki:write` kerak.
    """
    _check_scope(scope)
    perm = f"supply_{scope}:{verb}"
    if not has_permission(user, perm):
        raise HTTPException(403, f"Ushbu amal uchun ruxsat yo'q ({perm})")
    return scope


async def _aggregates(db: AsyncSession, product_ids: Optional[list[uuid.UUID]] = None):
    """product_id -> pul va miqdor yig'indilari xaritasi.

    Pul: purchased/paid. Miqdor (ombor qoldig'i uchun): in_qty (olib kelingan),
    out_qty (sarflangan), adjust_qty (to'g'rilashlar).
    """
    q = select(
        TaminotTransaction.product_id,
        func.coalesce(
            func.sum(case((TaminotTransaction.kind == "purchase", TaminotTransaction.amount), else_=0)), 0
        ).label("purchased"),
        func.coalesce(
            func.sum(case((TaminotTransaction.kind == "payment", TaminotTransaction.amount), else_=0)), 0
        ).label("paid"),
        func.coalesce(
            func.sum(case((TaminotTransaction.kind == "purchase", TaminotTransaction.qty), else_=0)), 0
        ).label("in_qty"),
        func.coalesce(
            func.sum(case((TaminotTransaction.kind == "consume", TaminotTransaction.qty), else_=0)), 0
        ).label("out_qty"),
        func.coalesce(
            func.sum(case((TaminotTransaction.kind == "adjust", TaminotTransaction.qty), else_=0)), 0
        ).label("adjust_qty"),
        func.max(
            case((TaminotTransaction.kind == "purchase", TaminotTransaction.created_at), else_=None)
        ).label("last_purchase_at"),
        func.max(
            case((TaminotTransaction.kind == "consume", TaminotTransaction.created_at), else_=None)
        ).label("last_consume_at"),
        func.count(TaminotTransaction.id).label("tx_count"),
    ).group_by(TaminotTransaction.product_id)
    if product_ids is not None:
        if not product_ids:
            return {}
        q = q.where(TaminotTransaction.product_id.in_(product_ids))
    res = await db.execute(q)
    out: dict[uuid.UUID, dict] = {}
    for row in res.all():
        out[row.product_id] = {
            "purchased": _q(row.purchased),
            "paid": _q(row.paid),
            "in_qty": _q(row.in_qty),
            "out_qty": _q(row.out_qty),
            "adjust_qty": _q(row.adjust_qty),
            "last_purchase_at": row.last_purchase_at,
            "last_consume_at": row.last_consume_at,
            "tx_count": row.tx_count or 0,
        }
    return out


def _stock_status(stock: float, min_qty: float, has_movement: bool) -> str:
    """none — hali harakat yo'q; out — tugagan; low — chegaradan past; ok — yetarli."""
    if not has_movement:
        return "none"
    if stock <= 0:
        return "out"
    if min_qty > 0 and stock <= min_qty:
        return "low"
    return "ok"


def _build_out(p: TaminotProduct, agg: dict) -> TaminotProductOut:
    purchased = agg.get("purchased", 0.0)
    paid = agg.get("paid", 0.0)
    in_qty = agg.get("in_qty", 0.0)
    out_qty = agg.get("out_qty", 0.0)
    adjust_qty = agg.get("adjust_qty", 0.0)
    tx_count = agg.get("tx_count", 0)
    stock = round(in_qty - out_qty + adjust_qty, 3)
    min_qty = _q(p.min_qty)
    return TaminotProductOut(
        id=p.id,
        scope=p.scope,
        name=p.name,
        unit=p.unit,
        unit_price=_q(p.unit_price),
        currency=p.currency,
        min_qty=min_qty,
        supplier=p.supplier,
        note=p.note,
        created_at=p.created_at,
        total_purchased=purchased,
        total_paid=paid,
        balance=round(purchased - paid, 2),
        last_purchase_at=agg.get("last_purchase_at"),
        tx_count=tx_count,
        in_qty=in_qty,
        out_qty=out_qty,
        adjust_qty=adjust_qty,
        stock=stock,
        stock_value=round(max(stock, 0.0) * _q(p.unit_price), 2),
        stock_status=_stock_status(stock, min_qty, tx_count > 0),
        last_consume_at=agg.get("last_consume_at"),
    )


async def _current_stock(db: AsyncSession, product_id: uuid.UUID) -> float:
    """Bitta mahsulotning joriy ombor qoldig'i."""
    agg = (await _aggregates(db, [product_id])).get(product_id, {})
    return round(
        agg.get("in_qty", 0.0) - agg.get("out_qty", 0.0) + agg.get("adjust_qty", 0.0), 3
    )


async def _get_product(db: AsyncSession, product_id: uuid.UUID) -> TaminotProduct:
    p = (await db.execute(
        select(TaminotProduct).where(TaminotProduct.id == product_id)
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    return p


# ---------------------------------------------------------------------------
# Umumiy hisob (KPI kartalari)
# ---------------------------------------------------------------------------
@router.get("/summary", response_model=TaminotSummary)
async def taminot_summary(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    scope: str = Query(..., description="ichki / tashqi"),
):
    _require_scope(user, scope, "read")
    products = (await db.execute(
        select(TaminotProduct).where(TaminotProduct.scope == scope)
    )).scalars().all()
    agg = await _aggregates(db, [p.id for p in products])

    by_cur: dict[str, dict] = {}
    counts = {"none": 0, "out": 0, "low": 0, "ok": 0}
    for p in products:
        o = _build_out(p, agg.get(p.id, {}))
        cur = o.currency or "UZS"
        slot = by_cur.setdefault(
            cur, {"purchased": 0.0, "paid": 0.0, "with_debt": 0, "stock_value": 0.0}
        )
        slot["purchased"] += o.total_purchased
        slot["paid"] += o.total_paid
        slot["stock_value"] += o.stock_value
        if o.balance > 0:
            slot["with_debt"] += 1
        counts[o.stock_status] += 1

    totals = [
        CurrencyTotal(
            currency=cur,
            total_purchased=round(s["purchased"], 2),
            total_paid=round(s["paid"], 2),
            total_balance=round(s["purchased"] - s["paid"], 2),
            with_debt_count=s["with_debt"],
            stock_value=round(s["stock_value"], 2),
        )
        for cur, s in sorted(by_cur.items())
    ]
    return TaminotSummary(
        by_currency=totals,
        product_count=len(products),
        low_stock_count=counts["low"],
        out_of_stock_count=counts["out"],
        ok_stock_count=counts["ok"],
        tracked_count=counts["low"] + counts["out"] + counts["ok"],
    )


# ---------------------------------------------------------------------------
# Mahsulotlar
# ---------------------------------------------------------------------------
@router.get("/products", response_model=list[TaminotProductOut])
async def list_products(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    scope: str = Query(..., description="ichki / tashqi"),
    search: Optional[str] = None,
    with_debt: bool = Query(False, description="Faqat qarzi borlar"),
    low_stock: bool = Query(False, description="Faqat kam qolgan yoki tugagan mahsulotlar"),
    sort: str = Query("name", description="name / stock (kam qolganlar birinchi)"),
):
    _require_scope(user, scope, "read")
    q = select(TaminotProduct).where(TaminotProduct.scope == scope)
    if search:
        like = f"%{search.strip()}%"
        q = q.where(or_(TaminotProduct.name.ilike(like), TaminotProduct.supplier.ilike(like)))
    res = await db.execute(q.order_by(TaminotProduct.name.asc()))
    products = res.scalars().all()
    agg = await _aggregates(db, [p.id for p in products])
    out = [_build_out(p, agg.get(p.id, {})) for p in products]
    if with_debt:
        out = [o for o in out if o.balance > 0]
    if low_stock:
        out = [o for o in out if o.stock_status in ("low", "out")]
    if sort == "stock":
        # Diqqat talab qiladiganlar tepada: tugagan → kam qoldi → yetarli → harakatsiz
        rank = {"out": 0, "low": 1, "ok": 2, "none": 3}
        out.sort(key=lambda o: (rank.get(o.stock_status, 9), o.name.lower()))
    return out


@router.post("/products", response_model=TaminotProductOut, status_code=201)
async def create_product(
    payload: TaminotProductCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    _require_scope(user, payload.scope, "write")
    p = TaminotProduct(**payload.model_dump(), created_by_id=user.id)
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return _build_out(p, {})


@router.patch("/products/{product_id}", response_model=TaminotProductOut)
async def update_product(
    product_id: uuid.UUID,
    payload: TaminotProductUpdate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "write")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(p, k, v)
    await db.commit()
    await db.refresh(p)
    agg = await _aggregates(db, [p.id])
    return _build_out(p, agg.get(p.id, {}))


@router.delete("/products/{product_id}", status_code=204)
async def delete_product(
    product_id: uuid.UUID,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "delete")
    await db.delete(p)  # tranzaksiyalar cascade bilan o'chadi
    await db.commit()


# ---------------------------------------------------------------------------
# Tranzaksiyalar (bitta mahsulot tarixi)
# ---------------------------------------------------------------------------
@router.get("/products/{product_id}/transactions", response_model=list[TaminotTransactionOut])
async def list_transactions(
    product_id: uuid.UUID, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "read")
    res = await db.execute(
        select(TaminotTransaction)
        .where(TaminotTransaction.product_id == product_id)
        .order_by(TaminotTransaction.created_at.desc())
    )
    return res.scalars().all()


@router.post("/products/{product_id}/purchase", response_model=TaminotTransactionOut, status_code=201)
async def add_purchase(
    product_id: uuid.UUID,
    payload: PurchaseCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "write")
    unit_price = Decimal(str(payload.unit_price)) if payload.unit_price is not None else p.unit_price
    qty = Decimal(str(payload.qty))
    amount = (qty * unit_price).quantize(Decimal("0.01"))
    cash = payload.payment_mode == "cash"
    note = payload.note
    tx = TaminotTransaction(
        product_id=product_id,
        kind="purchase",
        qty=qty,
        unit_price=unit_price,
        amount=amount,
        currency=p.currency,
        note=f"{note} · naqd" if (cash and note) else ("Naqd olib kelish" if cash else note),
        created_by_id=user.id,
    )
    db.add(tx)
    # Naqdga olib kelindi — shu zahoti to'liq summaga to'lov yoziladi, shuning
    # uchun qarz qoldig'i o'zgarmaydi (ombor qoldig'i esa baribir oshadi).
    if cash and amount > 0:
        db.add(TaminotTransaction(
            product_id=product_id,
            kind="payment",
            qty=Decimal("0"),
            unit_price=Decimal("0"),
            amount=amount,
            currency=p.currency,
            note="Naqd to'lov (olib kelish bilan birga)",
            created_by_id=user.id,
        ))
    await db.commit()
    await db.refresh(tx)
    return tx


@router.post("/products/{product_id}/payment", response_model=TaminotTransactionOut, status_code=201)
async def add_payment(
    product_id: uuid.UUID,
    payload: PaymentCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "write")
    tx = TaminotTransaction(
        product_id=product_id,
        kind="payment",
        qty=Decimal("0"),
        unit_price=Decimal("0"),
        amount=Decimal(str(payload.amount)).quantize(Decimal("0.01")),
        currency=p.currency,
        note=payload.note,
        created_by_id=user.id,
    )
    db.add(tx)
    await db.commit()
    await db.refresh(tx)
    return tx


@router.post("/products/{product_id}/consume", response_model=TaminotTransactionOut, status_code=201)
async def add_consume(
    product_id: uuid.UUID,
    payload: ConsumeCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Sarflash — ombordan chiqim. Pulga (qarzga) ta'sir qilmaydi.

    Qoldiq manfiy bo'lib ketmasligi uchun sarf miqdori joriy qoldiqdan oshsa
    xatolik qaytariladi — bu ma'lumot aniqligini saqlaydi. Haqiqiy qoldiq
    boshqacha bo'lsa, avval "Qoldiqni to'g'rilash" orqali kiritiladi.
    """
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "write")
    stock = await _current_stock(db, product_id)
    qty = Decimal(str(payload.qty))
    if float(qty) > stock:
        raise HTTPException(
            422,
            f"Ombordagi qoldiq yetarli emas. Joriy qoldiq: {stock:g} {p.unit}. "
            "Agar haqiqiy qoldiq boshqacha bo'lsa — «Qoldiqni to'g'rilash»dan foydalaning.",
        )
    tx = TaminotTransaction(
        product_id=product_id,
        kind="consume",
        qty=qty,
        unit_price=p.unit_price,
        amount=Decimal("0"),
        currency=p.currency,
        note=payload.note,
        created_by_id=user.id,
    )
    db.add(tx)
    await db.commit()
    await db.refresh(tx)
    return tx


@router.post("/products/{product_id}/stock", response_model=TaminotTransactionOut, status_code=201)
async def set_stock(
    product_id: uuid.UUID,
    payload: StockSetCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Qoldiqni to'g'rilash (inventarizatsiya) — ombordagi haqiqiy qoldiqni belgilash.

    Farq `adjust` harakati sifatida yoziladi (musbat yoki manfiy), shu sababli
    tarix saqlanadi va qarz hisobiga ta'sir qilmaydi.
    """
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "write")
    stock = await _current_stock(db, product_id)
    delta = Decimal(str(payload.qty)) - Decimal(str(stock))
    if delta == 0:
        raise HTTPException(422, f"Qoldiq allaqachon {stock:g} {p.unit} — o'zgarish yo'q")
    tx = TaminotTransaction(
        product_id=product_id,
        kind="adjust",
        qty=delta,
        unit_price=p.unit_price,
        amount=Decimal("0"),
        currency=p.currency,
        note=payload.note,
        created_by_id=user.id,
    )
    db.add(tx)
    await db.commit()
    await db.refresh(tx)
    return tx


@router.delete("/transactions/{tx_id}", status_code=204)
async def delete_transaction(
    tx_id: uuid.UUID,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    tx = (await db.execute(
        select(TaminotTransaction).where(TaminotTransaction.id == tx_id)
    )).scalar_one_or_none()
    if not tx:
        raise HTTPException(404, "Tranzaksiya topilmadi")
    p = await _get_product(db, tx.product_id)
    _require_scope(user, p.scope, "delete")
    await db.delete(tx)
    await db.commit()


# ---------------------------------------------------------------------------
# Hisobotlar — scope bo'yicha to'liq harakatlar jurnali
# ---------------------------------------------------------------------------
@router.get("/transactions", response_model=list[TaminotTxLogOut])
async def transaction_log(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    scope: str = Query(..., description="ichki / tashqi"),
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    kind: Optional[str] = Query(None, description="purchase / payment / consume / adjust"),
    limit: int = Query(500, le=2000),
):
    _require_scope(user, scope, "read")
    q = (
        select(
            TaminotTransaction,
            TaminotProduct.name,
            TaminotProduct.unit,
            TaminotProduct.supplier,
        )
        .join(TaminotProduct, TaminotProduct.id == TaminotTransaction.product_id)
        .where(TaminotProduct.scope == scope)
    )
    if date_from is not None:
        q = q.where(func.date(TaminotTransaction.created_at) >= date_from)
    if date_to is not None:
        q = q.where(func.date(TaminotTransaction.created_at) <= date_to)
    if kind in ("purchase", "payment", "consume", "adjust"):
        q = q.where(TaminotTransaction.kind == kind)
    q = q.order_by(TaminotTransaction.created_at.desc()).limit(limit)
    res = await db.execute(q)
    out: list[TaminotTxLogOut] = []
    for tx, name, unit, supplier in res.all():
        out.append(TaminotTxLogOut(
            id=tx.id,
            product_id=tx.product_id,
            product_name=name,
            unit=unit,
            supplier=supplier,
            kind=tx.kind,
            qty=_q(tx.qty),
            unit_price=_q(tx.unit_price),
            amount=_q(tx.amount),
            currency=tx.currency,
            note=tx.note,
            created_at=tx.created_at,
        ))
    return out


# ===========================================================================
# Xarid spiskasi — ta'minotchi uchun reja ro'yxati
# ===========================================================================
def _list_out(pl: TaminotPurchaseList, products: dict[uuid.UUID, TaminotProduct]) -> PurchaseListOut:
    items: list[PurchaseListItemOut] = []
    totals: dict[str, Decimal] = {}
    for it in pl.items:
        prod = products.get(it.product_id)
        amount = (Decimal(it.qty) * Decimal(it.unit_price)).quantize(Decimal("0.01"))
        totals[it.currency] = totals.get(it.currency, Decimal(0)) + amount
        items.append(PurchaseListItemOut(
            id=it.id, product_id=it.product_id,
            product_name=prod.name if prod else "(o'chirilgan mahsulot)",
            unit=prod.unit if prod else "dona",
            qty=it.qty, unit_price=it.unit_price, currency=it.currency, amount=amount,
        ))
    return PurchaseListOut(
        id=pl.id, scope=pl.scope, title=pl.title, status=pl.status, note=pl.note,
        applied_at=pl.applied_at, created_at=pl.created_at,
        items=items,
        totals=[PurchaseListTotal(currency=c, amount=a) for c, a in sorted(totals.items())],
        item_count=len(items),
    )


async def _load_list(db: AsyncSession, list_id: uuid.UUID) -> TaminotPurchaseList:
    pl = (await db.execute(
        select(TaminotPurchaseList)
        .where(TaminotPurchaseList.id == list_id)
        .options(selectinload(TaminotPurchaseList.items))
        # populate_existing — sessiyada allaqachon yuklangan obyektni ham
        # bazadan qayta o'qiydi. Busiz tahrirlashdan keyin eski qatorlar
        # identity-map keshidan qaytardi.
        .execution_options(populate_existing=True)
    )).scalar_one_or_none()
    if not pl:
        raise HTTPException(404, "Spiska topilmadi")
    return pl


async def _products_of(db: AsyncSession, ids: list[uuid.UUID]) -> dict[uuid.UUID, TaminotProduct]:
    if not ids:
        return {}
    rows = (await db.execute(
        select(TaminotProduct).where(TaminotProduct.id.in_(ids))
    )).scalars().all()
    return {p.id: p for p in rows}


async def _replace_items(db: AsyncSession, pl: TaminotPurchaseList,
                         items: list[PurchaseListItemIn]) -> None:
    """Spiska qatorlarini almashtiradi. Narx/valyuta mahsulotdan nusxalanadi."""
    if not items:
        raise HTTPException(422, "Spiskada kamida bitta mahsulot bo'lishi kerak")
    prods = await _products_of(db, [i.product_id for i in items])
    for it in items:
        prod = prods.get(it.product_id)
        if not prod:
            raise HTTPException(422, "Mahsulot topilmadi")
        if prod.scope != pl.scope:
            raise HTTPException(422, f"«{prod.name}» boshqa ta'minot turiga tegishli")
        if Decimal(str(it.qty)) <= 0:
            raise HTTPException(422, f"«{prod.name}» miqdori 0 dan katta bo'lishi kerak")

    # Relationship orqali emas, to'g'ridan-to'g'ri DELETE: yangi yaratilgan
    # spiskada `pl.items` ga murojaat lazy-load chaqirib yuboradi (async
    # kontekstda MissingGreenlet xatosi).
    await db.execute(
        sa_delete(TaminotPurchaseListItem)
        .where(TaminotPurchaseListItem.list_id == pl.id)
        .execution_options(synchronize_session="fetch")
    )
    await db.flush()

    for it in items:
        prod = prods[it.product_id]
        db.add(TaminotPurchaseListItem(
            list_id=pl.id, product_id=prod.id, qty=Decimal(str(it.qty)),
            unit_price=prod.unit_price, currency=prod.currency,
        ))


@router.get("/lists", response_model=list[PurchaseListOut])
async def list_purchase_lists(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    scope: str = Query(...),
    status: Optional[str] = None,
):
    scope = _require_scope(user, _check_scope(scope), "read")
    q = select(TaminotPurchaseList).where(TaminotPurchaseList.scope == scope)
    if status:
        q = q.where(TaminotPurchaseList.status == status)
    q = q.order_by(TaminotPurchaseList.created_at.desc()).options(
        selectinload(TaminotPurchaseList.items)
    )
    lists = (await db.execute(q)).scalars().all()
    prods = await _products_of(db, [i.product_id for pl in lists for i in pl.items])
    return [_list_out(pl, prods) for pl in lists]


@router.post("/lists", response_model=PurchaseListOut, status_code=201)
async def create_purchase_list(
    payload: PurchaseListCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    scope = _require_scope(user, _check_scope(payload.scope), "write")
    pl = TaminotPurchaseList(
        scope=scope, title=(payload.title or None), note=(payload.note or None),
        status="draft", created_by_id=user.id,
    )
    db.add(pl)
    await db.flush()
    await _replace_items(db, pl, payload.items)
    await db.commit()
    pl = await _load_list(db, pl.id)
    prods = await _products_of(db, [i.product_id for i in pl.items])
    return _list_out(pl, prods)


@router.patch("/lists/{list_id}", response_model=PurchaseListOut)
async def update_purchase_list(
    list_id: uuid.UUID,
    payload: PurchaseListUpdate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    pl = await _load_list(db, list_id)
    _require_scope(user, pl.scope, "write")
    if pl.status != "draft":
        raise HTTPException(400, "Qabul qilingan spiskani o'zgartirib bo'lmaydi")
    if payload.title is not None:
        pl.title = payload.title or None
    if payload.note is not None:
        pl.note = payload.note or None
    if payload.items is not None:
        await _replace_items(db, pl, payload.items)
    await db.commit()
    pl = await _load_list(db, list_id)
    prods = await _products_of(db, [i.product_id for i in pl.items])
    return _list_out(pl, prods)


@router.post("/lists/{list_id}/apply", response_model=PurchaseListOut)
async def apply_purchase_list(
    list_id: uuid.UUID,
    payload: PurchaseListApplyIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Spiskani qabul qiladi: har bir qator uchun `purchase` tranzaksiyasi.

    `payment_mode="cash"` bo'lsa har mahsulotga to'liq summaga to'lov ham
    yoziladi — ombor qoldig'i oshadi, qarz esa oshmaydi.

    Shu daqiqadan boshlab ombor qoldig'i (va qarzga olingan bo'lsa qarz)
    hisoblanadi. Bir marta bajariladi — takroriy chaqiruv xato qaytaradi.
    """
    pl = await _load_list(db, list_id)
    _require_scope(user, pl.scope, "write")
    if pl.status == "applied":
        raise HTTPException(400, "Bu spiska allaqachon qabul qilingan")
    if not pl.items:
        raise HTTPException(422, "Spiska bo'sh")

    cash = payload.payment_mode == "cash"
    label = pl.title or "Spiska"
    suffix = " · naqd" if cash else ""
    for it in pl.items:
        amount = (Decimal(it.qty) * Decimal(it.unit_price)).quantize(Decimal("0.01"))
        db.add(TaminotTransaction(
            product_id=it.product_id,
            kind="purchase",
            qty=Decimal(it.qty),
            unit_price=Decimal(it.unit_price),
            amount=amount,
            currency=it.currency,
            note=f"{label} bo'yicha qabul qilindi{suffix}",
            created_by_id=user.id,
        ))
        # Naqd to'langan — shu zahoti to'liq summaga to'lov yoziladi,
        # shuning uchun qarz qoldig'i o'zgarmaydi (ombor qoldig'i oshaveradi).
        if cash and amount > 0:
            db.add(TaminotTransaction(
                product_id=it.product_id,
                kind="payment",
                qty=Decimal("0"),
                unit_price=Decimal("0"),
                amount=amount,
                currency=it.currency,
                note=f"{label} · naqd to'lov",
                created_by_id=user.id,
            ))
    pl.status = "applied"
    pl.applied_at = datetime.now(timezone.utc)
    await db.commit()
    pl = await _load_list(db, list_id)
    prods = await _products_of(db, [i.product_id for i in pl.items])
    return _list_out(pl, prods)


@router.delete("/lists/{list_id}", status_code=204)
async def delete_purchase_list(
    list_id: uuid.UUID,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Spiskani o'chiradi. Qabul qilinganini o'chirib bo'lmaydi — u bilan
    yaratilgan tranzaksiyalar tarixda qolishi kerak."""
    pl = await _load_list(db, list_id)
    _require_scope(user, pl.scope, "delete")
    if pl.status == "applied":
        raise HTTPException(400, "Qabul qilingan spiskani o'chirib bo'lmaydi")
    await db.delete(pl)
    await db.commit()
