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
from sqlalchemy import delete, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import module_guard
from app.db.session import get_db
from app.models.costing import CostingMaterial, ProductRecipe, ProductRecipeItem
from app.models.finance import FinanceCategory, FinanceTransaction
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.schemas.costing import (
    CostBreakdown,
    CostingSummary,
    MaterialIn,
    MaterialOption,
    MatrixOut,
    MatrixRowOut,
    MatrixSave,
    ProductCostDetail,
    OpexRow,
    ProductCostRow,
    ProfitProductRow,
    ProfitReport,
    ProfitStructure,
    ProfitTrendPoint,
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
    materials: dict[uuid.UUID, CostingMaterial],
    rate: Decimal,
) -> list[RecipeItemOut]:
    """Satrlarni amaldagi narx bilan hisoblab chiqadi.

    entry_mode="sum" — satr summasi `amount` dan olinadi (miqdor × narx emas).
    entry_mode="qty" — miqdor × narx; narx bo'sh bo'lsa katalogdan jonli olinadi.
    """
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
        if (it.entry_mode or "qty") == "sum":
            line_total = _q(it.amount).quantize(Decimal("0.01"))
        else:
            line_total = (qty * price_d).quantize(Decimal("0.01"))
        line_total_uzs = line_total * rate if currency == "USD" else line_total

        out.append(RecipeItemOut(
            id=it.id,
            kind=it.kind,
            material_id=it.material_id,
            label=it.label or (mat.name if mat else "—"),
            entry_mode=it.entry_mode or "qty",
            qty=_f(it.qty),
            amount=_f(it.amount) if it.amount is not None else None,
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


async def _materials_map(db: AsyncSession, ids: set[uuid.UUID]) -> dict[uuid.UUID, CostingMaterial]:
    if not ids:
        return {}
    res = await db.execute(select(CostingMaterial).where(CostingMaterial.id.in_(ids)))
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
        .where(Order.status != "rejected", Order.order_date >= cutoff)
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
    search: Optional[str] = None,
    only_missing: bool = Query(False, description="Faqat kalkulyatsiyasi yo'qlar"),
):
    # Tannarx faqat ASOSIY mahsulotlar (kotyollar) uchun yuritiladi
    q = select(Product).where(Product.status == "active", Product.product_type == "main")
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
):
    rows = await list_product_costs(db=db, user=user, search=None, only_missing=False)
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
# ---------------------------------------------------------------------------
# Materiallar katalogi — tannarx modulining O'Z ro'yxati (ta'minotdan mustaqil)
# ---------------------------------------------------------------------------
def _material_out(m: CostingMaterial, used_in: int = 0) -> MaterialOption:
    return MaterialOption(
        id=m.id, name=m.name, unit=m.unit, unit_price=_f(m.unit_price),
        currency=m.currency, note=m.note, is_active=m.is_active, used_in=used_in,
    )


async def _usage_map(db: AsyncSession) -> dict[uuid.UUID, int]:
    """material_id -> nechta mahsulot kalkulyatsiyasida ishlatilgan."""
    res = await db.execute(
        select(ProductRecipeItem.material_id,
               func.count(func.distinct(ProductRecipeItem.recipe_id)))
        .where(ProductRecipeItem.material_id.isnot(None))
        .group_by(ProductRecipeItem.material_id)
    )
    return {row[0]: int(row[1] or 0) for row in res.all()}


@router.get("/materials", response_model=list[MaterialOption])
async def list_materials(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    search: Optional[str] = None,
    include_inactive: bool = Query(False, description="Arxivlanganlar ham"),
):
    q = select(CostingMaterial)
    if not include_inactive:
        q = q.where(CostingMaterial.is_active.is_(True))
    if search:
        q = q.where(CostingMaterial.name.ilike(f"%{search.strip()}%"))
    mats = (await db.execute(q.order_by(CostingMaterial.name.asc()))).scalars().all()
    usage = await _usage_map(db)
    return [_material_out(m, usage.get(m.id, 0)) for m in mats]


