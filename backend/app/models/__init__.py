"""All SQLAlchemy models — import here so Alembic can autogenerate migrations."""
from app.db.base import Base
from app.models.user import Role, User, UserAvatar, UserRole
from app.models.customer import Customer
from app.models.product import Product, Inventory
from app.models.order import Order, OrderItem, Payment
from app.models.service import ServiceTicket, ServiceVisit
from app.models.finance import (
    Account,
    FinanceCategory,
    FinanceTransaction,
    ExchangeRate,
)
from app.models.hr import (
    Department,
    Position,
    Employee,
    SalaryRate,
    Attendance,
    SalaryAdvance,
    PayrollRun,
    PayrollItem,
)
from app.models.supply import (
    SupplySector,
    Vendor,
    Item,
    GoodsReceipt,
    VendorPayment,
    StockMovement,
)
from app.models.system import Notification, AuditLog, FileRecord, TelegramOrder

__all__ = [
    "Base",
    "Role",
    "User",
    "UserAvatar",
    "UserRole",
    "Customer",
    "Product",
    "Inventory",
    "Order",
    "OrderItem",
    "Payment",
    "ServiceTicket",
    "ServiceVisit",
    "Account",
    "FinanceCategory",
    "FinanceTransaction",
    "ExchangeRate",
    "Department",
    "Position",
    "Employee",
    "SalaryRate",
    "Attendance",
    "SalaryAdvance",
    "PayrollRun",
    "PayrollItem",
    "SupplySector",
    "Vendor",
    "Item",
    "GoodsReceipt",
    "VendorPayment",
    "StockMovement",
    "Notification",
    "AuditLog",
    "FileRecord",
    "TelegramOrder",
]
