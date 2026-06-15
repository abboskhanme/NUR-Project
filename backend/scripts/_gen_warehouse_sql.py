"""Ombor ro'yxatidan import_warehouse.sql hosil qiladi (bir martalik generator).

Har qator: MODEL ... KVM ... "BUNKER O`NGA"/"BUNKER CHAP" ... 1 ... NARX ... ID

Yangi arxitektura: ombor turlari product_type='warehouse' (sotuvdan ajratilgan).
Bu generator:
  1) Har bir (model, kvm) uchun 'warehouse' mahsulot YARATADI (mavjud bo'lmasa).
  2) Birliklarni shu mahsulotlarga ulaydi.
Yo'nalish (O'NGA/CHAP) va aniq narx har birlikning `notes` ustuniga yoziladi.
Idempotent: takror ID qayta qo'shilmaydi (ON CONFLICT DO NOTHING), mahsulot ham
NOT EXISTS bilan himoyalangan.
"""

RAW = r"""
OPTIMA 2     200    BUNKER  O`NGA    1    2 299    68
OPTIMA 2     200    BUNKER  O`NGA    1    2 299    75
OPTIMA 2     200    BUNKER  O`NGA    1    2 299    64
OPTIMA 2     200    BUNKER CHAP    1    2 299    67
OPTIMA 1     300    BUNKER CHAP    1    2 299    85
26 MAGNUM    200    BUNKER  O`NGA    1    1 599    99
26 MAGNUM    200    BUNKER  O`NGA    1    1 599    89
25 MAGNUM    300    BUNKER  O`NGA    1    1 699    113
25 MAGNUM    400    BUNKER CHAP    1    1 899    47
25 MAGNUM    200    BUNKER  O`NGA    1    1 549    122
25 MAGNUM    300    BUNKER  O`NGA    1    1 699    127
25 MAGNUM    150    BUNKER  O`NGA    1    1 499    126
25 MAGNUM    150    BUNKER  O`NGA    1    1 499    121
25 MAGNUM    150    BUNKER  O`NGA    1    1 499    125
25 MAGNUM    300    BUNKER CHAP    1    1 699    136
ULTRA 26    150    BUNKER  O`NGA    1    1 499    70
ULTRA 25    300    BUNKER  O`NGA    1    1 549    55
ULTRA 25    300    BUNKER CHAP    1    1 549    101
ULTRA 25    150    BUNKER  O`NGA    1    1 349    94
ULTRA 25    150    BUNKER CHAP    1    1 349    93
ULTRA 25    150    BUNKER CHAP    1    1 349    110
ULTRA 25    200    BUNKER  O`NGA    1    1 399    102
ULTRA 25    200    BUNKER  O`NGA    1    1 499    109
ULTRA 25    200    BUNKER CHAP    1    1 499    108
ULTRA 25    150    BUNKER  O`NGA    1    1 449    111
ULTRA 25    150    BUNKER  O`NGA    1    1 349    120
ULTRA 25    150    BUNKER  O`NGA    1    1 449    114
ULTRA 25    300    BUNKER CHAP    1    1 549    112
ULTRA 25    200    BUNKER  O`NGA    1    1 399    117
ULTRA 25    150    BUNKER  O`NGA    1    1 449    115
ULTRA 25    300    BUNKER CHAP    1    1 549    124
ULTRA 25    300    BUNKER  O`NGA    1    1 549    119
ULTRA 25    300    BUNKER CHAP    1    1 549    118
ULTRA 25    200    BUNKER CHAP    1    1 399    123
ULTRA 25    200    BUNKER  O`NGA    1    1 499    129
ULTRA 25    300    BUNKER CHAP    1    1 699    134
ULTRA 25    200    BUNKER  O`NGA    1    1 399    130
ULTRA 25    300    BUNKER CHAP    1    1 549    139
PREMIUM 3. 25    300    BUNKER CHAP    1    1 399    140
PREMIUM 3. 25    200    BUNKER  O`NGA    1    1 299    138
PRO 25    200    BUNKER CHAP    1    1 329    135
PRO 25    200    BUNKER  O`NGA    1    1 329    142
PRO 2026    200    BUNKER  O`NGA    1    1 399    149
ULTRA 2026    200    BUNKER CHAP    1    1 499    153
MIR TEPLO    200    BUNKER CHAP    1    1 350    148
MIR TEPLO    200    BUNKER CHAP    1    1 350    146
MAGNUM 26    200    BUNKER CHAP    1    1 599    162
ULTRA 2026    150    BUNKER CHAP    1    1 499    161
ULTRA 25    300    BUNKER CHAP    1    1 699    152
ULTRA 2026    200    BUNKER CHAP    1    1 499    173
OPTIMA 1     200    BUNKER CHAP    1    2 299    182
OPTIMA 1     200    BUNKER CHAP    1    2 299    183
ULTRA 2026    200    BUNKER  O`NGA    1    1 499    186
ULTRA 2026    200    BUNKER CHAP    1    1 499    187
ULTRA 2026    200    BUNKER  O`NGA    1    1 499    191
ULTRA 2026    200    BUNKER CHAP    1    1 499    170
ULTRA 2026    300    BUNKER CHAP    1    1 599    202
MAGNUM 26    300    BUNKER  O`NGA    1    1 649    204
MAGNUM 26    300    BUNKER CHAP    1    1 649    200
ULTRA 2026    300    BUNKER CHAP    1    1 599    218
MAGNUM 26    300    BUNKER CHAP    1    1 649    221
OPTIMA 2     300    BUNKER  O`NGA    1    2 299    232
ULTRA 2026    150    BUNKER CHAP    1    1 499    246
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    247
ULTRA 2026    150    BUNKER CHAP    1    1 499    248
ULTRA 2026    150    BUNKER CHAP    1    1 499    240
ULTRA 2026    150    BUNKER CHAP    1    1 499    241
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    238
MAGNUM 26    150    BUNKER CHAP    1    1 559    239
MAGNUM 26    150    BUNKER  O`NGA    1    1 559    249
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    250
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    252
MAGNUM 26    150    BUNKER CHAP    1    1 559    257
MAGNUM 26    150    BUNKER CHAP    1    1 559    260
MAGNUM 26    150    BUNKER CHAP    1    1 559    265
MAGNUM 26    150    BUNKER CHAP    1    1 559    258
MAGNUM 26    150    BUNKER CHAP    1    1 559    273
MAGNUM 26    150    BUNKER CHAP    1    1 559    276
MAGNUM 26    150    BUNKER  O`NGA    1    1 559    259
ULTRA 2026    150    BUNKER CHAP    1    1 499    270
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    264
ULTRA 2026    150    BUNKER CHAP    1    1 499    269
ULTRA 2026    150    BUNKER CHAP    1    1 499    275
ULTRA 2026    150    BUNKER CHAP    1    1 499    277
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    274
PREMIUM 3    150    BUNKER  O`NGA    1    1 299    271
PREMIUM 3    150    BUNKER CHAP    1    1 299    272
PREMIUM 3    150    BUNKER CHAP    1    1 299    278
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    279
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    280
MAGNUM 26    150    BUNKER  O`NGA    1    1 559    284
MAGNUM 26    150    BUNKER  O`NGA    1    1 559    285
MAGNUM 26    150    BUNKER  O`NGA    1    1 559    287
OPTIMA    150    BUNKER  O`NGA    1    1 999    290
OPTIMA    150    BUNKER CHAP    1    1 999    286
OPTIMA    150    BUNKER  O`NGA    1    1 999    288
MAGNUM 26    150    BUNKER  O`NGA    1    1 559    281
MAGNUM 26    150    BUNKER  O`NGA    1    1 559    282
MAGNUM 26    150    BUNKER CHAP    1    1 559    283
MAGNUM 26    150    BUNKER CHAP    1    1 559    291
MAGNUM 26    150    BUNKER CHAP    1    1 559    289
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    261
ULTRA 2026    150    BUNKER CHAP    1    1 499    262
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    263
ULTRA 2026    150    BUNKER CHAP    1    1 499    267
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    266
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    268
ULTRA 2026    150    BUNKER  O`NGA    1    1 499    293
ULTRA 2026    150    BUNKER CHAP    1    1 499    294
MAGNUM 26    150    BUNKER CHAP    1    1 559    296
MAGNUM 26    150    BUNKER CHAP    1    1 559    297
MAGNUM 26    150    BUNKER CHAP    1    1 559    298
PREMIUM 3    150    BUNKER  O`NGA    1    1 299    299
PREMIUM 3    150    BUNKER CHAP    1    1 299    244
ULTRA    150    BUNKER  O`NGA    1    1 499    301
ULTRA    500    BUNKER  O`NGA    1    1 799    237
MAGNUM    500    BUNKER  O`NGA    1    2 199    303
OPTIMA    150    BUNKER CHAP    1    1 999    302
OPTIMA    150    BUNKER CHAP    1    1 999    254
MAGNUM 26    150    BUNKER  O`NGA    1    1 559    256
MAGNUM 26    500    BUNKER  O`NGA    1    2 199    305
MAGNUM 26    500    BUNKER  O`NGA    1    2 199    308
MAGNUM 26    200    BUNKER CHAP    1    1 599    314
MAGNUM 26    200    BUNKER CHAP    1    1 599    315
MAGNUM 26    200    BUNKER CHAP    1    1 599    316
MAGNUM 26    400    BUNKER  O`NGA    1    1 899    312
ULTRA 2026    200    BUNKER  O`NGA    1    1 499    320
ULTRA 2026    200    BUNKER  O`NGA    1    1 499    321
ULTRA 2026    200    BUNKER  O`NGA    1    1 499    324
ULTRA 2026    200    BUNKER CHAP    1    1 499    313
ULTRA 2026    200    BUNKER  O`NGA    1    1 499    322
ULTRA 2026    200    BUNKER  O`NGA    1    1 499    323
ULTRA 2026    500    BUNKER  O`NGA    1    1 799    234
ULTRA 2026    500    BUNKER  O`NGA    1    1 799    307
ULTRA 2026    400    BUNKER  O`NGA    1    1 749    311
MAGNUM 26    200    BUNKER  O`NGA    1    1 599    330
MAGNUM 26    200    BUNKER  O`NGA    1    1 599    333
MAGNUM 26    200    BUNKER  O`NGA    1    1 599    334
ULTRA 2026    200    BUNKER CHAP    1    1 499    336
ULTRA 2026    200    BUNKER CHAP    1    1 499    332
ULTRA 2026    200    BUNKER CHAP    1    1 499    335
MAGNUM 26    200    BUNKER  O`NGA    1    1 599    338
MAGNUM 26    200    BUNKER CHAP    1    1 599    339
MAGNUM 26    200    BUNKER  O`NGA    1    1 599    340
"""


