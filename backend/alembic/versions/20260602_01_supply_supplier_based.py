"""ta'minot modulini taminotchi-asosli qilish

Revision ID: 20260602_01
Revises: 20260601_03
Create Date: 2026-06-02

Sektor (supply_sectors) tushunchasi olib tashlandi. Mahsulot endi taminotchiga
(items.vendor_id) tegishli, taminotchi login akkauntiga bog'lanadi
(vendors.user_id). Items'ga unit_price, vendor_payments'ga receipt_id qo'shildi.

Idempotent (IF EXISTS / IF NOT EXISTS) — chunki jadvallar seed.create_all orqali
ham yaratilishi mumkin.
"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20260602_01"
down_revision: Union[str, None] = "20260601_03"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- vendors ---
    op.execute("ALTER TABLE vendors ADD COLUMN IF NOT EXISTS user_id UUID")
    op.execute("ALTER TABLE vendors ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true")
    op.execute("ALTER TABLE vendors DROP COLUMN IF EXISTS sector_id")
    op.execute(
        "DO $$ BEGIN "
        "IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_vendors_user_id') THEN "
        "ALTER TABLE vendors ADD CONSTRAINT fk_vendors_user_id FOREIGN KEY (user_id) "
        "REFERENCES users(id) ON DELETE SET NULL; END IF; END $$;"
    )
    op.execute("CREATE UNIQUE INDEX IF NOT EXISTS ix_vendors_user_id ON vendors (user_id)")

    # --- items ---
    op.execute("ALTER TABLE items ADD COLUMN IF NOT EXISTS vendor_id UUID")
    op.execute("ALTER TABLE items ADD COLUMN IF NOT EXISTS unit_price NUMERIC(16,2) NOT NULL DEFAULT 0")
    op.execute("ALTER TABLE items ADD COLUMN IF NOT EXISTS note TEXT")
    op.execute("ALTER TABLE items DROP COLUMN IF EXISTS sector_id")
    op.execute("ALTER TABLE items DROP COLUMN IF EXISTS default_vendor_id")
    op.execute(
        "DO $$ BEGIN "
        "IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_items_vendor_id') THEN "
        "ALTER TABLE items ADD CONSTRAINT fk_items_vendor_id FOREIGN KEY (vendor_id) "
        "REFERENCES vendors(id) ON DELETE SET NULL; END IF; END $$;"
    )
    op.execute("CREATE INDEX IF NOT EXISTS ix_items_vendor_id ON items (vendor_id)")

    # --- goods_receipts ---
    op.execute("ALTER TABLE goods_receipts ADD COLUMN IF NOT EXISTS note TEXT")
    op.execute("ALTER TABLE goods_receipts DROP COLUMN IF EXISTS currency")
    op.execute("CREATE INDEX IF NOT EXISTS ix_goods_receipts_vendor_id ON goods_receipts (vendor_id)")

    # --- vendor_payments ---
    op.execute("ALTER TABLE vendor_payments ADD COLUMN IF NOT EXISTS receipt_id UUID")
    op.execute("ALTER TABLE vendor_payments DROP COLUMN IF EXISTS currency")
    op.execute(
        "DO $$ BEGIN "
        "IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_vendor_payments_receipt_id') THEN "
        "ALTER TABLE vendor_payments ADD CONSTRAINT fk_vendor_payments_receipt_id FOREIGN KEY (receipt_id) "
        "REFERENCES goods_receipts(id) ON DELETE SET NULL; END IF; END $$;"
    )

    # --- stock_movements ---
    op.execute("ALTER TABLE stock_movements ADD COLUMN IF NOT EXISTS created_by_id UUID")
    op.execute(
        "DO $$ BEGIN "
        "IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_stock_movements_created_by_id') THEN "
        "ALTER TABLE stock_movements ADD CONSTRAINT fk_stock_movements_created_by_id FOREIGN KEY (created_by_id) "
        "REFERENCES users(id) ON DELETE SET NULL; END IF; END $$;"
    )

    # --- supply_sectors jadvali olib tashlanadi ---
    op.execute("DROP TABLE IF EXISTS supply_sectors CASCADE")


def downgrade() -> None:
    # Sektor-asosli sxemaga qaytarish (ma'lumotsiz, faqat tuzilma).
    op.execute(
        "CREATE TABLE IF NOT EXISTS supply_sectors ("
        "id UUID PRIMARY KEY, name VARCHAR(50) UNIQUE NOT NULL, code VARCHAR(20) UNIQUE NOT NULL, "
        "responsible_user_id UUID, "
        "created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now())"
    )
    op.execute("ALTER TABLE items ADD COLUMN IF NOT EXISTS sector_id UUID")
    op.execute("ALTER TABLE items DROP COLUMN IF EXISTS vendor_id")
    op.execute("ALTER TABLE items DROP COLUMN IF EXISTS unit_price")
    op.execute("ALTER TABLE items DROP COLUMN IF EXISTS note")
    op.execute("ALTER TABLE vendors ADD COLUMN IF NOT EXISTS sector_id UUID")
    op.execute("ALTER TABLE vendors DROP COLUMN IF EXISTS user_id")
    op.execute("ALTER TABLE vendors DROP COLUMN IF EXISTS is_active")
    op.execute("ALTER TABLE goods_receipts ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'UZS'")
    op.execute("ALTER TABLE vendor_payments ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'UZS'")
    op.execute("ALTER TABLE vendor_payments DROP COLUMN IF EXISTS receipt_id")
