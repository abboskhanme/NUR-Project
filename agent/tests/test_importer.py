"""Eski Instagram suhbatlarini ERP'ga import qilish (tarmoqsiz)."""
from __future__ import annotations

import asyncio


def _conversation() -> dict:
    """Instagram javobi: eng yangi xabar birinchi bo'lib keladi."""
    return {
        "data": [{
            "id": "conv_1",
            "updated_time": "2026-08-06T09:00:00+0000",
            "participants": {"data": [
                {"id": "our_ig", "username": "nurtechno"},
                {"id": "cust_77", "username": "azixon_sobirov_07"},
            ]},
            "messages": {"data": [
                {"id": "m3", "created_time": "2026-08-06T09:00:00+0000",
                 "from": {"id": "cust_77"}, "message": "300 квадрат жойга канчалигини олишимкерак"},
                {"id": "m2", "created_time": "2026-08-06T08:59:00+0000",
                 "from": {"id": "our_ig"}, "message": "Assalomu alaykum!"},
                {"id": "m1", "created_time": "2026-08-06T08:58:00+0000",
                 "from": {"id": "cust_77"}, "message": "Ассалом алейкум ака"},
            ]},
        }]
    }


def test_import_writes_full_history(monkeypatch):
    from app.instagram import importer

    monkeypatch.setattr(importer.settings, "IG_ACCESS_TOKEN", "token")
    monkeypatch.setattr(importer.settings, "IG_USER_ID", "our_ig")
    monkeypatch.setattr(importer.settings, "IG_ACCOUNT_ID", "our_ig")
    monkeypatch.setattr(importer.settings, "IG_USERNAME", "nurtechno")

    calls: list[dict] = []

    async def fake_list(after=None):
        return _conversation() if after is None else {"data": []}

    async def fake_log(**kwargs):
        calls.append(kwargs)
        return True

    monkeypatch.setattr(importer.instagram, "list_conversations", fake_list)
    monkeypatch.setattr(importer.leads_client, "log_message", fake_log)

    stats = asyncio.run(importer.import_conversations())

    assert stats == {"conversations": 1, "messages": 3, "skipped": 0}, stats
    # Xabarlar eski→yangi tartibda yozilgan
    assert [c["ig_message_id"] for c in calls] == ["m1", "m2", "m3"]
    # Kim yozgani to'g'ri aniqlangan
    assert [c["role"] for c in calls] == ["user", "operator", "user"]
    # Mijoz (biz emas) suhbat egasi
    assert {c["ig_user_id"] for c in calls} == {"cust_77"}
    assert {c["ig_username"] for c in calls} == {"azixon_sobirov_07"}
    # Import qilinganlar alohida manba bilan belgilanadi
    assert {c["source"] for c in calls} == {"instagram_import"}
    # Asl vaqti saqlanadi (bugungi sana bilan aralashib ketmasin)
    assert calls[0]["sent_at"] == "2026-08-06T08:58:00+0000"


def test_import_without_token_is_safe(monkeypatch):
    from app.instagram import importer

    monkeypatch.setattr(importer.settings, "IG_ACCESS_TOKEN", "")
    stats = asyncio.run(importer.import_conversations())
    assert stats == {"error": "instagram_not_connected"}


def test_import_fetches_message_details_when_nested_missing(monkeypatch):
    """Instagram faqat ID bersa — har xabar alohida so'raladi."""
    from app.instagram import importer

    monkeypatch.setattr(importer.settings, "IG_ACCESS_TOKEN", "token")
    monkeypatch.setattr(importer.settings, "IG_USER_ID", "our_ig")
    monkeypatch.setattr(importer.settings, "IG_ACCOUNT_ID", "our_ig")
    monkeypatch.setattr(importer.settings, "IG_USERNAME", "nurtechno")

    async def fake_list(after=None):
        if after is not None:
            return {"data": []}
        return {"data": [{
            "id": "conv_2",
            "participants": {"data": [
                {"id": "our_ig", "username": "nurtechno"},
                {"id": "cust_88", "username": "maqsad"},
            ]},
            "messages": {"data": [{"id": "x1"}, {"id": "x2"}]},
        }]}

    async def fake_get_message(mid):
        return {
            "id": mid,
            "created_time": f"2026-08-05T10:0{mid[-1]}:00+0000",
            "from": {"id": "cust_88"},
            "message": f"Narxi qanca brat {mid}",
        }

    calls: list[dict] = []

    async def fake_log(**kwargs):
        calls.append(kwargs)
        return True

    monkeypatch.setattr(importer.instagram, "list_conversations", fake_list)
    monkeypatch.setattr(importer.instagram, "get_message", fake_get_message)
    monkeypatch.setattr(importer.leads_client, "log_message", fake_log)

    stats = asyncio.run(importer.import_conversations())
    assert stats["messages"] == 2, stats
    assert [c["ig_message_id"] for c in calls] == ["x1", "x2"]
