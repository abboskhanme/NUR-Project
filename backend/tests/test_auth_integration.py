"""Auth oqimi va token bekor qilish — integration testlar (Postgres kerak).

TEST_DATABASE_URL berilmagan bo'lsa avtomatik skip qilinadi.
"""
import pytest

from tests.conftest import requires_db

pytestmark = requires_db

LOGIN_PHONE = "+998901112233"
LOGIN_PASS = "Test@12345"


async def _seed_user(client):
    """Test foydalanuvchisini to'g'ridan-to'g'ri DB orqali yaratadi."""
    from app.core.security import hash_password
    from app.models.user import User

    async with client._session_factory() as db:
        user = User(
            phone=LOGIN_PHONE,
            password_hash=hash_password(LOGIN_PASS),
            full_name="Test User",
            is_active=True,
        )
        db.add(user)
        await db.commit()
        return str(user.id)


async def test_login_success_and_me(client):
    await _seed_user(client)
    res = await client.post("/api/v1/auth/login", json={"phone": LOGIN_PHONE, "password": LOGIN_PASS})
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["access_token"] and body["refresh_token"]

    me = await client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {body['access_token']}"}
    )
    assert me.status_code == 200
    assert me.json()["phone"] == LOGIN_PHONE


async def test_login_wrong_password(client):
    await _seed_user(client)
    res = await client.post(
        "/api/v1/auth/login", json={"phone": LOGIN_PHONE, "password": "wrong"}
    )
    assert res.status_code == 401


async def test_logout_revokes_old_access_token(client):
    await _seed_user(client)
    login = (
        await client.post(
            "/api/v1/auth/login", json={"phone": LOGIN_PHONE, "password": LOGIN_PASS}
        )
    ).json()
    headers = {"Authorization": f"Bearer {login['access_token']}"}

    # Logout token_version'ni oshiradi
    out = await client.post("/api/v1/auth/logout", headers=headers)
    assert out.status_code == 200

    # Eski access token endi yaroqsiz
    me = await client.get("/api/v1/auth/me", headers=headers)
    assert me.status_code == 401

    # Eski refresh token ham bekor qilingan
    refreshed = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": login["refresh_token"]}
    )
    assert refreshed.status_code == 401


async def test_refresh_issues_new_tokens(client):
    await _seed_user(client)
    login = (
        await client.post(
            "/api/v1/auth/login", json={"phone": LOGIN_PHONE, "password": LOGIN_PASS}
        )
    ).json()
    res = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": login["refresh_token"]}
    )
    assert res.status_code == 200
    assert res.json()["access_token"]
