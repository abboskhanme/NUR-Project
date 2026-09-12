"""WhatsApp kanali — webhookni o'qish, AI javobi, operator aralashuvi."""
from __future__ import annotations

import asyncio
import hashlib
import hmac
import json

from fastapi.testclient import TestClient

from app.config import settings
from app.instagram.models import IncomingEvent
from app.models import AgentOutput, LeadInfo
from app.state.store import store
from app.whatsapp.client import whatsapp
from app.whatsapp.models import parse_webhook

CUSTOMER = "998901112233"
APP_SECRET = "wa-app-secret"


def _payload(message: dict, *, contacts: bool = True, echo: bool = False) -> dict:
    value: dict = {
        "messaging_product": "whatsapp",
        "metadata": {"display_phone_number": "998900000000", "phone_number_id": "PN1"},
    }
    if contacts:
        value["contacts"] = [{"wa_id": CUSTOMER, "profile": {"name": "Ali"}}]
    value["message_echoes" if echo else "messages"] = [message]
    return {"object": "whatsapp_business_account",
            "entry": [{"id": "WABA", "changes": [{"field": "messages", "value": value}]}]}


def _text_msg(body: str, *, mid: str = "wamid.1") -> dict:
    return {"from": CUSTOMER, "id": mid, "timestamp": "1700000000",
            "type": "text", "text": {"body": body}}


def _out(reply="Salom! Qanday yordam beray?") -> AgentOutput:
    return AgentOutput(
        reply=reply, language="uz-Latn", intent="greeting", lead_score=30,
        is_hot_lead=False, move_to_dm=False, escalate_to_human=False, lead=LeadInfo(),
    )


# --------------------------------------------------------------------------- #
# Webhook payload -> IncomingEvent
# --------------------------------------------------------------------------- #
def test_customer_message_becomes_dm_event():
    events = parse_webhook(_payload(_text_msg("Narxi qancha?")))
    assert len(events) == 1
    ev = events[0]
    assert ev.channel == "whatsapp" and ev.kind == "dm"
    assert ev.sender_id == CUSTOMER and ev.text == "Narxi qancha?"
    assert ev.username == "Ali"
    assert ev.store_key == f"wa:{CUSTOMER}"
    assert ev.dedup_key == f"wa:{CUSTOMER}:wamid.1"


def test_media_message_kept_with_placeholder():
    msg = {"from": CUSTOMER, "id": "wamid.2", "type": "audio", "audio": {"id": "m1"}}
    events = parse_webhook(_payload(msg))
    assert len(events) == 1
    assert "ovozli xabar" in events[0].text and events[0].has_attachment is True


def test_media_caption_is_used_as_text():
    msg = {"from": CUSTOMER, "id": "wamid.3", "type": "image",
           "image": {"id": "m2", "caption": "Shu modeldan bormi?"}}
    events = parse_webhook(_payload(msg))
    assert events[0].text == "Shu modeldan bormi?"


def test_button_reply_is_read_as_text():
    msg = {"from": CUSTOMER, "id": "wamid.4", "type": "interactive",
           "interactive": {"type": "button_reply",
                           "button_reply": {"id": "b1", "title": "Ha, qiziqaman"}}}
    assert parse_webhook(_payload(msg))[0].text == "Ha, qiziqaman"


def test_statuses_are_ignored():
    payload = {"entry": [{"changes": [{"value": {
        "statuses": [{"id": "wamid.9", "status": "delivered"}]}}]}]}
    assert parse_webhook(payload) == []


def test_our_own_message_becomes_echo():
    """Operator telefondan yozsa — echo, ya'ni bot o'sha suhbatda jim turishi kerak."""
    msg = {"to": CUSTOMER, "id": "wamid.5", "type": "text",
           "text": {"body": "Men menejerman"}}
    events = parse_webhook(_payload(msg, echo=True))
    assert len(events) == 1 and events[0].kind == "echo"
    assert events[0].sender_id == CUSTOMER


# --------------------------------------------------------------------------- #
# Pipeline: WhatsApp orqali javob
# --------------------------------------------------------------------------- #
def _patch_pipeline(monkeypatch, sent: list, logged: list):
    from app.processing import pipeline

    async def fake_send(to, text):
        sent.append({"to": to, "text": text})
        return {"sent": True}

    async def fake_log(**kwargs):
        logged.append(kwargs)
        return True

    async def fake_context(user_id, limit=40, *, channel="instagram"):
        assert channel == "whatsapp"
        return None

    async def fake_handle(text, **kwargs):
        assert kwargs.get("channel") == "whatsapp"
        return _out()

    async def noop(*a, **k):
        return {}

    monkeypatch.setattr(pipeline.whatsapp, "send_message", fake_send)
    monkeypatch.setattr(pipeline.whatsapp, "mark_read", noop)
    monkeypatch.setattr(pipeline.leads_client, "log_message", fake_log)
    monkeypatch.setattr(pipeline.leads_client, "fetch_context", fake_context)
    monkeypatch.setattr(pipeline.leads_client, "push", noop)
    monkeypatch.setattr(pipeline._agent, "handle", fake_handle)
    monkeypatch.setattr(pipeline.notifier, "notify_hot_lead", noop)
    return pipeline


