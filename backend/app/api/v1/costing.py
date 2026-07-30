"""Tannarx va foyda (costing) — asosiy mahsulot tarkibi asosida hisob-kitob.

Har mahsulot uchun kalkulyatsiya kiritiladi: ichki ta'minotdan qanday material,
qancha miqdorda ketadi + qo'lda kiritilgan xarajatlar + umumiy ustama foizi.

MUHIM: material narxi sukut bo'yicha ichki ta'minotdagi JORIY narxdan olinadi —
ta'minotda narx o'zgarsa tannarx o'zi yangilanadi. Satrga narx qo'lda kiritilsa,
shu satr uchun aynan o'sha narx ishlatiladi.

Valyutalar: har satr o'z valyutasida saqlanadi, jami esa oxirgi USD→UZS kursi
bo'yicha so'mda hisoblanadi (kurs Moliya bo'limidan keladi).

Ruxsat: modul `costing` (GET → costing:read, PUT/POST → costing:write,
DELETE → costing:delete). Odatda admin va menejerlarga beriladi.
"""
import uuid
from datetime import date, timedelta
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import case, delete, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.costing import ProductRecipe, ProductRecipeItem
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.taminot import TaminotProduct, TaminotTransaction
from app.schemas.costing import (
    CostBreakdown,
    CostingSummary,
    MaterialOption,
    ProductCostDetail,
    ProductCostRow,
    RecipeIn,
    RecipeItemOut,
)
from app.services.finance_service import latest_exchange_rate

router = APIRouter(dependencies=[Depends(module_guard("costing"))])

# Haqiqiy o'rtacha sotuv narxi shu oraliqdagi buyurtmalardan olinadi
SALES_WINDOW_DAYS = 180


def _q(v) -> Decimal:
    return Decimal(str(v)) if v is not None else Decimal(0)


def _f(v) -> float:
    return float(v or 0)


def _r2(v: Decimal) -> float:
    return float(round(v, 2))


# ---------------------------------------------------------------------------
# Hisob-kitob
# ---------------------------------------------------------------------------
def _build_lines(
    items: list[ProductRecipeItem],
    materials: dict[uuid.UUID, TaminotProduct],
    rate: Decimal,
) -> list[RecipeItemOut]:
    """Satrlarni amaldagi narx bilan hisoblab chiqadi."""
    out: list[RecipeItemOut] = []
    for it in items:
        mat = materials.get(it.material_id) if it.material_id else None
        price_from_material = False
        price = it.unit_price
        currency = it.currency or "UZS"
        if it.kind == "material" and price is None and mat is not None:
            price = mat.unit_price
            currency = mat.currency or "UZS"
            price_from_material = True

        qty = _q(it.qty)
        price_d = _q(price)
        line_total = (qty * price_d).quantize(Decimal("0.01"))
        line_total_uzs = line_total * rate if currency == "USD" else line_total

        out.append(RecipeItemOut(
            id=it.id,
            kind=it.kind,
            material_id=it.material_id,
            label=it.label or (mat.name if mat else "—"),
            qty=_f(it.qty),
            unit=it.unit or (mat.unit if mat else None),
            unit_price=_f(price_d),
            currency=currency,
            line_total=_f(line_total),
            line_total_uzs=_r2(line_total_uzs),
            price_from_material=price_from_material,
            material_missing=it.kind == "material" and mat is None,
        ))
    return out


