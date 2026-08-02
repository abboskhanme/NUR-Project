"""AI provayder fabrikasi — .env dagi AI_PROVIDER bo'yicha birini beradi (singleton)."""
from __future__ import annotations

from functools import lru_cache

from app.ai.base import AIProvider
from app.config import settings


@lru_cache
def get_provider() -> AIProvider:
    provider = settings.AI_PROVIDER.strip().lower()
    if provider == "claude":
        from app.ai.claude_provider import ClaudeProvider

        return ClaudeProvider()
    if provider == "gemini":
        from app.ai.gemini_provider import GeminiProvider

        return GeminiProvider()
    if provider == "mock":
        # Kalitsiz sinash uchun (tashqi API chaqirmaydi)
        from app.ai.mock_provider import MockProvider

        return MockProvider()
    raise RuntimeError(f"Noma'lum AI_PROVIDER: {settings.AI_PROVIDER!r} (claude|gemini|mock)")
