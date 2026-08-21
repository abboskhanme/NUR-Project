"""Pipeline — webhook hodisasidan to javob + lead + bildirishnomagacha.

Har bosqich alohida try/except: biri yiqilsa boshqalari ishlashda davom etadi
(masalan ERP tushib qolsa ham kommentга javob berilgan bo'ladi).
"""
from __future__ import annotations

from loguru import logger

from app.agent.core import SalesAgent
from app.config import settings
from app.instagram.client import instagram
from app.instagram.models import IncomingEvent
from app.telegram_business.client import telegram
from app.leads import client as leads_client
from app.models import AgentOutput, LeadPayload
from app.state.store import store
from app.telegram import notifier

_agent = SalesAgent()

# XAVFSIZLIK CHEKLOVI (circuit breaker). Bot o'z izohini begona deb hisoblab
# qolsa cheksiz halqa boshlanadi va akkaunt spam sifatida cheklanishi mumkin.
# Shuning uchun bir post ostida qisqa vaqtda beriladigan javoblar soni qat'iy
# cheklangan: normal muloqotda bunga hech qachon yetilmaydi, halqada esa
# darhol to'xtaydi.
_COMMENT_LIMIT = 8          # bitta post ostida
_COMMENT_WINDOW = 600       # 10 daqiqada
_GLOBAL_LIMIT = 30          # butun akkaunt bo'yicha
_GLOBAL_WINDOW = 600


async def process_event(event: IncomingEvent) -> None:
    # 0. Echo — akkauntimizdan chiqqan xabar. Agar uni bot yubormagan bo'lsa,
    #    demak operator telefondan qo'lda javob yozdi → bot o'sha suhbatda jim turadi.
    if event.kind == "echo":
        await _handle_echo(event)
        return

    # 1. Dedup — bir xil komment/xabarni takror ishlamaymiz
    try:
        if await store.seen_once(event.dedup_key, settings.DEDUP_TTL):
            logger.info("Dublikat o'tkazib yuborildi: {}", event.dedup_key)
            return
    except Exception as exc:  # noqa: BLE001
        logger.warning("Dedup xatosi (davom etamiz): {}", exc)

    # 1a. Halqadan zaxira himoya — izohlar bo'yicha tezlik cheklovi.
    #     Asosiy himoya `parse_webhook` da: o'z izohimiz ID va username bo'yicha
    #     ajratiladi. Bu esa o'sha tekshiruv qandaydir sabab ishlamay qolsa
    #     spamning oldini oladi.
    if event.kind == "comment" and not await _within_comment_limits(event):
        return

    # 1b. Operator aralashgan suhbatga bot aralashmaydi
    if event.kind == "dm":
        try:
            if await store.is_paused(event.store_key):
                logger.info("Bot pauzada (operator javob bermoqda): {}", event.sender_id)
                return
        except Exception as exc:  # noqa: BLE001
            logger.warning("Pauza tekshiruvida xato (davom etamiz): {}", exc)

    notifier.bump("total")

    # 2. Kontekst — suhbat tarixi va biz allaqachon bilgan faktlar.
    #    Asosiy manba ERP (u yerda butun yozishma saqlanadi), Redis esa tezkor
    #    zaxira: ERP javob bermasa ham bot kontekstsiz qolmaydi.
    history: list[dict] = []
    known: dict = {}
    if event.sender_id:
        ctx = await leads_client.fetch_context(event.sender_id, channel=event.channel)
        if ctx:
            history = ctx.get("messages") or []
            known = {
                "name": ctx.get("name"),
                "contact": ctx.get("contact"),
                "product_interest": ctx.get("product_interest"),
                "summary": ctx.get("summary"),
            }
        elif event.kind == "dm":
            try:
                history = await store.get_history(event.store_key)
            except Exception as exc:  # noqa: BLE001
                logger.warning("Tarixni olishда xato: {}", exc)

    # 2a. Mijoz xabarini DARHOL jurnalga yozamiz — AI javob bera olmasa ham
    #     yozishma yo'qolmaydi (keyingi safar xotira sifatida ishlatiladi).
    await _log(event, event.text, role="user")

    # 3. AI javobi
    try:
        out = await _agent.handle(
            event.text,
            is_comment=event.kind == "comment",
            username=event.username,
            media_caption=event.media_caption,
            history=history,
            known=known,
            has_attachment=event.has_attachment,
        )
    except Exception as exc:  # noqa: BLE001
        logger.exception("Agent javob berolmadi: {}", exc)
        return

    logger.info(
        "Javob tayyor: intent={} score={} hot={} dm={} esc={}\n  ➜ javob: {}",
        out.intent, out.lead_score, out.is_hot_lead, out.move_to_dm,
        out.escalate_to_human, out.reply,
    )

    # 4. Javob yuborish (Instagram)
    try:
        await _deliver(event, out, is_first=not history)
    except Exception as exc:  # noqa: BLE001
        logger.exception("Javob yuborishда xato: {}", exc)

    # 5. Tarixni saqlash — ERP (asosiy xotira) va Redis (tezkor kesh)
    await _log(event, out.reply, role="assistant")
    if event.kind == "dm":
        try:
            await store.append_turn(event.store_key, "user", event.text)
            await store.append_turn(event.store_key, "assistant", out.reply)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Tarixni saqlashда xato: {}", exc)

    # 6. Qaynoq lead → ERP
    if out.is_hot_lead or out.lead.contact:
        try:
            await leads_client.push(_to_payload(event, out))
        except Exception as exc:  # noqa: BLE001
            logger.exception("Lead ERP'ga yuborishда xato: {}", exc)

    # 7. Telegram bildirishnoma
    try:
        if out.is_hot_lead:
            notifier.bump("hot")
        if out.escalate_to_human:
            notifier.bump("escalated")
        if out.is_hot_lead or out.escalate_to_human:
            await notifier.notify_hot_lead(event.username, out)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Telegram bildirishnomada xato: {}", exc)