def _breakdown(
    lines: list[RecipeItemOut],
    recipe: Optional[ProductRecipe],
    product: Product,
    rate: Decimal,
    sales: Optional[tuple[Decimal, int]] = None,
) -> CostBreakdown:
    """Satrlar + ustama + sotish narxidan tannarx va foydani hisoblaydi."""
    materials = sum((_q(l.line_total_uzs) for l in lines if l.kind == "material"), Decimal(0))
    expenses = sum((_q(l.line_total_uzs) for l in lines if l.kind == "expense"), Decimal(0))
    pct = _q(recipe.overhead_percent) if recipe else Decimal(0)
    overhead = ((materials + expenses) * pct / Decimal(100)).quantize(Decimal("0.01"))
    cost = materials + expenses + overhead

    # Sotish narxi: kalkulyatsiyada ko'rsatilgan yoki mahsulot narxi
    price_usd = Decimal(0)
    source = "none"
    if recipe is not None and recipe.target_price_usd is not None:
        price_usd = _q(recipe.target_price_usd)
        source = "recipe"
    elif product.base_price_usd:
        price_usd = _q(product.base_price_usd)
        source = "product"
    price_uzs = (price_usd * rate).quantize(Decimal("0.01"))

    profit = price_uzs - cost
    margin = (profit / price_uzs * 100) if price_uzs > 0 else Decimal(0)
    markup = (profit / cost * 100) if cost > 0 else Decimal(0)

    avg_sold: Optional[float] = None
    real_profit: Optional[float] = None
    real_margin: Optional[float] = None
    sold_count = 0
    if sales:
        total_uzs, qty = sales
        sold_count = int(qty or 0)
        if sold_count > 0:
            avg = (_q(total_uzs) / Decimal(sold_count)).quantize(Decimal("0.01"))
            avg_sold = _f(avg)
            real_profit = _r2(avg - cost)
            real_margin = _r2((avg - cost) / avg * 100) if avg > 0 else 0.0

    return CostBreakdown(
        usd_rate=_f(rate),
        materials_uzs=_r2(materials),
        expenses_uzs=_r2(expenses),
        overhead_percent=_f(pct),
        overhead_uzs=_r2(overhead),
        cost_uzs=_r2(cost),
        cost_usd=_r2(cost / rate) if rate > 0 else 0.0,
        price_usd=_f(price_usd),
        price_uzs=_r2(price_uzs),
        price_source=source,
        profit_uzs=_r2(profit),
        margin_percent=_r2(margin),
        markup_percent=_r2(markup),
        avg_sold_uzs=avg_sold,
        sold_count=sold_count,
        real_profit_uzs=real_profit,
        real_margin_percent=real_margin,
    )


async def _materials_map(db: AsyncSession, ids: set[uuid.UUID]) -> dict[uuid.UUID, TaminotProduct]:
    if not ids:
        return {}
    res = await db.execute(select(TaminotProduct).where(TaminotProduct.id.in_(ids)))
    return {m.id: m for m in res.scalars().all()}


async def _sales_map(db: AsyncSession) -> dict[uuid.UUID, tuple[Decimal, int]]:
    """product_id -> (jami tushum UZS, sotilgan dona) — oxirgi SALES_WINDOW_DAYS kun."""
    cutoff = date.today() - timedelta(days=SALES_WINDOW_DAYS)
    res = await db.execute(
        select(
            OrderItem.product_id,
            func.coalesce(func.sum(OrderItem.total_uzs), 0),
            func.coalesce(func.sum(OrderItem.quantity), 0),
        )
        .join(Order, Order.id == OrderItem.order_id)
        .where(Order.status != "cancelled", Order.order_date >= cutoff)
        .group_by(OrderItem.product_id)
    )
    return {row[0]: (row[1], row[2]) for row in res.all()}


async def _recipes_map(
    db: AsyncSession, product_ids: Optional[list[uuid.UUID]] = None
) -> dict[uuid.UUID, ProductRecipe]:
    q = select(ProductRecipe)
    if product_ids is not None:
        if not product_ids:
            return {}
        q = q.where(ProductRecipe.product_id.in_(product_ids))
    res = await db.execute(q)
    return {r.product_id: r for r in res.scalars().all()}


async def _items_map(
    db: AsyncSession, recipe_ids: list[uuid.UUID]
) -> dict[uuid.UUID, list[ProductRecipeItem]]:
    """recipe_id -> satrlar. Relationship'ga tayanmaymiz (async lazy-load xavfi)."""
    if not recipe_ids:
        return {}
    res = await db.execute(
        select(ProductRecipeItem)
        .where(ProductRecipeItem.recipe_id.in_(recipe_ids))
        .order_by(ProductRecipeItem.sort_order.asc())
    )
    out: dict[uuid.UUID, list[ProductRecipeItem]] = {}
    for it in res.scalars().all():
        out.setdefault(it.recipe_id, []).append(it)
    return out


