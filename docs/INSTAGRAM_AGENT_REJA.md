# NUR Agent — Instagram AI sotuv agenti + ERP "Leadlar" moduli

> **Bu — arxitektor rejasi (v2).** `PLAN.md` dagi g'oyalar saqlab qolindi, lekin
> struktura mavjud NUR ERP kodiga (RBAC, `navItems`, alembic, Caddy/compose)
> **aniq mos** qilib qayta ishlandi. Har bir qadam bosqichma-bosqich bajariladigan
> darajada aniq. Til: butun UI **o'zbekcha** (i18n yo'q — bu tizim qoidasi).

---

## 0. Qisqa javob: "Shuni qanchalik qilolamiz?"

**To'liq qilolamiz — 100%.** Ikki mustaqil bo'lakka bo'lamiz:

1. **Instagram AI Agent** — mavjud ERP'ga **umuman tegmaydigan**, **alohida Docker image**
   (`nur-agent`). U webhook oladi, AI bilan javob beradi, va tayyor lead'ni ERP'ga
   **HTTP orqali** uzatadi. Alohida repo/papka, alohida deploy, alohida ishga tushadi.

2. **ERP "Leadlar" moduli** — hozirgi platforma ichida **yangi, additiv menyu**
   (mavjud hech narsani buzmaydi — bu ham tizim qoidasi). Mavjud pattern bilan:
   yangi `leads` moduli (RBAC), yangi model + router + sahifa + navItem.

**Yagona texnik cheklov — bizga bog'liq emas:** Instagram uchun Meta'ning
**App Review**'idan o'tish kerak (`instagram_manage_comments`, `..._messages`).
Bu **1–3 hafta** ketishi mumkin. Kod tayyor bo'lib turadi, ruxsat kelishi bilan
"yoqamiz". App Review kutilayotganda ham hamma narsani **soxta webhook** bilan
to'liq test qilib bo'ladi (0-kunlik ishga tushirish bloklanmaydi).

**Nega bu arxitektura to'g'ri:**
- Agent alohida image → Instagram/AI yuki ERP'ni sekinlashtirmaydi, alohida qulaydi/qayta ishga tushadi.
- ERP `leads` jadvalining egasi bitta (ERP + alembic) → ikki servis migratsiya ustida urishmaydi.
- Ulanish yagona, tor: **`POST /api/v1/leads/ingest`** (servis kaliti bilan). Ertaga
  agentni C#/Node'ga ko'chirsangiz ham ERP tomoni o'zgarmaydi.

---

## 1. Umumiy arxitektura

```
        Instagram (komment / DM)
                │  webhook (real vaqt, ≤1 daq.)
                ▼
┌───────────────────────────────────────────────────────┐
│   nur-agent  (ALOHIDA DOCKER IMAGE — ERP'ga tegmaydi)  │
│                                                        │
│  webhook → dedup → AI Agent (Claude/Gemini)            │
│     ├─▶ ochiq kommentga javob (≤1 daq.)                │
│     ├─▶ DM → sotuv suhbati (24s oyna) + kontakt olish  │
│     ├─▶ suhbat holati → Redis (yoki SQLite)            │
│     └─▶ Telegram: qaynoq lead alerti + kunlik hisobot  │
│                     │                                  │
│          POST /api/v1/leads/ingest  (X-Agent-Key)      │
└─────────────────────┼──────────────────────────────────┘
                      ▼
┌───────────────────────────────────────────────────────┐
│  NUR ERP (mavjud FastAPI + React — FAQAT QO'SHAMIZ)    │
│                                                        │
│  • ingest endpoint  → Lead + LeadEvent yozadi          │
│  • yangi "Leadlar" menyusi (RBAC: leads moduli)        │
│  • ro'yxat / filtr / status quvuri (new→won/lost)       │
│  • analitika (konversiya, top mahsulot, til)            │
│  • "Leaddan mijoz/buyurtma yaratish" → mavjud Sotuvga   │
└───────────────────────────────────────────────────────┘
```

