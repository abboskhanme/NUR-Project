"""Uchdan-uchgacha oqim testi — soxta AI provayder bilan (tarmoqsiz).

Kalit yoki API kerak emas: get_provider, instagram klienti, ERP push va Telegram
monkeypatch qilinadi. Bu Bosqich 2/3 ni App Review'siz tekshirish usuli.
"""
from __future__ import annotations

import asyncio

from app.instagram.models import IncomingEvent
from app.models import AgentOutput, LeadInfo


def _hot_output() -> AgentOutput:
    return AgentOutput(
        reply="Salom! Narxni DM'ga yozaman 👌",
        language="uz-Latn",
        intent="buying_intent",
        lead_score=85,
        is_hot_lead=True,
        move_to_dm=True,
        escalate_to_human=False,
        lead=LeadInfo(name="Ali", contact="+998901112233", product_interest="Kotyol 50L",
                      summary="Narx so'radi, raqam qoldirdi"),
    )


def test_comment_flow_replies_and_pushes_lead(monkeypatch):
    from app.processing import pipeline

    sent, pushed, alerts = [], [], []

    async def fake_reply(comment_id, message):
        sent.append(("reply", comment_id, message))
        return {}

    async def fake_private(comment_id, message):
        sent.append(("private", comment_id, message))
        return {}

    async def fake_push(payload):
        pushed.append(payload)
        return True

    async def fake_alert(username, out):
        alerts.append((username, out))

    async def fake_handle(*args, **kwargs):
        return _hot_output()
    monkeypatch.setattr(pipeline._agent, "handle", fake_handle)

    monkeypatch.setattr(pipeline.instagram, "reply_to_comment", fake_reply)
    monkeypatch.setattr(pipeline.instagram, "send_private_reply", fake_private)
    monkeypatch.setattr(pipeline.leads_client, "push", fake_push)
    monkeypatch.setattr(pipeline.notifier, "notify_hot_lead", fake_alert)

    event = IncomingEvent(
        kind="comment", text="Qancha turadi?", sender_id="cust_9",
        username="ali", comment_id="cmt_9", media_id="med_9",
    )
    asyncio.run(pipeline.process_event(event))

    assert any(s[0] == "reply" for s in sent), "kommentga javob yozilmadi"
    assert any(s[0] == "private" for s in sent), "DM'ga o'tkazilmadi"
    assert len(pushed) == 1, "lead ERP'ga yuborilmadi"
    assert pushed[0].contact == "+998901112233"
    assert pushed[0].lead_score == 85
    assert len(alerts) == 1, "Telegram alerti yuborilmadi"


def test_operator_reply_pauses_bot(monkeypatch):
    """Operator telefondan qo'lda javob yozsa (echo), bot o'sha suhbatda jim turadi."""
    from app.processing import pipeline
    from app.state.store import store

    calls = []

    async def fake_handle(*args, **kwargs):
        calls.append(1)
        return _hot_output()

    async def noop(*a, **k):
        return {}

    monkeypatch.setattr(pipeline._agent, "handle", fake_handle)
    monkeypatch.setattr(pipeline.instagram, "send_dm", noop)
    monkeypatch.setattr(pipeline.leads_client, "push", noop)
    monkeypatch.setattr(pipeline.notifier, "notify_hot_lead", noop)

    async def scenario():
        # 1. Operator qo'lda yozdi -> echo (bot yubormagan matn)
        await pipeline.process_event(
            IncomingEvent(kind="echo", text="Men menejerman, salom", sender_id="cust_p")
        )
        assert await store.is_paused("cust_p"), "bot pauzaga o'tmadi"
        # 2. Mijoz yana yozdi -> bot javob bermasligi kerak
        await pipeline.process_event(
            IncomingEvent(kind="dm", text="Narxi qancha?", sender_id="cust_p")
        )

    asyncio.run(scenario())
    assert calls == [], "bot pauzada bo'lsa ham javob berdi"


def test_bot_own_echo_does_not_pause(monkeypatch):
    """Botning O'Z javobi echo bo'lib qaytsa — pauza bo'lmaydi."""
    from app.processing import pipeline
    from app.state.store import store

    async def scenario():
        await store.mark_sent("cust_b", "Salom! Narxni yozaman")
        await pipeline.process_event(
            IncomingEvent(kind="echo", text="Salom! Narxni yozaman", sender_id="cust_b")
        )
        assert not await store.is_paused("cust_b"), "o'z javobidan pauzaga o'tdi"

    asyncio.run(scenario())


def test_dedup_skips_second_time(monkeypatch):
    from app.processing import pipeline

    calls = []

    async def fake_handle(*args, **kwargs):
        calls.append(1)
        return _hot_output()

    async def noop(*a, **k):
        return {}

    monkeypatch.setattr(pipeline._agent, "handle", fake_handle)
    monkeypatch.setattr(pipeline.instagram, "reply_to_comment", noop)
    monkeypatch.setattr(pipeline.instagram, "send_private_reply", noop)
    monkeypatch.setattr(pipeline.leads_client, "push", noop)
    monkeypatch.setattr(pipeline.notifier, "notify_hot_lead", noop)

    event = IncomingEvent(kind="comment", text="hi", sender_id="c", comment_id="dup_1")
    asyncio.run(pipeline.process_event(event))
    asyncio.run(pipeline.process_event(event))  # dublikat
    assert len(calls) == 1, "dublikat ikkinchi marta ishlandi"
