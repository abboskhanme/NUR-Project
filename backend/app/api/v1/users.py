"""User management (Super Admin) — CRUD, avatar, parol reset, rollar, arxiv."""
import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Query, Response, UploadFile
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser, require_roles
from app.core.permissions import require_permission  # Yangi permission tizimi
from app.core.security import hash_password, normalize_phone, phone_digits
from app.db.session import get_db
from app.models.hr import Employee, Position
from app.models.supply import Vendor
from app.models.user import Role, User, UserAvatar
from app.schemas.auth import (
    AdminPasswordReset,
    RoleCreate,
    RoleOut,
    RoleUpdate,
    UserCreate,
    UserOut,
    UserUpdate,
)
from app.schemas.common import Page

router = APIRouter()


ALLOWED_AVATAR_TYPES = {"image/png", "image/jpeg", "image/jpg", "image/webp", "image/gif"}
MAX_AVATAR_BYTES = 2 * 1024 * 1024


def _ensure_superadmin(user: User) -> None:
    if user.is_superadmin:
        return
    if any(r.name == "super_admin" for r in (user.roles or [])):
        return
    raise HTTPException(status_code=403, detail="Faqat super-admin uchun")


async def _find_or_create_position(db: AsyncSession, name: str | None) -> uuid.UUID | None:
    """Lavozim nomi bo'yicha mavjudini topadi yoki yangisini yaratadi (Lavozimlar ro'yxati)."""
    if not name or not name.strip():
        return None
    name = name.strip()
    res = await db.execute(select(Position).where(func.lower(Position.name) == name.lower()))
    pos = res.scalar_one_or_none()
    if pos:
        return pos.id
    pos = Position(name=name)
    db.add(pos)
    await db.flush()
    return pos.id


async def _sync_employee_from_user(db: AsyncSession, user: User) -> None:
    """Foydalanuvchi uchun bog'langan 'Ofis xodimi' Employee yozuvini yaratadi/yangilaydi.

    Users bo'limidan o'tgan har bir foydalanuvchi avtomatik ravishda HR bo'limida
    employment_type='office' (Ofis xodimi) sifatida ko'rinadi.
    """
    res = await db.execute(select(Employee).where(Employee.user_id == user.id))
    emp = res.scalar_one_or_none()
    position_id = await _find_or_create_position(db, user.position)
    new_status = "active" if user.is_active else "terminated"

    if emp is None:
        # Ish boshlagan sana — foydalanuvchi tizimga qo'shilgan kun
        hire = user.created_at.date() if getattr(user, "created_at", None) else date.today()
        emp = Employee(
            full_name=user.full_name,
            phone=user.phone,
            employment_type="office",
            has_account=True,
            user_id=user.id,
            position_id=position_id,
            status=new_status,
            hire_date=hire,
        )
        db.add(emp)
    else:
        emp.full_name = user.full_name
        emp.phone = user.phone
        emp.has_account = True
        emp.employment_type = "office"
        emp.status = new_status
        # Lavozim faqat foydalanuvchida ko'rsatilgan bo'lsa yangilanadi
        if position_id is not None:
            emp.position_id = position_id


async def _sync_vendor_from_user(db: AsyncSession, user: User) -> None:
    """'supplier' rolli foydalanuvchi uchun bog'langan Taminotchi (Vendor) yozuvini
    yaratadi/yangilaydi. Shu sababli taminotchilar alohida qo'shilmaydi — Foydalanuvchilar
    bo'limida 'Taminotchi' roli berilgan har bir user avtomatik Ta'minot bo'limida paydo bo'ladi.

    Rol olib tashlansa yoki user arxivlansa — vendor nofaol qilinadi (ma'lumot o'chmaydi).
    """
    role_names = {r.name for r in (user.roles or [])}
    res = await db.execute(select(Vendor).where(Vendor.user_id == user.id))
    vendor = res.scalar_one_or_none()

    if "supplier" in role_names:
        if vendor is None:
            db.add(Vendor(
                name=user.full_name, user_id=user.id,
                phone=user.phone, is_active=user.is_active,
            ))
        else:
            vendor.name = user.full_name
            vendor.phone = user.phone
            vendor.is_active = user.is_active
    elif vendor is not None:
        # Taminotchi roli olib tashlandi — yozuvni o'chirmaymiz, faqat nofaol qilamiz
        vendor.is_active = False


# ============================================================
# CRUD
# ============================================================
@router.get("", response_model=Page[UserOut])
async def list_users(
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    q: str | None = Query(None, description="Telefon yoki ism bo'yicha qidiruv"),
    is_active: bool | None = Query(None, description="Aktivlar (true) yoki arxiv (false)"),
):
    stmt = select(User)
    count_stmt = select(func.count(User.id))
    if q:
        like = f"%{q.lower()}%"
        stmt = stmt.where(
            func.lower(User.phone).like(like) | func.lower(User.full_name).like(like)
        )
        count_stmt = count_stmt.where(
            func.lower(User.phone).like(like) | func.lower(User.full_name).like(like)
        )
    if is_active is not None:
        stmt = stmt.where(User.is_active == is_active)
        count_stmt = count_stmt.where(User.is_active == is_active)

    total_res = await db.execute(count_stmt)
    total = total_res.scalar() or 0
    res = await db.execute(
        stmt.offset((page - 1) * page_size).limit(page_size).order_by(User.created_at.desc())
    )
    users = res.scalars().all()
    return Page[UserOut](
        items=[UserOut.model_validate(u) for u in users],
        total=total, page=page, page_size=page_size,
    )


