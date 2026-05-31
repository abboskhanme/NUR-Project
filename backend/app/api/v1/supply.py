"""Supply: sectors, vendors, items, goods receipts, vendor payments."""
import uuid
from datetime import date
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser, require_roles
from app.db.session import get_db
from app.models.supply import (
    GoodsReceipt, Item, StockMovement, SupplySector, Vendor, VendorPayment,
)
from app.schemas.common import Page
from app.schemas.supply import (
    GoodsReceiptIn, GoodsReceiptOut,
    ItemCreate, ItemOut,
    SectorOut,
    VendorCreate, VendorOut,
    VendorPaymentIn, VendorPaymentOut,
)

router = APIRouter()


# ---- Sectors ----
@router.get("/sectors", response_model=list[SectorOut])
async def list_sectors(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(select(SupplySector).order_by(SupplySector.name))
    return [SectorOut.model_validate(s) for s in res.scalars().all()]


# ---- Vendors ----
@router.get("/vendors", response_model=list[VendorOut])
async def list_vendors(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                       sector_id: Optional[uuid.UUID] = None):
    q = select(Vendor)
    if sector_id:
        q = q.where(Vendor.sector_id == sector_id)
    res = await db.execute(q.order_by(Vendor.name))
    return [VendorOut.model_validate(v) for v in res.scalars().all()]


@router.post("/vendors", response_model=VendorOut, status_code=201)
async def create_vendor(payload: VendorCreate, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    v = Vendor(**payload.model_dump())
    db.add(v)
    await db.commit()
    await db.refresh(v)
    return v


# ---- Items ----
@router.get("/items", response_model=Page[ItemOut])
async def list_items(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                     sector_id: Optional[uuid.UUID] = None,
                     low_stock_only: bool = False,
                     page: int = Query(1, ge=1), page_size: int = Query(50, ge=1, le=200)):
    q = select(Item)
    if sector_id:
        q = q.where(Item.sector_id == sector_id)
    if low_stock_only:
        q = q.where(Item.stock_qty < Item.min_qty)
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar() or 0
    res = await db.execute(q.order_by(Item.name)
                            .offset((page - 1) * page_size).limit(page_size))
    return Page[ItemOut](
        items=[ItemOut.model_validate(i) for i in res.scalars().all()],
        total=total, page=page, page_size=page_size,
    )


@router.post("/items", response_model=ItemOut, status_code=201)
async def create_item(payload: ItemCreate, _: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    i = Item(**payload.model_dump())
    db.add(i)
    await db.commit()
    await db.refresh(i)
    return i


# ---- Goods Receipts ----
@router.get("/receipts", response_model=list[GoodsReceiptOut])
async def list_receipts(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                        vendor_id: Optional[uuid.UUID] = None,
                        item_id: Optional[uuid.UUID] = None,
                        status: Optional[str] = None):
    q = select(GoodsReceipt)
    if vendor_id:
        q = q.where(GoodsReceipt.vendor_id == vendor_id)
    if item_id:
        q = q.where(GoodsReceipt.item_id == item_id)
    if status:
        q = q.where(GoodsReceipt.status == status)
    res = await db.execute(q.order_by(GoodsReceipt.date.desc()).limit(500))
    return [GoodsReceiptOut.model_validate(r) for r in res.scalars().all()]


@router.post("/receipts", response_model=GoodsReceiptOut, status_code=201)
async def create_receipt(payload: GoodsReceiptIn, user: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    total = (payload.qty or Decimal(0)) * (payload.unit_price or Decimal(0))
    paid = payload.paid or Decimal(0)
    balance = total - paid
    status = "paid" if balance <= 0 else ("partial" if paid > 0 else "open")

    r = GoodsReceipt(
        date=payload.date, vendor_id=payload.vendor_id, item_id=payload.item_id,
        qty=payload.qty, unit_price=payload.unit_price, currency=payload.currency,
        total=total, paid=paid, balance=balance, status=status,
        created_by_id=user.id,
    )
    db.add(r)

    # Stock movement
    db.add(StockMovement(item_id=payload.item_id, qty_change=payload.qty,
                         reason="receipt", note=payload.note))
    # Update stock qty
    item_res = await db.execute(select(Item).where(Item.id == payload.item_id))
    item = item_res.scalar_one_or_none()
    if item:
        item.stock_qty = (item.stock_qty or Decimal(0)) + payload.qty

    await db.commit()
    await db.refresh(r)
    return r


# ---- Vendor Payments ----
@router.post("/vendor-payments", response_model=VendorPaymentOut, status_code=201)
async def pay_vendor(payload: VendorPaymentIn, user: CurrentUser,
                     db: Annotated[AsyncSession, Depends(get_db)]):
    p = VendorPayment(created_by_id=user.id, **payload.model_dump())
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return p


@router.get("/vendors/{vendor_id}/balance")
async def vendor_balance(vendor_id: uuid.UUID, _: CurrentUser,
                         db: Annotated[AsyncSession, Depends(get_db)]):
    """Joriy qarz = sum(receipt.balance) - sum(extra payments)."""
    rec_res = await db.execute(
        select(func.coalesce(func.sum(GoodsReceipt.balance), 0))
        .where(GoodsReceipt.vendor_id == vendor_id)
    )
    balance = rec_res.scalar() or Decimal(0)
    return {"vendor_id": str(vendor_id), "open_debt": float(balance)}
