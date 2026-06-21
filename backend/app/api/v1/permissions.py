"""Permissions katalog va joriy foydalanuvchi ruxsatlari."""
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.permissions import (
    _collect_user_permissions,
    ensure_can_grant_special,
    has_permission,
    has_special,
    is_superadmin,
    permission_catalog,
)
from app.db.session import get_db
from app.models.user import Role

router = APIRouter()


@router.get("/catalog", summary="Modul va verb katalogi (UI matritsasi uchun)")
async def get_catalog(_: CurrentUser):
    return permission_catalog()


@router.get("/me", summary="Joriy foydalanuvchining ruxsatlari ro'yxati")
async def get_my_permissions(user: CurrentUser):
    return {
        "is_superadmin": is_superadmin(user),
        "permissions": sorted(_collect_user_permissions(user)),
    }


@router.get("/check", summary="Bitta ruxsatni tekshirish (debug)")
async def check(perm: str, user: CurrentUser):
    return {"perm": perm, "allowed": has_permission(user, perm)}


@router.patch("/role/{role_id}", summary="Rolga ruxsatlar ro'yxatini yangilash")
async def set_role_permissions(
    role_id: str,
    payload: dict,  # {"permissions": ["users:read", "..."]}
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Rolga ruxsatlar ro'yxatini yangilash — `system:roles` huquqi kerak.

    Maxsus (super-admin darajasidagi) ruxsatlarni biriktirish faqat haqiqiy
    super-adminga ruxsat etiladi (privilege escalation'dan himoya).
    """
    if not has_special(user, "system:roles"):
        raise HTTPException(403, "Bu amal uchun ruxsat yo'q (super-admin darajasidagi).")
    res = await db.execute(select(Role).where(Role.id == role_id))
    role = res.scalar_one_or_none()
    if not role:
        raise HTTPException(404, "Rol topilmadi")
    perms = payload.get("permissions") or []
    if not isinstance(perms, list):
        raise HTTPException(400, "permissions list bo'lishi kerak")
    new_perms = [str(p) for p in perms]
    old_data = role.permissions or {}
    old_perms = old_data.get("permissions") if isinstance(old_data, dict) else old_data
    ensure_can_grant_special(user, new_perms, old_perms or [])
    role.permissions = {"permissions": new_perms}
    await db.commit()
    await db.refresh(role)
    return {"id": str(role.id), "name": role.name, "permissions": role.permissions}
