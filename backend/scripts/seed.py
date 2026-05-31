"""Seed the database with initial roles, super admin user, sectors, products."""
import asyncio
import random
from datetime import date, time, timedelta
from decimal import Decimal

from sqlalchemy import select

from app.core.config import settings
from app.core.security import hash_password
from app.db.session import AsyncSessionLocal, engine
from app.db.base import Base
from app.models.customer import Customer
from app.models.order import Order, OrderItem, Payment
from app.models.finance import Account, FinanceCategory
from app.models.hr import Attendance, Employee, Position, SalaryRate
from app.models.product import Product
from app.models.supply import SupplySector
from app.models.user import Role, User


DEFAULT_ROLES = [
    ("super_admin", "Super Admin (barcha modul)"),
    ("director", "Bosh direktor"),
    ("sales_manager", "Sotuv menejeri"),
    ("salesperson", "Sotuvchi"),
    ("service_manager", "Servis menejeri"),
    ("service_technician", "Servis ustasi"),
    ("finance_manager", "Moliya menejeri"),
    ("hr_manager", "HR menejeri"),
    ("supply_lazer", "Ta'minot — LAZER sektor"),
    ("supply_chugun", "Ta'minot — CHUGUN sektor"),
    ("supply_main", "Ta'minot — ASOSIY (Umid Tokir) sektor"),
    ("supply_mardon", "Ta'minot — MARDON sektor"),
    ("viewer", "Ko'rish (read-only)"),
]


SUPPLY_SECTORS = [
    ("LAZER", "LAZER"),
    ("CHUGUN", "CHUGUN"),
    ("ASOSIY (Umid Tokir)", "ASOSIY"),
    ("MARDON", "MARDON"),
]


PRODUCT_MODELS = [
    ("PREMIUM 3", 150, "right", Decimal("1200")),
    ("PREMIUM 3", 200, "right", Decimal("1400")),
    ("PREMIUM 4", 200, "right", Decimal("1500")),
    ("PREMIUM 4", 300, "right", Decimal("1700")),
    ("ULTRA", 300, "right", Decimal("1900")),
    ("ULTRA", 400, "right", Decimal("2100")),
    ("MAGNUM", 400, "right", Decimal("2200")),
    ("MAGNUM", 500, "right", Decimal("2500")),
    ("OPTIMA", 200, "right", Decimal("1300")),
    ("OPTIMA", 300, "right", Decimal("1500")),
]


# Qo'shimcha mahsulotlar (nom, o'lchov birligi, narx USD)
ADDITIONAL_PRODUCTS = [
    ("Turba (issiqlik quvuri)", "metr", Decimal("3")),
    ("Defizor (radiator)", "dona", Decimal("25")),
    ("Aylanma nasos", "dona", Decimal("60")),
    ("Termostat", "dona", Decimal("15")),
    ("Montaj komplekti", "komplekt", Decimal("40")),
    ("Kengaytma baki", "dona", Decimal("35")),
]


INCOME_CATS = [
    ("Mahsulot sotuvi", "sales_payment"),
    ("Avans to'lovi", "advance_payment"),
    ("Qoldiq to'lov", "remaining_payment"),
    ("Qayta kirim", "returned_funds"),
    ("Boshqa kirimlar", "other_income"),
]


EXPENSE_CATS = [
    ("Xodimlar oyligi", "employee_salary"),
    ("Ta'minotga o'tkazma", "supply_payment"),
    ("Transport", "transport"),
    ("Oziq-ovqat", "food"),
    ("Kommunal xizmatlar", "utilities"),
    ("Reklama", "advertising"),
    ("Ehtiyot qismlar", "spare_parts"),
    ("Xodimga avans", "advance_to_employee"),
    ("Boshqa xarajatlar", "other_expense"),
]


SAMPLE_POSITIONS = [
    "Usta", "Yordamchi ishchi", "Payvandchi", "Montajchi",
    "Operator", "Omborchi", "Haydovchi", "Tozalovchi",
]


