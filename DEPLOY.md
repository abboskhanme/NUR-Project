# NUR Project — DigitalOcean'ga deploy qilish (qadam-baqadam)

Bu qo'llanma **Droplet + Docker + Managed Database + domen (HTTPS)** sxemasi uchun.
Stack: FastAPI (backend) + React/Vite (frontend) + PostgreSQL.

---

## Nega aynan shu sxema? (qisqa tavsiya)

**Droplet + Docker** (App Platform emas):
- Sizda allaqachon `docker-compose` bor — shu ishni qayta ishlatamiz, sozlash minimal.
- Arzon va to'liq nazorat: bitta $6–12/oy server hamma narsani ko'taradi.
- Xatolarni topish va loglarni ko'rish oson.
- App Platform har bir servis uchun alohida to'lov oladi va Docker dev-rejimini qayta yozishni talab qiladi.

**Managed Database** (baza alohida) — ERP uchun **tavsiya etaman**:
- Avtomatik kunlik **backup** va vaqt bo'yicha tiklash (point-in-time recovery). Sizning buyurtma/moliya ma'lumotlaringiz biznes uchun kritik — bu eng katta afzallik.
- Droplet o'chib qolsa ham baza tirik qoladi (alohida turadi).
- Avtomatik xavfsizlik yangilanishlari, monitoring, kerak bo'lsa replikatsiya.
- Kamchiligi: ~$15/oy qo'shimcha.
- **Pulni tejash kerak bo'lsa:** boshида bazani droplet ichida ishlatib, keyinroq Managed'ga ko'chirsa bo'ladi (compose faylida tayyor variant izoh ostida turibdi). Lekin u holda backup'ni o'zingiz sozlashingiz kerak.

> Qisqasi: **Droplet + Docker + Managed DB** — ishonchlilik va narx muvozanati eng yaxshi.

---

