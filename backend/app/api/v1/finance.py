"""Finance: accounts, categories, transactions, exchange rates, employee payments."""
import calendar
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import has_special, module_guard
from app.db.session import get_db
from app.models.finance import Account, ExchangeRate, FinanceCategory, FinanceTransaction
from app.models.hr import Employee, SalaryAdvance
from app.schemas.common import Page
from app.schemas.finance import (
    AccountCreate, AccountOut, BalanceSummary,
    CategoryCreate, CategoryOut,
    EmployeePaymentIn,
    ExchangeRateBase, ExchangeRateOut,
    FinanceSummary,
    TransactionCreate, TransactionOut,
)
from app.services.finance_service import (
    apply_transaction, current_balances, ensure_today_rate, month_summary,
)

router = APIRouter(dependencies=[Depends(module_guard("finance", read_exempt=("/exchange-rates",)))])


# ---- Accounts ----
@router.get("/accounts", response_model=list[AccountOut])
async def list_accounts(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(select(Account).order_by(Account.name))
    return [AccountOut.model_validate(a) for a in res.scalars().all()]


@router.post("/accounts", response_model=AccountOut, status_code=201)
async def create_account(payload: AccountCreate, db: Annotated[AsyncSession, Depends(get_db)]):
    a = Account(**payload.model_dump())
    db.add(a)
    await db.commit()
    await db.refresh(a)
    return a


@router.delete("/accounts/{account_id}", status_code=204)
async def delete_account(account_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(Account).where(Account.id == account_id))
    acc = res.scalar_one_or_none()
    if not acc:
        raise HTTPException(status_code=404, detail="Hisobvaraq topilmadi")
    used = (await db.execute(
        select(func.count()).select_from(FinanceTransaction).where(
            FinanceTransaction.account_id == account_id)
    )).scalar() or 0
    if used:
        raise HTTPException(status_code=400, detail="Tranzaksiyalarda ishlatilgan, o'chirib bo'lmaydi")
    await db.delete(acc)
    await db.commit()


# ---- Categories ----
@router.get("/categories", response_model=list[CategoryOut])
async def list_categories(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                          kind: Optional[str] = None):
    q = select(FinanceCategory)
    if kind:
        q = q.where(FinanceCategory.kind == kind)
    res = await db.execute(q.order_by(FinanceCategory.name))
    return [CategoryOut.model_validate(c) for c in res.scalars().all()]


@router.post("/categories", response_model=CategoryOut, status_code=201)
async def create_category(payload: CategoryCreate, db: Annotated[AsyncSession, Depends(get_db)]):
    c = FinanceCategory(**payload.model_dump())
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


@router.delete("/categories/{category_id}", status_code=204)
async def delete_category(category_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)]):
    res = await db.execute(select(FinanceCategory).where(FinanceCategory.id == category_id))
    cat = res.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    used = (await db.execute(
        select(func.count()).select_from(FinanceTransaction).where(
            FinanceTransaction.category_id == category_id)
    )).scalar() or 0
    if used:
        raise HTTPException(status_code=400, detail="Tranzaksiyalarda ishlatilgan, o'chirib bo'lmaydi")
    await db.delete(cat)
    await db.commit()


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
    res = await db.execute(q.order_by(FinanceTransaction.date.desc(), FinanceTransaction.created_at.desc())
                            .offset((page - 1) * page_size).limit(page_size))
    rows = res.scalars().all()

    # Kategoriya/hisobvaraq nomlarini bir so'rovda yuklab, embed qilamiz
    cat_ids = {t.category_id for t in rows if t.category_id}
    acc_ids = {t.account_id for t in rows if t.account_id}
    cat_names: dict = {}
    acc_names: dict = {}
    if cat_ids:
        cr = await db.execute(select(FinanceCategory.id, FinanceCategory.name)
                              .where(FinanceCategory.id.in_(cat_ids)))
        cat_names = {i: n for i, n in cr.all()}
    if acc_ids:
        ar = await db.execute(select(Account.id, Account.name).where(Account.id.in_(acc_ids)))
        acc_names = {i: n for i, n in ar.all()}

    items = []
    for t in rows:
        out = TransactionOut.model_validate(t)
        out.category_name = cat_names.get(t.category_id)
        out.account_name = acc_names.get(t.account_id)
        items.append(out)

    return Page[TransactionOut](items=items, total=total, page=page, page_size=page_size)


