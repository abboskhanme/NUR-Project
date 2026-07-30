#!/usr/bin/env python3
"""Foydalanuvchi parolini tiklash (parolni eslamay qolgan holat uchun).

Parol SKRIPT ICHIDA YOZILMAYDI — ishga tushganda terminalda so'raladi va
yozilayotganda ekranda ko'rinmaydi. Skript uni bcrypt bilan hashlab bazaga
yozadi, ya'ni parol hech qayerda (kodda, logda, tarixda) ochiq saqlanmaydi.

Ishga tushirish (konteyner ichida, interaktiv — `-T` BERMANG):

    docker compose exec backend python scripts/reset_password.py +998976662675

Prodda:

    docker compose -f docker-compose.prod.yml exec backend python scripts/reset_password.py +998976662675

Parol almashgach `token_version` oshiriladi — barcha eski sessiyalar (brauzer,
telefon) uziladi va yangi parol bilan qaytadan kirish kerak bo'ladi. Bu
ilovaning o'z "parolni almashtirish" amali bilan bir xil xatti-harakat.
"""
import asyncio
import getpass
import re
import sys
from pathlib import Path

# scripts/ ichidan ishga tushirilganda ham `app` paketi topilishi uchun
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import func, select  # noqa: E402

from app.core.security import hash_password  # noqa: E402
from app.db.session import AsyncSessionLocal  # noqa: E402
from app.models.user import User  # noqa: E402

MIN_LENGTH = 8  # ilovadagi qoida bilan bir xil (schemas/auth.py)


def _digits(v: str) -> str:
    return re.sub(r"\D", "", v or "")


async def main() -> int:
    if len(sys.argv) < 2:
        print("Foydalanish: python scripts/reset_password.py <telefon>")
        print("Masalan:     python scripts/reset_password.py +998976662675")
        return 2

    phone = sys.argv[1]
    digits = _digits(phone)
    if not digits:
        print("Telefon raqam noto'g'ri")
        return 2

    async with AsyncSessionLocal() as db:
        # Login bilan bir xil mantiq: faqat raqamlar bo'yicha solishtiramiz
        user = (await db.execute(
            select(User).where(func.regexp_replace(User.phone, r"\D", "", "g") == digits)
        )).scalar_one_or_none()
        if user is None:
            print(f"Bunday foydalanuvchi topilmadi: {phone}")
            return 1

        print(f"Foydalanuvchi: {user.full_name} ({user.phone})"
              f"{' · super-admin' if user.is_superadmin else ''}")
        if not sys.stdin.isatty():
            print("XATO: parolni xavfsiz so'rash uchun interaktiv terminal kerak.")
            print("`docker compose exec` buyrug'ida `-T` bayrog'ini bermang.")
            return 2

        new = getpass.getpass("Yangi parol (ekranda ko'rinmaydi): ")
        again = getpass.getpass("Takrorlang: ")
        if new != again:
            print("Parollar mos kelmadi — hech narsa o'zgartirilmadi.")
            return 1
        if len(new) < MIN_LENGTH:
            print(f"Parol kamida {MIN_LENGTH} belgidan iborat bo'lishi kerak.")
            return 1

        user.password_hash = hash_password(new)
        # Eski tokenlarni bekor qilamiz (barcha qurilmalardagi sessiyalar uziladi)
        user.token_version = (user.token_version or 0) + 1
        await db.commit()

    print("Parol yangilandi. Eski sessiyalar uzildi — yangi parol bilan kiring.")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
