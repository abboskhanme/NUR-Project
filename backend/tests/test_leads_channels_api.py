"""Leadlar API — kanal bo'yicha yo'naltirish (Instagram / Telegram / WhatsApp).

Bu endpointlar kanal mantig'i BITTA jadvalga (CHANNEL_COLUMNS) ko'chirilganda
qayta yozilgan, shuning uchun har bir yo'l alohida tekshiriladi:

  POST /leads/ingest           — lead qaysi ustunlarga yoziladi
  POST /leads/ingest/message   — suhbat jurnali, dedup, telefon ajratish
  GET  /leads/ingest/context   — AI uchun tarix (kanal bo'yicha ajratilgan)
  GET  /leads/inbox            — kanal filtri va javob oynasi

Eng muhimi: bir kanaldagi lead BOSHQA kanalga sizib o'tmasligi kerak.

Integration test — Postgres kerak (TEST_DATABASE_URL).
"""
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from tests.conftest import requires_db

pytestmark = requires_db

API = "/api/v1/leads"
KEY = "test-agent-key"
HDR = {"X-Agent-Key": KEY}


def _agent_key(monkeypatch=None):
    """Ingest endpointlari uchun servis kalitini o'rnatadi."""
    from app.core.config import settings
    settings.AGENT_INGEST_KEY = KEY


async def _staff(db_engine):
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}",
                    permissions={"permissions": ["leads:read", "leads:write"]})
        db.add(role)
        await db.flush()
        user = User(phone=f"+9989{uuid.uuid4().int % 10**8:08d}", password_hash="x",
                    full_name="Operator", is_active=True, token_version=0)
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


# --------------------------------------------------------------------------- #
# POST /leads/ingest — kanal ustunlari
# --------------------------------------------------------------------------- #
async def test_ingest_writes_channel_specific_columns(client, db_engine):
    _agent_key()
    cases = {
        "instagram": ("ig_user_id", "ig_username"),
        "telegram": ("tg_user_id", "tg_username"),
        "whatsapp": ("wa_user_id", "wa_username"),
    }
    from app.models.lead import Lead

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    for channel, (id_field, name_field) in cases.items():
        uid = f"{channel}-{uuid.uuid4().hex[:8]}"
        r = await client.post(f"{API}/ingest", headers=HDR, json={
            "channel": channel, "user_id": uid, "username": f"nomi-{channel}",
            "message_text": "Narxi qancha?", "agent_reply": "Salom!",
            "lead_score": 55,
        })
        assert r.status_code == 201, r.text

        async with Session() as db:
            lead = await db.get(Lead, uuid.UUID(r.json()["id"]))
            assert getattr(lead, id_field) == uid, f"{channel}: ID noto'g'ri ustunda"
            assert getattr(lead, name_field) == f"nomi-{channel}"
            # Boshqa kanallarning ustunlari BO'SH qolishi shart
            for other, (oid, oname) in cases.items():
                if other == channel:
                    continue
                assert getattr(lead, oid) is None, f"{channel} leadi {other} ustuniga yozildi"
                assert getattr(lead, oname) is None
            assert lead.source == channel


async def test_ingest_same_id_in_two_channels_creates_two_leads(client, db_engine):
    """Bir xil ID Telegram va WhatsAppda — bu IKKI boshqa odam, aralashmasin."""
    _agent_key()
    uid = f"998{uuid.uuid4().int % 10**9:09d}"

    tg = await client.post(f"{API}/ingest", headers=HDR, json={
        "channel": "telegram", "user_id": uid, "message_text": "salom"})
    wa = await client.post(f"{API}/ingest", headers=HDR, json={
        "channel": "whatsapp", "user_id": uid, "message_text": "salom"})
    assert tg.status_code == 201 and wa.status_code == 201
    assert tg.json()["id"] != wa.json()["id"]
    assert wa.json()["duplicate"] is False


async def test_ingest_second_message_reuses_open_lead(client, db_engine):
    _agent_key()
    uid = f"wa-{uuid.uuid4().hex[:8]}"
    first = await client.post(f"{API}/ingest", headers=HDR, json={
        "channel": "whatsapp", "user_id": uid, "message_text": "salom"})
    second = await client.post(f"{API}/ingest", headers=HDR, json={
        "channel": "whatsapp", "user_id": uid, "message_text": "narxi?",
        "name": "Nabijon"})
    assert first.json()["id"] == second.json()["id"]
    assert second.json()["duplicate"] is True


async def test_ingest_requires_agent_key(client):
    _agent_key()
    r = await client.post(f"{API}/ingest", json={"channel": "whatsapp", "user_id": "1"})
    assert r.status_code == 401


# --------------------------------------------------------------------------- #
# POST /leads/ingest/message + GET /leads/ingest/context
# --------------------------------------------------------------------------- #
async def test_message_log_and_context_round_trip(client):
    _agent_key()
    uid = f"998{uuid.uuid4().int % 10**9:09d}"

    for role, text in (("user", "Salom, kotyol kerak"), ("assistant", "Qaysi hajmda?")):
        r = await client.post(f"{API}/ingest/message", headers=HDR, json={
            "channel": "whatsapp", "user_id": uid, "username": "Nabijon",
            "role": role, "text": text, "kind": "dm",
        })
        assert r.status_code == 201, r.text
        assert r.json()["logged"] is True

    ctx = await client.get(f"{API}/ingest/context", headers=HDR,
                           params={"user_id": uid, "channel": "whatsapp"})
    assert ctx.status_code == 200, ctx.text
    body = ctx.json()
    assert body["channel"] == "whatsapp"
    assert body["username"] == "Nabijon"
    assert [m["content"] for m in body["messages"]] == [
        "Salom, kotyol kerak", "Qaysi hajmda?"]
    assert [m["role"] for m in body["messages"]] == ["user", "assistant"]


