"""Finance helpers: balance summary, USD/UZS conversion."""
from decimal import Decimal
from datetime import datetime, date as date_cls

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.cbu import fetch_usd_rate
from app.models.finance import Account, ExchangeRate, FinanceTransaction


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


async def apply_transaction(db: AsyncSession, tx: FinanceTransaction) -> None:
    """Apply tx amount to its account balance."""
    if not tx.account_id:
        return
    res = await db.execute(select(Account).where(Account.id == tx.account_id))
    acc = res.scalar_one_or_none()
    if not acc:
        return
    sign = 1 if tx.type == "income" else -1
    acc.balance = (acc.balance or Decimal(0)) + sign * tx.amount
