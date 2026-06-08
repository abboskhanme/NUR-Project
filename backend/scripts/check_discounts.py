"""Bazadagi me'yordan ortiq chegirmalarni topish.

Chegirma ($) mahsulot summasidan (narx $ * soni) oshgan yoki manfiy bo'lgan
buyurtma qatorlarini ro'yxatlab beradi.

Ishga tushirish (backend papkasidan):
    python -m scripts.check_discounts

Docker ichida bo'lsa:
    docker compose exec backend python -m scripts.check_discounts
"""
import asyncio

from sqlalchemy import select

from app.db.session import AsyncSessionLocal
from app.models.order import Order, OrderItem


async def main() -> None:
    async with AsyncSessionLocal() as db:
        res = await db.execute(
            select(OrderItem, Order.code, Order.status)
            .join(Order, Order.id == OrderItem.order_id)
            .where(
                (OrderItem.discount_usd < 0)
                | (OrderItem.discount_usd > OrderItem.unit_price_usd * OrderItem.quantity)
            )
            .order_by(Order.code)
        )
        rows = res.all()

    if not rows:
        print("Hammasi joyida — me'yordan ortiq chegirma topilmadi.")
        return

    print(f"DIQQAT: {len(rows)} ta qatorda chegirma me'yordan ortiq:\n")
    print(f"{'Buyurtma':<12} {'Status':<10} {'Narx ($)':>12} {'Soni':>5} {'Summa ($)':>12} {'Chegirma ($)':>14} {'Farq ($)':>12}")
    print("-" * 84)
    for item, code, status in rows:
        subtotal = (item.unit_price_usd or 0) * (item.quantity or 1)
        diff = (item.discount_usd or 0) - subtotal
        print(
            f"{code:<12} {status:<10} {float(item.unit_price_usd or 0):>12,.2f} "
            f"{item.quantity:>5} {float(subtotal):>12,.2f} "
            f"{float(item.discount_usd or 0):>14,.2f} {float(diff):>+12,.2f}"
        )
    print(
        "\nTuzatish: buyurtmani ochib chegirmani to'g'rilang yoki SQL bilan:\n"
        "  UPDATE order_items SET discount_usd = unit_price_usd * quantity,\n"
        "         discount = unit_price_uzs * quantity, total_uzs = 0\n"
        "  WHERE discount_usd > unit_price_usd * quantity;  -- (chegirmani summa darajasiga tushiradi)"
    )


if __name__ == "__main__":
    asyncio.run(main())
