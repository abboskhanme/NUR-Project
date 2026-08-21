"""Suhbat xotirasi — ERP jurnali, ma'lum faktlar va matnsiz xabarlar.

Tarmoqsiz: ERP klienti va Instagram monkeypatch qilinadi.
"""
from __future__ import annotations

import asyncio

from app.agent.core import _normalize_history
from app.instagram.models import IncomingEvent, parse_webhook
from app.models import AgentOutput, LeadInfo


def _out(reply: str = "Yaxshi, tushundim") -> AgentOutput:
    return AgentOutput(
        reply=reply, language="uz-Cyrl", intent="product_question", lead_score=50,
        is_hot_lead=False, move_to_dm=False, escalate_to_human=False, lead=LeadInfo(),
    )


# --------------------------------------------------------------------------- #
# Tarixni AI API formatiga keltirish
# --------------------------------------------------------------------------- #
def test_history_normalized_for_ai():
    raw = [
        {"role": "assistant", "content": "Salom!", "at": "2026-08-01T10:00:00Z"},  # tashlanadi
        {"role": "user", "content": "Narxi qancha?", "at": "2026-08-01T10:01:00Z"},
        {"role": "user", "content": "300 kvm uchun", "at": "2026-08-01T10:02:00Z"},
        {"role": "operator", "content": "Hozir aytaman", "at": "2026-08-01T10:03:00Z"},
        {"role": "assistant", "content": "", "at": "2026-08-01T10:04:00Z"},        # bo'sh
    ]
    out = _normalize_history(raw)
    assert out == [
        {"role": "user", "content": "Narxi qancha?\n300 kvm uchun"},
        {"role": "assistant", "content": "Hozir aytaman"},
    ], out


# --------------------------------------------------------------------------- #
# Matnsiz xabarlar (ovoz/rasm) endi yo'qolmaydi
# --------------------------------------------------------------------------- #
def test_attachment_message_is_kept():
    payload = {
        "entry": [{
            "messaging": [{
                "sender": {"id": "cust_1"},
                "recipient": {"id": "our_ig"},
                "message": {"mid": "mid_1", "attachments": [{"type": "audio"}]},
            }]
        }]
    }
    events = parse_webhook(payload, {"our_ig"}, "nur")
    assert len(events) == 1
    ev = events[0]
    assert ev.kind == "dm" and ev.has_attachment is True
    assert "ovozli xabar" in ev.text
    assert ev.message_id == "mid_1"
    assert ev.dedup_key == "msg:mid_1"


def test_dedup_key_is_stable_across_processes():
    """hash() jarayonlar orasida o'zgaradi — sha1 esa doim bir xil."""
    import hashlib

    ev = IncomingEvent(kind="dm", text="Salom", sender_id="c1")
    expected = "dm:c1:" + hashlib.sha1("Salom".encode()).hexdigest()[:16]
    assert ev.dedup_key == expected
    # Bir xil xabar -> bir xil kalit (restartdan keyin ham dublikat aniqlanadi)
    assert IncomingEvent(kind="dm", text="Salom", sender_id="c1").dedup_key == expected


# --------------------------------------------------------------------------- #
# Pipeline: har xabar ERP jurnaliga tushadi, ma'lum faktlar AI'ga uzatiladi
# --------------------------------------------------------------------------- #
def test_dm_logged_to_erp_and_facts_passed(monkeypatch):
    from app.processing import pipeline

    logged: list[dict] = []
    seen_kwargs: dict = {}

    async def fake_log(**kwargs):
        logged.append(kwargs)
        return True

    async def fake_context(user_id, limit=40, *, channel="instagram"):
        return {
            "messages": [{"role": "user", "content": "Salom", "at": None}],
            "contact": "+998901112233",
            "product_interest": "300 kvm kotyol",
            "name": None,
            "summary": None,
        }

    async def fake_handle(text, **kwargs):
        seen_kwargs.update(kwargs)
        return _out()

    async def noop(*a, **k):
        return {}

    monkeypatch.setattr(pipeline.leads_client, "log_message", fake_log)
    monkeypatch.setattr(pipeline.leads_client, "fetch_context", fake_context)
    monkeypatch.setattr(pipeline.leads_client, "push", noop)
    monkeypatch.setattr(pipeline._agent, "handle", fake_handle)
    monkeypatch.setattr(pipeline.instagram, "send_dm", noop)
    monkeypatch.setattr(pipeline.notifier, "notify_hot_lead", noop)

    event = IncomingEvent(kind="dm", text="Раками ёзиб ташладим ку", sender_id="cust_m1",
                          message_id="mid_m1")
    asyncio.run(pipeline.process_event(event))

    roles = [item["role"] for item in logged]
    assert roles == ["user", "assistant"], logged
    assert logged[0]["ig_message_id"] == "mid_m1"
    assert logged[0]["channel"] == "instagram" and logged[0]["user_id"] == "cust_m1"
    assert logged[0]["create_lead"] is True

    # AI biz bilgan raqamni ko'rdi — qayta so'ramaydi
    assert seen_kwargs["known"]["contact"] == "+998901112233"
    assert seen_kwargs["known"]["product_interest"] == "300 kvm kotyol"
    assert seen_kwargs["history"] == [{"role": "user", "content": "Salom", "at": None}]


def test_comment_does_not_create_new_lead(monkeypatch):
    """Izohlar jurnalga yoziladi, lekin yangi lead ochmaydi (ro'yxat toza qolsin)."""
    from app.processing import pipeline

    logged: list[dict] = []

    async def fake_log(**kwargs):
        logged.append(kwargs)
        return True

    async def fake_context(user_id, limit=40, *, channel="instagram"):
        return None

    async def fake_handle(text, **kwargs):
        return _out()

    async def noop(*a, **k):
        return {}

    monkeypatch.setattr(pipeline.leads_client, "log_message", fake_log)
    monkeypatch.setattr(pipeline.leads_client, "fetch_context", fake_context)
    monkeypatch.setattr(pipeline.leads_client, "push", noop)
    monkeypatch.setattr(pipeline._agent, "handle", fake_handle)
    monkeypatch.setattr(pipeline.instagram, "reply_to_comment", noop)
    monkeypatch.setattr(pipeline.instagram, "send_private_reply", noop)
    monkeypatch.setattr(pipeline.notifier, "notify_hot_lead", noop)

    asyncio.run(pipeline.process_event(IncomingEvent(
        kind="comment", text="Narxi qancha?", sender_id="cust_c1",
        comment_id="cmt_c1", media_id="med_c1",
    )))

    assert logged, "izoh jurnalga yozilmadi"
    assert all(item["create_lead"] is False for item in logged), logged


def test_operator_manual_reply_is_logged(monkeypatch):
    """Operator telefondan yozgan javob ham suhbat tarixiga tushadi."""
    from app.processing import pipeline

    logged: list[dict] = []

    async def fake_log(**kwargs):
        logged.append(kwargs)
        return True

    monkeypatch.setattr(pipeline.leads_client, "log_message", fake_log)

    asyncio.run(pipeline.process_event(IncomingEvent(
        kind="echo", text="Salom, men menejerman", sender_id="cust_op",
    )))

    assert len(logged) == 1
    assert logged[0]["role"] == "operator"
    assert logged[0]["text"] == "Salom, men menejerman"