## 0. Sizga kerak bo'ladi
- DigitalOcean akkaunti ($5 kredit ko'rinib turibdi).
- Domen (bor dedingiz) — masalan `nurtechno.uz`. ERP'ni `erp.nurtechno.uz` subdomeniga qo'yamiz.
- GitHub repo: `github.com/abboskhanme/NUR-Project` (bor).

---

## 1. Yangi production fayllarni GitHub'ga yuborish

Men loyihaga 5 ta yangi fayl qo'shdim (kompyuteringizda, `NUR Project` papkasida):

- `frontend/Dockerfile.prod` — frontendni build qilib nginx orqali beradi
- `frontend/nginx.conf` — React Router uchun
- `docker-compose.prod.yml` — production stack
- `Caddyfile` — reverse proxy + avtomatik HTTPS
- `.env.prod.example` — sozlamalar namunasi

Kompyuteringizda (loyiha papkasida) terminalda:

```bash
git add frontend/Dockerfile.prod frontend/nginx.conf docker-compose.prod.yml Caddyfile .env.prod.example DEPLOY.md
git commit -m "Add production deployment config (Docker + Caddy)"
git push origin main
```

> `.env.prod` (haqiqiy parollar bilan) faylini **commit qilmang** — u faqat serverda bo'ladi.

---

## 2. Managed PostgreSQL bazasini yaratish

1. DigitalOcean panelida: **Create → Databases**.
2. Engine: **PostgreSQL** (eng yangi versiya, masalan 16).
3. Plan: eng arzon (**Basic, 1 GB / $15/oy**) — boshlash uchun yetarli.
4. Datacenter: **Frankfurt (FRA1)** yoki **Amsterdam (AMS3)** — O'zbekistonga eng yaqin va tez.
5. Nom bering (masalan `nur-db`) → **Create**.
6. Yaratilgach: **Users & Databases** bo'limida `nur_erp` nomli yangi database yarating (yoki standart `defaultdb` ni ishlatasiz).
7. **Connection details** → "Connection string" ni nusxalab oling. U shunday ko'rinadi:
   ```
   postgresql://doadmin:PAROL@db-nur-...ondigitalocean.com:25060/nur_erp?sslmode=require
   ```
   Buni 4-qadamda `.env.prod` ga yozasiz (boshini `postgresql+asyncpg://` ga o'zgartirib, oxiridagi `?sslmode=require` ni olib tashlab).

> Bazani 3-qadamdagi droplet bilan **bir xil region**da yarating — tezlik va ichki tarmoq uchun.

---

## 3. Droplet (server) yaratish

1. **Create → Droplets**.
2. Image: **Ubuntu 24.04 LTS**.
3. Plan: **Basic → Regular → $6/oy** (1 GB RAM) bilan boshlasa bo'ladi. Sekinlashsa $12/oy (2 GB) ga oshirasiz.
4. Region: baza bilan **bir xil** (FRA1 yoki AMS3).
5. Authentication: **SSH key** (tavsiya) yoki parol.
6. Hostname: `nur-erp` → **Create Droplet**.
7. Droplet IP manzilini eslab qoling (masalan `164.92.xx.xx`).

---

## 4. Domenni serverga yo'naltirish (DNS)

Domeningiz boshqaruv panelida (yoki DigitalOcean → Networking → Domains) **A record** qo'shing:

| Type | Host | Value (IP)        |
|------|------|-------------------|
| A    | erp  | 164.92.xx.xx      |

Ya'ni `erp.nurtechno.uz` → droplet IP. (Asosiy domenni ishlatmoqchi bo'lsangiz, Host: `@`.)
DNS tarqalishi 5–30 daqiqa olishi mumkin.

> Caddy HTTPS sertifikat olishidan oldin DNS to'g'ri ulanган bo'lishi shart.

---

## 5. Serverga ulanib, kerakli dasturlarni o'rnatish

Kompyuteringiz terminalidan serverга kiring:

```bash
ssh root@164.92.xx.xx
```

Docker va Docker Compose'ni o'rnatamiz:

```bash
# Tizimni yangilash
apt update && apt upgrade -y

# Docker o'rnatish (rasmiy skript)
curl -fsSL https://get.docker.com | sh

# Tekshirish
docker --version
docker compose version
```

Faervolni ochamiz (80/443 portlar HTTPS uchun):

```bash
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable
```

---

## 6. Loyihani serverga olish

```bash
cd /opt
git clone https://github.com/abboskhanme/NUR-Project.git
cd NUR-Project
```

> Repo private bo'lsa, GitHub'da **Personal Access Token** yarating va clone'da parol o'rnida ishlating, yoki serverga deploy SSH key qo'shing.

---

## 7. `.env.prod` faylini yaratish (parollar shu yerda)

```bash
cp .env.prod.example .env.prod
nano .env.prod
```

Quyidagilarni to'ldiring:

- **`DOMAIN`** → `erp.nurtechno.uz`
- **`DATABASE_URL`** → 2-qadamdagi connection string, LEKIN:
  - boshini `postgresql://` dan **`postgresql+asyncpg://`** ga o'zgartiring
  - oxiridagi **`?sslmode=require`** ni olib tashlang
  - natija: `postgresql+asyncpg://doadmin:PAROL@db-nur-...ondigitalocean.com:25060/nur_erp`
- **`SECRET_KEY`** → kuchli tasodifiy satr. Yaratish: `openssl rand -hex 32`
- **`INIT_ADMIN_EMAIL` / `INIT_ADMIN_PASSWORD`** → birinchi admin login (parolni o'zgartiring).

Saqlash: `Ctrl+O`, `Enter`, keyin `Ctrl+X`.

> **Muhim:** Managed DB sahifasida **Trusted Sources** bo'limiga droplet'ingizni qo'shing (yoki "All resources"). Aks holda backend bazaga ulana olmaydi.

---

## 8. Ishga tushirish 🚀

```bash
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

Birinchi marta build 2–5 daqiqa oladi. Loglarni kuzating:

```bash
docker compose -f docker-compose.prod.yml logs -f
```

Quyidagilarni ko'rsangiz tayyor:
- backend: `[init] Seeding DB...` → `Starting uvicorn` → `Application startup complete`
- caddy: sertifikat olgani haqida xabar (`certificate obtained`)

Endi brauzerda oching: **https://erp.nurtechno.uz**

Login: `.env.prod` dagi `INIT_ADMIN_EMAIL` / `INIT_ADMIN_PASSWORD`.
API hujjatlar: `https://erp.nurtechno.uz/api/docs`

---

## 9. Tekshirish

```bash
# Konteynerlar holati
docker compose -f docker-compose.prod.yml ps

# Backend sog'ligi
curl https://erp.nurtechno.uz/health
# {"status":"ok"} qaytishi kerak
```

---

## Keyingi yangilanishlar (kod o'zgarsa)

Kompyuterda kodni o'zgartirib `git push` qilgandan keyin, serverda:

```bash
cd /opt/NUR-Project
git pull
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

---

## Foydali buyruqlar

```bash
# Loglar (faqat backend)
docker compose -f docker-compose.prod.yml logs -f backend

# To'xtatish
docker compose -f docker-compose.prod.yml down

# Qayta ishga tushirish
docker compose -f docker-compose.prod.yml restart

# Disk/joy tozalash (eski image'lar)
docker system prune -f
```

---

## Muammolar (troubleshooting)

- **Sayt ochilmayapti / SSL xatosi** → DNS hali tarqalmagan bo'lishi mumkin. `dig erp.nurtechno.uz` bilan IP to'g'ri ko'rsatayotganini tekshiring. Caddy loglarini ko'ring.
- **Backend bazaga ulanmayapti** → Managed DB → **Trusted Sources** ga droplet qo'shilganini, `DATABASE_URL` da `+asyncpg` borligini va `?sslmode=require` olib tashlanganini tekshiring.
- **502 Bad Gateway** → backend hali ishga tushmagan yoki seed xato bergan. `logs -f backend` ko'ring.
- **Frontend "Network Error"** → frontend `/api/v1` nisbiy yo'ldan foydalanadi; Caddy `/api/*` ni backendga uzatayotganini tekshiring.

---

## Xavfsizlik tavsiyalari (deploy'dan keyin)

- Birinchi kirgandan so'ng admin parolini ilovada o'zgartiring.
- `root` o'rniga oddiy `sudo` user yarating va SSH'ni faqat key bilan qoldiring.
- Managed DB allaqachon kunlik backup qiladi — qo'shimcha sozlash shart emas.