@router.post("/transactions", response_model=TransactionOut, status_code=201)
async def create_transaction(payload: TransactionCreate, user: CurrentUser,
                             db: Annotated[AsyncSession, Depends(get_db)]):
    if payload.type not in ("income", "expense"):
        raise HTTPException(status_code=422, detail="Noto'g'ri tranzaksiya turi")
    if payload.amount is None or payload.amount <= 0:
        raise HTTPException(status_code=422, detail="Summa 0 dan katta bo'lishi kerak")

    tx = FinanceTransaction(created_by_id=user.id, **payload.model_dump())
    db.add(tx)
    await db.flush()
    await apply_transaction(db, tx)
    await db.commit()
    await db.refresh(tx)
    return tx


@router.delete("/transactions/{tx_id}", response_model=TransactionOut)
async def void_transaction(tx_id: uuid.UUID, db: Annotated[AsyncSession, Depends(get_db)]):
    """Noto'g'ri kiritilgan tranzaksiyani bekor qiladi (yumshoq o'chirish).

    Yozuv butunlay o'chirilmaydi — tarixda 'void' statusi bilan qoladi, lekin
    moliyaviy ta'siri teskari qaytariladi (balans tiklanadi) va barcha
    yig'indilardan (KPI, hisobotlar) chiqarib tashlanadi.
    """
    res = await db.execute(select(FinanceTransaction).where(FinanceTransaction.id == tx_id))
    tx = res.scalar_one_or_none()
    if not tx:
        raise HTTPException(status_code=404, detail="Tranzaksiya topilmadi")
    if tx.status == "void":
        return tx
    tx.status = "void"
    await apply_transaction(db, tx, reverse=True)  # balansni qaytarish
    await db.commit()
    await db.refresh(tx)
    return tx


# ---- Summary (oylik KPI) ----
@router.get("/summary", response_model=FinanceSummary)
async def finance_summary(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser,
                          year: int = Query(...), month: int = Query(..., ge=1, le=12)):
    return FinanceSummary(**await month_summary(db, year, month))


