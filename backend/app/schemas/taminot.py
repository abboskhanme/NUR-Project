"""Ta'minot (ichki/tashqi) — Pydantic sxemalar."""
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal, Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase

# Ruxsat etilgan ta'minot turlari
SCOPES = ("ichki", "tashqi")


# ---------------------------------------------------------------------------
# Yetkazib beruvchi — pul hisobi shu daraja bo'yicha
# ---------------------------------------------------------------------------
class TaminotSupplierCreate(BaseModel):
    scope: str  # "ichki" / "tashqi"
    name: str
    phone: Optional[str] = None
    note: Optional[str] = None


class TaminotSupplierUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    note: Optional[str] = None


class SupplierCurrencyTotal(BaseModel):
    """Bitta yetkazib beruvchining bitta valyutadagi hisobi.

    UZS va USD hech qachon qo'shilmaydi — har biri alohida qator.
    """
    currency: str
    total_purchased: float = 0
    total_paid: float = 0
    balance: float = 0
    stock_value: float = 0


class TaminotSupplierOut(ORMBase):
    id: uuid.UUID
    scope: str
    name: str
    phone: Optional[str] = None
    note: Optional[str] = None
    created_at: datetime
    # Hisoblangan qiymatlar
    product_count: int = 0
    totals: list[SupplierCurrencyTotal] = []
    last_purchase_at: Optional[datetime] = None
    # Ombor holati — shu yetkazib beruvchining mahsulotlari bo'yicha
    low_stock_count: int = 0
    out_of_stock_count: int = 0


# ---------------------------------------------------------------------------
# Mahsulot
# ---------------------------------------------------------------------------
class TaminotProductCreate(BaseModel):
    scope: str  # "ichki" / "tashqi"
    supplier_id: uuid.UUID
    name: str
    unit: str = "dona"
    unit_price: float = 0
    currency: str = "UZS"
    min_qty: float = Field(0, ge=0, description="Kam qoldi chegarasi (0 — chegara yo'q)")
    note: Optional[str] = None


class TaminotProductUpdate(BaseModel):
    # Mahsulotni boshqa yetkazib beruvchiga ko'chirish mumkin — bunda uning
    # butun tarixi (kirimlari) ham yangi joyning hisobiga o'tadi.
    supplier_id: Optional[uuid.UUID] = None
    name: Optional[str] = None
    unit: Optional[str] = None
    unit_price: Optional[float] = None
    currency: Optional[str] = None
    min_qty: Optional[float] = Field(None, ge=0)
    note: Optional[str] = None


class TaminotProductOut(ORMBase):
    id: uuid.UUID
    scope: str
    supplier_id: uuid.UUID
    supplier_name: Optional[str] = None
    name: str
    unit: str
    unit_price: float
    currency: str = "UZS"
    min_qty: float = 0
    note: Optional[str] = None
    created_at: datetime
    # Hisoblangan pul qiymatlari. DIQQAT: qarz mahsulot darajasida yuritilmaydi —
    # to'lovlar yetkazib beruvchiga qilinadi, shuning uchun bu yerda faqat shu
    # mahsulotdan qancha olib kelinganini ko'rsatuvchi summa bor.
    total_purchased: float = 0
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
    """Olib kelish. qty (+ ixtiyoriy unit_price) → summa = qty × narx.

    `payment_mode`:
      - "debt" (sukut) — qarzga olib kelindi, qarz qoldig'i oshadi
      - "cash"         — naqdga olib kelindi: shu zahoti to'liq summaga
                         to'lov yoziladi, qarz qoldig'i o'zgarmaydi
    Ombor qoldig'i ikkala holatda ham bir xil oshadi.
    """
    qty: float = Field(gt=0)
    unit_price: Optional[float] = None  # bo'lmasa mahsulot narxi olinadi
    payment_mode: Literal["debt", "cash"] = "debt"
    note: Optional[str] = None


class SupplierPurchaseItemIn(BaseModel):
    """Kirim hujjatidagi bitta qator."""
    product_id: uuid.UUID
    qty: float = Field(gt=0)
    unit_price: Optional[float] = None  # bo'lmasa mahsulot narxi olinadi


class SupplierPurchaseCreate(BaseModel):
    """Yetkazib beruvchidan KIRIM HUJJATI — bir yo'la bir necha mahsulot.

    Bitta joydan 15 xil mahsulot olib kelinsa, hammasi bitta hujjat bilan
    kiritiladi: har qator uchun `purchase` yoziladi, summalari esa o'sha
    yetkazib beruvchining umumiy qarziga qo'shiladi.

    `payment_mode` — `PurchaseCreate` bilan bir xil ("debt" / "cash").
    """
    items: list[SupplierPurchaseItemIn]
    payment_mode: Literal["debt", "cash"] = "debt"
    note: Optional[str] = None


class PaymentCreate(BaseModel):
    """Yetkazib beruvchiga qarz to'lash — uning qarz qoldig'ini kamaytiradi.

    Valyuta majburiy ko'rsatiladi: bitta joyda ham UZS, ham USD hisobi bo'lishi
    mumkin va ular hech qachon aralashtirilmaydi.
    """
    amount: float = Field(gt=0)
    currency: str = "UZS"
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
    supplier_id: uuid.UUID
    # To'lovda bo'sh — u yetkazib beruvchiga qilinadi, mahsulotga emas
    product_id: Optional[uuid.UUID] = None
    kind: str
    qty: float
    unit_price: float
    amount: float
    currency: str = "UZS"
    note: Optional[str] = None
    created_at: datetime
    # To'ldirilgan bo'lsa — yozuv ARXIVDA: hisobga qo'shilmaydi, lekin tarixda
    # ustidan chizilgan holda ko'rinadi
    deleted_at: Optional[datetime] = None


