"""Namunaviy (demo) ma'lumotlar — barcha bo'limlarni test qilish uchun.

Ishlatish (Docker ichida):
    docker compose exec backend python -m scripts.seed_demo

Mahsulot/mijoz/xodimlar scripts/sample_data.json dan olinadi; qolgan bo'limlar
(orders, finance, supply, service, HR davomat) shu skriptda yaratiladi.
Yangi xususiyatlarni ham qamraydi:
  - to'lanmagan buyurtmalar  -> Qarzdorlik hisoboti
  - zaxirasi kam mahsulotlar -> Buyurtma tavsiyalari
  - rejalashtirilgan servis  -> Kalendar ko'rinishi

Idempotent: agar buyurtmalar allaqachon bo'lsa — to'xtaydi (takror seeddan saqlanish).
"""
import asyncio
import json
import os
import random
from datetime import date, datetime, time, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select

from app.db.session import AsyncSessionLocal
from app.models.customer import Customer
from app.models.finance import Account, ExchangeRate, FinanceCategory, FinanceTransaction
from app.models.hr import Attendance, Department, Employee, Position
from app.models.order import Order, OrderItem, Payment
from app.models.product import Inventory, Product
from app.models.service import ServiceCategory, ServiceTicket, ServiceVisit
from app.models.supply import GoodsReceipt, Item, Vendor

RATE = Decimal("12650")
TODAY = date.today()
HERE = os.path.dirname(__file__)


def D(v) -> Decimal:
    return Decimal(str(v))


def dt(d: date, hh: int = 10, mm: int = 0) -> datetime:
    return datetime.combine(d, time(hh, mm), tzinfo=timezone.utc)


