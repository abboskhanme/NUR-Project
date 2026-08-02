"""Leadlar bo'limiga NAMUNAVIY (demo) ma'lumot qo'shish — kanban doskani ko'rish uchun.

Har status ustuniga bir nechta lead + suhbat hodisalari qo'shadi (Instagram AI
agenti topganday). Faqat DEV/DEMO uchun — prod bazaga ishlatmang.

Ishga tushirish (backend papkasidan):
    python -m scripts.seed_leads
Docker ichida:
    docker compose exec backend python -m scripts.seed_leads

Qayta tozalab qo'shish (eski demo leadlarni o'chirib):
    python -m scripts.seed_leads --reset

Demo leadlar `extra.seed = true` bilan belgilanadi — shu orqali topiladi/o'chiriladi.
"""
import asyncio
import sys
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import delete, func, select

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.models.lead import Lead, LeadEvent

TZ = ZoneInfo(settings.TIMEZONE)


def _ago(days: float) -> datetime:
    return datetime.now(TZ) - timedelta(days=days)


# (status, username, name, contact, product, language, intent, score, summary, days_ago,
#  [(kind, message_text, agent_reply), ...])
SAMPLES = [
    # --- new ---
    ("new", "dilnoza_style", "Dilnoza", None, "Kotyol 50L", "uz-Latn", "price_inquiry", 55,
     "Narx so'radi, hali javob kutmoqda", 0.2,
     [("comment", "Qancha turadi?", "Salom! Narxni DM'ga yozib yubordim 👌")]),
    ("new", "sardor_uy", "Sardor", None, "Bunker", "uz-Cyrl", "product_info", 45,
     "Bunker haqida so'radi", 0.5,
     [("comment", "Бункер борми?", "Ҳа, бор! DM'га ёзинг, батафсил айтаман 🙌")]),
    ("new", "malika.home", None, None, "Garelka", "uz-Latn", "greeting", 25,
     "Umumiy qiziqish", 0.8, [("comment", "Zo'r ekan", "Rahmat! 💛")]),
    ("new", "otabek_777", "Otabek", None, "Suv isitgich", "ru", "price_inquiry", 50,
     "Цена интересует", 1.1, [("dm", "Сколько стоит?", "Здравствуйте! Уточню и напишу 👍")]),

    # --- contacted ---
    ("contacted", "gulnoza_shop", "Gulnoza", "+998901234501", "Kotyol 100L", "uz-Latn",
     "buying_intent", 65, "Bog'lanildi, narx aytildi, o'ylayapti", 2.0,
     [("dm", "100 litrligi kerak edi", "100L mavjud. Manzilingizni yuborsangiz, yetkazamiz."),
      ("dm", "Toshkentdaman", "Ajoyib, yetkazib beramiz 🚚")]),
    ("contacted", "jamshid_fer", "Jamshid", "+998907654302", "Bunker", "uz-Cyrl",
     "product_info", 60, "Bunker o'lchamlari muhokama qilindi", 3.0,
     [("dm", "Катта бункер керак", "Қайси ҳажм — 200л ми, каттароқми?")]),
    ("contacted", "nafisa_k", "Nafisa", None, "Garelka", "uz-Latn", "price_inquiry", 55,
     "Narx aytildi", 3.5, [("dm", "Narxi?", "Garelka narxini yubordim 👌")]),

    # --- qualified ---
    ("qualified", "bekzod_qurilish", "Bekzod", "+998901112203", "Kotyol 50L", "uz-Latn",
     "buying_intent", 82, "Jiddiy xaridor, raqam qoldirdi", 4.0,
     [("dm", "2 dona kerak, qachon tayyor?", "2 kunda tayyor. Buyurtmani rasmiylashtiramizmi?"),
      ("dm", "Ha, rasmiylashtiring", "Zo'r! Menejerimiz bog'lanadi 📞")]),
    ("qualified", "shahnoza_biz", "Shahnoza", "+998935556604", "Kotyol 100L", "ru",
     "buying_intent", 78, "Готова купить, ждёт счёт", 5.0,
     [("dm", "Нужен счёт на 100л", "Выставлю счёт, отправлю на этот номер 📄")]),
    ("qualified", "akmal_montaj", "Akmal", "+998977778805", "Bunker", "uz-Cyrl",
     "buying_intent", 75, "O'rnatish bilan so'radi", 6.0,
     [("dm", "Ўрнатиб берасизми?", "Ҳа, ўрнатиб берамиз. Манзил ва рақамингизни ёзинг.")]),

    # --- won ---
    ("won", "dilshod_pro", "Dilshod", "+998901239906", "Kotyol 50L", "uz-Latn",
     "buying_intent", 90, "Mijozga aylandi, buyurtma berdi", 7.0,
     [("dm", "Oldim, rahmat!", "Sizga ham rahmat! Xaridingiz muborak bo'lsin 🎉")]),
    ("won", "kamola_home", "Kamola", "+998907771107", "Garelka", "uz-Cyrl",
     "buying_intent", 88, "Buyurtma yakunlandi", 9.0,
     [("dm", "Етказиб беринглар", "Буюртма қабул қилинди, эртага етказамиз ✅")]),

    # --- lost ---
    ("lost", "random_user22", None, None, "Kotyol 50L", "uz-Latn", "spam", 10,
     "Qiziqmadi / javob bermadi", 8.0,
     [("comment", "qimmat ekan", "Sifatли mahsulot 💛 Savol bo'lsa yozing.")]),
    ("lost", "test_akk", "Sanjar", None, "Bunker", "ru", "other", 30,
     "Boshqa firmadan oldi", 10.0,
     [("dm", "уже купил в другом месте", "Понятно! Будем рады в следующий раз 🙏")]),
]


