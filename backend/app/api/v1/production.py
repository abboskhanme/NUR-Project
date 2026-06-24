"""Ishlab chiqarish (PRODUCTION) — kunlik kotyol/bunker/garelka jurnali.

Modellar ombor modellaridan (products.product_type == "warehouse") olinadi —
shu sabab bu modulda alohida model jadvali yo'q. Kotyol modeli frontend'da
/products?product_type=warehouse orqali tanlanadi.
"""
import uuid
from datetime import date
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard, require_permission
from app.db.session import get_db
from app.models.product import Product
from app.models.production import ProductionRecord
from app.schemas.production import (
    CATEGORIES,
    DaySummary,
    ProductionSummary,
    RecordCreate,
    RecordOut,
    RecordUpdate,
)

router = APIRouter(dependencies=[Depends(module_guard("production"))])


# --------------------------------------------------------------------------- #
# Yordamchilar
# --------------------------------------------------------------------------- #
def _to_out(rec: ProductionRecord, model: Optional[str] = None,
            kvm: Optional[int] = None) -> RecordOut:
    out = RecordOut.model_validate(rec)
    out.model = model
    out.kvm = kvm
    return out


async def _model_info(db: AsyncSession, product_id: Optional[uuid.UUID]):
    """Yozuv javobida ko'rsatish uchun model nomi va o'lchamini oladi."""
    if not product_id:
        return None, None
    row = (await db.execute(
        select(Product.model, Product.kvm).where(Product.id == product_id))).first()
    return (row[0], row[1]) if row else (None, None)


async def _validate_kotyol_product(db: AsyncSession, product_id: uuid.UUID) -> Product:
    prod = (await db.execute(
        select(Product).where(Product.id == product_id))).scalar_one_or_none()
    if not prod or prod.product_type != "warehouse":
        raise HTTPException(400, "Noto'g'ri model tanlandi (ombor modeli kerak)")
    return prod


async def _ensure_unique_code(db: AsyncSession, code: str,
                              exclude_id: Optional[uuid.UUID] = None) -> None:
    q = select(ProductionRecord.id).where(ProductionRecord.unit_code == code)
    if exclude_id:
        q = q.where(ProductionRecord.id != exclude_id)
    if (await db.execute(q)).scalar_one_or_none():
        raise HTTPException(400, f"«{code}» ID raqami allaqachon mavjud")


# --------------------------------------------------------------------------- #
# Kunlik hisobot — sana bo'yicha kategoriya sanoqlari
# --------------------------------------------------------------------------- #
@router.get("/summary", response_model=ProductionSummary)
async def production_summary(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
):
    q = (
        select(ProductionRecord.production_date, ProductionRecord.category,
               func.coalesce(func.sum(ProductionRecord.quantity), 0))
        .group_by(ProductionRecord.production_date, ProductionRecord.category)
    )
    if date_from:
        q = q.where(ProductionRecord.production_date >= date_from)
    if date_to:
        q = q.where(ProductionRecord.production_date <= date_to)

    rows = (await db.execute(q)).all()
    by_day: dict[date, DaySummary] = {}
    for d, cat, cnt in rows:
        day = by_day.get(d)
        if not day:
            day = DaySummary(production_date=d)
            by_day[d] = day
        if cat in CATEGORIES:
            setattr(day, cat, getattr(day, cat) + int(cnt or 0))

    days = sorted(by_day.values(), key=lambda x: x.production_date, reverse=True)
    return ProductionSummary(
        days=days,
        total_kotyol=sum(d.kotyol for d in days),
        total_bunker=sum(d.bunker for d in days),
        total_garelka=sum(d.garelka for d in days),
    )