# (ism, lavozim, telefon, soatbay_summa, ish_boshlagan, tug'ilgan, manzil)
SAMPLE_WORKERS = [
    ("Aliyev Bobur",        "Usta",            "+998 90 123 45 67", 22000, date(2026, 1, 6),  date(1990, 3, 12), "Toshkent, Yunusobod"),
    ("Karimov Sardor",      "Payvandchi",      "+998 91 234 56 78", 20000, date(2026, 1, 20), date(1988, 7, 25), "Toshkent, Chilonzor"),
    ("Toshmatov Jasur",     "Montajchi",       "+998 93 345 67 89", 19000, date(2026, 2, 3),  date(1995, 11, 2), "Toshkent, Sergeli"),
    ("Rahimov Otabek",      "Yordamchi ishchi","+998 94 456 78 90", 16000, date(2026, 2, 17), date(1999, 1, 18), "Toshkent, Olmazor"),
    ("Yusupov Diyor",       "Operator",        "+998 95 567 89 01", 18000, date(2026, 3, 2),  date(1992, 9, 9),  "Toshkent, Mirzo Ulug'bek"),
    ("Sobirov Akmal",       "Omborchi",        "+998 97 678 90 12", 17000, date(2026, 3, 16), date(1985, 5, 30), "Toshkent, Yashnobod"),
    ("Nazarov Shahzod",     "Haydovchi",       "+998 98 789 01 23", 17500, date(2026, 4, 1),  date(1991, 12, 5), "Toshkent, Bektemir"),
    ("Ismoilov Bekzod",     "Yordamchi ishchi","+998 99 890 12 34", 16000, date(2026, 4, 14), date(2000, 2, 22), "Toshkent, Uchtepa"),
]


# (ism, telefon, qo'shimcha_telefon, davlat, viloyat, shahar/tuman, manzil, manba, izoh)
SAMPLE_CUSTOMERS = [
    ("Abdullayev Jahongir", "+998 90 111 22 33", "+998 91 111 22 33", "Uzbekistan", "Toshkent", "Yunusobod", "Amir Temur ko'chasi 12", "manual", "Doimiy mijoz"),
    ("Mirzayeva Nodira",    "+998 93 222 33 44", None,                 "Uzbekistan", "Toshkent", "Chilonzor", "Bunyodkor shoh ko'chasi 45", "manual", None),
    ("Qodirov Sherzod",     "+998 94 333 44 55", None,                 "Uzbekistan", "Samarqand", "Samarqand sh.", "Registon ko'chasi 8", "telegram_bot", "Telegram bot orqali"),
    ("Tursunova Malika",    "+998 95 444 55 66", "+998 97 444 55 66",  "Uzbekistan", "Buxoro", "Buxoro sh.", "Mustaqillik ko'chasi 23", "manual", None),
    ("Ergashev Bekzod",     "+998 97 555 66 77", None,                 "Uzbekistan", "Andijon", "Andijon sh.", "Navoiy ko'chasi 56", "manual", "Ulgurji buyurtma"),
    ("Yo'ldosheva Sevara",  "+998 98 666 77 88", None,                 "Uzbekistan", "Farg'ona", "Farg'ona sh.", "Al-Farg'oniy ko'chasi 17", "manual", None),
    ("Sodiqov Aziz",        "+998 99 777 88 99", "+998 90 777 88 99",  "Uzbekistan", "Namangan", "Namangan sh.", "Uychi ko'chasi 9", "manual", None),
    ("Rashidova Gulnora",   "+998 90 888 99 00", None,                 "Uzbekistan", "Qashqadaryo", "Qarshi sh.", "Mustaqillik ko'chasi 34", "telegram_bot", None),
    ("Olimov Farrux",       "+998 91 999 00 11", None,                 "Uzbekistan", "Surxondaryo", "Termiz sh.", "Alpomish ko'chasi 21", "manual", "Yetkazib berish kerak"),
    ("Hamidova Dilnoza",    "+998 93 100 20 30", None,                 "Uzbekistan", "Xorazm", "Urganch sh.", "Al-Xorazmiy ko'chasi 5", "manual", None),
    ("Jo'rayev Sanjar",     "+998 94 200 30 40", "+998 95 200 30 40",  "Uzbekistan", "Navoiy", "Navoiy sh.", "Navoiy ko'chasi 78", "manual", None),
    ("Nurmatova Kamola",    "+998 95 300 40 50", None,                 "Uzbekistan", "Jizzax", "Jizzax sh.", "Sharof Rashidov ko'chasi 14", "manual", None),
    ("Saidov Ulug'bek",     "+998 97 400 50 60", None,                 "Uzbekistan", "Sirdaryo", "Guliston sh.", "Istiqlol ko'chasi 30", "manual", "Naqd to'lov"),
    ("Bozorov Davron",      "+998 98 500 60 70", None,                 "Uzbekistan", "Toshkent viloyati", "Chirchiq sh.", "Sanoat ko'chasi 11", "manual", None),
    ("Allayorov Rustam",    "+998 99 600 70 80", "+998 90 600 70 80",  "Uzbekistan", "Qoraqalpog'iston", "Nukus sh.", "Berdaq ko'chasi 41", "telegram_bot", "Uzoq hudud"),
]


