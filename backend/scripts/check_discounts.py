"""Bazadagi me'yordan ortiq chegirmalarni topish.

Chegirma mahsulot summasidan (narx * soni) oshgan yoki manfiy bo'lgan
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
                (OrderItem.discount < 0)
                | (OrderItem.discount > OrderItem.unit_price_uzs * OrderItem.quantity)
            )
            .order_by(Order.code)
        )
        rows = res.all()

    if not rows:
        print("Hammasi joyida — me'yordan ortiq chegirma topilmadi.")
        return

    print(f"DIQQAT: {len(rows)} ta qatorda chegirma me'yordan ortiq:\n")
    print(f"{'Buyurtma':<12} {'Status':<10} {'Narx (UZS)':>14} {'Soni':>5} {'Summa':>14} {'Chegirma':>14} {'Farq':>14}")
    print("-" * 90)
    for item, code, status in rows:
        subtotal = (item.unit_price_uzs or 0) * (item.quantity or 1)
        diff = (item.discount or 0) - subtotal
        print(
            f"{code:<12} {status:<10} {float(item.unit_price_uzs or 0):>14,.0f} "
            f"{item.quantity:>5} {float(subtotal):>14,.0f} "
            f"{float(item.discount or 0):>14,.0f} {float(diff):>+14,.0f}"
        )
    print(
        "\nTuzatish: buyurtmani ochib chegirmani to'g'rilang yoki SQL bilan:\n"
        "  UPDATE order_items SET discount = unit_price_uzs * quantity,\n"
        "         total_uzs = 0\n"
        "  WHERE discount > unit_price_uzs * quantity;  -- (chegirmani summa darajasiga tushiradi)"
    )


if __name__ == "__main__":
    asyncio.run(main())
