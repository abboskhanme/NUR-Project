"""Moliya tranzaksiyasini yumshoq o'chirish (void) — integration (Postgres kerak).

Void qilingan tranzaksiya:
  - balansga ta'siri teskari qaytariladi (balans tiklanadi),
  - oylik KPI yig'indisidan (month_summary) chiqarib tashlanadi,
  - lekin yozuv DB'da qoladi (status="void").
"""
from datetime import date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db


async def test_void_reverses_balance_and_excludes_from_summary(db_engine):
    from app.models.finance import Account, FinanceTransaction
    from app.services.finance_service import apply_transaction, month_summary

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    today = date.today()
    async with Session() as db:
        acc = Account(name="Kassa", currency="UZS", balance=Decimal(0))
        db.add(acc)
        await db.flush()

        tx = FinanceTransaction(
            date=today, type="expense", amount=Decimal(100), currency="UZS",
            account_id=acc.id, status="active",
        )
        db.add(tx)
        await db.flush()
        await apply_transaction(db, tx)
        await db.commit()

        # Chiqim balansni kamaytiradi va KPI'ga kiradi
        await db.refresh(acc)
        assert acc.balance == Decimal(-100)
        summ = await month_summary(db, today.year, today.month)
        assert summ["expense_total"] == Decimal(100)

        # --- void qilamiz ---
        tx.status = "void"
        await apply_transaction(db, tx, reverse=True)
        await db.commit()

        # Balans tiklandi, KPI'dan chiqdi, lekin yozuv DB'da qoldi
        await db.refresh(acc)
        assert acc.balance == Decimal(0)
        summ2 = await month_summary(db, today.year, today.month)
        assert summ2["expense_total"] == Decimal(0)

        row_count = (await db.execute(
            select(func.count(FinanceTransaction.id))
            .where(FinanceTransaction.status == "void")
        )).scalar()
        assert row_count == 1
