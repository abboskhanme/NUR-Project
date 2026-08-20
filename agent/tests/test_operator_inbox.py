"""ERP "Yozishmalar" bo'limi uchun agent endpointlari (tarmoqsiz)."""
from __future__ import annotations

import asyncio

from fastapi.testclient import TestClient

from app.config import settings
from app.instagram.client import instagram
from app.main import app
from app.state.store import store

KEY = {"X-Agent-Key": "k1"}


def _client(monkeypatch) -> TestClient:
    monkeypatch.setattr(settings, "AGENT_INGEST_KEY", "k1")
    monkeypatch.setattr(settings, "IG_ACCESS_TOKEN", "token")
    return TestClient(app)


# --------------------------------------------------------------------------- #
# send_dm_result — 24 soatlik oyna va HUMAN_AGENT tegi
# --------------------------------------------------------------------------- #
def test_send_ok(monkeypatch):
    async def fake_post(path, json):
        assert "tag" not in json
        return 200, {"message_id": "m1"}

    monkeypatch.setattr(instagram, "_post_once", fake_post)
    res = asyncio.run(instagram.send_dm_result("u1", "Salom"))
    assert res == {"sent": True, "tag": None}, res


def test_window_error_retries_with_human_agent_tag(monkeypatch):
    calls = []

    async def fake_post(path, json):
        calls.append(json.get("tag"))
        if len(calls) == 1:
            return 400, {"error": {"code": 10,
                                   "message": "This message is sent outside of allowed window"}}
        return 200, {"message_id": "m2"}

    monkeypatch.setattr(instagram, "_post_once", fake_post)
    res = asyncio.run(instagram.send_dm_result("u1", "Kechikkanimiz uchun uzr"))
    assert res == {"sent": True, "tag": "HUMAN_AGENT"}, res
    assert calls == [None, "HUMAN_AGENT"], calls


def test_other_error_returns_reason(monkeypatch):
    async def fake_post(path, json):
        return 400, {"error": {"code": 100, "message": "Invalid recipient"}}

    monkeypatch.setattr(instagram, "_post_once", fake_post)
    res = asyncio.run(instagram.send_dm_result("u1", "Salom"))
    assert res["sent"] is False and "Invalid recipient" in res["error"], res


def test_human_agent_requested_directly(monkeypatch):
    seen = {}

    async def fake_post(path, json):
        seen.update(json)
        return 200, {}

    monkeypatch.setattr(instagram, "_post_once", fake_post)
    res = asyncio.run(instagram.send_dm_result("u1", "Salom", human_agent=True))
    assert res["tag"] == "HUMAN_AGENT"
    assert seen["messaging_type"] == "MESSAGE_TAG" and seen["tag"] == "HUMAN_AGENT"


# --------------------------------------------------------------------------- #
# Endpointlar
# --------------------------------------------------------------------------- #
def test_send_dm_endpoint_requires_key(monkeypatch):
    with _client(monkeypatch) as c:
        r = c.post("/admin/send-dm", json={"ig_user_id": "u1", "text": "salom"})
        assert r.status_code == 401
        r2 = c.post("/admin/send-dm", headers={"X-Agent-Key": "boshqa"},
                    json={"ig_user_id": "u1", "text": "salom"})
        assert r2.status_code == 401


def test_send_dm_pauses_bot_and_marks_sent(monkeypatch):
    async def fake_send(recipient_id, message, *, human_agent=False):
        return {"sent": True, "tag": "HUMAN_AGENT" if human_agent else None}

    monkeypatch.setattr(instagram, "send_dm_result", fake_send)

    with _client(monkeypatch) as c:
        r = c.post("/admin/send-dm", headers=KEY,
                   json={"ig_user_id": "cust_x", "text": "Narxi 12 mln"})
        assert r.status_code == 200 and r.json()["sent"] is True, r.text

    async def checks():
        # Operator yozdi -> AI o'sha suhbatda jim turadi
        assert await store.is_paused("cust_x") is True
        # Xabar echo bo'lib qaytganda ikkinchi marta yozilmasin
        assert await store.was_sent_by_bot("cust_x", "Narxi 12 mln") is True

    asyncio.run(checks())


def test_empty_text_rejected(monkeypatch):
    with _client(monkeypatch) as c:
        r = c.post("/admin/send-dm", headers=KEY, json={"ig_user_id": "u1", "text": "  "})
        assert r.status_code == 400


def test_bot_pause_and_resume(monkeypatch):
    with _client(monkeypatch) as c:
        off = c.post("/admin/bot-pause", headers=KEY,
                     json={"ig_user_id": "cust_b", "enabled": False})
        assert off.json()["paused"] is True, off.text

        state = c.get("/admin/bot-state", headers=KEY, params={"ig_user_id": "cust_b"})
        assert state.json()["paused"] is True

        on = c.post("/admin/bot-pause", headers=KEY,
                    json={"ig_user_id": "cust_b", "enabled": True})
        assert on.json()["paused"] is False, on.text
