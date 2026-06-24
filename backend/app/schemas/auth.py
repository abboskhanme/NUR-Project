"""Authentication schemas."""
import uuid
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase


class LoginRequest(BaseModel):
    phone: str = Field(min_length=4, max_length=20)
    password: str = Field(min_length=6)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class RoleOut(ORMBase):
    id: uuid.UUID
    name: str
    description: Optional[str] = None
    permissions: dict = {}


class RoleCreate(BaseModel):
    name: str = Field(min_length=2, max_length=50)
    description: Optional[str] = None
    permissions: dict = {}


class RoleUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=2, max_length=50)
    description: Optional[str] = None
    permissions: Optional[dict] = None


class UserOut(ORMBase):
    id: uuid.UUID
    phone: str
    full_name: str
    avatar_url: Optional[str] = None
    position: Optional[str] = None
    locale: str = "uz"
    theme: str = "light"
    is_active: bool = True
    is_superadmin: bool = False
    roles: list[RoleOut] = []


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut


class PasswordChange(BaseModel):
    old_password: str
    new_password: str = Field(min_length=8)


class UserCreate(BaseModel):
    phone: str = Field(min_length=4, max_length=20)
    password: str = Field(min_length=8)
    full_name: str
    position: Optional[str] = None
    role_names: list[str] = []


class UserUpdate(BaseModel):
    phone: Optional[str] = Field(default=None, min_length=4, max_length=20)
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    position: Optional[str] = None
    locale: Optional[str] = None
    theme: Optional[str] = None
    is_active: Optional[bool] = None
    is_superadmin: Optional[bool] = None
    telegram_chat_id: Optional[str] = None
    role_names: Optional[list[str]] = None


class AdminPasswordReset(BaseModel):
    new_password: str = Field(min_length=8)


class LinkableEmployeeOut(BaseModel):
    """Akkaunti yo'q (foydalanuvchiga aylantirish mumkin bo'lgan) HR xodimi."""
    id: uuid.UUID
    full_name: str
    phone: Optional[str] = None
    position: Optional[str] = None


class UserFromEmployee(BaseModel):
    """Mavjud xodimni sayt foydalanuvchisiga aylantirish payloadi.

    full_name/position berilmasa — xodim yozuvidan olinadi.
    """
    phone: str = Field(min_length=4, max_length=20)
    password: str = Field(min_length=8)
    full_name: Optional[str] = None
    position: Optional[str] = None
    role_names: list[str] = []
