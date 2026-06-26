"""Telegram bot uchun bazaviy operatsiyalar (mavjud modellardan foydalanadi).

Bu yerda hech qanday mavjud servis/endpoint o'zgartirilmaydi — faqat mavjud
ORM modellariga to'g'ridan-to'g'ri yoziladi (manba: telegram_bot).
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import AsyncSessionLocal
from app.models.customer import Customer
from app.models.finance import ExchangeRate
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.services.order_service import generate_order_code

from .common import normalize_phone, today


@dataclass
class OrderDraft:
    """Mijoz suhbatda kiritgan ma'lumotlar."""
    name: str
    phone: str
    region: str
    model: str
    kvm: int
    direction: str          # "right" / "left"
    price_usd: Decimal
    note: str | None = None


@dataclass
class CreatedOrder:
    code: str
    customer_name: str
    phone: str
    model: str
    kvm: int
    price_usd: Decimal
    total_uzs: Decimal


def _norm_phone_sql(col):
    """SQL tomonda telefon raqamini normallashtirish (probel/-/+ olib tashlash)."""
    expr = func.replace(col, " ", "")
    expr = func.replace(expr, "-", "")
    expr = func.replace(expr, "+", "")
    expr = func.replace(expr, "(", "")
    expr = func.replace(expr, ")", "")
    return expr


async def _find_or_create_customer(db: AsyncSession, draft: OrderDraft) -> Customer:
    """Telefon raqami bo'yicha mijozni topadi, bo'lmasa yangisini yaratadi."""
    norm = normalize_phone(draft.phone)
    if norm:
        stmt = select(Customer).where(_norm_phone_sql(Customer.phone) == norm).limit(1)
        cust = (await db.execute(stmt)).scalar_one_or_none()
        if cust is not None:
            return cust
    cust = Customer(
        full_name=draft.name.strip() or "Telegram mijoz",
        phone=draft.phone.strip(),
        region=draft.region.strip() or None,
        source="telegram_bot",
    )
    db.add(cust)
    await db.flush()
    return cust


async def _resolve_or_create_product(db: AsyncSession, model: str, kvm: int) -> Product:
    """Model + kvm bo'yicha asosiy mahsulotni topadi, bo'lmasa yaratadi.

    OrderItem.product_id majburiy (RESTRICT FK) bo'lgani uchun mahsulot
    albatta mavjud bo'lishi shart. Katalogda topilmasa, shu model/kvm uchun
    yangi 'main' mahsulot yaratiladi (narxsiz — narx buyurtmada saqlanadi).
    """
    stmt = (
        select(Product)
        .where(
            Product.product_type == "main",
            Product.model == model,
            Product.kvm == kvm,
            Product.status == "active",
        )
        .limit(1)
    )
    prod = (await db.execute(stmt)).scalar_one_or_none()
    if prod is not None:
        return prod
    prod = Product(
        product_type="main",
        model=model,
        kvm=kvm,
        status="active",
        base_price_usd=Decimal(0),
    )
    db.add(prod)
    await db.flush()
    return prod


async def _latest_usd_rate(db: AsyncSession) -> Decimal:
    """Eng so'nggi USD->UZS kursi (yo'q bo'lsa 0)."""
    stmt = select(ExchangeRate.usd_to_uzs).order_by(ExchangeRate.date.desc()).limit(1)
    rate = (await db.execute(stmt)).scalar_one_or_none()
    return Decimal(rate) if rate else Decimal(0)


async def create_order_from_draft(draft: OrderDraft) -> CreatedOrder:
    """Suhbatdan kelgan ma'lumot asosida real buyurtma yaratadi.

    Mavjud `create_order` endpoint mantig'iga mos: kod generatsiyasi, mijozni
    bog'lash, OrderItem UZS jami hisoblash. salesperson_id=None (bot buyurtmasi),
    source='telegram_bot', status='new'.
    """
    async with AsyncSessionLocal() as db:
        cust = await _find_or_create_customer(db, draft)
        product = await _resolve_or_create_product(db, draft.model, draft.kvm)
        rate = await _latest_usd_rate(db)
        code = await generate_order_code(db)

        unit_price_usd = draft.price_usd or Decimal(0)
        unit_price_uzs = (unit_price_usd * rate) if rate else Decimal(0)
        total_uzs = unit_price_uzs  # quantity=1, chegirmasiz

        order = Order(
            code=code,
            customer_id=cust.id,
            salesperson_id=None,
            source="telegram_bot",
            status="new",
            order_date=today(),
            exchange_rate=rate,
            bunker_direction=draft.direction,
            delivery_address=(draft.region.strip() or None),
            note=draft.note,
        )
        order.items.append(
            OrderItem(
                product_id=product.id,
                quantity=1,
                unit_price_usd=unit_price_usd,
                unit_price_uzs=unit_price_uzs,
                bunker_direction=draft.direction,
                discount_usd=Decimal(0),
                discount=Decimal(0),
                total_uzs=total_uzs,
            )
        )
        db.add(order)
        await db.commit()

        return CreatedOrder(
            code=code,
            customer_name=cust.full_name,
            phone=cust.phone,
            model=draft.model,
            kvm=draft.kvm,
            price_usd=unit_price_usd,
            total_uzs=total_uzs,
        )
