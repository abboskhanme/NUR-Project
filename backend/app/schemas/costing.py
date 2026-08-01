"""Tannarx (kalkulyatsiya) — Pydantic sxemalar."""
import uuid
from datetime import date, datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field

ITEM_KINDS = ("material", "expense")


# ---------------------------------------------------------------------------
# Kirish (saqlash)
# ---------------------------------------------------------------------------
class RecipeItemIn(BaseModel):
    """Kalkulyatsiya satri.

    material uchun `material_id` majburiy; `unit_price` bo'sh bo'lsa materialning
    joriy narxi ishlatiladi. expense uchun `label` va `unit_price` majburiy.
    """
    kind: Literal["material", "expense"] = "material"
    material_id: Optional[uuid.UUID] = None
    label: Optional[str] = None
    # qty — miqdor × narx; sum — `amount` to'g'ridan-to'g'ri summa
    entry_mode: Literal["qty", "sum"] = "qty"
    qty: float = Field(1, gt=0)
    amount: Optional[float] = Field(None, ge=0)
    unit: Optional[str] = None
    unit_price: Optional[float] = Field(None, ge=0)
    currency: Literal["UZS", "USD"] = "UZS"


class RecipeIn(BaseModel):
    """Mahsulot kalkulyatsiyasini saqlash — satrlar to'liq almashtiriladi."""
    overhead_percent: float = Field(0, ge=0, le=100)
    target_price_usd: Optional[float] = Field(None, ge=0)
    note: Optional[str] = None
    items: list[RecipeItemIn] = []


# ---------------------------------------------------------------------------
# Chiqish
# ---------------------------------------------------------------------------
class RecipeItemOut(BaseModel):
    id: Optional[uuid.UUID] = None
    kind: str
    material_id: Optional[uuid.UUID] = None
    label: str
    entry_mode: str = "qty"
    qty: float
    amount: Optional[float] = None
    unit: Optional[str] = None
    # Amalda ishlatilgan narx (override yoki materialning joriy narxi)
    unit_price: float
    currency: str = "UZS"
    # Satr summasi: o'z valyutasida va UZS ekvivalentida
    line_total: float
    line_total_uzs: float
    # Narx materialdan jonli olinganmi yoki qo'lda kiritilganmi
    price_from_material: bool = False
    # Material o'chirilgan/topilmagan bo'lsa — ogohlantirish uchun
    material_missing: bool = False


class CostBreakdown(BaseModel):
    """Tannarx tafsiloti (barchasi UZS'da, kurs bilan birga)."""
    usd_rate: float = 0
    materials_uzs: float = 0
    expenses_uzs: float = 0
    overhead_percent: float = 0
    overhead_uzs: float = 0
    cost_uzs: float = 0          # TANNARX
    cost_usd: float = 0
    # Sotish narxi — target_price_usd yoki mahsulotning base_price_usd
    price_usd: float = 0
    price_uzs: float = 0
    price_source: str = "none"   # recipe / product / none
    profit_uzs: float = 0        # foyda = sotish − tannarx
    margin_percent: float = 0    # foyda / sotish × 100
    markup_percent: float = 0    # foyda / tannarx × 100
    # Haqiqiy sotuvlar bo'yicha o'rtacha (order_items asosida)
    avg_sold_uzs: Optional[float] = None
    sold_count: int = 0
    real_profit_uzs: Optional[float] = None
    real_margin_percent: Optional[float] = None


class ProductCostRow(BaseModel):
    """Ro'yxatdagi bitta mahsulot — qisqa ko'rsatkichlar bilan."""
    product_id: uuid.UUID
    display_name: str
    product_type: str
    model: Optional[str] = None
    kvm: Optional[int] = None
    year: Optional[int] = None
    has_recipe: bool = False
    item_count: int = 0
    cost_uzs: Optional[float] = None
    price_uzs: Optional[float] = None
    profit_uzs: Optional[float] = None
    margin_percent: Optional[float] = None
    avg_sold_uzs: Optional[float] = None
    sold_count: int = 0
    updated_at: Optional[datetime] = None


class ProductCostDetail(BaseModel):
    """To'liq kalkulyatsiya (tahrirlash oynasi uchun)."""
    product_id: uuid.UUID
    display_name: str
    product_type: str
    base_price_usd: float = 0
    has_recipe: bool = False
    overhead_percent: float = 0
    target_price_usd: Optional[float] = None
    note: Optional[str] = None
    items: list[RecipeItemOut] = []
    breakdown: CostBreakdown
    updated_at: Optional[datetime] = None


class MaterialOption(BaseModel):
    """Tannarx katalogidagi material."""
    id: uuid.UUID
    name: str
    # Birlik ixtiyoriy (summa rejimida ko'pincha kerak emas)
    unit: Optional[str] = None
    unit_price: float
    currency: str = "UZS"
    note: Optional[str] = None
    is_active: bool = True
    # Nechta mahsulot kalkulyatsiyasida ishlatilgani
    used_in: int = 0


class MaterialIn(BaseModel):
    """Katalogga material qo'shish / tahrirlash."""
    name: str = Field(min_length=2, max_length=255)
    # Ixtiyoriy: bo'sh bo'lsa birlik ko'rsatilmaydi
    unit: Optional[Literal["dona", "kg", "metr", "list", "litr"]] = None
    unit_price: float = Field(0, ge=0)
    currency: Literal["UZS", "USD"] = "UZS"
    note: Optional[str] = None
    is_active: bool = True


