"""Operatsion (namunaviy + qo'lda kiritilgan) ma'lumotlarni bazadan tozalash.

TO'LIQ TOZALASH rejimi — toza slate:
  O'CHIRILADI (barcha yozuvlar):
    - Sotuv: buyurtma, buyurtma item, to'lov
    - Servis: ariza (ticket) va tashrif (visit)
    - Mijozlar
    - HR: xodim, davomat, stavka tarixi, avans, oylik (payroll)
    - Ta'minot: vendor, item, kirim (goods_receipt), to'lov, stok harakati
    - Foydalanuvchilar: super-admin'dan tashqari barcha login (taminotchi + xodim akkauntlari)

  SAQLANADI (o'chmaydi):
    - Mahsulot katalogi (products_main / products_additional)
    - Tizim konfig: rollar, super-admin, hisobvaraqlar, moliya/servis toifalari,
      lavozimlar, bo'limlar
    - Moliya tranzaksiyalari (ledger) — ularga tegilmaydi

Foydalanish (Docker ichida):
  # Avval nima o'chishini KO'RISH (hech narsa o'chmaydi):
  docker compose exec backend python -m scripts.clean_sample_data

  # Haqiqatan o'chirish:
  docker compose exec backend python -m scripts.clean_sample_data --yes

Hammasi bitta tranzaksiyada — xato bo'lsa to'liq rollback (hech narsa o'chmaydi).
"""
import asyncio
import sys

from sqlalchemy import text

from app.db.session import engine

# FK-xavfsiz o'chirish tartibi: bola jadvallar avval, ota jadvallar keyin.
# (label, DELETE SQL). Har biri "barcha yozuv" — operatsion slate tozalanadi.
DELETE_STEPS = [
    # --- Servis (ticket -> orders/customers RESTRICT) ---
    ("service_visits", "DELETE FROM service_visits"),
    ("service_tickets", "DELETE FROM service_tickets"),
    # --- Sotuv (order_items/payments orders'ga CASCADE, lekin aniq o'chiramiz) ---
    ("payments", "DELETE FROM payments"),
    ("order_items", "DELETE FROM order_items"),
    ("orders", "DELETE FROM orders"),
    # --- Ta'minot ---
    ("stock_movements", "DELETE FROM stock_movements"),
    ("goods_receipts", "DELETE FROM goods_receipts"),
    ("vendor_payments", "DELETE FROM vendor_payments"),
    ("items", "DELETE FROM items"),
    ("vendors", "DELETE FROM vendors"),
    # --- HR ---
    ("payroll_items", "DELETE FROM payroll_items"),
    ("payroll_runs", "DELETE FROM payroll_runs"),
    ("attendance", "DELETE FROM attendance"),
    ("salary_rates", "DELETE FROM salary_rates"),
    ("salary_advances", "DELETE FROM salary_advances"),
    ("employees", "DELETE FROM employees"),
    # --- Mijozlar (buyurtma/ticket o'chgach RESTRICT bloklamaydi) ---
    ("customers", "DELETE FROM customers"),
    # --- Login akkauntlar: super-admin'dan tashqari hammasi ---
    ("users (non-admin)", "DELETE FROM users WHERE is_superadmin = false"),
]


async def _count(conn, table_sql: str) -> int:
    # "DELETE FROM x [WHERE ...]" -> "SELECT count(*) FROM x [WHERE ...]"
    cnt_sql = "SELECT count(*) FROM " + table_sql.split("FROM", 1)[1]
    res = await conn.execute(text(cnt_sql))
    return int(res.scalar() or 0)


async def main(apply: bool) -> None:
    mode = "O'CHIRISH (--yes)" if apply else "KO'RISH (dry-run)"
    print(f"=== Operatsion ma'lumotlarni to'liq tozalash — rejim: {mode} ===")
    print(f"DB: {engine.url}")
    print("-" * 60)

    async with engine.begin() as conn:
        # Preview — har jadvalda nechta yozuv o'chadi
        total = 0
        for label, sql in DELETE_STEPS:
            n = await _count(conn, sql)
            total += n
            print(f"  {label:24} {n:>6}")
        print("-" * 60)
        print(f"  {'JAMI':24} {total:>6}")
        print("-" * 60)

        if not apply:
            print("Dry-run — hech narsa o'chirilmadi.")
            print("Haqiqatan o'chirish: ... python -m scripts.clean_sample_data --yes")
            return

        # O'chirish (FK-xavfsiz tartibda, bitta tranzaksiya)
        for label, sql in DELETE_STEPS:
            await conn.execute(text(sql))

    print("[OK] Operatsion ma'lumotlar o'chirildi. "
          "Katalog, konfig, super-admin va moliya ledger saqlandi.")


if __name__ == "__main__":
    apply = "--yes" in sys.argv or "-y" in sys.argv
    asyncio.run(main(apply))
