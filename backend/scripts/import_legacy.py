"""Eski NUR SAVDO bazasidan import — bir martalik, IDEMPOTENT skript.

Ishlatish (backend papkasidan yoki konteyner ichida):
    # 1) Dry-run (HECH NARSA yozilmaydi, faqat sonlarni ko'rsatadi):
    docker compose exec backend python -m scripts.import_legacy
    # 2) Haqiqiy yozish (jonli bazaga):
    docker compose exec backend python -m scripts.import_legacy --yes

Qarorlar (kelishilgan):
  - Mijozlar TELEFON bo'yicha upsert qilinadi (qayta ishga tushsa dublikat yaratmaydi).
  - Mahsulot YANGI yaratilmaydi. Buyurtma mavjud katalogga (model+kvm, keyin faqat
    model) bo'yicha moslashtiriladi. Mos kelmaganlar BITTA umumiy "Eski model (import)"
    mahsulotiga bog'lanadi; asl model nomi buyurtmaning additional_info'siga yoziladi.
  - Buyurtmalar legacy kod (masalan L-2505-0002) bo'yicha idempotent — mavjud bo'lsa
    o'tkazib yuboriladi.
  - Eski buyurtmalarga TO'LOV / MOLIYA yozuvi yaratilmaydi (exchange_rate=0).
  - Hammasi BITTA tranzaksiyada. --yes bo'lmasa rollback (dry-run).
"""
import asyncio
import json
import sys
from datetime import datetime
from decimal import Decimal
from pathlib import Path

from sqlalchemy import select

from app.db.session import AsyncSessionLocal
from app.models.customer import Customer
from app.models.order import Order, OrderItem, Payment
from app.models.product import Product

DATA = Path(__file__).parent / "legacy_data.json"
GENERIC_MODEL_NAME = "Eski model (import)"


def pdate(s):
    return datetime.strptime(s, "%Y-%m-%d").date() if s else None


def dec(v):
    return Decimal(str(v)) if v is not None else Decimal(0)


