"""Servis qidiruvi — mijozning istalgan ma'lumoti bo'yicha.

1) Arizalar ro'yxati (`/service/tickets?search=`) va KPI kartalari: ariza kodi,
   muammo, serial ID, manzil, mijoz ismi/manzili, telefon (asosiy va qo'shimcha,
   faqat raqamlar), buyurtma ID (qo'lda kiritilgan va tizim kodi).
2) Yangi ariza oynasi (`/service/customer-search?q=`): yuqoridagi mijoz/buyurtma
   maydonlari; qo'lda kiritilgan ID bo'yicha topilsa buyurtma biriktiriladi.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import date, datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/service"


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


async def _seed(db_engine) -> dict:
    """Ikki mijoz, har birining buyurtmasi va arizasi."""
    from app.models.customer import Customer
    from app.models.order import Order
    from app.models.service import ServiceTicket

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        nodir = Customer(full_name="Nodirbek Qosimov", phone="+998 90 123 45 67",
                         phone2="+998 93 777 11 22", region="Farg'ona",
                         address="Rishton tumani, Navbahor ko'chasi")
        aziz = Customer(full_name="Aziz Karimov", phone="+998 91 400 00 01",
                        region="Namangan", address="Chust shahri")
        db.add_all([nodir, aziz])
        await db.flush()
        o1 = Order(code="2026-00156", customer_id=nodir.id, order_date=date(2026, 3, 1),
                   status="delivered", unit_uid="K-4471")
        o2 = Order(code="2026-00200", customer_id=aziz.id, order_date=date(2026, 4, 1),
                   status="delivered", unit_uid="K-5590")
        db.add_all([o1, o2])
        await db.flush()
        now = datetime.now(timezone.utc)
        t1 = ServiceTicket(code="SRV-0001", customer_id=nodir.id, order_id=o1.id,
                           problem="garelka yonmayapti", status="new", opened_at=now)
        t2 = ServiceTicket(code="SRV-0002", customer_id=aziz.id, order_id=o2.id,
                           problem="OPTIMA 400 kvm — eshik singan", status="completed",
                           serial_id="SN-77821", address="Chust, bozor orqasi",
                           opened_at=now, closed_at=now)
        db.add_all([t1, t2])
        await db.commit()
        return {"nodir": str(nodir.id), "aziz": str(aziz.id),
                "o1": str(o1.id), "t1": "SRV-0001", "t2": "SRV-0002"}


async def _codes(c, **params) -> set[str]:
    r = await c.get(f"{API}/tickets", params={"page_size": 100, **params})
    assert r.status_code == 200, r.text
    return {t["code"] for t in r.json()["items"]}


# --------------------------------------------------------------------------- #
# Arizalar ro'yxati
# --------------------------------------------------------------------------- #
async def test_list_search_by_customer_and_order_fields(client, db_engine):
    ids = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    cases = {
        "nodirbek": {ids["t1"]},          # ism (katta-kichik harf farqsiz)
        "Rishton": {ids["t1"]},           # mijoz manzili
        "90 123 45": {ids["t1"]},         # telefon — bo'shliqlar bilan
        "901234567": {ids["t1"]},         # telefon — faqat raqamlar
        "93-777-11": {ids["t1"]},         # qo'shimcha telefon
        "K-4471": {ids["t1"]},            # qo'lda kiritilgan buyurtma ID
        "2026-00200": {ids["t2"]},        # buyurtma tizim kodi
        "SN-778": {ids["t2"]},            # arizadagi serial ID
        "bozor orqasi": {ids["t2"]},      # arizadagi manzil
        "SRV-0002": {ids["t2"]},          # ariza kodi (avvalgidek)
        "garelka": {ids["t1"]},           # muammo matni (avvalgidek)
    }
    for term, expected in cases.items():
        assert await _codes(c, search=term) == expected, term


async def test_list_search_text_with_digits_does_not_match_phones(client, db_engine):
    """"OPTIMA 400" — telefonda "400" bor mijoz (Aziz) shuning uchun topilmasligi kerak,
    faqat muammo matni bo'yicha topiladi."""
    ids = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    assert await _codes(c, search="OPTIMA 400") == {ids["t2"]}
    assert await _codes(c, search="eshik 400") == set()


async def test_list_search_combines_with_region_filter(client, db_engine):
    ids = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    assert await _codes(c, search="Karimov", region="Namangan") == {ids["t2"]}
    assert await _codes(c, search="Karimov", region="Farg'ona") == set()
    assert await _codes(c, search="K-4471", region="Farg'ona") == {ids["t1"]}


async def test_summary_cards_follow_new_search_fields(client, db_engine):
    await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    s = (await c.get(f"{API}/summary", params={"search": "K-5590"})).json()
    assert (s["total"], s["new"], s["completed"]) == (1, 0, 1)


# --------------------------------------------------------------------------- #
# Yangi ariza oynasi — mijoz qidiruvi
# --------------------------------------------------------------------------- #
async def test_customer_search_by_manual_order_id_attaches_order(client, db_engine):
    ids = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    r = await c.get(f"{API}/customer-search", params={"q": "k-4471"})
    assert r.status_code == 200, r.text
    hits = r.json()
    assert hits[0]["customer_id"] == ids["nodir"]
    assert hits[0]["order_id"] == ids["o1"]
    assert hits[0]["unit_uid"] == "K-4471"
    assert hits[0]["order_code"] == "2026-00156"


async def test_customer_search_by_phone2_and_address(client, db_engine):
    ids = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    for q in ("93 777 11 22", "Rishton", "nodirbek"):
        hits = (await c.get(f"{API}/customer-search", params={"q": q})).json()
        assert [h["customer_id"] for h in hits] == [ids["nodir"]], q


async def test_customer_search_by_order_code_still_works(client, db_engine):
    ids = await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["service:read"]))

    hits = (await c.get(f"{API}/customer-search", params={"q": "2026-00200"})).json()
    assert hits[0]["customer_id"] == ids["aziz"]
    assert hits[0]["unit_uid"] == "K-5590"


async def test_search_requires_service_permission(client, db_engine):
    await _seed(db_engine)
    c = _auth(client, await _user(db_engine, ["orders:read"]))

    assert (await c.get(f"{API}/tickets", params={"search": "K-4471"})).status_code == 403
    assert (await c.get(f"{API}/customer-search", params={"q": "K-4471"})).status_code == 403
