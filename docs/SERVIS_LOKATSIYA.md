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

## Sozlash — hammasi ERP ichidan

Botning tokeni va sozlamalari **Tizim sozlamalari → «ERP Telegram boti»**
bo'limida (faqat super-admin). `.env` ni tahrirlash shart emas.

| Sozlama | Nima uchun |
|---|---|
| **Bot token** | BotFather'dan olinadi. Saqlagach bot ~30 soniyada o'zi qayta ulanadi — konteynerni qayta ishga tushirish kerak emas. |
| **Bot foydalanuvchi nomi** | `@` siz. Arizadagi «Botga o'tish» havolasi shundan yasaladi. |
| **Hisobot oluvchilar (chat ID)** | Kunlik hisobot va yangi buyurtma xabari shu chat'larga boradi. |
| **Kunlik hisobot vaqti** | HH:MM. |
| **Yangi buyurtmada darhol xabar** | ha / yo'q. |

So'ng har bir servis xodimi botga `/id` yozadi, chiqqan raqam ERP →
**Foydalanuvchilar** → profilidagi *Telegram chat ID* maydoniga qo'yiladi.
Bog'lanmagan akkauntdan kelgan lokatsiya qabul qilinmaydi (kim biriktirgani
yozib boriladi).

Instagram agenti bilan **bir xil bot** ishlatilsa — o'sha tokenni ikkala
bo'limga ham qo'ying («Telegram bildirishnoma» agentniki, «ERP Telegram boti»
esa shu bot uchun). Ular to'qnashmaydi: agent faqat xabar yuboradi, ERP boti
esa polling qiladi.

`telegram-bot` konteyneri endi doim ishlaydi (profil ortida emas). Token
kiritilmagan bo'lsa jarayon yiqilmaydi — kutib turadi va kiritilgach o'zi
ulanadi. Eski `.env` qiymatlari (`TELEGRAM_BOT_TOKEN` va h.k.) zaxira sifatida
saqlanib qoldi: sozlama bo'sh bo'lsa o'shalar ishlatiladi.

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
- Sozlama o'qish tartibi: `system_settings` (DB) > `.env`. Kod:
  `app/core/settings_store.py`, bot uchun
  `app/integrations/telegram/config_store.py`. ERP kalitlari (`local=True`)
  tashqi agentga (`/agent-config`) yuborilmaydi.