async def _check_duplicate(db: AsyncSession, name: str, exclude_id: Optional[uuid.UUID] = None):
    q = select(CostingMaterial).where(func.lower(CostingMaterial.name) == name.lower())
    if exclude_id is not None:
        q = q.where(CostingMaterial.id != exclude_id)
    dup = (await db.execute(q)).scalar_one_or_none()
    if dup is not None:
        raise HTTPException(422, f"«{dup.name}» nomli material allaqachon bor")


@router.post("/materials", response_model=MaterialOption, status_code=201)
async def create_material(
    payload: MaterialIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
):
    """Katalogga yangi material qo'shadi (tannarx bo'limining o'z ro'yxati)."""
    name = payload.name.strip()
    await _check_duplicate(db, name)
    m = CostingMaterial(
        name=name, unit=payload.unit or None, unit_price=_q(payload.unit_price),
        currency=payload.currency, note=payload.note,
        is_active=payload.is_active, created_by_id=user.id,
    )
    db.add(m)
    await db.commit()
    await db.refresh(m)
    return _material_out(m)


@router.patch("/materials/{material_id}", response_model=MaterialOption)
async def update_material(
    material_id: uuid.UUID,
    payload: MaterialIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
):
    """Materialni tahrirlaydi. Narx o'zgarsa — uni ishlatgan barcha
    kalkulyatsiyalar tannarxi o'zi yangilanadi (satrda narx qotirilmagan bo'lsa)."""
    m = (await db.execute(
        select(CostingMaterial).where(CostingMaterial.id == material_id)
    )).scalar_one_or_none()
    if m is None:
        raise HTTPException(404, "Material topilmadi")
    name = payload.name.strip()
    await _check_duplicate(db, name, exclude_id=material_id)
    m.name = name
    m.unit = payload.unit or None
    m.unit_price = _q(payload.unit_price)
    m.currency = payload.currency
    m.note = payload.note
    m.is_active = payload.is_active
    await db.commit()
    await db.refresh(m)
    usage = await _usage_map(db)
    return _material_out(m, usage.get(m.id, 0))


