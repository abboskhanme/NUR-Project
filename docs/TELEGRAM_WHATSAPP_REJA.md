# Telegram AI javob + Telegram → WhatsApp post ko'chirish — reja

> **Holat: BAJARILDI (2026-08-21).** Reja 2026-08-20 da tuzilgan, ertasiga
> to'liq qurildi va sinovdan o'tkazildi (A va B qismlari).
>
> **Sozlash qo'llanmasi: `docs/TELEGRAM_WHATSAPP_SETUP.md`** — bot yaratish,
> Business ulanishi, Meta shabloni va ERP sozlamalari shu yerda.
>
> Bog'liq hujjatlar: `docs/INSTAGRAM_AGENT_REJA.md`, `docs/INSTAGRAM_SETUP.md`.

---

## 0. Qisqa javob

| Ish | Mumkinmi | Reallik | Ish hajmi |
|---|---|---|---|
| **A.** Telegram shaxsiy chatlarga AI avto-javob | **Ha**, rasmiy Bot API | 95% | ~1.5 kun |
| **B.** Telegram kanal posti → 1 soatdan keyin WhatsApp kanalga | **Yarim-avtomatik ha** | 90% | ~2 kun (+0.5 kun katta videolar uchun) |
| ~~B2.~~ WhatsApp kanalga to'g'ridan-to'g'ri API bilan post | **Yo'q** | — | — |

**Nega B to'liq avtomatik emas:** Meta'ning rasmiy WhatsApp Cloud API'sida
**Kanallar (Channels) uchun API yo'q**. Kanalga post tashlaydigan xizmatlar
(Whapi.Cloud, WAHA) raqamni QR orqali "WhatsApp Web" sifatida ulaydi — bu
rasmiy emas, WhatsApp shartlariga zid va **raqam bloklanishi mumkin**. Biznes
raqami va kanal egaligi xavf ostida qolmasligi uchun bu yo'l tanlanmadi.

**Tanlangan yechim (B):** tizim tayyor postni (rasm/video + caption) kanal
admini bo'lgan xodimning shaxsiy WhatsApp raqamiga yuboradi, xodim uni
**Forward → kanal** qiladi (2 ta bosish). WhatsApp chatdagi xabarni kanalga
forward qilishga ruxsat beradi (matn, rasm, video, GIF, audio).

---

# A. Telegram shaxsiy chatlarda AI avto-javob

## A1. Nima uchun oson

AI "miya"si allaqachon qurilgan va **kanaldan mustaqil**:

- `agent/app/agent/core.py` — SalesAgent (persona + bilim bazasi)
- `agent/app/processing/pipeline.py` — dedup, operator pauzasi, lead, alert
- ERP xotirasi — `POST /leads/ingest/message`, `GET /leads/ingest/context`
- Leadlar → "Yozishmalar" tabi — operator qo'lda javob berishi

Telegram uchun faqat **adapter** kerak: kelgan xabarni shu pipeline'ga uzatish
va javobni Telegram orqali qaytarish.

## A2. Ikki yo'l (ikkalasi ham qurilishi mumkin)

