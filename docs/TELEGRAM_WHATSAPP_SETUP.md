# Telegram AI yordamchisi + WhatsApp ko'prigi — sozlash qo'llanmasi

> Kod tayyor va sinovdan o'tgan. Bu hujjat — **sizning tomoningizda** bajariladigan
> qadamlar. Reja va texnik tafsilotlar: `docs/TELEGRAM_WHATSAPP_REJA.md`.

Deploy (ikkala qism uchun ham):

```bash
cd /opt/NUR-Project && git pull
docker compose -f docker-compose.prod.yml --env-file .env.prod --profile agent \
  up -d --build backend frontend agent wa-bridge
```

Migratsiyalar startda avtomatik qo'llanadi (`20260821_01`, `20260821_02`).

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

## Xavfsizlik va cheklovlar

- Ikkala qism ham **rasmiy API**larda ishlaydi — raqam yoki akkaunt bloklanish
  xavfi yo'q.
- WhatsApp tokeni faqat ERP bazasida, **shifrlangan** holda saqlanadi.
- Telegram AI yordamchisining tokeni agent sozlamalarida (shifrlangan).
- Ko'prik alohida konteynerda (`nur-wa-bridge`) ishlaydi: u to'xtasa ERP ishlashda
  davom etadi, postlar esa navbatda saqlanib qoladi.
