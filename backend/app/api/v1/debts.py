"""Bizning qarzlar — mustaqil modul API.

Boshqa bo'limlarga (moliya, savdo, ta'minot) hech qanday ta'sir qilmaydi.
"""
import uuid
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import case, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.debt import DebtProduct, DebtTransaction
from app.schemas.debt import (
    CurrencyTotal,
    DebtProductCreate,
    DebtProductOut,
    DebtProductUpdate,
    DebtSummary,
    DebtTransactionOut,
    PaymentCreate,
    PurchaseCreate,
)

router = APIRouter(dependencies=[Depends(module_guard("debts"))])


def _q(v) -> float:
    return float(v or 0)


async def _aggregates(db: AsyncSession, product_ids: Optional[list[uuid.UUID]] = None):
    """product_id -> {purchased, paid, last_purchase_at, tx_count} xaritasi."""
    q = select(
        DebtTransaction.product_id,
        func.coalesce(
            func.sum(
                case((DebtTransaction.kind == "purchase", DebtTransaction.amount), else_=0)
            ),
            0,
        ).label("purchased"),
        func.coalesce(
            func.sum(
                case((DebtTransaction.kind == "payment", DebtTransaction.amount), else_=0)
            ),
            0,
        ).label("paid"),
        func.max(
            case(
                (DebtTransaction.kind == "purchase", DebtTransaction.created_at), else_=None
            )
        ).label("last_purchase_at"),
        func.count(DebtTransaction.id).label("tx_count"),
    ).group_by(DebtTransaction.product_id)
    if product_ids is not None:
        if not product_ids:
            return {}
        q = q.where(DebtTransaction.product_id.in_(product_ids))
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


def _build_out(p: DebtProduct, agg: dict) -> DebtProductOut:
    purchased = agg.get("purchased", 0.0)
    paid = agg.get("paid", 0.0)
    return DebtProductOut(
        id=p.id,
        name=p.name,
        debt_type=p.debt_type,
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


# ---------------------------------------------------------------------------
# Umumiy hisob
# ---------------------------------------------------------------------------
@router.get("/summary", response_model=DebtSummary)
async def debt_summary(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    # Har bir (mahsulot, valyuta) bo'yicha qarz/to'lov — valyutalarni aralashtirmaymiz
    res = await db.execute(
        select(
            DebtTransaction.product_id,
            DebtTransaction.currency,
            func.coalesce(
                func.sum(case((DebtTransaction.kind == "purchase", DebtTransaction.amount), else_=0)), 0
            ).label("purchased"),
            func.coalesce(
                func.sum(case((DebtTransaction.kind == "payment", DebtTransaction.amount), else_=0)), 0
            ).label("paid"),
        ).group_by(DebtTransaction.product_id, DebtTransaction.currency)
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

    product_count = (await db.execute(select(func.count(DebtProduct.id)))).scalar() or 0
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
    return DebtSummary(by_currency=totals, product_count=product_count)


# ---------------------------------------------------------------------------
# Ehtiyot qismlar (mahsulotlar)
# ---------------------------------------------------------------------------
@router.get("/products", response_model=list[DebtProductOut])
async def list_products(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: CurrentUser,
    search: Optional[str] = None,
    with_debt: bool = Query(False, description="Faqat qarzi borlar"),
):
    q = select(DebtProduct)
    if search:
        like = f"%{search.strip()}%"
        q = q.where(or_(DebtProduct.name.ilike(like), DebtProduct.supplier.ilike(like)))
    res = await db.execute(q.order_by(DebtProduct.name.asc()))
    products = res.scalars().all()
    agg = await _aggregates(db, [p.id for p in products])
    out = [_build_out(p, agg.get(p.id, {})) for p in products]
    if with_debt:
        out = [o for o in out if o.balance > 0]
    return out


@router.post("/products", response_model=DebtProductOut, status_code=201)
async def create_product(
    payload: DebtProductCreate, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    p = DebtProduct(**payload.model_dump(), created_by_id=user.id)
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return _build_out(p, {})


@router.patch("/products/{product_id}", response_model=DebtProductOut)
async def update_product(
    product_id: uuid.UUID,
    payload: DebtProductUpdate,
    _: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = (await db.execute(select(DebtProduct).where(DebtProduct.id == product_id))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(p, k, v)
    await db.commit()
    await db.refresh(p)
    agg = await _aggregates(db, [p.id])
    return _build_out(p, agg.get(p.id, {}))


@router.delete("/products/{product_id}", status_code=204)
async def delete_product(
    product_id: uuid.UUID, _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    p = (await db.execute(select(DebtProduct).where(DebtProduct.id == product_id))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    await db.delete(p)  # tranzaksiyalar cascade bilan o'chadi
    await db.commit()


# ---------------------------------------------------------------------------
# Tranzaksiyalar
# ---------------------------------------------------------------------------
@router.get("/products/{product_id}/transactions", response_model=list[DebtTransactionOut])
async def list_transactions(
    product_id: uuid.UUID, _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    p = (await db.execute(select(DebtProduct).where(DebtProduct.id == product_id))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    res = await db.execute(
        select(DebtTransaction)
        .where(DebtTransaction.product_id == product_id)
        .order_by(DebtTransaction.created_at.desc())
    )
    return res.scalars().all()


@router.post("/products/{product_id}/purchase", response_model=DebtTransactionOut, status_code=201)
async def add_purchase(
    product_id: uuid.UUID,
    payload: PurchaseCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = (await db.execute(select(DebtProduct).where(DebtProduct.id == product_id))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Qarz yozuvi topilmadi")

    if p.debt_type == "product":
        # Mahsulot: miqdor × birlik narxi
        if payload.qty is None or payload.qty <= 0:
            raise HTTPException(422, "Miqdor 0 dan katta bo'lishi kerak")
        unit_price = Decimal(str(payload.unit_price)) if payload.unit_price is not None else p.unit_price
        qty = Decimal(str(payload.qty))
        amount = (qty * unit_price).quantize(Decimal("0.01"))
    else:
        # Kredit/qarz/custom: to'g'ridan-to'g'ri summa
        if payload.amount is None or payload.amount <= 0:
            raise HTTPException(422, "Summa 0 dan katta bo'lishi kerak")
        qty = Decimal("0")
        unit_price = Decimal("0")
        amount = Decimal(str(payload.amount)).quantize(Decimal("0.01"))

    tx = DebtTransaction(
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


@router.post("/products/{product_id}/payment", response_model=DebtTransactionOut, status_code=201)
async def add_payment(
    product_id: uuid.UUID,
    payload: PaymentCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = (await db.execute(select(DebtProduct).where(DebtProduct.id == product_id))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    tx = DebtTransaction(
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
    tx_id: uuid.UUID, _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    tx = (await db.execute(select(DebtTransaction).where(DebtTransaction.id == tx_id))).scalar_one_or_none()
    if not tx:
        raise HTTPException(404, "Tranzaksiya topilmadi")
    await db.delete(tx)
    await db.commit()