# ---- Employee payments (avans / oylik) ----
@router.post("/employee-payments", response_model=TransactionOut, status_code=201)
async def create_employee_payment(payload: EmployeePaymentIn, user: CurrentUser,
                                  db: Annotated[AsyncSession, Depends(get_db)]):
    """Moliyachi xodimga avans yoki oylik to'laydi.

    Bir vaqtda: (1) HR SalaryAdvance yozuvi (xodim tarixiga tushadi va oylik
    qoldig'ini kamaytiradi) + (2) Moliya chiqim tranzaksiyasi (hisobvaraq
    balansidan ayriladi). Oylikda summa backend'da net qoldiqdan hisoblanadi.
    """
    from app.api.v1.hr import _month_aggregate  # lazy import — circular importdan qochish

    if payload.kind not in ("advance", "salary"):
        raise HTTPException(status_code=422, detail="Noto'g'ri to'lov turi")

    emp = (await db.execute(
        select(Employee).where(Employee.id == payload.employee_id)
    )).scalar_one_or_none()
    if not emp:
        raise HTTPException(status_code=404, detail="Xodim topilmadi")

    month_start = date(payload.year, payload.month, 1)
    last_day = calendar.monthrange(payload.year, payload.month)[1]
    month_end = date(payload.year, payload.month, last_day)

    if payload.kind == "salary":
        _, _, _, _, net = await _month_aggregate(db, emp, payload.year, payload.month)
        amount = net
        if amount is None or amount <= 0:
            raise HTTPException(status_code=400, detail="To'lanadigan qoldiq oylik yo'q")
        cat_code = "employee_salary"
        default_note = f"Oylik to'lovi — {emp.full_name} ({payload.month:02d}.{payload.year})"
    else:
        amount = payload.amount or Decimal(0)
        if amount <= 0:
            raise HTTPException(status_code=422, detail="Summa 0 dan katta bo'lishi kerak")
        cat_code = "advance_to_employee"
        default_note = f"Avans — {emp.full_name}"

        # AVANS CHEKLOVI: jami avanslar tahminiy oylikdan oshmasligi kerak.
        # Oshsa — oddiy xodimga BLOK; faqat super-admin yoki `system:finance_override`
        # ruxsatli rol "baribir berish" (override) huquqiga ega
        # (frontend tasdiqdan keyin override=true yuboradi).
        from app.api.v1.hr import advance_cap  # lazy import — circular importdan qochish
        max_gross, current_adv = await advance_cap(db, emp, payload.year, payload.month)
        if max_gross > 0 and (current_adv + amount) > max_gross:
            remaining = max_gross - current_adv
            limit_msg = (
                f"Avans tahminiy oylikdan oshib ketadi. Oylik: {max_gross:,.0f}, "
                f"joriy avans: {current_adv:,.0f}, qolgan: {max(remaining, Decimal(0)):,.0f} so'm"
            ).replace(",", " ")
            if not payload.override:
                raise HTTPException(status_code=400, detail=limit_msg)
            if not has_special(user, "system:finance_override"):
                raise HTTPException(
                    status_code=403,
                    detail="Oylikdan ortiq avans berish uchun ruxsat yo'q (super-admin darajasidagi)")

    # Sana o'sha oy ichida bo'lishi kerak (aggregate sanaga qarab oyga biriktiradi)
    today = date.today()
    pay_date = payload.pay_date or (today if month_start <= today <= month_end else month_end)
    if not (month_start <= pay_date <= month_end):
        pay_date = month_end

    currency = payload.currency or emp.currency or "UZS"
    note = payload.note or default_note

    # Moliyadan ayirish — endi SANAGA bog'liq EMAS, alohida bayroq orqali boshqariladi
    # (default: yoqilgan). Eski/migratsiya avanslarni moliyaga tegmasdan kiritish uchun
    # `affect_finance=False` yuboriladi. Oylik to'lovi har doim moliyaga yoziladi.
    if payload.kind == "salary":
        affects_finance = True
    else:
        affects_finance = payload.affect_finance if payload.affect_finance is not None else True

    # 1) HR: SalaryAdvance (xodim oylik-avans tarixiga)
    adv = SalaryAdvance(employee_id=emp.id, advance_date=pay_date, amount=amount,
                        currency=currency, note=note, created_by_id=user.id)
    db.add(adv)

    cat = (await db.execute(
        select(FinanceCategory).where(FinanceCategory.code == cat_code)
    )).scalar_one_or_none()

    acc = None
    tx = None
    if affects_finance:
        # 2) Moliya: operatsion hisobvaraq + chiqim tranzaksiyasi
        acc = (await db.execute(
            select(Account).where(and_(
                Account.currency == currency, Account.ledger == "operational"
            )).limit(1)
        )).scalar_one_or_none()
        tx = FinanceTransaction(
            date=pay_date, type="expense", category_id=cat.id if cat else None,
            amount=amount, currency=currency, account_id=acc.id if acc else None,
            note=note, created_by_id=user.id,
        )
        db.add(tx)
        await db.flush()
        adv.tx_id = tx.id  # bekor qilinganda moliya tranzaksiyasini topish uchun
        await apply_transaction(db, tx)

    await db.commit()

    if tx is not None:
        await db.refresh(tx)
        out = TransactionOut.model_validate(tx)
        out.category_name = cat.name if cat else None
        out.account_name = acc.name if acc else None
        return out

    # Moliyaga ta'sir qilmagan avans — javobni HR yozuvidan quramiz
    await db.refresh(adv)
    out = TransactionOut(
        id=adv.id, date=pay_date, type="expense", category_id=cat.id if cat else None,
        amount=amount, currency=currency, amount_other_curr=Decimal(0),
        account_id=None, related_order_id=None, note=note, status="active",
        created_at=adv.created_at, category_name=cat.name if cat else None,
        account_name=None,
    )
    return out


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


@router.post("/exchange-rates", response_model=ExchangeRateOut, status_code=201)
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