async def main() -> None:
    random.seed(42)
    data = json.load(open(os.path.join(HERE, "sample_data.json"), encoding="utf-8"))

    async with AsyncSessionLocal() as db:
        existing = (await db.execute(select(func.count(Order.id)))).scalar() or 0
        if existing:
            print(f"[skip] {existing} ta buyurtma allaqachon bor — avval tozalang "
                  f"(python -m scripts.clean_sample_data --yes)")
            return

        # ---------------- Mahsulotlar ----------------
        main_products: list[Product] = []
        for i, p in enumerate(data["products_main"], start=1):
            prod = Product(
                product_type="main", model=p["model"], kvm=p.get("kvm"),
                name=None, unit="dona", sku=f"KTL-{i:03d}",
                base_price_usd=D(p["base_price_usd"]), status="active",
            )
            db.add(prod)
            main_products.append(prod)
        add_products: list[Product] = []
        for i, p in enumerate(data["products_additional"], start=1):
            prod = Product(
                product_type="additional", model=None, name=p["name"],
                unit=p.get("unit", "dona"), sku=f"QSM-{i:03d}",
                base_price_usd=D(p["base_price_usd"]), status="active",
            )
            db.add(prod)
            add_products.append(prod)
        await db.flush()

        # ---------------- Inventar (SKLAD KATYOL) ----------------
        inv_units: list[Inventory] = []
        for pi, prod in enumerate(main_products[:6]):
            for n in range(2):
                u = Inventory(
                    product_id=prod.id, unique_id=f"SKL-{pi:02d}{n}",
                    status="available", added_date=TODAY - timedelta(days=30 + pi),
                )
                db.add(u)
                inv_units.append(u)
        await db.flush()

        # ---------------- Mijozlar ----------------
        customers: list[Customer] = []
        for i, c in enumerate(data["customers"]):
            cust = Customer(
                full_name=c["full_name"], phone=c["phone"], phone2=c.get("phone2"),
                country=c.get("country", "Uzbekistan"), region=c.get("region"),
                city=c.get("city"), address=c.get("address"),
                source=c.get("source", "manual"), note=c.get("note"),
                is_dealer=(i % 6 == 0),  # har 6-mijoz diller
            )
            db.add(cust)
            customers.append(cust)
        await db.flush()

        # ---------------- HR: bo'lim, lavozim, xodim, davomat ----------------
        dept = Department(name="NUR TECHNO GROUP")
        db.add(dept)
        await db.flush()
        pos_cache: dict[str, Position] = {}
        employees: list[Employee] = []
        for e in data["employees"]:
            pname = e.get("position") or "Xodim"
            pos = pos_cache.get(pname)
            if not pos:
                pos = Position(name=pname, department_id=dept.id)
                db.add(pos)
                await db.flush()
                pos_cache[pname] = pos
            emp = Employee(
                full_name=e["full_name"], phone=e.get("phone"),
                secondary_phone=e.get("secondary_phone"),
                birth_date=date.fromisoformat(e["birth_date"]) if e.get("birth_date") else None,
                address=e.get("address"), position_id=pos.id,
                hire_date=date.fromisoformat(e["hire_date"]) if e.get("hire_date") else None,
                employment_type=e.get("employment_type", "worker"),
                salary_type=e.get("salary_type", "fixed"),
                salary_amount=D(e.get("salary_amount", 0)), currency=e.get("currency", "UZS"),
                status="active",
            )
            db.add(emp)
            employees.append(emp)
        await db.flush()
        # Davomat — oxirgi 5 ish kuni, dastlabki 6 ishchi uchun
        for emp in employees[:6]:
            for back in range(5):
                wd = TODAY - timedelta(days=back)
                if wd.weekday() == 6:  # yakshanba dam
                    continue
                db.add(Attendance(
                    employee_id=emp.id, work_date=wd,
                    check_in=time(9, 0), check_out=time(18, 0),
                    hours_worked=D(8), daily_pay=D(0),
                ))

        # ---------------- Moliya ----------------
        acc_uzs = Account(name="Asosiy kassa (UZS)", currency="UZS", ledger="operational", balance=D(0))
        acc_usd = Account(name="Dollar kassa (USD)", currency="USD", ledger="operational", balance=D(0))
        acc_gazna = Account(name="GAZNA (zaxira)", currency="USD", ledger="gazna", balance=D(0))
        db.add_all([acc_uzs, acc_usd, acc_gazna])
        cat_sale = FinanceCategory(name="Buyurtma to'lovi", kind="income", code="order_payment")
        cat_other_inc = FinanceCategory(name="Boshqa kirim", kind="income", code="other_income")
        cat_salary = FinanceCategory(name="Oylik maosh", kind="expense", code="salary")
        cat_mat = FinanceCategory(name="Material xaridi", kind="expense", code="materials")
        cat_rent = FinanceCategory(name="Ijara", kind="expense", code="rent")
        db.add_all([cat_sale, cat_other_inc, cat_salary, cat_mat, cat_rent])
        db.add(ExchangeRate(date=TODAY, usd_to_uzs=RATE, source="manual"))
        await db.flush()
        # Bir nechta xarajat/kirim tranzaksiyasi (oxirgi 60 kun)
        for k in range(8):
            d = TODAY - timedelta(days=k * 7)
            db.add(FinanceTransaction(date=d, type="expense", category_id=cat_salary.id,
                                      amount=D(3_000_000 + k * 100_000), currency="UZS",
                                      account_id=acc_uzs.id, note="Maosh to'lovi"))
            db.add(FinanceTransaction(date=d, type="expense", category_id=cat_rent.id,
                                      amount=D(1_500_000), currency="UZS",
                                      account_id=acc_uzs.id, note="Ofis ijarasi"))

        # ---------------- Ta'minot ----------------
        vendors = [Vendor(name=n, phone=f"+998 90 5{i}0 00 00", is_active=True)
                   for i, n in enumerate(["Metall Plyus", "Issiqlik Servis", "TexnoдетalI", "OmadInvest"])]
        db.add_all(vendors)
        await db.flush()
        item_specs = [
            ("Po'lat list 2mm", "list", 85_000, 50, 120),   # yetarli
            ("Issiqlik quvuri", "metr", 32_000, 8, 40),      # KAM -> reorder
            ("Termostat", "dona", 145_000, 3, 15),           # KAM
            ("Ventilyator", "dona", 220_000, 25, 20),        # yetarli
            ("Nasos", "dona", 480_000, 1, 6),                # KAM
            ("Bolt-gayka to'plami", "dona", 5_000, 200, 100),
            ("Bo'yoq (issiqbardosh)", "litr", 38_000, 4, 25),  # KAM
            ("Izolyatsiya material", "metr", 18_000, 60, 50),
        ]
        items: list[Item] = []
        for i, (nm, unit, price, stock, mn) in enumerate(item_specs):
            it = Item(name=nm, vendor_id=vendors[i % len(vendors)].id, unit=unit,
                      unit_price=D(price), stock_qty=D(stock), min_qty=D(mn))
            db.add(it)
            items.append(it)
        await db.flush()
        # Bir nechta kirim — qisman to'langan (vendor qarzi)
        for i, it in enumerate(items[:5]):
            qty = D(20 + i * 5)
            total = qty * it.unit_price
            paid = total if i % 2 == 0 else (total / 2).quantize(Decimal("1"))
            db.add(GoodsReceipt(
                date=TODAY - timedelta(days=10 + i), vendor_id=it.vendor_id, item_id=it.id,
                qty=qty, unit_price=it.unit_price, total=total, paid=paid,
                balance=total - paid, status="paid" if paid >= total else "partial",
            ))

        # ---------------- Buyurtmalar + to'lovlar ----------------
        # Statuslar: ko'pi to'langan/yetkazilgan, bir qismi qarzdor (receivables)
        plans = [
            # (status, to'lov ulushi 0..1, navbatdami)
            ("delivered", 1.0, False), ("delivered", 1.0, False),
            ("ready", 0.5, True), ("ready", 0.0, True),
            ("new", 0.3, True), ("new", 0.0, True), ("new", 0.6, True),
            ("delivered", 1.0, False), ("rejected", 0.0, False),
            ("ready", 0.4, True), ("new", 0.0, True), ("delivered", 1.0, False),
        ]
        order_no = 0
        seeded_orders: list[Order] = []
        for idx, (status, paid_ratio, in_q) in enumerate(plans):
            order_no += 1
            cust = customers[idx % len(customers)]
            odate = TODAY - timedelta(days=random.randint(2, 75))
            order = Order(
                code=f"NUR-{TODAY.year}-{order_no:04d}", customer_id=cust.id,
                source="manual", order_date=odate,
                status=status, in_queue=in_q and status in ("new", "ready"),
                exchange_rate=RATE, payment_type="cash",
                area_m2=random.choice([150, 200, 300, 400]),
            )
            if status == "delivered":
                order.delivered_at = odate + timedelta(days=random.randint(3, 20))
            # 1-2 ta mahsulot
            n_items = random.randint(1, 2)
            total_uzs = Decimal(0)
            for _ in range(n_items):
                prod = random.choice(main_products)
                qty = 1
                price_usd = prod.base_price_usd or D(1000)
                unit_uzs = (price_usd * RATE).quantize(Decimal("1"))
                line = unit_uzs * qty
                total_uzs += line
                order.items.append(OrderItem(
                    product_id=prod.id, quantity=qty,
                    unit_price_usd=price_usd, unit_price_uzs=unit_uzs,
                    discount_usd=D(0), discount=D(0), total_uzs=line,
                    bunker_direction=random.choice(["left", "right"]),
                ))
            # qo'shimcha qism (ba'zan)
            if random.random() < 0.4:
                ap = random.choice(add_products)
                qty = random.randint(1, 5)
                unit_uzs = (ap.base_price_usd * RATE).quantize(Decimal("1"))
                line = unit_uzs * qty
                total_uzs += line
                order.items.append(OrderItem(
                    product_id=ap.id, quantity=qty, unit_price_usd=ap.base_price_usd,
                    unit_price_uzs=unit_uzs, discount_usd=D(0), discount=D(0), total_uzs=line,
                ))
            # to'lov(lar)
            if paid_ratio > 0 and status != "rejected":
                pay_amt = (total_uzs * D(paid_ratio)).quantize(Decimal("1"))
                order.payments.append(Payment(
                    date=odate + timedelta(days=1), amount=pay_amt, currency="UZS",
                    amount_uzs_equiv=pay_amt, method="cash", note="Boshlang'ich to'lov",
                ))
            db.add(order)
            seeded_orders.append(order)
        await db.flush()

        # ---------------- Servis arizalari ----------------
        ServiceCategoriesSeed = ["Ishga tushirish", "Profilaktika", "Ta'mirlash", "Konsultatsiya"]
        for nm in ServiceCategoriesSeed:
            db.add(ServiceCategory(name=nm, is_active=True))
        problems = [
            "Bunker qizimayapti", "Ventilyator shovqin qilyapti", "Termostat ishlamayapti",
            "Profilaktik ko'rik", "Nasos oqyapti", "Ishga tushirish va sozlash",
        ]
        delivered_orders = [o for o in seeded_orders if o.status == "delivered"]
        for i in range(8):
            cust = customers[(i * 2) % len(customers)]
            opened = dt(TODAY - timedelta(days=random.randint(1, 30)), 9 + i % 6)
            # Statuslar aralash; 4 tasi kelajakka rejalashtirilgan (kalendar uchun)
            if i < 4:
                st = "scheduled"
                sched = dt(TODAY + timedelta(days=i + 1), 10 + i)
            elif i < 6:
                st, sched = "completed", None
            else:
                st, sched = "new", None
            ord_link = delivered_orders[i % len(delivered_orders)] if delivered_orders else None
            tk = ServiceTicket(
                code=f"SRV-{TODAY.year}-{i + 1:03d}",
                customer_id=cust.id,
                order_id=ord_link.id if ord_link else None,
                problem=problems[i % len(problems)],
                category=ServiceCategoriesSeed[i % len(ServiceCategoriesSeed)],
                opened_at=opened, scheduled_at=sched,
                closed_at=dt(TODAY - timedelta(days=1)) if st == "completed" else None,
                status=st, in_warranty=(i % 2 == 0),
                client_cost=D(random.choice([0, 150_000, 300_000])),
            )
            if sched:
                tk.visits.append(ServiceVisit(planned_at=sched, travel_cost=D(50_000)))
            db.add(tk)

        await db.commit()

    # Hisobot
    async with AsyncSessionLocal() as db:
        async def cnt(model):
            return (await db.execute(select(func.count(model.id)))).scalar() or 0
        print("[ok] Demo ma'lumotlar qo'shildi:")
        for label, model in [
            ("Mahsulotlar", Product), ("Inventar", Inventory), ("Mijozlar", Customer),
            ("Xodimlar", Employee), ("Buyurtmalar", Order), ("To'lovlar", Payment),
            ("Ta'minotchilar", Vendor), ("Materiallar", Item),
            ("Servis arizalari", ServiceTicket), ("Moliya tranzaksiyalari", FinanceTransaction),
        ]:
            print(f"   - {label}: {await cnt(model)}")


if __name__ == "__main__":
    asyncio.run(main())
