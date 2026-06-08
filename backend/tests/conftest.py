"""Pytest fixtures.

Ikki bosqichli testlar:
  - Pure unit testlar (DB kerak emas) — har joyda ishlaydi.
  - Integration testlar — TEST_DATABASE_URL berilgan bo'lsa ishlaydi,
    aks holda skip qilinadi. CI'da Postgres service container beradi.
"""
import os
from types import SimpleNamespace

import pytest


def make_user(*, permissions=None, is_superadmin=False, role_name="staff", **extra):
    """has_permission() uchun yengil soxta User obyekti.

    permissions — ["orders:read", "*:export", ...] ko'rinishidagi ro'yxat.
    """
    role = SimpleNamespace(
        name=role_name,
        permissions={"permissions": list(permissions or [])},
    )
    return SimpleNamespace(
        is_superadmin=is_superadmin,
        roles=[role],
        token_version=0,
        is_active=True,
        **extra,
    )


@pytest.fixture
def user_factory():
    return make_user


# --- Integration (DB) fixtures -------------------------------------------------

TEST_DATABASE_URL = os.getenv("TEST_DATABASE_URL")
requires_db = pytest.mark.skipif(
    not TEST_DATABASE_URL,
    reason="TEST_DATABASE_URL o'rnatilmagan — integration testlar o'tkazib yuborildi",
)


@pytest.fixture
async def db_engine():
    """TEST_DATABASE_URL bo'yicha engine; barcha jadvallarni yaratadi/tozalaydi."""
    from sqlalchemy.ext.asyncio import create_async_engine

    from app.db.base import Base
    import app.models  # noqa: F401 — barcha modellarni ro'yxatga olish uchun

    engine = create_async_engine(TEST_DATABASE_URL, future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest.fixture
async def client(db_engine):
    """get_db'ni test engine'ga ulagan holda ASGI httpx mijozi."""
    from httpx import ASGITransport, AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

    from app.db.session import get_db
    from app.main import app

    TestSession = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)

    async def override_get_db():
        async with TestSession() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        ac._session_factory = TestSession  # testlarda to'g'ridan-to'g'ri DB uchun
        yield ac
    app.dependency_overrides.clear()
