"""Reports: KPI, monthly P&L, sales by region/model/seller."""
from datetime import date, timedelta
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import and_, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.db.session import get_db
from app.models.customer import Customer
from app.models.finance import FinanceTransaction
from app.models.order import Order, OrderItem
from app.models.product import Product

router = APIRouter()


@router.get("/sales/kpi")
async def sales_kpi(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    today = date.today()
    if not date_from:
        date_from = today.replace(day=1)
    if not date_to:
        date_to = today

    cond = and_(Order.order_date >= date_from, Order.order_date <= date_to)
    cnt = (await db.execute(select(func.count(Order.id)).where(cond))).scalar() or 0
    delivered = (await db.execute(select(func.count(Order.id)).where(
        and_(cond, Order.status == "delivered")))).scalar() or 0
    paid = (await db.execute(select(func.count(Order.id)).where(
        and_(cond, Order.status == "paid")))).scalar() or 0
    cancelled = (await db.execute(select(func.count(Order.id)).where(
        and_(cond, Order.status.in_(["cancelled", "rejected"]))))).scalar() or 0

    total_uzs = (await db.execute(
        select(func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(Order, Order.id == OrderItem.order_id)
        .where(cond)
    )).scalar() or Decimal(0)

    return {
        "date_from": date_from, "date_to": date_to,
        "orders_total": cnt,
        "orders_delivered": delivered,
        "orders_paid": paid,
        "orders_cancelled": cancelled,
        "total_uzs": float(total_uzs),
    }


@router.get("/sales/by-model")
async def sales_by_model(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    today = date.today()
    if not date_from:
        date_from = today - timedelta(days=90)
    if not date_to:
        date_to = today
    res = await db.execute(
        select(Product.model, func.count(OrderItem.id), func.sum(OrderItem.total_uzs))
        .join(OrderItem, OrderItem.product_id == Product.id)
        .join(Order, Order.id == OrderItem.order_id)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
        .group_by(Product.model)
        .order_by(func.sum(OrderItem.total_uzs).desc())
    )
    return [
        {"model": m, "count": c, "total_uzs": float(t or 0)}
        for m, c, t in res.all()
    ]


@router.get("/finance/pnl")
async def finance_pnl(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    today = date.today()
    if not date_from:
        date_from = today.replace(day=1)
    if not date_to:
        date_to = today
    cond = and_(FinanceTransaction.date >= date_from, FinanceTransaction.date <= date_to)

    income = (await db.execute(
        select(func.coalesce(func.sum(FinanceTransaction.amount), 0))
        .where(and_(cond, FinanceTransaction.type == "income"))
    )).scalar() or Decimal(0)
    expense = (await db.execute(
        select(func.coalesce(func.sum(FinanceTransaction.amount), 0))
        .where(and_(cond, FinanceTransaction.type == "expense"))
    )).scalar() or Decimal(0)

    return {
        "date_from": date_from, "date_to": date_to,
        "income": float(income),
        "expense": float(expense),
        "net": float(income - expense),
    }


@router.get("/sales/by-region")
async def sales_by_region(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    today = date.today()
    if not date_from:
        date_from = today - timedelta(days=90)
    if not date_to:
        date_to = today
    res = await db.execute(
        select(Customer.region, func.count(Order.id), func.sum(OrderItem.total_uzs))
        .join(Order, Order.customer_id == Customer.id)
        .join(OrderItem, OrderItem.order_id == Order.id)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
        .group_by(Customer.region)
        .order_by(func.sum(OrderItem.total_uzs).desc())
    )
    return [
        {"region": r or "—", "count": c, "total_uzs": float(t or 0)}
        for r, c, t in res.all()
    ]