async def test_context_is_isolated_between_channels(client):
    """WhatsApp suhbati Telegram kontekstiga tushmasligi kerak."""
    _agent_key()
    uid = f"998{uuid.uuid4().int % 10**9:09d}"
    await client.post(f"{API}/ingest/message", headers=HDR, json={
        "channel": "whatsapp", "user_id": uid, "role": "user", "text": "WhatsAppdan"})

    tg = await client.get(f"{API}/ingest/context", headers=HDR,
                          params={"user_id": uid, "channel": "telegram"})
    assert tg.status_code == 200
    assert tg.json()["messages"] == [], "kanallar aralashib ketdi"


async def test_message_dedup_by_message_id(client):
    _agent_key()
    uid = f"998{uuid.uuid4().int % 10**9:09d}"
    payload = {"channel": "whatsapp", "user_id": uid, "role": "user",
               "text": "takror", "ig_message_id": "wamid.42"}
    first = await client.post(f"{API}/ingest/message", headers=HDR, json=payload)
    second = await client.post(f"{API}/ingest/message", headers=HDR, json=payload)
    assert first.json()["logged"] is True
    assert second.json()["logged"] is False and second.json()["duplicate"] is True


async def test_phone_extracted_from_customer_message(client):
    _agent_key()
    uid = f"998{uuid.uuid4().int % 10**9:09d}"
    r = await client.post(f"{API}/ingest/message", headers=HDR, json={
        "channel": "whatsapp", "user_id": uid, "role": "user",
        "text": "Raqamim +998 90 111 22 33, qo'ng'iroq qiling"})
    assert r.status_code == 201

    ctx = await client.get(f"{API}/ingest/context", headers=HDR,
                           params={"user_id": uid, "channel": "whatsapp"})
    assert ctx.json()["contact"] == "+998901112233"


# --------------------------------------------------------------------------- #
# GET /leads/inbox — kanal filtri va javob oynasi
# --------------------------------------------------------------------------- #
async def _seed_inbox(db_engine, channel: str, *, ago_hours: float = 1.0):
    """Berilgan kanalda mijoz xabari bo'lgan lead yaratadi."""
    from app.models.lead import Lead, LeadEvent

    cols = {"instagram": ("ig_user_id", "ig_username"),
            "telegram": ("tg_user_id", "tg_username"),
            "whatsapp": ("wa_user_id", "wa_username")}[channel]
    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        lead = Lead(source=channel, status="new")
        setattr(lead, cols[0], f"{channel}-{uuid.uuid4().hex[:8]}")
        setattr(lead, cols[1], f"nomi-{channel}")
        db.add(lead)
        await db.flush()
        ev = LeadEvent(lead_id=lead.id, kind="dm", message_text="Salom", actor="user")
        ev.created_at = datetime.now(timezone.utc) - timedelta(hours=ago_hours)
        db.add(ev)
        await db.commit()
        await db.refresh(lead)
        return lead


async def test_inbox_channel_filter(client, db_engine):
    ig = await _seed_inbox(db_engine, "instagram")
    tg = await _seed_inbox(db_engine, "telegram")
    wa = await _seed_inbox(db_engine, "whatsapp")
    c = _auth(client, await _staff(db_engine))

    async def ids(channel: str) -> set:
        r = await c.get(f"{API}/inbox", params={"channel": channel})
        assert r.status_code == 200, r.text
        return {row["lead_id"] for row in r.json()}

    assert await ids("whatsapp") == {str(wa.id)}
    assert await ids("telegram") == {str(tg.id)}
    assert await ids("instagram") == {str(ig.id)}, "WhatsApp leadi Instagramga tushdi"

    everything = await c.get(f"{API}/inbox")
    assert {str(ig.id), str(tg.id), str(wa.id)} <= {r["lead_id"] for r in everything.json()}


async def test_inbox_reports_channel_and_user_id(client, db_engine):
    wa = await _seed_inbox(db_engine, "whatsapp")
    c = _auth(client, await _staff(db_engine))

    row = next(r for r in (await c.get(f"{API}/inbox", params={"channel": "whatsapp"})).json()
               if r["lead_id"] == str(wa.id))
    assert row["channel"] == "whatsapp"
    assert row["user_id"] == wa.wa_user_id
    assert row["username"] == wa.wa_username


async def test_inbox_window_rules_per_channel(client, db_engine):
    """Telegram — doim ochiq; WhatsApp — 24 soatdan keyin yopiq;
    Instagram — 24 soatdan keyin hali 7 kungacha operator uchun ochiq."""
    old = 30.0   # soat — 24 dan katta, 7 kundan kichik
    tg = await _seed_inbox(db_engine, "telegram", ago_hours=old)
    wa = await _seed_inbox(db_engine, "whatsapp", ago_hours=old)
    ig = await _seed_inbox(db_engine, "instagram", ago_hours=old)
    c = _auth(client, await _staff(db_engine))

    rows = {r["lead_id"]: r["window"] for r in (await c.get(f"{API}/inbox")).json()}
    assert rows[str(tg.id)] == "open"
    assert rows[str(wa.id)] == "closed"
    assert rows[str(ig.id)] == "human_agent"


async def test_inbox_requires_permission(client, db_engine):
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}",
                    permissions={"permissions": ["orders:read"]})
        db.add(role)
        await db.flush()
        user = User(phone=f"+9989{uuid.uuid4().int % 10**8:08d}", password_hash="x",
                    full_name="Begona", is_active=True, token_version=0)
        user.roles = [role]
        db.add(user)
        await db.commit()
        await db.refresh(user)

    c = _auth(client, user)
    assert (await c.get(f"{API}/inbox")).status_code == 403
