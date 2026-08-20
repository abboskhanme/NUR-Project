# NUR Agent — Instagram AI sotuv agenti

ERP'dan **mustaqil** Docker image. Instagram komment/DM webhookини oladi, AI
(Claude yoki Gemini) bilan sotuvchi sifatida javob beradi, qaynoq lead'ni ERP'ga
`POST /api/v1/leads/ingest` orqali uzatadi va Telegram'ga bildirishnoma yuboradi.

ERP kodiga **tegmaydi** — yagona ulanish HTTP ingest API (servis kaliti bilan).

## Struktura
```
agent/
├── app/
│   ├── main.py            FastAPI: webhook + /health + /simulate + scheduler
│   ├── config.py          barcha .env sozlamalari
│   ├── models.py          AgentOutput, LeadPayload (ERP ingest bilan mos)
│   ├── ai/                Claude + Gemini provayderlar + factory
│   ├── agent/             SalesAgent, o'zbek/kirill persona prompti, bilim bazasi
│   ├── instagram/         webhook (HMAC), Graph API klienti, parser, importer
│   ├── leads/             ERP klienti: lead ingest + suhbat xotirasi
│   ├── telegram/          qaynoq lead alerti + kunlik hisobot
│   ├── state/             tezkor kesh: dedup, pauza, tarix keshi (Redis)
│   └── processing/        pipeline: webhook -> AI -> javob -> lead -> alert
├── data/knowledge/        mahsulot/narx/FAQ (SIZ to'ldirasiz)
└── tests/                 soxta payload bilan uchdan-uchgacha test
```

## 1. Sozlash
```bash
cp .env.example .env
# .env ni to'ldiring: ANTHROPIC_API_KEY (yoki GEMINI_API_KEY), IG_* tokenlar,
# AGENT_INGEST_KEY (ERP bilan BIR XIL), TELEGRAM_* .
# Bilim faylini yozing:
$EDITOR data/knowledge/company_and_products.md
```

`AGENT_INGEST_KEY` ERP tomonidagi `AGENT_INGEST_KEY` bilan **bir xil** bo'lishi
shart (ERP dev compose'da default: `dev-agent-key-change-me`).

## 2. Lokal ishga tushirish va test (App Review kutmasdan)
```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt

# testlar (tarmoqsiz, soxta AI provayder)
pytest -q

# serverni ishga tushirish
uvicorn app.main:app --reload --port 8020

# soxta hodisa bilan to'liq oqimni tekshirish (haqiqiy AI kalit kerak):
curl -X POST localhost:8020/simulate \
  -H 'Content-Type: application/json' \
  -d '{"text":"Qancha turadi?","kind":"comment","username":"ali"}'
```

`/simulate` haqiqiy AI provayderni chaqiradi (kalit `.env` da bo'lsin), lekin
Instagram'ga yozish/ERP'ga yozish oqimini ham ishga soladi — shuning uchun
ERP ishlab turgani va `AGENT_INGEST_KEY` to'g'ri bo'lgani ma'qul. Faqat AI
javobini ko'rmoqchi bo'lsangiz, ERP/IG tokenlarsiz ham loglardan javob ko'rinadi.

## 3. Docker (bitta compose ichida, additiv)
Dev — repo ildizidan:
```bash
docker compose --profile agent up -d --build agent agent-redis
# webhook lokal: ngrok http 8020
```
Prod:
```bash
docker compose -f docker-compose.prod.yml --env-file .env.prod \
  --profile agent up -d --build
# Meta webhook URL: https://<DOMAIN>/agent/webhook/instagram
```
`agent` profili ortida bo'lgani uchun oddiy `docker compose up` xatti-harakati
**o'zgarmaydi** (mavjud ERP servislariga ta'sir yo'q).

## 4. AI provayderni almashtirish
`.env` da `AI_PROVIDER=claude` yoki `AI_PROVIDER=gemini`. Yuqori hajmda arzon/tez
uchun `CLAUDE_MODEL=claude-sonnet-5` yoki `AI_PROVIDER=gemini` qo'ying.

## 5. Bilim bazasini yangilash
`data/knowledge/*.md` ni o'zgartirgach:
```bash
curl -X POST localhost:8020/reload-knowledge
```
yoki konteynerni qayta ishga tushiring.

## Meta App Review (tashqi, 1–3 hafta)
Ruxsatlar: `instagram_manage_comments`, `instagram_manage_messages`,
`pages_manage_metadata`, `pages_read_engagement`. Tasdiq kelgunча hamma narsani
`/simulate` va soxta webhook payload bilan to'liq test qilib bo'ladi. Ruxsat
kelgach faqat `.env` ga tokenlarni qo'yib "yoqamiz".

## Suhbat xotirasi (AI oldingi gaplarni eslaydi)

Har bir DM/izoh va har bir javob darhol ERP'ga yoziladi
(`POST /api/v1/leads/ingest/message`), javob berishdan oldin esa butun yozishma
va ma'lum faktlar (telefon, qiziqqan mahsulot) ERP'dan olinadi
(`GET /api/v1/leads/ingest/context`).

Nima uchun ERP'da: Instagram API tarixni 30 kun saqlaydi, Redis esa faqat kesh.
Yagona ishonchli manba — ERP bazasi. Shu sababli:

- mijoz bir hafta oldin raqamini yozgan bo'lsa, AI uni **qayta so'ramaydi**;
- operator telefondan qo'lda yozgan javob ham tarixга tushadi;
- ovozli xabar/rasm kabi matnsiz xabarlar `[Mijoz ovozli xabar yubordi]` deb
  yoziladi va AI mazmunini matn bilan yozishni so'raydi.

Izohlar (kommentlar) jurnalga yoziladi, lekin YANGI lead ochmaydi — har bir "🔥"
izohi Leadlar ro'yxatini to'ldirib yubormasligi uchun.

## Eski suhbatlarni import qilish

Webhook ishlamagan davrda kelgan yoki Instagram'ning "Requests" papkasida
turgan yozishmalar tizimga tushmaydi. Ularni ko'chirib olish:

```bash
curl -X POST https://<DOMAIN>/agent/admin/import-conversations \
     -H "X-Agent-Key: <AGENT_INGEST_KEY>"
```

yoki ERP'da: **Tizim sozlamalari → Instagram → "Eski suhbatlarni import qilish"**.

Import fon rejimida ketadi, natija Telegram'ga keladi. Leadlar `instagram_import`
manbasi bilan belgilanadi va ularga AI javob YOZMAYDI (Instagram'da javob oynasi
mijozning oxirgi xabaridan 24 soat). Instagram bu suhbatlarni **30 kun** saqlaydi
— shundan keyin API orqali ham olib bo'lmaydi.

> Kelajakda request'ga tushmasligi uchun: Instagram ilovasi → Sozlamalar →
> Xabarlar va story javoblari → Xabarlarni boshqarish → "Instagramdagi boshqalar"
> → **Chat**. Shunda kuzatmaydiganlar ham to'g'ridan-to'g'ri inboxga tushadi.
