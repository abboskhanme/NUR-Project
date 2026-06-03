"""Finance helpers: balance summary, USD/UZS conversion."""
from decimal import Decimal
from datetime import datetime, date as date_cls

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.cbu import fetch_usd_rate
from app.models.finance import Account, ExchangeRate, FinanceCategory, FinanceTransaction


async def current_balances(db: AsyncSession) -> dict[str, Decimal]:
    """Sum account balances per ledger/currency.

    Returns dict with keys: uzs, usd, gazna.
    """
    result = await db.execute(select(Account))
    accounts = result.scalars().all()

    out = {"uzs": Decimal(0), "usd": Decimal(0), "gazna": Decimal(0)}
    for acc in accounts:
        if acc.ledger == "gazna":
            out["gazna"] += acc.balance
        elif acc.currency == "USD":
            out["usd"] += acc.balance
        else:
            out["uzs"] += acc.balance
    return out


async def latest_exchange_rate(db: AsyncSession) -> Decimal | None:
    res = await db.execute(
        select(ExchangeRate).order_by(ExchangeRate.date.desc()).limit(1)
    )
    rate = res.scalar_one_or_none()
    return rate.usd_to_uzs if rate else None


async def ensure_today_rate(db: AsyncSession) -> ExchangeRate | None:
    """Bugungi USD->UZS kursini qaytaradi (read-through kunlik avto-sinx).

    Agar bugungi kurs bazada bo'lmasa, CBU'dan jonli olib, source="cbu" bilan
    yozib qo'yadi. CBU ishlamasa, mavjud oxirgi kursga qaytadi.
    """
    today = date_cls.today()
    res = await db.execute(select(ExchangeRate).where(ExchangeRate.date == today))
    existing = res.scalar_one_or_none()
    if existing:
        return existing

    rate_val = await fetch_usd_rate()
    if rate_val is not None:
        rec = ExchangeRate(date=today, usd_to_uzs=rate_val, source="cbu")
        db.add(rec)
        await db.commit()
        await db.refresh(rec)
        return rec

    # CBU mavjud emas — eng oxirgi mavjud kursni qaytaramiz
    res = await db.execute(
        select(ExchangeRate).order_by(ExchangeRate.date.desc()).limit(1)
    )
    return res.scalar_one_or_none()


async def apply_transaction(db: AsyncSession, tx: FinanceTransaction, *, reverse: bool = False) -> None:
    """Tranzaksiya summasini hisobvaraq balansiga qo'llaydi.

    income  → account_id balansiga + amount
    expense → account_id balansiga − amount

    `reverse=True` — teskari amalga (o'chirishda balansni qaytarish).
    """
    if not tx.account_id:
        return
    res = await db.execute(select(Account).where(Account.id == tx.account_id))
    acc = res.scalar_one_or_none()
    if not acc:
        return
    mult = Decimal(-1) if reverse else Decimal(1)
    sign = Decimal(1) if tx.type == "income" else Decimal(-1)
    acc.balance = (acc.balance or Decimal(0)) + mult * sign * tx.amount


async def month_summary(db: AsyncSession, year: int, month: int) -> dict:
    """Berilgan oy uchun kirim/chiqim KPI (UZS va USD alohida) va
    kategoriyalar bo'yicha taqsimot (UZS). Transfer turi KPI'ga kirmaydi.
    """
    if month == 12:
        nxt = date_cls(year + 1, 1, 1)
    else:
        nxt = date_cls(year, month + 1, 1)
    start = date_cls(year, month, 1)

    # Kirim/chiqim jami — valyuta bo'yicha alohida (UZS va USD)
    totals = (await db.execute(
        select(
            FinanceTransaction.type,
            FinanceTransaction.currency,
            func.coalesce(func.sum(FinanceTransaction.amount), 0),
        )
        .where(and_(
            FinanceTransaction.date >= start,
            FinanceTransaction.date < nxt,
            FinanceTransaction.type.in_(("income", "expense")),
        ))
        .group_by(FinanceTransaction.type, FinanceTransaction.currency)
    )).all()

    income_total = Decimal(0)
    expense_total = Decimal(0)
    usd_income_total = Decimal(0)
    usd_expense_total = Decimal(0)
    for type_, curr, total in totals:
        total = Decimal(total or 0)
        if curr == "USD":
            if type_ == "income":
                usd_income_total += total
            else:
                usd_expense_total += total
        else:
            if type_ == "income":
                income_total += total
            else:
                expense_total += total

    # Kategoriyalar bo'yicha taqsimot (UZS)
    rows = (await db.execute(
        select(
            FinanceTransaction.type,
            FinanceCategory.name,
            func.coalesce(func.sum(FinanceTransaction.amount), 0),
        )
        .join(FinanceCategory, FinanceCategory.id == FinanceTransaction.category_id, isouter=True)
        .where(and_(
            FinanceTransaction.date >= start,
            FinanceTransaction.date < nxt,
            FinanceTransaction.currency == "UZS",
            FinanceTransaction.type.in_(("income", "expense")),
        ))
        .group_by(FinanceTransaction.type, FinanceCategory.name)
    )).all()

    by_category: list[dict] = [
        {"type": type_, "category_name": cat_name or "Boshqa", "total": Decimal(total or 0)}
        for type_, cat_name, total in rows
    ]
    by_category.sort(key=lambda r: r["total"], reverse=True)

    return {
        "year": year,
        "month": month,
        "income_total": income_total,
        "expense_total": expense_total,
        "net": income_total - expense_total,
        "usd_income_total": usd_income_total,
        "usd_expense_total": usd_expense_total,
        "by_category": by_category,
    }
