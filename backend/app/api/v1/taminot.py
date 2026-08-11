"""Ta'minot — ichki/tashqi ta'minot API.

Har bir yozuv `scope` (ichki/tashqi) bilan ajratiladi. RUXSATLAR HAR SCOPE
UCHUN ALOHIDA:
  - ichki  -> `supply_ichki:read|write|delete`
  - tashqi -> `supply_tashqi:read|write|delete`
Shu sabab ichki va tashqi ta'minot turli odamlarga alohida lavozim sifatida
biriktirilishi mumkin.

IKKI DARAJA:
  1) YETKAZIB BERUVCHI (`TaminotSupplier`) — pul hisobi shu yerda. Bitta joydan
     nechta mahsulot olinishidan qat'i nazar qarz bitta:
         qarz = Σ purchase.amount − Σ payment.amount   (valyuta bo'yicha alohida)
     To'lov ham, kirim hujjati ham shu daraja bilan ishlaydi.
  2) MAHSULOT (`TaminotProduct`) — OMBOR QOLDIG'I shu yerda:
         qoldiq = olib kelingan (purchase.qty) − sarflangan (consume.qty)
                  + to'g'rilashlar (adjust.qty)
     Qoldiq mahsulotning `min_qty` chegarasidan past bo'lsa — "kam qoldi" (low),
     0 va past bo'lsa — "tugadi" (out) holati qaytariladi.

Mahsulot darajasida ALOHIDA QARZ YO'Q — to'lovlar yetkazib beruvchiga qilingani
uchun uni mahsulotlarga bo'lib chiqish mumkin emas va kerak ham emas.
"""
import uuid
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import (
    case, delete as sa_delete, func, or_, select, update as sa_update,
)
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import CurrentUser
from app.core.permissions import has_permission
from app.db.session import get_db
from app.models.taminot import (
    TaminotProduct, TaminotPurchaseList, TaminotPurchaseListItem, TaminotSupplier,
    TaminotTransaction,
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
    SupplierCurrencyTotal,
    SupplierPurchaseCreate,
    TaminotProductCreate,
    TaminotProductOut,
    TaminotProductUpdate,
    TaminotSummary,
    TaminotSupplierCreate,
    TaminotSupplierOut,
    TaminotSupplierUpdate,
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


async def _aggregates(db: AsyncSession, product_ids: Optional[list[uuid.UUID]] = None,
                      include_archived: bool = False):
    """product_id -> pul va miqdor yig'indilari xaritasi.

    Pul: purchased (shu mahsulotdan qancha olib kelingan). To'lovlar yetkazib
    beruvchiga qilingani uchun mahsulot darajasida "to'langan"/"qarz" yo'q.
    Miqdor (ombor qoldig'i uchun): in_qty (olib kelingan), out_qty (sarflangan),
    adjust_qty (to'g'rilashlar).
    """
    q = select(
        TaminotTransaction.product_id,
        func.coalesce(
            func.sum(case((TaminotTransaction.kind == "purchase", TaminotTransaction.amount), else_=0)), 0
        ).label("purchased"),
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
    ).where(
        # Yetkazib beruvchiga qilingan umumiy to'lovda mahsulot bo'lmaydi
        TaminotTransaction.product_id.is_not(None),
    ).group_by(TaminotTransaction.product_id)
    if not include_archived:
        # Arxivdagilar hisobga qo'shilmaydi. `include_archived` faqat arxiv
        # ro'yxatida ishlatiladi — u yerda "nechta yozuv saqlangani" ko'rsatiladi.
        q = q.where(TaminotTransaction.deleted_at.is_(None))
    if product_ids is not None:
        if not product_ids:
            return {}
        q = q.where(TaminotTransaction.product_id.in_(product_ids))
    res = await db.execute(q)
    out: dict[uuid.UUID, dict] = {}
    for row in res.all():
        out[row.product_id] = {
            "purchased": _q(row.purchased),
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


def _build_out(p: TaminotProduct, agg: dict,
               supplier_name: Optional[str] = None) -> TaminotProductOut:
    purchased = agg.get("purchased", 0.0)
    in_qty = agg.get("in_qty", 0.0)
    out_qty = agg.get("out_qty", 0.0)
    adjust_qty = agg.get("adjust_qty", 0.0)
    tx_count = agg.get("tx_count", 0)
    stock = round(in_qty - out_qty + adjust_qty, 3)
    min_qty = _q(p.min_qty)
    return TaminotProductOut(
        id=p.id,
        scope=p.scope,
        supplier_id=p.supplier_id,
        supplier_name=supplier_name,
        name=p.name,
        unit=p.unit,
        unit_price=_q(p.unit_price),
        currency=p.currency,
        min_qty=min_qty,
        note=p.note,
        created_at=p.created_at,
        total_purchased=purchased,
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


async def _get_product(db: AsyncSession, product_id: uuid.UUID,
                       allow_archived: bool = False) -> TaminotProduct:
    p = (await db.execute(
        select(TaminotProduct).where(TaminotProduct.id == product_id)
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    if p.deleted_at is not None and not allow_archived:
        raise HTTPException(400, f"«{p.name}» arxivga o'tgan — u bilan ishlab bo'lmaydi")
    return p


async def _get_supplier(db: AsyncSession, supplier_id: uuid.UUID) -> TaminotSupplier:
    sp = (await db.execute(
        select(TaminotSupplier).where(TaminotSupplier.id == supplier_id)
    )).scalar_one_or_none()
    if not sp:
        raise HTTPException(404, "Yetkazib beruvchi topilmadi")
    return sp


# ===========================================================================
# Yetkazib beruvchi — pul hisobining asosiy darajasi
# ===========================================================================
async def _supplier_money(
    db: AsyncSession, supplier_ids: Optional[list[uuid.UUID]] = None
) -> dict[uuid.UUID, dict[str, dict]]:
    """supplier_id -> {valyuta: {purchased, paid, last_purchase_at}} xaritasi.

    Bu yerda mahsulotlar bo'yicha ajratilmaydi — bitta yetkazib beruvchining
    barcha kirimlari va to'lovlari valyuta kesimida jamlanadi. Aynan shu
    "bitta joydan 15 xil mahsulot olinsa ham hisob bitta" qoidasini beradi.
    """
    q = select(
        TaminotTransaction.supplier_id,
        TaminotTransaction.currency,
        func.coalesce(func.sum(case(
            (TaminotTransaction.kind == "purchase", TaminotTransaction.amount), else_=0)), 0
        ).label("purchased"),
        func.coalesce(func.sum(case(
            (TaminotTransaction.kind == "payment", TaminotTransaction.amount), else_=0)), 0
        ).label("paid"),
        func.max(case(
            (TaminotTransaction.kind == "purchase", TaminotTransaction.created_at), else_=None)
        ).label("last_purchase_at"),
    ).where(
        # Arxivga o'tgan yozuvlar qarzga ham, to'lovga ham qo'shilmaydi
        TaminotTransaction.deleted_at.is_(None)
    ).group_by(TaminotTransaction.supplier_id, TaminotTransaction.currency)
    if supplier_ids is not None:
        if not supplier_ids:
            return {}
        q = q.where(TaminotTransaction.supplier_id.in_(supplier_ids))
    out: dict[uuid.UUID, dict[str, dict]] = {}
    for row in (await db.execute(q)).all():
        out.setdefault(row.supplier_id, {})[row.currency or "UZS"] = {
            "purchased": _q(row.purchased),
            "paid": _q(row.paid),
            "last_purchase_at": row.last_purchase_at,
        }
    return out


async def _supplier_stock(
    db: AsyncSession, supplier_ids: list[uuid.UUID]
) -> dict[uuid.UUID, dict]:
    """supplier_id -> {product_count, stock_value: {valyuta: summa}, low, out}.

    Ombor qoldig'i har mahsulot uchun alohida hisoblanadi, keyin yetkazib
    beruvchi bo'yicha jamlanadi — shu bilan "qaysi joyda nima kam qolgan"
    bir qarashda ko'rinadi.
    """
    if not supplier_ids:
        return {}
    products = (await db.execute(
        select(TaminotProduct).where(
            TaminotProduct.supplier_id.in_(supplier_ids),
            TaminotProduct.deleted_at.is_(None),
        )
    )).scalars().all()
    agg = await _aggregates(db, [p.id for p in products])
    out: dict[uuid.UUID, dict] = {
        sid: {"product_count": 0, "stock_value": {}, "low": 0, "out": 0}
        for sid in supplier_ids
    }
    for p in products:
        slot = out.setdefault(
            p.supplier_id, {"product_count": 0, "stock_value": {}, "low": 0, "out": 0}
        )
        o = _build_out(p, agg.get(p.id, {}))
        slot["product_count"] += 1
        cur = o.currency or "UZS"
        slot["stock_value"][cur] = slot["stock_value"].get(cur, 0.0) + o.stock_value
        if o.stock_status == "low":
            slot["low"] += 1
        elif o.stock_status == "out":
            slot["out"] += 1
    return out


def _supplier_out(sp: TaminotSupplier, money: dict[str, dict],
                  stock: dict) -> TaminotSupplierOut:
    """Yetkazib beruvchi javobi. Valyutalar hech qachon qo'shilmaydi."""
    stock_value: dict = stock.get("stock_value", {})
    currencies = sorted(set(money.keys()) | set(stock_value.keys()))
    totals: list[SupplierCurrencyTotal] = []
    last_purchase = None
    for cur in currencies:
        m = money.get(cur, {})
        purchased = m.get("purchased", 0.0)
        paid = m.get("paid", 0.0)
        totals.append(SupplierCurrencyTotal(
            currency=cur,
            total_purchased=round(purchased, 2),
            total_paid=round(paid, 2),
            balance=round(purchased - paid, 2),
            stock_value=round(stock_value.get(cur, 0.0), 2),
        ))
        lp = m.get("last_purchase_at")
        if lp and (last_purchase is None or lp > last_purchase):
            last_purchase = lp
    # Hech qanday harakat bo'lmasa ham bitta bo'sh qator ko'rsatiladi
    if not totals:
        totals = [SupplierCurrencyTotal(currency="UZS")]
    return TaminotSupplierOut(
        id=sp.id,
        scope=sp.scope,
        name=sp.name,
        phone=sp.phone,
        note=sp.note,
        created_at=sp.created_at,
        product_count=stock.get("product_count", 0),
        totals=totals,
        last_purchase_at=last_purchase,
        low_stock_count=stock.get("low", 0),
        out_of_stock_count=stock.get("out", 0),
    )


async def _suppliers_out(db: AsyncSession,
                         suppliers: list[TaminotSupplier]) -> list[TaminotSupplierOut]:
    ids = [s.id for s in suppliers]
    money = await _supplier_money(db, ids)
    stock = await _supplier_stock(db, ids)
    return [_supplier_out(s, money.get(s.id, {}), stock.get(s.id, {})) for s in suppliers]


@router.get("/suppliers", response_model=list[TaminotSupplierOut])
async def list_suppliers(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    scope: str = Query(..., description="ichki / tashqi"),
    search: Optional[str] = None,
    with_debt: bool = Query(False, description="Faqat qarzi borlar"),
):
    _require_scope(user, scope, "read")
    q = select(TaminotSupplier).where(TaminotSupplier.scope == scope)
    if search:
        like = f"%{search.strip()}%"
        q = q.where(or_(TaminotSupplier.name.ilike(like), TaminotSupplier.phone.ilike(like)))
    suppliers = (await db.execute(q.order_by(TaminotSupplier.name.asc()))).scalars().all()
    out = await _suppliers_out(db, list(suppliers))
    if with_debt:
        out = [o for o in out if any(t.balance > 0 for t in o.totals)]
    return out


@router.post("/suppliers", response_model=TaminotSupplierOut, status_code=201)
async def create_supplier(
    payload: TaminotSupplierCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    scope = _require_scope(user, _check_scope(payload.scope), "write")
    name = (payload.name or "").strip()
    if not name:
        raise HTTPException(422, "Yetkazib beruvchi nomini kiriting")
    # Bir scope ichida bir xil nom ikki marta bo'lmasin — aks holda qarz
    # ikkiga bo'linib ketadi va butun g'oya buziladi
    exists = (await db.execute(
        select(TaminotSupplier.id).where(
            TaminotSupplier.scope == scope, func.lower(TaminotSupplier.name) == name.lower()
        )
    )).first()
    if exists:
        raise HTTPException(409, f"«{name}» allaqachon mavjud")
    sp = TaminotSupplier(
        scope=scope, name=name, phone=(payload.phone or "").strip() or None,
        note=(payload.note or "").strip() or None, created_by_id=user.id,
    )
    db.add(sp)
    await db.commit()
    await db.refresh(sp)
    return _supplier_out(sp, {}, {})


@router.get("/suppliers/{supplier_id}", response_model=TaminotSupplierOut)
async def get_supplier(
    supplier_id: uuid.UUID, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    sp = await _get_supplier(db, supplier_id)
    _require_scope(user, sp.scope, "read")
    return (await _suppliers_out(db, [sp]))[0]


@router.patch("/suppliers/{supplier_id}", response_model=TaminotSupplierOut)
async def update_supplier(
    supplier_id: uuid.UUID,
    payload: TaminotSupplierUpdate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    sp = await _get_supplier(db, supplier_id)
    _require_scope(user, sp.scope, "write")
    data = payload.model_dump(exclude_unset=True)
    if "name" in data:
        name = (data["name"] or "").strip()
        if not name:
            raise HTTPException(422, "Yetkazib beruvchi nomini kiriting")
        dup = (await db.execute(
            select(TaminotSupplier.id).where(
                TaminotSupplier.scope == sp.scope,
                func.lower(TaminotSupplier.name) == name.lower(),
                TaminotSupplier.id != sp.id,
            )
        )).first()
        if dup:
            raise HTTPException(409, f"«{name}» allaqachon mavjud")
        sp.name = name
    if "phone" in data:
        sp.phone = (data["phone"] or "").strip() or None
    if "note" in data:
        sp.note = (data["note"] or "").strip() or None
    await db.commit()
    await db.refresh(sp)
    return (await _suppliers_out(db, [sp]))[0]


@router.delete("/suppliers/{supplier_id}", status_code=204)
async def delete_supplier(
    supplier_id: uuid.UUID, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    """Yetkazib beruvchini o'chiradi.

    Mahsuloti yoki harakati bo'lsa o'chirilmaydi — aks holda qarz tarixi
    yo'qoladi. Avval mahsulotlar boshqa joyga ko'chiriladi yoki o'chiriladi.
    """
    sp = await _get_supplier(db, supplier_id)
    _require_scope(user, sp.scope, "delete")
    products = (await db.execute(
        select(func.count(TaminotProduct.id)).where(TaminotProduct.supplier_id == sp.id)
    )).scalar_one()
    if products:
        raise HTTPException(
            400,
            f"«{sp.name}» da {products} ta mahsulot bor. Avval ularni boshqa "
            "yetkazib beruvchiga ko'chiring yoki o'chiring.",
        )
    txs = (await db.execute(
        select(func.count(TaminotTransaction.id)).where(TaminotTransaction.supplier_id == sp.id)
    )).scalar_one()
    if txs:
        raise HTTPException(
            400, f"«{sp.name}» bo'yicha {txs} ta harakat tarixda bor — o'chirib bo'lmaydi",
        )
    await db.delete(sp)
    await db.commit()


@router.post("/suppliers/{supplier_id}/payment", response_model=TaminotTransactionOut,
             status_code=201)
async def add_supplier_payment(
    supplier_id: uuid.UUID,
    payload: PaymentCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Yetkazib beruvchiga qarz to'lash — uning umumiy qarzini kamaytiradi.

    To'lov mahsulotga biriktirilmaydi (`product_id` bo'sh): bitta joyda 15 xil
    mahsulot bo'lsa ham to'lov bitta — o'sha joyga nisbatan.
    """
    sp = await _get_supplier(db, supplier_id)
    _require_scope(user, sp.scope, "write")
    currency = (payload.currency or "UZS").upper()
    tx = TaminotTransaction(
        supplier_id=sp.id,
        product_id=None,
        kind="payment",
        qty=Decimal("0"),
        unit_price=Decimal("0"),
        amount=Decimal(str(payload.amount)).quantize(Decimal("0.01")),
        currency=currency,
        note=payload.note,
        created_by_id=user.id,
    )
    db.add(tx)
    await db.commit()
    await db.refresh(tx)
    return tx


@router.post("/suppliers/{supplier_id}/purchase", response_model=TaminotSupplierOut,
             status_code=201)
async def add_supplier_purchase(
    supplier_id: uuid.UUID,
    payload: SupplierPurchaseCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """KIRIM HUJJATI — bir yo'la bir necha mahsulotni olib kelish.

    Har qator uchun `purchase` yoziladi: mahsulotning ombor qoldig'i oshadi,
    summasi esa yetkazib beruvchining umumiy qarziga qo'shiladi.
    `payment_mode="cash"` bo'lsa har qatorga darhol to'lov ham yoziladi —
    qoldiq baribir oshadi, qarz esa oshmaydi.
    """
    sp = await _get_supplier(db, supplier_id)
    _require_scope(user, sp.scope, "write")
    if not payload.items:
        raise HTTPException(422, "Kamida bitta mahsulot kiriting")

    prods = await _products_of(db, [i.product_id for i in payload.items])
    seen: set[uuid.UUID] = set()
    for it in payload.items:
        prod = prods.get(it.product_id)
        if not prod:
            raise HTTPException(422, "Mahsulot topilmadi")
        if prod.deleted_at is not None:
            raise HTTPException(422, f"«{prod.name}» arxivda — kirim qilib bo'lmaydi")
        if prod.supplier_id != sp.id:
            raise HTTPException(422, f"«{prod.name}» boshqa yetkazib beruvchiga tegishli")
        if it.product_id in seen:
            raise HTTPException(422, f"«{prod.name}» ikki marta kiritilgan")
        seen.add(it.product_id)

    cash = payload.payment_mode == "cash"
    base_note = (payload.note or "").strip() or None
    for it in payload.items:
        prod = prods[it.product_id]
        unit_price = (
            Decimal(str(it.unit_price)) if it.unit_price is not None else prod.unit_price
        )
        qty = Decimal(str(it.qty))
        amount = (qty * unit_price).quantize(Decimal("0.01"))
        db.add(TaminotTransaction(
            supplier_id=sp.id,
            product_id=prod.id,
            kind="purchase",
            qty=qty,
            unit_price=unit_price,
            amount=amount,
            currency=prod.currency,
            note=f"{base_note} · naqd" if (cash and base_note)
                 else ("Naqd olib kelish" if cash else base_note),
            created_by_id=user.id,
        ))
        if cash and amount > 0:
            db.add(TaminotTransaction(
                supplier_id=sp.id,
                product_id=prod.id,
                kind="payment",
                qty=Decimal("0"),
                unit_price=Decimal("0"),
                amount=amount,
                currency=prod.currency,
                note="Naqd to'lov (olib kelish bilan birga)",
                created_by_id=user.id,
            ))
    await db.commit()
    return (await _suppliers_out(db, [sp]))[0]


@router.get("/suppliers/{supplier_id}/transactions", response_model=list[TaminotTxLogOut])
async def supplier_transactions(
    supplier_id: uuid.UUID,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    limit: int = Query(300, le=2000),
):
    """Yetkazib beruvchining butun tarixi — kirimlar, to'lovlar, sarflar."""
    sp = await _get_supplier(db, supplier_id)
    _require_scope(user, sp.scope, "read")
    rows = (await db.execute(
        select(TaminotTransaction, TaminotProduct.name, TaminotProduct.unit)
        .outerjoin(TaminotProduct, TaminotProduct.id == TaminotTransaction.product_id)
        .where(TaminotTransaction.supplier_id == sp.id)
        .order_by(TaminotTransaction.created_at.desc())
        .limit(limit)
    )).all()
    return [
        TaminotTxLogOut(
            id=tx.id,
            supplier_id=sp.id,
            supplier_name=sp.name,
            product_id=tx.product_id,
            product_name=name,
            unit=unit or "dona",
            kind=tx.kind,
            qty=_q(tx.qty),
            unit_price=_q(tx.unit_price),
            amount=_q(tx.amount),
            currency=tx.currency,
            note=tx.note,
            created_at=tx.created_at,
            deleted_at=tx.deleted_at,
        )
        for tx, name, unit in rows
    ]


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
        select(TaminotProduct).where(
            TaminotProduct.scope == scope, TaminotProduct.deleted_at.is_(None)
        )
    )).scalars().all()
    agg = await _aggregates(db, [p.id for p in products])

    # Ombor holati — mahsulot darajasida
    by_cur: dict[str, dict] = {}
    counts = {"none": 0, "out": 0, "low": 0, "ok": 0}
    for p in products:
        o = _build_out(p, agg.get(p.id, {}))
        cur = o.currency or "UZS"
        slot = by_cur.setdefault(
            cur, {"purchased": 0.0, "paid": 0.0, "with_debt": 0, "stock_value": 0.0}
        )
        slot["stock_value"] += o.stock_value
        counts[o.stock_status] += 1

    # Pul hisobi — YETKAZIB BERUVCHI darajasida (qarz o'sha yerda yuritiladi)
    supplier_ids = [sid for (sid,) in (await db.execute(
        select(TaminotSupplier.id).where(TaminotSupplier.scope == scope)
    )).all()]
    money = await _supplier_money(db, supplier_ids)
    with_debt_suppliers = 0
    for per_cur in money.values():
        has_debt = False
        for cur, m in per_cur.items():
            slot = by_cur.setdefault(
                cur, {"purchased": 0.0, "paid": 0.0, "with_debt": 0, "stock_value": 0.0}
            )
            slot["purchased"] += m["purchased"]
            slot["paid"] += m["paid"]
            if m["purchased"] - m["paid"] > 0:
                slot["with_debt"] += 1
                has_debt = True
        if has_debt:
            with_debt_suppliers += 1

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
        supplier_count=len(supplier_ids),
        supplier_with_debt_count=with_debt_suppliers,
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
    supplier_id: Optional[uuid.UUID] = Query(None, description="Faqat shu yetkazib beruvchiniki"),
    low_stock: bool = Query(False, description="Faqat kam qolgan yoki tugagan mahsulotlar"),
    archived: bool = Query(False, description="Faqat arxivdagilar (o'chirilganlar)"),
    sort: str = Query("name", description="name / stock (kam qolganlar birinchi)"),
):
    _require_scope(user, scope, "read")
    q = (
        select(TaminotProduct, TaminotSupplier.name)
        .join(TaminotSupplier, TaminotSupplier.id == TaminotProduct.supplier_id)
        .where(
            TaminotProduct.scope == scope,
            TaminotProduct.deleted_at.is_not(None) if archived
            else TaminotProduct.deleted_at.is_(None),
        )
    )
    if supplier_id is not None:
        q = q.where(TaminotProduct.supplier_id == supplier_id)
    if search:
        like = f"%{search.strip()}%"
        q = q.where(or_(TaminotProduct.name.ilike(like), TaminotSupplier.name.ilike(like)))
    rows = (await db.execute(q.order_by(TaminotProduct.name.asc()))).all()
    products = [p for p, _ in rows]
    names = {p.id: sup_name for p, sup_name in rows}
    # Arxiv ro'yxatida saqlangan yozuvlar soni ko'rsatiladi — ular ham
    # arxivda bo'lgani uchun oddiy hisobga tushmaydi
    agg = await _aggregates(db, [p.id for p in products], include_archived=archived)
    out = [_build_out(p, agg.get(p.id, {}), names.get(p.id)) for p in products]
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
    """Mahsulot yaratish. Yetkazib beruvchi majburiy — mahsulot doim biror
    joyga tegishli bo'ladi va uning puli o'sha joyning hisobiga boradi."""
    scope = _require_scope(user, _check_scope(payload.scope), "write")
    sp = await _get_supplier(db, payload.supplier_id)
    if sp.scope != scope:
        raise HTTPException(422, "Yetkazib beruvchi boshqa ta'minot turiga tegishli")
    p = TaminotProduct(**payload.model_dump(), created_by_id=user.id)
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return _build_out(p, {}, sp.name)


@router.patch("/products/{product_id}", response_model=TaminotProductOut)
async def update_product(
    product_id: uuid.UUID,
    payload: TaminotProductUpdate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "write")
    data = payload.model_dump(exclude_unset=True)
    new_supplier_id = data.pop("supplier_id", None)
    if new_supplier_id is not None and new_supplier_id != p.supplier_id:
        sp = await _get_supplier(db, new_supplier_id)
        if sp.scope != p.scope:
            raise HTTPException(422, "Yetkazib beruvchi boshqa ta'minot turiga tegishli")
        # Mahsulot bilan birga uning butun tarixi ham yangi joyning hisobiga
        # o'tadi — aks holda eski joyda "egasiz" qarz osilib qolardi.
        await db.execute(
            sa_update(TaminotTransaction)
            .where(TaminotTransaction.product_id == p.id)
            .values(supplier_id=sp.id)
        )
        p.supplier_id = sp.id
    for k, v in data.items():
        setattr(p, k, v)
    await db.commit()
    await db.refresh(p)
    agg = await _aggregates(db, [p.id])
    sup = await _get_supplier(db, p.supplier_id)
    return _build_out(p, agg.get(p.id, {}), sup.name)


@router.delete("/products/{product_id}", status_code=204)
async def delete_product(
    product_id: uuid.UUID,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Mahsulotni o'chiradi.

    OMBORDA QOLDIG'I BOR MAHSULOT O'CHIRILMAYDI — u jismonan omborda turibdi,
    yozuvni yo'q qilish qoldiqni "havoga uchirib" yuboradi. Avval sarflanadi
    yoki inventarizatsiya orqali qoldiq 0 ga tushiriladi.

    Harakatlari bo'lsa BAZADAN YO'Q QILINMAYDI — mahsulot ham, yozuvlari ham
    arxivga o'tadi: qarz va ombor hisobidan chiqadi (summa to'g'ri ayiriladi),
    lekin tarixda ustidan chizilgan holda ko'rinib turadi. Hech qanday harakati
    bo'lmagan mahsulot esa oddiy o'chiriladi — saqlanadigan tarix yo'q.
    """
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "delete")
    stock = await _current_stock(db, product_id)
    if stock > 0:
        raise HTTPException(
            400,
            f"«{p.name}» omborda {stock:g} {p.unit} qoldiq bor — o'chirib bo'lmaydi. "
            "Avval sarflang yoki «Qoldiqni to'g'rilash» orqali 0 ga tushiring.",
        )
    now = datetime.now(timezone.utc)
    tx_count = (await db.execute(
        select(func.count(TaminotTransaction.id))
        .where(TaminotTransaction.product_id == p.id)
    )).scalar_one()
    if tx_count:
        await db.execute(
            sa_update(TaminotTransaction)
            .where(TaminotTransaction.product_id == p.id,
                   TaminotTransaction.deleted_at.is_(None))
            .values(deleted_at=now, deleted_by_id=user.id)
        )
        p.deleted_at = now
    else:
        await db.delete(p)
    await db.commit()


# ---------------------------------------------------------------------------
# Tranzaksiyalar (bitta mahsulot tarixi)
# ---------------------------------------------------------------------------
@router.get("/products/{product_id}/transactions", response_model=list[TaminotTransactionOut])
async def list_transactions(
    product_id: uuid.UUID, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    # Arxivdagi mahsulotning tarixi ham ochiladi — u yo'qolmagan
    p = await _get_product(db, product_id, allow_archived=True)
    _require_scope(user, p.scope, "read")
    # Arxivga o'tganlar ham qaytariladi (`deleted_at` bilan) — ular ro'yxatda
    # ustidan chizilgan holda ko'rsatiladi
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
    """Bitta mahsulotni tez olib kelish (ro'yxatdagi [+] tugmasi).

    Guruhdan faqat bitta mahsulot kerak bo'lganda ishlatiladi. Summa baribir
    mahsulotning yetkazib beruvchisi hisobiga boradi — ko'p mahsulotli kirim
    hujjatidan farqi faqat qulaylikda.
    """
    p = await _get_product(db, product_id)
    _require_scope(user, p.scope, "write")
    unit_price = Decimal(str(payload.unit_price)) if payload.unit_price is not None else p.unit_price
    qty = Decimal(str(payload.qty))
    amount = (qty * unit_price).quantize(Decimal("0.01"))
    cash = payload.payment_mode == "cash"
    note = payload.note
    tx = TaminotTransaction(
        supplier_id=p.supplier_id,
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
            supplier_id=p.supplier_id,
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
        supplier_id=p.supplier_id,
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
        supplier_id=p.supplier_id,
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
    """Harakatni ARXIVGA o'tkazadi (bazadan o'chirmaydi).

    Shu daqiqadan boshlab yozuv qarz, to'lov va ombor qoldig'i hisobiga
    qo'shilmaydi — summa to'g'ri ayiriladi. Lekin u tarixda ustidan chizilgan
    holda ko'rinib turadi va kerak bo'lsa qaytarib tiklanadi.
    """
    tx = (await db.execute(
        select(TaminotTransaction).where(TaminotTransaction.id == tx_id)
    )).scalar_one_or_none()
    if not tx:
        raise HTTPException(404, "Tranzaksiya topilmadi")
    # Ruxsat yetkazib beruvchining bo'limidan olinadi — to'lovda mahsulot yo'q
    sp = await _get_supplier(db, tx.supplier_id)
    _require_scope(user, sp.scope, "delete")
    if tx.deleted_at is not None:
        raise HTTPException(400, "Bu yozuv allaqachon arxivda")
    tx.deleted_at = datetime.now(timezone.utc)
    tx.deleted_by_id = user.id
    await db.commit()


@router.post("/transactions/{tx_id}/restore", response_model=TaminotTransactionOut)
async def restore_transaction(
    tx_id: uuid.UUID,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Arxivdagi harakatni tiklaydi — summa yana hisobga qo'shiladi."""
    tx = (await db.execute(
        select(TaminotTransaction).where(TaminotTransaction.id == tx_id)
    )).scalar_one_or_none()
    if not tx:
        raise HTTPException(404, "Tranzaksiya topilmadi")
    sp = await _get_supplier(db, tx.supplier_id)
    _require_scope(user, sp.scope, "delete")
    if tx.deleted_at is None:
        raise HTTPException(400, "Bu yozuv arxivda emas")
    # Mahsuloti arxivda bo'lsa yozuvni tiklash mantiqsiz — avval mahsulot kerak
    if tx.product_id is not None:
        prod = await _get_product(db, tx.product_id, allow_archived=True)
        if prod.deleted_at is not None:
            raise HTTPException(
                400, f"«{prod.name}» arxivda — avval mahsulotni tiklash kerak"
            )
    tx.deleted_at = None
    tx.deleted_by_id = None
    await db.commit()
    await db.refresh(tx)
    return tx


@router.post("/products/{product_id}/restore", response_model=TaminotProductOut)
async def restore_product(
    product_id: uuid.UUID,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Arxivdagi mahsulotni yozuvlari bilan birga tiklaydi."""
    p = await _get_product(db, product_id, allow_archived=True)
    _require_scope(user, p.scope, "delete")
    if p.deleted_at is None:
        raise HTTPException(400, "Bu mahsulot arxivda emas")
    archived_at = p.deleted_at
    # Faqat mahsulot bilan birga arxivlanganlar tiklanadi — undan oldin
    # alohida o'chirilgan yozuvlar arxivda qoladi
    await db.execute(
        sa_update(TaminotTransaction)
        .where(TaminotTransaction.product_id == p.id,
               TaminotTransaction.deleted_at == archived_at)
        .values(deleted_at=None, deleted_by_id=None)
    )
    p.deleted_at = None
    await db.commit()
    await db.refresh(p)
    agg = await _aggregates(db, [p.id])
    sup = await _get_supplier(db, p.supplier_id)
    return _build_out(p, agg.get(p.id, {}), sup.name)


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
    # Bog'lanish yetkazib beruvchi orqali — to'lovlarda mahsulot bo'lmaydi,
    # shuning uchun mahsulotga LEFT JOIN qilinadi
    q = (
        select(
            TaminotTransaction,
            TaminotProduct.name,
            TaminotProduct.unit,
            TaminotSupplier.name.label("supplier_name"),
        )
        .join(TaminotSupplier, TaminotSupplier.id == TaminotTransaction.supplier_id)
        .outerjoin(TaminotProduct, TaminotProduct.id == TaminotTransaction.product_id)
        .where(TaminotSupplier.scope == scope)
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
    for tx, name, unit, supplier_name in res.all():
        out.append(TaminotTxLogOut(
            id=tx.id,
            supplier_id=tx.supplier_id,
            supplier_name=supplier_name,
            product_id=tx.product_id,
            product_name=name,
            unit=unit or "dona",
            kind=tx.kind,
            qty=_q(tx.qty),
            unit_price=_q(tx.unit_price),
            amount=_q(tx.amount),
            currency=tx.currency,
            note=tx.note,
            created_at=tx.created_at,
            deleted_at=tx.deleted_at,
        ))
    return out


# ===========================================================================
# Xarid spiskasi — ta'minotchi uchun reja ro'yxati
# ===========================================================================
def _list_out(pl: TaminotPurchaseList, products: dict[uuid.UUID, TaminotProduct],
              supplier_name: Optional[str] = None) -> PurchaseListOut:
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
        id=pl.id, scope=pl.scope, supplier_id=pl.supplier_id, supplier_name=supplier_name,
        title=pl.title, status=pl.status, note=pl.note,
        applied_at=pl.applied_at, created_at=pl.created_at,
        items=items,
        totals=[PurchaseListTotal(currency=c, amount=a) for c, a in sorted(totals.items())],
        item_count=len(items),
    )


async def _supplier_names(db: AsyncSession, ids: list[uuid.UUID]) -> dict[uuid.UUID, str]:
    if not ids:
        return {}
    rows = (await db.execute(
        select(TaminotSupplier.id, TaminotSupplier.name).where(TaminotSupplier.id.in_(ids))
    )).all()
    return {sid: name for sid, name in rows}


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
        if prod.deleted_at is not None:
            raise HTTPException(422, f"«{prod.name}» arxivda — spiskaga qo'shib bo'lmaydi")
        if prod.scope != pl.scope:
            raise HTTPException(422, f"«{prod.name}» boshqa ta'minot turiga tegishli")
        # Spiska bitta joyga borish uchun — begona mahsulot aralashmaydi
        if prod.supplier_id != pl.supplier_id:
            raise HTTPException(422, f"«{prod.name}» boshqa yetkazib beruvchiga tegishli")
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
    supplier_id: Optional[uuid.UUID] = Query(None, description="Faqat shu yetkazib beruvchiniki"),
    status: Optional[str] = None,
):
    scope = _require_scope(user, _check_scope(scope), "read")
    q = select(TaminotPurchaseList).where(TaminotPurchaseList.scope == scope)
    if supplier_id is not None:
        q = q.where(TaminotPurchaseList.supplier_id == supplier_id)
    if status:
        q = q.where(TaminotPurchaseList.status == status)
    q = q.order_by(TaminotPurchaseList.created_at.desc()).options(
        selectinload(TaminotPurchaseList.items)
    )
    lists = (await db.execute(q)).scalars().all()
    prods = await _products_of(db, [i.product_id for pl in lists for i in pl.items])
    names = await _supplier_names(db, [pl.supplier_id for pl in lists])
    return [_list_out(pl, prods, names.get(pl.supplier_id)) for pl in lists]


@router.post("/lists", response_model=PurchaseListOut, status_code=201)
async def create_purchase_list(
    payload: PurchaseListCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    scope = _require_scope(user, _check_scope(payload.scope), "write")
    sp = await _get_supplier(db, payload.supplier_id)
    if sp.scope != scope:
        raise HTTPException(422, "Yetkazib beruvchi boshqa ta'minot turiga tegishli")
    pl = TaminotPurchaseList(
        scope=scope, supplier_id=sp.id,
        title=(payload.title or None), note=(payload.note or None),
        status="draft", created_by_id=user.id,
    )
    db.add(pl)
    await db.flush()
    await _replace_items(db, pl, payload.items)
    await db.commit()
    pl = await _load_list(db, pl.id)
    prods = await _products_of(db, [i.product_id for i in pl.items])
    return _list_out(pl, prods, sp.name)


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
    names = await _supplier_names(db, [pl.supplier_id])
    return _list_out(pl, prods, names.get(pl.supplier_id))


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
            supplier_id=pl.supplier_id,
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
                supplier_id=pl.supplier_id,
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
    names = await _supplier_names(db, [pl.supplier_id])
    return _list_out(pl, prods, names.get(pl.supplier_id))


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
