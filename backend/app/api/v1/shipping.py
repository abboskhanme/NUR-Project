"""Yuk chiqarish — yetkazib berilgan yuklar jurnali API.

Excel kabi joyida tahrirlanadi: bo'sh qator qo'shiladi, har bir katak PATCH bilan
yangilanadi. Buyurtma "yetkazildi" bo'lganda qator avtomatik yaratiladi (orders.py).
"""
import calendar
import uuid
from datetime import date
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.shipping import Shipment
from app.schemas.shipping import ShipmentCreate, ShipmentOut, ShipmentUpdate

router = APIRouter(dependencies=[Depends(module_guard("shipping"))])


@router.get("", response_model=list[ShipmentOut])
async def list_shipments(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: CurrentUser,
    year: Optional[int] = Query(None, ge=2000, le=2100),
    month: Optional[int] = Query(None, ge=1, le=12),
):
    """Yuklar ro'yxati. year+month berilsa o'sha oy, aks holda barchasi.

    Eski jurnaldagidek sana bo'yicha o'sish tartibida qaytadi.
    """
    q = select(Shipment)
    if year and month:
        start = date(year, month, 1)
        end = date(year, month, calendar.monthrange(year, month)[1])
        q = q.where(and_(Shipment.date >= start, Shipment.date <= end))
    elif year:
        q = q.where(and_(Shipment.date >= date(year, 1, 1), Shipment.date <= date(year, 12, 31)))
    q = q.order_by(Shipment.date.asc().nulls_last(), Shipment.created_at.asc())
    return (await db.execute(q)).scalars().all()


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
    data = payload.model_dump(exclude_unset=True)
    # Buyurtmadan avtomatik tushgan qatorda mahsulot/buyurtma maydonlari o'zgarmaydi
    if s.order_id:
        for locked in ("date", "qty", "destination", "kvm", "direction"):
            data.pop(locked, None)
    for k, v in data.items():
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
