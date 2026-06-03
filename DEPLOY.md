# NUR Project — DigitalOcean'ga deploy qilish (qadam-baqadam)

Bu qo'llanma **hammasi bitta Droplet ichida** (Docker + ichki PostgreSQL + Caddy/HTTPS) sxemasi uchun.
Stack: FastAPI (backend) + React/Vite (frontend) + PostgreSQL — hammasi bir serverda.

---

## Nega aynan shu sxema? (qisqa tavsiya)

**Droplet + Docker** (App Platform emas):
- Sizda allaqachon `docker-compose` bor — shu ishni qayta ishlatamiz, sozlash minimal.
- Arzon va to'liq nazorat: bitta $6–12/oy server hamma narsani ko'taradi.
- Xatolarni topish va loglarni ko'rish oson.

**Baza shu droplet ichida** (Managed DB emas):
- Qo'shimcha to'lov yo'q — Managed DB ~$15/oy bo'lardi, bu yerda baza serverning bir qismi.
- Sodda: bitta `docker compose up` hammasini ko'taradi.
- **Diqqat — backup o'zingizning zimmangizda.** Managed DB avtomatik backup qilardi; bu yerda buni biz o'zimiz sozlaymiz (pastdagi **"Backup"** bo'limiga qarang — bu MUHIM, chunki ERP ma'lumotlari kritik).
- Keyinroq biznes o'ssa, bazani Managed DB ga ko'chirish mumkin — faqat `DATABASE_URL` o'zgaradi.

> Qisqasi: hozircha **bitta droplet** — eng arzon va sodda. Faqat **backup**ni albatta yoqing.

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

## 2. Droplet (server) yaratish

1. **Create → Droplets**.
2. Image: **Ubuntu 24.04 LTS**.
3. Plan: **Basic → Regular → $12/oy (2 GB RAM)** tavsiya — baza ham shu serverda turgani uchun 1 GB ozlik qilishi mumkin. Pulni tejash uchun $6/oy (1 GB) bilan boshlab, sekinlashsa oshirsa bo'ladi.
4. Region: **Frankfurt (FRA1)** yoki **Amsterdam (AMS3)** — O'zbekistonga eng yaqin va tez.
5. Authentication: **SSH key** (tavsiya) yoki parol.
6. Hostname: `nur-erp` → **Create Droplet**.
7. Droplet IP manzilini eslab qoling (masalan `164.92.xx.xx`).

---

## 3. Domenni serverga yo'naltirish (DNS)

Domeningiz boshqaruv panelida (yoki DigitalOcean → Networking → Domains) **A record** qo'shing:

| Type | Host | Value (IP)        |
|------|------|-------------------|
| A    | erp  | 164.92.xx.xx      |

Ya'ni `erp.nurtechno.uz` → droplet IP. (Asosiy domenni ishlatmoqchi bo'lsangiz, Host: `@`.)
DNS tarqalishi 5–30 daqiqa olishi mumkin.

> Caddy HTTPS sertifikat olishidan oldin DNS to'g'ri ulanган bo'lishi shart.

---

## 4. Serverga ulanib, kerakli dasturlarni o'rnatish

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

## 5. Loyihani serverga olish

```bash
cd /opt
git clone https://github.com/abboskhanme/NUR-Project.git
cd NUR-Project
```

> Repo private bo'lsa, GitHub'da **Personal Access Token** yarating va clone'da parol o'rnida ishlating, yoki serverga deploy SSH key qo'shing.

---

## 6. `.env.prod` faylini yaratish (parollar shu yerda)

```bash
cp .env.prod.example .env.prod
nano .env.prod
```

Quyidagilarni to'ldiring:

