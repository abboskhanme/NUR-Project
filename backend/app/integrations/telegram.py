"""Telegram bot — aiogram 3 conversation flow for order intake.

Run as a separate process:
    python -m app.integrations.telegram
"""
import asyncio
import logging

from aiogram import Bot, Dispatcher, F
from aiogram.filters import Command
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.fsm.storage.memory import MemoryStorage
from aiogram.types import (
    InlineKeyboardButton, InlineKeyboardMarkup, KeyboardButton, Message,
    ReplyKeyboardMarkup, ReplyKeyboardRemove,
)

from app.core.config import settings

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)


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


MODELS = ["PREMIUM 3", "PREMIUM 4", "ULTRA", "MAGNUM", "OPTIMA"]
KVMS = ["150", "200", "300", "400", "500"]
DIRS = ["O'NGA", "CHAP"]


def kb(rows: list[list[str]]) -> ReplyKeyboardMarkup:
    return ReplyKeyboardMarkup(
        keyboard=[[KeyboardButton(text=t) for t in r] for r in rows],
        resize_keyboard=True, one_time_keyboard=True,
    )


def build_dispatcher() -> Dispatcher:
    dp = Dispatcher(storage=MemoryStorage())

    @dp.message(Command("start"))
    async def cmd_start(m: Message):
        await m.answer(
            "Assalomu alaykum! NUR TECHNO GROUPga xush kelibsiz.\n"
            "Yangi buyurtma uchun /neworder buyrug'ini yuboring."
        )

    @dp.message(Command("neworder"))
    async def cmd_new(m: Message, state: FSMContext):
        await state.set_state(OrderFSM.name)
        await m.answer("Ismingiz va familiyangizni yozing:", reply_markup=ReplyKeyboardRemove())

    @dp.message(OrderFSM.name)
    async def s_name(m: Message, state: FSMContext):
        await state.update_data(name=m.text)
        await state.set_state(OrderFSM.phone)
        await m.answer("Telefon raqamingizni yozing (masalan 90 123 45 67):")

    @dp.message(OrderFSM.phone)
    async def s_phone(m: Message, state: FSMContext):
        await state.update_data(phone=m.text)
        await state.set_state(OrderFSM.region)
        await m.answer("Viloyat / shaharingizni yozing:")

    @dp.message(OrderFSM.region)
    async def s_region(m: Message, state: FSMContext):
        await state.update_data(region=m.text)
        await state.set_state(OrderFSM.model)
        await m.answer("Bunker modelini tanlang:", reply_markup=kb([MODELS[:3], MODELS[3:]]))

    @dp.message(OrderFSM.model)
    async def s_model(m: Message, state: FSMContext):
        if m.text not in MODELS:
            return await m.answer("Iltimos, ro'yxatdan tanlang.")
        await state.update_data(model=m.text)
        await state.set_state(OrderFSM.kvm)
        await m.answer("Kvadraturani tanlang:", reply_markup=kb([KVMS]))

    @dp.message(OrderFSM.kvm)
    async def s_kvm(m: Message, state: FSMContext):
        await state.update_data(kvm=m.text)
        await state.set_state(OrderFSM.direction)
        await m.answer("Bunker yo'nalishini tanlang:", reply_markup=kb([DIRS]))

    @dp.message(OrderFSM.direction)
    async def s_dir(m: Message, state: FSMContext):
        await state.update_data(direction=m.text)
        await state.set_state(OrderFSM.price)
        await m.answer("Mahsulot narxini USD da yozing:", reply_markup=ReplyKeyboardRemove())

    @dp.message(OrderFSM.price)
    async def s_price(m: Message, state: FSMContext):
        await state.update_data(price=m.text)
        await state.set_state(OrderFSM.note)
        await m.answer("Qo'shimcha izoh (yoki '-' ni yozing):")

    @dp.message(OrderFSM.note)
    async def s_note(m: Message, state: FSMContext):
        await state.update_data(note=m.text if m.text != "-" else None)
        data = await state.get_data()
        summary = (
            "Tasdiqlang:\n\n"
            f"Ism: {data['name']}\n"
            f"Telefon: {data['phone']}\n"
            f"Viloyat: {data['region']}\n"
            f"Model: {data['model']} ({data['kvm']} kvm, {data['direction']})\n"
            f"Narx: ${data['price']}\n"
            f"Izoh: {data.get('note') or '—'}\n"
        )
        await state.set_state(OrderFSM.confirm)
        await m.answer(summary, reply_markup=kb([["TASDIQLAYMAN", "BEKOR QILISH"]]))

    @dp.message(OrderFSM.confirm, F.text == "TASDIQLAYMAN")
    async def s_confirm(m: Message, state: FSMContext):
        data = await state.get_data()
        # TODO: POST to FastAPI /api/v1/orders with source=telegram_bot
        await m.answer(
            f"Rahmat! Buyurtmangiz qabul qilindi. Tez orada sotuvchi siz bilan bog'lanadi.",
            reply_markup=ReplyKeyboardRemove(),
        )
        await state.clear()

    @dp.message(OrderFSM.confirm, F.text == "BEKOR QILISH")
    async def s_cancel(m: Message, state: FSMContext):
        await m.answer("Buyurtma bekor qilindi.", reply_markup=ReplyKeyboardRemove())
        await state.clear()

    return dp


async def main():
    if not settings.TELEGRAM_BOT_TOKEN:
        raise RuntimeError("TELEGRAM_BOT_TOKEN .env ga qo'shilmagan")
    bot = Bot(settings.TELEGRAM_BOT_TOKEN)
    dp = build_dispatcher()
    log.info("Telegram bot ishga tushdi")
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())
