# Telegram / WhatsApp AI yordamchisi + WhatsApp ko'prigi — sozlash qo'llanmasi

> Kod tayyor va sinovdan o'tgan. Bu hujjat — **sizning tomoningizda** bajariladigan
> qadamlar. Reja va texnik tafsilotlar: `docs/TELEGRAM_WHATSAPP_REJA.md`.

Deploy (ikkala qism uchun ham):

```bash
cd /opt/NUR-Project && git pull
docker compose -f docker-compose.prod.yml --env-file .env.prod --profile agent \
  up -d --build backend frontend agent wa-bridge
```

Migratsiyalar startda avtomatik qo'llanadi (`20260821_01`, `20260821_02`, `20260912_01`).

> **Muhim:** hech qanday token `.env` ga yozilmaydi — hammasi **Tizim
> sozlamalari** menyusidan (super-admin) kiritiladi va bazada **shifrlangan**
> holda saqlanadi. `.env` da faqat infratuzilma qoladi: `DATABASE_URL`,
> `SECRET_KEY`, `AGENT_INGEST_KEY`.
>
> Qiymatni saqlagach: **WhatsApp ko'prigi** ~1 daqiqada, **Telegram AI
> yordamchisi** ~5 daqiqada o'zi qo'llaydi (webhook ham o'zi o'rnatiladi).
> Konteynerni qayta ishga tushirish shart emas.

---

# A. Telegram shaxsiy chatlarida AI javob

## A1. Bot yaratish (2 daqiqa)

1. Telegramda **@BotFather** → `/newbot` → nom va username bering.
2. Chiqqan **tokenni** nusxalang.

> ⚠️ Bu bot ERP boti va Instagram bildirishnoma botidan **alohida** bo'lishi shart.
> Bitta token ikki joyda ishlatilsa Telegram so'rovlarni rad eta boshlaydi.

## A2. ERP sozlamalari (1 daqiqa)

**Tizim sozlamalari → Telegram AI yordamchisi:**

| Maydon | Qiymat |
|---|---|
| Bot token | @BotFather bergan token |
| AI javob yoqilganmi | `ha` |
| Webhook maxfiy kaliti | O'zingiz o'ylab topgan 20+ belgili satr |

