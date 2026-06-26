"""Telegram bot paketi.

Ikki vazifa bajaradi:
  1. Oddiy mijozlar uchun — sotuvchi sifatida buyurtma qabul qiladi
     (manba: telegram_bot, to'g'ridan-to'g'ri bazaga yoziladi).
  2. Xo'jayin uchun — har kuni belgilangan vaqtda umumiy hisobot yuboradi.

Alohida jarayon sifatida ishga tushiriladi:
    python -m app.integrations.telegram

Mavjud FastAPI ilovasiga tegmaydi — o'z DB sessiyasini (AsyncSessionLocal)
va o'z asyncio tsiklini ishlatadi.
"""
