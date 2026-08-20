"""Xo'jayin (admin) buyruqlari: chat_id ni bilish va hisobotni darhol olish."""
from __future__ import annotations

import logging

from aiogram import Router
from aiogram.filters import Command
from aiogram.types import Message

from .config_store import admin_chat_ids
from .digest import build_digest, format_digest

log = logging.getLogger(__name__)
router = Router(name="admin")


@router.message(Command("id"))
async def cmd_id(m: Message):
    """Foydalanuvchiga o'z chat_id sini ko'rsatadi (admin ro'yxatiga qo'shish uchun)."""
    is_admin = m.chat.id in await admin_chat_ids()
    note = (
        "✅ Siz hisobot oluvchilar ro'yxatidasiz."
        if is_admin
        else "ℹ️ Bu raqamni ERP'da «Tizim sozlamalari → ERP Telegram boti → "
             "Hisobot oluvchilar» ga qo'shing.\n"
             "Servis lokatsiyasini biriktirish uchun esa — Foydalanuvchilar "
             "bo'limida o'z profilingizdagi «Telegram chat ID» maydoniga."
    )
    await m.answer(f"Sizning chat_id: <code>{m.chat.id}</code>\n\n{note}", parse_mode="HTML")


@router.message(Command("report"))
async def cmd_report(m: Message):
    """Faqat adminlar uchun — bugungi hisobotni darhol yuboradi."""
    if m.chat.id not in await admin_chat_ids():
        return await m.answer(
            "⛔️ Bu buyruq faqat administratorlar uchun.\n"
            "Chat_id ingizni bilish uchun /id yuboring."
        )
    try:
        digest = await build_digest()
        await m.answer(format_digest(digest), parse_mode="HTML")
    except Exception:  # noqa: BLE001
        log.exception("Hisobot tayyorlashda xato")
        await m.answer("Hisobotni tayyorlashda xatolik yuz berdi.")
