"""Tannarx bo'limiga NAMUNAVIY (demo) kalkulyatsiya qo'shish — foyda hisobotini
ko'rish/sinash uchun. Faqat DEV/DEMO uchun, prod bazaga ishlatmang.

Nima qiladi:
  - Tannarx katalogiga bir nechta namunaviy material qo'shadi (metall, nasos,
    gorelka, kraska, ...). Nomi bir xil material allaqachon bo'lsa — qayta
    yaratmaydi, borini ishlatadi.
  - Kalkulyatsiyasi YO'Q har bir faol asosiy mahsulotga tarkib yozadi: material
    miqdorlari kvm ga qarab, model bo'yicha murakkablik koeffitsienti bilan
    (shuning uchun marjalar har xil chiqadi — grafiklarda farq ko'rinadi).
  - MAVJUD kalkulyatsiyalarga TEGMAYDI.

Ishga tushirish (Docker):
    docker compose exec backend python -m scripts.seed_costing_demo

Tozalash (faqat shu skript qo'shganini o'chiradi):
    docker compose exec backend python -m scripts.seed_costing_demo --clear

Demo yozuvlar `note` maydonidagi "[demo]" belgisi bilan topiladi — qo'lda
kiritilgan haqiqiy ma'lumot hech qachon o'chmaydi.
"""
import asyncio
import sys
from decimal import Decimal

from sqlalchemy import delete, func, select

from app.db.session import AsyncSessionLocal
from app.models.costing import CostingMaterial, ProductRecipe, ProductRecipeItem
from app.models.product import Product
from app.services.finance_service import latest_exchange_rate

MARK = "[demo]"
NOTE = f"{MARK} namunaviy kalkulyatsiya — scripts/seed_costing_demo.py"

# (nom, birlik, narx, valyuta)
MATERIALS = [
    ("Metall list 2mm", "list", 420_000, "UZS"),
    ("Payvand simi", "kg", 38_000, "UZS"),
    ("Issiqlik izolyatsiyasi", "metr", 55_000, "UZS"),
    ("Sirkulyatsion nasos", "dona", 85, "USD"),
    ("Termostat datchigi", "dona", 25, "USD"),
    ("Gorelka bloki", "dona", 180, "USD"),
    ("Elektr kabel / avtomatika", "metr", 22_000, "UZS"),
    ("Kraska va gruntovka", None, 0, "UZS"),   # summa bilan kiritiladi
]

# Model bo'yicha murakkablik: metall sarfi va ish haqiga ta'sir qiladi
FACTORS = {"PREMIUM 4": 1.30, "ULTRA": 1.15, "PREMIUM 3": 1.05, "OPTIMA": 1.0, "MAGNUM": 0.95}
OVERHEADS = [8, 10, 7, 12, 9]  # ustama % — mahsulotlar bo'yicha aylanadi


def D(v) -> Decimal:
    return Decimal(str(v))


async def _clear() -> None:
    async with AsyncSessionLocal() as db:
        recipes = (await db.execute(
            select(ProductRecipe).where(ProductRecipe.note.like(f"{MARK}%"))
        )).scalars().all()
        for r in recipes:
            await db.delete(r)          # satrlar cascade bilan o'chadi
        await db.flush()

        # Demo materiallar — faqat hech qayerda ishlatilmayotganlari
        mats = (await db.execute(
            select(CostingMaterial).where(CostingMaterial.note.like(f"{MARK}%"))
        )).scalars().all()
        removed = 0
        for m in mats:
            used = (await db.execute(
                select(func.count()).select_from(ProductRecipeItem)
                .where(ProductRecipeItem.material_id == m.id)
            )).scalar() or 0
            if used == 0:
                await db.delete(m)
                removed += 1
        await db.commit()
        print(f"O'chirildi: {len(recipes)} ta demo kalkulyatsiya, {removed} ta demo material.")


async def _materials(db) -> dict[str, CostingMaterial]:
    """Katalogni tayyorlaydi — bori ishlatiladi, yo'g'i demo sifatida qo'shiladi."""
    out: dict[str, CostingMaterial] = {}
    for name, unit, price, currency in MATERIALS:
        existing = (await db.execute(
            select(CostingMaterial).where(func.lower(CostingMaterial.name) == name.lower())
        )).scalar_one_or_none()
        if existing is not None:
            out[name] = existing
            continue
        m = CostingMaterial(
            name=name, unit=unit, unit_price=D(price), currency=currency,
            entry_mode="sum" if unit is None else "qty",
            note=f"{MARK} namunaviy material", is_active=True,
        )
        db.add(m)
        await db.flush()
        out[name] = m
    return out