async def _seed_customers(db):
    """Namunaviy 15 ta mijoz (idempotent — telefon bo'yicha tekshiriladi)."""
    created = 0
    for full_name, phone, phone2, country, region, city, address, source, note in SAMPLE_CUSTOMERS:
        res = await db.execute(select(Customer).where(Customer.phone == phone))
        if res.scalar_one_or_none():
            continue
        db.add(Customer(
            full_name=full_name, phone=phone, phone2=phone2,
            country=country, region=region, city=city, address=address,
            source=source, note=note,
        ))
        created += 1
    print(f"[+] Mijozlar namunasi: {created} yangi mijoz")


# Har bir buyurtma uchun status (20 ta) — ko'pchiligi faol (navbatda ko'rinadi)
SAMPLE_ORDER_STATUSES = [
    "new", "new", "ready", "new", "ready",
    "new", "ready", "delivered", "new", "ready",
    "new", "ready", "new", "delivered", "new",
    "ready", "delivered", "new", "ready", "rejected",
]


async def _seed_orders(db):
    """Bor mijozlarga 20 ta namunaviy buyurtma (idempotent — kod bo'yicha tekshiriladi).

    Kodlar 2026-90001..90020 (yuqori raqamlar) — haqiqiy generatsiya bilan to'qnashmaydi.
    """
    custs = (await db.execute(select(Customer).order_by(Customer.created_at))).scalars().all()
    prods = (await db.execute(
        select(Product).where(Product.product_type == "main")
    )).scalars().all()
    if not custs or not prods:
        print("[i] Buyurtma seed: mijoz yoki mahsulot topilmadi — o'tkazib yuborildi")
        return

    rate = Decimal("12150")
    rng = random.Random(42)  # takrorlanuvchi natija uchun
    today = date.today()
    created = 0

    for i in range(20):
        code = f"2026-{90001 + i:05d}"
        exists = await db.execute(select(Order).where(Order.code == code))
        if exists.scalar_one_or_none():
            continue

        cust = custs[i % len(custs)]
        status = SAMPLE_ORDER_STATUSES[i]
        order_date = today - timedelta(days=rng.randint(0, 75))
        priority = rng.choice([0, 0, 0, 0, 0, 3, 7])

        order = Order(
            code=code, customer_id=cust.id, status=status,
            order_date=order_date, exchange_rate=rate, source="manual",
            priority=priority, delivery_address=cust.address,
        )

        total = Decimal(0)
        for _ in range(rng.choice([1, 1, 1, 2])):
            prod = rng.choice(prods)
            qty = rng.choice([1, 1, 1, 2])
            usd = (prod.base_price_usd or Decimal(0)) + Decimal(rng.choice([0, 50, 100, 150]))
            uzs = (usd * rate).quantize(Decimal("1"))
            discount = Decimal(rng.choice([0, 0, 0, 500000, 1000000]))
            line = uzs * qty - discount
            total += line
            order.items.append(OrderItem(
                product_id=prod.id,
                bunker_direction=rng.choice(["right", "left"]),
                quantity=qty, unit_price_usd=usd, unit_price_uzs=uzs,
                discount=discount, total_uzs=line,
            ))

        if status == "delivered":
            order.delivered_at = order_date + timedelta(days=rng.randint(3, 20))

        db.add(order)
        await db.flush()

        # Namunaviy to'lovlar
        pay_date = order_date + timedelta(days=2)
        if status == "delivered":
            # to'liq to'langan
            db.add(Payment(order_id=order.id, date=pay_date, amount=total,
                           currency="UZS", amount_uzs_equiv=total, method="transfer"))
        elif status == "ready":
            # taxminan 50% to'langan
            paid = (total * Decimal("0.5")).quantize(Decimal("1"))
            db.add(Payment(order_id=order.id, date=pay_date, amount=paid,
                           currency="UZS", amount_uzs_equiv=paid, method="cash"))
        elif status == "new":
            # 30% avans
            adv = (total * Decimal("0.3")).quantize(Decimal("1"))
            db.add(Payment(order_id=order.id, date=pay_date, amount=adv,
                           currency="UZS", amount_uzs_equiv=adv, method="cash"))
        # rejected — to'lovsiz

        created += 1

    print(f"[+] Buyurtma namunasi: {created} yangi buyurtma")


