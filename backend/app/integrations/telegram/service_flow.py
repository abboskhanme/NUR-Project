"""Servis lokatsiyasi — mijoz yuborgan pinni ERP'dagi arizaga biriktirish.

Mijoz lokatsiyani odatdagidek sotuvchining shaxsiy Telegramiga tashlaydi
(hech nima o'zgarmaydi). Xodim o'sha xabarni shu botga FORWARD qiladi —
koordinata strukturaviy kelgani uchun nusxalash/qidirish kerak emas.

Ikki oqim:
  * ERP'da "Lokatsiya biriktirish" bosilgan bo'lsa — kelgan lokatsiya
    to'g'ridan-to'g'ri o'sha arizaga tushadi (ariza tanlash shart emas);
  * aks holda bot lokatsiyasi yo'q oxirgi arizalarni tugma qilib beradi,
    yoki ariza kodi / mijoz ismi / telefoni bo'yicha qidirish mumkin.

Xarita havolasi (Google/Yandex/2GIS…) ham xuddi shunday qabul qilinadi.
"""
from __future__ import annotations

import html
import logging
import uuid

from aiogram import F, Router
from aiogram.filters import Command, CommandStart, StateFilter
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import CallbackQuery, InlineKeyboardButton, InlineKeyboardMarkup, Message

from app.db.session import AsyncSessionLocal
from app.services import geo, service_location as loc

log = logging.getLogger(__name__)
router = Router(name="service-location")

CB_PREFIX = "svcloc:"
CB_CANCEL = f"{CB_PREFIX}cancel"

HELP_TEXT = (
    "📍 <b>Servis lokatsiyasi</b>\n\n"
    "Mijoz yuborgan lokatsiyani shu yerga <b>forward</b> qiling — men uni "
    "arizaga biriktiraman.\n\n"
    "Xarita havolasini (Google, Yandex, 2GIS) yoki koordinatani "
    "(<code>41.311, 69.240</code>) tashlasangiz ham bo'ladi."
)


class LocFSM(StatesGroup):
    pick = State()   # lokatsiya keldi, ariza tanlanmoqda
    note = State()   # biriktirildi, mo'ljal kutilmoqda (ixtiyoriy)


def _esc(text: str | None) -> str:
    return html.escape(text or "")


def _is_map_text(text: str | None) -> bool:
    return geo.looks_like_map_link(text)


def _ticket_label(ticket) -> str:
    name = (ticket.customer.full_name if ticket.customer else None) or "Mijoz"
    label = f"{ticket.code} — {name}"
    return label[:60]


def _pick_kb(tickets) -> InlineKeyboardMarkup:
    rows = [[InlineKeyboardButton(text=_ticket_label(t), callback_data=f"{CB_PREFIX}{t.id}")]
            for t in tickets]
    rows.append([InlineKeyboardButton(text="❌ Bekor qilish", callback_data=CB_CANCEL)])
    return InlineKeyboardMarkup(inline_keyboard=rows)


def _saved_text(ticket, lat: float, lon: float) -> str:
    links = geo.map_links(lat, lon)
    name = _esc(ticket.customer.full_name if ticket.customer else None) or "—"
    parts = [
        f"✅ <b>{_esc(ticket.code)}</b> — {name}",
        f"📍 <code>{geo.format_coords(lat, lon)}</code>",
    ]
    if ticket.address:
        parts.append(f"🏠 {_esc(ticket.address)}")
    parts.append(
        f"<a href=\"{links['yandex']}\">Yandex</a> · "
        f"<a href=\"{links['google']}\">Google</a>"
    )
    parts.append("\n✍️ Mo'ljal qo'shmoqchi bo'lsangiz — shu yerga yozing "
                 "(masalan: <i>ko'k darvoza, do'kon yonida</i>).")
    return "\n".join(parts)


async def _not_linked(m: Message) -> None:
    await m.answer(
        "📍 Lokatsiya keldi, lekin bu Telegram akkaunt ERP xodimiga bog'lanmagan.\n\n"
        "Agar siz xodim bo'lsangiz — ERP'da <b>Sozlamalar → Telegram</b> "
        f"bo'limiga shu raqamni qo'ying:\n<code>{m.chat.id}</code>",
        parse_mode="HTML",
    )


async def _handle_coords(m: Message, state: FSMContext, lat: float, lon: float,
                         *, source: str, url: str | None = None) -> None:
    """Kelgan koordinatani arizaga biriktiradi yoki ariza tanlashni so'raydi."""
    async with AsyncSessionLocal() as db:
        user = await loc.user_by_chat_id(db, m.chat.id)
        if not user:
            await _not_linked(m)
            return

        req = await loc.active_request(db, user.id)
        if req:
            ticket = await loc.ticket_by_id(db, req.ticket_id)
            if ticket:
                loc.set_location(ticket, geo.Coords(lat=lat, lon=lon),
                                 source=source, url=url, user_id=user.id)
                loc.consume(req)
                await db.commit()
                await state.clear()
                await state.set_state(LocFSM.note)
                await state.update_data(ticket_id=str(ticket.id))
                await m.answer(_saved_text(ticket, lat, lon), parse_mode="HTML",
                               disable_web_page_preview=True)
                return
            loc.consume(req)
            await db.commit()

        tickets = await loc.tickets_needing_location(db, limit=8)

    await state.set_state(LocFSM.pick)
    await state.update_data(lat=lat, lon=lon, source=source, url=url)
    if not tickets:
        await m.answer(
            "Lokatsiya qabul qilindi. Lokatsiyasi yo'q ochiq ariza topilmadi — "
            "ariza kodi, mijoz ismi yoki telefon raqamini yozing.",
        )
        return
    await m.answer("📍 Lokatsiya qabul qilindi. Qaysi arizaga biriktiray?\n"
                   "<i>Ro'yxatda bo'lmasa — ariza kodi, mijoz ismi yoki telefonini yozing.</i>",
                   parse_mode="HTML", reply_markup=_pick_kb(tickets))


