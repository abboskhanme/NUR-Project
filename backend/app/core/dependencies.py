"""FastAPI dependencies: auth, role checks."""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import decode_token
from app.db.session import get_db
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_PREFIX}/auth/login")


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    creds_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Avtorizatsiya xatosi",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        token_type = payload.get("type")
        token_ver = payload.get("ver", 0)
        if user_id is None or token_type != "access":
            raise creds_exc
    except ValueError:
        raise creds_exc

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise creds_exc
    # Token bekor qilingan bo'lsa (logout/parol almashtirish) — rad etamiz
    if token_ver != user.token_version:
        raise creds_exc
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


def require_roles(*allowed: str):
    """Dependency factory: require any of given role names."""
    async def _check(user: CurrentUser) -> User:
        user_roles = {r.name for r in (user.roles or [])}
        if not (user_roles & set(allowed)):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Ushbu amal uchun ruxsat yo'q. Kerakli rol(lar): {', '.join(allowed)}",
            )
        return user
    return _check