async def _seed_hr_samples(db):
    """Namunaviy lavozimlar va oddiy ishchilar (idempotent) + bittasiga namuna davomat."""
    # Lavozimlar
    pos_by_name = {}
    for name in SAMPLE_POSITIONS:
        res = await db.execute(select(Position).where(Position.name == name))
        p = res.scalar_one_or_none()
        if not p:
            p = Position(name=name)
            db.add(p)
            await db.flush()
        pos_by_name[name] = p

    # Ishchilar
    created_emps = []
    for full_name, pos_name, phone, rate, hire, birth, addr in SAMPLE_WORKERS:
        res = await db.execute(
            select(Employee).where(
                Employee.full_name == full_name,
                Employee.employment_type == "worker",
            )
        )
        emp = res.scalar_one_or_none()
        if not emp:
            emp = Employee(
                full_name=full_name,
                phone=phone,
                birth_date=birth,
                address=addr,
                position_id=pos_by_name[pos_name].id,
                hire_date=hire,
                employment_type="worker",
                salary_type="hourly",
                salary_amount=Decimal(rate),
                currency="UZS",
                status="active",
                has_account=False,
            )
            db.add(emp)
            await db.flush()
            # Boshlang'ich stavka tarixi — ish boshlagan sanadan
            db.add(SalaryRate(
                employee_id=emp.id, effective_from=hire,
                salary_type="hourly", amount=Decimal(rate), currency="UZS",
            ))
            created_emps.append(emp)

    # Namuna davomat — birinchi 5 ishchi uchun oxirgi 3 oy (~92 kun), yakshanba dam.
    # Idempotent: mavjud yozuvlar o'tkazib yuboriladi, shuning uchun avval yaratilgan
    # ishchilarga ham keyingi seed'da davomat to'ldiriladi.
    today = date.today()
    target_names = [w[0] for w in SAMPLE_WORKERS[:5]]
    res = await db.execute(
        select(Employee).where(
            Employee.full_name.in_(target_names),
            Employee.employment_type == "worker",
        )
    )
    targets = res.scalars().all()

    check_in = time(8, 30)
    check_out = time(18, 0)
    hours = Decimal("9.50")
    filled = 0
    for emp in targets:
        daily = (emp.salary_amount or Decimal(0)) * hours
        for i in range(92):
            d = today - timedelta(days=i)
            if emp.hire_date and d < emp.hire_date:
                continue
            if d.weekday() == 6:  # yakshanba — dam
                continue
            exists = await db.execute(
                select(Attendance.id).where(
                    Attendance.employee_id == emp.id,
                    Attendance.work_date == d,
                )
            )
            if exists.scalar_one_or_none():
                continue
            db.add(Attendance(
                employee_id=emp.id, work_date=d,
                check_in=check_in, check_out=check_out,
                hours_worked=hours, daily_pay=daily,
            ))
            filled += 1
    print(f"[+] HR namuna: {len(created_emps)} yangi ishchi, {len(targets)} ishchiga davomat ({filled} kun)")


