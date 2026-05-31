"""Finance helpers: balance summary, USD/UZS conversion."""
from decimal import Decimal
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

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