def _items(recipe_id, mats: dict[str, CostingMaterial], kvm: int, factor: float):
    """Mahsulot o'lchamiga (kvm) qarab tarkib satrlarini yasaydi."""
    def mat(name, qty):
        m = mats[name]
        return ProductRecipeItem(
            recipe_id=recipe_id, kind="material", material_id=m.id, label=m.name,
            entry_mode="qty", qty=D(round(qty, 2)), unit=m.unit,
            unit_price=None,                     # narx katalogdan JONLI olinadi
            currency=m.currency or "UZS",
        )

    rows = [
        mat("Metall list 2mm", max(4, round(kvm / 25 * factor))),
        mat("Payvand simi", max(3, round(kvm / 40))),
        mat("Issiqlik izolyatsiyasi", max(5, round(kvm / 20))),
        mat("Sirkulyatsion nasos", 1),
        mat("Termostat datchigi", 2),
        mat("Gorelka bloki", 1),
        mat("Elektr kabel / avtomatika", max(10, round(kvm / 10))),
    ]
    kraska = mats["Kraska va gruntovka"]
    rows.append(ProductRecipeItem(
        recipe_id=recipe_id, kind="material", material_id=kraska.id, label=kraska.name,
        entry_mode="sum", qty=D(1), amount=D(350_000 + kvm * 500), currency="UZS",
    ))
    rows.append(ProductRecipeItem(
        recipe_id=recipe_id, kind="expense", label="Ish haqi (payvand va yig'ish)",
        entry_mode="sum", qty=D(1), amount=D(round((900_000 + kvm * 3_000) * factor, -3)),
        currency="UZS",
    ))
    rows.append(ProductRecipeItem(
        recipe_id=recipe_id, kind="expense", label="Sinov va sozlash",
        entry_mode="sum", qty=D(1), amount=D(250_000), currency="UZS",
    ))
    for i, row in enumerate(rows):
        row.sort_order = i
    return rows


async def main(clear: bool = False) -> None:
    if clear:
        await _clear()
        return

    async with AsyncSessionLocal() as db:
        rate = D(await latest_exchange_rate(db) or 0)
        if rate <= 0:
            print("DIQQAT: USD kursi kiritilmagan — dollarli satrlar 0 bo'lib qoladi. "
                  "Moliya bo'limida kurs kiriting.")

        products = (await db.execute(
            select(Product)
            .where(Product.status == "active", Product.product_type == "main")
            .order_by(Product.model, Product.kvm)
        )).scalars().all()
        if not products:
            print("Faol asosiy mahsulot topilmadi — avval mahsulot qo'shing.")
            return

        have = {r.product_id for r in (await db.execute(select(ProductRecipe))).scalars().all()}
        mats = await _materials(db)

        created = 0
        report: list[tuple[str, Decimal, Decimal]] = []
        for idx, p in enumerate(products):
            if p.id in have:
                print(f"  o'tkazildi (kalkulyatsiyasi bor): {p.display_name}")
                continue
            factor = FACTORS.get((p.model or "").upper(), 1.0)
            overhead = OVERHEADS[idx % len(OVERHEADS)]
            recipe = ProductRecipe(
                product_id=p.id, overhead_percent=D(overhead),
                target_price_usd=None,           # sotish narxi mahsulotdan olinadi
                note=NOTE,
            )
            db.add(recipe)
            await db.flush()
            rows = _items(recipe.id, mats, int(p.kvm or 200), factor)
            db.add_all(rows)
            created += 1

            # Ko'z bilan tekshirish uchun taxminiy hisob (API bilan bir xil mantiq)
            total = Decimal(0)
            for r in rows:
                if r.entry_mode == "sum":
                    line = D(r.amount)
                else:
                    m = next(x for x in mats.values() if x.id == r.material_id)
                    line = D(r.qty) * D(m.unit_price)
                    if (m.currency or "UZS") == "USD":
                        line *= rate
                total += line
            cost = total * (1 + D(overhead) / 100)
            price = D(p.base_price_usd or 0) * rate
            report.append((p.display_name, cost, price))

        await db.commit()

    print(f"\nQo'shildi: {created} ta namunaviy kalkulyatsiya (kurs {rate:,.0f} so'm).\n")
    print(f"{'Mahsulot':<24}{'Tannarx':>16}{'Sotish':>16}{'Marja':>9}")
    for name, cost, price in report:
        margin = (price - cost) / price * 100 if price > 0 else Decimal(0)
        print(f"{name:<24}{cost:>16,.0f}{price:>16,.0f}{margin:>8.1f}%")
    print("\nEndi: Hisobotlar → «Tannarx / Foyda» tabini oching.")
    print("Tozalash: python -m scripts.seed_costing_demo --clear")


if __name__ == "__main__":
    asyncio.run(main(clear="--clear" in sys.argv or "--reset" in sys.argv))
