# NUR Project — NUR TECHNO GROUP

NUR TECHNO GROUP kompaniyasining ichki ERP / CRM tizimi. Sotuv, Servis, Moliya,
HR va Ta'minot bo'limlarini birlashtiruvchi zamonaviy veb-platforma.

Loyiha ikki qismdan iborat:

- **`backend/`** — Python 3.11+ / FastAPI / SQLAlchemy 2.0 (async) / PostgreSQL / Alembic
- **`frontend/`** — React 18 + TypeScript + Vite + Tailwind CSS + TanStack Query

> Docker ishlatish shart emas — har bir qism alohida lokal kompyuterda yoki
> serverda ishga tushiriladi.

## Tezkor boshlash

### 1. PostgreSQL ni o'rnatish

Lokal kompyuteringizda PostgreSQL 14+ bo'lishi kerak. Yangi DB yarating:

```sql
CREATE DATABASE nur_erp;
```

### 2. Backend ishga tushirish

```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt

cp .env.example .env
# .env faylida DATABASE_URL va boshqa qiymatlarni o'zgartiring

# Jadvallar yaratish + boshlang'ich ma'lumotlar (super admin, rollar, mahsulotlar)
python -m scripts.seed

# Yoki Alembic migratsiya:
alembic revision --autogenerate -m "init"
alembic upgrade head

# Serverni ishga tushirish
uvicorn app.main:app --reload
```

Backend manzili: <http://localhost:8000>

Swagger hujjati: <http://localhost:8000/api/docs>

### 3. Frontend ishga tushirish

```bash
cd frontend
npm install
cp .env.example .env

npm run dev
```

Frontend manzili: <http://localhost:5173>

### 4. Birinchi login

Seed scripti standart Super Admin yaratadi:

- Telefon: `+998901234567`
- Parol: `Admin@12345`

(Parolni darhol o'zgartiring — Settings → Parolni o'zgartirish)

## Loyiha tuzilmasi

```
NUR Project/
├── backend/
│   ├── app/
│   │   ├── api/v1/        # FastAPI routerlar (auth, orders, ...)
│   │   ├── core/          # config, security, dependencies
│   │   ├── db/            # SQLAlchemy session, Base
│   │   ├── models/        # SQLAlchemy ORM modellari
│   │   ├── schemas/       # Pydantic v2 sxemalari
│   │   ├── services/      # biznes mantiq
│   │   ├── integrations/  # telegram, cbu
│   │   └── main.py        # FastAPI app
│   ├── alembic/           # migratsiyalar
│   ├── scripts/seed.py    # boshlang'ich ma'lumotlar
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── app/           # App.tsx, router
│   │   ├── api/           # axios client + interceptors
│   │   ├── components/    # layout, UI
│   │   ├── features/      # feature-based modules
│   │   ├── pages/         # router-darajadagi sahifalar
│   │   ├── stores/        # Zustand (auth, ui)
│   │   ├── lib/           # format, cn
│   │   ├── locales/       # uz, ru, en
│   │   └── main.tsx
│   ├── tailwind.config.ts
│   ├── vite.config.ts
│   └── package.json
└── docs/
```

## Modullar ro'yxati

- **Auth** — JWT (access + refresh), profile, parolni o'zgartirish
- **Users & Roles** — Super Admin paneli, granular permissions (JSONB)
- **Customers** — mijozlar bazasi (mamlakat, viloyat, manzil)
- **Products** — bunker katalogi (PREMIUM 3/4, ULTRA, MAGNUM, OPTIMA) + Inventory
- **Sales / Orders** — to'liq state machine (NEW → CONFIRMED → ... → PAID), to'lovlar
- **Service** — kafolat avtomatik hisob, tashriflar, kalendar
- **Finance** — 3 daftar (UZS, USD, GAZNA), tranzaksiyalar, CBU kurs
- **HR** — xodimlar, davomat (15-kunlik batch), payroll
- **Supply** — 4 sektor (LAZER, CHUGUN, ASOSIY, MARDON), vendorlar, ombor
- **Telegram bot** — `/neworder` orqali buyurtma qabul qilish (aiogram 3)
- **Reports** — sotuv KPI, P&L, viloyat va model bo'yicha tahlil
- **Notifications** — in-app bildirishnomalar

## Texnologiyalar

### Backend
- FastAPI (async)
- SQLAlchemy 2.0 + asyncpg + Alembic
- Pydantic v2 (request/response sxemalari)
- python-jose + passlib (JWT + bcrypt)
- aiogram 3 (Telegram bot)
- Celery + Redis (ixtiyoriy — fon vazifalari, CBU kurs yangilash)
- httpx (CBU API uchun)

### Frontend
- React 18 + TypeScript + Vite
- Tailwind CSS (iOS-style, soft shadows, rounded corners)
- TanStack Query (server state)
- Zustand (lokal state — auth, theme, locale)
- React Router v6
- React Hook Form + Zod (forma validatsiyasi)
- Recharts (grafiklar)
- i18next (uz/ru/en)
- lucide-react (ikonkalar)

## Dizayn falsafasi

- **iOS-inspired** — yumshoq burchaklar, yumshoq soyalar
- **Mobile-first** — mobil va desktopda bir xil yaxshi ishlaydi
- **Cozy ranglar** — Primary #1E3A5F, Accent #2980B9
- **Inter font family** (Google Fonts)
- **O'zbek tilida birinchi navbatda** — RU va EN qo'shimcha

## Telegram bot (ixtiyoriy)

`.env` ga `TELEGRAM_BOT_TOKEN` qo'shing, so'ng:

```bash
python -m app.integrations.telegram
```

Yoki webhook rejimi uchun `POST /api/v1/telegram/webhook` endpointi ishlatiladi.

## Backup va Production

- HTTPS majburiy (Let's Encrypt — certbot)
- PostgreSQL kunlik `pg_dump` (kechqurun 02:00)
- Log saqlash: 30 kun lokal, 1 yil arxiv
- Audit log immutable (faqat o'qish, super_admin va director uchun)

## Litsenziya

NUR TECHNO GROUP — ichki ishlatish uchun. Tashqi tarqatish ruxsat etilmaydi.
