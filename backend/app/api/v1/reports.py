"""Reports & dashboard.

Bosh sahifa (dashboard) va Hisobotlar bo'limi uchun barcha agregat
endpointlar. Hammasi real DB ma'lumotlaridan hisoblanadi (mock yo'q).

Endpointlar:
  GET /reports/dashboard               — bosh sahifa uchun yagona summary
  GET /reports/sales/kpi               — sotuv KPI (oraliq bo'yicha)
  GET /reports/sales/trend             — kunlik/oylik tushum dinamikasi
  GET /reports/sales/income-expense    — haftalik kirim vs chiqim (moliya)
  GET /reports/sales/by-model          — model bo'yicha sotuv
  GET /reports/sales/by-region         — viloyat bo'yicha sotuv
  GET /reports/sales/by-seller         — sotuvchi bo'yicha sotuv
  GET /reports/sales/status-breakdown  — status bo'yicha buyurtmalar
  GET /reports/finance/pnl             — oylik P&L
  GET /reports/service/summary         — servis bo'limi summary
  GET /reports/supply/summary          — ta'minot bo'limi summary
"""
from calendar import monthrange
from datetime import date, timedelta
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.db.session import get_db
from app.models.customer import Customer
from app.models.finance import FinanceCategory, FinanceTransaction
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.service import ServiceTicket
from app.models.supply import GoodsReceipt, Item, Vendor
from app.models.user import User

router = APIRouter()


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def _resolve_range(date_from: Optional[date], date_to: Optional[date],
                   default_days: int = 0, month_start: bool = False) -> tuple[date, date]:
    """Sana oralig'ini normallashtiradi.

    month_start=True bo'lsa va date_from berilmasa — oyning 1-kunidan.
    Aks holda default_days kun orqaga qaytadi.
    """
    today = date.today()
    if not date_to:
        date_to = today
    if not date_from:
        date_from = date_to.replace(day=1) if month_start else date_to - timedelta(days=default_days)
    return date_from, date_to


async def _scalar(db: AsyncSession, stmt) -> Decimal:
    return (await db.execute(stmt)).scalar() or Decimal(0)