async def _log(event: IncomingEvent, text: str, *, role: str) -> None:
    """Xabarni ERP suhbat jurnaliga yozadi (xotira). Xato bo'lsa jim o'tadi."""
    if not event.sender_id or not text:
        return
    try:
        await leads_client.log_message(
            user_id=event.sender_id,
            username=event.username,
            channel=event.channel,
            text=text,
            role=role,
            kind="comment" if event.kind == "comment" else "dm",
            # AI javobiga alohida ID yo'q — faqat mijoz xabarini ID bilan yozamiz
            ig_message_id=event.message_id if role == "user" else None,
            comment_id=event.comment_id,
            media_id=event.media_id,
            # Izohdan yangi lead ochmaymiz (har bir "🔥" izohi ro'yxatni
            # to'ldirib yubormasin) — DM esa har doim yoziladi.
            create_lead=event.kind != "comment",
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("Suhbatni jurnalga yozishda xato: {}", exc)


async def _handle_echo(event: IncomingEvent) -> None:
    """Akkauntimizdan chiqqan xabar: bizniki bo'lsa — e'tibor bermaymiz;
    operator qo'lda yozgan bo'lsa — botni o'sha suhbatda pauza qilamiz."""
    if not event.sender_id:
        return
    try:
        if await store.was_sent_by_bot(event.store_key, event.text):
            return  # bu botning o'z javobi, qaytib kelgan
        # Operator qo'lda yozgan javob ham suhbat tarixiga tushsin
        await _log(event, event.text, role="operator")
        await store.pause(event.store_key, settings.BOT_PAUSE_HOURS)
        logger.info(
            "Operator qo'lda javob berdi — bot {} soat pauzada: {}",
            settings.BOT_PAUSE_HOURS, event.sender_id,
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("Echo ishlashда xato: {}", exc)


async def _deliver(event: IncomingEvent, out: AgentOutput, *, is_first: bool = False) -> None:
    if event.channel == "telegram":
        await _deliver_telegram(event, out, is_first=is_first)
        return
    if event.kind == "comment" and event.comment_id:
        # Ochiq kommentга ≤1 daqiqa javob
        await instagram.reply_to_comment(event.comment_id, out.reply)
        # Shaxsiy ma'lumot kerak bo'lsa DM'ga o'tkazamiz (private reply)
        if out.move_to_dm:
            text = _with_disclosure(
                "Salom! Batafsil ma'lumot uchun shu yerda yozib turamiz 👇"
            )
            await instagram.send_private_reply(event.comment_id, text)
            await store.mark_sent(event.sender_id, text)
    elif event.kind == "dm":
        text = out.reply
        # Meta talabi: suhbatning BIRINCHI xabarida bot ekanini oshkor qilish
        # (tarix ERP'dan olinadi — Redis kesh bo'shab qolsa ham takrorlanmaydi)
        if is_first:
            text = _with_disclosure(text)
        await instagram.send_dm(event.sender_id, text)
        await store.mark_sent(event.store_key, text)


async def _deliver_telegram(
    event: IncomingEvent, out: AgentOutput, *, is_first: bool = False
) -> None:
    """Telegram shaxsiy chatiga javob (Business ulanishi bo'lsa — siz nomingizdan).

    Instagramdan farqi: javob oynasi cheklovi yo'q, izoh tushunchasi ham yo'q.
    """
    from app.telegram_business.webhook import connection_for_chat

    text = out.reply
    if is_first:
        text = _with_disclosure(text)

    chat_id = event.chat_id or event.sender_id
    conn_id = event.business_connection_id or await connection_for_chat(str(chat_id))
    result = await telegram.send_message(chat_id, text, business_connection_id=conn_id)
    if result.get("sent"):
        await store.mark_sent(event.store_key, text)
    else:
        logger.warning("Telegram javobi yuborilmadi: {}", result.get("error"))


async def _within_comment_limits(event: IncomingEvent) -> bool:
    """Izohga javob berish cheklovdan oshmaganini tekshiradi.

    Xatolik bo'lsa `True` qaytaradi — hisoblagich ishlamay qolgani uchun
    butun xizmatni to'xtatib qo'yish noto'g'ri bo'lardi.
    """
    try:
        media = event.media_id or "unknown"
        per_media = await store.bump_rate(f"cmt:{media}", _COMMENT_WINDOW)
        if per_media > _COMMENT_LIMIT:
            logger.error(
                "CHEKLOV: {} post ostida {} daqiqada {} ta javob — TO'XTATILDI. "
                "Sabab halqa bo'lishi mumkin (bot o'z izohiga javob beryapti).",
                media, _COMMENT_WINDOW // 60, per_media,
            )
            return False
        total = await store.bump_rate("cmt:all", _GLOBAL_WINDOW)
        if total > _GLOBAL_LIMIT:
            logger.error(
                "CHEKLOV: {} daqiqada jami {} ta izoh javobi — TO'XTATILDI.",
                _GLOBAL_WINDOW // 60, total,
            )
            return False
    except Exception as exc:  # noqa: BLE001
        logger.warning("Cheklov tekshiruvida xato (davom etamiz): {}", exc)
    return True


def _with_disclosure(text: str) -> str:
    """Suhbatning BIRINCHI xabariga bot ekanligini qo'shadi (Meta tavsiyasi)."""
    return f"{text}\n\n🤖 Men {settings.COMPANY_NAME}ning AI yordamchisiman. Operator kerak bo'lsa yozing — ulaymiz."


def _to_payload(event: IncomingEvent, out: AgentOutput) -> LeadPayload:
    return LeadPayload(
        source=event.channel,
        channel=event.channel,
        user_id=event.sender_id or None,
        username=event.username,
        ig_user_id=event.sender_id if event.channel == "instagram" else None,
        ig_username=event.username if event.channel == "instagram" else None,
        media_id=event.media_id,
        comment_id=event.comment_id,
        name=out.lead.name,
        contact=out.lead.contact,
        product_interest=out.lead.product_interest,
        language=out.language,
        intent=out.intent,
        lead_score=out.lead_score,
        summary=out.lead.summary,
        message_text=event.text,
        agent_reply=out.reply,
        extra={"is_hot_lead": out.is_hot_lead, "escalate": out.escalate_to_human},
    )