def test_pipeline_replies_via_whatsapp(monkeypatch):
    sent: list[dict] = []
    logged: list[dict] = []
    pipeline = _patch_pipeline(monkeypatch, sent, logged)

    event = IncomingEvent(kind="dm", text="Salom", sender_id=CUSTOMER,
                          channel="whatsapp", chat_id=CUSTOMER, message_id="wamid.7")
    asyncio.run(pipeline.process_event(event))

    assert len(sent) == 1 and sent[0]["to"] == CUSTOMER, sent
    assert "AI yordamchisi" in sent[0]["text"], "birinchi xabarda oshkorlik bo'lishi kerak"
    assert [i["channel"] for i in logged] == ["whatsapp", "whatsapp"]
    assert [i["role"] for i in logged] == ["user", "assistant"]

    async def check():
        assert await store.was_sent_by_bot(f"wa:{CUSTOMER}", sent[0]["text"]) is True
    asyncio.run(check())


def test_ai_disabled_still_logs_but_does_not_reply(monkeypatch):
    """«AI javob» o'chirilganda xabar jurnalga tushadi, lekin javob ketmaydi."""
    sent: list[dict] = []
    logged: list[dict] = []
    pipeline = _patch_pipeline(monkeypatch, sent, logged)

    event = IncomingEvent(kind="dm", text="Salom", sender_id="998900000009",
                          channel="whatsapp", message_id="wamid.8")
    asyncio.run(pipeline.process_event(event, reply=False))

    assert sent == []
    assert [i["role"] for i in logged] == ["user"]


def test_operator_message_pauses_bot(monkeypatch):
    from app.processing import pipeline

    async def fake_log(**kwargs):
        return True

    monkeypatch.setattr(pipeline.leads_client, "log_message", fake_log)

    event = IncomingEvent(kind="echo", text="Men javob beraman",
                          sender_id="998901110000", channel="whatsapp")
    asyncio.run(pipeline.process_event(event))

    async def check():
        assert await store.is_paused("wa:998901110000") is True
    asyncio.run(check())


# --------------------------------------------------------------------------- #
# Webhook va ERP uchun endpointlar
# --------------------------------------------------------------------------- #
def _client(monkeypatch, *, ai_enabled: bool = True) -> TestClient:
    monkeypatch.setattr(settings, "AGENT_INGEST_KEY", "k1")
    monkeypatch.setattr(settings, "WA_AI_ENABLED", ai_enabled)
    monkeypatch.setattr(settings, "WA_VERIFY_TOKEN", "verify-me")
    monkeypatch.setattr(settings, "WA_APP_SECRET", APP_SECRET)
    monkeypatch.setattr(settings, "WA_PHONE_NUMBER_ID", "PN1")
    monkeypatch.setattr(settings, "WA_ACCESS_TOKEN", "tok")
    from app.main import app
    return TestClient(app)


def _signed(body: dict) -> tuple[bytes, dict]:
    raw = json.dumps(body).encode()
    mac = hmac.new(APP_SECRET.encode(), raw, hashlib.sha256).hexdigest()
    return raw, {"X-Hub-Signature-256": f"sha256={mac}", "Content-Type": "application/json"}


def test_webhook_verification(monkeypatch):
    with _client(monkeypatch) as c:
        ok = c.get("/webhook/whatsapp", params={
            "hub.mode": "subscribe", "hub.verify_token": "verify-me",
            "hub.challenge": "12345"})
        assert ok.status_code == 200 and ok.text == "12345"

        bad = c.get("/webhook/whatsapp", params={
            "hub.mode": "subscribe", "hub.verify_token": "boshqa",
            "hub.challenge": "12345"})
        assert bad.status_code == 403


def test_webhook_rejects_bad_signature(monkeypatch):
    with _client(monkeypatch) as c:
        raw, _ = _signed(_payload(_text_msg("salom")))
        r = c.post("/webhook/whatsapp", content=raw,
                   headers={"X-Hub-Signature-256": "sha256=deadbeef",
                            "Content-Type": "application/json"})
        assert r.status_code == 403


def test_webhook_accepts_signed_payload(monkeypatch):
    seen: list = []

    async def fake_process(event, **kwargs):
        seen.append((event, kwargs))

    monkeypatch.setattr("app.whatsapp.webhook.process_event", fake_process)
    with _client(monkeypatch) as c:
        raw, headers = _signed(_payload(_text_msg("salom", mid="wamid.100")))
        r = c.post("/webhook/whatsapp", content=raw, headers=headers)
        assert r.status_code == 200, r.text

    assert len(seen) == 1
    event, kwargs = seen[0]
    assert event.channel == "whatsapp" and kwargs["reply"] is True


def test_webhook_disabled_ai_passes_reply_false(monkeypatch):
    seen: list = []

    async def fake_process(event, **kwargs):
        seen.append(kwargs)

    monkeypatch.setattr("app.whatsapp.webhook.process_event", fake_process)
    with _client(monkeypatch, ai_enabled=False) as c:
        raw, headers = _signed(_payload(_text_msg("salom", mid="wamid.101")))
        assert c.post("/webhook/whatsapp", content=raw, headers=headers).status_code == 200

    assert seen and seen[0]["reply"] is False


def test_send_whatsapp_endpoint(monkeypatch):
    async def fake_send(to, text):
        return {"sent": True, "message_id": "wamid.200"}

    monkeypatch.setattr(whatsapp, "send_message", fake_send)

    with _client(monkeypatch) as c:
        r = c.post("/admin/send-whatsapp", headers={"X-Agent-Key": "k1"},
                   json={"wa_user_id": "998905550000", "text": "Menejer yozyapti"})
        assert r.status_code == 200 and r.json()["sent"] is True, r.text
        assert c.post("/admin/send-whatsapp",
                      json={"wa_user_id": "1", "text": "x"}).status_code == 401

    async def check():
        # Operator yozdi -> AI o'sha suhbatda jim turadi
        assert await store.is_paused("wa:998905550000") is True
    asyncio.run(check())
