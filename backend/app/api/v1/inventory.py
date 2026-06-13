"""Ombor — kotyol skladi (SKLAD KATYOL).

Ishlab chiqarilgan kotyollar ID raqamlari (unique_id) bilan saqlanadi.
Model + o'lcham (kvm) bo'yicha nechta bo'sh / band / sotilgan ekanini ko'rsatadi.
Sotuvda mos birlik avtomatik band qilinadi (orders.py da).
"""
import uuid
from datetime import date
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard, require_permission
from app.db.session import get_db
from app.models.customer import Customer
from app.models.order import Order
from app.models.product import Inventory, Product
from app.schemas.common import ORMBase

router = APIRouter(dependencies=[Depends(module_guard("inventory"))])


# --------------------------------------------------------------------------- #
# Schemas
# --------------------------------------------------------------------------- #
class ModelSummary(BaseModel):
    product_id: uuid.UUID
    model: Optional[str] = None
    kvm: Optional[int] = None
    available: int = 0
    reserved: int = 0
    sold: int = 0
    total: int = 0


class WarehouseSummary(BaseModel):
    rows: list[ModelSummary]
    total_available: int
    total_reserved: int
    total_sold: int


class UnitOut(ORMBase):
    id: uuid.UUID
    unique_id: str
    status: str
    added_date: date
    notes: Optional[str] = None
    product_id: uuid.UUID
    model: Optional[str] = None
    kvm: Optional[int] = None
    order_code: Optional[str] = None
    customer_name: Optional[str] = None


class UnitsCreate(BaseModel):
    product_id: uuid.UUID
    unique_ids: list[str] = Field(..., min_length=1)
    added_date: Optional[date] = None
    notes: Optional[str] = None


class UnitUpdate(BaseModel):
    unique_id: Optional[str] = None
    notes: Optional[str] = None
    product_id: Optional[uuid.UUID] = None
    added_date: Optional[date] = None


def _unit_out_query():
    return (
        select(Inventory, Product.model, Product.kvm, Order.code, Customer.full_name)
        .join(Product, Product.id == Inventory.product_id)
        .outerjoin(Order, Order.inventory_id == Inventory.id)
        .outerjoin(Customer, Customer.id == Order.customer_id)
    )


def _to_unit_out(row) -> "UnitOut":
    inv, model_, kvm, code, cust = row
    u = UnitOut.model_validate(inv)
    u.model, u.kvm, u.order_code, u.customer_name = model_, kvm, code, cust
    return u


