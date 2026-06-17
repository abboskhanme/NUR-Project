"""Eski Google Sheet'dan "Yuk chiqarish" ma'lumotlarini import qilish (BIR MARTALIK).

Foydalanish (CSV stdin orqali beriladi):
    # Avval ko'rish (hech narsa yozilmaydi):
    docker exec -i nur-backend python scripts/import_shipping.py --dry-run < shipping_old.csv
    # Haqiqiy import:
    docker exec -i nur-backend python scripts/import_shipping.py < shipping_old.csv

CSV ustunlari Google Sheets'dagi tartibda bo'lishi kerak:
    SANA, SONI, MANZIL, KVM, UNG/CHAP, SHOPIR TEL, YUL KIRA, KIMDAN,
    KARTA RAQAMI, KARTA EGASI, TO'LANDI, PAUZA, SABABI

KIMDAN / TO'LANDI / PAUZA — modulda yo'q, import QILINMAYDI.
Sarlavha qatorlari (SANA bilan boshlanadi) va sanasiz/bo'sh qatorlar o'tkazib yuboriladi.
"""
import asyncio
import csv
import os
import re
import sys
from datetime import date
from decimal import Decimal

# Skript qaysi papkadan ishga tushirilsa ham `app` paketini topishi uchun
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import AsyncSessionLocal  # noqa: E402
from app.models.shipping import Shipment  # noqa: E402

DRY = "--dry-run" in sys.argv

# UNG/CHAP/ORQA -> bazadagi qiymat
DIRMAP = {"UNG": "right", "CHAP": "left", "ORQA": "orqa", "RIGHT": "right", "LEFT": "left"}

# MANZIL ichidagi kalit so'zdan viloyatni aniqlash (eng yaxshi taxmin)
REGION_KEYS = [
    ("surxandaryo", "Surxondaryo"), ("qashqadaryo", "Qashqadaryo"), ("jizzax", "Jizzax"),
    ("buxoro", "Buxoro"), ("samarqand", "Samarqand"), ("namangan", "Namangan"),
    ("andijon", "Andijon"), ("andjon", "Andijon"), ("asaka", "Andijon"), ("shaxrixon", "Andijon"),
    ("jalaquduq", "Andijon"), ("xonaobod", "Andijon"), ("xonobod", "Andijon"), ("buston", "Andijon"),
    ("marxamat", "Andijon"), ("baliqchi", "Andijon"), ("oltinkul", "Andijon"), ("paxtaobod", "Andijon"),
    ("qurgontepa", "Andijon"), ("xorazm", "Xorazm"), ("xiva", "Xorazm"), ("xazorasp", "Xorazm"),
    ("qoraqalpoq", "Qoraqalpog'iston"), ("mangit", "Qoraqalpog'iston"),
    ("sirdaryo", "Sirdaryo"), ("navoiy", "Navoiy"), ("toshkent", "Toshkent"),
    ("bustonliq", "Toshkent"), ("gazalkent", "Toshkent"),
    # Farg'ona vodiysi
    ("fargona", "Farg'ona"), ("farg`ona", "Farg'ona"), ("margilon", "Farg'ona"),
    ("marg`ilon", "Farg'ona"), ("rishton", "Farg'ona"), ("quva", "Farg'ona"),
    ("qushtepa", "Farg'ona"), ("toshloq", "Farg'ona"), ("yaypan", "Farg'ona"),
    ("oltariq", "Farg'ona"), ("oltiariq", "Farg'ona"), ("beshariq", "Farg'ona"),
    ("bogdod", "Farg'ona"), ("bag`dod", "Farg'ona"), ("buvayda", "Farg'ona"),
    ("vodil", "Farg'ona"), ("yozyavon", "Farg'ona"), ("qumtepa", "Farg'ona"), ("dang", "Farg'ona"),
    # Namangan tumanlari
    ("kosonsoy", "Namangan"), ("chortoq", "Namangan"), ("uchqurg", "Namangan"),
    ("uchqurgon", "Namangan"), ("uychi", "Namangan"), ("chust", "Namangan"),
    ("norin", "Namangan"), ("chodak", "Namangan"), ("turaqurg", "Namangan"),
    ("yangi qurgon", "Namangan"), ("kasonsoy", "Namangan"), ("uchkuprik", "Namangan"),
    ("uzb tuman", "Namangan"), ("isboskan", "Andijon"), ("naymancha", "Namangan"),
    # Buxoro
    ("vobkent", "Buxoro"), ("peshku", "Buxoro"),
    # Qo'qon
    ("qoqon", "Farg'ona"), ("qo`qon", "Farg'ona"), ("kokon", "Farg'ona"),
]


