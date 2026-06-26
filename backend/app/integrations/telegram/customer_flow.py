"""Mijoz uchun buyurtma qabul qilish suhbati (bot = sotuvchi).

aiogram 3 Router + FSM. Suhbat oxirida real buyurtma yaratiladi
(repository.create_order_from_draft) va xo'jayinga xabar beriladi.
"""
from __future__ import annotations

import logging

from aiogram import F, Router
from aiogram.filters import Command, StateFilter
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import (
    KeyboardButton, Message, ReplyKeyboardMarkup, ReplyKeyboardRemove,
)

from app.core.config import settings

from .common import MODELS, KVMS, DIRECTIONS, fmt_usd, fmt_uzs, to_decimal
from .repository import OrderDraft, create_order_from_draft

log = logging.getLogger(__name__)
router = Router(name="customer")

CANCEL = "❌ Bekor qilish"
CONFIRM = "✅ Tasdiqlayman"


class OrderFSM(StatesGroup):
    name = State()
    phone = State()
    region = State()
    model = State()
    kvm = State()
    direction = State()
    price = State()
    note = State()
    confirm = State()


def _kb(rows: list[list[str]], with_cancel: bool = True) -> ReplyKeyboardMarkup:
    keyboard = [[KeyboardButton(text=t) for t in r] for r in rows]
    if with_cancel:
        keyboard.append([KeyboardButton(text=CANCEL)])
    return ReplyKeyboardMarkup(keyboard=keyboard, resize_keyboard=True, one_time_keyboard=True)


@router.message(Command("start"))
async def cmd_start(m: Message, state: FSMContext):
    await state.clear()
    await m.answer(
        f"Assalomu alaykum! <b>{settings.COMPANY_NAME}</b>ga xush kelibsiz. 🔥\n\n"
        "Men sizga yangi buyurtma berishda yordam beraman.\n"
        "Boshlash uchun /neworder buyrug'ini yuboring.",
        parse_mode="HTML",
        reply_markup=ReplyKeyboardRemove(),
    )


@router.message(Command("cancel"))
@router.message(F.text == CANCEL)
async def cmd_cancel(m: Message, state: FSMContext):
    await state.clear()
    await m.answer("Buyurtma bekor qilindi.", reply_markup=ReplyKeyboardRemove())


@router.message(Command("neworder"))
async def cmd_new(m: Message, state: FSMContext):
    await state.clear()
    await state.set_state(OrderFSM.name)
    await m.answer(
        "Ismingiz va familiyangizni yozing:",
        reply_markup=_kb([]),
    )


@router.message(OrderFSM.name, F.text)
async def s_name(m: Message, state: FSMContext):
    await state.update_data(name=m.text.strip())
    await state.set_state(OrderFSM.phone)
    await m.answer("📞 Telefon raqamingizni yozing (masalan: +998 90 123 45 67):",
                   reply_markup=_kb([]))


@router.message(OrderFSM.phone, F.text)
async def s_phone(m: Message, state: FSMContext):
    await state.update_data(phone=m.text.strip())
    await state.set_state(OrderFSM.region)
    await m.answer("📍 Viloyat / shaharingizni yozing:", reply_markup=_kb([]))


@router.message(OrderFSM.region, F.text)
async def s_region(m: Message, state: FSMContext):
    await state.update_data(region=m.text.strip())
    await state.set_state(OrderFSM.model)
    await m.answer("Bunker modelini tanlang:", reply_markup=_kb([MODELS[:3], MODELS[3:]]))


@router.message(OrderFSM.model, F.text)
async def s_model(m: Message, state: FSMContext):
    if m.text not in MODELS:
        return await m.answer("Iltimos, ro'yxatdan tanlang.",
                              reply_markup=_kb([MODELS[:3], MODELS[3:]]))
    await state.update_data(model=m.text)
    await state.set_state(OrderFSM.kvm)
    await m.answer("Kvadraturani tanlang:", reply_markup=_kb([KVMS]))


@router.message(OrderFSM.kvm, F.text)
async def s_kvm(m: Message, state: FSMContext):
    if m.text not in KVMS:
        return await m.answer("Iltimos, ro'yxatdan tanlang.", reply_markup=_kb([KVMS]))
    await state.update_data(kvm=int(m.text))
    await state.set_state(OrderFSM.direction)
    await m.answer("Bunker yo'nalishini tanlang:", reply_markup=_kb([list(DIRECTIONS.keys())]))


