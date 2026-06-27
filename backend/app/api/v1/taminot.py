"""Ta'minot — ichki/tashqi ta'minot bo'yicha qarzga olinadigan mahsulotlar API.

"Bizning qarzlar" moduli mantig'iga asoslanadi, lekin har bir yozuv `scope`
(ichki/tashqi) bilan ajratiladi. RUXSATLAR HAR SCOPE UCHUN ALOHIDA:
  - ichki  -> `supply_ichki:read|write|delete`
  - tashqi -> `supply_tashqi:read|write|delete`
Shu sabab ichki va tashqi ta'minot turli odamlarga alohida lavozim sifatida
biriktirilishi mumkin.
"""
import uuid
from datetime import date
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import case, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import has_permission
from app.db.session import get_db
from app.models.taminot import TaminotProduct, TaminotTransaction
from app.schemas.taminot import (
    SCOPES,
    CurrencyTotal,
    PaymentCreate,
    PurchaseCreate,
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
    """product_id -> {purchased, paid, last_purchase_at, tx_count} xaritasi."""
    q = select(
        TaminotTransaction.product_id,
        func.coalesce(
            func.sum(case((TaminotTransaction.kind == "purchase", TaminotTransaction.amount), else_=0)), 0
        ).label("purchased"),
        func.coalesce(
            func.sum(case((TaminotTransaction.kind == "payment", TaminotTransaction.amount), else_=0)), 0
        ).label("paid"),
        func.max(
            case((TaminotTransaction.kind == "purchase", TaminotTransaction.created_at), else_=None)
        ).label("last_purchase_at"),
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
            "last_purchase_at": row.last_purchase_at,
            "tx_count": row.tx_count or 0,
        }
    return out


def _build_out(p: TaminotProduct, agg: dict) -> TaminotProductOut:
    purchased = agg.get("purchased", 0.0)
    paid = agg.get("paid", 0.0)
    return TaminotProductOut(
        id=p.id,
        scope=p.scope,
        name=p.name,
        unit=p.unit,
        unit_price=_q(p.unit_price),
        currency=p.currency,
        supplier=p.supplier,
        note=p.note,
        created_at=p.created_at,
        total_purchased=purchased,
        total_paid=paid,
        balance=round(purchased - paid, 2),
        last_purchase_at=agg.get("last_purchase_at"),
        tx_count=agg.get("tx_count", 0),
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
    res = await db.execute(
        select(
            TaminotTransaction.product_id,
            TaminotTransaction.currency,
            func.coalesce(
                func.sum(case((TaminotTransaction.kind == "purchase", TaminotTransaction.amount), else_=0)), 0
            ).label("purchased"),
            func.coalesce(
                func.sum(case((TaminotTransaction.kind == "payment", TaminotTransaction.amount), else_=0)), 0
            ).label("paid"),
        )
        .join(TaminotProduct, TaminotProduct.id == TaminotTransaction.product_id)
        .where(TaminotProduct.scope == scope)
        .group_by(TaminotTransaction.product_id, TaminotTransaction.currency)
    )
    by_cur: dict[str, dict] = {}
    for row in res.all():
        cur = row.currency or "UZS"
        slot = by_cur.setdefault(cur, {"purchased": 0.0, "paid": 0.0, "with_debt": 0})
        purchased, paid = _q(row.purchased), _q(row.paid)
        slot["purchased"] += purchased
        slot["paid"] += paid
        if round(purchased - paid, 2) > 0:
            slot["with_debt"] += 1

    product_count = (await db.execute(
        select(func.count(TaminotProduct.id)).where(TaminotProduct.scope == scope)
    )).scalar() or 0
    totals = [
        CurrencyTotal(
            currency=cur,
            total_purchased=round(s["purchased"], 2),
            total_paid=round(s["paid"], 2),
            total_balance=round(s["purchased"] - s["paid"], 2),
            with_debt_count=s["with_debt"],
        )
        for cur, s in sorted(by_cur.items())
    ]
    return TaminotSummary(by_currency=totals, product_count=product_count)


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
    tx = TaminotTransaction(
        product_id=product_id,
        kind="purchase",
        qty=qty,
        unit_price=unit_price,
        amount=amount,
        currency=p.currency,
        note=payload.note,
        created_by_id=user.id,
    )
    db.add(tx)
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
    kind: Optional[str] = Query(None, description="purchase / payment"),
    limit: int = Query(500, le=2000),
):
    _require_scope(user, scope, "read")
    q = (
        select(TaminotTransaction, TaminotProduct.name, TaminotProduct.supplier)
        .join(TaminotProduct, TaminotProduct.id == TaminotTransaction.product_id)
        .where(TaminotProduct.scope == scope)
    )
    if date_from is not None:
        q = q.where(func.date(TaminotTransaction.created_at) >= date_from)
    if date_to is not None:
        q = q.where(func.date(TaminotTransaction.created_at) <= date_to)
    if kind in ("purchase", "payment"):
        q = q.where(TaminotTransaction.kind == kind)
    q = q.order_by(TaminotTransaction.created_at.desc()).limit(limit)
    res = await db.execute(q)
    out: list[TaminotTxLogOut] = []
    for tx, name, supplier in res.all():
        out.append(TaminotTxLogOut(
            id=tx.id,
            product_id=tx.product_id,
            product_name=name,
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