**Ikki repo/papka:**
- `NUR_Agent/` — agent (yangi, mustaqil).
- `NUR-Project/` — mavjud ERP (bu yerda faqat additiv o'zgarish).

**Prod'da ikkalasi bitta droplet, bitta `docker-compose.prod.yml`** ichida (yangi
`agent` servisi qo'shiladi), Caddy orqali marshrutlanadi. Xohlansa keyin alohida
serverga ajratsa ham bo'ladi — ulanish HTTP bo'lgani uchun hech narsa o'zgarmaydi.

---

## 2. Chegara qarori (eng muhim arxitektura tanlovi)

**Qaror: Agent → ERP ulanishi faqat HTTP ingest API orqali (servis kaliti).**
Agent ERP bazasiga to'g'ridan-to'g'ri **yozmaydi**.

| Variant | Baho |
|---|---|
| **A. HTTP ingest API + servis kaliti** ✅ tanlandi | Tor chegara, DB egasi bitta, agentni mustaqil deploy/almashtirish oson. "Butunlay alohida image" talabiga to'liq mos. |
| B. Umumiy Postgres'ga to'g'ridan yozish | Tezroq, lekin ikki servis bitta sxema/migratsiyani baham ko'radi — noaniqlik, bog'liqlik. Rad etildi. |

Agentning **o'z holati** (DM suhbat konteksti, dedup) ERP'da emas — agentning
**o'z Redis/SQLite**'sida saqlanadi. Shunda ERP bazasi faqat biznes lead'lar bilan toza qoladi.

---

## 3. ERP TOMONI (mavjud `NUR-Project` — faqat additiv)

> Barcha o'zgarish mavjud patternni **aynan** takrorlaydi (namuna: `targets`/`debts`
> mustaqil modullari). Hech qaysi mavjud fayl **buzilmaydi**, faqat qo'shiladi.

### 3.1. Model — `backend/app/models/lead.py`

`UUIDPrimaryKeyMixin` + `TimestampMixin` (mavjud `db/base.py`). Ikki jadval:

```python
class Lead(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "leads"

    source: Mapped[str] = mapped_column(String(30), default="instagram", index=True)
    # Instagram identifikatorlari
    ig_user_id: Mapped[Optional[str]] = mapped_column(String(64), index=True)
    ig_username: Mapped[Optional[str]] = mapped_column(String(120), index=True)
    media_id: Mapped[Optional[str]] = mapped_column(String(64))   # qaysi post/reels
    comment_id: Mapped[Optional[str]] = mapped_column(String(64))

    # Mazmun
    name: Mapped[Optional[str]] = mapped_column(String(255))
    contact: Mapped[Optional[str]] = mapped_column(String(64))    # tel/username
    product_interest: Mapped[Optional[str]] = mapped_column(String(255))
    language: Mapped[Optional[str]] = mapped_column(String(10))   # uz-Cyrl/uz-Latn/ru/en
    intent: Mapped[Optional[str]] = mapped_column(String(30))
    lead_score: Mapped[int] = mapped_column(Integer, default=0)   # 0..100
    summary: Mapped[Optional[str]] = mapped_column(Text)          # AI xulosasi (o'zbekcha)

    # Ish quvuri (ERP xodimlari boshqaradi)
    status: Mapped[str] = mapped_column(String(20), default="new", index=True)
    #   new → contacted → qualified → won / lost
    assigned_to_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))

    # Konversiya izlari (ixtiyoriy — leaddan mijoz/buyurtma yaratilганda to'ladi)
    customer_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("customers.id", ondelete="SET NULL"))
    order_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="SET NULL"))

    extra: Mapped[dict] = mapped_column(default=dict)  # JSONB — kelajakka zaxira
    events: Mapped[list["LeadEvent"]] = relationship(
        back_populates="lead", cascade="all, delete-orphan", passive_deletes=True)


class LeadEvent(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Suhbat/hodisa jurnali — har bir xabar+javob yoki status o'zgarishi."""
    __tablename__ = "lead_events"

    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("leads.id", ondelete="CASCADE"), index=True)
    kind: Mapped[str] = mapped_column(String(20))     # comment / dm / reply / status / note
    message_text: Mapped[Optional[str]] = mapped_column(Text)   # mijoz yozgani
    agent_reply: Mapped[Optional[str]] = mapped_column(Text)    # agent javobi
    actor: Mapped[str] = mapped_column(String(20), default="agent")  # agent / user
    meta: Mapped[dict] = mapped_column(default=dict)
```

