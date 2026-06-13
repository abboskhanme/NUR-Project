"""Global qidiruv — barcha bo'limlar bo'yicha yagona qidiruv.

Mijoz, buyurtma, mahsulot va servis chiptalarini bitta so'rovda qidiradi.
Faqat foydalanuvchi ruxsati bor bo'limlar natijaga kiritiladi.
"""
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import VERBS, has_permission
from app.db.session import get_db
from app.models.customer import Customer
from app.models.order import Order
from app.models.product import Product
from app.models.service import ServiceTicket

router = APIRouter()


def _norm(col):
    """Telefon raqamini solishtirish uchun bo'shliq/+/- belgilarini olib tashlash."""
    return func.replace(func.replace(func.replace(
        func.coalesce(col, ""), " ", ""), "-", ""), "+", "")


def _can_read(user, module: str) -> bool:
    return any(has_permission(user, f"{module}:{v}") for v in VERBS)


@router.get("")
async def global_search(
    db: Annotated[AsyncSession, Depends(get_db)], current: CurrentUser,
    q: str = Query(..., min_length=1),
    per_type: int = Query(6, ge=1, le=20),
):
    text = q.strip()
    if len(text) < 2:
        return {"query": text, "groups": []}

    like = f"%{text}%"
    digits = "".join(c for c in text if c.isdigit())
    groups: list[dict] = []

    # --- Mijozlar ---
    if _can_read(current, "customers"):
        conds = [Customer.full_name.ilike(like)]
        if digits:
            conds.append(_norm(Customer.phone).like(f"%{digits}%"))
            conds.append(_norm(Customer.phone2).like(f"%{digits}%"))
        rows = (await db.execute(
            select(Customer.id, Customer.full_name, Customer.phone,
                   Customer.region, Customer.city)
            .where(or_(*conds))
            .order_by(Customer.full_name.asc())
            .limit(per_type)
        )).all()
        items = [
            {"id": str(i), "label": name,
             "sublabel": " · ".join(x for x in [phone, region or city] if x) or None,
             "route": f"/customers/{i}"}
            for i, name, phone, region, city in rows
        ]
        if items:
            groups.append({"type": "customers", "items": items})

    # --- Buyurtmalar ---
    if _can_read(current, "orders"):
        conds = [Order.code.ilike(like), Customer.full_name.ilike(like)]
        if digits:
            conds.append(_norm(Customer.phone).like(f"%{digits}%"))
        rows = (await db.execute(
            select(Order.id, Order.code, Order.status, Customer.full_name)
            .outerjoin(Customer, Customer.id == Order.customer_id)
            .where(or_(*conds))
            .order_by(Order.order_date.desc(), Order.created_at.desc())
            .limit(per_type)
        )).all()
        items = [
            {"id": str(i), "label": code,
             "sublabel": cust or None, "status": status,
             "route": f"/orders/{i}"}
            for i, code, status, cust in rows
        ]
        if items:
            groups.append({"type": "orders", "items": items})

    # --- Mahsulotlar ---
    if _can_read(current, "products"):
        conds = [Product.model.ilike(like), Product.name.ilike(like),
                 Product.sku.ilike(like)]
        rows = (await db.execute(
            select(Product.id, Product.model, Product.name, Product.kvm, Product.sku)
            .where(or_(*conds))
            .order_by(Product.model.asc().nulls_last(), Product.name.asc().nulls_last())
            .limit(per_type)
        )).all()
        items = [
            {"id": str(i),
             "label": (model or name or sku or "—") + (f" · {kvm} kvm" if kvm else ""),
             "sublabel": sku or None,
             "route": "/products"}
            for i, model, name, kvm, sku in rows
        ]
        if items:
            groups.append({"type": "products", "items": items})

    # --- Servis chiptalari ---
    if _can_read(current, "service"):
        conds = [ServiceTicket.code.ilike(like), ServiceTicket.problem.ilike(like)]
        rows = (await db.execute(
            select(ServiceTicket.id, ServiceTicket.code, ServiceTicket.status,
                   ServiceTicket.problem)
            .where(or_(*conds))
            .order_by(ServiceTicket.opened_at.desc())
            .limit(per_type)
        )).all()
        items = [
            {"id": str(i), "label": code, "status": status,
             "sublabel": (problem[:50] + "…") if problem and len(problem) > 50 else problem,
             "route": "/service"}
            for i, code, status, problem in rows
        ]
        if items:
            groups.append({"type": "service", "items": items})

    return {"query": text, "groups": groups}
