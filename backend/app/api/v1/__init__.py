"""API v1 aggregator router."""
from fastapi import APIRouter

from app.api.v1 import (
    auth,
    users,
    customers,
    products,
    inventory,
    orders,
    service,
    finance,
    hr,
    supply,
    taminot,
    telegram,
    notifications,
    reports,
    permissions,
    search,
    debts,
    shipping,
    production,
    goals,
)

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Auth"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(customers.router, prefix="/customers", tags=["Customers"])
api_router.include_router(products.router, prefix="/products", tags=["Products"])
api_router.include_router(inventory.router, prefix="/inventory", tags=["Warehouse / Ombor"])
api_router.include_router(orders.router, prefix="/orders", tags=["Sales / Orders"])
api_router.include_router(service.router, prefix="/service", tags=["Service"])
api_router.include_router(finance.router, prefix="/finance", tags=["Finance"])
api_router.include_router(hr.router, prefix="/hr", tags=["HR"])
api_router.include_router(supply.router, prefix="/supply", tags=["Supply"])
api_router.include_router(taminot.router, prefix="/taminot", tags=["Ta'minot (ichki/tashqi)"])
api_router.include_router(telegram.router, prefix="/telegram", tags=["Telegram Bot"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(reports.router, prefix="/reports", tags=["Reports"])
api_router.include_router(permissions.router, prefix="/permissions", tags=["Permissions"])
api_router.include_router(search.router, prefix="/search", tags=["Search"])
api_router.include_router(debts.router, prefix="/debts", tags=["Debts / Bizning qarzlar"])
api_router.include_router(shipping.router, prefix="/shipping", tags=["Shipping / Yuk chiqarish"])
api_router.include_router(production.router, prefix="/production", tags=["Production / Ishlab chiqarish"])
api_router.include_router(goals.router, prefix="/goals", tags=["Goals / Oylik maqsadlar"])
