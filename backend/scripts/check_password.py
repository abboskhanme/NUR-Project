#!/usr/bin/env python3
"""Parolni TEKSHIRISH (hech narsani o'zgartirmaydi) — kirishda muammo bo'lsa.

"Telefon yoki parol xato" xatosi ikki xil sababdan chiqadi va xabar ikkisida
bir xil: (1) bunday raqamli foydalanuvchi yo'q, (2) parol mos kelmadi. Bu skript
ikkisini ajratib beradi — ya'ni muammo raqamdami, paroldami yoki bazadami.

Parol terminalda so'raladi (ekranda ko'rinmaydi) va hech qayerga yozilmaydi.

    docker compose exec backend python scripts/check_password.py +998976662675

Prodda (serverda, avval `git pull` qiling):

    docker compose -f docker-compose.prod.yml exec backend python scripts/check_password.py +998976662675
"""
import asyncio
import getpass
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import func, select  # noqa: E402

from app.core.config import settings  # noqa: E402
from app.core.security import verify_password  # noqa: E402
from app.db.session import AsyncSessionLocal  # noqa: E402
from app.models.user import User  # noqa: E402


def _digits(v: str) -> str:
    return re.sub(r"\D", "", v or "")


async def main() -> int:
    if len(sys.argv) < 2:
        print("Foydalanish: python scripts/check_password.py <telefon>")
        return 2

    phone = sys.argv[1]
    digits = _digits(phone)

    # Qaysi bazaga ulanayotganini ko'rsatamiz (dev/prod adashmaslik uchun)
    db_url = str(settings.DATABASE_URL)
    print(f"Baza: {re.sub(r'://[^@]*@', '://***@', db_url)}")

    async with AsyncSessionLocal() as db:
        user = (await db.execute(
            select(User).where(func.regexp_replace(User.phone, r"\D", "", "g") == digits)
        )).scalar_one_or_none()

        if user is None:
            print(f"\n❌ Bu bazada {phone} ({digits}) raqamli foydalanuvchi YO'Q.")
            all_users = (await db.execute(select(User.phone, User.full_name))).all()
            print("Bazadagi raqamlar:")
            for ph, name in all_users:
                print(f"   · {ph}  —  {name}")
            print("\nDemak muammo parolda emas: yoki raqam boshqacha kiritilgan "
                  "(+998 bilan to'liq yozilishi kerak), yoki bu boshqa baza.")
            return 1

        print(f"Foydalanuvchi topildi: {user.full_name} ({user.phone})"
              f"{' · super-admin' if user.is_superadmin else ''}")
        if not user.is_active:
            print("❌ Akkount FAOL EMAS (is_active=false) — parol to'g'ri bo'lsa ham kirmaydi.")
            return 1

        if not sys.stdin.isatty():
            print("Parolni so'rash uchun interaktiv terminal kerak (`-T` bermang).")
            return 2

        pw = getpass.getpass("Parolni kiriting (ekranda ko'rinmaydi): ")
        if verify_password(pw, user.password_hash):
            print("\n✅ Parol MOS KELADI. Shu baza bilan ishlaydigan saytga kirishingiz mumkin.")
            print("   Agar sayt hamon o'tkazmasa — boshqa bazaga (prod/dev) kirmoqdasiz.")
            return 0
        print("\n❌ Parol MOS KELMADI. Raqam to'g'ri, parol boshqa.")
        print("   Bo'sh joy (space) yoki klaviatura tili almashib ketmaganini tekshiring;")
        print("   kerak bo'lsa reset_password.py bilan qaytadan qo'yasiz.")
        return 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