# ---------------------------------------------------------------------------
# Mahsulotlar ro'yxati (tannarx jadvali)
# ---------------------------------------------------------------------------
@router.get("/products", response_model=list[ProductCostRow])
async def list_product_costs(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    product_type: str = Query("main", description="main / additional / all"),
    search: Optional[str] = None,
    only_missing: bool = Query(False, description="Faqat kalkulyatsiyasi yo'qlar"),
):
    q = select(Product).where(Product.status == "active")
    if product_type in ("main", "additional"):
        q = q.where(Product.product_type == product_type)
    if search:
        like = f"%{search.strip()}%"
        q = q.where(or_(Product.model.ilike(like), Product.name.ilike(like)))
    products = (await db.execute(
        q.order_by(Product.model.asc().nullslast(), Product.year.desc().nullslast(), Product.kvm.asc().nullslast())
    )).scalars().all()

    rate = _q(await latest_exchange_rate(db)) or Decimal(0)
    recipes = await _recipes_map(db, [p.id for p in products])
    items_by_recipe = await _items_map(db, [r.id for r in recipes.values()])
    sales = await _sales_map(db)
    mat_ids = {
        i.material_id
        for rows_ in items_by_recipe.values() for i in rows_ if i.material_id
    }
    materials = await _materials_map(db, mat_ids)

    rows: list[ProductCostRow] = []
    for p in products:
        recipe = recipes.get(p.id)
        if only_missing and recipe is not None:
            continue
        lines = _build_lines(items_by_recipe.get(recipe.id, []), materials, rate) if recipe else []
        b = _breakdown(lines, recipe, p, rate, sales.get(p.id))
        rows.append(ProductCostRow(
            product_id=p.id,
            display_name=p.display_name,
            product_type=p.product_type,
            model=p.model,
            kvm=p.kvm,
            year=p.year,
            has_recipe=recipe is not None,
            item_count=len(lines),
            cost_uzs=b.cost_uzs if recipe else None,
            price_uzs=b.price_uzs or None,
            profit_uzs=b.profit_uzs if (recipe and b.price_uzs) else None,
            margin_percent=b.margin_percent if (recipe and b.price_uzs) else None,
            avg_sold_uzs=b.avg_sold_uzs,
            sold_count=b.sold_count,
            updated_at=recipe.updated_at if recipe else None,
        ))
    return rows


# ---------------------------------------------------------------------------
# Umumiy hisob (KPI)
# ---------------------------------------------------------------------------
@router.get("/summary", response_model=CostingSummary)
async def costing_summary(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    product_type: str = Query("main"),
):
    rows = await list_product_costs(db=db, user=user, product_type=product_type,
                                   search=None, only_missing=False)
    with_recipe = [r for r in rows if r.has_recipe and r.margin_percent is not None]
    margins = [r.margin_percent for r in with_recipe if r.margin_percent is not None]
    best = max(with_recipe, key=lambda r: r.margin_percent or 0, default=None)
    worst = min(with_recipe, key=lambda r: r.margin_percent or 0, default=None)
    rate = _q(await latest_exchange_rate(db)) or Decimal(0)
    return CostingSummary(
        usd_rate=_f(rate),
        product_count=len(rows),
        with_recipe=sum(1 for r in rows if r.has_recipe),
        without_recipe=sum(1 for r in rows if not r.has_recipe),
        avg_margin_percent=round(sum(margins) / len(margins), 2) if margins else None,
        best_name=best.display_name if best else None,
        best_margin_percent=best.margin_percent if best else None,
        worst_name=worst.display_name if worst else None,
        worst_margin_percent=worst.margin_percent if worst else None,
        loss_count=sum(1 for r in with_recipe if (r.profit_uzs or 0) <= 0),
    )


# ---------------------------------------------------------------------------
# Materiallar (ichki ta'minot) — tanlash ro'yxati
# ---------------------------------------------------------------------------
@router.get("/materials", response_model=list[MaterialOption])
async def list_materials(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    search: Optional[str] = None,
):
    """Ichki ta'minot materiallari — narxi va ombordagi qoldig'i bilan."""
    q = select(TaminotProduct).where(TaminotProduct.scope == "ichki")
    if search:
        like = f"%{search.strip()}%"
        q = q.where(or_(TaminotProduct.name.ilike(like), TaminotProduct.supplier.ilike(like)))
    mats = (await db.execute(q.order_by(TaminotProduct.name.asc()))).scalars().all()

    # Qoldiq: kirim − sarf ± to'g'rilash (ta'minot moduli bilan bir xil mantiq)
    stock: dict[uuid.UUID, float] = {}
    if mats:
        res = await db.execute(
            select(
                TaminotTransaction.product_id,
                func.coalesce(func.sum(case(
                    (TaminotTransaction.kind == "purchase", TaminotTransaction.qty),
                    (TaminotTransaction.kind == "consume", -TaminotTransaction.qty),
                    (TaminotTransaction.kind == "adjust", TaminotTransaction.qty),
                    else_=0,
                )), 0),
            )
            .where(TaminotTransaction.product_id.in_([m.id for m in mats]))
            .group_by(TaminotTransaction.product_id)
        )
        stock = {row[0]: _f(row[1]) for row in res.all()}

    return [
        MaterialOption(
            id=m.id, name=m.name, unit=m.unit, unit_price=_f(m.unit_price),
            currency=m.currency, supplier=m.supplier, stock=stock.get(m.id, 0.0),
        )
        for m in mats
    ]


