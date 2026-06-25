"""Authentication endpoints: login, refresh, logout, current user."""
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import CurrentUser
from app.core.limiter import LOGIN_RATE_LIMIT, limiter
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    normalize_phone,
    phone_digits,
    verify_password,
)
from sqlalchemy import func
from app.db.session import get_db
from app.models.user import User, UserAvatar
from app.schemas.auth import (
    LoginRequest,
    LoginResponse,
    PasswordChange,
    PinDisable,
    PinSet,
    PinTimeoutUpdate,
    PinVerify,
    RefreshRequest,
    TokenResponse,
    UserOut,
    UserUpdate,
)

ALLOWED_AVATAR_TYPES = {"image/png", "image/jpeg", "image/jpg", "image/webp", "image/gif"}
MAX_AVATAR_BYTES = 2 * 1024 * 1024

router = APIRouter()


@router.post("/login", response_model=LoginResponse, summary="Login (telefon raqam + parol)")
@limiter.limit(LOGIN_RATE_LIMIT)
async def login(
    request: Request,
    payload: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    # Format/bo'shliqdan qat'i nazar — faqat raqamlar bo'yicha solishtiramiz
    digits = phone_digits(payload.phone)
    res = await db.execute(
        select(User).where(func.regexp_replace(User.phone, r"\D", "", "g") == digits)
    )
    user = res.scalar_one_or_none()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Telefon raqam yoki parol noto'g'ri",
        )
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Akkount o'chirilgan")

    return LoginResponse(
        access_token=create_access_token(user.id, user.token_version),
        refresh_token=create_refresh_token(user.id, user.token_version),
        user=UserOut.model_validate(user),
    )


@router.post("/refresh", response_model=TokenResponse, summary="Refresh access token")
async def refresh(payload: RefreshRequest, db: Annotated[AsyncSession, Depends(get_db)]):
    try:
        data = decode_token(payload.refresh_token)
        if data.get("type") != "refresh":
            raise ValueError("Wrong token type")
        user_id = data["sub"]
        token_ver = data.get("ver", 0)
    except (ValueError, KeyError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token noto'g'ri yoki muddati o'tgan",
        )

    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Foydalanuvchi topilmadi")
    # Bekor qilingan refresh token (logout/parol almashtirish)
    if token_ver != user.token_version:
        raise HTTPException(status_code=401, detail="Refresh token bekor qilingan")

    return TokenResponse(
        access_token=create_access_token(user.id, user.token_version),
        refresh_token=create_refresh_token(user.id, user.token_version),
    )


@router.post("/logout", summary="Logout — barcha eski tokenlarni bekor qiladi")
async def logout(user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)]):
    # token_version oshiriladi — shu foydalanuvchining oldingi access/refresh
    # tokenlari darhol yaroqsiz bo'ladi (Redis kerak emas).
    user.token_version = (user.token_version or 0) + 1
    await db.commit()
    return {"detail": "Tizimdan chiqildi"}


@router.get("/me", response_model=UserOut, summary="Joriy foydalanuvchi profili")
async def me(user: CurrentUser):
    return user


@router.patch("/me", response_model=UserOut)
async def update_me(
    payload: UserUpdate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if payload.phone is not None:
        new_phone = normalize_phone(payload.phone)
        if not new_phone:
            raise HTTPException(status_code=422, detail="Telefon raqam noto'g'ri")
        if new_phone != user.phone:
            dup = await db.execute(
                select(User).where(
                    func.regexp_replace(User.phone, r"\D", "", "g") == phone_digits(new_phone),
                    User.id != user.id,
                )
            )
            if dup.scalar_one_or_none():
                raise HTTPException(status_code=409, detail="Bu telefon raqam allaqachon ishlatilgan")
        user.phone = new_phone
    for field in ("full_name", "avatar_url", "position", "theme", "telegram_chat_id"):
        val = getattr(payload, field, None)
        if val is not None:
            setattr(user, field, val)
    await db.commit()
    await db.refresh(user)
    return user


@router.patch("/me/password")
async def change_password(
    payload: PasswordChange,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if not verify_password(payload.old_password, user.password_hash):
        raise HTTPException(status_code=400, detail="Eski parol noto'g'ri")
    user.password_hash = hash_password(payload.new_password)
    # Parol almashgach barcha eski tokenlarni bekor qilamiz, joriy sessiyaga
    # esa yangi tokenlar qaytaramiz (boshqa qurilmalardagi sessiyalar uziladi).
    user.token_version = (user.token_version or 0) + 1
    await db.commit()
    await db.refresh(user)
    return {
        "detail": "Parol yangilandi",
        "access_token": create_access_token(user.id, user.token_version),
        "refresh_token": create_refresh_token(user.id, user.token_version),
    }


# ──────────────────────────── Harakatsizlik PIN-qulfi ────────────────────────────

@router.post("/me/pin", response_model=UserOut, summary="PIN-qulfni yoqish / o'zgartirish")
async def set_pin(
    payload: PinSet,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """4 xonali PIN o'rnatadi (yoki o'zgartiradi) va qulfni yoqadi.
    Joriy parol bilan tasdiqlanadi."""
    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Parol noto'g'ri")
    user.pin_hash = hash_password(payload.pin)
    user.pin_enabled = True
    user.pin_timeout_minutes = payload.timeout_minutes
    await db.commit()
    await db.refresh(user)
    return user


@router.patch("/me/pin", response_model=UserOut, summary="PIN-qulf vaqtini o'zgartirish")
async def update_pin_timeout(
    payload: PinTimeoutUpdate,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if not user.pin_enabled:
        raise HTTPException(status_code=400, detail="PIN-qulf yoqilmagan")
    user.pin_timeout_minutes = payload.timeout_minutes
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/me/pin/disable", response_model=UserOut, summary="PIN-qulfni o'chirish")
async def disable_pin(
    payload: PinDisable,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Parol noto'g'ri")
    user.pin_hash = None
    user.pin_enabled = False
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/verify-pin", summary="PIN-kodni tekshirish (qulfni ochish)")
@limiter.limit("15/minute")
async def verify_pin(
    request: Request,
    payload: PinVerify,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if not user.pin_enabled or not user.pin_hash:
        raise HTTPException(status_code=400, detail="PIN-qulf yoqilmagan")
    if not verify_password(payload.pin, user.pin_hash):
        raise HTTPException(status_code=400, detail="PIN-kod noto'g'ri")
    return {"detail": "ok"}


@router.post("/me/avatar", response_model=UserOut)
async def upload_my_avatar(
    file: Annotated[UploadFile, File(description="Profil rasmi (PNG/JPEG/WEBP, <2MB)")],
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Joriy foydalanuvchi o'z avatarini yuklaydi."""
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
    await db.refresh(user)
    return user


@router.delete("/me/avatar", status_code=204)
async def delete_my_avatar(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    res = await db.execute(select(UserAvatar).where(UserAvatar.user_id == user.id))
    av = res.scalar_one_or_none()
    if av:
        await db.delete(av)
    user.avatar_url = None
    await db.commit()
