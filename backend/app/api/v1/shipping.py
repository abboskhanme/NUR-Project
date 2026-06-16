"""Yuk chiqarish — yetkazib berilgan yuklar jurnali API (mustaqil modul).

Savdoga bog'liq emas: barcha qatorlar shu yerda qo'lda yaratiladi va Excel kabi
joyida tahrirlanadi (bo'sh qator qo'shiladi, har bir katak PATCH bilan yangilanadi).
Statistika: qayerga/kimga qancha yuk ketgani bo'yicha yig'ma hisobotlar.
"""
import calendar
import uuid
from datetime import date
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.product import Product
from app.models.shipping import Shipment
from app.schemas.shipping import (
    DriverOut, ShipmentCreate, ShipmentOut, ShipmentStatRow, ShipmentStats,
    ShipmentUpdate, ShipProductOut,
)

router = APIRouter(dependencies=[Depends(module_guard("shipping"))])


@router.get("", response_model=list[ShipmentOut])
async def list_shipments(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: CurrentUser,
    year: Optional[int] = Query(None, ge=2000, le=2100),
    month: Optional[int] = Query(None, ge=1, le=12),
):
    """Yuklar ro'yxati. year+month berilsa o'sha oy, aks holda yil/barchasi.

    Sana bo'yicha teskari (yangi → eski) tartibda; bir xil sanada eng oxirgi
    qo'shilgani yuqorida — shu sabab yangi qator har doim tepaga tushadi.
    """
    q = select(Shipment)
    if year and month:
        start = date(year, month, 1)
        end = date(year, month, calendar.monthrange(year, month)[1])
        q = q.where(and_(Shipment.date >= start, Shipment.date <= end))
    elif year:
        q = q.where(and_(Shipment.date >= date(year, 1, 1), Shipment.date <= date(year, 12, 31)))
    q = q.order_by(Shipment.date.desc().nulls_last(), Shipment.created_at.desc())
    return (await db.execute(q)).scalars().all()


# Statistika guruhlash ustunlari. driver — ism bo'lsa ism, bo'lmasa telefon.
_GROUP_EXPR = {
    "region": Shipment.region,
    "country": Shipment.country,
    "direction": Shipment.direction,
    "driver": func.coalesce(func.nullif(Shipment.driver_name, ""), Shipment.driver_phone),
    "month": func.extract("month", Shipment.date),
    "year": func.extract("year", Shipment.date),
}


def _fmt_key(group_by: str, raw) -> str:
    if raw is None or raw == "":
        return "—"
    if group_by in ("month", "year"):
        return str(int(raw))
    return str(raw)


@router.get("/stats", response_model=ShipmentStats)
async def shipment_stats(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: CurrentUser,
    group_by: str = Query("region"),
    year: Optional[int] = Query(None, ge=2000, le=2100),
    month: Optional[int] = Query(None, ge=1, le=12),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
):
    """Yig'ma hisobot: tanlangan guruh (viloyat/davlat/yo'nalish/shofyor/oy/yil)
    bo'yicha qatorlar soni, jami dona, KVM va fraht summasi.

    Davr: date_from/date_to berilsa — oraliq; aks holda year (+ixtiyoriy month).
    """
    if group_by not in _GROUP_EXPR:
        raise HTTPException(422, "Noto'g'ri group_by")

    conds = []
    if date_from or date_to:
        if date_from:
            conds.append(Shipment.date >= date_from)
        if date_to:
            conds.append(Shipment.date <= date_to)
    elif year and month:
        conds.append(Shipment.date >= date(year, month, 1))
        conds.append(Shipment.date <= date(year, month, calendar.monthrange(year, month)[1]))
    elif year:
        conds.append(Shipment.date >= date(year, 1, 1))
        conds.append(Shipment.date <= date(year, 12, 31))
    where = and_(*conds) if conds else True

    gexpr = _GROUP_EXPR[group_by]
    cnt = func.count(Shipment.id)
    qty_sum = func.coalesce(func.sum(Shipment.qty), 0)
    kvm_sum = func.coalesce(func.sum(Shipment.kvm), 0)
    fr_sum = func.coalesce(func.sum(Shipment.freight), 0)

    res = await db.execute(
        select(gexpr.label("k"), cnt, qty_sum, kvm_sum, fr_sum)
        .where(where).group_by(gexpr).order_by(fr_sum.desc(), cnt.desc())
    )
    rows = [
        ShipmentStatRow(key=_fmt_key(group_by, k), count=int(c or 0), qty=int(q or 0),
                        kvm=int(kv or 0), freight=Decimal(fr or 0))
        for k, c, q, kv, fr in res.all()
    ]
    tc, tq, tkv, tfr = (await db.execute(
        select(cnt, qty_sum, kvm_sum, fr_sum).where(where)
    )).one()
    total = ShipmentStatRow(key="—", count=int(tc or 0), qty=int(tq or 0),
                            kvm=int(tkv or 0), freight=Decimal(tfr or 0))
    return ShipmentStats(group_by=group_by, total=total, rows=rows)


@router.get("/drivers", response_model=list[DriverOut])
async def list_drivers(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    """Ilgari kiritilgan shofyorlar (ism + oxirgi telefon) — avtomatik to'ldirish uchun.

    Alohida ro'yxat/boshqaruv yo'q — jurnaldagi noyob ismlardan yig'iladi.
    """
    # Har bir ism uchun eng so'nggi yozuvdagi telefon (DISTINCT ON).
    rows = (await db.execute(
        select(Shipment.driver_name, Shipment.driver_phone)
        .where(and_(Shipment.driver_name.isnot(None), Shipment.driver_name != ""))
        .distinct(Shipment.driver_name)
        .order_by(Shipment.driver_name, Shipment.created_at.desc())
    )).all()
    return [DriverOut(name=n, phone=p) for n, p in rows]


@router.get("/products", response_model=list[ShipProductOut])
async def list_ship_products(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    """Mahsulot tanlovi — "Mahsulotlar" menyusidagi aktiv mahsulotlar (ombor turidan tashqari).

    Nom (display_name) + USD narx qaytadi; UZS narx frontendda joriy kurs bilan hisoblanadi.
    """
    prods = (await db.execute(
        select(Product).where(and_(
            Product.status == "active", Product.product_type != "warehouse",
        )).order_by(Product.product_type, Product.model, Product.name)
    )).scalars().all()
    return [ShipProductOut(name=p.display_name, price_usd=p.base_price_usd or 0) for p in prods]


@router.post("", response_model=ShipmentOut, status_code=201)
async def create_shipment(
    payload: ShipmentCreate, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    s = Shipment(**payload.model_dump(), created_by_id=user.id)
    db.add(s)
    await db.commit()
    await db.refresh(s)
    return s


@router.patch("/{shipment_id}", response_model=ShipmentOut)
async def update_shipment(
    shipment_id: uuid.UUID,
    payload: ShipmentUpdate,
    _: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    s = (await db.execute(select(Shipment).where(Shipment.id == shipment_id))).scalar_one_or_none()
    if not s:
        raise HTTPException(404, "Yozuv topilmadi")
    # Mustaqil modul — barcha ustunlar qo'lda tahrirlanadi (qulf yo'q).
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(s, k, v)
    await db.commit()
    await db.refresh(s)
    return s


@router.delete("/{shipment_id}", status_code=204)
async def delete_shipment(
    shipment_id: uuid.UUID, _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    s = (await db.execute(select(Shipment).where(Shipment.id == shipment_id))).scalar_one_or_none()
    if not s:
        raise HTTPException(404, "Yozuv topilmadi")
    await db.delete(s)
    await db.commit()
