#!/usr/bin/env python3
"""Bo'sh bazani noldan tayyorlash (ikkinchi brend nusxasi uchun).

Alembic migratsiyalari bo'sh bazada ishlamaydi: eng birinchisi
(20260528_01) `users` jadvali allaqachon bor deb hisoblaydi — NUR bazasi
dastlab `create_all` bilan qurilgan. Shu sabab yangi baza uchun:

  1. joriy modellardan barcha jadvallar yaratiladi (`create_all`),
  2. migratsiyalar bo'sh bazada yaratadigan standart kassalar qo'shiladi,
  3. alembic `head` ga belgilanadi (stamp) — keyingi migratsiyalar odatdagidek.

Baza allaqachon tayyor bo'lsa (`users` yoki `alembic_version` bor) hech narsa
qilmaydi, shuning uchun har startda xavfsiz ishga tushiriladi:

    python scripts/init_empty_db.py && alembic upgrade head && uvicorn ...
"""
import asyncio
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from sqlalchemy import inspect  # noqa: E402

from app import models  # noqa: E402,F401  — barcha jadvallar metadata'ga tushsin
from app.db.base import Base  # noqa: E402
from app.db.session import AsyncSessionLocal, engine  # noqa: E402
from app.models.finance import Account  # noqa: E402

# 20260626_01 va 20260806_01 migratsiyalari bo'sh bazada yaratadigan kassalar
DEFAULT_ACCOUNTS = (
    # (name, currency, ledger, payment_type)
    ("Kassa UZS", "UZS", "operational", "naqd"),
    ("Kassa USD", "USD", "operational", "naqd"),
    ("G'azna", "USD", "gazna", "naqd"),
    ("Karta UZS", "UZS", "operational", "karta"),
    ("Karta USD", "USD", "operational", "karta"),
)


async def _create_schema() -> bool:
    """Jadvallarni yaratadi. Baza bo'sh bo'lmasa False qaytaradi."""
    async with engine.begin() as conn:
        tables = set(await conn.run_sync(lambda c: inspect(c).get_table_names()))
        if tables & {"users", "alembic_version"}:
            return False
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        for name, currency, ledger, payment_type in DEFAULT_ACCOUNTS:
            db.add(Account(name=name, currency=currency, ledger=ledger,
                           payment_type=payment_type, balance=0))
        await db.commit()
    await engine.dispose()
    return True


def main() -> None:
    if not asyncio.run(_create_schema()):
        print("[init-db] Baza allaqachon tayyor — o'tkazib yuborildi.")
        return
    # stamp sinxron chaqiriladi: alembic env.py o'zi asyncio.run() ishlatadi
    command.stamp(Config(str(ROOT / "alembic.ini")), "head")
    print(f"[init-db] Bo'sh baza yaratildi: {len(Base.metadata.tables)} jadval, "
          f"{len(DEFAULT_ACCOUNTS)} kassa, alembic head.")


if __name__ == "__main__":
    main()