# --------------------------------------------------------------------------- #
# Kirish nuqtalari
# --------------------------------------------------------------------------- #
@router.message(CommandStart(deep_link=True, magic=F.args == "loc"))
async def cmd_start_loc(m: Message, state: FSMContext):
    """ERP'dagi "Botga o'tish" havolasi (t.me/<bot>?start=loc)."""
    await state.clear()
    await m.answer(HELP_TEXT, parse_mode="HTML")


@router.message(Command("lokatsiya"))
async def cmd_help(m: Message, state: FSMContext):
    await state.clear()
    await m.answer(HELP_TEXT, parse_mode="HTML")


@router.message(F.location)
async def on_location(m: Message, state: FSMContext):
    """Telegram pin — forward qilingani ham, to'g'ridan-to'g'ri yuborilgani ham."""
    live = bool(getattr(m.location, "live_period", None))
    await _handle_coords(m, state, m.location.latitude, m.location.longitude,
                         source=loc.SOURCE_TELEGRAM)
    if live:
        await m.answer("ℹ️ Jonli lokatsiya edi — hozirgi nuqta saqlandi.")


@router.message(StateFilter(None, LocFSM.pick, LocFSM.note), F.text.func(_is_map_text))
async def on_map_link(m: Message, state: FSMContext):
    """Xarita havolasi yoki koordinata matni."""
    raw = m.text.strip()
    coords = await geo.resolve_coords(raw)
    if not coords:
        await m.answer(
            "Bu havoladan koordinatani ololmadim. Havolani xaritada ochib, "
            "uzun (to'liq) havolani yuboring yoki koordinatani yozing: "
            "<code>41.311, 69.240</code>",
            parse_mode="HTML",
        )
        return
    await _handle_coords(m, state, coords.lat, coords.lon, source=loc.SOURCE_LINK,
                         url=raw if raw.lower().startswith("http") else None)


@router.message(LocFSM.pick, F.text, ~F.text.startswith("/"))
async def on_pick_search(m: Message, state: FSMContext):
    """Ariza kodi / mijoz ismi / telefon bo'yicha qidiruv."""
    async with AsyncSessionLocal() as db:
        tickets = await loc.search_tickets(db, m.text, limit=8)
    if not tickets:
        await m.answer("Ariza topilmadi. Ariza kodi, mijoz ismi yoki telefon raqamini yozing.")
        return
    await m.answer("Topildi — birini tanlang:", reply_markup=_pick_kb(tickets))


@router.message(LocFSM.note, F.text, ~F.text.startswith("/"))
async def on_note(m: Message, state: FSMContext):
    """Biriktirilgandan keyingi ixtiyoriy mo'ljal matni."""
    data = await state.get_data()
    ticket_id = data.get("ticket_id")
    await state.clear()
    if not ticket_id:
        return
    async with AsyncSessionLocal() as db:
        ticket = await loc.ticket_by_id(db, uuid.UUID(ticket_id))
        if not ticket:
            return
        ticket.location_note = m.text.strip()[:255] or None
        await db.commit()
        code = ticket.code
    await m.answer(f"✍️ Mo'ljal saqlandi — <b>{_esc(code)}</b>", parse_mode="HTML")


@router.callback_query(F.data.startswith(CB_PREFIX))
async def on_pick_callback(cb: CallbackQuery, state: FSMContext):
    key = cb.data[len(CB_PREFIX):]
    if key == "cancel":
        await state.clear()
        await cb.message.edit_text("Bekor qilindi.")
        await cb.answer()
        return

    data = await state.get_data()
    lat, lon = data.get("lat"), data.get("lon")
    if lat is None or lon is None:
        await cb.answer("Lokatsiya eskirdi — qaytadan yuboring.", show_alert=True)
        await state.clear()
        return

    try:
        ticket_id = uuid.UUID(key)
    except ValueError:
        await cb.answer("Ariza aniqlanmadi.", show_alert=True)
        return

    async with AsyncSessionLocal() as db:
        user = await loc.user_by_chat_id(db, cb.message.chat.id)
        if not user:
            await cb.answer("Akkaunt ERP'ga bog'lanmagan.", show_alert=True)
            return
        ticket = await loc.ticket_by_id(db, ticket_id)
        if not ticket:
            await cb.answer("Ariza topilmadi.", show_alert=True)
            return
        loc.set_location(ticket, geo.Coords(lat=float(lat), lon=float(lon)),
                         source=data.get("source") or loc.SOURCE_TELEGRAM,
                         url=data.get("url"), user_id=user.id)
        req = await loc.active_request(db, user.id)
        if req:
            loc.consume(req)
        await db.commit()
        text = _saved_text(ticket, float(lat), float(lon))

    await state.clear()
    await state.set_state(LocFSM.note)
    await state.update_data(ticket_id=str(ticket_id))
    await cb.message.edit_text(text, parse_mode="HTML", disable_web_page_preview=True)
    await cb.answer("Biriktirildi")