def _orders_revenue_subq(date_from: date, date_to: date):
    """Berilgan oraliqdagi buyurtmalar tushumi (OrderItem.total_uzs yig'indisi)."""
    return (
        select(func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(Order, Order.id == OrderItem.order_id)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
    )


# --------------------------------------------------------------------------- #
# DASHBOARD — bosh sahifa
# --------------------------------------------------------------------------- #
@router.get("/dashboard")
async def dashboard(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
):
    """Bosh sahifa uchun yagona, to'liq summary.

    Bitta so'rovda: oylik KPI, eslatmalar (kafolat, servis, ombor, qarz),
    status taqsimoti, so'nggi buyurtmalar va navbat holati.
    """
    today = date.today()
    month_start = today.replace(day=1)
    prev_month_end = month_start - timedelta(days=1)
    prev_month_start = prev_month_end.replace(day=1)

    # --- Oylik buyurtma KPI ---
    cur_cond = and_(Order.order_date >= month_start, Order.order_date <= today)

    orders_total = int(await _scalar(db, select(func.count(Order.id)).where(cur_cond)))
    orders_delivered = int(await _scalar(db, select(func.count(Order.id)).where(
        and_(cur_cond, Order.status == "delivered"))))
    revenue_cur = float(await _scalar(db, _orders_revenue_subq(month_start, today)))
    revenue_prev = float(await _scalar(db, _orders_revenue_subq(prev_month_start, prev_month_end)))
    revenue_growth = (
        round((revenue_cur - revenue_prev) / revenue_prev * 100, 1)
        if revenue_prev else None
    )

    # --- Moliya (joriy oy) ---
    fin_cond = and_(FinanceTransaction.date >= month_start, FinanceTransaction.date <= today)
    income = float(await _scalar(db, select(func.coalesce(func.sum(FinanceTransaction.amount), 0))
                                 .where(and_(fin_cond, FinanceTransaction.type == "income"))))
    expense = float(await _scalar(db, select(func.coalesce(func.sum(FinanceTransaction.amount), 0))
                                  .where(and_(fin_cond, FinanceTransaction.type == "expense"))))

    # --- Eslatmalar (alerts) ---
    # Kafolat 30 kun ichida tugaydigan buyurtmalar (yetkazilgan + 365 kun)
    warn_lo = today
    warn_hi = today + timedelta(days=30)
    warranty_expiring = int(await _scalar(db, select(func.count(Order.id)).where(and_(
        Order.delivered_at.isnot(None),
        (Order.delivered_at + timedelta(days=365)) >= warn_lo,
        (Order.delivered_at + timedelta(days=365)) <= warn_hi,
    ))))

    service_new = int(await _scalar(db, select(func.count(ServiceTicket.id))
                                    .where(ServiceTicket.status == "new")))
    service_scheduled = int(await _scalar(db, select(func.count(ServiceTicket.id))
                                          .where(ServiceTicket.status == "scheduled")))

    low_stock = int(await _scalar(db, select(func.count(Item.id)).where(and_(
        Item.min_qty > 0, Item.stock_qty <= Item.min_qty))))

    vendor_debt = float(await _scalar(db, select(func.coalesce(func.sum(GoodsReceipt.balance), 0))
                                      .where(GoodsReceipt.balance > 0)))

    queue_count = int(await _scalar(db, select(func.count(Order.id))
                                    .where(Order.status.in_(["new", "ready"]))))

    # --- Status taqsimoti (joriy oy) ---
    status_rows = (await db.execute(
        select(Order.status, func.count(Order.id))
        .where(cur_cond).group_by(Order.status)
    )).all()
    status_breakdown = [{"status": s, "count": int(c)} for s, c in status_rows]

    # --- So'nggi 6 buyurtma ---
    recent_rows = (await db.execute(
        select(Order.id, Order.code, Order.order_date, Order.status, Customer.full_name)
        .join(Customer, Customer.id == Order.customer_id)
        .order_by(Order.order_date.desc(), Order.created_at.desc())
        .limit(6)
    )).all()
    recent_orders = [
        {"id": str(i), "code": code, "order_date": d, "status": st, "customer": cust}
        for i, code, d, st, cust in recent_rows
    ]

    # --- 14 kunlik tushum sparkline ---
    spark_from = today - timedelta(days=13)
    spark = await _daily_revenue(db, spark_from, today)

    return {
        "as_of": today,
        "kpi": {
            "orders_total": orders_total,
            "orders_delivered": orders_delivered,
            "revenue_uzs": revenue_cur,
            "revenue_prev_uzs": revenue_prev,
            "revenue_growth_pct": revenue_growth,
            "income_uzs": income,
            "expense_uzs": expense,
            "net_uzs": income - expense,
        },
        "alerts": {
            "warranty_expiring": warranty_expiring,
            "service_new": service_new,
            "service_scheduled": service_scheduled,
            "low_stock": low_stock,
            "vendor_debt_uzs": vendor_debt,
            "queue_count": queue_count,
        },
        "status_breakdown": status_breakdown,
        "recent_orders": recent_orders,
        "revenue_sparkline": spark,
    }


# --------------------------------------------------------------------------- #
# SALES — KPI
# --------------------------------------------------------------------------- #
@router.get("/sales/kpi")
async def sales_kpi(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    date_from, date_to = _resolve_range(date_from, date_to, month_start=True)

    cond = and_(Order.order_date >= date_from, Order.order_date <= date_to)
    cnt = int(await _scalar(db, select(func.count(Order.id)).where(cond)))
    delivered = int(await _scalar(db, select(func.count(Order.id))
                                  .where(and_(cond, Order.status == "delivered"))))
    ready = int(await _scalar(db, select(func.count(Order.id))
                              .where(and_(cond, Order.status == "ready"))))
    new = int(await _scalar(db, select(func.count(Order.id))
                            .where(and_(cond, Order.status == "new"))))
    rejected = int(await _scalar(db, select(func.count(Order.id))
                                 .where(and_(cond, Order.status == "rejected"))))

    total_uzs = float(await _scalar(db, _orders_revenue_subq(date_from, date_to)))
    avg_check = round(total_uzs / cnt, 2) if cnt else 0.0

    return {
        "date_from": date_from, "date_to": date_to,
        "orders_total": cnt,
        "orders_new": new,
        "orders_ready": ready,
        "orders_delivered": delivered,
        "orders_rejected": rejected,
        "total_uzs": total_uzs,
        "avg_check_uzs": avg_check,
    }


# --------------------------------------------------------------------------- #
# SALES — trend (kunlik / oylik tushum)
# --------------------------------------------------------------------------- #
async def _daily_revenue(db: AsyncSession, date_from: date, date_to: date) -> list[dict]:
    rows = (await db.execute(
        select(Order.order_date, func.coalesce(func.sum(OrderItem.total_uzs), 0),
               func.count(func.distinct(Order.id)))
        .join(OrderItem, OrderItem.order_id == Order.id)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
        .group_by(Order.order_date)
    )).all()
    by_day = {d: (float(t or 0), int(c or 0)) for d, t, c in rows}
    out: list[dict] = []
    cur = date_from
    while cur <= date_to:
        total, cnt = by_day.get(cur, (0.0, 0))
        out.append({"date": cur, "total_uzs": total, "orders": cnt})
        cur += timedelta(days=1)
    return out


async def _monthly_revenue(db: AsyncSession, date_from: date, date_to: date) -> list[dict]:
    month_col = func.date_trunc("month", Order.order_date)
    rows = (await db.execute(
        select(month_col.label("m"), func.coalesce(func.sum(OrderItem.total_uzs), 0),
               func.count(func.distinct(Order.id)))
        .join(OrderItem, OrderItem.order_id == Order.id)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
        .group_by("m").order_by("m")
    )).all()
    return [
        {"date": (m.date() if hasattr(m, "date") else m), "total_uzs": float(t or 0), "orders": int(c or 0)}
        for m, t, c in rows
    ]


@router.get("/sales/trend")
async def sales_trend(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
    granularity: str = Query("day", pattern="^(day|month)$"),
):
    """Tushum dinamikasi. granularity=day|month."""
    date_from, date_to = _resolve_range(date_from, date_to, default_days=29)
    if granularity == "month":
        data = await _monthly_revenue(db, date_from, date_to)
    else:
        data = await _daily_revenue(db, date_from, date_to)
    return {"granularity": granularity, "date_from": date_from, "date_to": date_to, "points": data}


# --------------------------------------------------------------------------- #
# SALES — income vs expense (haftalik, moliyadan)
# --------------------------------------------------------------------------- #
@router.get("/sales/income-expense")
async def income_expense(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    year: Optional[int] = None, month: Optional[int] = None,
):
    """Tanlangan oy uchun haftalar kesimida kirim/chiqim (moliya tranzaksiyalari)."""
    today = date.today()
    year = year or today.year
    month = month or today.month
    last_day = monthrange(year, month)[1]
    start = date(year, month, 1)
    end = date(year, month, last_day)

    rows = (await db.execute(
        select(FinanceTransaction.date, FinanceTransaction.type,
               func.coalesce(func.sum(FinanceTransaction.amount), 0))
        .where(and_(FinanceTransaction.date >= start, FinanceTransaction.date <= end,
                    FinanceTransaction.type.in_(["income", "expense"])))
        .group_by(FinanceTransaction.date, FinanceTransaction.type)
    )).all()

    # 1-7, 8-14, 15-21, 22-28, 29-end => 5 ta hafta-segment
    buckets = [
        {"name": "1–7", "income": 0.0, "expense": 0.0},
        {"name": "8–14", "income": 0.0, "expense": 0.0},
        {"name": "15–21", "income": 0.0, "expense": 0.0},
        {"name": "22–28", "income": 0.0, "expense": 0.0},
        {"name": "29+", "income": 0.0, "expense": 0.0},
    ]
    for d, t, amt in rows:
        idx = min((d.day - 1) // 7, 4)
        buckets[idx][t] += float(amt or 0)
    return {"year": year, "month": month, "weeks": buckets}


# --------------------------------------------------------------------------- #
# SALES — by model
# --------------------------------------------------------------------------- #
@router.get("/sales/by-model")
async def sales_by_model(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    date_from, date_to = _resolve_range(date_from, date_to, default_days=90)
    res = await db.execute(
        select(Product.model, func.count(OrderItem.id), func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(OrderItem, OrderItem.product_id == Product.id)
        .join(Order, Order.id == OrderItem.order_id)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
        .group_by(Product.model)
        .order_by(func.sum(OrderItem.total_uzs).desc())
    )
    return [
        {"model": m or "—", "count": int(c or 0), "total_uzs": float(t or 0)}
        for m, c, t in res.all()
    ]


# --------------------------------------------------------------------------- #
# SALES — by region
# --------------------------------------------------------------------------- #
@router.get("/sales/by-region")
async def sales_by_region(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    date_from, date_to = _resolve_range(date_from, date_to, default_days=90)
    res = await db.execute(
        select(Customer.region, func.count(func.distinct(Order.id)),
               func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(Order, Order.customer_id == Customer.id)
        .join(OrderItem, OrderItem.order_id == Order.id)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
        .group_by(Customer.region)
        .order_by(func.sum(OrderItem.total_uzs).desc())
    )
    return [
        {"region": r or "—", "count": int(c or 0), "total_uzs": float(t or 0)}
        for r, c, t in res.all()
    ]


# --------------------------------------------------------------------------- #
# SALES — by seller
# --------------------------------------------------------------------------- #
@router.get("/sales/by-seller")
async def sales_by_seller(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    date_from, date_to = _resolve_range(date_from, date_to, default_days=90)
    res = await db.execute(
        select(User.full_name, func.count(func.distinct(Order.id)),
               func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(Order, Order.salesperson_id == User.id)
        .join(OrderItem, OrderItem.order_id == Order.id)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
        .group_by(User.full_name)
        .order_by(func.sum(OrderItem.total_uzs).desc())
    )
    return [
        {"seller": s or "—", "count": int(c or 0), "total_uzs": float(t or 0)}
        for s, c, t in res.all()
    ]


# --------------------------------------------------------------------------- #
# SALES — status breakdown
# --------------------------------------------------------------------------- #
@router.get("/sales/status-breakdown")
async def status_breakdown(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    date_from, date_to = _resolve_range(date_from, date_to, default_days=90)
    res = await db.execute(
        select(Order.status, func.count(func.distinct(Order.id)),
               func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(OrderItem, OrderItem.order_id == Order.id, isouter=True)
        .where(and_(Order.order_date >= date_from, Order.order_date <= date_to))
        .group_by(Order.status)
    )
    return [
        {"status": s, "count": int(c or 0), "total_uzs": float(t or 0)}
        for s, c, t in res.all()
    ]


# --------------------------------------------------------------------------- #
# FINANCE — P&L
# --------------------------------------------------------------------------- #
@router.get("/finance/pnl")
async def finance_pnl(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    date_from, date_to = _resolve_range(date_from, date_to, month_start=True)
    cond = and_(FinanceTransaction.date >= date_from, FinanceTransaction.date <= date_to)

    income = float(await _scalar(db, select(func.coalesce(func.sum(FinanceTransaction.amount), 0))
                                 .where(and_(cond, FinanceTransaction.type == "income"))))
    expense = float(await _scalar(db, select(func.coalesce(func.sum(FinanceTransaction.amount), 0))
                                  .where(and_(cond, FinanceTransaction.type == "expense"))))

    # Kategoriya kesimida chiqimlar (top 8)
    cat_rows = (await db.execute(
        select(FinanceCategory.name, func.coalesce(func.sum(FinanceTransaction.amount), 0))
        .join(FinanceCategory, FinanceCategory.id == FinanceTransaction.category_id, isouter=True)
        .where(and_(cond, FinanceTransaction.type == "expense"))
        .group_by(FinanceCategory.name)
        .order_by(func.sum(FinanceTransaction.amount).desc())
        .limit(8)
    )).all()
    expense_by_category = [
        {"category": n or "Boshqa", "amount": float(a or 0)} for n, a in cat_rows
    ]

    return {
        "date_from": date_from, "date_to": date_to,
        "income": income, "expense": expense, "net": income - expense,
        "margin_pct": round((income - expense) / income * 100, 1) if income else None,
        "expense_by_category": expense_by_category,
    }


# --------------------------------------------------------------------------- #
# SERVICE — summary
# --------------------------------------------------------------------------- #
@router.get("/service/summary")
async def service_summary(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    date_from, date_to = _resolve_range(date_from, date_to, default_days=90)
    cond = and_(func.date(ServiceTicket.opened_at) >= date_from,
                func.date(ServiceTicket.opened_at) <= date_to)

    by_status_rows = (await db.execute(
        select(ServiceTicket.status, func.count(ServiceTicket.id))
        .where(cond).group_by(ServiceTicket.status)
    )).all()
    by_status = {s: int(c) for s, c in by_status_rows}

    total = sum(by_status.values())
    in_warranty = int(await _scalar(db, select(func.count(ServiceTicket.id))
                                    .where(and_(cond, ServiceTicket.in_warranty.is_(True)))))
    client_revenue = float(await _scalar(db, select(func.coalesce(func.sum(ServiceTicket.client_cost), 0))
                                         .where(cond)))

    by_cat_rows = (await db.execute(
        select(func.coalesce(ServiceTicket.category, "—"), func.count(ServiceTicket.id))
        .where(cond).group_by(ServiceTicket.category)
        .order_by(func.count(ServiceTicket.id).desc()).limit(8)
    )).all()
    by_category = [{"category": c, "count": int(n)} for c, n in by_cat_rows]

    return {
        "date_from": date_from, "date_to": date_to,
        "total": total,
        "new": by_status.get("new", 0),
        "scheduled": by_status.get("scheduled", 0),
        "completed": by_status.get("completed", 0),
        "cancelled": by_status.get("cancelled", 0),
        "in_warranty": in_warranty,
        "out_warranty": total - in_warranty,
        "client_revenue_uzs": client_revenue,
        "by_category": by_category,
    }


# --------------------------------------------------------------------------- #
# SUPPLY — summary
# --------------------------------------------------------------------------- #
@router.get("/supply/summary")
async def supply_summary(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    date_from, date_to = _resolve_range(date_from, date_to, default_days=90)
    cond = and_(GoodsReceipt.date >= date_from, GoodsReceipt.date <= date_to)

    receipts_total = float(await _scalar(db, select(func.coalesce(func.sum(GoodsReceipt.total), 0)).where(cond)))
    receipts_paid = float(await _scalar(db, select(func.coalesce(func.sum(GoodsReceipt.paid), 0)).where(cond)))
    debt_total = float(await _scalar(db, select(func.coalesce(func.sum(GoodsReceipt.balance), 0))
                                     .where(GoodsReceipt.balance > 0)))

    low_stock_rows = (await db.execute(
        select(Item.name, Item.unit, Item.stock_qty, Item.min_qty)
        .where(and_(Item.min_qty > 0, Item.stock_qty <= Item.min_qty))
        .order_by((Item.stock_qty - Item.min_qty).asc())
        .limit(20)
    )).all()
    low_stock = [
        {"name": n, "unit": u, "stock_qty": float(s or 0), "min_qty": float(m or 0)}
        for n, u, s, m in low_stock_rows
    ]

    # Eng katta qarzli ta'minotchilar
    debt_rows = (await db.execute(
        select(Vendor.name, func.coalesce(func.sum(GoodsReceipt.balance), 0))
        .join(GoodsReceipt, GoodsReceipt.vendor_id == Vendor.id)
        .where(GoodsReceipt.balance > 0)
        .group_by(Vendor.name)
        .order_by(func.sum(GoodsReceipt.balance).desc()).limit(10)
    )).all()
    top_debts = [{"vendor": v, "debt_uzs": float(b or 0)} for v, b in debt_rows]

    return {
        "date_from": date_from, "date_to": date_to,
        "receipts_total_uzs": receipts_total,
        "receipts_paid_uzs": receipts_paid,
        "debt_total_uzs": debt_total,
        "low_stock_count": len(low_stock),
        "low_stock": low_stock,
        "top_debts": top_debts,
    }
