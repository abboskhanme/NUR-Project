# Docker bilan ishlash — Tezkor qo'llanma

## Ishga tushirish (birinchi marta)

PowerShell yoki CMD'ni oching, loyiha papkasiga kiring:

```bash
cd "C:\NUR Project"
docker compose up -d --build
```

Birinchi marta ~5-10 daqiqa vaqt oladi (image'larni yuklab olish + npm install + pip install).

## Tekshirish

```bash
docker compose ps
```

4 ta servis ishga tushgan bo'lishi kerak:
- `nur-postgres` (5432-port)
- `nur-redis` (6379-port)
- `nur-backend` (8000-port)
- `nur-frontend` (5173-port)

## Manzillar

- **Frontend (asosiy)**: <http://localhost:5173>
- **Backend Swagger**: <http://localhost:8000/api/docs>
- **Backend health**: <http://localhost:8000/health>

## Birinchi login

- Email: `admin@nurtechno.uz`
- Parol: `Admin@12345`

(Seed avtomatik ishga tushadi backend birinchi marta ko'tarilganda.)

## Loglarni ko'rish

```bash
# Hamma loglar
docker compose logs -f

# Faqat backend
docker compose logs -f backend

# Faqat frontend
docker compose logs -f frontend
```

## Servisni qayta ishga tushirish

```bash
docker compose restart backend
```

## To'xtatish

```bash
docker compose down
```

(DB ma'lumotlari saqlanadi — qayta ishga tushganda yo'qolmaydi.)

## Hammasini o'chirish (DB + volume'lar bilan)

```bash
docker compose down -v
```

Diqqat: bu **barcha ma'lumotlarni o'chiradi**. Faqat boshidan boshlash uchun.

## Tez-tez kerak bo'ladigan amallar

### DB ichiga kirish (psql)

```bash
docker compose exec postgres psql -U postgres -d nur_erp
```

Ichida:
- `\dt` — jadvallar ro'yxati
- `SELECT * FROM users;` — foydalanuvchilarni ko'rish
- `\q` — chiqish

### Backend konteyneriga kirish

```bash
docker compose exec backend bash
```

Ichida:
- `alembic upgrade head` — sxema migratsiyasi
- `alembic revision --autogenerate -m "msg"` — yangi migratsiya

### Yangi npm package qo'shish

`frontend/package.json`'ga qo'shing va:

```bash
docker compose exec frontend npm install
```

Yoki container'ni qayta build qiling:

```bash
docker compose up -d --build frontend
```

### Yangi pip package qo'shish

`backend/requirements.txt`'ga qo'shing va:

```bash
docker compose up -d --build backend
```

## Muammolar va yechimlar

**Port band ekan ("port is already in use"):**
- 5432-port band — boshqa PostgreSQL ishlayapti. `docker-compose.yml`'da `5432:5432` ni `5433:5432`'ga o'zgartiring.
- 5173/8000 — boshqa dasturlar ishlatayotgan bo'lishi mumkin

**Frontend kodni o'zgartirsam yangilanmayapti:**
- Vite dev server bilan hot-reload o'z-o'zidan ishlashi kerak
- Windows'da WSL2 muammosi bo'lsa: `vite.config.ts`'ga `server: { watch: { usePolling: true } }` qo'shing

**Backend kodni o'zgartirsam yangilanmayapti:**
- `--reload` flag bilan ishga tushadi, avtomatik yangilanishi kerak
- Agar muammo bo'lsa: `docker compose restart backend`

**"Cannot connect to Docker daemon":**
- Docker Desktop ishga tushirilganmi? Tray icon'ni tekshiring

**Frontend backend'ga ulana olmayapti:**
- CORS muammosi — `docker-compose.yml`'da `ALLOWED_ORIGINS` ichida `http://localhost:5173` borligini tekshiring
- Brauzerda devtools → Network'da xato kodini ko'ring

## Production uchun

Hozirgi `docker-compose.yml` — **development uchun** (volume mount, hot reload, debug=true).

Production uchun alohida `docker-compose.prod.yml` kerak bo'ladi:
- Frontend Nginx orqali static fayllar
- Backend `--reload`'siz
- SSL (Let's Encrypt)
- Secrets `.env` faylda emas, balki Docker secrets'da

Bu fayl keyinroq qo'shiladi (deploy bosqichida).