async def seed():
    print(f"Connecting to DB at: {settings.DATABASE_URL}")

    # Ensure tables exist
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        # Roles — super_admin'ga to'liq ruxsat (*:*), boshqalari bo'sh
        # Permission UI orqali keyinroq to'ldiriladi
        for name, desc in DEFAULT_ROLES:
            res = await db.execute(select(Role).where(Role.name == name))
            existing = res.scalar_one_or_none()
            default_perms = {"permissions": ["*:*"]} if name == "super_admin" else {"permissions": []}
            if not existing:
                db.add(Role(name=name, description=desc, permissions=default_perms))
            elif name == "super_admin":
                # super_admin'da *:* yo'q bo'lsa qo'shamiz (eski seed'larni yangilash)
                perms = existing.permissions or {}
                items = perms.get("permissions") if isinstance(perms, dict) else perms
                if not items or "*:*" not in items:
                    existing.permissions = {"permissions": ["*:*"]}

        # Rolelarni darhol flush qilamiz — keyin super_admin role'ni topa olamiz
        await db.flush()

        # Super admin user
        res = await db.execute(select(User).where(User.email == settings.INIT_ADMIN_EMAIL))
        if not res.scalar_one_or_none():
            # super_admin role'ni topamiz (user yaratishdan OLDIN — async lazy-load muammosini chetlab o'tish uchun)
            role_res = await db.execute(select(Role).where(Role.name == "super_admin"))
            super_role = role_res.scalar_one_or_none()

            admin = User(
                email=settings.INIT_ADMIN_EMAIL,
                password_hash=hash_password(settings.INIT_ADMIN_PASSWORD),
                full_name=settings.INIT_ADMIN_NAME,
                is_active=True, is_superadmin=True, locale="uz", theme="light",
                roles=[super_role] if super_role else [],
            )
            db.add(admin)
            print(f"[+] Created super admin: {settings.INIT_ADMIN_EMAIL} / {settings.INIT_ADMIN_PASSWORD}")

        # Supply sectors
        for name, code in SUPPLY_SECTORS:
            res = await db.execute(select(SupplySector).where(SupplySector.code == code))
            if not res.scalar_one_or_none():
                db.add(SupplySector(name=name, code=code))

        # Default accounts
        for name, currency, ledger in [
            ("Naqd - UZS", "UZS", "operational"),
            ("Naqd - USD", "USD", "operational"),
            ("Bank Asaka - UZS", "UZS", "operational"),
            ("Karta Uzcard - UZS", "UZS", "operational"),
            ("G'azna (naqd dollar)", "USD", "gazna"),
        ]:
            res = await db.execute(select(Account).where(Account.name == name))
            if not res.scalar_one_or_none():
                db.add(Account(name=name, currency=currency, ledger=ledger, balance=Decimal(0)))

        # Finance categories
        for name, code in INCOME_CATS:
            res = await db.execute(select(FinanceCategory).where(FinanceCategory.code == code))
            if not res.scalar_one_or_none():
                db.add(FinanceCategory(name=name, code=code, kind="income"))
        for name, code in EXPENSE_CATS:
            res = await db.execute(select(FinanceCategory).where(FinanceCategory.code == code))
            if not res.scalar_one_or_none():
                db.add(FinanceCategory(name=name, code=code, kind="expense"))

        # Products
        for model, kvm, direction, price in PRODUCT_MODELS:
            res = await db.execute(
                select(Product).where(
                    Product.product_type == "main",
                    Product.model == model,
                    Product.kvm == kvm,
                )
            )
            if not res.scalar_one_or_none():
                db.add(Product(
                    product_type="main", model=model, kvm=kvm,
                    base_price_usd=price, status="active",
                ))

        # Qo'shimcha mahsulotlar (idempotent — nom bo'yicha)
        for name, unit, price in ADDITIONAL_PRODUCTS:
            res = await db.execute(
                select(Product).where(
                    Product.product_type == "additional",
                    Product.name == name,
                )
            )
            if not res.scalar_one_or_none():
                db.add(Product(
                    product_type="additional", name=name, unit=unit,
                    base_price_usd=price, status="active",
                ))

        # Namunaviy mijozlar
        await _seed_customers(db)

        # Namunaviy buyurtmalar (mijoz va mahsulotlar flush qilingach)
        await db.flush()
        await _seed_orders(db)

        # HR — namunaviy lavozim va ishchilar
        await _seed_hr_samples(db)

        await db.commit()
        print("[OK] Seed completed.")


if __name__ == "__main__":
    asyncio.run(seed())