def parse_date(s: str):
    m = re.match(r"\s*(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})", s or "")
    if not m:
        return None
    d, mo, y = int(m.group(1)), int(m.group(2)), int(m.group(3))
    if y < 100:
        y += 2000
    try:
        return date(y, mo, d)
    except ValueError:
        return None


def parse_int(s: str):
    s = re.sub(r"[^\d]", "", s or "")
    return int(s) if s else None


def parse_money(s: str):
    s = re.sub(r"[^\d]", "", s or "")  # "475 000", "150 000\\", "C" -> faqat raqamlar
    return Decimal(s) if s else None


def parse_dir(s: str):
    return DIRMAP.get((s or "").strip().upper()) or None


def parse_country(dest: str):
    d = (dest or "").lower()
    if "tojik" in d:
        return "Tajikistan"
    if "qirg" in d:  # qirgiz/qirgiziston
        return "Kyrgyzstan"
    return "Uzbekistan"


def detect_region(dest: str, country: str):
    if country != "Uzbekistan":
        return None
    d = (dest or "").lower()
    for key, region in REGION_KEYS:
        if key in d:
            return region
    return None


def norm_phone(s: str):
    digits = re.sub(r"\D", "", s or "")
    if len(digits) == 12 and digits.startswith("998"):
        digits = digits[3:]
    if len(digits) == 9:
        return f"+998 {digits[0:2]} {digits[2:5]} {digits[5:7]} {digits[7:9]}"
    return (s or "").strip() or None


def build_shipment(row: list[str]):
    row = (list(row) + [""] * 13)[:13]
    sana, soni, manzil, kvm, dir_, tel, freight, _kimdan, card_no, card_holder, _tolandi, _pauza, sababi = row
    d = parse_date(sana)
    if d is None:
        return None  # sanasiz/sarlavha qator
    country = parse_country(manzil)
    return Shipment(
        date=d,
        qty=parse_int(soni) or 1,
        country=country,
        region=detect_region(manzil, country),
        destination=(manzil or "").strip() or None,
        kvm=parse_int(kvm),
        direction=parse_dir(dir_),
        driver_phone=norm_phone(tel),
        freight=parse_money(freight),
        card_number=(card_no or "").strip() or None,
        card_holder=(card_holder or "").strip() or None,
        reason=(sababi or "").strip() or None,
    )


async def main():
    reader = csv.reader(sys.stdin)
    objs = []
    skipped = 0
    for raw in reader:
        if not raw or not (raw[0] or "").strip():
            skipped += 1
            continue
        if (raw[0] or "").strip().upper().startswith("SANA"):
            skipped += 1
            continue
        sh = build_shipment(raw)
        if sh is None:
            skipped += 1
            continue
        objs.append(sh)

    print(f"Tayyor: {len(objs)} qator import qilinadi, {skipped} qator o'tkazib yuborildi.")
    # Namuna (birinchi 5)
    for sh in objs[:5]:
        print(f"  {sh.date} | {sh.country}/{sh.region} | {sh.destination} | {sh.kvm} | "
              f"{sh.direction} | {sh.driver_phone} | freight={sh.freight} | "
              f"{sh.card_holder or ''} | {sh.reason or ''}")

    if DRY:
        print("\n[--dry-run] hech narsa yozilmadi.")
        return

    async with AsyncSessionLocal() as db:
        db.add_all(objs)
        await db.commit()
    print(f"\n✅ Import tugadi: {len(objs)} qator qo'shildi.")


if __name__ == "__main__":
    asyncio.run(main())