@router.delete("/materials/{material_id}", status_code=204)
async def delete_material(
    material_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
):
    """Materialni o'chiradi. Kalkulyatsiyada ishlatilgan bo'lsa — o'chirmaydi,
    o'rniga arxivlashni taklif qiladi (tarix buzilmasligi uchun)."""
    m = (await db.execute(
        select(CostingMaterial).where(CostingMaterial.id == material_id)
    )).scalar_one_or_none()
    if m is None:
        raise HTTPException(404, "Material topilmadi")
    used = (await _usage_map(db)).get(material_id, 0)
    if used > 0:
        raise HTTPException(
            422,
            f"Bu material {used} ta mahsulot kalkulyatsiyasida ishlatilgan — "
            "o'chirish o'rniga arxivlang (faol emas qilib qo'ying)",
        )
    await db.delete(m)
    await db.commit()


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
                select(CostingMaterial).where(CostingMaterial.id == row.material_id)
            )).scalar_one_or_none()
            if mat is None:
                raise HTTPException(422, "Tanlangan material katalogda topilmadi")
            label = row.label or mat.name
            unit = row.unit or mat.unit
            currency = mat.currency if row.unit_price is None else row.currency
        else:
            if not (row.label or "").strip():
                raise HTTPException(422, "Xarajat satrida nom kiritilishi kerak")
            label = row.label.strip()
            unit = row.unit
            currency = row.currency

        if row.entry_mode == "sum" and (row.amount is None or row.amount <= 0):
            raise HTTPException(422, f"«{label}» uchun summa kiritilishi kerak")

        new_items.append(ProductRecipeItem(
            recipe_id=recipe.id,
            kind=row.kind,
            material_id=row.material_id if row.kind == "material" else None,
            label=label,
            entry_mode=row.entry_mode,
            qty=_q(row.qty),
            amount=_q(row.amount) if row.entry_mode == "sum" else None,
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


# ---------------------------------------------------------------------------
# Matritsa: mahsulot × material jadvali (bir ekranda hammasini belgilash)
# ---------------------------------------------------------------------------
@router.get("/matrix", response_model=MatrixOut)
async def costing_matrix(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
):
    """Jadval ko'rinishi: qatorlar — asosiy mahsulotlar, ustunlar — ichki materiallar.

    Katakdagi qiymat — shu mahsulotga o'sha materialdan qancha ketishi. Narx
    ta'minotdan jonli olinadi, shuning uchun katakda faqat MIQDOR bo'ladi.
    """
    products = (await db.execute(
        select(Product)
        .where(Product.status == "active", Product.product_type == "main")
        .order_by(Product.model.asc().nullslast(),
                  Product.year.desc().nullslast(),
                  Product.kvm.asc().nullslast())
    )).scalars().all()

    materials = await list_materials(db=db, user=user, search=None, include_inactive=False)
    mat_by_id = {m.id: m for m in materials}
    rate = _q(await latest_exchange_rate(db)) or Decimal(0)

    recipes = await _recipes_map(db, [p.id for p in products])
    items_by_recipe = await _items_map(db, [r.id for r in recipes.values()])

    rows: list[MatrixRowOut] = []
    for p in products:
        recipe = recipes.get(p.id)
        items = items_by_recipe.get(recipe.id, []) if recipe else []
        cells: dict[str, float] = {}
        sum_lines = 0
        for it in items:
            if it.kind != "material":
                continue
            if (it.entry_mode or "qty") == "sum":
                # Summa bilan kiritilgan satr — jadvalda tahrirlanmaydi, faqat sanaladi
                sum_lines += 1
                continue
            if it.material_id and it.material_id in mat_by_id:
                key = str(it.material_id)
                cells[key] = cells.get(key, 0.0) + _f(it.qty)

        lines = _build_lines(
            items,
            await _materials_map(db, {i.material_id for i in items if i.material_id}),
            rate,
        )
        b = _breakdown(lines, recipe, p, rate, None)
        rows.append(MatrixRowOut(
            product_id=p.id,
            display_name=p.display_name,
            has_recipe=recipe is not None,
            cells=cells,
            materials_uzs=b.materials_uzs,
            cost_uzs=b.cost_uzs,
            expense_count=sum(1 for l in lines if l.kind == "expense"),
            sum_line_count=sum_lines,
            overhead_percent=b.overhead_percent,
        ))

    return MatrixOut(usd_rate=_f(rate), materials=materials, rows=rows)


@router.put("/matrix", response_model=MatrixOut)
async def save_costing_matrix(
    payload: MatrixSave,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
):
    """Jadvalni saqlaydi — FAQAT material satrlari almashtiriladi.

    Har bir qator uchun eski material satrlari o'chiriladi va yangilari yoziladi.
    Qo'shimcha xarajatlar, ustama foizi, sotish narxi va izoh TEGILMAYDI —
    ular mahsulotning o'z sahifasida tahrirlanadi.
    """
    if not payload.rows:
        return await costing_matrix(db=db, user=user)

    # Faqat asosiy mahsulotlar va faqat ichki materiallar
    product_ids = [r.product_id for r in payload.rows]
    products = {p.id: p for p in (await db.execute(
        select(Product).where(Product.id.in_(product_ids))
    )).scalars().all()}
    for pid in product_ids:
        if pid not in products:
            raise HTTPException(422, "Mahsulot topilmadi")

    mat_ids = {c.material_id for r in payload.rows for c in r.cells}
    mats = await _materials_map(db, mat_ids)
    for mid in mat_ids:
        if mats.get(mid) is None:
            raise HTTPException(422, "Tanlangan material katalogda topilmadi")

    recipes = await _recipes_map(db, product_ids)
    for row in payload.rows:
        recipe = recipes.get(row.product_id)
        if recipe is None:
            recipe = ProductRecipe(product_id=row.product_id, created_by_id=user.id)
            db.add(recipe)
            await db.flush()
            recipes[row.product_id] = recipe

        # Faqat MIQDOR bilan kiritilgan material satrlari almashtiriladi.
        # Xarajatlar va summa bilan kiritilgan satrlar SAQLANADI (ular mahsulot
        # sahifasida boshqariladi).
        await db.execute(
            delete(ProductRecipeItem).where(
                ProductRecipeItem.recipe_id == recipe.id,
                ProductRecipeItem.kind == "material",
                ProductRecipeItem.entry_mode != "sum",
            )
        )
        await db.flush()

        # Xarajat satrlari sort_order'da tepada qolmasligi uchun materiallarni
        # oldindan joylashtiramiz (0..n-1)
        for idx, cell in enumerate(row.cells):
            mat = mats[cell.material_id]
            db.add(ProductRecipeItem(
                recipe_id=recipe.id,
                kind="material",
                material_id=mat.id,
                label=mat.name,
                entry_mode="qty",
                qty=_q(cell.value),
                amount=None,
                unit=mat.unit,
                unit_price=None,          # narx katalogdan jonli olinadi
                currency=mat.currency or "UZS",
                sort_order=idx,
            ))

    await db.commit()
    return await costing_matrix(db=db, user=user)


# ---------------------------------------------------------------------------
# Foyda hisoboti — tannarx × haqiqiy sotuvlar (Hisobotlar bo'limi «Tannarx» tabi)
# ---------------------------------------------------------------------------
def _resolve_report_range(
    date_from: Optional[date], date_to: Optional[date]
) -> tuple[date, date]:
    """Bo'sh qoldirilsa — joriy oyning 1-kunidan bugungacha."""
    today = date.today()
    date_to = date_to or today
    date_from = date_from or date_to.replace(day=1)
    return date_from, date_to


async def _cost_map(
    db: AsyncSession, product_ids: list[uuid.UUID], rate: Decimal
) -> dict[uuid.UUID, CostBreakdown]:
    """product_id -> tannarx tafsiloti. FAQAT kalkulyatsiyasi borlar kiradi."""
    if not product_ids:
        return {}
    products = {p.id: p for p in (await db.execute(
        select(Product).where(Product.id.in_(product_ids))
    )).scalars().all()}
    recipes = await _recipes_map(db, product_ids)
    items_by_recipe = await _items_map(db, [r.id for r in recipes.values()])
    materials = await _materials_map(db, {
        i.material_id for rows_ in items_by_recipe.values() for i in rows_ if i.material_id
    })

    out: dict[uuid.UUID, CostBreakdown] = {}
    for pid, recipe in recipes.items():
        product = products.get(pid)
        if product is None:
            continue
        lines = _build_lines(items_by_recipe.get(recipe.id, []), materials, rate)
        out[pid] = _breakdown(lines, recipe, product, rate, None)
    return out


def _period_points(date_from: date, date_to: date, granularity: str) -> list[date]:
    """Grafik uchun bo'sh davrlar ham chiqishi kerak — to'liq ro'yxat."""
    out: list[date] = []
    if granularity == "day":
        cur = date_from
        while cur <= date_to:
            out.append(cur)
            cur += timedelta(days=1)
        return out
    cur = date_from.replace(day=1)
    last = date_to.replace(day=1)
    while cur <= last:
        out.append(cur)
        cur = (cur + timedelta(days=32)).replace(day=1)
    return out


async def _profit_trend(
    db: AsyncSession,
    date_from: date,
    date_to: date,
    granularity: str,
    costs: dict[uuid.UUID, CostBreakdown],
    sold_cond: tuple,
) -> list[ProfitTrendPoint]:
    """Davrlar kesimida tushum / tannarx / yalpi foyda dinamikasi."""
    period_col = (
        Order.order_date if granularity == "day"
        else func.date_trunc("month", Order.order_date)
    )
    rows = (await db.execute(
        select(period_col.label("p"), OrderItem.product_id,
               func.coalesce(func.sum(OrderItem.quantity), 0),
               func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(Order, Order.id == OrderItem.order_id)
        .where(*sold_cond)
        .group_by("p", OrderItem.product_id)
    )).all()

    agg: dict[date, list[Decimal]] = {}
    for period, pid, qty, total in rows:
        b = costs.get(pid)
        # Kalkulyatsiyasizlar dinamikaga ham kirmaydi (tannarxi noma'lum)
        if b is None:
            continue
        key = period.date() if hasattr(period, "date") else period
        cell = agg.setdefault(key, [Decimal(0), Decimal(0)])
        cell[0] += _q(total)
        cell[1] += _q(b.cost_uzs) * int(qty or 0)

    out: list[ProfitTrendPoint] = []
    for point in _period_points(date_from, date_to, granularity):
        rev, cost = agg.get(point, [Decimal(0), Decimal(0)])
        out.append(ProfitTrendPoint(
            date=point, revenue_uzs=_r2(rev), cogs_uzs=_r2(cost),
            profit_uzs=_r2(rev - cost),
        ))
    return out


@router.get("/profit-report", response_model=ProfitReport)
async def profit_report(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: CurrentUser,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    granularity: str = Query("month", pattern="^(day|month)$"),
):
    """Tannarx asosidagi FOYDA hisoboti — Hisobotlar bo'limi uchun.

    Davr ichida haqiqatda sotilgan mahsulotlar (buyurtma satrlari) olinadi va
    har biriga JORIY tannarx qo'llanadi:

        tannarx (COGS) = sotilgan dona × birlik tannarxi
        yalpi foyda    = tushum − tannarx
        sof foyda      = yalpi foyda − moliyadagi operatsion xarajatlar

    MUHIM: tannarx JORIY narxlar bo'yicha hisoblanadi (o'sha kundagi narx
    tarixi saqlanmaydi), rad etilgan buyurtmalar hisobga olinmaydi va
    kalkulyatsiyasi kiritilmagan mahsulotlar foyda hisobiga KIRMAYDI —
    ular alohida `uncovered_*` maydonlarida ko'rsatiladi.
    """
    date_from, date_to = _resolve_report_range(date_from, date_to)
    rate = _q(await latest_exchange_rate(db)) or Decimal(0)
    sold_cond = (
        Order.status != "rejected",
        Order.order_date >= date_from,
        Order.order_date <= date_to,
    )

    # --- Davr ichida sotilganlar (mahsulot kesimida) ---
    sold_rows = (await db.execute(
        select(OrderItem.product_id,
               func.coalesce(func.sum(OrderItem.quantity), 0),
               func.coalesce(func.sum(OrderItem.total_uzs), 0))
        .join(Order, Order.id == OrderItem.order_id)
        .where(*sold_cond)
        .group_by(OrderItem.product_id)
    )).all()

    product_ids = [r[0] for r in sold_rows]
    products = {p.id: p for p in (await db.execute(
        select(Product).where(Product.id.in_(product_ids))
    )).scalars().all()} if product_ids else {}
    costs = await _cost_map(db, product_ids, rate)

    rows: list[ProfitProductRow] = []
    units_sold = revenue = covered_revenue = cogs = Decimal(0)
    uncovered_revenue = Decimal(0)
    uncovered_units = uncovered_count = 0
    mat_total = exp_total = ovh_total = Decimal(0)

    for pid, qty, total in sold_rows:
        p = products.get(pid)
        if p is None:
            continue
        units = int(qty or 0)
        rev = _q(total)
        units_sold += units
        revenue += rev
        b = costs.get(pid)
        avg_price = (rev / units).quantize(Decimal("0.01")) if units else Decimal(0)

        if b is None:
            uncovered_revenue += rev
            uncovered_units += units
            uncovered_count += 1
            rows.append(ProfitProductRow(
                product_id=pid, display_name=p.display_name, has_recipe=False,
                units=units, revenue_uzs=_r2(rev), avg_price_uzs=_f(avg_price),
            ))
            continue

        unit_cost = _q(b.cost_uzs)
        line_cogs = (unit_cost * units).quantize(Decimal("0.01"))
        profit = rev - line_cogs
        covered_revenue += rev
        cogs += line_cogs
        mat_total += _q(b.materials_uzs) * units
        exp_total += _q(b.expenses_uzs) * units
        ovh_total += _q(b.overhead_uzs) * units
        rows.append(ProfitProductRow(
            product_id=pid, display_name=p.display_name, has_recipe=True,
            units=units, revenue_uzs=_r2(rev), avg_price_uzs=_f(avg_price),
            unit_cost_uzs=_f(unit_cost), cogs_uzs=_r2(line_cogs),
            profit_uzs=_r2(profit),
            margin_percent=_r2(profit / rev * 100) if rev > 0 else 0.0,
        ))

    rows.sort(key=lambda r: r.profit_uzs if r.profit_uzs is not None else -1, reverse=True)

    # --- Operatsion xarajatlar (moliya, faqat UZS va faol tranzaksiyalar) ---
    # DIQQAT: moliyadagi KIRIM ishlatilmaydi — u kassa/naqd oqimini ko'rsatadi,
    # sotuvning hammasi (karta bilan to'langani) unga tushmaydi. Tushum har doim
    # Sotuv bo'limidan olinadi.
    opex_cond = (
        FinanceTransaction.date >= date_from,
        FinanceTransaction.date <= date_to,
        FinanceTransaction.status == "active",
        FinanceTransaction.currency == "UZS",
        FinanceTransaction.type == "expense",
    )
    opex_rows = (await db.execute(
        select(FinanceCategory.name,
               func.coalesce(func.sum(FinanceTransaction.amount), 0),
               func.count(FinanceTransaction.id))
        .join(FinanceCategory,
              FinanceCategory.id == FinanceTransaction.category_id, isouter=True)
        .where(*opex_cond)
        .group_by(FinanceCategory.name)
        .order_by(func.sum(FinanceTransaction.amount).desc())
    )).all()
    opex = sum((_q(a) for _n, a, _c in opex_rows), Decimal(0))
    opex_count = sum(int(c or 0) for _n, _a, c in opex_rows)

    gross = covered_revenue - cogs
    net = gross - opex

    return ProfitReport(
        date_from=date_from,
        date_to=date_to,
        granularity=granularity,
        usd_rate=_f(rate),
        units_sold=int(units_sold),
        revenue_uzs=_r2(revenue),
        covered_revenue_uzs=_r2(covered_revenue),
        uncovered_revenue_uzs=_r2(uncovered_revenue),
        uncovered_units=uncovered_units,
        uncovered_count=uncovered_count,
        coverage_percent=_r2(covered_revenue / revenue * 100) if revenue > 0 else 0.0,
        cogs_uzs=_r2(cogs),
        gross_profit_uzs=_r2(gross),
        gross_margin_percent=_r2(gross / covered_revenue * 100) if covered_revenue > 0 else None,
        opex_uzs=_r2(opex),
        opex_count=opex_count,
        opex_by_category=[
            OpexRow(category=n or "Boshqa", amount_uzs=_r2(_q(a)), count=int(c or 0))
            for n, a, c in opex_rows
        ],
        net_profit_uzs=_r2(net),
        net_margin_percent=_r2(net / covered_revenue * 100) if covered_revenue > 0 else None,
        structure=ProfitStructure(
            materials_uzs=_r2(mat_total),
            expenses_uzs=_r2(exp_total),
            overhead_uzs=_r2(ovh_total),
            profit_uzs=_r2(gross),
        ),
        products=rows,
        trend=await _profit_trend(db, date_from, date_to, granularity, costs, sold_cond),
    )
