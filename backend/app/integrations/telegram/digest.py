"""Kunlik hisobot (xo'jayin uchun) — mavjud modellardan agregatsiya.

Hech qanday mavjud kod o'zgartirilmaydi: bu yerda faqat o'qish (SELECT)
so'rovlari bor, ular reports.py'dagi mavjud ifodalarni takrorlaydi.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import AsyncSessionLocal
from app.models.order import Order, OrderItem, Payment
from app.models.finance import FinanceTransaction
from app.services.finance_service import current_balances

from .common import fmt_uzs, fmt_usd, today


# To'langan summa ifodasi — butun loyiha bo'ylab ishlatiladigan kanonik forma
# (reports.py va orders.py'dagi bilan bir xil): amount_uzs_equiv bo'lsa o'sha,
# aks holda amount.
_PAID_EXPR = func.coalesce(
    func.sum(func.coalesce(func.nullif(Payment.amount_uzs_equiv, 0), Payment.amount)),
    0,
)


@dataclass
class DailyDigest:
    day: date
    new_orders: int = 0
    revenue_uzs: Decimal = Decimal(0)
    payments_uzs: Decimal = Decimal(0)
    delivered: int = 0
    telegram_orders: int = 0
    income_uzs: Decimal = Decimal(0)
    expense_uzs: Decimal = Decimal(0)
    cash_uzs: Decimal = Decimal(0)
    cash_usd: Decimal = Decimal(0)
    cash_gazna: Decimal = Decimal(0)
    outstanding_uzs: Decimal = Decimal(0)
    queue_count: int = 0
    status_breakdown: list[tuple[str, int]] = field(default_factory=list)

    @property
    def net_uzs(self) -> Decimal:
        return self.income_uzs - self.expense_uzs


async def _scalar(db: AsyncSession, stmt) -> Decimal:
    return (await db.execute(stmt)).scalar() or Decimal(0)


async def build_digest(day: date | None = None) -> DailyDigest:
    """Berilgan kun uchun kunlik hisobotni yig'adi (default — bugun)."""
    day = day or today()
    async with AsyncSessionLocal() as db:
        d = DailyDigest(day=day)

        # --- Buyurtmalar (shu kun) ---
        d.new_orders = int(await _scalar(
            db, select(func.count(Order.id)).where(Order.order_date == day)))
        d.telegram_orders = int(await _scalar(
            db, select(func.count(Order.id)).where(
                and_(Order.order_date == day, Order.source == "telegram_bot"))))
        d.delivered = int(await _scalar(
            db, select(func.count(Order.id)).where(Order.delivered_at == day)))

        # --- Savdo tushumi (shu kun, OrderItem.total_uzs) ---
        d.revenue_uzs = await _scalar(
            db,
            select(func.coalesce(func.sum(OrderItem.total_uzs), 0))
            .join(Order, Order.id == OrderItem.order_id)
            .where(Order.order_date == day),
        )

        # --- Qabul qilingan to'lovlar (zaklad, shu kun) ---
        d.payments_uzs = await _scalar(
            db, select(_PAID_EXPR).where(Payment.date == day))

        # --- Moliya kirim/chiqim (shu kun, faqat active) ---
        fin_cond = and_(FinanceTransaction.date == day,
                        FinanceTransaction.status == "active")
        d.income_uzs = await _scalar(
            db, select(func.coalesce(func.sum(FinanceTransaction.amount), 0))
            .where(and_(fin_cond, FinanceTransaction.type == "income")))
        d.expense_uzs = await _scalar(
            db, select(func.coalesce(func.sum(FinanceTransaction.amount), 0))
            .where(and_(fin_cond, FinanceTransaction.type == "expense")))

        # --- Kassa qoldig'i (joriy) ---
        bal = await current_balances(db)
        d.cash_uzs = bal.get("uzs", Decimal(0))
        d.cash_usd = bal.get("usd", Decimal(0))
        d.cash_gazna = bal.get("gazna", Decimal(0))

        # --- Navbatdagi buyurtmalar (new + ready) ---
        d.queue_count = int(await _scalar(
            db, select(func.count(Order.id)).where(Order.status.in_(["new", "ready"]))))

        # --- Umumiy qarzdorlik (jami savdo - jami to'lov) ---
        total_rev = await _scalar(
            db, select(func.coalesce(func.sum(OrderItem.total_uzs), 0)))
        total_paid = await _scalar(db, select(_PAID_EXPR))
        d.outstanding_uzs = max(Decimal(0), total_rev - total_paid)

        # --- Status taqsimoti (shu kun) ---
        rows = (await db.execute(
            select(Order.status, func.count(Order.id))
            .where(Order.order_date == day)
            .group_by(Order.status)
        )).all()
        d.status_breakdown = [(s, int(c)) for s, c in rows]

        return d


_STATUS_UZ = {
    "new": "Yangi",
    "ready": "Tayyor",
    "delivered": "Yetkazilgan",
    "rejected": "Rad etilgan",
}


def format_digest(d: DailyDigest) -> str:
    """Hisobotni Telegram uchun HTML matnga aylantiradi."""
    day_str = d.day.strftime("%d.%m.%Y")
    lines: list[str] = []
    lines.append(f"📊 <b>Kunlik hisobot — {day_str}</b>")
    lines.append("")
    lines.append("🛒 <b>Savdo</b>")
    lines.append(f"  • Yangi buyurtmalar: <b>{d.new_orders}</b>"
                 + (f" (shundan Telegram: {d.telegram_orders})" if d.telegram_orders else ""))
    lines.append(f"  • Yetkazilgan: <b>{d.delivered}</b>")
    lines.append(f"  • Savdo summasi: <b>{fmt_uzs(d.revenue_uzs)}</b>")
    lines.append(f"  • Qabul qilingan to'lov: <b>{fmt_uzs(d.payments_uzs)}</b>")

    if d.status_breakdown:
        parts = [f"{_STATUS_UZ.get(s, s)}: {c}" for s, c in d.status_breakdown]
        lines.append("  • Holatlar: " + ", ".join(parts))

    lines.append("")
    lines.append("💰 <b>Moliya (bugun)</b>")
    lines.append(f"  • Kirim: <b>{fmt_uzs(d.income_uzs)}</b>")
    lines.append(f"  • Chiqim: <b>{fmt_uzs(d.expense_uzs)}</b>")
    lines.append(f"  • Sof: <b>{fmt_uzs(d.net_uzs)}</b>")

    lines.append("")
    lines.append("🏦 <b>Kassa qoldig'i</b>")
    lines.append(f"  • UZS: <b>{fmt_uzs(d.cash_uzs)}</b>")
    lines.append(f"  • USD: <b>{fmt_usd(d.cash_usd)}</b>")
    lines.append(f"  • Gazna: <b>{fmt_usd(d.cash_gazna)}</b>")

    lines.append("")
    lines.append("📌 <b>Umumiy</b>")
    lines.append(f"  • Navbatda: <b>{d.queue_count}</b> ta buyurtma")
    lines.append(f"  • Umumiy qarzdorlik: <b>{fmt_uzs(d.outstanding_uzs)}</b>")

    return "\n".join(lines)