# ---------------------------------------------------------------------------
# Bitta mahsulot kalkulyatsiyasi
# ---------------------------------------------------------------------------
async def _get_product(db: AsyncSession, product_id: uuid.UUID) -> Product:
    p = (await db.execute(select(Product).where(Product.id == product_id))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Mahsulot topilmadi")
    return p


async def _detail(db: AsyncSession, product: Product) -> ProductCostDetail:
    recipe = (await db.execute(
        select(ProductRecipe).where(ProductRecipe.product_id == product.id)
    )).scalar_one_or_none()
    rate = _q(await latest_exchange_rate(db)) or Decimal(0)
    items = (await _items_map(db, [recipe.id])).get(recipe.id, []) if recipe else []
    materials = await _materials_map(db, {i.material_id for i in items if i.material_id})
    lines = _build_lines(items, materials, rate)
    sales = (await _sales_map(db)).get(product.id)
    return ProductCostDetail(
        product_id=product.id,
        display_name=product.display_name,
        product_type=product.product_type,
        base_price_usd=_f(product.base_price_usd),
        has_recipe=recipe is not None,
        overhead_percent=_f(recipe.overhead_percent) if recipe else 0.0,
        target_price_usd=_f(recipe.target_price_usd) if (recipe and recipe.target_price_usd is not None) else None,
        note=recipe.note if recipe else None,
        items=lines,
        breakdown=_breakdown(lines, recipe, product, rate, sales),
        updated_at=recipe.updated_at if recipe else None,
    )


@router.get("/products/{product_id}", response_model=ProductCostDetail)
async def get_product_cost(
    product_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
):
    return await _detail(db, await _get_product(db, product_id))


@router.put("/products/{product_id}", response_model=ProductCostDetail)
async def save_product_cost(
    product_id: uuid.UUID,
    payload: RecipeIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
):
    """Kalkulyatsiyani saqlaydi. Satrlar TO'LIQ almashtiriladi (upsert)."""
    product = await _get_product(db, product_id)

    recipe = (await db.execute(
        select(ProductRecipe).where(ProductRecipe.product_id == product_id)
    )).scalar_one_or_none()
    if recipe is None:
        recipe = ProductRecipe(product_id=product_id, created_by_id=user.id)
        db.add(recipe)
        await db.flush()

    recipe.overhead_percent = _q(payload.overhead_percent)
    recipe.target_price_usd = (
        _q(payload.target_price_usd) if payload.target_price_usd is not None else None
    )
    recipe.note = payload.note

    # Eski satrlar aniq DELETE bilan olib tashlanadi (relationship'ga tegmaymiz —
    # async sessiyada kolleksiyani lazy-load qilish xatoga olib keladi).
    await db.execute(
        delete(ProductRecipeItem).where(ProductRecipeItem.recipe_id == recipe.id)
    )
    await db.flush()

    new_items: list[ProductRecipeItem] = []
    for idx, row in enumerate(payload.items):
        if row.kind == "material":
            if row.material_id is None:
                raise HTTPException(422, "Material satrida material tanlanishi kerak")
            mat = (await db.execute(
                select(TaminotProduct).where(TaminotProduct.id == row.material_id)
            )).scalar_one_or_none()
            if mat is None:
                raise HTTPException(422, "Tanlangan material topilmadi")
            if mat.scope != "ichki":
                raise HTTPException(422, "Faqat ichki ta'minot materiallari qo'shiladi")
            label = row.label or mat.name
            unit = row.unit or mat.unit
            currency = mat.currency if row.unit_price is None else row.currency
        else:
            if not (row.label or "").strip():
                raise HTTPException(422, "Xarajat satrida nom kiritilishi kerak")
            label = row.label.strip()
            unit = row.unit
            currency = row.currency

        new_items.append(ProductRecipeItem(
            recipe_id=recipe.id,
            kind=row.kind,
            material_id=row.material_id if row.kind == "material" else None,
            label=label,
            qty=_q(row.qty),
            unit=unit,
            unit_price=_q(row.unit_price) if row.unit_price is not None else None,
            currency=currency or "UZS",
            sort_order=idx,
        ))

    db.add_all(new_items)
    await db.commit()
    return await _detail(db, product)


@router.delete("/products/{product_id}", status_code=204)
async def delete_product_cost(
    product_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
):
    recipe = (await db.execute(
        select(ProductRecipe).where(ProductRecipe.product_id == product_id)
    )).scalar_one_or_none()
    if recipe is None:
        raise HTTPException(404, "Kalkulyatsiya topilmadi")
    await db.delete(recipe)
    await db.commit()
