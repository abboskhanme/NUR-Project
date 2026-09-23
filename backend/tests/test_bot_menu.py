"""Telegram bot menyusi — buyruq tekshiruvi (unit) va API (integration).

Unit qism DB talab qilmaydi. Integration qism TEST_DATABASE_URL bo'lsa ishlaydi:
  • RBAC: `telegram` ruxsatisiz xodim menyuni ko'ra ham, o'zgartira ham olmaydi
  • CRUD + rasm yuklash + tartib
  • Agent endpointi: faqat X-Agent-Key bilan, faqat faol bo'limlar
"""
import uuid

import pytest
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.schemas.bot_menu import BotMenuItemCreate, BotMenuItemUpdate
from tests.conftest import requires_db

API = "/api/v1/bot-menu"
KEY = "test-agent-key"
HDR = {"X-Agent-Key": KEY}
# 1x1 PNG
PNG = bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010806000000"
    "1f15c4890000000d49444154789c6360000002000154a24f5d0000000049454e44ae426082"
)


# --------------------------------------------------------------------------- #
# Unit: buyruq nomini tozalash
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize("raw,expected", [
    ("narxlar", "narxlar"),
    ("/Narxlar", "narxlar"),
    ("  yetkazib_berish ", "yetkazib_berish"),
    ("aloqa2", "aloqa2"),
])
def test_command_is_normalized(raw, expected):
    item = BotMenuItemCreate(command=raw, title="Narxlar")
    assert item.command == expected


@pytest.mark.parametrize("raw", [
    "", "narx lar", "narxlar!", "нарх", "a" * 33,
    "start", "/menu",          # bot o'zi ishlatadi
])
def test_invalid_or_reserved_command_rejected(raw):
    with pytest.raises(ValidationError):
        BotMenuItemCreate(command=raw, title="Narxlar")


def test_text_length_counts_emoji_like_telegram():
    """Telegram 4096 chegarasini UTF-16 da sanaydi — 2100 ta emoji = 4200 birlik."""
    BotMenuItemCreate(command="narxlar", title="Narxlar", text="x" * 4096)
    with pytest.raises(ValidationError):
        BotMenuItemCreate(command="narxlar", title="Narxlar", text="💰" * 2100)
    with pytest.raises(ValidationError):
        BotMenuItemUpdate(text="💰" * 2100)


def test_blank_title_rejected():
    with pytest.raises(ValidationError):
        BotMenuItemCreate(command="narxlar", title="   ")
    with pytest.raises(ValidationError):
        BotMenuItemUpdate(title="  ")


# --------------------------------------------------------------------------- #
# Integration
# --------------------------------------------------------------------------- #
async def _user(db_engine, permissions):
    from app.models.user import Role, User

    Session = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as db:
        role = Role(name=f"role-{uuid.uuid4().hex[:8]}",
                    permissions={"permissions": permissions})
        db.add(role)
        await db.flush()
        user = User(phone=f"+9989{uuid.uuid4().int % 10**8:08d}", password_hash="x",
                    full_name="Xodim", is_active=True, token_version=0)
        user.roles = [role]
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user


def _login(user):
    from app.core.dependencies import get_current_user
    from app.main import app

    async def _override():
        return user

    app.dependency_overrides[get_current_user] = _override


def over_ids(menu_response, item_id, *, keep):
    item = next(i for i in menu_response.json()["items"] if i["id"] == item_id)
    return [img["id"] for img in item["images"] if img["id"] != keep]


@pytest.fixture
def no_agent(monkeypatch):
    """Agentga «yangila» xabari testda tarmoqqa chiqmasin."""
    from app.api.v1 import bot_menu

    calls: list[int] = []

    async def fake_notify():
        calls.append(1)

    monkeypatch.setattr(bot_menu, "_notify_agent", fake_notify)
    return calls


@requires_db
async def test_rbac_requires_telegram_permission(client, db_engine, no_agent):
    outsider = await _user(db_engine, ["orders:read", "orders:write"])
    _login(outsider)
    assert (await client.get(API)).status_code == 403
    r = await client.post(f"{API}/items", json={"command": "narxlar", "title": "Narxlar"})
    assert r.status_code == 403

    reader = await _user(db_engine, ["telegram:read"])
    _login(reader)
    assert (await client.get(API)).status_code == 200
    r = await client.post(f"{API}/items", json={"command": "narxlar", "title": "Narxlar"})
    assert r.status_code == 403, "faqat o'qish ruxsati bilan yaratib bo'lmasligi kerak"
    assert no_agent == []


