# NUR Project Backend (FastAPI)

Python 3.11+ FastAPI backend NUR TECHNO GROUP ERP/CRM tizimi uchun.

## O'rnatish

```bash
python -m venv .venv
source .venv/bin/activate     # macOS/Linux
.venv\Scripts\activate         # Windows

pip install -r requirements.txt
cp .env.example .env
```

`.env` faylida `DATABASE_URL`, `SECRET_KEY` va boshqa qiymatlarni o'zgartiring.

## Ma'lumotlar bazasi

PostgreSQL 14+ kerak. Bo'sh DB yarating:

```sql
CREATE DATABASE nur_erp;
```

Migratsiyalar va boshlang'ich ma'lumotlar:

```bash
# Variant 1: seed (jadvallarni create_all bilan yaratadi + ma'lumot kiritadi)
python -m scripts.seed

# Variant 2: Alembic
alembic revision --autogenerate -m "init"
alembic upgrade head
python -m scripts.seed
```

## Ishga tushirish

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Swagger UI: <http://localhost:8000/api/docs>

## Standart Super Admin

Seed scripti yaratadi:

- Email: `admin@nurtechno.uz`
- Parol: `Admin@12345`

## Asosiy endpointlar

### Auth
- `POST /api/v1/auth/login` — login
- `POST /api/v1/auth/refresh` — token yangilash
- `GET /api/v1/auth/me` — joriy profil
- `PATCH /api/v1/auth/me` — profilni yangilash

### Buyurtmalar
- `GET /api/v1/orders` — ro'yxat (filtr: status, sana, viloyat)
- `POST /api/v1/orders` — yangi buyurtma
- `POST /api/v1/orders/{id}/status` — status o'zgartirish
- `POST /api/v1/orders/{id}/payments` — to'lov qo'shish

### Moliya
- `GET /api/v1/finance/balance-summary` — joriy balanslar (UZS/USD/GAZNA)
- `POST /api/v1/finance/transactions` — yangi tranzaksiya
- `GET /api/v1/finance/exchange-rates` — kurs tarixi
- `POST /api/v1/finance/exchange-rates` — kurs o'rnatish

### HR
- `GET /api/v1/hr/employees` — xodimlar
- `POST /api/v1/hr/attendance/batch` — davomat (15-kunlik batch)
- `POST /api/v1/hr/payroll/runs` — oylik hisoblash

### Ta'minot
- `GET /api/v1/supply/sectors` — sektorlar
- `GET /api/v1/supply/items` — materiallar (low_stock_only filter)
- `POST /api/v1/supply/receipts` — yangi kirim
- `POST /api/v1/supply/vendor-payments` — vendor to'lovi

### Servis
- `GET /api/v1/service/tickets` — arizalar
- `POST /api/v1/service/tickets` — yangi ariza
- `GET /api/v1/service/warranty/{order_id}` — kafolat info

### Hisobotlar
- `GET /api/v1/reports/sales/kpi`
- `GET /api/v1/reports/sales/by-model`
- `GET /api/v1/reports/sales/by-region`
- `GET /api/v1/reports/finance/pnl`

## Telegram bot

`.env` faylida `TELEGRAM_BOT_TOKEN` qo'shilgandan keyin:

```bash
# Long-polling rejim (test uchun)
python -m app.integrations.telegram

# Yoki webhook (production)
# POST /api/v1/telegram/webhook endpointini bot Telegramda webhook qilib o'rnating
```

## Test

```bash
pytest -v
```

## Lint/Format

```bash
ruff check .
ruff format .
```