class CostingSummary(BaseModel):
    usd_rate: float = 0
    product_count: int = 0
    with_recipe: int = 0
    without_recipe: int = 0
    avg_margin_percent: Optional[float] = None
    best_name: Optional[str] = None
    best_margin_percent: Optional[float] = None
    worst_name: Optional[str] = None
    worst_margin_percent: Optional[float] = None
    loss_count: int = 0  # zarariga ishlayotganlar (foyda <= 0)


# ---------------------------------------------------------------------------
# Matritsa ko'rinishi — mahsulot × material jadvali (kalendar uslubida)
# ---------------------------------------------------------------------------
class MatrixCell(BaseModel):
    """Bitta katak: mahsulotga shu materialdan ketadigan MIQDOR."""
    material_id: uuid.UUID
    value: float = Field(gt=0)


class MatrixRow(BaseModel):
    """Saqlash uchun bitta qator — mahsulot va uning material miqdorlari."""
    product_id: uuid.UUID
    cells: list[MatrixCell] = []


class MatrixRowOut(BaseModel):
    product_id: uuid.UUID
    display_name: str
    has_recipe: bool = False
    # material_id (matn) -> miqdor
    cells: dict[str, float] = {}
    # Faqat materiallardan kelgan summa va to'liq tannarx (xarajat + ustama bilan)
    materials_uzs: float = 0
    cost_uzs: float = 0
    expense_count: int = 0
    # Mahsulot sahifasida summa bilan kiritilgan satrlar (jadvalda tahrirlanmaydi)
    sum_line_count: int = 0
    overhead_percent: float = 0


class MatrixOut(BaseModel):
    """Jadval uchun to'liq ma'lumot: ustunlar (materiallar) + qatorlar."""
    usd_rate: float = 0
    materials: list[MaterialOption] = []
    rows: list[MatrixRowOut] = []


class MatrixSave(BaseModel):
    """Jadvalni saqlash — FAQAT material satrlari almashtiriladi.

    Qo'shimcha xarajatlar, ustama foizi, sotish narxi va izoh o'z holida qoladi
    (ular mahsulot sahifasida tahrirlanadi).
    """
    rows: list[MatrixRow] = []


# ---------------------------------------------------------------------------
# Foyda hisoboti — tannarx × haqiqiy sotuvlar (Hisobotlar bo'limi uchun)
# ---------------------------------------------------------------------------
class ProfitProductRow(BaseModel):
    """Davr ichida sotilgan bitta mahsulot bo'yicha foyda."""
    product_id: uuid.UUID
    display_name: str
    has_recipe: bool = False
    units: int = 0
    revenue_uzs: float = 0
    avg_price_uzs: float = 0
    # Kalkulyatsiya yo'q bo'lsa tannarx noma'lum — None
    unit_cost_uzs: Optional[float] = None
    cogs_uzs: Optional[float] = None
    profit_uzs: Optional[float] = None
    margin_percent: Optional[float] = None


class ProfitTrendPoint(BaseModel):
    """Dinamika nuqtasi: tushum, tannarx va yalpi foyda."""
    date: date
    revenue_uzs: float = 0
    cogs_uzs: float = 0
    profit_uzs: float = 0


class ProfitStructure(BaseModel):
    """Sotilgan mahsulotlar tushumining tarkibi (nimaga qancha ketdi)."""
    materials_uzs: float = 0
    expenses_uzs: float = 0
    overhead_uzs: float = 0
    profit_uzs: float = 0


class ProfitReport(BaseModel):
    """Tannarx asosidagi foyda hisoboti (davr bo'yicha).

    Yalpi foyda FAQAT kalkulyatsiyasi kiritilgan mahsulotlar bo'yicha
    hisoblanadi — kalkulyatsiyasizlari alohida ko'rsatiladi (`uncovered_*`),
    chunki ularning tannarxi noma'lum.
    """
    date_from: date
    date_to: date
    granularity: str = "month"
    usd_rate: float = 0

    units_sold: int = 0
    revenue_uzs: float = 0            # davr ichidagi BARCHA sotuv tushumi
    covered_revenue_uzs: float = 0    # kalkulyatsiyasi bor mahsulotlar tushumi
    uncovered_revenue_uzs: float = 0  # kalkulyatsiyasizlar tushumi
    uncovered_units: int = 0
    uncovered_count: int = 0          # nechta mahsulot turi
    coverage_percent: float = 0       # tushumning necha foizi qamrab olingan

    cogs_uzs: float = 0               # tannarx (sotilgan miqdor × birlik tannarxi)
    gross_profit_uzs: float = 0       # yalpi foyda = qamrab olingan tushum − tannarx
    gross_margin_percent: Optional[float] = None
    opex_uzs: float = 0               # moliyadagi operatsion xarajatlar (UZS)
    net_profit_uzs: float = 0         # sof foyda = yalpi foyda − xarajatlar
    net_margin_percent: Optional[float] = None

    structure: ProfitStructure = ProfitStructure()
    products: list[ProfitProductRow] = []
    trend: list[ProfitTrendPoint] = []

