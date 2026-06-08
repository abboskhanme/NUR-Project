"""Rate limiting — slowapi (in-memory, bitta instance uchun mos).

Bir nechta instance/worker ishlatilsa, REDIS_URL'ni storage sifatida ulang:
    Limiter(key_func=..., storage_uri=settings.REDIS_URL)
"""
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import settings

# IP manzil bo'yicha cheklaymiz. Standart limit barcha endpointlarga tegishli;
# alohida endpointlar @limiter.limit(...) bilan qattiqroq cheklanadi.
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["240/minute"],
    enabled=not settings.DEBUG,  # development'da o'chiq
)

# Login kabi nozik endpointlar uchun qattiq limit
LOGIN_RATE_LIMIT = "5/minute"