**1) Telegram Business ulanishi** *(asosiy maqsad)* — odam **shaxsiy
akkauntingizga** yozadi, bot **siz nomingizdan** javob beradi, mijoz "bot"
yorlig'ini ko'rmaydi.
- Sozlamalar → Telegram Business → **Chatbots** → botni ulash.
- Telegram hujjati: **bot ulash uchun Premium SHART EMAS**
  (Business'ning boshqa funksiyalari Premium bilan keladi — ilovada tekshiriladi).
- Bot API: `business_connection`, `business_message`, `edited_business_message`
  yangilanishlari; javob yuborishda `business_connection_id` uzatiladi.
- Telegramning o'zida **har bir chatni botdan pauza qilish / uzish** bor —
  operator qo'lga olishi shu bilan ham, bizning qoidamiz bilan ham ishlaydi.

**2) Oddiy bot** — mijoz botning o'ziga yozadi. Premium/Business kerak emas.
Bizda buyurtma qabul qiladigan bot bor (`backend/app/integrations/telegram/`),
lekin AI javob **agent** tomonida turishi kerak (bilim bazasi va xotira o'sha yerda).

## A3. Arxitektura

```
Telegram (shaxsiy chat)
      │  business_message (webhook)
      ▼
 nur-agent  ──►  pipeline (dedup → xotira → AI → javob)
      │                 │
      │                 ├─► ERP: /leads/ingest/message  (suhbat jurnali)
      │                 └─► ERP: /leads/ingest/context  (xotira + faktlar)
      ▼
 sendMessage(business_connection_id=…)  →  mijoz "siz"dan javob oladi
```

## A4. Bosqichlar

1. **Yangi bot yaratish** (@BotFather) — `TELEGRAM_SALES_BOT_TOKEN`.
   ERP'ning mavjud boti bilan aralashtirmaslik kerak (u boshqa vazifada).
2. **Agentda webhook**: `agent/app/telegram_business/webhook.py`
   → `POST /webhook/telegram` (Caddy allaqachon `/agent/*` ni uzatadi).
   `setWebhook` ni startupda avtomatik qo'yish (Instagramdagi kabi).
3. **Adapter**: `agent/app/telegram_business/models.py` — Telegram update'ini
   mavjud `IncomingEvent` ga aylantiradi:
   - `channel="telegram"`, `sender_id=<tg user id>`, `username`, `message_id`
   - matnsiz xabar (ovoz/rasm) → `[Mijoz ovozli xabar yubordi]` (Instagramdagi kabi)
   - biz yozgan xabar (owner) → `echo` → operator pauzasi
4. **Pipeline umumlashtirish**: `IncomingEvent` ga `channel` maydoni; `_deliver`
   kanalga qarab Instagram yoki Telegram orqali yuboradi. Qolgan mantiq
   (dedup, xotira, lead, Telegram alert) **o'zgarmaydi**.
5. **ERP tomoni** — leadlar Instagram bilan aralashmasligi uchun:
   - migration: `leads.tg_user_id`, `leads.tg_username` (nullable, indeksli)
   - `LeadMessageIn`/`LeadContextOut` ga `channel` maydoni (`instagram|telegram`)
   - `_lead_for_conversation` — kanalga qarab mos ustun bo'yicha qidiradi
   - `source="telegram"`
6. **"Yozishmalar" tabi** — har suhbat yonida kanal ikonkasi (Instagram/Telegram),
   filtr: "Hammasi / Instagram / Telegram".
   ⚠️ Telegramda **24 soatlik oyna yo'q** — javob har doim yuboriladi, ya'ni
   `window` doim `open`.
7. **Sozlamalar** (Tizim sozlamalari katalogiga): `TELEGRAM_SALES_BOT_TOKEN`,
   `TG_BOT_ENABLED`, `TG_PAUSE_HOURS` (sukut 12).

## A5. Sinov rejasi

- Soxta update bilan (`/simulate` uslubida) — tarmoqsiz, AI mock bilan.
- Haqiqiy sinov: botni **o'z** akkauntingizga Business orqali ulab, boshqa
  telefondan yozib ko'rish. Tekshiriladi: javob "siz"dan ko'rinadimi, ERP'da
  suhbat yozilyaptimi, operator qo'lda yozsa bot jim turadimi.

## A6. Xavflar

| Xavf | Ehtimol | Yechim |
|---|---|---|
| Business ulanishi Premium talab qilishi | O'rta | Hujjatda "shart emas" deyilgan; bo'lmasa oddiy bot yo'li ishlaydi |
| Bot shaxsiy chatlarga "haddan tashqari" javob berishi | O'rta | Business sozlamasida istisno chatlar + har chatda pauza tugmasi |
| AI noto'g'ri narx aytishi | Past | Mavjud qoida: bilim bazasida yo'q bo'lsa → operatorga o'tkazadi |

---

# B. Telegram kanal → WhatsApp kanal (1 soat kechikish)

## B1. Oqim

```
Telegram kanal (post)
   │ channel_post  (bot kanalda admin)
   ▼
 ERP: channel_posts navbati  ──(1 soat kutadi)──►  WhatsApp Cloud API
                                                        │
                                          xodimning shaxsiy raqamiga
                                          rasm/video + caption
                                                        │
                                        xodim: Forward → WhatsApp kanal
```

## B2. Texnik cheklovlar (rejaga kiritilgan)

| Cheklov | Qiymat | Ta'siri |
|---|---|---|
| Cloud API rasm | 5 MB | Katta rasm siqiladi |
| Cloud API video | 16 MB | Kattalari siqiladi yoki o'tkazib yuboriladi |
| Telegram **Bot API** fayl yuklab olish | 20 MB | Kattaroq video uchun **local Bot API server** (2 GB) kerak |
| 24 soatlik oyna | Cloud API | Xodim javob yozsa yangilanadi; yopilsa utility shablon |
| Albom (bir nechta rasm) | — | Har rasm alohida xabar → kanalda alohida post |
| "Forwarded" yorlig'i | — | Kanalda ko'rinishi mumkin (kosmetik) |

## B3. Bosqichlar

1. **Migration + model**: `channel_posts`
   - `tg_chat_id`, `tg_message_id` (unikal juftlik — dublikat bo'lmasin)
   - `kind` (text/photo/video/album), `caption`, `media_path` (volume), `mime`, `size`
   - `planned_at` (post vaqti + `WA_DELAY_MINUTES`), `sent_at`, `status`
     (`pending|sent|failed|skipped`), `error`, `sent_to` (raqam)
2. **Telegram tinglovchi**: mavjud ERP boti (`backend/app/integrations/telegram/bot.py`)
   kanalga admin qilinadi → `channel_post` ushlanadi → media yuklab olinadi
   (`getFile`) → docker volume'ga saqlanadi → navbatga yoziladi.
3. **Navbat ishchisi** (APScheduler, `nur-telegram-bot` konteynerida, har 5 daq.):
   `planned_at <= now()` bo'lgan postlarni oladi → WhatsApp'ga yuboradi.
4. **WhatsApp klienti**: `backend/app/integrations/whatsapp/client.py`
   - media yuklash: `POST /{PHONE_NUMBER_ID}/media`
   - yuborish: `POST /{PHONE_NUMBER_ID}/messages` (image/video + caption)
   - xato kodlarini o'qish: oyna yopiq bo'lsa → shablon yuborish → keyin qayta urinish
5. **WhatsApp webhook** (`/api/v1/whatsapp/webhook`): xodim javob yozganini
   ushlaydi → `wa_window_until = now + 24h` yozib qo'yadi (oyna ochiqligini bilish uchun).
6. **Utility shablon**: Meta'da tasdiqlanadi (1–2 kun) — masalan
   `nur_post_tayyor`: "Yangi post tayyor. Ko'rish uchun shu xabarga javob yozing."
7. **ERP sahifasi** (kichik, additiv): Sozlamalar ichida yoki alohida
   "WhatsApp navbati" — postlar ro'yxati, holati, xatosi, **"Qayta yuborish"** va
   **"O'tkazib yuborish"** tugmalari. Media oldindan ko'rinadi.
8. **Sozlamalar** (Tizim sozlamalari katalogiga): `WA_PHONE_NUMBER_ID`,
   `WA_ACCESS_TOKEN` (maxfiy), `WA_TARGET_NUMBERS` (vergul bilan, kanal
   adminlari), `WA_DELAY_MINUTES` (60), `WA_TEMPLATE_NAME`, `TG_SOURCE_CHANNEL_ID`.
9. **(Ixtiyoriy, +0.5 kun)** Local Telegram Bot API server (docker) — 20 MB
   cheklovi olib tashlanadi, katta videolar ham ko'chadi. `ffmpeg` bilan
   16 MB gacha siqish.

## B4. Sinov rejasi

- Soxta `channel_post` bilan navbatga yozilishi va 1 soatlik hisob-kitob.
- WhatsApp klientini mock bilan sinash (oyna yopiq/ochiq, xato kodlari).
- Haqiqiy sinov: test kanalga post → 1 soatdan keyin xodim telefoniga kelishi →
  forward qilib kanalga qo'yish.

## B5. Xavflar

| Xavf | Ehtimol | Yechim |
|---|---|---|
| 24 soatlik oyna yopiq | Yuqori (kunlik post bo'lmasa) | Utility shablon avtomatik yuboriladi |
| Video 16 MB dan katta | O'rta | `ffmpeg` siqish; bo'lmasa "Telegramdan oling" izohi |
| Telegram Bot API 20 MB limiti | O'rta | Local Bot API server |
| Xodim forward qilishni unutishi | O'rta | Navbatda "yuborildi, lekin tasdiqlanmagan" holati + eslatma |

---

## C. Qaror talab qiladigan savollar (ish boshlashdan oldin)

1. **A uchun:** shaxsiy akkauntga Business ulaymizmi (siz nomingizdan javob),
   yoki mijozlar to'g'ridan-to'g'ri botga yozadimi?
2. **A uchun:** Telegram leadlari Instagram leadlari bilan **bitta ro'yxatda**
   tursinmi yoki filtr bilan ajratilsinmi?
3. **B uchun:** kechikish aynan 60 daqiqami, sozlanadigan bo'lsinmi?
4. **B uchun:** postni nechta xodimga yuboramiz (bittasi yetadimi)?
5. **B uchun:** katta videolar uchun local Bot API server ko'taramizmi
   (+0.5 kun), yoki hozircha faqat rasm/qisqa video bilan boshlaymizmi?

---

## D. Manbalar

- [Telegram — connected business bots](https://core.telegram.org/api/bots/connected-business-bots)
- [Telegram Business](https://core.telegram.org/api/business)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [WhatsApp Cloud API — media limitlari](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/media)
- [WhatsApp Business Platform](https://developers.facebook.com/documentation/business-messaging/whatsapp/about-the-platform)
- [WhatsApp — kanalga forward qilish](https://faq.whatsapp.com/699347952293912/?cms_platform=web)

---

## E. Nima qurildi (2026-08-21)

**A — Telegram AI yordamchisi**
- `agent/app/telegram_business/` — klient, update tahlilchisi, webhook
  (Business ulanishi ham, oddiy bot chati ham).
- Pipeline umumlashtirildi: `IncomingEvent.channel` va `store_key` — dedup,
  xotira, pauza va lead oqimi ikkala kanal uchun bitta.
- Migration `20260821_01`: `leads.tg_user_id`, `leads.tg_username`.
  ERP endpointlari `channel` bilan ishlaydi (eski `ig_*` maydonlari saqlangan).
- "Yozishmalar" tabida kanal ikonkasi va filtr; Telegramda javob oynasi doim ochiq.
- Agent endpointlari: `POST /admin/send-telegram`, `bot-pause`/`bot-state`
  endi `user_key` (`tg:<id>`) bilan.
- Sozlamalar: «Tizim sozlamalari → Telegram AI yordamchisi».

**B — WhatsApp ko'prigi**
- Migration `20260821_02`: `channel_posts` navbat jadvali (media BYTEA sifatida,
  yuborilgach o'chiriladi).
- `app/integrations/wa_bridge/` — kanal kuzatuvchisi (getUpdates) va yuboruvchi
  (`SKIP LOCKED` bilan), alohida konteyner `nur-wa-bridge`.
- `app/integrations/whatsapp/client.py` — Cloud API (media yuklash, rasm/video,
  shablon, 24 soatlik oyna xatosini tanish).
- ERP sahifasi: **WhatsApp navbati** (`/wa-bridge`, `telegram` ruxsati) —
  holat, media ko'rinishi, "Qo'ydim / Qayta / O'tkazish".
- Sozlamalar: «Tizim sozlamalari → Telegram → WhatsApp».

**Sinov:** agent 47 test, backend 81 unit test (+52 skip), 6 ta integratsion
to'plam (migratsiya zanjiri bilan), frontend `tsc` — hammasi toza.
