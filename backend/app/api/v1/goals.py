"""Oylik maqsadlar — sotuv soni va tushum (UZS) bo'yicha.

Bosh sahifada hammaga ko'rinadi (reports:read), lekin faqat
`system:goals_manage` ruxsatli foydalanuvchi belgilaydi/o'zgartiradi.

Endpointlar:
  GET /goals/current   — joriy oy maqsadi + real progress (% bilan)
  PUT /goals/current   — joriy oy maqsadini belgilash/yangilash (maxsus ruxsat)
"""
from datetime import date
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import require_permission, require_special
from app.db.session import get_db
from app.models.order import Order, OrderItem
from app.models.system import MonthlyGoal
from app.models.user import User

router = APIRouter()


class GoalIn(BaseModel):
    target_orders: Optional[int] = None
    target_revenue_uzs: Optional[Decimal] = None


def _month_start(today: date) -> date:
    return today.replace(day=1)


def _pct(actual: float, target: Optional[float]) -> Optional[float]:
    if not target:
        return None
    return round(min(actual / float(target) * 100, 999), 1)


async def _current_actuals(db: AsyncSession, month_start: date, today: date) -> tuple[int, float]:
    """Joriy oydagi haqiqiy sotuv soni va tushum (UZS)."""
    cond = and_(Order.order_date >= month_start, Order.order_date <= today)
    orders = int((await db.execute(
        select(func.count(Order.id)).where(cond)
    )).scalar() or 0)
    revenue = float((await db.execute(
        select(func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(Order, Order.id == OrderItem.order_id)
        .where(cond)
    )).scalar() or 0)
    return orders, revenue


def _serialize(goal: Optional[MonthlyGoal], month_start: date,
               actual_orders: int, actual_revenue: float) -> dict:
    target_orders = goal.target_orders if goal else None
    target_revenue = float(goal.target_revenue_uzs) if goal and goal.target_revenue_uzs is not None else None
    return {
        "period_month": month_start,
        "target_orders": target_orders,
        "target_revenue_uzs": target_revenue,
        "actual_orders": actual_orders,
        "actual_revenue_uzs": actual_revenue,
        "orders_pct": _pct(actual_orders, target_orders),
        "revenue_pct": _pct(actual_revenue, target_revenue),
        "updated_at": goal.updated_at if goal else None,
    }


@router.get("/current")
async def current_goal(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_permission("reports:read"))],
):
    """Joriy oy maqsadi va real progress. Hisobot ko'rish huquqi yetarli."""
    today = date.today()
    ms = _month_start(today)
    goal = (await db.execute(
        select(MonthlyGoal).where(MonthlyGoal.period_month == ms)
    )).scalar_one_or_none()
    orders, revenue = await _current_actuals(db, ms, today)
    return _serialize(goal, ms, orders, revenue)


@router.put("/current")
async def set_current_goal(
    payload: GoalIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_special("system:goals_manage"))],
):
    """Joriy oy maqsadini belgilash/yangilash — `system:goals_manage` kerak."""
    today = date.today()
    ms = _month_start(today)
    goal = (await db.execute(
        select(MonthlyGoal).where(MonthlyGoal.period_month == ms)
    )).scalar_one_or_none()
    if goal is None:
        goal = MonthlyGoal(period_month=ms)
        db.add(goal)
    goal.target_orders = payload.target_orders
    goal.target_revenue_uzs = payload.target_revenue_uzs
    goal.set_by_id = user.id
    await db.commit()
    await db.refresh(goal)

    orders, revenue = await _current_actuals(db, ms, today)
    return _serialize(goal, ms, orders, revenue)
