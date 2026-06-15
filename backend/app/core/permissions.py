"""Permission tizimi — modul:verb ko'rinishidagi RBAC.

QO'SHIB BORISH:
  - Yangi modul: MODULES ro'yxatiga nom qo'shing (masalan 'warehouse').
  - Yangi verb: VERBS ro'yxatiga qo'shing (masalan 'export').
  - Endpoint'da: Depends(require_permission('warehouse:write'))
  - Router darajasida: APIRouter(dependencies=[Depends(module_guard('warehouse'))])
  - Frontend'da: {can('warehouse:write') && <Button />}
  - Hech qanday migration yoki tarmoq o'zgartirish kerak emas.

WILDCARD'LAR:
  - "*"           — barchasi (super-admin)
  - "module:*"    — modul ichidagi barcha amallar
  - "*:verb"      — barcha modulning shu verb'i (masalan *:read)
  - "module:verb" — aniq ruxsat

SAQLASH FORMATI (Role.permissions JSONB):
  { "permissions": ["users:read", "finance:read", "*:export"] }
"""
from __future__ import annotations

from typing import Iterable, Set

from fastapi import Depends, HTTPException, Request, status

from app.core.dependencies import CurrentUser
from app.models.user import User


# =============================================================================
# Markaziy katalog — yangi modul/verb qo'shsangiz, shu yerdan boshlang.
# =============================================================================
MODULES: list[str] = [
    "users",       # Foydalanuvchilar va rollar
    "customers",   # Mijozlar
    "orders",      # Sotuv buyurtmalari
    "products",    # Mahsulotlar va inventar
    "inventory",   # Ombor (kotyol skladi) — ID raqamli birliklar
    "service",     # Servis va kafolat
    "finance",     # Moliya
    "hr",          # Xodimlar
    "supply",      # Ta'minot
    "reports",     # Hisobotlar
    "telegram",    # Telegram bot
    "debts",       # Bizning qarzlar (mustaqil modul)
    "settings",    # Tizim sozlamalari
]

VERBS: list[str] = [
    "read",     # Ko'rish/o'qish
    "write",    # Yaratish/o'zgartirish
    "delete",   # O'chirish/arxivlash
    "approve",  # Tasdiqlash (moliya, buyurtma)
    "export",   # Eksport (xlsx/pdf)
]

# Super-admin bayrog'i belgilab qo'yilgan ruxsat sifatida
WILDCARD_ALL = "*:*"


# =============================================================================
# Asosiy mantiq
# =============================================================================
def _collect_user_permissions(user: User) -> Set[str]:
    """Foydalanuvchining barcha rollardan ruxsatlarini yig'ish."""
    perms: Set[str] = set()
    for role in (user.roles or []):
        data = role.permissions or {}
        # Yangi format: {"permissions": ["..."]} yoki to'g'ridan-to'g'ri ro'yxat
        items = data.get("permissions") if isinstance(data, dict) else data
        if not items:
            continue
        for p in items:
            if isinstance(p, str):
                perms.add(p)
    return perms


def has_permission(user: User, perm: str) -> bool:
    """Foydalanuvchi `module:verb` ruxsatiga ega-yo'qligini tekshirish."""
    # Super-admin har doim hammasiga ega
    if user.is_superadmin:
        return True
    if any(r.name == "super_admin" for r in (user.roles or [])):
        return True

    perms = _collect_user_permissions(user)
    if not perms:
        return False

    # Aniq mos kelishi
    if perm in perms:
        return True
    # Umumiy wildcard
    if "*" in perms or WILDCARD_ALL in perms:
        return True

    if ":" not in perm:
        return False
    module, verb = perm.split(":", 1)

    if f"{module}:*" in perms:
        return True
    if f"*:{verb}" in perms:
        return True

    return False


def has_any_permission(user: User, perms: Iterable[str]) -> bool:
    return any(has_permission(user, p) for p in perms)


def has_all_permissions(user: User, perms: Iterable[str]) -> bool:
    return all(has_permission(user, p) for p in perms)


# =============================================================================
# FastAPI Dependency'lar
# =============================================================================
def require_permission(*perms: str):
    """Bir nechta perm berilsa — `any` (kamida bittasi yetadi).

    Misol:
        @router.post(..., dependencies=[Depends(require_permission("finance:write"))])
    """
    async def _check(user: CurrentUser) -> User:
        if not perms or has_any_permission(user, perms):
            return user
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Ushbu amal uchun ruxsat yo'q. Kerakli: {' yoki '.join(perms)}",
        )
    return _check


def require_all_permissions(*perms: str):
    """Barcha berilgan perm'lar majburiy."""
    async def _check(user: CurrentUser) -> User:
        if has_all_permissions(user, perms):
            return user
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Ushbu amal uchun barcha quyidagilar kerak: {', '.join(perms)}",
        )
    return _check


# HTTP metod -> verb xaritasi
_METHOD_VERB: dict[str, str] = {
    "GET": "read",
    "HEAD": "read",
    "OPTIONS": "read",
    "POST": "write",
    "PUT": "write",
    "PATCH": "write",
    "DELETE": "delete",
}


def module_guard(module: str, read_exempt: tuple[str, ...] = (), exempt: tuple[str, ...] = ()):
    """Router darajasidagi modul qo'riqchisi — HTTP metodga qarab verb tanlaydi.

    GET/HEAD -> module:read (modul ichida istalgan ruxsat bo'lsa ham o'tadi)
    POST/PATCH/PUT -> module:write
    DELETE -> module:delete

    `read_exempt` — GET so'rovlarda tekshiruvsiz o'tadigan path bo'laklari
    (masalan, valyuta kursini hamma o'qiy olishi uchun "/exchange-rates").

    Misol:
        router = APIRouter(dependencies=[Depends(module_guard("orders"))])
    """
    async def _check(request: Request, user: CurrentUser) -> User:
        path = request.url.path
        # To'liq istisno — bu path'lar o'z route-darajasidagi tekshiruviga ega
        # (masalan, buyurtma to'lovlari finance ruxsati bilan boshqariladi)
        if any(part in path for part in exempt):
            return user

        verb = _METHOD_VERB.get(request.method, "write")

        if verb == "read":
            if any(part in path for part in read_exempt):
                return user
            # Modulda istalgan ruxsati bor foydalanuvchi ro'yxatlarni ko'ra oladi
            if any(has_permission(user, f"{module}:{v}") for v in VERBS):
                return user
        else:
            if has_permission(user, f"{module}:{verb}"):
                return user

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Ushbu bo'lim uchun ruxsat yo'q ({module}:{verb})",
        )
    return _check


# =============================================================================
# Frontend uchun katalog yuborish (settings/permissions endpoint)
# =============================================================================
def permission_catalog() -> dict:
    """UI matritsasini qurish uchun frontend'ga yuboriladigan ma'lumot."""
    return {
        "modules": MODULES,
        "verbs": VERBS,
        "wildcard_all": WILDCARD_ALL,
    }