async def run(commit: bool) -> None:
    data = json.loads(DATA.read_text(encoding="utf-8"))
    customers = data["customers"]
    orders = data["orders"]
    stats = {
        "cust_created": 0, "cust_existing": 0,
        "ord_created": 0, "ord_skipped": 0,
        "matched": 0, "unmatched": 0, "generic_product_created": 0, "payments_paid": 0,
    }

    async with AsyncSessionLocal() as db:
        try:
            # --- mavjud katalog (asosiy mahsulotlar) ---
            res = await db.execute(select(Product).where(Product.product_type == "main"))
            by_model_kvm: dict = {}
            by_model: dict = {}
            for p in res.scalars().all():
                if p.model:
                    by_model.setdefault(p.model.strip().lower(), p)
                    if p.kvm:
                        by_model_kvm[(p.model.strip().lower(), int(p.kvm))] = p
            generic = by_model.get(GENERIC_MODEL_NAME.strip().lower())

            # --- mijozlar (telefon bo'yicha upsert) ---
            key_to_id: dict = {}
            for c in customers:
                phone = c["phone"] or c["key"]
                r = await db.execute(select(Customer).where(Customer.phone == phone))
                existing = r.scalar_one_or_none()
                if existing:
                    stats["cust_existing"] += 1
                    if not existing.phone2 and c.get("phone2"):
                        existing.phone2 = c["phone2"]
                    if not existing.region and c.get("region"):
                        existing.region = c["region"]
                    if not existing.address and c.get("address"):
                        existing.address = c["address"]
                    key_to_id[c["key"]] = existing.id
                else:
                    obj = Customer(
                        full_name=c["full_name"], phone=phone, phone2=c.get("phone2"),
                        country=c.get("country") or "Uzbekistan", region=c.get("region"),
                        city=c.get("city"), address=c.get("address"),
                        source="import", note=c.get("note"),
                    )
                    db.add(obj)
                    await db.flush()
                    key_to_id[c["key"]] = obj.id
                    stats["cust_created"] += 1

            # --- buyurtmalar (legacy kod bo'yicha idempotent) ---
            for o in orders:
                r = await db.execute(select(Order).where(Order.code == o["legacy_code"]))
                if r.scalar_one_or_none():
                    stats["ord_skipped"] += 1
                    continue

                model = (o["model_raw"] or "").strip().lower()
                kvm = o["kvm"]
                prod = None
                if model and kvm:
                    prod = by_model_kvm.get((model, int(kvm)))
                if not prod and model:
                    prod = by_model.get(model)

                add_info = o.get("additional_info")
                if prod:
                    stats["matched"] += 1
                else:
                    stats["unmatched"] += 1
                    if generic is None:
                        generic = Product(
                            product_type="main", model=GENERIC_MODEL_NAME,
                            name=GENERIC_MODEL_NAME, status="active",
                            base_price_usd=Decimal(0),
                        )
                        db.add(generic)
                        await db.flush()
                        by_model[GENERIC_MODEL_NAME.strip().lower()] = generic
                        stats["generic_product_created"] += 1
                    prod = generic
                    mtxt = f"Model (asl): {o['model_raw'] or '—'}"
                    if kvm:
                        mtxt += f", {kvm} kvm"
                    add_info = mtxt + (f" | {o['additional_info']}" if o.get("additional_info") else "")

                note_bits = []
                if o.get("deposit_uzs"):
                    note_bits.append(f"Zaklad: {o['deposit_uzs']:.0f} so'm")
                if o.get("balance_uzs"):
                    note_bits.append(f"Qoldiq: {o['balance_uzs']:.0f} so'm")
                note = "; ".join(note_bits) or None

                order = Order(
                    code=o["legacy_code"], customer_id=key_to_id[o["customer_key"]],
                    source="import", order_date=pdate(o["order_date"]),
                    delivered_at=pdate(o["delivered_at"]), status=o["status"],
                    area_m2=kvm, bunker_direction=o["bunker_direction"],
                    delivery_address=o.get("delivery_address"), exchange_rate=Decimal(0),
                    additional_info=add_info, note=note,
                )
                db.add(order)
                await db.flush()

                qty = o["quantity"] or 1
                total_uzs = dec(o.get("total_uzs"))
                paid_uzs = dec(o.get("paid_uzs"))
                db.add(OrderItem(
                    order_id=order.id, product_id=prod.id, quantity=qty,
                    bunker_direction=o["bunker_direction"],
                    unit_price_usd=dec(o.get("unit_price_usd")),
                    unit_price_uzs=(total_uzs / qty if qty else total_uzs),
                    discount_usd=Decimal(0), discount=Decimal(0), total_uzs=total_uzs,
                ))
                # To'lov: yetkazilgan -> to'liq to'langan; navbatda -> to'langan qismi (zaklad)
                if paid_uzs > 0:
                    pay_date = pdate(o["delivered_at"]) or pdate(o["order_date"])
                    pnote = ("Eski baza — yetkazilgan, to'liq to'langan"
                             if o["status"] == "delivered"
                             else "Eski baza — oldindan to'lov (zaklad)")
                    db.add(Payment(
                        order_id=order.id, date=pay_date, amount=paid_uzs,
                        currency="UZS", amount_uzs_equiv=paid_uzs, method="cash",
                        note=pnote,
                    ))
                    stats["payments_paid"] += 1
                stats["ord_created"] += 1

            if commit:
                await db.commit()
                print("\n[OK] COMMIT — ma'lumot jonli bazaga yozildi.")
            else:
                await db.rollback()
                print("\n[DRY-RUN] Hech narsa yozilmadi. Yozish uchun: --yes")
        except Exception as exc:  # noqa: BLE001
            await db.rollback()
            print(f"\n[XATO] Rollback qilindi — hech narsa yozilmadi: {exc}")
            raise

    print(json.dumps(stats, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    asyncio.run(run(commit="--yes" in sys.argv))