@requires_db
async def test_crud_images_and_order(client, db_engine, no_agent):
    admin = await _user(db_engine, ["telegram:read", "telegram:write", "telegram:delete"])
    _login(admin)

    a = await client.post(f"{API}/items", json={
        "command": "/Narxlar", "title": "💰 Narxlar", "text": "Kotyol 50L — 1 200 000 so'm"})
    assert a.status_code == 201, a.text
    assert a.json()["command"] == "narxlar"
    b = await client.post(f"{API}/items", json={"command": "manzil", "title": "📍 Manzil"})
    assert b.status_code == 201
    a_id, b_id = a.json()["id"], b.json()["id"]

    dup = await client.post(f"{API}/items", json={"command": "narxlar", "title": "Boshqa"})
    assert dup.status_code == 409
    same_title = await client.post(f"{API}/items", json={"command": "narx2", "title": "💰 NARXLAR"})
    assert same_title.status_code == 409, "bir xil tugma nomi — ikkinchisi hech qachon tanlanmas edi"

    # Rasm yuklash
    up = await client.post(f"{API}/items/{a_id}/images",
                           files={"file": ("narx.png", PNG, "image/png")})
    assert up.status_code == 201, up.text
    images = up.json()["images"]
    assert len(images) == 1 and images[0]["content_type"] == "image/png"
    img = await client.get(f"{API}/images/{images[0]['id']}")
    assert img.status_code == 200 and img.content == PNG

    # 10 tadan ortiq rasm — Telegram albomi qabul qilmaydi
    for _ in range(9):
        r = await client.post(f"{API}/items/{a_id}/images",
                              files={"file": ("n.png", PNG, "image/png")})
        assert r.status_code == 201
    over = await client.post(f"{API}/items/{a_id}/images",
                             files={"file": ("n.png", PNG, "image/png")})
    assert over.status_code == 400
    for extra in over_ids(await client.get(API), a_id, keep=images[0]["id"]):
        assert (await client.delete(f"{API}/images/{extra}")).status_code == 204

    bad = await client.post(f"{API}/items/{a_id}/images",
                            files={"file": ("x.pdf", b"%PDF", "application/pdf")})
    assert bad.status_code == 400

    # Tahrirlash: boshqa bo'limning buyrug'ini olib bo'lmaydi
    clash = await client.patch(f"{API}/items/{b_id}", json={"command": "narxlar"})
    assert clash.status_code == 409
    upd = await client.patch(f"{API}/items/{b_id}", json={"text": "Toshkent, Chilonzor", "is_active": False})
    assert upd.status_code == 200 and upd.json()["is_active"] is False

    # Tartib
    order = await client.post(f"{API}/reorder", json={"ids": [b_id, a_id]})
    assert order.status_code == 200
    assert [i["id"] for i in order.json()["items"]] == [b_id, a_id]
    stale = await client.post(f"{API}/reorder", json={"ids": [a_id]})
    assert stale.status_code == 400

    # Salomlashish matni
    g = await client.put(f"{API}/greeting", json={"greeting": "Assalomu alaykum!"})
    assert g.status_code == 200 and g.json()["greeting"] == "Assalomu alaykum!"

    # Rasmni va bo'limni o'chirish
    assert (await client.delete(f"{API}/images/{images[0]['id']}")).status_code == 204
    assert (await client.delete(f"{API}/items/{a_id}")).status_code == 204
    menu = (await client.get(API)).json()
    assert [i["id"] for i in menu["items"]] == [b_id]

    assert len(no_agent) >= 8, "har o'zgarishdan keyin agentga xabar berilishi kerak"


@requires_db
async def test_agent_endpoint_returns_only_active_items(client, db_engine, no_agent):
    from app.core.config import settings
    settings.AGENT_INGEST_KEY = KEY

    admin = await _user(db_engine, ["telegram:read", "telegram:write"])
    _login(admin)
    a = (await client.post(f"{API}/items", json={
        "command": "narxlar", "title": "Narxlar", "text": "Narxlar ro'yxati"})).json()
    await client.post(f"{API}/items", json={
        "command": "yashirin", "title": "Yashirin", "is_active": False})
    up = (await client.post(f"{API}/items/{a['id']}/images",
                            files={"file": ("n.png", PNG, "image/png")})).json()
    image_id = up["images"][0]["id"]

    assert (await client.get(f"{API}/agent")).status_code == 401
    assert (await client.get(f"{API}/agent", headers={"X-Agent-Key": "noto'g'ri"})).status_code == 401

    r = await client.get(f"{API}/agent", headers=HDR)
    assert r.status_code == 200, r.text
    data = r.json()
    assert [i["command"] for i in data["items"]] == ["narxlar"]
    img = data["items"][0]["images"][0]
    assert img["id"] == image_id and len(img["sha256"]) == 64

    raw = await client.get(f"{API}/agent/images/{image_id}", headers=HDR)
    assert raw.status_code == 200 and raw.content == PNG
    assert (await client.get(f"{API}/agent/images/{image_id}")).status_code == 401