`models/__init__.py` ga `from app.models.lead import Lead, LeadEvent` + `__all__` ga qo'shish.

### 3.2. Schemas — `backend/app/schemas/lead.py`
`ORMBase` (mavjud `schemas/common.py`) asosida: `LeadIngest` (agent yuboradigan JSON),
`LeadOut`, `LeadUpdate` (status/assign/note), `LeadEventOut`, `LeadAnalytics`.

### 3.3. Router — `backend/app/api/v1/leads.py`

**Ikki xil kirish (auth):**

```python
# (a) Odam-uchun (ERP xodimlari) — mavjud RBAC bilan
router = APIRouter(dependencies=[Depends(module_guard("leads"))])

GET    /leads                 # ro'yxat + filtr (status, source, sana, ball, intent, til)
GET    /leads/{id}            # detal + events (suhbat tarixi)
PATCH  /leads/{id}            # status / assigned_to / note (leads:write)
POST   /leads/{id}/convert    # → mijoz (+ ixtiyoriy prefill buyurtma) yaratadi
GET    /leads/analytics       # konversiya, top mahsulot, til taqsimoti, kunlik

# (b) Agent-uchun ingest — servis kaliti bilan (JWT emas!)
ingest_router = APIRouter()   # module_guard YO'Q
POST   /leads/ingest          # Depends(require_agent_key)
```

**`require_agent_key`** — yangi kichik dependency (`core/dependencies.py` yoki
`core/agent_auth.py`): `X-Agent-Key` header'ini `settings.AGENT_INGEST_KEY` bilan
solishtiradi (`hmac.compare_digest`). Xato bo'lsa 401. Bu — agentga alohida, uzoq
muddatli sirli kalit; foydalanuvchi JWT'siga umuman bog'liq emas.

**Ingest mantiq (idempotent):** `comment_id`/`ig_user_id` bo'yicha oxirgi ochiq
lead'ni topadi; bor bo'lsa yangi `LeadEvent` qo'shadi (dublikat Lead yaratmaydi),
yo'q bo'lsa yangi `Lead` + `LeadEvent`. Javob: `201 {id, status}`.

Ikkalasini `api/v1/__init__.py` da ro'yxatga olamiz:
```python
api_router.include_router(leads.router,        prefix="/leads", tags=["Leads / Marketing"])
api_router.include_router(leads.ingest_router, prefix="/leads", tags=["Leads / Marketing"])
```

### 3.4. RBAC — yangi `leads` moduli
- `backend/app/core/permissions.py` → `MODULES` ro'yxatiga `"leads"` qo'shish.
- `frontend/src/lib/permissions.ts` → `MODULES` ga `'leads'` qo'shish.
- Boshqa hech narsa shart emas — `module_guard`, `Can`, `navItems` avtomatik ishlaydi.
- (Ixtiyoriy) direktor/sotuv rollariga `leads:read/write` biriktiriladi (UI'dagi
  mavjud rollar matritsasidan).

### 3.5. Alembic migratsiya
`backend/alembic/versions/20260713_01_add_leads.py` — `leads` + `lead_events`
jadvallari. Prod'da startup'da `alembic upgrade head` avtomatik qo'llaydi
(mavjud sozlama). Namuna: `20260710_01_add_targets.py`.

### 3.6. Frontend — yangi menyu (additiv)
- **`components/layout/navItems.ts`** ga bitta qator (mavjud tartibga mos joyга):
  ```ts
  { to: '/leads', label: 'Leadlar', icon: Sparkles, module: 'leads' },
  ```
  (`Sparkles`/`Megaphone`/`Contact` — `lucide-react` dan.)
- **`app/App.tsx`** ga marshrut:
  ```tsx
  <Route path="leads" element={<RequireModule module="leads"><LeadsPage/></RequireModule>} />
  <Route path="leads/:leadId" element={<RequireModule module="leads"><LeadDetailPage/></RequireModule>} />
  ```
