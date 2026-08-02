# Instagram AI agentini ulash — tez yo'l (App Review'siz)

> **Asosiy xabar:** biz **faqat o'z akkauntimiz** uchun ishlatamiz, shuning uchun
> Meta'ning **App Review**'idan o'tish **SHART EMAS**. Facebook Page ham kerak emas.
> Real ish vaqti: **~30–40 daqiqa**.

Bu qo'llanma **"Instagram API with Instagram Login"** yo'lidan boradi. Meta
hujjatida aniq yozilgan:

> *"Standard Access is the default access level for all apps… **If your app only
> serves your Instagram professional account or an account you manage, Standard
> Access is all your app needs.**"*
>
> *"Advanced Access is the access level required if your app serves Instagram
> professional accounts that you **don't** own or manage…"*

Ya'ni: akkaunt bizniki → Standard Access yetadi → App Review yo'q.

---

## 0. Shartlar (2 daqiqa)

1. Instagram akkaunt **Professional (Business yoki Creator)** bo'lsin.
   Instagram ilova → Sozlamalar → Akkaunt turi → Professional.
2. Serveringizda **HTTPS** ishlayotgan bo'lsin (Caddy buni avtomatik qiladi).

Facebook Page, Business Verification, App Review — **kerak emas**.

---

## 1. Meta App yaratish (~10 daqiqa)

1. https://developers.facebook.com → **My Apps** → **Create App**.
2. Use case: **"Other"** → App type: **Business** → nom bering.
3. Dashboard → **Add product** → **Instagram** ni qo'shing.
4. Chap menyudan **Instagram → API setup with Instagram login** ni oching.
   (Diqqat: *"API setup with Facebook login"* EMAS — bizga birinchisi kerak.)

Shu sahifadan olinadi:

| Nima | Qayerdan |
|---|---|
| **Instagram App ID** | 3-bo'lim: *"Set up Instagram business login"* |
| **Instagram App Secret** | Xuddi shu joyda (**Show** bosing) |

### 1.1. Redirect URI ni ro'yxatga qo'shish

Xuddi shu sahifada **"Set up Instagram business login" → Business login settings**:

- **OAuth redirect URI** ga quyidagini kiriting:
  ```
  https://<domeningiz>/agent/connect/callback
  ```
- **Save**.

> Manzil ERP domeningiz + `/agent` prefiksi. Caddy `/agent/*` ni agentga
> yo'naltiradi (`Caddyfile` da tayyor).

---

## 2. ERP'ga kiritish (~5 daqiqa)

ERP → **Tizim sozlamalari** (faqat super-admin) → **Instagram** bo'limi:

| Maydon | Qiymat |
|---|---|
| Instagram App ID | 1-bosqichdan |
| Instagram App Secret | 1-bosqichdan |
| Webhook verify token | **O'zingiz o'ylab topasiz** (masalan `nur_ig_2026`) |
| Agentning tashqi manzili | `https://<domeningiz>/agent` |

**Saqlash** ni bosing.

So'ng **AI** bo'limi: provayder (`claude`) + **Anthropic API kaliti**
(https://console.anthropic.com dan; Claude Code obunasi API uchun ishlamaydi —
API alohida billing).

So'ng **Bilim bazasi** bo'limini to'ldiring — agent FAQAT shu ma'lumot asosida
javob beradi, bilmagan narsasini o'ylab topmaydi:
kompaniya, **mahsulotlar va narxlar**, yetkazish/to'lov/kafolat, FAQ.

---

## 3. Agentni ishga tushirish

```bash
cd /opt/NUR-Project
cp agent/.env.example agent/.env      # faqat 2 ta qatorni to'ldiring:
                                      #   ERP_INGEST_URL, AGENT_INGEST_KEY
docker compose -f docker-compose.prod.yml --env-file .env.prod \
  --profile agent up -d --build
```

Tekshirish:

```bash
curl https://<domeningiz>/agent/health
# {"status":"ok","instagram_connected":false,"knowledge_chars":1234}
```

> `AGENT_INGEST_KEY` — agent bilan ERP orasidagi maxfiy kalit. Ikkala `.env` da
> **bir xil** bo'lishi shart (ERP `.env.prod` va `agent/.env`).

---

## 4. Webhook ulash (~5 daqiqa)

Meta Dashboard → **Instagram → API setup with Instagram login** →
2-bo'lim **"Configure webhooks"**:

