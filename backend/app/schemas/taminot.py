"""Ta'minot (ichki/tashqi) — Pydantic sxemalar."""
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase

# Ruxsat etilgan ta'minot turlari
SCOPES = ("ichki", "tashqi")


# ---------------------------------------------------------------------------
# Mahsulot
# ---------------------------------------------------------------------------
class TaminotProductCreate(BaseModel):
    scope: str  # "ichki" / "tashqi"
    name: str
    unit: str = "dona"
    unit_price: float = 0
    currency: str = "UZS"
    min_qty: float = Field(0, ge=0, description="Kam qoldi chegarasi (0 — chegara yo'q)")
    supplier: Optional[str] = None
    note: Optional[str] = None


class TaminotProductUpdate(BaseModel):
    name: Optional[str] = None
    unit: Optional[str] = None
    unit_price: Optional[float] = None
    currency: Optional[str] = None
    min_qty: Optional[float] = Field(None, ge=0)
    supplier: Optional[str] = None
    note: Optional[str] = None


class TaminotProductOut(ORMBase):
    id: uuid.UUID
    scope: str
    name: str
    unit: str
    unit_price: float
    currency: str = "UZS"
    min_qty: float = 0
    supplier: Optional[str] = None
    note: Optional[str] = None
    created_at: datetime
    # Hisoblangan pul qiymatlari
    total_purchased: float = 0
    total_paid: float = 0
    balance: float = 0
    last_purchase_at: Optional[datetime] = None
    tx_count: int = 0
    # Hisoblangan ombor qoldig'i (miqdor bo'yicha)
    in_qty: float = 0          # jami olib kelingan miqdor
    out_qty: float = 0         # jami sarflangan miqdor
    adjust_qty: float = 0      # to'g'rilashlar yig'indisi (musbat/manfiy)
    stock: float = 0           # ombordagi qoldiq = in − out + adjust
    stock_value: float = 0     # qoldiqning puldagi qiymati (qoldiq × birlik narxi)
    # none — hali harakat yo'q, out — tugagan, low — kam qoldi, ok — yetarli
    stock_status: str = "none"
    last_consume_at: Optional[datetime] = None


# ---------------------------------------------------------------------------
# Tranzaksiyalar
# ---------------------------------------------------------------------------
class PurchaseCreate(BaseModel):
    """Olib kelish — qarzni oshiradi. qty (+ ixtiyoriy unit_price) → summa = qty × narx."""
    qty: float = Field(gt=0)
    unit_price: Optional[float] = None  # bo'lmasa mahsulot narxi olinadi
    note: Optional[str] = None


class PaymentCreate(BaseModel):
    """Qarz to'lash — qarzni kamaytiradi."""
    amount: float = Field(gt=0)
    note: Optional[str] = None


class ConsumeCreate(BaseModel):
    """Sarflash — ombor qoldig'ini kamaytiradi, qarzga ta'sir qilmaydi."""
    qty: float = Field(gt=0)
    note: Optional[str] = None


class StockSetCreate(BaseModel):
    """Qoldiqni to'g'rilash (inventarizatsiya) — haqiqiy qoldiqni belgilash.

    Farq (yangi qoldiq − joriy qoldiq) `adjust` harakati sifatida yoziladi,
    shuning uchun tarix va hisob-kitob buzilmaydi.
    """
    qty: float = Field(ge=0, description="Ombordagi haqiqiy qoldiq")
    note: Optional[str] = None


class TaminotTransactionOut(ORMBase):
    id: uuid.UUID
    product_id: uuid.UUID
    kind: str
    qty: float
    unit_price: float
    amount: float
    currency: str = "UZS"
    note: Optional[str] = None
    created_at: datetime


class TaminotTxLogOut(BaseModel):
    """Hisobotlar uchun — mahsulot nomi bilan birga to'liq harakatlar jurnali."""
    id: uuid.UUID
    product_id: uuid.UUID
    product_name: str
    unit: str = "dona"
    supplier: Optional[str] = None
    kind: str
    qty: float
    unit_price: float
    amount: float
    currency: str = "UZS"
    note: Optional[str] = None
    created_at: datetime


# ---------------------------------------------------------------------------
# Umumiy hisob (card uchun) — har valyuta alohida
# ---------------------------------------------------------------------------
class CurrencyTotal(BaseModel):
    currency: str
    total_purchased: float = 0
    total_paid: float = 0
    total_balance: float = 0
    with_debt_count: int = 0
    # Shu valyutadagi mahsulotlar ombor qoldig'ining qiymati
    stock_value: float = 0


class TaminotSummary(BaseModel):
    by_currency: list[CurrencyTotal] = []
    product_count: int = 0
    # Ombor holati
    low_stock_count: int = 0     # kam qolganlar (chegaradan past, lekin bor)
    out_of_stock_count: int = 0  # tugaganlar
    ok_stock_count: int = 0      # yetarli
    tracked_count: int = 0       # harakati bo'lgan (qoldig'i hisoblanadigan) mahsulotlar
