"""Hisobotlar — Servis va Ishlab chiqarish bo'limlari.

Tekshiriladi:
  - /reports/service/summary: holatlar, viloyat kesimi, ehtiyot qismlar,
    safar puli, dinamika va o'rtacha yopish muddati
  - /reports/production/summary: FAQAT kotyol va olib kelingan kotyol (tana);
    bunker/garelka hisobotga kirmaydi; model/o'lcham/yo'nalish va omborga
    o'tkazilgan holati

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/reports"

TODAY = date.today()
FROM = TODAY - timedelta(days=10)


def _dt(d: date) -> datetime:
    return datetime(d.year, d.month, d.day, 10, 0, tzinfo=timezone.utc)


async def _user(db_engine, permissions: list[str]):
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}", permissions={"permissions": permissions})
        db.add(role)
        await db.flush()
        user = User(phone=f"+9989{uuid.uuid4().int % 10**8:08d}", password_hash="x",
                    full_name="Test", is_active=True, token_version=0)
        user.roles = [role]
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user


def _auth(client, user):
    from app.core.dependencies import get_current_user
    from app.main import app

    async def _override():
        return user

    app.dependency_overrides[get_current_user] = _override
    return client


async def _seed_service(db_engine):
    from app.models.customer import Customer
    from app.models.service import ServiceTicket, ServiceTrip

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        andijon = Customer(full_name="Ali", phone="+998900000001", region="Andijon")
        namangan = Customer(full_name="Vali", phone="+998900000002", region="Namangan")
        # Viloyati ko'rsatilmagan mijoz — alohida qatorga tushishi kerak
        noregion = Customer(full_name="Sami", phone="+998900000003", region="  ")
        db.add_all([andijon, namangan, noregion])
        await db.commit()
        for c in (andijon, namangan, noregion):
            await db.refresh(c)

        opened = TODAY - timedelta(days=5)
        db.add_all([
            # Bajarilgan, 2 kunda yopilgan, kafolatda, 2 ta qism
            ServiceTicket(code="SRV-T-1", customer_id=andijon.id, problem="Timer ishlamaydi",
                          category="Elektr", parts_used=["Timer", "Nasos"],
                          opened_at=_dt(opened), closed_at=_dt(opened + timedelta(days=2)),
                          status="completed", in_warranty=True, client_cost=Decimal(150_000)),
            # Yangi, kafolatdan tashqari, "0 dan" ariza
            ServiceTicket(code="SRV-T-2", customer_id=namangan.id, problem="Shovqin",
                          category="Mexanika", parts_used=["Timer"],
                          opened_at=_dt(opened), status="new", in_warranty=False,
                          is_external=True, client_cost=Decimal(50_000)),
            # Toifasiz — bo'sh toifa "Toifasiz" bo'lib guruhlanishi kerak
            ServiceTicket(code="SRV-T-3", customer_id=noregion.id, problem="Boshqa",
                          category="  ", parts_used=[],
                          opened_at=_dt(TODAY - timedelta(days=1)), status="scheduled"),
            # Davrdan TASHQARI — hisobotga kirmasligi kerak
            ServiceTicket(code="SRV-T-4", customer_id=andijon.id, problem="Eski",
                          category="Elektr", parts_used=["Motor"],
                          opened_at=_dt(TODAY - timedelta(days=90)), status="completed",
                          client_cost=Decimal(999_000)),
        ])
        # Yakunlangan safar — puli hisobotga kiradi; ochiq safar kirmaydi
        db.add_all([
            ServiceTrip(name="Safar-1", status="closed", collected=Decimal(500_000),
                        spent=Decimal(200_000), opened_at=_dt(TODAY - timedelta(days=4)),
                        closed_at=_dt(TODAY - timedelta(days=3))),
            ServiceTrip(name="Safar-2", status="open", collected=Decimal(700_000),
                        spent=Decimal(100_000), opened_at=_dt(TODAY)),
        ])
        await db.commit()


async def _seed_production(db_engine):
    from app.models.product import Product
    from app.models.production import ProductionRecord

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        optima = Product(product_type="warehouse", model="OPTIMA", kvm=200, status="active")
        maxi = Product(product_type="warehouse", model="MAXI", kvm=300, status="active")
        db.add_all([optima, maxi])
        await db.commit()
        await db.refresh(optima)
        await db.refresh(maxi)

        d1 = TODAY - timedelta(days=3)
        d2 = TODAY - timedelta(days=1)
        db.add_all([
            ProductionRecord(category="kotyol", production_date=d1, quantity=1,
                             product_id=optima.id, unit_code="K-1", bunker_direction="right",
                             transferred_at=datetime.now(timezone.utc)),
            ProductionRecord(category="kotyol", production_date=d1, quantity=1,
                             product_id=optima.id, unit_code="K-2", bunker_direction="left"),
            ProductionRecord(category="kotyol", production_date=d2, quantity=1,
                             product_id=maxi.id, unit_code="K-3", bunker_direction="right"),
            ProductionRecord(category="tana", production_date=d2, quantity=4,
                             body_size="200", bunker_direction="right"),
            ProductionRecord(category="tana", production_date=d2, quantity=2,
                             body_size="300", bunker_direction="left"),
            # Bunker/garelka — hisobotga KIRMAYDI
            ProductionRecord(category="bunker", production_date=d2, quantity=10),
            ProductionRecord(category="garelka", production_date=d2, quantity=7),
            # Davrdan tashqari kotyol
            ProductionRecord(category="kotyol", production_date=TODAY - timedelta(days=90),
                             quantity=1, product_id=maxi.id, unit_code="K-OLD"),
        ])
        await db.commit()


async def test_service_summary_report(client, db_engine):
    await _seed_service(db_engine)
    user = await _user(db_engine, ["reports:read"])
    c = _auth(client, user)

    r = await c.get(f"{API}/service/summary",
                    params={"date_from": FROM.isoformat(), "date_to": TODAY.isoformat()})
    assert r.status_code == 200, r.text
    d = r.json()

    # Davrdan tashqaridagi ariza kirmaydi
    assert d["total"] == 3
    assert d["completed"] == 1 and d["new"] == 1 and d["scheduled"] == 1
    assert d["in_warranty"] == 1 and d["out_warranty"] == 2
    assert d["external"] == 1
    assert d["client_revenue_uzs"] == 200_000
    # 2 kunda yopilgan yagona ariza
    assert d["avg_close_days"] == 2.0

    cats = {row["category"]: row["count"] for row in d["by_category"]}
    assert cats == {"Elektr": 1, "Mexanika": 1, "Toifasiz": 1}

    regions = {row["region"]: row for row in d["by_region"]}
    assert regions["Andijon"]["count"] == 1
    assert regions["Andijon"]["client_cost_uzs"] == 150_000
    assert regions["Namangan"]["count"] == 1
    assert regions["Ko'rsatilmagan"]["count"] == 1

    parts = {row["name"]: row["count"] for row in d["parts"]}
    assert parts == {"Timer": 2, "Nasos": 1}
    assert d["parts_total"] == 3

    # Faqat yakunlangan safar
    assert d["trips"]["trip_count"] == 1
    assert d["trips"]["collected_uzs"] == 500_000
    assert d["trips"]["spent_uzs"] == 200_000
    assert d["trips"]["net_uzs"] == 300_000

    assert d["granularity"] == "day"
    assert len(d["trend"]) == 11  # 10 kunlik oraliq, ikki chekka kiritilgan
    assert sum(p["total"] for p in d["trend"]) == 3
    assert sum(p["completed"] for p in d["trend"]) == 1


async def test_production_summary_report(client, db_engine):
    await _seed_production(db_engine)
    user = await _user(db_engine, ["reports:read"])
    c = _auth(client, user)

    r = await c.get(f"{API}/production/summary",
                    params={"date_from": FROM.isoformat(), "date_to": TODAY.isoformat()})
    assert r.status_code == 200, r.text
    d = r.json()

    assert d["kotyol_total"] == 3
    assert d["tana_total"] == 6          # 4 + 2 (bunker/garelka qo'shilmaydi)
    assert d["kotyol_transferred"] == 1
    assert d["kotyol_pending"] == 2
    assert d["work_days"] == 2

    models = {(row["model"], row["kvm"]): row["count"] for row in d["kotyol_by_model"]}
    assert models == {("OPTIMA", 200): 2, ("MAXI", 300): 1}

    sizes = {row["size"]: row["count"] for row in d["kotyol_by_size"]}
    assert sizes == {"200 kvm": 2, "300 kvm": 1}

    tana_sizes = {row["size"]: row["count"] for row in d["tana_by_size"]}
    assert tana_sizes == {"200": 4, "300": 2}

    kdir = {row["direction"]: row["count"] for row in d["kotyol_by_direction"]}
    assert kdir == {"O'ngga": 2, "Chapga": 1}
    tdir = {row["direction"]: row["count"] for row in d["tana_by_direction"]}
    assert tdir == {"O'ngga": 4, "Chapga": 2}

    assert d["granularity"] == "day"
    assert sum(p["kotyol"] for p in d["trend"]) == 3
    assert sum(p["tana"] for p in d["trend"]) == 6


async def test_production_report_needs_reports_permission(client, db_engine):
    user = await _user(db_engine, ["orders:read"])
    c = _auth(client, user)
    r = await c.get(f"{API}/production/summary")
    assert r.status_code == 403


async def test_month_granularity_for_long_range(client, db_engine):
    """62 kundan uzun oraliqda dinamika OYLIK kesimga o'tadi."""
    await _seed_service(db_engine)
    await _seed_production(db_engine)
    user = await _user(db_engine, ["reports:read"])
    c = _auth(client, user)
    params = {"date_from": (TODAY - timedelta(days=120)).isoformat(),
              "date_to": TODAY.isoformat()}

    s = await c.get(f"{API}/service/summary", params=params)
    assert s.status_code == 200, s.text
    assert s.json()["granularity"] == "month"
    # Endi 90 kun oldingi ariza ham kiradi
    assert s.json()["total"] == 4
    assert sum(p["total"] for p in s.json()["trend"]) == 4

    p = await c.get(f"{API}/production/summary", params=params)
    assert p.status_code == 200, p.text
    assert p.json()["granularity"] == "month"
    assert p.json()["kotyol_total"] == 4
    assert sum(x["kotyol"] for x in p.json()["trend"]) == 4
    assert sum(x["tana"] for x in p.json()["trend"]) == 6
