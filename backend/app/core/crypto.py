"""Maxfiy sozlamalarni bazada SHIFRLANGAN holda saqlash (Fernet / AES-128-CBC + HMAC).

Nega kerak: `system_settings` jadvalida Instagram tokeni, Anthropic API kaliti
kabi sirlar turadi. Baza nusxasi (dump/backup) qo'lga tushsa, ular ochiq matnda
bo'lmasligi kerak.

Kalit qayerdan: ERP `SECRET_KEY` (.env) dan HKDF orqali chiqariladi — yangi
sozlama qo'shish shart emas. **Diqqat:** `SECRET_KEY` ni almashtirsangiz, eski
shifrlangan qiymatlarni o'qib bo'lmaydi — sirlarni qayta kiritish kerak
(Instagram uchun shunchaki «Ulash» tugmasini qayta bosasiz).

Orqaga moslik: prefikssiz (eski, shifrlanmagan) qiymatlar o'qilaveradi va
keyingi saqlashda avtomatik shifrlanadi.
"""
from __future__ import annotations

import base64
from functools import lru_cache

from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from loguru import logger

from app.core.config import settings

# Shifrlangan qiymat shu prefiks bilan boshlanadi — eski ochiq matnni shundan ajratamiz
_PREFIX = "enc:v1:"
_INFO = b"nur-erp:system-settings:v1"


@lru_cache
def _fernet() -> Fernet:
    key = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=None,
        info=_INFO,
    ).derive(settings.SECRET_KEY.encode())
    return Fernet(base64.urlsafe_b64encode(key))


def encrypt_secret(plain: str) -> str:
    """Ochiq matnni shifrlaydi. Bo'sh qiymat shifrlanmaydi."""
    if not plain:
        return plain
    return _PREFIX + _fernet().encrypt(plain.encode()).decode()


def decrypt_secret(stored: str) -> str:
    """Bazadagi qiymatni ochadi.

    Prefiks bo'lmasa — eski ochiq matn, o'zini qaytaramiz.
    Ochib bo'lmasa (SECRET_KEY almashgan) — "" qaytaramiz, tizim yiqilmaydi.
    """
    if not stored or not stored.startswith(_PREFIX):
        return stored
    try:
        return _fernet().decrypt(stored[len(_PREFIX):].encode()).decode()
    except InvalidToken:
        logger.error(
            "Sozlama qiymatini ochib bo'lmadi — SECRET_KEY almashgan bo'lishi mumkin. "
            "Maxfiy kalitlarni qayta kiriting."
        )
        return ""


def is_encrypted(stored: str) -> bool:
    return bool(stored) and stored.startswith(_PREFIX)


async def encrypt_existing_secrets() -> int:
    """Startup migratsiyasi: bazadagi ESKI (shifrlanmagan) sirlarni shifrlaydi.

    Idempotent — allaqachon shifrlangan qatorlarga tegmaydi. Shu sabab tizim
    shifrlashgacha yozilgan kalitlar (masalan Gemini API kaliti) birinchi
    ishga tushishdayoq avtomatik shifrlanadi, qo'lda qayta kiritish shart emas.
    """
    # Kech import — aylanma bog'liqlikdan qochish uchun
    from sqlalchemy import select

    from app.core.system_settings import CATALOG_BY_KEY
    from app.db.session import AsyncSessionLocal
    from app.models.system import SystemSetting

    secret_keys = {k for k, item in CATALOG_BY_KEY.items() if item.secret}
    migrated = 0
    async with AsyncSessionLocal() as db:
        rows = (await db.execute(select(SystemSetting))).scalars().all()
        for row in rows:
            if row.key in secret_keys and row.value and not is_encrypted(row.value):
                row.value = encrypt_secret(row.value)
                migrated += 1
        if migrated:
            await db.commit()
            logger.info("Tizim sozlamalari: {} ta maxfiy kalit shifrlandi", migrated)
    return migrated