- **`DOMAIN`** → `erp.nurtechno.uz`
- **`POSTGRES_PASSWORD`** → kuchli parol. Yaratish: `openssl rand -hex 16`
- **`DATABASE_URL`** → yuqoridagi parol bilan **bir xil** bo'lsin:
  `postgresql+asyncpg://postgres:O'SHA_PAROL@postgres:5432/nur_erp`
  (`@postgres` — bu compose ichidagi baza konteyner nomi, o'zgartirmang.)
- **`SECRET_KEY`** → kuchli tasodifiy satr. Yaratish: `openssl rand -hex 32`
- **`INIT_ADMIN_EMAIL` / `INIT_ADMIN_PASSWORD`** → birinchi admin login (parolni o'zgartiring).

Saqlash: `Ctrl+O`, `Enter`, keyin `Ctrl+X`.

---

## 7. Ishga tushirish 🚀

```bash
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

Birinchi marta build 2–5 daqiqa oladi. Loglarni kuzating:

```bash
docker compose -f docker-compose.prod.yml logs -f
```

Quyidagilarni ko'rsangiz tayyor:
- postgres: `database system is ready to accept connections`
- backend: `[init] Seeding DB...` → `Starting uvicorn` → `Application startup complete`
- caddy: sertifikat olgani haqida xabar (`certificate obtained`)

Endi brauzerda oching: **https://erp.nurtechno.uz**

Login: `.env.prod` dagi `INIT_ADMIN_EMAIL` / `INIT_ADMIN_PASSWORD`.
API hujjatlar: `https://erp.nurtechno.uz/api/docs`

---

## 8. Tekshirish

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

# To'xtatish (baza saqlanib qoladi)
docker compose -f docker-compose.prod.yml down

# Qayta ishga tushirish
docker compose -f docker-compose.prod.yml restart

# Disk/joy tozalash (eski image'lar)
docker system prune -f
```

> ⚠️ **`docker compose down -v` ishlatMANG** — `-v` bayrog'i volume'larni, ya'ni
> **butun bazani o'chiradi**. Oddiy `down` bazani saqlab qoladi.

---

## Backup (MUHIM — baza droplet ichida bo'lgani uchun)

Managed DB'dan voz kechganimiz uchun backup'ni o'zimiz sozlaymiz. Bu ERP ma'lumotlari
(buyurtma, moliya) uchun shart. Serverda quyidagi backup skriptini yarating:

```bash
mkdir -p /opt/backups
cat > /opt/backup-db.sh <<'EOF'
#!/bin/bash
# Har kuni bazani dump qiladi, 14 kundan eski nusxalarni o'chiradi.
STAMP=$(date +%F_%H%M)
docker exec nur-postgres pg_dump -U postgres nur_erp | gzip > /opt/backups/nur_erp_$STAMP.sql.gz
find /opt/backups -name "*.sql.gz" -mtime +14 -delete
EOF
chmod +x /opt/backup-db.sh
```

Har kuni soat 03:00 da avtomatik ishlashi uchun cron qo'shing:

```bash
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/backup-db.sh") | crontab -
```

> Yanada xavfsiz: `/opt/backups` ni vaqti-vaqti bilan DigitalOcean Spaces yoki
> boshqa kompyuterga ko'chirib turing — droplet butunlay o'chsa ham nusxa qoladi.

**Tiklash (restore):**
```bash
gunzip < /opt/backups/nur_erp_2026-06-03_0300.sql.gz | docker exec -i nur-postgres psql -U postgres nur_erp
```

> Qo'shimcha himoya: DigitalOcean Droplet sahifasida **Backups** ($1.2/oy ~ haftalik
> snapshot) ni ham yoqsa bo'ladi — butun serverning nusxasi.

---

## Muammolar (troubleshooting)

- **Sayt ochilmayapti / SSL xatosi** → DNS hali tarqalmagan bo'lishi mumkin. `dig erp.nurtechno.uz` bilan IP to'g'ri ko'rsatayotganini tekshiring. Caddy loglarini ko'ring.
- **Backend bazaga ulanmayapti** → `.env.prod` da `POSTGRES_PASSWORD` va `DATABASE_URL` dagi parol **bir xil** ekanini, `DATABASE_URL` da `+asyncpg` va `@postgres:5432` borligini tekshiring. `logs -f postgres` ko'ring.
- **502 Bad Gateway** → backend hali ishga tushmagan yoki seed xato bergan. `logs -f backend` ko'ring.
- **Frontend "Network Error"** → frontend `/api/v1` nisbiy yo'ldan foydalanadi; Caddy `/api/*` ni backendga uzatayotganini tekshiring.

---

## Xavfsizlik tavsiyalari (deploy'dan keyin)

- Birinchi kirgandan so'ng admin parolini ilovada o'zgartiring.
- `root` o'rniga oddiy `sudo` user yarating va SSH'ni faqat key bilan qoldiring.
- **Backup'ni albatta yoqing** (yuqoridagi bo'lim) — baza serverda bo'lgani uchun bu sizning zimmangizda.