async def _existing_count(db) -> int:
    return (
        await db.execute(
            select(func.count()).select_from(Lead).where(Lead.extra["seed"].astext == "true")
        )
    ).scalar_one()


async def _delete_seed(db) -> int:
    ids = (
        await db.execute(select(Lead.id).where(Lead.extra["seed"].astext == "true"))
    ).scalars().all()
    if ids:
        await db.execute(delete(Lead).where(Lead.id.in_(ids)))  # events cascade
    return len(ids)


async def main(reset: bool) -> None:
    async with AsyncSessionLocal() as db:
        if reset:
            n = await _delete_seed(db)
            await db.commit()
            print(f"O'chirildi: {n} ta eski demo lead")

        if await _existing_count(db) > 0:
            print("Demo leadlar allaqachon mavjud. Qayta qo'shish: --reset bilan ishga tushiring.")
            return

        created = 0
        for (status, username, name, contact, product, lang, intent, score,
             summary, days, events) in SAMPLES:
            base_time = _ago(days)
            lead = Lead(
                source="instagram",
                ig_user_id=f"demo_{username}",
                ig_username=username,
                name=name,
                contact=contact,
                product_interest=product,
                language=lang,
                intent=intent,
                lead_score=score,
                summary=summary,
                status=status,
                extra={"seed": True},
                created_at=base_time,
                updated_at=base_time,
            )
            db.add(lead)
            await db.flush()  # lead.id
            for i, (kind, msg, reply) in enumerate(events):
                db.add(LeadEvent(
                    lead_id=lead.id,
                    kind=kind,
                    message_text=msg,
                    agent_reply=reply,
                    actor="agent",
                    created_at=base_time + timedelta(minutes=5 * (i + 1)),
                    updated_at=base_time + timedelta(minutes=5 * (i + 1)),
                ))
            created += 1

        await db.commit()
        print(f"Qo'shildi: {created} ta namunaviy lead (kanban doskada ko'rinadi).")


if __name__ == "__main__":
    asyncio.run(main(reset="--reset" in sys.argv))