class TaminotTxLogOut(BaseModel):
    """Hisobotlar uchun — mahsulot va yetkazib beruvchi nomi bilan to'liq jurnal."""
    id: uuid.UUID
    supplier_id: uuid.UUID
    supplier_name: Optional[str] = None
    # Yetkazib beruvchiga qilingan umumiy to'lovda mahsulot bo'lmaydi
    product_id: Optional[uuid.UUID] = None
    product_name: Optional[str] = None
    unit: str = "dona"
    kind: str
    qty: float
    unit_price: float
    amount: float
    currency: str = "UZS"
    note: Optional[str] = None
    created_at: datetime
    # Arxivga o'tgan yozuv — hisobga qo'shilmaydi, ro'yxatda chizib ko'rsatiladi
    deleted_at: Optional[datetime] = None


# ---------------------------------------------------------------------------
# Umumiy hisob (card uchun) — har valyuta alohida
# ---------------------------------------------------------------------------
class CurrencyTotal(BaseModel):
    currency: str
    total_purchased: float = 0
    total_paid: float = 0
    total_balance: float = 0
    # Shu valyutada qarzi qolgan YETKAZIB BERUVCHILAR soni
    with_debt_count: int = 0
    # Shu valyutadagi mahsulotlar ombor qoldig'ining qiymati
    stock_value: float = 0


class TaminotSummary(BaseModel):
    by_currency: list[CurrencyTotal] = []
    product_count: int = 0
    supplier_count: int = 0
    # Qarzi bor yetkazib beruvchilar soni (valyutadan qat'i nazar)
    supplier_with_debt_count: int = 0
    # Ombor holati
    low_stock_count: int = 0     # kam qolganlar (chegaradan past, lekin bor)
    out_of_stock_count: int = 0  # tugaganlar
    ok_stock_count: int = 0      # yetarli
    tracked_count: int = 0       # harakati bo'lgan (qoldig'i hisoblanadigan) mahsulotlar


# ---------------------------------------------------------------------------
# Xarid spiskasi (draft ro'yxat)
# ---------------------------------------------------------------------------
class PurchaseListItemIn(BaseModel):
    product_id: uuid.UUID
    qty: Decimal


class PurchaseListItemOut(BaseModel):
    id: uuid.UUID
    product_id: uuid.UUID
    product_name: str
    unit: str
    qty: Decimal
    unit_price: Decimal
    currency: str
    amount: Decimal          # qty * unit_price

    model_config = {"from_attributes": True}


class PurchaseListCreate(BaseModel):
    scope: str
    # Spiska bitta yetkazib beruvchiga tegishli — faqat uning mahsulotlari kiradi
    supplier_id: uuid.UUID
    title: Optional[str] = None
    note: Optional[str] = None
    items: list[PurchaseListItemIn]


class PurchaseListUpdate(BaseModel):
    title: Optional[str] = None
    note: Optional[str] = None
    items: Optional[list[PurchaseListItemIn]] = None


class PurchaseListApplyIn(BaseModel):
    """Spiskani qabul qilish. `payment_mode` — `PurchaseCreate` bilan bir xil:
      - "debt" (sukut) — qarzga olindi, qarz qoldig'i oshadi
      - "cash"         — naqd to'landi: har mahsulotga to'liq summaga to'lov
                         yoziladi, qarz qoldig'i o'zgarmaydi
    Ombor qoldig'i ikkala holatda ham bir xil oshadi.
    """
    payment_mode: Literal["debt", "cash"] = "debt"


class PurchaseListTotal(BaseModel):
    """Valyuta bo'yicha jami — UZS va USD hech qachon qo'shilmaydi."""
    currency: str
    amount: Decimal


class PurchaseListOut(BaseModel):
    id: uuid.UUID
    scope: str
    supplier_id: uuid.UUID
    supplier_name: Optional[str] = None
    title: Optional[str] = None
    status: str
    note: Optional[str] = None
    applied_at: Optional[datetime] = None
    created_at: datetime
    items: list[PurchaseListItemOut] = []
    totals: list[PurchaseListTotal] = []
    item_count: int = 0

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# «Bizning qarzlar» bo'limi uchun — FAQAT KO'RISH
# ---------------------------------------------------------------------------
class TaminotDebtView(BaseModel):
    """Ta'minot qarzining qisqacha ko'rinishi.

    «Bizning qarzlar» bo'limida ta'minot bo'yicha umumiy manzarani ko'rsatish
    uchun ishlatiladi. Hech qanday amal (to'lov, tahrir) bu yerdan bajarilmaydi —
    barchasi Ta'minot bo'limida qoladi.
    """
    supplier_id: uuid.UUID
    scope: str
    name: str
    phone: Optional[str] = None
    product_count: int = 0
    totals: list[SupplierCurrencyTotal] = []
    last_purchase_at: Optional[datetime] = None
