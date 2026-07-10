"""Maqsadlar — mustaqil modul API.

Boshqa bo'limlarga (moliya, savdo, ta'minot) hech qanday ta'sir qilmaydi.
"""
import uuid
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.target import Target, TargetContribution
from app.schemas.target import (
    ContributionCreate,
    TargetContributionOut,
    TargetCreate,
    TargetCurrencyTotal,
    TargetOut,
    TargetSummary,
    TargetUpdate,
)

router = APIRouter(dependencies=[Depends(module_guard("targets"))])


def _q(v) -> float:
    return float(v or 0)


async def _aggregates(db: AsyncSession, target_ids: Optional[list[uuid.UUID]] = None):
    """target_id -> {saved, last_at, count} xaritasi."""
    q = select(
        TargetContribution.target_id,
        func.coalesce(func.sum(TargetContribution.amount), 0).label("saved"),
        func.max(TargetContribution.created_at).label("last_at"),
        func.count(TargetContribution.id).label("cnt"),
    ).group_by(TargetContribution.target_id)
    if target_ids is not None:
        if not target_ids:
            return {}
        q = q.where(TargetContribution.target_id.in_(target_ids))
    res = await db.execute(q)
    out: dict[uuid.UUID, dict] = {}
    for row in res.all():
        out[row.target_id] = {
            "saved": _q(row.saved),
            "last_at": row.last_at,
            "count": row.cnt or 0,
        }
    return out


def _build_out(t: Target, agg: dict) -> TargetOut:
    goal = _q(t.target_amount)
    saved = agg.get("saved", 0.0)
    remaining = round(max(goal - saved, 0.0), 2)
    progress = round(min(saved / goal * 100, 100), 2) if goal > 0 else 0.0
    return TargetOut(
        id=t.id,
        name=t.name,
        target_amount=goal,
        currency=t.currency,
        deadline=t.deadline,
        note=t.note,
        created_at=t.created_at,
        saved_amount=round(saved, 2),
        remaining=remaining,
        progress=progress,
        is_completed=goal > 0 and saved >= goal,
        last_contribution_at=agg.get("last_at"),
        contribution_count=agg.get("count", 0),
    )


async def _get_target(db: AsyncSession, target_id: uuid.UUID) -> Target:
    t = (await db.execute(select(Target).where(Target.id == target_id))).scalar_one_or_none()
    if not t:
        raise HTTPException(404, "Maqsad topilmadi")
    return t


# ---------------------------------------------------------------------------
# Umumiy hisob
# ---------------------------------------------------------------------------
@router.get("/summary", response_model=TargetSummary)
async def target_summary(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(select(Target))
    targets = res.scalars().all()
    agg = await _aggregates(db, [t.id for t in targets])

    by_cur: dict[str, dict] = {}
    for t in targets:
        cur = t.currency or "UZS"
        slot = by_cur.setdefault(
            cur, {"goal": 0.0, "saved": 0.0, "count": 0, "completed": 0}
        )
        goal = _q(t.target_amount)
        saved = agg.get(t.id, {}).get("saved", 0.0)
        slot["goal"] += goal
        # Ortiqcha yig'ilgan summa "qolgani"ni manfiy qilmasligi uchun cheklaymiz
        slot["saved"] += min(saved, goal) if goal > 0 else saved
        slot["count"] += 1
        if goal > 0 and saved >= goal:
            slot["completed"] += 1

    totals = [
        TargetCurrencyTotal(
            currency=cur,
            total_target=round(s["goal"], 2),
            total_saved=round(s["saved"], 2),
            total_remaining=round(max(s["goal"] - s["saved"], 0.0), 2),
            target_count=s["count"],
            completed_count=s["completed"],
        )
        for cur, s in sorted(by_cur.items())
    ]
    return TargetSummary(by_currency=totals, target_count=len(targets))


# ---------------------------------------------------------------------------
# Maqsadlar
# ---------------------------------------------------------------------------
@router.get("", response_model=list[TargetOut])
async def list_targets(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: CurrentUser,
    search: Optional[str] = None,
    status: str = Query("all", pattern="^(all|active|completed)$"),
):
    q = select(Target)
    if search:
        like = f"%{search.strip()}%"
        q = q.where(or_(Target.name.ilike(like), Target.note.ilike(like)))
    res = await db.execute(q.order_by(Target.created_at.desc()))
    targets = res.scalars().all()
    agg = await _aggregates(db, [t.id for t in targets])
    out = [_build_out(t, agg.get(t.id, {})) for t in targets]
    if status == "active":
        out = [o for o in out if not o.is_completed]
    elif status == "completed":
        out = [o for o in out if o.is_completed]
    return out


@router.post("", response_model=TargetOut, status_code=201)
async def create_target(
    payload: TargetCreate, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    t = Target(**payload.model_dump(), created_by_id=user.id)
    db.add(t)
    await db.commit()
    await db.refresh(t)
    return _build_out(t, {})


@router.patch("/{target_id}", response_model=TargetOut)
async def update_target(
    target_id: uuid.UUID,
    payload: TargetUpdate,
    _: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    t = await _get_target(db, target_id)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(t, k, v)
    await db.commit()
    await db.refresh(t)
    agg = await _aggregates(db, [t.id])
    return _build_out(t, agg.get(t.id, {}))


@router.delete("/{target_id}", status_code=204)
async def delete_target(
    target_id: uuid.UUID, _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    t = await _get_target(db, target_id)
    await db.delete(t)  # qo'shimchalar cascade bilan o'chadi
    await db.commit()


# ---------------------------------------------------------------------------
# Qo'shimchalar (summa qo'shish)
# ---------------------------------------------------------------------------
@router.get("/{target_id}/contributions", response_model=list[TargetContributionOut])
async def list_contributions(
    target_id: uuid.UUID, _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    await _get_target(db, target_id)
    res = await db.execute(
        select(TargetContribution)
        .where(TargetContribution.target_id == target_id)
        .order_by(TargetContribution.created_at.desc())
    )
    return res.scalars().all()


@router.post("/{target_id}/contributions", response_model=TargetContributionOut, status_code=201)
async def add_contribution(
    target_id: uuid.UUID,
    payload: ContributionCreate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    t = await _get_target(db, target_id)
    c = TargetContribution(
        target_id=t.id,
        amount=Decimal(str(payload.amount)).quantize(Decimal("0.01")),
        currency=t.currency,
        note=payload.note,
        created_by_id=user.id,
    )
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


@router.delete("/contributions/{contribution_id}", status_code=204)
async def delete_contribution(
    contribution_id: uuid.UUID, _: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]
):
    c = (
        await db.execute(
            select(TargetContribution).where(TargetContribution.id == contribution_id)
        )
    ).scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Yozuv topilmadi")
    await db.delete(c)
    await db.commit()