# --------------------------------------------------------------------------- #
# Summary — model + kvm bo'yicha sanoq
# --------------------------------------------------------------------------- #
@router.get("/summary", response_model=WarehouseSummary)
async def warehouse_summary(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    rows = (await db.execute(
        select(Product.id, Product.model, Product.kvm, Inventory.status,
               func.count(Inventory.id))
        .join(Inventory, Inventory.product_id == Product.id)
        .where(Product.product_type == "main")
        .group_by(Product.id, Product.model, Product.kvm, Inventory.status)
    )).all()

    by_product: dict[uuid.UUID, ModelSummary] = {}
    for pid, model, kvm, status, cnt in rows:
        m = by_product.get(pid)
        if not m:
            m = ModelSummary(product_id=pid, model=model, kvm=kvm)
            by_product[pid] = m
        c = int(cnt or 0)
        if status == "available":
            m.available += c
        elif status == "reserved":
            m.reserved += c
        elif status == "sold":
            m.sold += c
        m.total += c

    out = sorted(by_product.values(),
                 key=lambda r: (r.model or "", r.kvm or 0))
    return WarehouseSummary(
        rows=out,
        total_available=sum(r.available for r in out),
        total_reserved=sum(r.reserved for r in out),
        total_sold=sum(r.sold for r in out),
    )


# --------------------------------------------------------------------------- #
# Units — to'liq ro'yxat (filtr + buyurtma bog'lanishi)
# --------------------------------------------------------------------------- #
@router.get("/units", response_model=list[UnitOut])
async def list_units(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    status: Optional[str] = None,
    product_id: Optional[uuid.UUID] = None,
    model: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(500, ge=1, le=2000),
):
    q = (
        select(Inventory, Product.model, Product.kvm, Order.code, Customer.full_name)
        .join(Product, Product.id == Inventory.product_id)
        .outerjoin(Order, Order.inventory_id == Inventory.id)
        .outerjoin(Customer, Customer.id == Order.customer_id)
        .where(Product.product_type == "main")
    )
    if status:
        q = q.where(Inventory.status == status)
    if product_id:
        q = q.where(Inventory.product_id == product_id)
    if model:
        q = q.where(Product.model == model)
    if search:
        q = q.where(Inventory.unique_id.ilike(f"%{search.strip()}%"))
    q = q.order_by(Inventory.status.asc(), Inventory.added_date.desc()).limit(limit)

    rows = (await db.execute(q)).all()
    out: list[UnitOut] = []
    for inv, model_, kvm, code, cust in rows:
        u = UnitOut.model_validate(inv)
        u.model = model_
        u.kvm = kvm
        u.order_code = code
        u.customer_name = cust
        out.append(u)
    return out


# --------------------------------------------------------------------------- #
# Birlik(lar) qo'shish — bitta yoki ko'p ID
# --------------------------------------------------------------------------- #
@router.post("/units", status_code=201,
             dependencies=[Depends(require_permission("inventory:write"))])
async def add_units(payload: UnitsCreate, _: CurrentUser,
                    db: Annotated[AsyncSession, Depends(get_db)]):
    prod = (await db.execute(
        select(Product).where(Product.id == payload.product_id))).scalar_one_or_none()
    if not prod:
        raise HTTPException(404, "Mahsulot topilmadi")
    if prod.product_type != "main":
        raise HTTPException(400, "Ombor faqat kotyol (asosiy) modellari uchun")

    # ID larni tozalash + takrorlarni olib tashlash
    ids = [s.strip() for s in payload.unique_ids if s and s.strip()]
    ids = list(dict.fromkeys(ids))
    if not ids:
        raise HTTPException(422, "Kamida bitta ID raqami kerak")

    existing = set((await db.execute(
        select(Inventory.unique_id).where(Inventory.unique_id.in_(ids)))).scalars().all())
    clashes = [i for i in ids if i in existing]
    if clashes:
        raise HTTPException(400, f"Bu ID raqamlar allaqachon mavjud: {', '.join(clashes[:10])}")

    added = payload.added_date or date.today()
    for uid in ids:
        db.add(Inventory(product_id=prod.id, unique_id=uid, status="available",
                         added_date=added, notes=payload.notes))
    await db.commit()
    return {"created": len(ids), "product_id": str(prod.id)}


# --------------------------------------------------------------------------- #
# Birlikni tahrirlash — ID raqami va/yoki izoh
# --------------------------------------------------------------------------- #
@router.patch("/units/{unit_id}", response_model=UnitOut,
              dependencies=[Depends(require_permission("inventory:write"))])
async def update_unit(unit_id: uuid.UUID, payload: UnitUpdate, _: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    inv = (await db.execute(
        select(Inventory).where(Inventory.id == unit_id))).scalar_one_or_none()
    if not inv:
        raise HTTPException(404, "Birlik topilmadi")

    # Sotilgan kotyolni tahrirlab bo'lmaydi (band qilingan/bo'shini tahrirlash mumkin)
    if inv.status == "sold":
        raise HTTPException(400, "Sotilgan kotyolni tahrirlab bo'lmaydi")

    data = payload.model_dump(exclude_unset=True)
    if "unique_id" in data:
        new_id = (data["unique_id"] or "").strip()
        if not new_id:
            raise HTTPException(422, "ID raqami bo'sh bo'lishi mumkin emas")
        if new_id != inv.unique_id:
            clash = (await db.execute(
                select(Inventory.id).where(Inventory.unique_id == new_id,
                                           Inventory.id != unit_id))).scalar_one_or_none()
            if clash:
                raise HTTPException(400, f"«{new_id}» ID raqami allaqachon mavjud")
            inv.unique_id = new_id
    if "product_id" in data and data["product_id"] and data["product_id"] != inv.product_id:
        prod = (await db.execute(
            select(Product).where(Product.id == data["product_id"]))).scalar_one_or_none()
        if not prod or prod.product_type != "main":
            raise HTTPException(400, "Noto'g'ri model tanlandi")
        inv.product_id = prod.id
    if "added_date" in data and data["added_date"]:
        inv.added_date = data["added_date"]
    if "notes" in data:
        inv.notes = data["notes"]

    await db.commit()
    row = (await db.execute(_unit_out_query().where(Inventory.id == unit_id))).first()
    return _to_unit_out(row)


# --------------------------------------------------------------------------- #
# Birlikni o'chirish — faqat bo'sh (sotilmagan/band qilinmagan) bo'lsa
# --------------------------------------------------------------------------- #
@router.delete("/units/{unit_id}", status_code=204,
               dependencies=[Depends(require_permission("inventory:delete"))])
async def delete_unit(unit_id: uuid.UUID, _: CurrentUser,
                      db: Annotated[AsyncSession, Depends(get_db)]):
    inv = (await db.execute(
        select(Inventory).where(Inventory.id == unit_id))).scalar_one_or_none()
    if not inv:
        raise HTTPException(404, "Birlik topilmadi")
    if inv.status != "available":
        raise HTTPException(400, "Faqat bo'sh (band qilinmagan/sotilmagan) birlikni o'chirish mumkin")
    await db.delete(inv)
    await db.commit()
