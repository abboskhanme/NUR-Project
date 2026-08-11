"""Tizim sozlamalari katalogi — Instagram AI agenti (.env) ni UI'dan boshqarish.

Bu — QAYSI kalitlar tahrirlanishi mumkinligining yagona manbai. Qiymatlar
`system_settings` jadvalида (DB) saqlanadi; tashqi agent ularni ERP'dan
avtomatik oladi (X-Agent-Key bilan) va ishlab turgan holda qo'llaydi.

Xavfli infratuzilma sozlamalari (DATABASE_URL, SECRET_KEY, AGENT_INGEST_KEY)
bu yerга ATAYIN kiritilmagan — ular faqat .env orqali. AGENT_INGEST_KEY esa
agentning ERP bilan bog'lanish (bootstrap) kaliti — uni bu yerda boshqarish
aylanma bog'liqlik/lockout xavfini tug'diradi.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class SettingItem:
    key: str
    label: str
    group: str
    secret: bool = False
    type: str = "text"          # text | password | number | select | textarea
    options: tuple[str, ...] = ()
    placeholder: str = ""
    help: str = ""
    # hidden=True — UI'da KO'RINMAYDI (odam kiritmaydi), lekin agent uni
    # `/agent-config` orqali baribir oladi. Masalan «Ulash» tugmasi avtomatik
    # to'ldiradigan token/ID lar: ularni ekranda ko'rsatish faqat chalg'itadi.
    hidden: bool = False


GROUPS: dict[str, str] = {
    "ai": "Sun'iy intellekt (AI)",
    "knowledge": "Bilim bazasi",
    "instagram": "Instagram (Meta)",
    "telegram": "Telegram bildirishnoma",
    "general": "Umumiy",
}

CATALOG: tuple[SettingItem, ...] = (
    # --- AI ---
    SettingItem("AI_PROVIDER", "AI provayder", "ai", type="select",
                options=("claude", "gemini"),
                help="Jonli sotuvda Claude (sifatli), arzon test uchun Gemini."),
    SettingItem("ANTHROPIC_API_KEY", "Anthropic (Claude) API kaliti", "ai", secret=True),
    SettingItem("CLAUDE_MODEL", "Claude modeli", "ai", placeholder="claude-opus-5",
                help="Arzonroq variantlar: claude-sonnet-5, claude-haiku-4-5"),
    SettingItem("GEMINI_API_KEY", "Gemini API kaliti", "ai", secret=True),
    SettingItem("GEMINI_MODEL", "Gemini modeli", "ai", placeholder="gemini-2.5-flash"),
    SettingItem("AI_MAX_TOKENS", "Javob uzunligi (max token)", "ai", type="number",
                help="2048 dan pastga tushirmang — fikrlash ham shu limitdan yeydi."),
    SettingItem("AI_EFFORT", "Fikrlash darajasi", "ai", type="select",
                options=("low", "medium", "high"),
                help="Sotuv javobi qisqa — «low» tez va arzon."),

    # --- Bilim bazasi (agent shu ma'lumot asosida javob beradi) ---
    SettingItem(
        "KB_COMPANY", "Kompaniya haqida", "knowledge", type="textarea",
        placeholder="NUR — ... bilan shug'ullanamiz. Ish vaqti: ...\nManzil: ...\nAloqa: ...",
        help="Nima ish qilasiz, ish vaqti, manzil, aloqa raqamlari, ijtimoiy tarmoqlar.",
    ),
    SettingItem(
        "KB_PRODUCTS", "Mahsulotlar va narxlar", "knowledge", type="textarea",
        placeholder="- Kotyol 50L — 1 200 000 so'm, mavjud\n- Kotyol 100L — buyurtma asosida\n- ...",
        help="Har bir mahsulot: nomi, hajm/o'lcham, narx, mavjudlik. Agent faqat shu narxlarni aytadi.",
    ),
    SettingItem(
        "KB_DELIVERY", "Yetkazib berish, to'lov, kafolat", "knowledge", type="textarea",
        placeholder="Yetkazib berish: Toshkent bo'ylab bepul, viloyatlarga ...\nTo'lov: naqd/karta/bo'lib to'lash\nKafolat: 1 yil",
        help="Yetkazish hududlari va narxi, muddat, to'lov turlari, kafolat shartlari, o'rnatish.",
    ),
    SettingItem(
        "KB_FAQ", "Ko'p so'raladigan savol-javoblar", "knowledge", type="textarea",
        placeholder="S: O'rnatib berasizmi?\nJ: Ha, ustalarimiz bepul o'rnatadi.\n\nS: Qancha vaqtda tayyor?\nJ: 2-3 kun.",
        help="Har bir savolni 'S:' va javobni 'J:' bilan yozing. Iloji boricha ko'proq savolni qamrab oling.",
    ),
    SettingItem(
        "KB_RULES", "Muloqot qoidalari (ixtiyoriy)", "knowledge", type="textarea",
        placeholder="- Doim samimiy va qisqa yoz.\n- Aksiya: shu hafta 10% chegirma.\n- Narxni bilmasang, operatorga o'tkaz.",
        help="Agent uslubi, joriy aksiyalar, va NIMA deyish MUMKIN EMASligi.",
    ),

    # --- Instagram ---
    SettingItem("IG_VERIFY_TOKEN", "Webhook verify token", "instagram", secret=True,
                help="O'zingiz o'ylab topasiz; Meta webhook sozlashда kiritiladi."),
    SettingItem("IG_APP_ID", "Instagram App ID", "instagram",
                help="Meta App > Instagram > API setup with Instagram login."),
    SettingItem("IG_APP_SECRET", "Instagram App Secret", "instagram", secret=True,
                help="Xuddi shu yerdan. Webhook imzosini tekshirishda ham ishlatiladi."),
    SettingItem("AGENT_PUBLIC_URL", "Agentning tashqi manzili", "instagram",
                placeholder="https://domeningiz.uz/agent",
                help="«Ulash» tugmasi va webhook shu manzil orqali ishlaydi (HTTPS shart)."),
    # Quyidagilarni «Ulash» tugmasi avtomatik to'ldiradi — UI'da ko'rinmaydi.
    SettingItem("IG_ACCESS_TOKEN", "Access token", "instagram", secret=True, hidden=True),
    SettingItem("IG_USER_ID", "Instagram User ID", "instagram", hidden=True),
    # Akkauntning o'z ID'si va username'i — agent webhook'da O'Z izohini
    # tanish uchun ishlatadi (aks holda o'ziga javob berib halqaga tushadi).
    SettingItem("IG_ACCOUNT_ID", "Instagram Account ID", "instagram", hidden=True),
    SettingItem("IG_USERNAME", "Instagram username", "instagram", hidden=True),
    SettingItem("IG_TOKEN_ISSUED_AT", "Token olingan sana", "instagram", hidden=True),
    SettingItem("GRAPH_API_VERSION", "Graph API versiyasi", "instagram",
                placeholder="v23.0", hidden=True),

    # --- Telegram ---
    SettingItem("TELEGRAM_BOT_TOKEN", "Bot token (agent boti)", "telegram", secret=True),
    SettingItem("TELEGRAM_CHAT_ID", "Chat ID (bildirishnoma oluvchi)", "telegram"),
    SettingItem("DAILY_REPORT_TIME", "Kunlik hisobot vaqti", "telegram", placeholder="20:00"),

    # --- Umumiy ---
    SettingItem("COMPANY_NAME", "Kompaniya nomi", "general"),
    SettingItem("BOT_PAUSE_HOURS", "Operator aralashgach bot pauzasi (soat)", "general",
                type="number",
                help="Siz telefondan qo'lda javob yozsangiz, bot shu suhbatda shuncha soat jim turadi."),
    SettingItem("DEDUP_TTL", "Takror xabar bloki (soniya)", "general",
                type="number", hidden=True),
    SettingItem("TIMEZONE", "Vaqt mintaqasi", "general", placeholder="Asia/Tashkent"),
)

CATALOG_BY_KEY: dict[str, SettingItem] = {item.key: item for item in CATALOG}
ALLOWED_KEYS: frozenset[str] = frozenset(CATALOG_BY_KEY)