- **Callback URL:** `https://<domeningiz>/agent/webhook/instagram`
- **Verify token:** 2-bosqichda yozgan verify token (aynan bir xil)
- **Verify and save** → yashil bo'lishi kerak.
- **Subscribe** maydonlari: `comments`, `messages`, `message_echoes`.

> `message_echoes` muhim: siz telefondan qo'lda javob yozsangiz, bot buni
> sezib o'sha suhbatda **jim turadi** (sozlamada `BOT_PAUSE_HOURS`, standart 12 soat).

---

## 5. Akkauntni ULASH — bitta tugma (~1 daqiqa)

ERP → **Tizim sozlamalari → Instagram** → **«Instagram'ni ulash»** tugmasi.

Bosganingizda:
1. Instagram'ning **o'z login oynasi** ochiladi (parolingizni biz ko'rmaymiz).
2. Ruxsat berasiz: xabarlar + izohlar.
3. Agent avtomatik:
   - qisqa tokenni **60 kunlik** tokenga almashtiradi,
   - Instagram User ID ni aniqlaydi,
   - webhook'ga obuna qiladi,
   - hammasini **Tizim sozlamalariga saqlaydi**.

Sahifada *"Instagram ulandi ✅"* chiqsa — tayyor.

> Token 60 kunlik, lekin agent uni **har kuni tekshirib, 45-kundan keyin
> avtomatik yangilaydi**. Qo'lda hech narsa qilish shart emas. Agar yangilash
> muvaffaqiyatsiz bo'lsa — Telegram'ga ogohlantirish keladi.

---

## 6. Sinash

1. **Izoh:** o'z postingizga boshqa akkauntdan "Qancha turadi?" deb yozing →
   agent ochiq javob beradi va DM'ga taklif qiladi.
2. **DM:** "Kotyol 50L narxi?" → agent javob beradi, raqam so'raydi.
3. ERP → **Leadlar** menyusida yangi lead paydo bo'ladi.
4. Qaynoq lead bo'lsa — Telegram'ga xabar keladi.

Agentsiz, tarmoqsiz sinash (AI oqimini tekshirish):

```bash
curl -X POST https://<domeningiz>/agent/simulate \
  -H 'Content-Type: application/json' \
  -d '{"text":"Kotyol narxi qancha?","kind":"dm"}'
docker compose -f docker-compose.prod.yml logs -f agent
```

---

## 7. Qachon App Review KERAK bo'ladi

Faqat quyidagi holatda:

- Ilovani **boshqa kompaniyalarga** sotmoqchi bo'lsangiz (ular o'z akkauntini
  ulashi kerak bo'lsa).

Bizning holatda — kerak emas. Ilovani **Live rejimga** o'tkazish ham shart emas:
Standard Access development rejimda o'z akkauntingiz uchun ishlaydi.

---

## 8. Blok xavfi

Yo'q. Bu **rasmiy API** — Meta Platform Terms bo'yicha to'liq qonuniy.
Ban'lar odatda parol bilan kiradigan "avtomatlashtirish" botlaridan keladi;
biz ManyChat ishlatadigan aynan o'sha eshikdan kiramiz, faqat o'z kodimiz bilan.

Kod darajasida himoya:
- yuborishlar **soniyasiga 1 ta** bilan cheklangan (throttle),
- har bir javob AI tomonidan **boshqacha** yoziladi (shablon takrorlanmaydi),
- 24 soatlik oyna hurmat qilinadi (faqat mijoz yozgandan keyin javob beramiz),
- birinchi xabarda **"Men AI yordamchiman"** deb oshkor qilinadi (Meta talabi),
- mijoz "operator" desa — darhol odamga o'tkaziladi (Telegram alerti).

---

## 9. Muammo bo'lsa

| Belgi | Sabab / yechim |
|---|---|
| Webhook "Verify and save" qizil | Verify token mos emas, yoki `/agent/*` Caddy'da yo'q. `curl https://<domen>/agent/health` bilan tekshiring |
| «Ulash» tugmasi o'chiq | App ID / App Secret / tashqi manzil to'ldirilmagan yoki saqlanmagan |
| `Invalid redirect_uri` | Meta'dagi redirect URI 1.1-bo'limdagidek **aynan** bo'lsin (oxirida `/` yo'q) |
| Agent javob bermayapti | `docker compose logs -f agent`; `AI` bo'limida API kalit bormi; bilim bazasi bo'shmi |
| Lead ERP'ga tushmayapti | `AGENT_INGEST_KEY` ikkala `.env` da bir xilmi |
| Bot suhbatda jim | Operator qo'lda javob bergan (12 soat pauza) — bu ataylab shunday |
