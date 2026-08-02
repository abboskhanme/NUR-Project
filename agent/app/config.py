"""Agent konfiguratsiyasi — barcha sozlamalar .env dan (pydantic-settings)."""
from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    # AI provayder
    AI_PROVIDER: str = "claude"  # claude | gemini
    ANTHROPIC_API_KEY: str = ""
    CLAUDE_MODEL: str = "claude-opus-5"
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.5-flash"
    # Opus 5'da "thinking" sukut bo'yicha YOQIQ va u ham shu limitdan yeydi —
    # javob o'rtada kesilib qolmasligi uchun 1024 emas, kengroq limit.
    AI_MAX_TOKENS: int = 2048
    # low | medium | high — sotuv javobi qisqa, "low" tez va arzon.
    AI_EFFORT: str = "low"

    # Instagram — "Instagram API with Instagram Login" (Facebook Page KERAK EMAS).
    # Bu yo'lda o'z akkauntimiz uchun App Review talab qilinmaydi (Standard Access).
    IG_API_BASE: str = "https://graph.instagram.com"
    IG_VERIFY_TOKEN: str = ""
    IG_APP_ID: str = ""          # Instagram App ID (OAuth uchun)
    IG_APP_SECRET: str = ""      # Instagram App Secret (OAuth + webhook imzosi)
    IG_ACCESS_TOKEN: str = ""    # uzoq muddatli (60 kun, avtomatik yangilanadi)
    IG_TOKEN_ISSUED_AT: str = "" # ISO sana — refresh cron shu bo'yicha hisoblaydi
    IG_USER_ID: str = ""
    GRAPH_API_VERSION: str = "v23.0"

    # Agentning tashqi (HTTPS) manzili — OAuth redirect va webhook uchun.
    # Masalan: https://erp.domeningiz.uz/agent
    AGENT_PUBLIC_URL: str = ""

    # ERP ulanishi
    ERP_INGEST_URL: str = "http://backend:8000/api/v1/leads/ingest"
    AGENT_INGEST_KEY: str = ""

    # Telegram
    TELEGRAM_BOT_TOKEN: str = ""
    TELEGRAM_CHAT_ID: str = ""
    DAILY_REPORT_TIME: str = "20:00"

    # Bilim bazasi — ERP "Tizim sozlamalari > Bilim bazasi" dan avtomatik keladi.
    # Bo'sh bo'lsa KNOWLEDGE_DIR fayllariga qaytiladi (fallback).
    KB_COMPANY: str = ""
    KB_PRODUCTS: str = ""
    KB_DELIVERY: str = ""
    KB_FAQ: str = ""
    KB_RULES: str = ""

    # Holat / boshqa
    REDIS_URL: str = ""
    KNOWLEDGE_DIR: str = "data/knowledge"
    TIMEZONE: str = "Asia/Tashkent"
    DEDUP_TTL: int = 86400
    # Operator telefondan qo'lda javob yozsa, bot shu suhbatda necha soat jim tursin.
    BOT_PAUSE_HOURS: int = 12
    LOG_LEVEL: str = "INFO"
    COMPANY_NAME: str = "NUR"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
