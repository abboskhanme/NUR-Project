"""Ta'minot: taminotchilar, mahsulotlar, kirimlar, qarz to'lovlari, ombor.

Taminotchi-asosli. Agar joriy foydalanuvchi biror taminotchiga (Vendor.user_id)
bog'langan bo'lsa — u faqat o'z mahsulotlari va kirimlarini ko'radi/boshqaradi.
Aks holda (admin/menejer) barcha taminotchilarni ko'radi.
"""
import uuid
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.supply import (
    GoodsReceipt, Item, StockMovement, Vendor, VendorPayment,
)
from app.models.system import Notification
from app.models.user import User
from app.schemas.common import Page
from app.schemas.supply import (
    GoodsReceiptIn, GoodsReceiptOut,
    ItemCreate, ItemOut, ItemUpdate,
    StockIssueIn,
    SupplySummary,
    VendorCreate, VendorOut, VendorUpdate,
    VendorPaymentIn, VendorPaymentOut,
)

router = APIRouter()

ZERO = Decimal(0)


# --------------------------------------------------------------------------- #
# Yordamchilar
# --------------------------------------------------------------------------- #
async def _my_vendor_id(user: User, db: AsyncSession) -> Optional[uuid.UUID]:
    """Joriy foydalanuvchi taminotchi akkauntiga bog'langan bo'lsa — uning vendor_id."""
    res = await db.execute(select(Vendor.id).where(Vendor.user_id == user.id))
    return res.scalar_one_or_none()


def _is_low(item: Item) -> bool:
    return bool(item.min_qty and item.min_qty > 0 and (item.stock_qty or ZERO) < item.min_qty)


def _ensure_item_in_scope(item: Item, scope: Optional[uuid.UUID]):
    if scope is not None and item.vendor_id != scope:
        raise HTTPException(status_code=403, detail="Bu mahsulot sizning taminotchingizga tegishli emas")


async def _notify_low_stock(db: AsyncSession, item: Item, actor_id: Optional[uuid.UUID]):
    """Zaxira minimumdan past tushganda bildirishnoma yaratish.
    Taminotchining login akkaunti va barcha superadminlar ogohlantiriladi."""
    recipients: set[uuid.UUID] = set()
    if actor_id:
        recipients.add(actor_id)

    if item.vendor_id:
        v = (await db.execute(select(Vendor).where(Vendor.id == item.vendor_id))).scalar_one_or_none()
        if v and v.user_id:
            recipients.add(v.user_id)

    admins = (await db.execute(select(User.id).where(User.is_superadmin.is_(True)))).scalars().all()
    recipients.update(admins)

    title = "Zaxira kam qoldi"
    body = (f"«{item.name}» — joriy qoldiq {item.stock_qty} {item.unit}, "
            f"minimum {item.min_qty} {item.unit}.")
    for uid in recipients:
        db.add(Notification(
            user_id=uid, channel="in_app", type="low_stock",
            title=title, body=body,
            payload={"item_id": str(item.id), "name": item.name,
                     "stock_qty": str(item.stock_qty), "min_qty": str(item.min_qty)},
        ))


# --------------------------------------------------------------------------- #
# Taminotchilar (Vendors)
# --------------------------------------------------------------------------- #
@router.get("/vendors", response_model=list[VendorOut])
async def list_vendors(db: Annotated[AsyncSession, Depends(get_db)], user: CurrentUser,
                       active_only: bool = False):
    scope = await _my_vendor_id(user, db)
    q = select(Vendor)
    if scope is not None:
        q = q.where(Vendor.id == scope)
    if active_only:
        q = q.where(Vendor.is_active.is_(True))
    vendors = (await db.execute(q.order_by(Vendor.name))).scalars().all()

    out: list[VendorOut] = []
    for v in vendors:
        debt = (await db.execute(
            select(func.coalesce(func.sum(GoodsReceipt.balance), 0))
            .where(GoodsReceipt.vendor_id == v.id)
        )).scalar() or ZERO
        items = (await db.execute(select(Item).where(Item.vendor_id == v.id))).scalars().all()
        low = sum(1 for it in items if _is_low(it))
        dto = VendorOut.model_validate(v)
        dto.open_debt = Decimal(debt)
        dto.items_count = len(items)
        dto.low_stock_count = low
        out.append(dto)
    return out


@router.post("/vendors", response_model=VendorOut, status_code=201,
             dependencies=[Depends(require_permission("supply:write"))])
