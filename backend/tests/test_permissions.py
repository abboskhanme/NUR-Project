"""Permission tizimi (modul:verb RBAC) uchun unit testlar — DB kerak emas."""
from tests.conftest import make_user

from app.core.permissions import (
    has_all_permissions,
    has_any_permission,
    has_permission,
)


def test_exact_permission():
    user = make_user(permissions=["orders:read"])
    assert has_permission(user, "orders:read")
    assert not has_permission(user, "orders:write")


def test_superadmin_flag_grants_everything():
    user = make_user(permissions=[], is_superadmin=True)
    assert has_permission(user, "finance:approve")
    assert has_permission(user, "anything:goes")


def test_super_admin_role_name_grants_everything():
    user = make_user(permissions=[], role_name="super_admin")
    assert has_permission(user, "finance:approve")


def test_module_wildcard():
    user = make_user(permissions=["finance:*"])
    assert has_permission(user, "finance:read")
    assert has_permission(user, "finance:approve")
    assert not has_permission(user, "orders:read")


def test_verb_wildcard():
    user = make_user(permissions=["*:export"])
    assert has_permission(user, "reports:export")
    assert has_permission(user, "finance:export")
    assert not has_permission(user, "reports:read")


def test_global_wildcard():
    user = make_user(permissions=["*"])
    assert has_permission(user, "hr:delete")


def test_empty_permissions_denies():
    user = make_user(permissions=[])
    assert not has_permission(user, "orders:read")


def test_has_any_and_all():
    user = make_user(permissions=["orders:read", "customers:read"])
    assert has_any_permission(user, ["orders:read", "finance:read"])
    assert not has_any_permission(user, ["finance:read", "hr:read"])
    assert has_all_permissions(user, ["orders:read", "customers:read"])
    assert not has_all_permissions(user, ["orders:read", "finance:read"])


def test_malformed_permission_string_is_safe():
    user = make_user(permissions=["orders"])  # ":" yo'q
    assert not has_permission(user, "orders:read")
