# Servis lokatsiyasi — mijozning aniq nuqtasi arizada saqlanadi

Mijoz lokatsiyani odatdagidek Telegramga tashlaydi. Muammo shu pinni 10 kundan
keyin chat tarixidan izlashda edi — endi u **arizaning o'zida** turadi va
kartochkadagi bitta tugma navigatorga olib o'tadi.

Lokatsiya **har arizaga alohida** yoziladi, mijoz kartochkasiga emas: keyingi
safar boshqa manzilga chaqirishi mumkin.

## Lokatsiya qanday tushadi

| Yo'l | Qadamlar | Qayerda |
|---|---|---|
| **Telegram pin (asosiy)** | Kartochkada «Telegram orqali olish» → «Botga o'tish» → mijozning pinini botga **forward** | Ariza kartochkasi + bot |
| **Botdan boshlab** | Pinni to'g'ridan-to'g'ri botga forward → bot lokatsiyasi yo'q arizalarni tugma qilib beradi → tanlaysiz | Faqat bot |
| **Havola / koordinata** | Google/Yandex/2GIS/Apple havolasi yoki `41.311, 69.240` — kartochkadagi maydonga | Ariza kartochkasi yoki ariza yaratish oynasi |

Bot mijozdan hech nima so'ramaydi va mijoz ERP'ni ochmaydi — faqat xodim
ishlatadi.

## ERP'da nima ko'rinadi

- **Ariza kartochkasi** — yashil «Lokatsiya biriktirilgan» bloki: koordinata
  (bosilsa nusxalanadi), mo'ljal matni, **Yandex Navigator** va **Google Maps**
  tugmalari.
- **Arizalar ro'yxati** — har qatorda 📍: yashil = bor (bosilsa darhol
  navigator), kulrang = yo'q.
- **«Lokatsiyasiz» filtri** — safarga chiqishdan oldin tozalab olish uchun.
- **Servis safari paneli** — «Marshrut (N)»: barcha rejalashtirilgan arizalar
  bitta Yandex marshrutida; lokatsiyasi yo'qlari soni alohida ogohlantiriladi.

## Sozlash (bir martalik)

1. **Botni yoqish** — hozir `telegram` profili ortida turibdi:
   ```bash
   docker compose -f docker-compose.prod.yml --env-file .env.prod \
     --profile telegram up -d --build
   ```
2. **.env.prod** ga bot foydalanuvchi nomini qo'shish (ERP'dagi «Botga o'tish»
   havolasi shundan yasaladi):
   ```
   TELEGRAM_BOT_USERNAME=nurtechno_bot
   ```
3. **Xodimlarni botga bog'lash** — har bir servis xodimi botga `/id` yozadi,
   chiqqan raqam ERP → **Foydalanuvchilar** → profilidagi *Telegram chat ID*
   maydoniga qo'yiladi. Bog'lanmagan akkauntdan kelgan lokatsiya qabul
   qilinmaydi (kim biriktirgani yozib boriladi).

## Texnik eslatmalar

- Koordinata `service_tickets` jadvalida: `lat`, `lon`, `location_url`,
  `location_note`, `location_source`, `location_added_at`,
  `location_added_by_id` (migratsiya `20260820_02`).
- `service_location_requests` — «lokatsiya kutilmoqda» oynasi (30 daqiqa):
  shu muddat ichida xodim botga yuborgan lokatsiya aynan o'sha arizaga tushadi.
- Havola tahlili — `app/services/geo.py`. **Tuzoq:** Google `lat,lon`, Yandex
  (`ll`, `pt`) va 2GIS (`m`) esa `lon,lat` beradi; qisqartirilgan havolalar
  (`maps.app.goo.gl`, `yandex.uz/maps/-/…`) ochib ko'riladi. Testlar:
  `tests/test_service_location.py`.
- Xarita havolalari API kaliti yoki to'lov talab qilmaydi.
