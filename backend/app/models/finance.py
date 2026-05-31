"""Finance: accounts (3 ledgers: UZS, USD, GAZNA), transactions, exchange rates."""
import uuid
from datetime import date
from decimal import Decimal
from typing import Optional

from sqlalchemy import Date, ForeignKey, Numeric, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


# Transaction type
TX_INCOME = "income"
TX_EXPENSE = "expense"
TX_TRANSFER = "transfer"


class Account(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "accounts"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    # "operational" or "gazna" - for separating cash USD ledger
    ledger: Mapped[str] = mapped_column(String(20), default="operational")
    balance: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)


class FinanceCategory(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "finance_categories"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    parent_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("finance_categories.id", ondelete="SET NULL")
    )
    kind: Mapped[str] = mapped_column(String(20), default="expense")  # income/expense
    code: Mapped[Optional[str]] = mapped_column(String(50), unique=True)


class FinanceTransaction(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "finance_transactions"

    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    type: Mapped[str] = mapped_column(String(20), index=True)  # income/expense/transfer
    category_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("finance_categories.id", ondelete="SET NULL")
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    amount_other_curr: Mapped[Decimal] = mapped_column(Numeric(16, 2), default=0)
    account_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("accounts.id", ondelete="SET NULL")
    )
    related_order_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="SET NULL"), index=True
    )
    doc_file_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))
    note: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )


class ExchangeRate(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "exchange_rates"
    __table_args__ = (UniqueConstraint("date", name="uq_exchange_rate_date"),)

    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    usd_to_uzs: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    source: Mapped[str] = mapped_column(String(20), default="manual")  # manual/cbu