@router.post("", response_model=UserOut, status_code=201)
async def create_user(
    payload: UserCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    new_phone = normalize_phone(payload.phone)
    if not new_phone:
        raise HTTPException(status_code=422, detail="Telefon raqam noto'g'ri")
    exists = await db.execute(
        select(User).where(func.regexp_replace(User.phone, r"\D", "", "g") == phone_digits(new_phone))
    )
    if exists.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Bu telefon raqam allaqachon mavjud")

    user = User(
        phone=new_phone,
        password_hash=hash_password(payload.password),
        full_name=payload.full_name,
        position=payload.position,
    )
    if payload.role_names:
        rr = await db.execute(select(Role).where(Role.name.in_(payload.role_names)))
        user.roles = list(rr.scalars().all())
        user.is_superadmin = "super_admin" in payload.role_names
    db.add(user)
    await db.flush()
    # Avtomatik ravishda HR bo'limiga "Ofis xodimi" sifatida qo'shamiz
    await _sync_employee_from_user(db, user)
    # 'supplier' rolli bo'lsa — Ta'minot bo'limiga taminotchi sifatida qo'shamiz
    await _sync_vendor_from_user(db, user)
    await db.commit()
    await db.refresh(user)
    return user


@router.patch("/{user_id}", response_model=UserOut)
async def update_user(
    user_id: uuid.UUID,
    payload: UserUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Foydalanuvchi topilmadi")

    if payload.phone is not None:
        new_phone = normalize_phone(payload.phone)
        if not new_phone:
            raise HTTPException(422, "Telefon raqam noto'g'ri")
        if new_phone != user.phone:
            dup = await db.execute(
                select(User).where(
                    func.regexp_replace(User.phone, r"\D", "", "g") == phone_digits(new_phone),
                    User.id != user_id,
                )
            )
            if dup.scalar_one_or_none():
                raise HTTPException(409, "Bunday telefon raqam allaqachon ishlatilgan")
            user.phone = new_phone

    for field in (
        "full_name", "avatar_url", "position",
        "locale", "theme", "is_active", "is_superadmin", "telegram_chat_id",
    ):
        val = getattr(payload, field, None)
        if val is not None:
            setattr(user, field, val)

    if payload.role_names is not None:
        rr = await db.execute(select(Role).where(Role.name.in_(payload.role_names)))
        user.roles = list(rr.scalars().all())
        user.is_superadmin = "super_admin" in payload.role_names

    # Bog'langan HR yozuvini sinxronlaymiz (ism, telefon, lavozim, status)
    await _sync_employee_from_user(db, user)
    # Bog'langan taminotchi yozuvini sinxronlaymiz (rol/nom/status)
    await _sync_vendor_from_user(db, user)
    await db.commit()
    await db.refresh(user)
    return user


@router.delete("/{user_id}", status_code=204)
async def delete_user(
    user_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    """Soft delete — foydalanuvchi arxivga ko'chadi (is_active=False)."""
    _ensure_superadmin(current)
    if str(current.id) == str(user_id):
        raise HTTPException(400, "O'zingizni arxivga ko'chira olmaysiz")
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    user.is_active = False
    # Bog'langan xodim ham arxivlanadi (status=terminated)
    await _sync_employee_from_user(db, user)
    await _sync_vendor_from_user(db, user)
    await db.commit()


@router.post("/{user_id}/restore", response_model=UserOut)
async def restore_user(
    user_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    """Arxivdan tiklash — is_active=True."""
    _ensure_superadmin(current)
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    user.is_active = True
    # Bog'langan xodim qayta faollashadi (status=active)
    await _sync_employee_from_user(db, user)
    await _sync_vendor_from_user(db, user)
    await db.commit()
    await db.refresh(user)
    return user


@router.delete("/{user_id}/permanent", status_code=204)
async def permanently_delete_user(
    user_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    """Butunlay o'chirish — DB'dan to'liq olib tashlanadi. Faqat arxivdagi foydalanuvchini o'chirish mumkin."""
    _ensure_superadmin(current)
    if str(current.id) == str(user_id):
        raise HTTPException(400, "O'zingizni o'chira olmaysiz")
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    if user.is_active:
        raise HTTPException(400, "Aktiv foydalanuvchini butunlay o'chirib bo'lmaydi. Avval arxivga ko'chiring.")
    # Avtomatik yaratilgan Ofis xodimi yozuvini ham o'chiramiz
    emp_res = await db.execute(select(Employee).where(Employee.user_id == user.id))
    emp = emp_res.scalar_one_or_none()
    if emp is not None:
        await db.delete(emp)
    await db.delete(user)
    await db.commit()


# ============================================================
# Admin parol reset
# ============================================================
@router.post("/{user_id}/password", status_code=200)
async def admin_reset_password(
    user_id: uuid.UUID,
    payload: AdminPasswordReset,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    user.password_hash = hash_password(payload.new_password)
    await db.commit()
    return {"detail": "Parol yangilandi"}


# ============================================================
# Avatar
# ============================================================
async def _save_avatar(db: AsyncSession, user: User, file: UploadFile) -> None:
    if file.content_type not in ALLOWED_AVATAR_TYPES:
        raise HTTPException(400, f"Rasm formati qo'llab-quvvatlanmaydi: {file.content_type}")
    data = await file.read()
    if len(data) == 0:
        raise HTTPException(400, "Fayl bo'sh")
    if len(data) > MAX_AVATAR_BYTES:
        raise HTTPException(400, f"Fayl 2 MB dan kichik bo'lishi kerak (hozir {len(data)} bayt)")

    existing = await db.execute(select(UserAvatar).where(UserAvatar.user_id == user.id))
    av = existing.scalar_one_or_none()
    if av is None:
        av = UserAvatar(
            user_id=user.id,
            content_type=file.content_type,
            size_bytes=len(data),
            data=data,
        )
        db.add(av)
    else:
        av.content_type = file.content_type
        av.size_bytes = len(data)
        av.data = data

    user.avatar_url = f"/api/v1/users/{user.id}/avatar"
    await db.commit()


@router.post("/{user_id}/avatar", response_model=UserOut)
async def upload_avatar(
    user_id: uuid.UUID,
    file: Annotated[UploadFile, File(description="Profil rasmi (PNG/JPEG/WEBP, <2MB)")],
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    await _save_avatar(db, user, file)
    await db.refresh(user)
    return user


@router.get("/{user_id}/avatar")
async def get_avatar(
    user_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    res = await db.execute(select(UserAvatar).where(UserAvatar.user_id == user_id))
    av = res.scalar_one_or_none()
    if not av:
        raise HTTPException(404, "Avatar mavjud emas")
    return Response(
        content=av.data,
        media_type=av.content_type,
        headers={"Cache-Control": "private, max-age=300"},
    )


@router.delete("/{user_id}/avatar", status_code=204)
async def delete_avatar(
    user_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    res = await db.execute(select(UserAvatar).where(UserAvatar.user_id == user_id))
    av = res.scalar_one_or_none()
    if av:
        await db.delete(av)

    u_res = await db.execute(select(User).where(User.id == user_id))
    user = u_res.scalar_one_or_none()
    if user:
        user.avatar_url = None
    await db.commit()


# ============================================================
# Rollar
# ============================================================
@router.get("/roles/all", response_model=list[RoleOut])
async def list_roles(db: Annotated[AsyncSession, Depends(get_db)], _: CurrentUser):
    res = await db.execute(select(Role).order_by(Role.name))
    return [RoleOut.model_validate(r) for r in res.scalars().all()]


@router.post("/roles", response_model=RoleOut, status_code=201)
async def create_role(
    payload: RoleCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    exists = await db.execute(select(Role).where(Role.name == payload.name))
    if exists.scalar_one_or_none():
        raise HTTPException(409, "Bu nomli rol mavjud")
    role = Role(
        name=payload.name,
        description=payload.description,
        permissions=payload.permissions or {},
    )
    db.add(role)
    await db.commit()
    await db.refresh(role)
    return role


@router.patch("/roles/{role_id}", response_model=RoleOut)
async def update_role(
    role_id: uuid.UUID,
    payload: RoleUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    res = await db.execute(select(Role).where(Role.id == role_id))
    role = res.scalar_one_or_none()
    if not role:
        raise HTTPException(404, "Rol topilmadi")

    if payload.name is not None and payload.name != role.name:
        dup = await db.execute(
            select(Role).where(Role.name == payload.name, Role.id != role_id)
        )
        if dup.scalar_one_or_none():
            raise HTTPException(409, "Bu nomli rol allaqachon mavjud")
        role.name = payload.name
    if payload.description is not None:
        role.description = payload.description
    if payload.permissions is not None:
        role.permissions = payload.permissions

    await db.commit()
    await db.refresh(role)
    return role


@router.delete("/roles/{role_id}", status_code=204)
async def delete_role(
    role_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    res = await db.execute(select(Role).where(Role.id == role_id))
    role = res.scalar_one_or_none()
    if not role:
        raise HTTPException(404, "Rol topilmadi")
    if role.name == "super_admin":
        raise HTTPException(400, "super_admin rolini o'chirib bo'lmaydi")
    await db.delete(role)
    await db.commit()


@router.patch("/roles/{role_id}/permissions", response_model=RoleOut)
async def update_role_permissions(
    role_id: uuid.UUID,
    permissions: dict,
    db: Annotated[AsyncSession, Depends(get_db)],
    current: CurrentUser,
):
    _ensure_superadmin(current)
    res = await db.execute(select(Role).where(Role.id == role_id))
    role = res.scalar_one_or_none()
    if not role:
        raise HTTPException(404, "Rol topilmadi")
    role.permissions = permissions
    await db.commit()
    await db.refresh(role)
    return role