# --------------------------------------------------------------------------- #
# Yozuvlar ro'yxati — kategoriya / sana / qidiruv bo'yicha
# --------------------------------------------------------------------------- #
@router.get("/records", response_model=list[RecordOut])
async def list_records(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    category: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    search: Optional[str] = None,
    limit: int = Query(500, ge=1, le=2000),
):
    q = (
        select(ProductionRecord, Product.model, Product.kvm)
        .outerjoin(Product, Product.id == ProductionRecord.product_id)
    )
    if category:
        q = q.where(ProductionRecord.category == category)
    if date_from:
        q = q.where(ProductionRecord.production_date >= date_from)
    if date_to:
        q = q.where(ProductionRecord.production_date <= date_to)
    if search:
        q = q.where(ProductionRecord.unit_code.ilike(f"%{search.strip()}%"))
    q = q.order_by(ProductionRecord.production_date.desc(),
                   ProductionRecord.created_at.desc()).limit(limit)

    rows = (await db.execute(q)).all()
    return [_to_out(rec, model, kvm) for rec, model, kvm in rows]


# --------------------------------------------------------------------------- #
# Yozuv qo'shish
# --------------------------------------------------------------------------- #
@router.post("/records", response_model=RecordOut, status_code=201,
             dependencies=[Depends(require_permission("production:write"))])
async def create_record(payload: RecordCreate, user: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    if payload.category not in CATEGORIES:
        raise HTTPException(422, "Noto'g'ri kategoriya")

    prod_date = payload.production_date or date.today()
    rec = ProductionRecord(
        category=payload.category,
        production_date=prod_date,
        notes=(payload.notes or None),
        created_by_id=user.id,
    )

    if payload.category == "kotyol":
        if not payload.product_id:
            raise HTTPException(422, "Kotyol uchun model tanlang")
        await _validate_kotyol_product(db, payload.product_id)
        code = (payload.unit_code or "").strip()
        if not code:
            raise HTTPException(422, "Kotyol uchun ID raqami kerak")
        await _ensure_unique_code(db, code)
        rec.product_id = payload.product_id
        rec.unit_code = code
        rec.bunker_direction = payload.bunker_direction or None
        rec.quantity = 1
    else:
        # bunker / garelka — faqat soni
        rec.quantity = payload.quantity or 1

    db.add(rec)
    await db.commit()
    await db.refresh(rec)
    model, kvm = await _model_info(db, rec.product_id)
    return _to_out(rec, model, kvm)


# --------------------------------------------------------------------------- #
# Yozuvni tahrirlash
# --------------------------------------------------------------------------- #
@router.patch("/records/{record_id}", response_model=RecordOut,
              dependencies=[Depends(require_permission("production:write"))])
async def update_record(record_id: uuid.UUID, payload: RecordUpdate, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    rec = (await db.execute(
        select(ProductionRecord).where(ProductionRecord.id == record_id))).scalar_one_or_none()
    if not rec:
        raise HTTPException(404, "Yozuv topilmadi")

    data = payload.model_dump(exclude_unset=True)
    if "production_date" in data and data["production_date"]:
        rec.production_date = data["production_date"]
    if "notes" in data:
        rec.notes = data["notes"] or None

    if rec.category == "kotyol":
        if "product_id" in data and data["product_id"] and data["product_id"] != rec.product_id:
            await _validate_kotyol_product(db, data["product_id"])
            rec.product_id = data["product_id"]
        if "unit_code" in data:
            code = (data["unit_code"] or "").strip()
            if not code:
                raise HTTPException(422, "ID raqami bo'sh bo'lishi mumkin emas")
            if code != rec.unit_code:
                await _ensure_unique_code(db, code, exclude_id=record_id)
                rec.unit_code = code
        if "bunker_direction" in data:
            rec.bunker_direction = data["bunker_direction"] or None
    else:
        if "quantity" in data and data["quantity"]:
            rec.quantity = data["quantity"]

    await db.commit()
    await db.refresh(rec)
    model, kvm = await _model_info(db, rec.product_id)
    return _to_out(rec, model, kvm)


# --------------------------------------------------------------------------- #
# Yozuvni o'chirish
# --------------------------------------------------------------------------- #
@router.delete("/records/{record_id}", status_code=204,
               dependencies=[Depends(require_permission("production:delete"))])
async def delete_record(record_id: uuid.UUID, _: CurrentUser,
                        db: Annotated[AsyncSession, Depends(get_db)]):
    rec = (await db.execute(
        select(ProductionRecord).where(ProductionRecord.id == record_id))).scalar_one_or_none()
    if not rec:
        raise HTTPException(404, "Yozuv topilmadi")
    await db.delete(rec)
    await db.commit()
