"""Finance: accounts, categories, transactions, exchange rates."""
import uuid
from datetime import date, datetime
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser, require_roles
from app.db.session import get_db
from app.models.finance import Account, ExchangeRate, FinanceCategory, FinanceTransaction
from app.schemas.common import Page
from app.schemas.finance import (
    AccountCreate, AccountOut, BalanceSummary,
    CategoryCreate, CategoryOut,
    ExchangeRateBase, ExchangeRateOut,
    TransactionCreate, TransactionOut,
)
from app.services.finance_service import apply_transaction, current_balances, ensure_today_rate

router = APIRouter()


# ---- Accounts ----
@router.get("/accounts", response_model=list[AccountOut])
async def list_accounts(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(select(Account).order_by(Account.name))
    return [AccountOut.model_validate(a) for a in res.scalars().all()]


@router.post("/accounts", response_model=AccountOut, status_code=201,
             dependencies=[Depends(require_roles("super_admin", "finance_manager"))])
async def create_account(payload: AccountCreate, db: Annotated[AsyncSession, Depends(get_db)]):
    a = Account(**payload.model_dump())
    db.add(a)
    await db.commit()
    await db.refresh(a)
    return a


# ---- Categories ----
@router.get("/categories", response_model=list[CategoryOut])
async def list_categories(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                          kind: Optional[str] = None):
    q = select(FinanceCategory)
    if kind:
        q = q.where(FinanceCategory.kind == kind)
    res = await db.execute(q.order_by(FinanceCategory.name))
    return [CategoryOut.model_validate(c) for c in res.scalars().all()]


@router.post("/categories", response_model=CategoryOut, status_code=201,
             dependencies=[Depends(require_roles("super_admin", "finance_manager"))])
async def create_category(payload: CategoryCreate, db: Annotated[AsyncSession, Depends(get_db)]):
    c = FinanceCategory(**payload.model_dump())
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


# ---- Transactions ----
@router.get("/transactions", response_model=Page[TransactionOut])
async def list_transactions(
    db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    type: Optional[str] = None, account_id: Optional[uuid.UUID] = None,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
):
    q = select(FinanceTransaction)
    conds = []
    if type:
        conds.append(FinanceTransaction.type == type)
    if account_id:
        conds.append(FinanceTransaction.account_id == account_id)
    if date_from:
        conds.append(FinanceTransaction.date >= date_from)
    if date_to:
        conds.append(FinanceTransaction.date <= date_to)
    if conds:
        q = q.where(and_(*conds))

    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar() or 0
    res = await db.execute(q.order_by(FinanceTransaction.date.desc())
                            .offset((page - 1) * page_size).limit(page_size))
    return Page[TransactionOut](
        items=[TransactionOut.model_validate(t) for t in res.scalars().all()],
        total=total, page=page, page_size=page_size,
    )


@router.post("/transactions", response_model=TransactionOut, status_code=201,
             dependencies=[Depends(require_roles("super_admin", "finance_manager"))])
async def create_transaction(payload: TransactionCreate, user: CurrentUser,
                             db: Annotated[AsyncSession, Depends(get_db)]):
    tx = FinanceTransaction(created_by_id=user.id, **payload.model_dump())
    db.add(tx)
    await db.flush()
    await apply_transaction(db, tx)
    await db.commit()
    await db.refresh(tx)
    return tx


# ---- Exchange Rate ----
@router.get("/exchange-rates", response_model=list[ExchangeRateOut])
async def list_rates(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                     limit: int = Query(30, le=200)):
    res = await db.execute(select(ExchangeRate).order_by(ExchangeRate.date.desc()).limit(limit))
    return [ExchangeRateOut.model_validate(r) for r in res.scalars().all()]


@router.get("/exchange-rates/latest", response_model=ExchangeRateOut)
async def latest_rate(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    """Bugungi kurs (kunlik avto-sinx — kerak bo'lsa CBU'dan jonli oladi)."""
    rate = await ensure_today_rate(db)
    if not rate:
        raise HTTPException(status_code=404, detail="Kurs topilmadi")
    return rate


@router.post("/exchange-rates", response_model=ExchangeRateOut, status_code=201,
             dependencies=[Depends(require_roles("super_admin", "finance_manager"))])
async def set_rate(payload: ExchangeRateBase, db: Annotated[AsyncSession, Depends(get_db)]):
    # Upsert
    res = await db.execute(select(ExchangeRate).where(ExchangeRate.date == payload.date))
    existing = res.scalar_one_or_none()
    if existing:
        existing.usd_to_uzs = payload.usd_to_uzs
        existing.source = payload.source
        await db.commit()
        await db.refresh(existing)
        return existing
    r = ExchangeRate(**payload.model_dump())
    db.add(r)
    await db.commit()
    await db.refresh(r)
    return r


# ---- Dashboard ----
@router.get("/balance-summary", response_model=BalanceSummary)
async def balance_summary(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    bal = await current_balances(db)
    return BalanceSummary(
        uzs=bal["uzs"], usd=bal["usd"], gazna=bal["gazna"], last_updated=datetime.utcnow(),
    )