- **`pages/LeadsPage.tsx`**, **`pages/LeadDetailPage.tsx`** + **`features/leads/`**
  (ro'yxat, filtr, status quvuri (kanban yoki jadval), suhbat tarixi, analitika kartalari).
- **`api/`** — `features/leads/api.ts` (mavjud axios `client` bilan).
- Yozuv amallari `Can perm="leads:write"` bilan o'ralади (mavjud pattern).

### 3.7. Leaddan konversiya (biznes qiymati)
`POST /leads/{id}/convert` — qaynoq lead'ni:
1. **Customer** yaratadi (`source="instagram"` — mavjud `Customer.source` maydoni buni
   allaqachon qo'llab-quvvatlaydi), `full_name`/`phone` lead'dan.
2. Ixtiyoriy: **Order** qoralamasini oldindan to'ldiradi (mavjud Sotuv oqimiga ulanadi).
3. `lead.customer_id`/`order_id`/`status="won"` ni belgilaydi.

Shu bilan Instagram → lead → mijoz → buyurtma **yagona zanjir** hosil bo'ladi va
mavjud sotuv analitikasiga tabiiy tushadi.

---

## 4. AGENT TOMONI (`NUR_Agent/` — alohida image)

Stack: **Python + FastAPI** (ERP bilan bir xil, jamoaga tanish). Struktura:

```
NUR_Agent/
├── Dockerfile
├── requirements.txt
├── .env.example
├── data/knowledge/company_and_products.md   # mahsulot/narx/FAQ (foydalanuvchi to'ldiradi)
├── app/
│   ├── main.py            # FastAPI: webhook + /health + scheduler startup
│   ├── config.py          # pydantic-settings (barcha .env)
│   ├── models.py          # AgentOutput, LeadPayload (ERP ingest bilan bir xil)
│   ├── ai/
│   │   ├── base.py        # AIProvider (abstract)
│   │   ├── claude_provider.py     # anthropic AsyncAnthropic, structured output
│   │   ├── gemini_provider.py     # google-genai, response_schema
│   │   └── factory.py     # .env → provayder (singleton)
│   ├── agent/
│   │   ├── core.py        # SalesAgent: xabar → AgentOutput
│   │   ├── prompts.py     # o'zbek/kirill sotuv personasi (eng muhim qism)
│   │   └── knowledge.py   # bilim faylini yuklash + kesh + reload()
│   ├── instagram/
│   │   ├── webhook.py     # GET verify + POST (HMAC-SHA256 signature)
│   │   ├── client.py      # Graph API: kommentga javob, private reply, DM
│   │   └── models.py      # webhook payload sxemalari
│   ├── leads/
│   │   └── client.py      # ERP'ga POST /leads/ingest (X-Agent-Key, retry)
│   ├── telegram/
│   │   └── notifier.py    # qaynoq lead alerti + kunlik hisobot
│   ├── state/
│   │   └── store.py       # Redis (yoki SQLite fallback): DM konteksti + dedup
│   └── processing/
│       └── pipeline.py    # webhook → agent → javob → lead → telegram
└── tests/                 # soxta payload bilan uchdan-uchgacha test
```

### 4.1. AI qatlami (almashtiriladigan — Claude **va** Gemini)
- `AIProvider.generate(system, messages, output_model) -> BaseModel` — abstract.
- **Claude:** `AsyncAnthropic`, model `settings.CLAUDE_MODEL` (default `claude-opus-4-8`;
  arzonroq uchun `.env` da `claude-sonnet-5`). Strukturali chiqish + **prompt caching**
  (system+knowledge `cache_control: ephemeral` — har javobda bilim keshdan, arzon/tez).
- **Gemini:** `google-genai`, `gemini-2.5-flash` (tez/arzon), `response_schema=AgentOutput`.
- `factory.py` `settings.AI_PROVIDER` bo'yicha birini beradi.
> Model ID/SDK sintaksisini tasdiqlash uchun `/claude-api` skill'idan foydalaning.

### 4.2. `AgentOutput` (strukturali JSON — ikkala provayder ham shu sxemani qaytaradi)
`reply`, `language`, `intent`, `lead_score(0..100)`, `is_hot_lead`, `move_to_dm`,
`escalate_to_human`, `lead: {name, contact, product_interest, summary}`.

### 4.3. Sotuv prompti (`prompts.py`) — kalit talablar
- **Persona:** NUR'ning samimiy, tez, ishonchli sotuvchisi.
- **Til/yozuv:** mijoz **kirill** yozsa — kirillда, **lotin** yozsa — lotinда, **sheva**da,
  rasmiy emas. Rus/ingliz bo'lsa — o'sha tilда. Yozuvni mijoz xabaridan aniqla.
- **Narx yolg'on emas:** faqat `{knowledge}` ичидаги narx/mahsulot. Bilmasa → o'ylab topma,
  `escalate_to_human=true`, "operatorlarimiz bog'lanadi".
- **Spamga qarshi:** har javob biroz boshqacha, tabiiy (bir xil shablon Meta'da spam).
- **Qisqa:** ochiq komment 1–2 gap; DM'da batafsilroq + harakatga chaqir ("raqamingizni yuboring").
- 2–3 ta o'zbek (kirill) namuna javob bilan mustahkamlanadi.

### 4.4. Instagram integratsiyasi (Graph API, `httpx.AsyncClient`)
- **GET `/webhook/instagram`** — Meta verify (`hub.challenge`).
- **POST** — `X-Hub-Signature-256` HMAC tekshiruvi → o'z kommentini o'tkazib yubor →
  dedup → `BackgroundTasks`'ga topshir, 200'ni **darhol** qaytar (Meta 5s kutadi).
- `client.py`: `reply_to_comment`, `send_private_reply` (7 kun/1 marta),
  `send_dm` (24s oyna); 429/rate-limit'да backoff.

### 4.5. Pipeline
`process_event`: dedup → kontekst yig' (media, username, oldingi DM tarixi state'dan) →
`agent.handle()` → kommentga ≤1 daq. javob → (kerak bo'lsa) DM → `is_hot_lead` bo'lsa
`leads.client.push()` (ERP ingest) → `is_hot_lead|escalate` bo'lsa Telegram alert → log.
Har bosqich alohida `try/except` — biri yiqilsa boshqasi ishlaydi.

### 4.6. Telegram (faqat bildirishnoma — suhbat emas)
Qaynoq lead alerti + soatlik/kunlik jamlanma (APScheduler). Botfather token + chat id.
> Eslatma: ERP'ning o'z Telegram boti bor (`integrations/telegram`). Agent'niki **alohida bot**
> (boshqa token) — chalkashmaslik uchun. Yoki xohlansa bir botning boshqa chat'iga.

---

## 5. Docker integratsiya

### 5.1. Dev — `docker-compose.yml` ga yangi servis
```yaml
  agent:
    build: { context: ./../NUR_Agent, dockerfile: Dockerfile }
    container_name: nur-agent
    env_file: ../NUR_Agent/.env
    environment:
      ERP_INGEST_URL: http://backend:8000/api/v1/leads/ingest
      AGENT_INGEST_KEY: ${AGENT_INGEST_KEY}
    ports: ["8020:8000"]     # webhook lokal test (ngrok bilan)
    depends_on: [backend]
  # ixtiyoriy: agent uchun redis
  agent-redis:
    image: redis:7-alpine
```
> Yoki agentni o'z `NUR_Agent/docker-compose.yml`'ida saqlab, umumiy tarmoq (external
> network) orqali ERP'ga ulash — ikkalasi ham ishlaydi. Bitta compose — sodda deploy.

### 5.2. Prod — `docker-compose.prod.yml` ga `agent` (+ ixtiyoriy `agent-redis`)
- ERP'ga ichki tarmoq orqali ulanadi: `ERP_INGEST_URL=http://backend:8000/...`.
- Webhook uchun tashqi HTTPS kerak → **Caddy**'ga marshrut (`Caddyfile`):
  - Variant A: yo'l bo'yicha — `handle /agent/* { reverse_proxy agent:8000 }` →
    Meta webhook URL: `https://<domen>/agent/webhook/instagram`.
  - Variant B: subdomen — `agent.<domen> { reverse_proxy agent:8000 }` (aniqroq, tavsiya).
- Agent image ichida "baked" (dev volume yo'q), `--workers 2`.

### 5.3. Domen
Mavjud "Cloudflare DNS-only + Caddy auto-HTTPS" rejasiga mos: agent uchun bitta
qo'shimcha A-record (`agent.<domen>`) yoki asosiy domen ostidagi `/agent/*` yo'li.

---

## 6. Konfiguratsiya

**Agent `.env`:**
```env
AI_PROVIDER=claude            # claude | gemini
ANTHROPIC_API_KEY=
CLAUDE_MODEL=claude-opus-4-8
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash

IG_VERIFY_TOKEN=
IG_APP_SECRET=
IG_ACCESS_TOKEN=
IG_USER_ID=
GRAPH_API_VERSION=v21.0

ERP_INGEST_URL=http://backend:8000/api/v1/leads/ingest
AGENT_INGEST_KEY=            # ERP bilan bir xil sirli kalit

TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=

REDIS_URL=redis://agent-redis:6379/0   # yoki bo'sh → SQLite fallback
KNOWLEDGE_DIR=data/knowledge
LOG_LEVEL=INFO
```

**ERP `.env.prod` ga bitta qator qo'shiladi:**
```env
AGENT_INGEST_KEY=<agent bilan bir xil kalit>
```
(`backend/app/core/config.py` `Settings` ga `AGENT_INGEST_KEY` maydoni.)

---

## 7. API shartnomasi (agent ↔ ERP)

**`POST /api/v1/leads/ingest`**  ·  header: `X-Agent-Key: <AGENT_INGEST_KEY>`
```jsonc
{
  "source": "instagram",
  "ig_user_id": "1789...", "ig_username": "ali_valiyev",
  "media_id": "1784...", "comment_id": "1790...",
  "name": "Ali", "contact": "+99890...", "product_interest": "Kotyol 50L",
  "language": "uz-Cyrl", "intent": "buying_intent", "lead_score": 85,
  "summary": "Narx so'radi, DM'ga o'tdi, raqam qoldirdi.",
  "message_text": "Qancha turadi?", "agent_reply": "Assalomu alaykum! ..."
}
```
Javob: `201 { "id": "...", "status": "new", "duplicate": false }`.
Auth xato → `401`. ERP tushib qolса → agent 2–3 marta retry qiladi, so'ng Telegram'ga
"ingest failed" xabari (lead yo'qolmasin).

---

## 8. Xavfsizlik
- Barcha token'lar `.env` da (repo'ga tushmaydi; `.gitignore` allaqachon bor).
- Webhook — **HMAC-SHA256 signature** majburiy tekshiruv.
- Ingest — `X-Agent-Key` + `hmac.compare_digest`; TLS ichida (Caddy).
- ERP RBAC — `leads` moduli `module_guard` bilan; ingest esa alohida servis-kaliti.
- PII (telefon/username) — minimal saqlash, faqat lead uchun zarur maydonlar.
- Rate-limit — mavjud `slowapi` ingest endpoint'ida ham.

---

## 9. Bosqichli reja (checklist)

### Bosqich 0 — Tashqi tayyorgarlik (foydalanuvchi; parallel ketadi)
- [ ] Instagram → Professional akkaunt + Facebook Page'ga ulash
- [ ] Meta Developer App; ruxsatlar (`instagram_manage_comments`, `..._messages`,
      `pages_manage_metadata`, `pages_read_engagement`); **App Review boshlash** ← vaqt omili
- [ ] Uzoq muddatli access token
- [ ] Telegram bot (BotFather) + chat id
- [ ] AI kaliti (Anthropic **yoki** Gemini)
- [ ] **Bilim fayli** (mahsulot/narx/FAQ) → `data/knowledge/`

### Bosqich 1 — ERP "Leadlar" moduli (App Review'ga bog'liq emas — darrov qilinadi)
- [ ] `models/lead.py` (Lead + LeadEvent) + `__init__.py`
- [ ] `schemas/lead.py`
- [ ] `api/v1/leads.py` (human CRUD + `ingest`) + `require_agent_key`
- [ ] `MODULES` ga `leads` (backend + frontend)
- [ ] Alembic `20260713_01_add_leads.py`
- [ ] Frontend: navItem, marshrut, `LeadsPage`/`LeadDetailPage`, `features/leads/`
- [ ] `POST /leads/ingest` ni `curl` bilan test (soxta lead)

### Bosqich 2 — Agent MVP (kommentga auto-javob)
- [ ] Skelet, `config.py`, `.env`, `requirements.txt`, `Dockerfile`
- [ ] AI abstraksiya (Claude + Gemini) + factory
- [ ] `knowledge.py` + namuna bilim fayli
- [ ] `prompts.py` (o'zbek/kirill persona) + `SalesAgent`
- [ ] Webhook (GET verify + POST signature) + `reply_to_comment`
- [ ] `pipeline` → ochiq kommentga ≤1 daq. javob
- [ ] **Soxta webhook payload** bilan uchdan-uchgacha lokal test (App Review'siz)

### Bosqich 3 — DM sotuv + lead ERP'ga
- [ ] `send_private_reply` / `send_dm`, DM holati (Redis/SQLite, 24s oyna)
- [ ] `leads/client.py` → ERP ingest (retry + Telegram fallback)
- [ ] dedup

### Bosqich 4 — ERP Leadlar UI to'liq + konversiya + analitika
- [ ] Status quvuri (kanban/jadval), filtr, suhbat tarixi
- [ ] `POST /leads/{id}/convert` → Customer (+ prefill Order)
- [ ] Analitika (konversiya, top mahsulot, til taqsimoti)

### Bosqich 5 — Telegram hisobot
- [ ] Qaynoq lead alerti + kunlik/soatlik jamlanma (APScheduler)

### Bosqich 6 — Mustahkamlash + prod
- [ ] Spamga qarshi javob xilma-xilligi, rate-limit, escalation oqimi
- [ ] `docker-compose.prod.yml` ga `agent` (+ redis), Caddy marshruti/subdomen
- [ ] Monitoring/log, xatolarga chidamlilik
- [ ] Meta App Review tasdig'idan keyin — **jonli yoqish**

---

## 10. Kim nima qiladi / vaqt

| Ish | Kim | Bloklovchi |
|---|---|---|
| ERP Leadlar moduli (1-bosqich) | Biz (kod) | Hech narsa — bugun boshlanadi |
| Agent MVP + soxta test (2–3) | Biz (kod) | AI kaliti + bilim fayli |
| Meta App Review | Foydalanuvchi + Meta | **1–3 hafta** (tashqi) |
| Jonli Instagram yoqish | Biz | App Review tasdig'i |

**Xulosa:** App Review kutilayotgan vaqtda ERP moduli + agent to'liq yozilib, soxta
payload bilan tekshirilib turadi. Ruxsat kelishi bilan faqat token qo'yib "yoqamiz".

---

## 11. Ochiq qarorlar (tasdig'ingiz kerak — reja shu 3 taga tayanadi)

1. **AI default:** Claude (`claude-opus-4-8`, sifatli) yoki Gemini (`2.5-flash`, arzon/tez)?
   → Ikkalasi ham config'da; qaysisi **default** yoqilsin? (Tavsiya: dastlab Gemini bilan
   arzon test, jonli sotuvда Claude.)
2. **Agent deploy:** bitta droplet (mavjud compose'ga `agent` qo'shamiz) yoki alohida server?
   (Tavsiya: bitta droplet — sodda; keyin ajratsa bo'ladi.)
3. **Webhook manzili:** `agent.<domen>` subdomen yoki `<domen>/agent/*` yo'l?
   (Tavsiya: subdomen — toza.)

---

*Tayyorladi: NUR Agent arxitektura rejasi (v2). Keyingi qadam — 11-banddagi 3 qarorni
tasdiqlash, so'ng 1-bosqichdan (ERP Leadlar moduli) boshlash.*
