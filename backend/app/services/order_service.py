"""Order business logic: code generation, status transitions, totals."""
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.order import Order, OrderItem


# Soddalashtirilgan holatlar: Navbatda → Tayyor bo'ldi → Yetkazildi; istalgan
# faol holatdan Rad etildi.
VALID_TRANSITIONS = {
    # To'liq to'langan buyurtma "Tayyor" bosqichini chetlab to'g'ridan-to'g'ri
    # yetkazilishi ham mumkin (new -> delivered).
    "new": {"ready", "delivered", "rejected"},
    "ready": {"delivered", "rejected"},
    "delivered": set(),
    "rejected": set(),
}


async def generate_order_code(db: AsyncSession) -> str:
    """Format: YYYY-NNNNN (e.g. 2026-00123)."""
    year = datetime.utcnow().year
    prefix = f"{year}-"
    result = await db.execute(
        select(func.count(Order.id)).where(Order.code.like(f"{prefix}%"))
    )
    count = result.scalar() or 0
    return f"{prefix}{count + 1:05d}"


def is_valid_transition(current: str, new: str) -> bool:
    return new in VALID_TRANSITIONS.get(current, set())


def compute_order_total(items: list[OrderItem]) -> Decimal:
    return sum((it.total_uzs for it in items), Decimal(0))
