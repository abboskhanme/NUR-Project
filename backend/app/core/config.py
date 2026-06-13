"""Application configuration loaded from environment variables."""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # App
    APP_NAME: str = "NUR Project"
    APP_ENV: str = "development"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/nur_erp"

    # JWT
    SECRET_KEY: str = "change-me"  # MAJBURIY: production'da .env orqali almashtiring
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # CORS — vergul bilan ajratilgan string, parse qilamiz quyida
    ALLOWED_ORIGINS_STR: str = "http://localhost:5173,http://127.0.0.1:5173"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Telegram
    TELEGRAM_BOT_TOKEN: str = ""
    TELEGRAM_WEBHOOK_URL: str = ""

    # CBU
    CBU_API_URL: str = "https://cbu.uz/uz/arkhiv-kursov-valyut/json/"

    # Seed admin
    INIT_ADMIN_PHONE: str = "+998901234567"
    INIT_ADMIN_PASSWORD: str = "Admin@12345"
    INIT_ADMIN_NAME: str = "Super Admin"

    # Uploads
    UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE_MB: int = 20

    # Kompaniya rekvizitlari — PDF hujjatlar (faktura/kvitansiya/kafolat) uchun.
    # .env orqali real qiymatlarga almashtiriladi.
    COMPANY_NAME: str = "NUR TECHNO GROUP"
    COMPANY_PHONE: str = ""
    COMPANY_ADDRESS: str = ""
    COMPANY_INN_LABEL: str = ""   # masalan: "STIR: 123456789"
    COMPANY_WEBSITE: str = ""

    INSECURE_SECRET_DEFAULT: str = "change-me"

    @property
    def ALLOWED_ORIGINS(self) -> List[str]:
        return [o.strip() for o in self.ALLOWED_ORIGINS_STR.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.APP_ENV.lower() in {"production", "prod"}

    def validate_security(self) -> list[str]:
        """Xavfsizlik sozlamalarini tekshiradi.

        Production'da xavfli sozlama topilsa xato ko'tariladi; aks holda
        ogohlantirishlar ro'yxati qaytariladi (lifespan'da log qilinadi).
        """
        problems: list[str] = []
        if self.SECRET_KEY == self.INSECURE_SECRET_DEFAULT or len(self.SECRET_KEY) < 32:
            problems.append(
                "SECRET_KEY xavfsiz emas — kamida 32 belgilik tasodifiy qiymat o'rnating "
                "(masalan: `python -c \"import secrets; print(secrets.token_urlsafe(48))\"`)."
            )
        if self.is_production and self.DEBUG:
            problems.append("Production'da DEBUG=True bo'lishi mumkin emas.")
        if self.is_production and "*" in self.ALLOWED_ORIGINS:
            problems.append("Production'da CORS '*' (barcha origin) ruxsat etilmaydi.")
        if self.is_production and self.INIT_ADMIN_PASSWORD == "Admin@12345":
            problems.append("Production'da standart admin paroli o'zgartirilishi shart.")

        if self.is_production and problems:
            raise RuntimeError(
                "Xavfsizlik konfiguratsiyasi xatosi (production):\n - " + "\n - ".join(problems)
            )
        return problems


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
