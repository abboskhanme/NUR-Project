"""Seed the database with initial roles, super admin user, sectors, products.

Namunaviy (demo) baza ma'lumotlari — mahsulotlar, mijozlar, xodimlar — alohida
`scripts/sample_data.json` faylida saqlanadi. Bu skript har 'docker compose up' da
ishlaydi va o'sha fayldan o'qib bazani to'ldiradi. Hammasi IDEMPOTENT: mavjud yozuv
qayta qo'shilmaydi, shuning uchun `docker compose down` qilib qayta ko'targaningizda
namunaviy ma'lumotlar yana tiklanadi, sizning qo'lda kiritgan ma'lumotlaringiz esa
o'chmaydi.

Ma'lumotni o'zgartirish uchun faqat sample_data.json'ni tahrirlang — kodga tegmang.
"""
import asyncio
import json
import random
from datetime import date, time, timedelta
from decimal import Decimal
from pathlib import Path

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


# ---------------------------------------------------------------------------
# Namunaviy ma'lumotlar fayli — products / customers / employees shu yerdan
# ---------------------------------------------------------------------------
SAMPLE_DATA_PATH = Path(__file__).parent / "sample_data.json"


def _load_sample_data() -> dict:
    try:
        with open(SAMPLE_DATA_PATH, encoding="utf-8") as f:
            data = json.load(f)
        print(f"[i] Namunaviy ma'lumotlar yuklandi: {SAMPLE_DATA_PATH.name}")
        return data
    except FileNotFoundError:
        print(f"[!] {SAMPLE_DATA_PATH.name} topilmadi — namunaviy ma'lumotlar o'tkazib yuborildi")
        return {}
    except json.JSONDecodeError as e:
        print(f"[!] {SAMPLE_DATA_PATH.name} JSON xato ({e}) — namunaviy ma'lumotlar o'tkazib yuborildi")
        return {}


SAMPLE = _load_sample_data()


def _dec(v) -> Decimal:
    """JSON son/satrini xavfsiz Decimalga aylantiradi."""
    return Decimal(str(v if v is not None else 0))


def _parse_date(v):
    return date.fromisoformat(v) if v else None


# ---------------------------------------------------------------------------
# Tizim konfiguratsiyasi (namunaviy emas — har doim kerak)
# ---------------------------------------------------------------------------
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


# ---------------------------------------------------------------------------
# Mijozlar (sample_data.json -> customers)
# ---------------------------------------------------------------------------
async def _seed_customers(db):
    """Namunaviy mijozlar (idempotent — telefon bo'yicha tekshiriladi)."""
    created = 0
    for c in SAMPLE.get("customers", []):
        res = await db.execute(select(Customer).where(Customer.phone == c["phone"]))
        if res.scalar_one_or_none():
            continue
        db.add(Customer(
            full_name=c["full_name"], phone=c["phone"], phone2=c.get("phone2"),
            country=c.get("country", "Uzbekistan"), region=c.get("region"),
            city=c.get("city"), address=c.get("address"),
            source=c.get("source", "manual"), note=c.get("note"),
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


# ---------------------------------------------------------------------------
# Xodimlar — office (ofis) + worker (ishchi), sample_data.json -> employees
# ---------------------------------------------------------------------------
async def _seed_hr_samples(db):
    """Namunaviy xodimlar (ofis + ishchi, idempotent) + ishchilarga namuna davomat."""
    employees = SAMPLE.get("employees", [])

    # Lavozimlar — barcha xodimlardagi unikal lavozimlar
    pos_by_name = {}
    for name in sorted({e["position"] for e in employees if e.get("position")}):
        res = await db.execute(select(Position).where(Position.name == name))
        p = res.scalar_one_or_none()
        if not p:
            p = Position(name=name)
            db.add(p)
            await db.flush()
        pos_by_name[name] = p

    # Xodimlar — full_name + employment_type bo'yicha idempotent
    created_emps = 0
    for e in employees:
        emp_type = e.get("employment_type", "worker")
        res = await db.execute(
            select(Employee).where(
                Employee.full_name == e["full_name"],
                Employee.employment_type == emp_type,
            )
        )
        if res.scalar_one_or_none():
            continue

        pos = pos_by_name.get(e.get("position"))
        hire = _parse_date(e.get("hire_date"))
        salary_type = e.get("salary_type", "hourly")
        amount = _dec(e.get("salary_amount"))
        currency = e.get("currency", "UZS")

        emp = Employee(
            full_name=e["full_name"],
            phone=e.get("phone"),
            secondary_phone=e.get("secondary_phone"),
            birth_date=_parse_date(e.get("birth_date")),
            address=e.get("address"),
            position_id=pos.id if pos else None,
            hire_date=hire,
            employment_type=emp_type,
            salary_type=salary_type,
            salary_amount=amount,
            currency=currency,
            status="active",
            has_account=bool(e.get("has_account", False)),
        )
        db.add(emp)
        await db.flush()

        # Boshlang'ich stavka tarixi — ish boshlagan sanadan
        if hire:
            db.add(SalaryRate(
                employee_id=emp.id, effective_from=hire,
                salary_type=salary_type, amount=amount, currency=currency,
            ))
        created_emps += 1

    # Namuna davomat — birinchi 5 ISHCHI (worker) uchun oxirgi 3 oy (~92 kun),
    # yakshanba dam. Ofis xodimlariga davomat kiritilmaydi (oylik fixed).
    worker_names = [e["full_name"] for e in employees if e.get("employment_type") == "worker"][:5]
    targets = []
    if worker_names:
        res = await db.execute(
            select(Employee).where(
                Employee.full_name.in_(worker_names),
                Employee.employment_type == "worker",
            )
        )
        targets = res.scalars().all()

    today = date.today()
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

    office_cnt = sum(1 for e in employees if e.get("employment_type") == "office")
    worker_cnt = sum(1 for e in employees if e.get("employment_type") == "worker")
    print(f"[+] HR namuna: {created_emps} yangi xodim "
          f"({office_cnt} ofis / {worker_cnt} ishchi manbada), "
          f"{len(targets)} ishchiga davomat ({filled} kun)")


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

        # Products — asosiy (main) mahsulotlar (sample_data.json -> products_main)
        for p in SAMPLE.get("products_main", []):
            res = await db.execute(
                select(Product).where(
                    Product.product_type == "main",
                    Product.model == p["model"],
                    Product.kvm == p["kvm"],
                )
            )
            if not res.scalar_one_or_none():
                db.add(Product(
                    product_type="main", model=p["model"], kvm=p["kvm"],
                    base_price_usd=_dec(p.get("base_price_usd")), status="active",
                ))

        # Qo'shimcha mahsulotlar (idempotent — nom bo'yicha)
        for p in SAMPLE.get("products_additional", []):
            res = await db.execute(
                select(Product).where(
                    Product.product_type == "additional",
                    Product.name == p["name"],
                )
            )
            if not res.scalar_one_or_none():
                db.add(Product(
                    product_type="additional", name=p["name"], unit=p.get("unit"),
                    base_price_usd=_dec(p.get("base_price_usd")), status="active",
                ))

        # Namunaviy mijozlar
        await _seed_customers(db)

        # Namunaviy buyurtmalar (mijoz va mahsulotlar flush qilingach)
        await db.flush()
        await _seed_orders(db)

        # HR — namunaviy ofis va ishchi xodimlar
        await _seed_hr_samples(db)

        await db.commit()
        print("[OK] Seed completed.")


if __name__ == "__main__":
    asyncio.run(seed())