def q(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def main():
    units = []           # (model, kvm, uid, direction, price)
    seen, dup = set(), []
    for line in RAW.strip().splitlines():
        line = line.strip()
        if not line or "BUNKER" not in line:
            continue
        before, after = line.split("BUNKER", 1)
        bt = before.split()
        kvm = int(bt[-1])
        model = " ".join(bt[:-1]).strip()
        at = after.split()
        direction = "O'NGA" if at[0].upper().startswith("O") else "CHAP"
        uid = at[-1].strip()
        # narx — qty(at[1]) dan keyingi, uid(at[-1]) gacha bo'lgan tokenlar ("2 299" -> 2299)
        price = int("".join(at[2:-1]) or "0")
        if uid in seen:
            dup.append(uid)
            continue
        seen.add(uid)
        units.append((model, kvm, uid, direction, price))

    # Aniq (model, kvm) turlari — narx birinchi uchragan qiymat
    types: dict[tuple[str, int], int] = {}
    for (m, k, _u, _d, pr) in units:
        types.setdefault((m, k), pr)

    type_rows = ",\n  ".join(f"({q(m)}, {k}, {pr})" for (m, k), pr in types.items())
    unit_rows = ",\n  ".join(
        f"({q(m)}, {k}, {q(u)}, {q('BUNKER ' + d + ' · $' + format(pr, ','))})"
        for (m, k, u, d, pr) in units
    )

    sql = f"""-- NUR ombor importi (avtomatik hosil qilingan — _gen_warehouse_sql.py)
-- {len(units)} ta kotyol, {len(types)} ta tur (model+kvm).
-- product_type='warehouse' (sotuvdan ajratilgan). Yangi turlarni YARATADI.
-- Yo'nalish + narx har birlikning `notes` ustuniga yoziladi.
-- Idempotent: takror ID qo'shilmaydi (ON CONFLICT DO NOTHING); tur NOT EXISTS bilan.
-- Ishlatish (lokal):
--   docker exec -i nur-postgres psql -U postgres -d nur_erp < backend/scripts/import_warehouse.sql

BEGIN;

-- 1) Ombor turlarini yaratish (model+kvm) — mavjud bo'lmasa
INSERT INTO products
  (id, product_type, model, kvm, base_price_usd, specs, status, created_at, updated_at)
SELECT gen_random_uuid(), 'warehouse', t.model, t.kvm, t.price, '{{}}'::jsonb, 'active', now(), now()
FROM (VALUES
  {type_rows}
) AS t(model, kvm, price)
WHERE NOT EXISTS (
  SELECT 1 FROM products p
  WHERE p.product_type = 'warehouse'
    AND lower(btrim(p.model)) = lower(btrim(t.model))
    AND p.kvm = t.kvm
);

-- 2) Birliklarni qo'shish
INSERT INTO inventory
  (id, product_id, unique_id, status, added_date, notes, created_at, updated_at)
SELECT gen_random_uuid(), p.id, v.uid, 'available', CURRENT_DATE, v.note, now(), now()
FROM (VALUES
  {unit_rows}
) AS v(model, kvm, uid, note)
JOIN products p
  ON p.product_type = 'warehouse'
 AND lower(btrim(p.model)) = lower(btrim(v.model))
 AND p.kvm = v.kvm
ON CONFLICT (unique_id) DO NOTHING;

COMMIT;

-- ====== Natija ======
SELECT 'turlar' AS nima, count(*) FROM products WHERE product_type='warehouse'
UNION ALL
SELECT 'birliklar', count(*) FROM inventory;
"""
    out = __file__.replace("_gen_warehouse_sql.py", "import_warehouse.sql")
    with open(out, "w") as f:
        f.write(sql)
    print(f"Yozildi: {out}  ({len(units)} kotyol, {len(types)} tur)")
    if dup:
        print(f"  Takror ID tashlandi: {dup}")
    print("  Turlar:")
    for (m, k), pr in sorted(types.items()):
        print(f"    {m} · {k} kvm  (${pr})")


if __name__ == "__main__":
    main()
