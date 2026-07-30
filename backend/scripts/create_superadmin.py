#!/usr/bin/env python3
"""Yangi SUPER-ADMIN akkount yaratish.

Parol skriptda yozilmaydi — ishga tushganda terminalda so'raladi va yozilayotganda
ekranda ko'rinmaydi. bcrypt bilan hashlanib saqlanadi, ya'ni parol hech qayerda
(kodda, logda, buyruq tarixida) ochiq qolmaydi.

    docker compose exec backend python scripts/create_superadmin.py +998901112233 "Abbosxon"

Prodda (serverda, avval `git pull`):

    docker compose -f docker-compose.prod.yml exec backend python scripts/create_superadmin.py +998901112233 "Abbosxon"

`is_superadmin=true` bo'lgani uchun bu akkountga rol biriktirish shart emas —
u barcha modullarga to'liq kira oladi (ruxsat tekshiruvi super-admin uchun
har doim "ha" qaytaradi).
"""
import asyncio
import getpass
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import func, select  # noqa: E402

from app.core.config import settings  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.db.session import AsyncSessionLocal  # noqa: E402
from app.models.user import User  # noqa: E402

MIN_LENGTH = 8  # ilovadagi qoida bilan bir xil (schemas/auth.py)


def _digits(v: str) -> str:
    return re.sub(r"\D", "", v or "")


def _normalize(phone: str) -> str:
    """+998XXXXXXXXX ko'rinishiga keltiradi (login raqamlar bo'yicha solishtiradi)."""
    d = _digits(phone)
    if len(d) == 9:            # 976662675 -> 998976662675
        d = "998" + d
    return "+" + d


async def main() -> int:
    if len(sys.argv) < 3:
        print('Foydalanish: python scripts/create_superadmin.py <telefon> "<To\'liq ism>"')
        print('Masalan:     python scripts/create_superadmin.py +998901112233 "Abbosxon"')
        return 2

    phone = _normalize(sys.argv[1])
    full_name = sys.argv[2].strip()
    digits = _digits(phone)

    if len(digits) < 9:
        print(f"Telefon raqam noto'g'ri: {sys.argv[1]}")
        return 2
    if not full_name:
        print("Ism bo'sh bo'lmasligi kerak")
        return 2

    db_url = str(settings.DATABASE_URL)
    print(f"Baza: {re.sub(r'://[^@]*@', '://***@', db_url)}")

    async with AsyncSessionLocal() as db:
        # Login raqamlar bo'yicha solishtiradi — dublikat bo'lmasligi uchun shu mantiq
        existing = (await db.execute(
            select(User).where(func.regexp_replace(User.phone, r"\D", "", "g") == digits)
        )).scalar_one_or_none()
        if existing is not None:
            print(f"\n❌ Bu raqam allaqachon band: {existing.phone} — {existing.full_name}"
                  f"{' (super-admin)' if existing.is_superadmin else ''}")
            print("   Parolni tiklash uchun: python scripts/reset_password.py " + existing.phone)
            return 1

        print(f"Yaratiladi: {full_name} ({phone}) · super-admin")
        if not sys.stdin.isatty():
            print("XATO: parolni xavfsiz so'rash uchun interaktiv terminal kerak.")
            print("`docker compose exec` buyrug'ida `-T` bayrog'ini bermang.")
            return 2

        new = getpass.getpass(f"Parol (kamida {MIN_LENGTH} belgi, ekranda ko'rinmaydi): ")
        again = getpass.getpass("Takrorlang: ")
        if new != again:
            print("Parollar mos kelmadi — akkount yaratilmadi.")
            return 1
        if len(new) < MIN_LENGTH:
            print(f"Parol kamida {MIN_LENGTH} belgidan iborat bo'lishi kerak — akkount yaratilmadi.")
            return 1

        db.add(User(
            phone=phone,
            password_hash=hash_password(new),
            full_name=full_name,
            is_superadmin=True,
            is_active=True,
            token_version=0,
        ))
        await db.commit()

    print(f"\n✅ Super-admin yaratildi: {full_name} ({phone})")
    print("   Shu raqam va parol bilan tizimga kiring.")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
