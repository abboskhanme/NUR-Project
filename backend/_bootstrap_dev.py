"""Vaqtinchalik dev bootstrap — bo'sh bazada to'liq sxema yaratadi va admin seed qiladi.

Migratsiyalar zanjiri genezis (users/orders/...) jadvallarini yaratmaydi — ular
modellardan create_all orqali quriladi. Bu skript: create_all + admin seed.
Idempotent: qayta ishga tushirsa, mavjud bo'lsa o'tkazib yuboradi.
"""
import asyncio

from sqlalchemy import select

import app.models  # noqa: F401 — barcha modellarni Base.metadata ga ro'yxatdan o'tkazadi
from app.core.config import settings
from app.core.security import hash_password, normalize_phone
from app.db.base import Base
from app.db.session import AsyncSessionLocal, engine
from app.models.user import User


async def main() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("[ok] create_all — barcha jadvallar yaratildi")

    async with AsyncSessionLocal() as db:
        phone = normalize_phone(settings.INIT_ADMIN_PHONE)
        existing = (await db.execute(select(User).where(User.phone == phone))).scalar_one_or_none()
        if existing:
            print(f"[skip] admin allaqachon mavjud: {phone}")
            return
        admin = User(
            phone=phone,
            password_hash=hash_password(settings.INIT_ADMIN_PASSWORD),
            full_name=settings.INIT_ADMIN_NAME,
            is_superadmin=True,
            is_active=True,
        )
        db.add(admin)
        await db.commit()
        print(f"[ok] admin yaratildi: {phone} / {settings.INIT_ADMIN_PASSWORD}")


if __name__ == "__main__":
    asyncio.run(main())