@router.message(OrderFSM.direction, F.text)
async def s_direction(m: Message, state: FSMContext):
    if m.text not in DIRECTIONS:
        return await m.answer("Iltimos, ro'yxatdan tanlang.",
                              reply_markup=_kb([list(DIRECTIONS.keys())]))
    await state.update_data(direction=DIRECTIONS[m.text], direction_label=m.text)
    await state.set_state(OrderFSM.price)
    await m.answer("💵 Mahsulot narxini USD'da yozing (masalan: 1200):",
                   reply_markup=_kb([]))


@router.message(OrderFSM.price, F.text)
async def s_price(m: Message, state: FSMContext):
    price = to_decimal(m.text)
    if price is None:
        return await m.answer("Narx noto'g'ri. Faqat son kiriting (masalan: 1200):",
                              reply_markup=_kb([]))
    await state.update_data(price=str(price))
    await state.set_state(OrderFSM.note)
    await m.answer("✍️ Qo'shimcha izoh bo'lsa yozing (yoki '-' yuboring):",
                   reply_markup=_kb([["-"]]))


@router.message(OrderFSM.note, F.text)
async def s_note(m: Message, state: FSMContext):
    note = None if m.text.strip() == "-" else m.text.strip()
    await state.update_data(note=note)
    data = await state.get_data()
    summary = (
        "Iltimos, ma'lumotlarni tasdiqlang:\n\n"
        f"👤 Ism: <b>{data['name']}</b>\n"
        f"📞 Telefon: <b>{data['phone']}</b>\n"
        f"📍 Manzil: <b>{data['region']}</b>\n"
        f"🔧 Model: <b>{data['model']} ({data['kvm']} kvm, {data['direction_label']})</b>\n"
        f"💵 Narx: <b>{fmt_usd(data['price'])}</b>\n"
        f"✍️ Izoh: {note or '—'}\n"
    )
    await state.set_state(OrderFSM.confirm)
    await m.answer(summary, parse_mode="HTML", reply_markup=_kb([[CONFIRM]]))


@router.message(OrderFSM.confirm, F.text == CONFIRM)
async def s_confirm(m: Message, state: FSMContext):
    from decimal import Decimal

    data = await state.get_data()
    draft = OrderDraft(
        name=data["name"],
        phone=data["phone"],
        region=data["region"],
        model=data["model"],
        kvm=int(data["kvm"]),
        direction=data["direction"],
        price_usd=Decimal(data["price"]),
        note=data.get("note"),
    )
    try:
        created = await create_order_from_draft(draft)
    except Exception:  # noqa: BLE001 — foydalanuvchiga toza xabar beramiz
        log.exception("Telegram buyurtmasini yaratishda xato")
        await state.clear()
        return await m.answer(
            "Kechirasiz, texnik xatolik yuz berdi. Iltimos, keyinroq urinib ko'ring "
            "yoki biz bilan bog'laning.",
            reply_markup=ReplyKeyboardRemove(),
        )

    await state.clear()
    await m.answer(
        f"✅ Rahmat! Buyurtmangiz qabul qilindi.\n"
        f"Buyurtma raqami: <b>{created.code}</b>\n\n"
        "Tez orada sotuvchimiz siz bilan bog'lanadi. 🤝",
        parse_mode="HTML",
        reply_markup=ReplyKeyboardRemove(),
    )

    # Xo'jayin(lar)ga darhol xabar berish (sozlama yoqilgan bo'lsa).
    if settings.TELEGRAM_NOTIFY_NEW_ORDER:
        text = (
            "🆕 <b>Telegram orqali yangi buyurtma</b>\n\n"
            f"№ <b>{created.code}</b>\n"
            f"👤 {created.customer_name}\n"
            f"📞 {created.phone}\n"
            f"🔧 {created.model} ({created.kvm} kvm)\n"
            f"💵 {fmt_usd(created.price_usd)}"
            + (f" ≈ {fmt_uzs(created.total_uzs)}" if created.total_uzs else "")
        )
        await _notify_admins(m, text)


async def _notify_admins(m: Message, text: str) -> None:
    """Buyurtma haqida barcha admin chat_id'larga xabar yuboradi."""
    for chat_id in settings.TELEGRAM_ADMIN_IDS:
        try:
            await m.bot.send_message(chat_id, text, parse_mode="HTML")
        except Exception:  # noqa: BLE001
            log.warning("Adminga (%s) xabar yuborilmadi", chat_id)


# Holatdan tashqari har qanday matn — yo'naltiruvchi javob.
@router.message(StateFilter(None), F.text)
async def fallback(m: Message):
    await m.answer(
        "Yangi buyurtma berish uchun /neworder buyrug'ini yuboring.",
    )
