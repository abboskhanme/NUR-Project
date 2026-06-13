"""Buyurtmalarni xavfsiz o'chirish (test ma'lumotlarini tozalash uchun).

Nega oddiy `DELETE FROM orders` YETARLI EMAS:
  - har bir to'lov moliyada `income` tranzaksiya yaratadi va hisobvaraq
    (account.balance) running-balansini oshiradi. Buyurtmani DB cascade bilan
    o'chirsak, order_items va payments o'chadi, LEKIN finance_transactions
    orphan bo'lib qoladi va balans/hisobotlar shishib qoladi.
  - buyurtma SKLAD KATYOL birligini "reserved"/"sold" ga o'tkazadi.

Shu skript har bir buyurtma uchun:
  1) income finance tranzaksiyalarini teskari qo'llaydi (balansni tiklaydi) va o'chiradi,
  2) bog'langan inventory birligini "available" ga qaytaradi,
  3) buyurtmani o'chiradi (cascade order_items + payments ni oladi).

ISHLATISH (prod konteyner ichida):
    # 1) Avval KO'RISH (hech narsa o'chmaydi — dry-run):
    docker compose -f docker-compose.prod.yml exec backend \
        python -m scripts.delete_order "Ayubxon test uchun"

    # 2) Tasdiqlab o'chirish:
    docker compose -f docker-compose.prod.yml exec backend \
        python -m scripts.delete_order "Ayubxon test uchun" --confirm

Selektorlar (bir nechta berish mumkin) quyidagilarga mos keladi:
  - buyurtma kodi (aniq, katta-kichik harf farqsiz), yoki
  - mijoz ismi (qism, ilike), yoki
  - mijoz telefoni (qism).
"""
import asyncio
import sys
from decimal import Decimal

from sqlalchemy import func, or_, select
from sqlalchemy.orm import selectinload

from app.db.session import AsyncSessionLocal
from app.models.customer import Customer
from app.models.finance import FinanceTransaction
from app.models.order import Order
from app.services.finance_service import apply_transaction


async def find_orders(db, selectors):
    """Selektorlarga mos buyurtmalarni topadi (takrorsiz)."""
    found: dict = {}
    for sel in selectors:
        like = f"%{sel}%"
        stmt = (
            select(Order)
            .join(Customer, Customer.id == Order.customer_id)
            .where(
                or_(
                    func.lower(Order.code) == sel.lower(),
                    Customer.full_name.ilike(like),
                    Customer.phone.ilike(like),
                    Customer.phone2.ilike(like),
                )
            )
            .options(
                selectinload(Order.items),
                selectinload(Order.payments),
                selectinload(Order.customer),
            )
        )
        for o in (await db.execute(stmt)).scalars().all():
            found[o.id] = o
    return list(found.values())


async def main():
    args = [a for a in sys.argv[1:]]
    confirm = "--confirm" in args
    selectors = [a for a in args if not a.startswith("--")]

    if not selectors:
        print("Selektor bering. Masalan:\n"
              '  python -m scripts.delete_order "Ayubxon test uchun"')
        return

    async with AsyncSessionLocal() as db:
        orders = await find_orders(db, selectors)
        if not orders:
            print("Mos buyurtma topilmadi.")
            return

        print(f"\n{'O' if confirm else 'KO'}'CHIRISH — {len(orders)} ta buyurtma topildi:\n")
        for o in orders:
            txs = (await db.execute(select(FinanceTransaction).where(
                FinanceTransaction.related_order_id == o.id,
                FinanceTransaction.type == "income",
            ))).scalars().all()
            tx_sum = sum((t.amount or Decimal(0) for t in txs), Decimal(0))
            cust = o.customer.full_name if o.customer else "?"
            phone = o.customer.phone if o.customer else "?"
            print(f"  • {o.code}  {o.order_date}  {cust} ({phone})  status={o.status}")
            print(f"      items={len(o.items)}  payments={len(o.payments)}  "
                  f"income_tx={len(txs)} (∑ {tx_sum})  inventory={o.inventory_id}")

        if not confirm:
            print("\n[DRY-RUN] Hech narsa o'chmadi. Tasdiqlash uchun --confirm qo'shing.")
            return

        # --- Haqiqiy o'chirish ---
        from app.api.v1.orders import _set_inventory_status

        for o in orders:
            txs = (await db.execute(select(FinanceTransaction).where(
                FinanceTransaction.related_order_id == o.id,
            ))).scalars().all()
            for tx in txs:
                # income/expense balansga ta'sir qilganini teskari qaytaramiz
                if tx.type in ("income", "expense"):
                    await apply_transaction(db, tx, reverse=True)
                await db.delete(tx)

            if o.inventory_id:
                await _set_inventory_status(db, o.inventory_id, "available")
                o.inventory_id = None

            await db.delete(o)  # cascade: order_items + payments

        await db.commit()
        print(f"\n✓ {len(orders)} ta buyurtma o'chirildi, balans va inventar tiklandi.")


if __name__ == "__main__":
    asyncio.run(main())
