"""All SQLAlchemy models — import here so Alembic can autogenerate migrations."""
from app.db.base import Base
from app.models.user import Role, User, UserAvatar, UserRole
from app.models.customer import Customer
from app.models.product import Product, Inventory
from app.models.order import Order, OrderItem, Payment
from app.models.service import ServiceCategory, ServiceTicket, ServiceVisit
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
    Vendor,
    Item,
    GoodsReceipt,
    VendorPayment,
    StockMovement,
)
from app.models.system import Notification, AuditLog, FileRecord, TelegramOrder, MonthlyGoal
from app.models.debt import DebtProduct, DebtTransaction
from app.models.shipping import Shipment
from app.models.production import ProductionRecord

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
    "ServiceCategory",
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
    "Vendor",
    "Item",
    "GoodsReceipt",
    "VendorPayment",
    "StockMovement",
    "Notification",
    "AuditLog",
    "FileRecord",
    "TelegramOrder",
    "MonthlyGoal",
    "DebtProduct",
    "DebtTransaction",
    "Shipment",
    "ProductionRecord",
]