async def create_vendor(payload: VendorCreate,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    if payload.user_id:
        clash = (await db.execute(select(Vendor).where(Vendor.user_id == payload.user_id))).scalar_one_or_none()
        if clash:
            raise HTTPException(status_code=400, detail="Bu foydalanuvchi allaqachon boshqa taminotchiga bog'langan")
    v = Vendor(**payload.model_dump())
    db.add(v)
    await db.commit()
    await db.refresh(v)
    return VendorOut.model_validate(v)


@router.patch("/vendors/{vendor_id}", response_model=VendorOut,
              dependencies=[Depends(require_permission("supply:write"))])
async def update_vendor(vendor_id: uuid.UUID, payload: VendorUpdate,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    v = (await db.execute(select(Vendor).where(Vendor.id == vendor_id))).scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Taminotchi topilmadi")
    data = payload.model_dump(exclude_unset=True)
    if data.get("user_id"):
        clash = (await db.execute(
            select(Vendor).where(Vendor.user_id == data["user_id"], Vendor.id != vendor_id)
        )).scalar_one_or_none()
        if clash:
            raise HTTPException(status_code=400, detail="Bu foydalanuvchi allaqachon boshqa taminotchiga bog'langan")
    for k, val in data.items():
        setattr(v, k, val)
    await db.commit()
    await db.refresh(v)
    return VendorOut.model_validate(v)


@router.get("/vendors/{vendor_id}/balance",
            dependencies=[Depends(require_permission("supply:read"))])
async def vendor_balance(vendor_id: uuid.UUID, _: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    """Joriy qarz = sum(receipt.balance)."""
    debt = (await db.execute(
        select(func.coalesce(func.sum(GoodsReceipt.balance), 0))
        .where(GoodsReceipt.vendor_id == vendor_id)
    )).scalar() or ZERO
    received = (await db.execute(
        select(func.coalesce(func.sum(GoodsReceipt.total), 0))
        .where(GoodsReceipt.vendor_id == vendor_id)
    )).scalar() or ZERO
    paid = (await db.execute(
        select(func.coalesce(func.sum(GoodsReceipt.paid), 0))
        .where(GoodsReceipt.vendor_id == vendor_id)
    )).scalar() or ZERO
    return {"vendor_id": str(vendor_id), "open_debt": float(debt),
            "total_received": float(received), "total_paid": float(paid)}


# --------------------------------------------------------------------------- #
# Mahsulotlar (Items)
# --------------------------------------------------------------------------- #
@router.get("/items", response_model=Page[ItemOut])
async def list_items(db: Annotated[AsyncSession, Depends(get_db)], user: CurrentUser,
                     vendor_id: Optional[uuid.UUID] = None,
                     search: Optional[str] = None,
                     low_stock_only: bool = False,
                     page: int = Query(1, ge=1), page_size: int = Query(50, ge=1, le=200)):
    scope = await _my_vendor_id(user, db)
    q = select(Item)
    if scope is not None:
        q = q.where(Item.vendor_id == scope)
    elif vendor_id:
        q = q.where(Item.vendor_id == vendor_id)
    if search:
        q = q.where(Item.name.ilike(f"%{search}%"))
    if low_stock_only:
        q = q.where(Item.min_qty > 0, Item.stock_qty < Item.min_qty)

    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar() or 0
    rows = (await db.execute(
        q.order_by(Item.name).offset((page - 1) * page_size).limit(page_size)
    )).scalars().all()

    items_out = []
    for it in rows:
        dto = ItemOut.model_validate(it)
        dto.is_low = _is_low(it)
        items_out.append(dto)
    return Page[ItemOut](items=items_out, total=total, page=page, page_size=page_size)


@router.post("/items", response_model=ItemOut, status_code=201,
             dependencies=[Depends(require_permission("supply:write"))])
async def create_item(payload: ItemCreate, user: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    data = payload.model_dump()
    scope = await _my_vendor_id(user, db)
    if scope is not None:
        data["vendor_id"] = scope  # taminotchi faqat o'ziga mahsulot qo'shadi
    i = Item(**data)
    db.add(i)
    await db.commit()
    await db.refresh(i)
    dto = ItemOut.model_validate(i)
    dto.is_low = _is_low(i)
    return dto


@router.patch("/items/{item_id}", response_model=ItemOut,
              dependencies=[Depends(require_permission("supply:write"))])
async def update_item(item_id: uuid.UUID, payload: ItemUpdate, user: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    it = (await db.execute(select(Item).where(Item.id == item_id))).scalar_one_or_none()
    if not it:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    scope = await _my_vendor_id(user, db)
    _ensure_item_in_scope(it, scope)
    data = payload.model_dump(exclude_unset=True)
    if scope is not None:
        data.pop("vendor_id", None)  # taminotchi vendor'ni o'zgartira olmaydi
    for k, val in data.items():
        setattr(it, k, val)
    await db.commit()
    await db.refresh(it)
    dto = ItemOut.model_validate(it)
    dto.is_low = _is_low(it)
    return dto


@router.delete("/items/{item_id}", status_code=204,
               dependencies=[Depends(require_permission("supply:delete"))])
async def delete_item(item_id: uuid.UUID, user: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    it = (await db.execute(select(Item).where(Item.id == item_id))).scalar_one_or_none()
    if not it:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    scope = await _my_vendor_id(user, db)
    _ensure_item_in_scope(it, scope)
    await db.delete(it)
    await db.commit()


# --------------------------------------------------------------------------- #
# Kirimlar (Goods Receipts)
# --------------------------------------------------------------------------- #
async def _enrich_receipt(r: GoodsReceipt, db: AsyncSession) -> GoodsReceiptOut:
    dto = GoodsReceiptOut.model_validate(r)
    it = (await db.execute(select(Item).where(Item.id == r.item_id))).scalar_one_or_none()
    v = (await db.execute(select(Vendor).where(Vendor.id == r.vendor_id))).scalar_one_or_none()
    if it:
        dto.item_name = it.name
        dto.unit = it.unit
    if v:
        dto.vendor_name = v.name
    return dto


@router.get("/receipts", response_model=list[GoodsReceiptOut])
async def list_receipts(db: Annotated[AsyncSession, Depends(get_db)], user: CurrentUser,
                        vendor_id: Optional[uuid.UUID] = None,
                        item_id: Optional[uuid.UUID] = None,
                        status: Optional[str] = None):
    scope = await _my_vendor_id(user, db)
    q = select(GoodsReceipt)
    if scope is not None:
        q = q.where(GoodsReceipt.vendor_id == scope)
    elif vendor_id:
        q = q.where(GoodsReceipt.vendor_id == vendor_id)
    if item_id:
        q = q.where(GoodsReceipt.item_id == item_id)
    if status:
        q = q.where(GoodsReceipt.status == status)
    rows = (await db.execute(q.order_by(GoodsReceipt.date.desc()).limit(500))).scalars().all()
    return [await _enrich_receipt(r, db) for r in rows]


@router.post("/receipts", response_model=GoodsReceiptOut, status_code=201,
             dependencies=[Depends(require_permission("supply:write"))])
async def create_receipt(payload: GoodsReceiptIn, user: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    item = (await db.execute(select(Item).where(Item.id == payload.item_id))).scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")

    scope = await _my_vendor_id(user, db)
    vendor_id = scope if scope is not None else (payload.vendor_id or item.vendor_id)
    if vendor_id is None:
        raise HTTPException(status_code=400, detail="Taminotchi tanlanmagan")
    _ensure_item_in_scope(item, scope)

    qty = payload.qty or ZERO
    if qty <= 0:
        raise HTTPException(status_code=400, detail="Miqdor 0 dan katta bo'lishi kerak")

    # Birlik narxi: kiritilgan bo'lsa o'shani, aks holda mahsulotning belgilangan narxi
    unit_price = payload.unit_price if payload.unit_price is not None else (item.unit_price or ZERO)
    total = (qty * unit_price).quantize(Decimal("0.01"))
    paid = payload.paid or ZERO
    if paid > total:
        paid = total
    balance = total - paid  # qolgan qarz
    status = "paid" if balance <= 0 else ("partial" if paid > 0 else "open")

    r = GoodsReceipt(
        date=payload.date, vendor_id=vendor_id, item_id=item.id,
        qty=qty, unit_price=unit_price, total=total, paid=paid, balance=balance,
        status=status, note=payload.note, created_by_id=user.id,
    )
    db.add(r)
    await db.flush()  # r.id kerak

    # Ombor harakati + zaxira
    db.add(StockMovement(item_id=item.id, qty_change=qty, reason="receipt",
                         ref_id=r.id, note=payload.note, created_by_id=user.id))
    item.stock_qty = (item.stock_qty or ZERO) + qty

    await db.commit()
    await db.refresh(r)
    return await _enrich_receipt(r, db)


# --------------------------------------------------------------------------- #
# Qarz to'lash / so'ndirish
# --------------------------------------------------------------------------- #
@router.post("/payments", response_model=VendorPaymentOut, status_code=201,
             dependencies=[Depends(require_permission("supply:write"))])
async def pay_vendor(payload: VendorPaymentIn, user: CurrentUser,
                     db: Annotated[AsyncSession, Depends(get_db)]):
    """Qarzni yopish. receipt_id berilsa shu kirim, aks holda eng eski ochiq
    kirimlardan boshlab (FIFO) taqsimlanadi."""
    amount = payload.amount or ZERO
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Summa 0 dan katta bo'lishi kerak")

    if payload.receipt_id:
        one = (await db.execute(
            select(GoodsReceipt).where(
                GoodsReceipt.id == payload.receipt_id,
                GoodsReceipt.vendor_id == payload.vendor_id,
            )
        )).scalar_one_or_none()
        if one is None:
            raise HTTPException(status_code=404, detail="Kirim topilmadi")
        receipts = [one]
    else:
        receipts = (await db.execute(
            select(GoodsReceipt)
            .where(GoodsReceipt.vendor_id == payload.vendor_id, GoodsReceipt.balance > 0)
            .order_by(GoodsReceipt.date, GoodsReceipt.created_at)
        )).scalars().all()

    remaining = amount
    for r in receipts:
        if remaining <= 0:
            break
        pay = min(remaining, r.balance or ZERO)
        if pay <= 0:
            continue
        r.paid = (r.paid or ZERO) + pay
        r.balance = (r.balance or ZERO) - pay
        r.status = "paid" if r.balance <= 0 else "partial"
        remaining -= pay

    p = VendorPayment(
        vendor_id=payload.vendor_id, date=payload.date, amount=amount,
        receipt_id=payload.receipt_id, note=payload.note, created_by_id=user.id,
    )
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return VendorPaymentOut.model_validate(p)


# --------------------------------------------------------------------------- #
# Ombor chiqimi (Stock Issue)
# --------------------------------------------------------------------------- #
@router.post("/stock/issue", response_model=ItemOut,
             dependencies=[Depends(require_permission("supply:write"))])
async def issue_stock(payload: StockIssueIn, user: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    item = (await db.execute(select(Item).where(Item.id == payload.item_id))).scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    scope = await _my_vendor_id(user, db)
    _ensure_item_in_scope(item, scope)

    qty = payload.qty or ZERO
    if qty <= 0:
        raise HTTPException(status_code=400, detail="Miqdor 0 dan katta bo'lishi kerak")
    if qty > (item.stock_qty or ZERO):
        raise HTTPException(status_code=400, detail="Omborda yetarli zaxira yo'q")

    item.stock_qty = (item.stock_qty or ZERO) - qty
    db.add(StockMovement(item_id=item.id, qty_change=-qty, reason="issue",
                         note=payload.note, created_by_id=user.id))

    # Minimumdan past tushgan bo'lsa — ogohlantirish
    if _is_low(item):
        await _notify_low_stock(db, item, user.id)

    await db.commit()
    await db.refresh(item)
    dto = ItemOut.model_validate(item)
    dto.is_low = _is_low(item)
    return dto


# --------------------------------------------------------------------------- #
# Umumiy balans / KPI
# --------------------------------------------------------------------------- #
@router.get("/summary", response_model=SupplySummary)
async def supply_summary(db: Annotated[AsyncSession, Depends(get_db)], user: CurrentUser):
    scope = await _my_vendor_id(user, db)

    debt_q = select(func.coalesce(func.sum(GoodsReceipt.balance), 0))
    recv_q = select(func.coalesce(func.sum(GoodsReceipt.total), 0))
    paid_q = select(func.coalesce(func.sum(GoodsReceipt.paid), 0))
    vendors_q = select(func.count(Vendor.id))
    items_q = select(Item)
    if scope is not None:
        debt_q = debt_q.where(GoodsReceipt.vendor_id == scope)
        recv_q = recv_q.where(GoodsReceipt.vendor_id == scope)
        paid_q = paid_q.where(GoodsReceipt.vendor_id == scope)
        vendors_q = vendors_q.where(Vendor.id == scope)
        items_q = items_q.where(Item.vendor_id == scope)

    debt = (await db.execute(debt_q)).scalar() or ZERO
    received = (await db.execute(recv_q)).scalar() or ZERO
    paid = (await db.execute(paid_q)).scalar() or ZERO
    vendors_count = (await db.execute(vendors_q)).scalar() or 0

    items = (await db.execute(items_q)).scalars().all()
    stock_value = sum(((it.stock_qty or ZERO) * (it.unit_price or ZERO)) for it in items) or ZERO
    low = sum(1 for it in items if _is_low(it))

    return SupplySummary(
        total_debt=Decimal(debt), total_received=Decimal(received), total_paid=Decimal(paid),
        stock_value=Decimal(stock_value), items_count=len(items),
        low_stock_count=low, vendors_count=vendors_count,
    )
