"""Customer CRUD."""
import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.db.session import get_db
from app.models.customer import Customer
from app.models.order import Order
from app.schemas.common import Page
from app.schemas.customer import CustomerCreate, CustomerOut, CustomerUpdate

router = APIRouter()


@router.get("", response_model=Page[CustomerOut])
async def list_customers(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = None, region: Optional[str] = None,
    country: Optional[str] = None,
):
    q = select(Customer)
    if search:
        like = f"%{search}%"
        q = q.where(or_(Customer.full_name.ilike(like), Customer.phone.ilike(like)))
    if region:
        q = q.where(Customer.region == region)
    if country:
        q = q.where(Customer.country == country)

    total_res = await db.execute(select(func.count()).select_from(q.subquery()))
    total = total_res.scalar() or 0

    res = await db.execute(q.order_by(Customer.created_at.desc())
                            .offset((page - 1) * page_size).limit(page_size))
    items = res.scalars().all()
    return Page[CustomerOut](items=[CustomerOut.model_validate(c) for c in items],
                             total=total, page=page, page_size=page_size)


@router.post("", response_model=CustomerOut, status_code=201)
async def create_customer(payload: CustomerCreate, user: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    c = Customer(**payload.model_dump(), created_by_id=user.id)
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


@router.get("/{customer_id}", response_model=CustomerOut)
async def get_customer(customer_id: uuid.UUID, _: CurrentUser,
                       db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Customer).where(Customer.id == customer_id))
    c = res.scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Mijoz topilmadi")
    return c


@router.patch("/{customer_id}", response_model=CustomerOut)
async def update_customer(customer_id: uuid.UUID, payload: CustomerUpdate, _: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Customer).where(Customer.id == customer_id))
    c = res.scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Mijoz topilmadi")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(c, k, v)
    await db.commit()
    await db.refresh(c)
    return c


@router.delete("/{customer_id}", status_code=204)
async def delete_customer(customer_id: uuid.UUID, _: CurrentUser,
                          db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Customer).where(Customer.id == customer_id))
    c = res.scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Mijoz topilmadi")
    order_count = (await db.execute(
        select(func.count(Order.id)).where(Order.customer_id == customer_id)
    )).scalar() or 0
    if order_count:
        raise HTTPException(
            400, f"Mijozda {order_count} ta buyurtma mavjud — avval ularni o'chiring yoki boshqa mijozga o'tkazing"
        )
    await db.delete(c)
    await db.commit()