Saqlagach agent ~5 daqiqada sozlamani oladi va webhookni **o'zi** o'rnatadi
(qo'lda hech narsa qilinmaydi). Tekshirish: `https://<domen>/agent/health` →
`"telegram_connected": true`.

## A3. Business ulanishi (shaxsiy akkauntingizga)

Telegram ilovasida:

1. **Sozlamalar → Telegram Business → Chatbots**
2. Botingiz username'ini kiriting.
3. **"Reply to messages"** (xabarlarga javob berish) ruxsatini **yoqing** —
   busiz bot faqat o'qiydi, yoza olmaydi.
4. Kerak bo'lsa "Exclude chats" orqali istisno chatlarni belgilang.

Shundan keyin sizga yozgan odam **siz nomingizdan** javob oladi ("bot" yorlig'i
ko'rinmaydi).

> Agar Business bo'limi ochilmasa (Premium talab qilsa), ikkinchi yo'l ham
> ishlaydi: mijozlar **botning o'ziga** yozadi — u holda A3 qadami shart emas.

## A4. Tekshirish

1. Boshqa telefondan botga/akkauntingizga "Salom, narxi qancha?" deb yozing.
2. ERP → **Leadlar → Yozishmalar → Telegram** — suhbat paydo bo'ladi.
3. Xuddi Instagramdagidek: **"AI o'chiq/yoniq"** tugmasi, operator javob yozsa
   AI 12 soat jim turadi, telefon raqami avtomatik ajratib olinadi.

**Instagramdan farqi:** Telegramda 24 soatlik javob oynasi **yo'q** — istalgan
vaqtda javob yozish mumkin.

## A5. Bot menyusi (narxlar, manzil va h.k. — AI'siz tayyor javob)

ERP → **Bot menyusi** (`telegram` ruxsati) → **Bo'lim qo'shish**:
tugma nomi (`💰 Narxlar`), buyruq (`narxlar`), matn va 10 tagacha rasm.

Mijoz bo'limni tanlasa bot AI'ga murojaat qilmay, **darhol** shu matn va
rasmlarni yuboradi (2+ rasm — albom). Boshqa har qanday savolga AI javob beradi.

| Qayerda | Mijoz qanday tanlaydi |
|---|---|
| Botning o'z chati | Pastdagi tugmalar (`/start` da chiqadi) yoki «Menu» → `/narxlar` |
| Business ulanishi | Salomlashish ostidagi tugmalar (mijoz `/start` yoki «menyu» yozsa), yoki `/narxlar` |
| Havola | `t.me/<bot_nomi>?start=narxlar` — to'g'ri shu bo'limni ochadi |

Bilib qo'yish kerak:
- Business chatida pastki klaviatura **Telegram tomonidan taqiqlangan** — shu
  sabab u yerda inline tugmalar ishlatiladi.
- Matn 1024 belgidan uzun bo'lsa rasm ostiga sig'maydi — rasmlardan keyin
  alohida xabar bo'lib ketadi.
- Operator suhbatni o'z qo'liga olgan (AI pauzada) bo'lsa ham mijoz tugma
  bossa menyu javobi yuboriladi — bu AI javobi emas, mijozning aniq so'rovi.
- Yuborilgan menyu javobi Leadlar yozishmasiga ham tushadi, shuning uchun AI
  keyingi savolda («50 litrlisi qancha edi?») nima yuborilganini biladi.
- O'zgarish botda bir necha soniyada paydo bo'ladi (agent o'chiq bo'lsa —
  ishga tushgach, ko'pi bilan 5 daqiqada).

---

# B. Telegram kanal posti → WhatsApp kanali

Eslatma: WhatsApp **Kanallariga** to'g'ridan-to'g'ri yozadigan rasmiy API yo'q.
Shuning uchun tizim postni **xodimning shaxsiy WhatsApp raqamiga** yuboradi, u
esa bir marta **Forward → kanal** qiladi (2 ta bosish).

## B1. Kanalni o'qiydigan bot (2 daqiqa)

1. @BotFather → `/newbot` → **yana bitta** bot (A1 dagidan boshqa).
2. Telegram kanalingiz → **Administrators → Add Admin** → shu botni qo'shing
   (faqat "Post messages" ruxsati yetarli).
3. Kanal ID kerak bo'lsa: kanalga biror post tashlang va uni botga forward qiling,
   yoki `-100...` ko'rinishidagi ID ni oling. Bo'sh qoldirsangiz — bot admin
   bo'lgan barcha kanallardan oladi.

## B2. WhatsApp Cloud API (Meta)

1. **Meta for Developers → App → WhatsApp → API Setup**:
   - **Phone Number ID** ni nusxalang (biznes raqamingizniki).
   - **Permanent token** yarating: Business Settings → System Users → yangi user →
     "Generate token" → `whatsapp_business_messaging` + `whatsapp_business_management`.
     (API Setup sahifasidagi vaqtinchalik token 24 soatda tugaydi.)
2. **Shablon (template)** yarating — WhatsApp Manager → Message Templates:
   - Kategoriya: **Utility**
   - Nomi: `nur_post_tayyor`
   - Tili: **uz** (yoki `ru`/`en` — ERP'da mos tilni ko'rsating)
   - Matn (o'zgaruvchisiz): *"Yangi post tayyor. Ko'rish uchun shu xabarga javob yozing."*
   - Tasdiqlash odatda 1–2 kun.

## B3. ERP sozlamalari

**Tizim sozlamalari → Telegram → WhatsApp:**

| Maydon | Nima yoziladi |
|---|---|
| Ko'prik yoqilganmi | `ha` |
| Telegram bot token | B1 dagi bot tokeni |
| Kanal ID | `-1001234567890` (ixtiyoriy) |
| Kechikish (daqiqa) | `60` |
| WhatsApp Phone Number ID | B2 dan |
| WhatsApp access token | B2 dagi doimiy token |
| Qabul qiluvchi raqamlar | Kanal admini bo'lgan xodim raqami(lari), vergul bilan |
| Shablon nomi | `nur_post_tayyor` |

## B4. Birinchi ishga tushirish

1. Xodim o'z telefonidan **bizning WhatsApp biznes raqamimizga** istalgan xabar
   yozsin ("salom" yetadi) — shu bilan 24 soatlik oyna ochiladi.
2. Telegram kanalga sinov posti tashlang.
3. ERP → **WhatsApp navbati** — post "Navbatda" holatida ko'rinadi, yuborilish
   vaqti yozilgan bo'ladi.
4. Vaqti kelganda xodim WhatsApp'ga rasm/video + matn tushadi.
5. Xodim uni **bosib turib → Forward → kanal** qiladi.
6. ERP'da o'sha post yonidagi **"Qo'ydim"** tugmasini bosadi (hisobot uchun).

## B5. Nima bo'lishi mumkin

| Holat | Tizim nima qiladi |
|---|---|
| Xodim 24 soatdan beri javob yozmagan | Avval **shablon** yuboriladi; xodim javob yozishi bilan post **avtomatik** ketadi |
| Video 20 MB dan katta | Post "O'tkazib yuborildi" bo'ladi va sababi yoziladi — qo'lda joylaysiz |
| Video 16 MB dan katta (WhatsApp cheklovi) | Xuddi shunday — "O'tkazib yuborildi" |
| Xato bo'lsa | "Qayta" tugmasi bilan qayta navbatga qo'yiladi |
| 24 soat davomida yuborilmasa | "Xato" holatiga o'tadi |

Katta videolarni ham avtomatlashtirmoqchi bo'lsangiz — **local Telegram Bot API
server** ko'tarish kerak (2 GB gacha). Keyin "Telegram API manzili" sozlamasiga
o'sha serverning manzilini yozib qo'yish yetadi, kod o'zgarmaydi.

---

# C. WhatsApp'ga yozganlarga AI javob berishi

Instagram va Telegramdagi bilan **aynan bir xil** AI: bir xil bilim bazasi, bir
xil suhbat xotirasi (ERP'da), bir xil "AI o'chiq/yoniq" tugmasi va operator
aralashsa bot jim turishi. Farqi faqat kanalda.

> Hisob ma'lumotlari (**Phone Number ID** va **access token**) yuqoridagi
> **B2** bo'limida kiritilgani bilan bir xil — qayta kiritish shart emas.
> Bitta WhatsApp raqami ikkala vazifani ham bajaradi: kanal posti chiqishi
> **va** mijozga javob berish.

## C1. ERP sozlamalari (1 daqiqa)

**Tizim sozlamalari → WhatsApp AI yordamchisi:**

| Maydon | Nima yoziladi |
|---|---|
| AI javob yoqilganmi | `ha` |
| Webhook verify token | O'zingiz o'ylab topgan 20+ belgili satr (C2 da kerak bo'ladi) |
| App Secret | Meta App → Settings → Basic → App Secret. Bo'sh qoldirsangiz Instagram App Secret ishlatiladi |

Agar **B2** hali bajarilmagan bo'lsa, **Tizim sozlamalari → Telegram → WhatsApp**
dagi `WhatsApp Phone Number ID` va `WhatsApp access token` ni ham to'ldiring —
javob yuborish shular orqali ketadi.

## C2. Meta webhook (2 daqiqa)

**Meta for Developers → App → WhatsApp → Configuration → Webhook → Edit:**

| Maydon | Qiymat |
|---|---|
| Callback URL | `https://<domeningiz>/agent/webhook/whatsapp` |
| Verify token | C1 da yozgan qiymat |

**Verify and save** → keyin **Manage** tugmasi orqali `messages` maydoniga
obuna bo'ling (**Subscribe**).

> Xohlasangiz `message_echoes` ga ham obuna bo'ling: u holda siz WhatsApp
> ilovasidan qo'lda javob yozsangiz, bot o'sha suhbatda avtomatik jim turadi.

Agent sozlamani ~5 daqiqada oladi. Tekshirish: `https://<domen>/agent/health`
→ `"whatsapp_connected": true`.

## C3. Tekshirish

1. Boshqa telefondan **biznes raqamingizga** "Salom, narxi qancha?" deb yozing.
2. AI bir necha soniyada javob beradi; birinchi xabarga bot ekanligi haqidagi
   eslatma avtomatik qo'shiladi.
3. ERP → **Leadlar → Yozishmalar → WhatsApp** — suhbat paydo bo'ladi va u
   yerdan operator o'zi ham javob yozishi mumkin.

## C4. Bilib qo'yish kerak

| Holat | Nima bo'ladi |
|---|---|
| Mijozning oxirgi xabaridan 24 soat o'tdi | ERP'dan erkin matn yozib bo'lmaydi (Meta qoidasi) — telefon qilinadi |
| Operator ERP'dan javob yozdi | AI o'sha suhbatda 12 soat jim turadi |
| «AI javob yoqilganmi» = `yo'q` | Xabarlar baribir **Leadlar** bo'limiga tushadi, faqat AI javob bermaydi |
| Mijoz ovozli xabar / rasm yubordi | Tarixga "[Mijoz ovozli xabar yubordi]" deb yoziladi, AI matn bilan yozishni so'raydi |
| Mijoz "operator kerak" dedi | AI menejerga o'tkazadi va Telegramga bildirishnoma keladi |

---

## Xavfsizlik va cheklovlar

- Ikkala qism ham **rasmiy API**larda ishlaydi — raqam yoki akkaunt bloklanish
  xavfi yo'q.
- WhatsApp tokeni faqat ERP bazasida, **shifrlangan** holda saqlanadi.
- Telegram AI yordamchisining tokeni agent sozlamalarida (shifrlangan).
- WhatsApp webhook'i **imzo bilan** tekshiriladi (`X-Hub-Signature-256`) — begona
  so'rov qabul qilinmaydi.
- Ko'prik alohida konteynerda (`nur-wa-bridge`) ishlaydi: u to'xtasa ERP ishlashda
  davom etadi, postlar esa navbatda saqlanib qoladi.
