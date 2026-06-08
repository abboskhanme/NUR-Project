-- NUR SAVDO eski baza -> faqat SOTUV importi (620 yetkazilgan, navbatga tushmaydi)
-- SHART: avval import_customers.sql ishga tushgan bo'lsin (mijozlar mavjud bo'lsin).
-- Lokal:  docker compose exec -T postgres psql -U postgres -d nur_erp < backend/scripts/import_orders.sql
-- Server: docker compose -f docker-compose.prod.yml exec -T postgres psql -U postgres -d nur_erp < backend/scripts/import_orders.sql
-- DRY-RUN: oxiridagi COMMIT; ni ROLLBACK; ga o'zgartiring.
\set ON_ERROR_STOP on
BEGIN;

-- Umumiy 'Eski model' mahsuloti (faqat agar yo'q bo'lsa)
INSERT INTO products (id, product_type, model, name, status, base_price_usd)
SELECT gen_random_uuid(), 'main', 'Eski model (import)', 'Eski model (import)', 'active', 0
WHERE NOT EXISTS (SELECT 1 FROM products WHERE product_type='main' AND model='Eski model (import)');

-- Buyurtmalar (hammasi 'delivered' = SOTUV) + item + to'liq to'lov
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0002', (SELECT id FROM customers WHERE phone='+998 93 788 03 06' LIMIT 1), 'import', '2025-05-03'::date, '2025-05-15'::date, 'delivered', 0, 200, NULL, 'Namangan norin', 0, 'Model (asl): BUNKER 4, 200 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 788 03 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (10387000.0)/1, 0, 0, 10387000.0
FROM orders o WHERE o.code='L-2505-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-05-15'::date, 10387000.0, 'UZS', 10387000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0003', (SELECT id FROM customers WHERE phone='+998 94 056 35 66' LIMIT 1), 'import', '2025-05-08'::date, '2025-05-24'::date, 'delivered', 0, 750, NULL, 'TOSHKENT SHAXAR', 0, 'Model (asl): ODDIY, 750 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 056 35 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ODDIY') AND kvm=750 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ODDIY') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1400, (9000000.0)/1, 0, 0, 9000000.0
FROM orders o WHERE o.code='L-2505-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-05-24'::date, 9000000.0, 'UZS', 9000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0004', (SELECT id FROM customers WHERE phone='+998 91 916 66 66' LIMIT 1), 'import', '2025-05-09'::date, '2025-08-01'::date, 'delivered', 0, 200, NULL, 'Namangan shaxar', 0, 'Model (asl): BUNKER 4, 200 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 916 66 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (1278000.0)/1, 0, 0, 1278000.0
FROM orders o WHERE o.code='L-2505-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-01'::date, 1278000.0, 'UZS', 1278000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0005', (SELECT id FROM customers WHERE phone='+998 33 007 00 91' LIMIT 1), 'import', '2025-05-11'::date, '2025-05-26'::date, 'delivered', 0, 200, NULL, 'O''ZBEKISTON TUMANI', 0, 'Model (asl): BUNKER ARSTON, 200 kvm | WiFi ARSTON', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 007 00 91')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ARSTON') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ARSTON') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1415, (2860000.0)/1, 0, 0, 2860000.0
FROM orders o WHERE o.code='L-2505-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-05-26'::date, 2860000.0, 'UZS', 2860000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0006', (SELECT id FROM customers WHERE phone='+998 91 683 83 75' LIMIT 1), 'import', '2025-05-13'::date, '2025-06-04'::date, 'delivered', 0, 300, NULL, 'Uchkuprik tumani', 0, 'Model (asl): BUNKER 4, 300 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 683 83 75')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (500000.0)/1, 0, 0, 500000.0
FROM orders o WHERE o.code='L-2505-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-06-04'::date, 500000.0, 'UZS', 500000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0007', (SELECT id FROM customers WHERE phone='+998 94 025 10 08' LIMIT 1), 'import', '2025-05-13'::date, '2025-06-07'::date, 'delivered', 0, 150, NULL, 'SURXANDARYO MUZRABOT', 0, 'Model (asl): BUNKER 4, 150 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 025 10 08')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (12987000.0)/1, 0, 0, 12987000.0
FROM orders o WHERE o.code='L-2505-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-06-07'::date, 12987000.0, 'UZS', 12987000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0008', (SELECT id FROM customers WHERE phone='+998 97 693 83 93' LIMIT 1), 'import', '2025-05-22'::date, '2025-06-15'::date, 'delivered', 0, 150, NULL, 'DANGARA MULK OBOD', 0, 'Model (asl): BUNKER 2, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 693 83 93')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 2') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 2') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 880, (3640000.0)/1, 0, 0, 3640000.0
FROM orders o WHERE o.code='L-2505-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-06-15'::date, 3640000.0, 'UZS', 3640000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0009', (SELECT id FROM customers WHERE phone='+998 91 284 34 35' LIMIT 1), 'import', '2025-05-22'::date, '2025-08-01'::date, 'delivered', 0, 200, NULL, 'FARGONA QUVA', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 284 34 35')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1090, (15370000.0)/1, 0, 0, 15370000.0
FROM orders o WHERE o.code='L-2505-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-01'::date, 15370000.0, 'UZS', 15370000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0010', (SELECT id FROM customers WHERE phone='+998 50 300 17 66' LIMIT 1), 'import', '2025-05-23'::date, '2025-06-21'::date, 'delivered', 0, 200, NULL, 'Namangan uychi', 0, 'Model (asl): BUNKER 2, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 300 17 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 2') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 2') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (8019023.0)/1, 0, 0, 8019023.0
FROM orders o WHERE o.code='L-2505-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-06-21'::date, 8019023.0, 'UZS', 8019023.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0011', (SELECT id FROM customers WHERE phone='+998 91 050 08 51' LIMIT 1), 'import', '2025-05-25'::date, '2025-08-03'::date, 'delivered', 0, 400, NULL, 'Namangan NUROBOT', 0, 'Model (asl): ODDIY 1, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 050 08 51')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ODDIY 1') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ODDIY 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 899, (10387000.0)/1, 0, 0, 10387000.0
FROM orders o WHERE o.code='L-2505-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-03'::date, 10387000.0, 'UZS', 10387000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0012', (SELECT id FROM customers WHERE phone='+998 88 991 78 77' LIMIT 1), 'import', '2025-05-25'::date, '2025-09-25'::date, 'delivered', 0, 200, NULL, 'Andijon shaxrixon tumani', 0, 'Model (asl): BUNKER 4, 200 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 991 78 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13937000.0)/1, 0, 0, 13937000.0
FROM orders o WHERE o.code='L-2505-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-25'::date, 13937000.0, 'UZS', 13937000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0013', (SELECT id FROM customers WHERE phone='+998 88 991 78 77' LIMIT 1), 'import', '2025-05-25'::date, '2025-09-25'::date, 'delivered', 0, 150, NULL, 'Andijon shaxrixon tumani', 0, 'Model (asl): BUNKER 4, 150 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 991 78 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 949, (11337000.0)/1, 0, 0, 11337000.0
FROM orders o WHERE o.code='L-2505-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-25'::date, 11337000.0, 'UZS', 11337000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0014', (SELECT id FROM customers WHERE phone='+998 88 991 78 77' LIMIT 1), 'import', '2025-05-25'::date, '2025-09-25'::date, 'delivered', 0, 150, NULL, 'Andijon shaxrixon tumani', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 991 78 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 849, (10037000.0)/1, 0, 0, 10037000.0
FROM orders o WHERE o.code='L-2505-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-25'::date, 10037000.0, 'UZS', 10037000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0016', (SELECT id FROM customers WHERE phone='+998 99 066 33 00' LIMIT 1), 'import', '2025-05-25'::date, '2025-11-20'::date, 'delivered', 0, 300, NULL, 'YANGI NAMANGAN TUMAN SOHIL', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 066 33 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13637000.0)/1, 0, 0, 13637000.0
FROM orders o WHERE o.code='L-2505-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-20'::date, 13637000.0, 'UZS', 13637000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0017', (SELECT id FROM customers WHERE phone='+998 97 121 91 00' LIMIT 1), 'import', '2025-05-26'::date, '2025-07-31'::date, 'delivered', 0, 200, NULL, 'DANGARA SHIVOQ', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 121 91 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1090, (13017000.0)/1, 0, 0, 13017000.0
FROM orders o WHERE o.code='L-2505-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-31'::date, 13017000.0, 'UZS', 13017000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0018', (SELECT id FROM customers WHERE phone='+998 91 205 45 17' LIMIT 1), 'import', '2025-05-27'::date, '2025-07-23'::date, 'delivered', 0, 400, NULL, 'UCH KO`PRIK', 0, 'Model (asl): BUNKER 3, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 205 45 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1360, (15105000.0)/1, 0, 0, 15105000.0
FROM orders o WHERE o.code='L-2505-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-23'::date, 15105000.0, 'UZS', 15105000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0019', (SELECT id FROM customers WHERE phone='+998 99 933 19 93' LIMIT 1), 'import', '2025-05-28'::date, '2025-06-12'::date, 'delivered', 0, 200, NULL, 'NAMANGAN Norin', 0, 'Model (asl): BUNKER 3, 200 kvm | IAMAHOD DUM', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 933 19 93')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0019');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 0, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2505-0019' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0020', (SELECT id FROM customers WHERE phone='+385 955462622' LIMIT 1), 'import', '2025-05-28'::date, '2025-07-05'::date, 'delivered', 0, 300, NULL, 'BUXORO peshku', 0, 'Model (asl): BUNKER 4, 300 kvm | 4 lik', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+385 955462622')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1250, (16250000.0)/1, 0, 0, 16250000.0
FROM orders o WHERE o.code='L-2505-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-05'::date, 16250000.0, 'UZS', 16250000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0021', (SELECT id FROM customers WHERE phone='+998 90 835 29 38' LIMIT 1), 'import', '2025-05-29'::date, '2025-07-20'::date, 'delivered', 0, 200, NULL, 'QO`SHTEPA TUMANI', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 835 29 38')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1085, (10205000.0)/1, 0, 0, 10205000.0
FROM orders o WHERE o.code='L-2505-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-20'::date, 10205000.0, 'UZS', 10205000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0022', (SELECT id FROM customers WHERE phone='+998 97 208 84 83' LIMIT 1), 'import', '2025-05-29'::date, '2025-07-23'::date, 'delivered', 0, 200, NULL, 'QO`SHTEPA TUMANI', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 208 84 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1085, (10205000.0)/1, 0, 0, 10205000.0
FROM orders o WHERE o.code='L-2505-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-23'::date, 10205000.0, 'UZS', 10205000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0023', (SELECT id FROM customers WHERE phone='+998 90 780 46 56' LIMIT 1), 'import', '2025-05-29'::date, '2025-07-23'::date, 'delivered', 0, 200, NULL, 'QO`SHTEPA TUMANI', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAPGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 780 46 56')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1085, (10205000.0)/1, 0, 0, 10205000.0
FROM orders o WHERE o.code='L-2505-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-23'::date, 10205000.0, 'UZS', 10205000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0023' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0024', (SELECT id FROM customers WHERE phone='+998 90 600 13 60' LIMIT 1), 'import', '2025-05-29'::date, '2025-06-29'::date, 'delivered', 0, 300, NULL, 'SAMARQAND SHAXAR TURKSITON', 0, 'Model (asl): BUNKER 2, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 600 13 60')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0024');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 2') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 2') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1099, (11687000.0)/1, 0, 0, 11687000.0
FROM orders o WHERE o.code='L-2505-0024' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-06-29'::date, 11687000.0, 'UZS', 11687000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0024' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2505-0025', (SELECT id FROM customers WHERE phone='+998 90 530 41 51' LIMIT 1), 'import', '2025-05-30'::date, '2025-10-07'::date, 'delivered', 0, 200, NULL, 'QUVA TUMANI', 0, 'Model (asl): BUNKER 4, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 530 41 51')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2505-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (3587000.0)/1, 0, 0, 3587000.0
FROM orders o WHERE o.code='L-2505-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-07'::date, 3587000.0, 'UZS', 3587000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2505-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0002', (SELECT id FROM customers WHERE phone='+998 90 711 60 50' LIMIT 1), 'import', '2025-06-01'::date, '2025-06-28'::date, 'delivered', 0, 150, NULL, 'O''ZBEKISTON tumani', 0, 'Model (asl): BUNKER 4, 150 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 711 60 50')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1099, (10387000.0)/1, 0, 0, 10387000.0
FROM orders o WHERE o.code='L-2506-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-06-28'::date, 10387000.0, 'UZS', 10387000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0003', (SELECT id FROM customers WHERE phone='+998 90 251 08 88' LIMIT 1), 'import', '2025-06-03'::date, '2025-06-17'::date, 'delivered', 0, 300, NULL, 'ANDIJON ISBOSGAN', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (12005000.0)/1, 0, 0, 12005000.0
FROM orders o WHERE o.code='L-2506-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-06-17'::date, 12005000.0, 'UZS', 12005000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0004', (SELECT id FROM customers WHERE phone='+998 90 197 77 73' LIMIT 1), 'import', '2025-06-03'::date, '2025-06-29'::date, 'delivered', 0, 200, NULL, 'SAMARQAND URGUT', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 197 77 73')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12937000.0)/1, 0, 0, 12937000.0
FROM orders o WHERE o.code='L-2506-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-06-29'::date, 12937000.0, 'UZS', 12937000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0005', (SELECT id FROM customers WHERE phone='+7 905 113 28 22' LIMIT 1), 'import', '2025-06-04'::date, '2025-08-02'::date, 'delivered', 0, 200, NULL, 'KOSONSOY', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+7 905 113 28 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (11937000.0)/1, 0, 0, 11937000.0
FROM orders o WHERE o.code='L-2506-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-02'::date, 11937000.0, 'UZS', 11937000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0006', (SELECT id FROM customers WHERE phone='+998 94 301 64 10' LIMIT 1), 'import', '2025-06-04'::date, '2025-08-05'::date, 'delivered', 0, 300, NULL, 'KOSONSOY', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 301 64 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (13237000.0)/1, 0, 0, 13237000.0
FROM orders o WHERE o.code='L-2506-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-05'::date, 13237000.0, 'UZS', 13237000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0007', (SELECT id FROM customers WHERE phone='+998 95 007 92 85' LIMIT 1), 'import', '2025-06-04'::date, '2025-07-03'::date, 'delivered', 0, 200, NULL, 'ANDIJON BULOQ BOSHI', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 007 92 85')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13734000.0)/1, 0, 0, 13734000.0
FROM orders o WHERE o.code='L-2506-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-03'::date, 13734000.0, 'UZS', 13734000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0008', (SELECT id FROM customers WHERE phone='+998 33 051 55 30' LIMIT 1), 'import', '2025-06-04'::date, '2025-09-23'::date, 'delivered', 0, 200, NULL, 'BUVAYDA TUMANI', 0, 'Model (asl): BUNKER PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 051 55 30')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (12905000.0)/1, 0, 0, 12905000.0
FROM orders o WHERE o.code='L-2506-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-23'::date, 12905000.0, 'UZS', 12905000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0009', (SELECT id FROM customers WHERE phone='+998 88 965 72 22' LIMIT 1), 'import', '2025-06-04'::date, '2025-10-20'::date, 'delivered', 0, 150, NULL, 'BUVAYDA TUMANI', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 965 72 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (10307000.0)/1, 0, 0, 10307000.0
FROM orders o WHERE o.code='L-2506-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-20'::date, 10307000.0, 'UZS', 10307000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0010', (SELECT id FROM customers WHERE phone='+998 90 627 16 71' LIMIT 1), 'import', '2025-06-04'::date, '2025-07-09'::date, 'delivered', 0, 300, NULL, 'BUXORO ARABXONA', 0, 'Model (asl): BUNKER 3, 300 kvm | ARSTON', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 627 16 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1380, (15242000.0)/1, 0, 0, 15242000.0
FROM orders o WHERE o.code='L-2506-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-09'::date, 15242000.0, 'UZS', 15242000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0011', (SELECT id FROM customers WHERE phone='+998 91 665 49 92' LIMIT 1), 'import', '2025-06-04'::date, '2025-07-01'::date, 'delivered', 0, 150, NULL, 'OLTIARIG` TUMANI', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 665 49 92')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (9047000.0)/1, 0, 0, 9047000.0
FROM orders o WHERE o.code='L-2506-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-01'::date, 9047000.0, 'UZS', 9047000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0012', (SELECT id FROM customers WHERE phone='+998 95 159 54 53' LIMIT 1), 'import', '2025-06-05'::date, '2025-07-26'::date, 'delivered', 0, 200, NULL, 'FARG`ONA OQ BILOL', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 159 54 53')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (11067000.0)/1, 0, 0, 11067000.0
FROM orders o WHERE o.code='L-2506-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-26'::date, 11067000.0, 'UZS', 11067000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0013', (SELECT id FROM customers WHERE phone='+998 99 994 93 23' LIMIT 1), 'import', '2025-06-05'::date, '2025-07-12'::date, 'delivered', 0, 200, NULL, 'uchkuprik kenagaz', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 994 93 23')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (10952000.0)/1, 0, 0, 10952000.0
FROM orders o WHERE o.code='L-2506-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-12'::date, 10952000.0, 'UZS', 10952000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0014', (SELECT id FROM customers WHERE phone='+998 91 147 00 95' LIMIT 1), 'import', '2025-06-05'::date, '2025-07-28'::date, 'delivered', 0, 400, NULL, 'BOG`DOD NURAFSHON', 0, 'Model (asl): BUNKER 3, 400 kvm | YUPES', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 147 00 95')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 2339, (14807000.0)/1, 0, 0, 14807000.0
FROM orders o WHERE o.code='L-2506-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-28'::date, 14807000.0, 'UZS', 14807000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0015', (SELECT id FROM customers WHERE phone='+998 93 900 88 82' LIMIT 1), 'import', '2025-06-06'::date, '2025-07-28'::date, 'delivered', 0, 200, NULL, 'Namangan turagurgon', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 900 88 82')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1100, (10390000.0)/1, 0, 0, 10390000.0
FROM orders o WHERE o.code='L-2506-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-28'::date, 10390000.0, 'UZS', 10390000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0016', (SELECT id FROM customers WHERE phone='+998 95 233 77 24' LIMIT 1), 'import', '2025-06-06'::date, '2025-07-19'::date, 'delivered', 0, 200, NULL, 'Andijon baliqchi', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 233 77 24')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (10932000.0)/1, 0, 0, 10932000.0
FROM orders o WHERE o.code='L-2506-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-19'::date, 10932000.0, 'UZS', 10932000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0048', (SELECT id FROM customers WHERE phone='+998 90 290 00 17' LIMIT 1), 'import', '2025-06-07'::date, '2025-11-20'::date, 'delivered', 0, 300, NULL, 'MARG`ILON BESHKAPA', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 290 00 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0048');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (12242000.0)/1, 0, 0, 12242000.0
FROM orders o WHERE o.code='L-2506-0048' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-20'::date, 12242000.0, 'UZS', 12242000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0048' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0049', (SELECT id FROM customers WHERE phone='+998 93 044 03 62' LIMIT 1), 'import', '2025-06-09'::date, '2025-08-10'::date, 'delivered', 0, 300, NULL, 'BESHARIQ TUMANI', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 044 03 62')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0049');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 0, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2506-0049' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0050', (SELECT id FROM customers WHERE phone='+998 88 794 72 00' LIMIT 1), 'import', '2025-06-10'::date, '2025-07-06'::date, 'delivered', 0, 200, NULL, 'SURXANDARYO', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 794 72 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0050');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12477400.0)/1, 0, 0, 12477400.0
FROM orders o WHERE o.code='L-2506-0050' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-06'::date, 12477400.0, 'UZS', 12477400.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0050' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0051', (SELECT id FROM customers WHERE phone='+998 97 626 66 09' LIMIT 1), 'import', '2025-06-10'::date, '2025-09-22'::date, 'delivered', 0, 400, NULL, 'NAMANGAN', 0, 'Model (asl): BUNKER 3, 400 kvm | Ariston', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 626 66 09')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0051');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1479, (13832000.0)/1, 0, 0, 13832000.0
FROM orders o WHERE o.code='L-2506-0051' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-22'::date, 13832000.0, 'UZS', 13832000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0051' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0052', (SELECT id FROM customers WHERE phone='+998 95 368 83 35' LIMIT 1), 'import', '2025-06-10'::date, '2025-09-08'::date, 'delivered', 0, 300, NULL, 'KOSONSOY', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 368 83 35')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0052');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1389, (11597000.0)/1, 0, 0, 11597000.0
FROM orders o WHERE o.code='L-2506-0052' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-08'::date, 11597000.0, 'UZS', 11597000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0052' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0053', (SELECT id FROM customers WHERE phone='+998 91 124 78 77' LIMIT 1), 'import', '2025-06-11'::date, '2025-07-21'::date, 'delivered', 0, 150, NULL, 'MARG`ILON', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 124 78 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0053');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (10587000.0)/1, 0, 0, 10587000.0
FROM orders o WHERE o.code='L-2506-0053' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-21'::date, 10587000.0, 'UZS', 10587000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0053' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0054', (SELECT id FROM customers WHERE phone='+998 88 737 03 13' LIMIT 1), 'import', '2025-06-11'::date, '2025-07-03'::date, 'delivered', 0, 200, NULL, 'ANDIJON', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 737 03 13')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0054');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12647000.0)/1, 0, 0, 12647000.0
FROM orders o WHERE o.code='L-2506-0054' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-03'::date, 12647000.0, 'UZS', 12647000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0054' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0055', (SELECT id FROM customers WHERE phone='+998 88 238 32 97' LIMIT 1), 'import', '2025-06-11'::date, '2025-07-13'::date, 'delivered', 0, 150, NULL, 'бухоро карвон', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 238 32 97')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0055');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (11657000.0)/1, 0, 0, 11657000.0
FROM orders o WHERE o.code='L-2506-0055' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-13'::date, 11657000.0, 'UZS', 11657000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0055' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0056', (SELECT id FROM customers WHERE phone='+998 77 101 55 93' LIMIT 1), 'import', '2025-06-12'::date, '2025-07-22'::date, 'delivered', 0, 150, NULL, 'BUXORO PESHKO', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 101 55 93')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0056');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (11587400.0)/1, 0, 0, 11587400.0
FROM orders o WHERE o.code='L-2506-0056' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-22'::date, 11587400.0, 'UZS', 11587400.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0056' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0057', (SELECT id FROM customers WHERE phone='+998 99 054 83 93' LIMIT 1), 'import', '2025-06-12'::date, '2025-08-21'::date, 'delivered', 0, 200, NULL, 'XORAZIM SHOVOT', 0, 'Model (asl): BUNKER 3, 200 kvm | Ariston 32 L', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 054 83 93')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0057');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1279, (13871000.0)/1, 0, 0, 13871000.0
FROM orders o WHERE o.code='L-2506-0057' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-21'::date, 13871000.0, 'UZS', 13871000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0057' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0058', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2025-06-12'::date, '2025-07-14'::date, 'delivered', 0, 200, NULL, 'SAMARQAND URGUT', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0058');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13534000.0)/1, 0, 0, 13534000.0
FROM orders o WHERE o.code='L-2506-0058' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-14'::date, 13534000.0, 'UZS', 13534000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0058' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0059', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2025-06-12'::date, '2025-07-14'::date, 'delivered', 0, 300, NULL, 'SAMARQAND URGUT', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0059');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14167000.0)/1, 0, 0, 14167000.0
FROM orders o WHERE o.code='L-2506-0059' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-14'::date, 14167000.0, 'UZS', 14167000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0059' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0060', (SELECT id FROM customers WHERE phone='+998 90 869 17 08' LIMIT 1), 'import', '2025-06-17'::date, '2025-08-07'::date, 'delivered', 0, 200, NULL, 'QASHQADARYO KITOB', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 869 17 08')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0060');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12672000.0)/1, 0, 0, 12672000.0
FROM orders o WHERE o.code='L-2506-0060' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-07'::date, 12672000.0, 'UZS', 12672000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0060' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0061', (SELECT id FROM customers WHERE phone='+998 94 506 30 31' LIMIT 1), 'import', '2025-06-17'::date, '2025-07-21'::date, 'delivered', 0, 300, NULL, 'NAMANGAN UCHQURGON', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 506 30 31')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0061');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12311000.0)/1, 0, 0, 12311000.0
FROM orders o WHERE o.code='L-2506-0061' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-21'::date, 12311000.0, 'UZS', 12311000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0061' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0062', (SELECT id FROM customers WHERE phone='+998 93 335 93 16' LIMIT 1), 'import', '2025-06-18'::date, '2025-08-11'::date, 'delivered', 0, 300, NULL, 'Samarqand', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 335 93 16')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0062');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13287000.0)/1, 0, 0, 13287000.0
FROM orders o WHERE o.code='L-2506-0062' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-11'::date, 13287000.0, 'UZS', 13287000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0062' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0063', (SELECT id FROM customers WHERE phone='+998 93 335 93 16' LIMIT 1), 'import', '2025-06-18'::date, '2025-08-11'::date, 'delivered', 0, 300, NULL, 'Samarqand', 0, 'Model (asl): BUNKER 4, 300 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 335 93 16')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0063');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (14562000.0)/1, 0, 0, 14562000.0
FROM orders o WHERE o.code='L-2506-0063' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-11'::date, 14562000.0, 'UZS', 14562000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0063' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0064', (SELECT id FROM customers WHERE phone='+998 99 575 93 74' LIMIT 1), 'import', '2025-06-18'::date, '2025-10-13'::date, 'delivered', 0, 300, NULL, 'Qoraqlpogiston', 0, 'Model (asl): BUNKER 4, 300 kvm | Wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 575 93 74')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0064');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (12132000.0)/1, 0, 0, 12132000.0
FROM orders o WHERE o.code='L-2506-0064' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-13'::date, 12132000.0, 'UZS', 12132000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0064' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0065', (SELECT id FROM customers WHERE phone='+998 91 940 09 92' LIMIT 1), 'import', '2025-06-18'::date, '2025-07-30'::date, 'delivered', 0, 150, NULL, 'jizzax zarbdor tumani', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 940 09 92')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0065');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2506-0065' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0066', (SELECT id FROM customers WHERE phone='+998 99 999 89 41' LIMIT 1), 'import', '2025-06-19'::date, '2025-08-06'::date, 'delivered', 0, 200, NULL, 'Buxoro karvon b', 0, 'Model (asl): BUNKER 4, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 999 89 41')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0066');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (16458000.0)/1, 0, 0, 16458000.0
FROM orders o WHERE o.code='L-2506-0066' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-06'::date, 16458000.0, 'UZS', 16458000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0066' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0067', (SELECT id FROM customers WHERE phone='+998 91 436 66 69' LIMIT 1), 'import', '2025-06-20'::date, '2025-07-20'::date, 'delivered', 0, 300, NULL, 'XIVA SHAHAR', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 436 66 69')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0067');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12227000.0)/1, 0, 0, 12227000.0
FROM orders o WHERE o.code='L-2506-0067' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-20'::date, 12227000.0, 'UZS', 12227000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0067' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0068', (SELECT id FROM customers WHERE phone='+998 93 588 59 88' LIMIT 1), 'import', '2025-06-21'::date, '2025-09-02'::date, 'delivered', 0, 300, NULL, 'SURXANDARYO TERMIZ', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 588 59 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0068');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (11976000.0)/1, 0, 0, 11976000.0
FROM orders o WHERE o.code='L-2506-0068' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-02'::date, 11976000.0, 'UZS', 11976000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0068' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0069', (SELECT id FROM customers WHERE phone='+998 93 588 59 88' LIMIT 1), 'import', '2025-06-21'::date, '2025-09-02'::date, 'delivered', 0, 400, NULL, 'SURXANDARYO TERMIZ', 0, 'Model (asl): BUNKER 3, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 588 59 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0069');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (13238000.0)/1, 0, 0, 13238000.0
FROM orders o WHERE o.code='L-2506-0069' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-02'::date, 13238000.0, 'UZS', 13238000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0069' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0070', (SELECT id FROM customers WHERE phone='+998 99 679 52 78' LIMIT 1), 'import', '2025-06-21'::date, '2025-09-02'::date, 'delivered', 0, 150, NULL, 'SURXANDARYO TERMIZ', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 679 52 78')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0070');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (10714000.0)/1, 0, 0, 10714000.0
FROM orders o WHERE o.code='L-2506-0070' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-02'::date, 10714000.0, 'UZS', 10714000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0070' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0071', (SELECT id FROM customers WHERE phone='+998 93 588 59 88' LIMIT 1), 'import', '2025-06-21'::date, '2025-09-02'::date, 'delivered', 0, 150, NULL, 'SURXANDARYO TERMIZ', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 588 59 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0071');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (10714000.0)/1, 0, 0, 10714000.0
FROM orders o WHERE o.code='L-2506-0071' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-02'::date, 10714000.0, 'UZS', 10714000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0071' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0072', (SELECT id FROM customers WHERE phone='+998 97 975 00 06' LIMIT 1), 'import', '2025-06-21'::date, '2025-08-16'::date, 'delivered', 0, 150, NULL, 'ANDIJON v andijon t', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 975 00 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0072');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (13269000.0)/1, 0, 0, 13269000.0
FROM orders o WHERE o.code='L-2506-0072' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-16'::date, 13269000.0, 'UZS', 13269000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0072' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0073', (SELECT id FROM customers WHERE phone='+998 88 133 86 83' LIMIT 1), 'import', '2025-06-24'::date, '2025-07-25'::date, 'delivered', 0, 200, NULL, 'namangan turaqurgon', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 133 86 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0073');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (8737000.0)/1, 0, 0, 8737000.0
FROM orders o WHERE o.code='L-2506-0073' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-25'::date, 8737000.0, 'UZS', 8737000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0073' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0074', (SELECT id FROM customers WHERE phone='+998 93 410 15 10' LIMIT 1), 'import', '2025-06-25'::date, '2025-07-14'::date, 'delivered', 0, 300, NULL, 'ANDIJON ASAKA', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 410 15 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0074');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (12034000.0)/1, 0, 0, 12034000.0
FROM orders o WHERE o.code='L-2506-0074' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-14'::date, 12034000.0, 'UZS', 12034000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0074' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0075', (SELECT id FROM customers WHERE phone='+998 90 531 18 48' LIMIT 1), 'import', '2025-06-26'::date, '2025-07-29'::date, 'delivered', 0, 200, NULL, 'Qoshtepa tumani', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 531 18 48')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0075');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12454000.0)/1, 0, 0, 12454000.0
FROM orders o WHERE o.code='L-2506-0075' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-29'::date, 12454000.0, 'UZS', 12454000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0075' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0076', (SELECT id FROM customers WHERE phone='+998 90 277 71 32' LIMIT 1), 'import', '2025-06-27'::date, '2025-09-20'::date, 'delivered', 0, 300, NULL, 'Margilon', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 277 71 32')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0076');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12587000.0)/1, 0, 0, 12587000.0
FROM orders o WHERE o.code='L-2506-0076' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-20'::date, 12587000.0, 'UZS', 12587000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0076' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0077', (SELECT id FROM customers WHERE phone='+998 90 151 52 60' LIMIT 1), 'import', '2025-06-27'::date, '2025-08-13'::date, 'delivered', 0, 200, NULL, 'Furqat t', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 151 52 60')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0077');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12477000.0)/1, 0, 0, 12477000.0
FROM orders o WHERE o.code='L-2506-0077' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-13'::date, 12477000.0, 'UZS', 12477000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0077' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0078', (SELECT id FROM customers WHERE phone='+998 90 614 38 88' LIMIT 1), 'import', '2025-06-27'::date, '2025-08-23'::date, 'delivered', 0, 300, NULL, 'buxoro sh', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 614 38 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0078');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12587000.0)/1, 0, 0, 12587000.0
FROM orders o WHERE o.code='L-2506-0078' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-23'::date, 12587000.0, 'UZS', 12587000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0078' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0079', (SELECT id FROM customers WHERE phone='+998 90 277 06 95' LIMIT 1), 'import', '2025-06-27'::date, '2025-07-25'::date, 'delivered', 0, 300, NULL, 'Margilon', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 277 06 95')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0079');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1145, (12209000.0)/1, 0, 0, 12209000.0
FROM orders o WHERE o.code='L-2506-0079' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-25'::date, 12209000.0, 'UZS', 12209000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0079' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0080', (SELECT id FROM customers WHERE phone='+998 94 780 31 80' LIMIT 1), 'import', '2025-06-27'::date, '2025-09-03'::date, 'delivered', 0, 200, NULL, 'buxoro sh', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 780 31 80')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0080');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13622000.0)/1, 0, 0, 13622000.0
FROM orders o WHERE o.code='L-2506-0080' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-03'::date, 13622000.0, 'UZS', 13622000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0080' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0081', (SELECT id FROM customers WHERE phone='+998 90 583 20 80' LIMIT 1), 'import', '2025-06-27'::date, '2025-08-05'::date, 'delivered', 0, 200, NULL, 'quva', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 583 20 80')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0081');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13034000.0)/1, 0, 0, 13034000.0
FROM orders o WHERE o.code='L-2506-0081' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-05'::date, 13034000.0, 'UZS', 13034000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0081' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0082', (SELECT id FROM customers WHERE phone='+998 99 096 99 90' LIMIT 1), 'import', '2025-06-27'::date, '2025-09-14'::date, 'delivered', 0, 300, NULL, 'xorazm', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 096 99 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0082');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12004000.0)/1, 0, 0, 12004000.0
FROM orders o WHERE o.code='L-2506-0082' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-14'::date, 12004000.0, 'UZS', 12004000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0082' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0084', (SELECT id FROM customers WHERE phone='+998 93 341 41 11' LIMIT 1), 'import', '2025-06-27'::date, '2025-08-14'::date, 'delivered', 0, 300, NULL, 'Samarqand shaxar', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 341 41 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0084');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (5277000.0)/1, 0, 0, 5277000.0
FROM orders o WHERE o.code='L-2506-0084' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-14'::date, 5277000.0, 'UZS', 5277000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0084' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2506-0085', (SELECT id FROM customers WHERE phone='+998 93 050 01 54' LIMIT 1), 'import', '2025-06-29'::date, '2025-08-24'::date, 'delivered', 0, 300, NULL, 'ANDIJON TUMANI', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER O`NGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 050 01 54')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2506-0085');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1240, (13760000.0)/1, 0, 0, 13760000.0
FROM orders o WHERE o.code='L-2506-0085' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-24'::date, 13760000.0, 'UZS', 13760000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2506-0085' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0002', (SELECT id FROM customers WHERE phone='+998 90 254 15 10' LIMIT 1), 'import', '2025-07-01'::date, '2025-08-09'::date, 'delivered', 0, 400, NULL, 'ANDIJON TUMANI', 0, 'Model (asl): BUNKER 3, 400 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 254 15 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (14497000.0)/1, 0, 0, 14497000.0
FROM orders o WHERE o.code='L-2507-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-09'::date, 14497000.0, 'UZS', 14497000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0003', (SELECT id FROM customers WHERE phone='+998 91 679 45 86' LIMIT 1), 'import', '2025-07-01'::date, '2025-07-08'::date, 'delivered', 0, 200, NULL, 'YOZYAVON TUMANI', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 679 45 86')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12592000.0)/1, 0, 0, 12592000.0
FROM orders o WHERE o.code='L-2507-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-08'::date, 12592000.0, 'UZS', 12592000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0004', (SELECT id FROM customers WHERE phone='+998 94 832 89 96' LIMIT 1), 'import', '2025-07-01'::date, '2025-09-08'::date, 'delivered', 0, 400, NULL, 'SAMARQAND PAXTACHI', 0, 'Model (asl): BUNKER 3, 400 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 832 89 96')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (13426000.0)/1, 0, 0, 13426000.0
FROM orders o WHERE o.code='L-2507-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-08'::date, 13426000.0, 'UZS', 13426000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0005', (SELECT id FROM customers WHERE phone='+998 99 327 16 79' LIMIT 1), 'import', '2025-07-02'::date, '2025-08-26'::date, 'delivered', 0, 200, NULL, 'ANDIJON PAXTAOBOD', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 327 16 79')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1190, (7500000.0)/1, 0, 0, 7500000.0
FROM orders o WHERE o.code='L-2507-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-26'::date, 7500000.0, 'UZS', 7500000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0006', (SELECT id FROM customers WHERE phone='+998 77 777 21 01' LIMIT 1), 'import', '2025-07-03'::date, '2025-08-09'::date, 'delivered', 0, 200, NULL, 'ANDIJON QURGONTEPA', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 777 21 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12004000.0)/1, 0, 0, 12004000.0
FROM orders o WHERE o.code='L-2507-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-09'::date, 12004000.0, 'UZS', 12004000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0007', (SELECT id FROM customers WHERE phone='+998 93 736 88 87' LIMIT 1), 'import', '2025-07-03'::date, '2025-08-03'::date, 'delivered', 0, 200, NULL, 'NAMANGAN', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 736 88 87')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13534000.0)/1, 0, 0, 13534000.0
FROM orders o WHERE o.code='L-2507-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-03'::date, 13534000.0, 'UZS', 13534000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0008', (SELECT id FROM customers WHERE phone='+998 99 405 57 17' LIMIT 1), 'import', '2025-07-04'::date, '2025-08-29'::date, 'delivered', 0, 200, NULL, 'NAMANGAN uchqurgon', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 405 57 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (10188000.0)/1, 0, 0, 10188000.0
FROM orders o WHERE o.code='L-2507-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-29'::date, 10188000.0, 'UZS', 10188000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0009', (SELECT id FROM customers WHERE phone='+998 94 568 04 15' LIMIT 1), 'import', '2025-07-04'::date, '2025-08-09'::date, 'delivered', 0, 200, NULL, 'ANDIJON XONABOD', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 568 04 15')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13488000.0)/1, 0, 0, 13488000.0
FROM orders o WHERE o.code='L-2507-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-09'::date, 13488000.0, 'UZS', 13488000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0010', (SELECT id FROM customers WHERE phone='+998 99 900 75 63' LIMIT 1), 'import', '2025-07-04'::date, '2025-08-12'::date, 'delivered', 0, 200, NULL, 'ANDIJON MARXAMAT', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 900 75 63')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12488000.0)/1, 0, 0, 12488000.0
FROM orders o WHERE o.code='L-2507-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-12'::date, 12488000.0, 'UZS', 12488000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0011', (SELECT id FROM customers WHERE phone='+998 99 605 57 17' LIMIT 1), 'import', '2025-07-04'::date, '2025-09-08'::date, 'delivered', 0, 300, NULL, 'ANDIJON ULUGNOR', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 605 57 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12587000.0)/1, 0, 0, 12587000.0
FROM orders o WHERE o.code='L-2507-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-08'::date, 12587000.0, 'UZS', 12587000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0012', (SELECT id FROM customers WHERE phone='+996 553019490' LIMIT 1), 'import', '2025-07-04'::date, '2025-08-16'::date, 'delivered', 0, 150, NULL, 'QIRGIZSTON OSH', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+996 553019490')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (10077000.0)/1, 0, 0, 10077000.0
FROM orders o WHERE o.code='L-2507-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-16'::date, 10077000.0, 'UZS', 10077000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0013', (SELECT id FROM customers WHERE phone='+998 90 535 05 94' LIMIT 1), 'import', '2025-07-04'::date, '2025-08-03'::date, 'delivered', 0, 200, NULL, 'QUSHTEPA', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 535 05 94')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (10488000.0)/1, 0, 0, 10488000.0
FROM orders o WHERE o.code='L-2507-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-03'::date, 10488000.0, 'UZS', 10488000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0014', (SELECT id FROM customers WHERE phone='+998 99 417 35 17' LIMIT 1), 'import', '2025-07-04'::date, '2025-08-24'::date, 'delivered', 0, 300, NULL, 'samarqand pastargon', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 417 35 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13499000.0)/1, 0, 0, 13499000.0
FROM orders o WHERE o.code='L-2507-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-24'::date, 13499000.0, 'UZS', 13499000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0015', (SELECT id FROM customers WHERE phone='+998 90 567 34 44' LIMIT 1), 'import', '2025-07-04'::date, '2025-09-15'::date, 'delivered', 0, 400, NULL, 'Bagdod', 0, 'Model (asl): BUNKER 3, 400 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 567 34 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (8807000.0)/1, 0, 0, 8807000.0
FROM orders o WHERE o.code='L-2507-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-15'::date, 8807000.0, 'UZS', 8807000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0016', (SELECT id FROM customers WHERE phone='+998 97 577 74 10' LIMIT 1), 'import', '2025-07-04'::date, '2025-09-10'::date, 'delivered', 0, 300, NULL, 'samarqand pastargon', 0, 'Model (asl): BUNKER ULTRA, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 577 74 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1499, (16848000.0)/1, 0, 0, 16848000.0
FROM orders o WHERE o.code='L-2507-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-10'::date, 16848000.0, 'UZS', 16848000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0048', (SELECT id FROM customers WHERE phone='+998 99 785 66 60' LIMIT 1), 'import', '2025-07-04'::date, '2025-08-13'::date, 'delivered', 0, 150, NULL, 'Namangan', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 785 66 60')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0048');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (11000000.0)/1, 0, 0, 11000000.0
FROM orders o WHERE o.code='L-2507-0048' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-13'::date, 11000000.0, 'UZS', 11000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0048' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0049', (SELECT id FROM customers WHERE phone='+998 93 255 55 62' LIMIT 1), 'import', '2025-07-04'::date, '2025-08-15'::date, 'delivered', 0, 150, NULL, 'ANDIJON BUSTON', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 255 55 62')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0049');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (10587000.0)/1, 0, 0, 10587000.0
FROM orders o WHERE o.code='L-2507-0049' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-15'::date, 10587000.0, 'UZS', 10587000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0049' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0050', (SELECT id FROM customers WHERE phone='+7 925 466 02 51' LIMIT 1), 'import', '2025-07-04'::date, '2025-09-03'::date, 'delivered', 0, 200, NULL, 'JIZZAX PAXTAKOR', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+7 925 466 02 51')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0050');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (9477000.0)/1, 0, 0, 9477000.0
FROM orders o WHERE o.code='L-2507-0050' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-03'::date, 9477000.0, 'UZS', 9477000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0050' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0051', (SELECT id FROM customers WHERE phone='+998 97 583 98 00' LIMIT 1), 'import', '2025-07-05'::date, '2025-08-28'::date, 'delivered', 0, 200, NULL, 'aasaka tumani', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 583 98 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0051');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13667000.0)/1, 0, 0, 13667000.0
FROM orders o WHERE o.code='L-2507-0051' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-28'::date, 13667000.0, 'UZS', 13667000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0051' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0052', (SELECT id FROM customers WHERE phone='+998 97 583 98 00' LIMIT 1), 'import', '2025-07-05'::date, '2025-08-28'::date, 'delivered', 0, 200, NULL, 'aasaka tumani', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 583 98 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0052');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13667000.0)/1, 0, 0, 13667000.0
FROM orders o WHERE o.code='L-2507-0052' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-28'::date, 13667000.0, 'UZS', 13667000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0052' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0054', (SELECT id FROM customers WHERE phone='+998 99 562 42 44' LIMIT 1), 'import', '2025-07-06'::date, '2025-09-22'::date, 'delivered', 0, 300, NULL, 'XORAZM', 0, 'Model (asl): BUNKER 4, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 562 42 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0054');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (3404000.0)/1, 0, 0, 3404000.0
FROM orders o WHERE o.code='L-2507-0054' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-22'::date, 3404000.0, 'UZS', 3404000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0054' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0055', (SELECT id FROM customers WHERE phone='+998 94 748 02 00' LIMIT 1), 'import', '2025-07-06'::date, '2025-08-16'::date, 'delivered', 0, 150, NULL, 'TOSHLOQ TUMAN', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 748 02 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0055');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (10739000.0)/1, 0, 0, 10739000.0
FROM orders o WHERE o.code='L-2507-0055' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-16'::date, 10739000.0, 'UZS', 10739000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0055' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0056', (SELECT id FROM customers WHERE phone='+998 91 483 15 76' LIMIT 1), 'import', '2025-07-07'::date, '2025-08-16'::date, 'delivered', 0, 150, NULL, 'ANDIJON BULOQBOSHI', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 483 15 76')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0056');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (10869000.0)/1, 0, 0, 10869000.0
FROM orders o WHERE o.code='L-2507-0056' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-16'::date, 10869000.0, 'UZS', 10869000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0056' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0057', (SELECT id FROM customers WHERE phone='+998 90 202 11 22' LIMIT 1), 'import', '2025-07-08'::date, '2025-09-06'::date, 'delivered', 0, 300, NULL, 'ANDIJON', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 202 11 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0057');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13311000.0)/1, 0, 0, 13311000.0
FROM orders o WHERE o.code='L-2507-0057' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-06'::date, 13311000.0, 'UZS', 13311000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0057' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0058', (SELECT id FROM customers WHERE phone='+998 99 503 27 35' LIMIT 1), 'import', '2025-07-09'::date, '2025-08-27'::date, 'delivered', 0, 200, NULL, 'BUXORO', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 503 27 35')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0058');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12592000.0)/1, 0, 0, 12592000.0
FROM orders o WHERE o.code='L-2507-0058' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-27'::date, 12592000.0, 'UZS', 12592000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0058' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0059', (SELECT id FROM customers WHERE phone='+998 93 502 90 32' LIMIT 1), 'import', '2025-07-09'::date, '2025-09-03'::date, 'delivered', 0, 200, NULL, 'BUXORO', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 502 90 32')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0059');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12118000.0)/1, 0, 0, 12118000.0
FROM orders o WHERE o.code='L-2507-0059' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-03'::date, 12118000.0, 'UZS', 12118000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0059' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0060', (SELECT id FROM customers WHERE phone='+998 99 611 60 01' LIMIT 1), 'import', '2025-07-09'::date, '2025-09-11'::date, 'delivered', 0, 200, NULL, 'Namangan', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 611 60 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0060');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12118000.0)/1, 0, 0, 12118000.0
FROM orders o WHERE o.code='L-2507-0060' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-11'::date, 12118000.0, 'UZS', 12118000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0060' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0061', (SELECT id FROM customers WHERE phone='+7 929 917 47 87' LIMIT 1), 'import', '2025-07-09'::date, '2025-09-11'::date, 'delivered', 0, 200, NULL, 'Namangan', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+7 929 917 47 87')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0061');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (14672000.0)/1, 0, 0, 14672000.0
FROM orders o WHERE o.code='L-2507-0061' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-11'::date, 14672000.0, 'UZS', 14672000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0061' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0062', (SELECT id FROM customers WHERE phone='+998 99 621 01 11' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-29'::date, 'delivered', 0, 200, NULL, 'rishton', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 621 01 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0062');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13000000.0)/1, 0, 0, 13000000.0
FROM orders o WHERE o.code='L-2507-0062' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-29'::date, 13000000.0, 'UZS', 13000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0062' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0063', (SELECT id FROM customers WHERE phone='+998 33 963 30 55' LIMIT 1), 'import', '2025-07-11'::date, '2025-09-08'::date, 'delivered', 0, 300, NULL, 'Oltiariq', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 963 30 55')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0063');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12287000.0)/1, 0, 0, 12287000.0
FROM orders o WHERE o.code='L-2507-0063' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-08'::date, 12287000.0, 'UZS', 12287000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0063' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0064', (SELECT id FROM customers WHERE phone='+998 93 714 34 84' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-28'::date, 'delivered', 0, 200, NULL, 'Qoraqalpogiston', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 714 34 84')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0064');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12115000.0)/1, 0, 0, 12115000.0
FROM orders o WHERE o.code='L-2507-0064' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-28'::date, 12115000.0, 'UZS', 12115000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0064' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0065', (SELECT id FROM customers WHERE phone='+998 90 271 77 00' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-16'::date, 'delivered', 0, 200, NULL, 'Oltiariq', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 271 77 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0065');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12615000.0)/1, 0, 0, 12615000.0
FROM orders o WHERE o.code='L-2507-0065' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-16'::date, 12615000.0, 'UZS', 12615000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0065' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0066', (SELECT id FROM customers WHERE phone='+998 90 271 77 00' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-16'::date, 'delivered', 0, 200, NULL, 'Oltiariq', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 271 77 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0066');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12615000.0)/1, 0, 0, 12615000.0
FROM orders o WHERE o.code='L-2507-0066' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-16'::date, 12615000.0, 'UZS', 12615000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0066' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0067', (SELECT id FROM customers WHERE phone='+998 90 271 77 00' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-16'::date, 'delivered', 0, 200, NULL, 'Oltiariq', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 271 77 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0067');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12615000.0)/1, 0, 0, 12615000.0
FROM orders o WHERE o.code='L-2507-0067' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-16'::date, 12615000.0, 'UZS', 12615000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0067' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0068', (SELECT id FROM customers WHERE phone='+998 93 492 39 32' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-25'::date, 'delivered', 0, 200, NULL, 'uychi tumani', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 492 39 32')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0068');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12000000.0)/1, 0, 0, 12000000.0
FROM orders o WHERE o.code='L-2507-0068' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-25'::date, 12000000.0, 'UZS', 12000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0068' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0069', (SELECT id FROM customers WHERE phone='+998 93 492 39 32' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-25'::date, 'delivered', 0, 200, NULL, 'uychi tumani', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 492 39 32')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0069');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12000000.0)/1, 0, 0, 12000000.0
FROM orders o WHERE o.code='L-2507-0069' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-25'::date, 12000000.0, 'UZS', 12000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0069' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0070', (SELECT id FROM customers WHERE phone='+998 88 662 72 59' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-18'::date, 'delivered', 0, 150, NULL, 'Margilon', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 662 72 59')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0070');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (10737000.0)/1, 0, 0, 10737000.0
FROM orders o WHERE o.code='L-2507-0070' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-18'::date, 10737000.0, 'UZS', 10737000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0070' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0071', (SELECT id FROM customers WHERE phone='+998 99 036 10 61' LIMIT 1), 'import', '2025-07-11'::date, '2025-08-30'::date, 'delivered', 0, 150, NULL, 'Xorazm', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 036 10 61')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0071');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 999, (10737000.0)/1, 0, 0, 10737000.0
FROM orders o WHERE o.code='L-2507-0071' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-30'::date, 10737000.0, 'UZS', 10737000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0071' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0072', (SELECT id FROM customers WHERE phone='+998 97 253 93 93' LIMIT 1), 'import', '2025-07-11'::date, '2025-09-05'::date, 'delivered', 0, 200, NULL, 'uychi tumani', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 253 93 93')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0072');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13649000.0)/1, 0, 0, 13649000.0
FROM orders o WHERE o.code='L-2507-0072' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-05'::date, 13649000.0, 'UZS', 13649000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0072' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0073', (SELECT id FROM customers WHERE phone='+998 91 364 01 99' LIMIT 1), 'import', '2025-07-11'::date, '2025-09-05'::date, 'delivered', 0, 200, NULL, 'uychi tumani', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 364 01 99')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0073');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13649000.0)/1, 0, 0, 13649000.0
FROM orders o WHERE o.code='L-2507-0073' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-05'::date, 13649000.0, 'UZS', 13649000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0073' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0074', (SELECT id FROM customers WHERE phone='+998 97 337 50 02' LIMIT 1), 'import', '2025-07-12'::date, '2025-07-10'::date, 'delivered', 0, 200, NULL, 'Bogish qishlogi', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 337 50 02')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0074');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13311000.0)/1, 0, 0, 13311000.0
FROM orders o WHERE o.code='L-2507-0074' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-10'::date, 13311000.0, 'UZS', 13311000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0074' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0075', (SELECT id FROM customers WHERE phone='+998 77 777 72 75' LIMIT 1), 'import', '2025-07-13'::date, '2025-07-10'::date, 'delivered', 0, 300, NULL, 'MARGILON', 0, 'Model (asl): BUNKER ULTRA, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 777 72 75')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0075');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15797000.0)/1, 0, 0, 15797000.0
FROM orders o WHERE o.code='L-2507-0075' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-10'::date, 15797000.0, 'UZS', 15797000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0075' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0076', (SELECT id FROM customers WHERE phone='+998 88 700 60 84' LIMIT 1), 'import', '2025-07-13'::date, '2025-09-02'::date, 'delivered', 0, 200, NULL, 'qashqadaryo kitob', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 700 60 84')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0076');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (8849000.0)/1, 0, 0, 8849000.0
FROM orders o WHERE o.code='L-2507-0076' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-02'::date, 8849000.0, 'UZS', 8849000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0076' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0077', (SELECT id FROM customers WHERE phone='+998 91 552 70 10' LIMIT 1), 'import', '2025-07-14'::date, '2025-09-10'::date, 'delivered', 0, 300, NULL, 'samarqand', 0, 'Model (asl): BUNKER 4, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 552 70 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0077');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (15837000.0)/1, 0, 0, 15837000.0
FROM orders o WHERE o.code='L-2507-0077' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-10'::date, 15837000.0, 'UZS', 15837000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0077' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0078', (SELECT id FROM customers WHERE phone='+998 90 273 87 87' LIMIT 1), 'import', '2025-07-14'::date, '2025-09-11'::date, 'delivered', 0, 200, NULL, 'margilon', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 273 87 87')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0078');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (9549000.0)/1, 0, 0, 9549000.0
FROM orders o WHERE o.code='L-2507-0078' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-11'::date, 9549000.0, 'UZS', 9549000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0078' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0079', (SELECT id FROM customers WHERE phone='+998 91 173 33 11' LIMIT 1), 'import', '2025-07-15'::date, '2025-07-27'::date, 'delivered', 0, 300, NULL, 'ANDIJON DILLLER', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 173 33 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0079');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (16062000.0)/1, 0, 0, 16062000.0
FROM orders o WHERE o.code='L-2507-0079' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-27'::date, 16062000.0, 'UZS', 16062000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0079' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0080', (SELECT id FROM customers WHERE phone='+998 91 173 33 11' LIMIT 1), 'import', '2025-07-15'::date, '2025-07-27'::date, 'delivered', 0, 200, NULL, 'ANDIJON DILLLER', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 173 33 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0080');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14787000.0)/1, 0, 0, 14787000.0
FROM orders o WHERE o.code='L-2507-0080' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-27'::date, 14787000.0, 'UZS', 14787000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0080' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0084', (SELECT id FROM customers WHERE phone='+998 94 404 42 12' LIMIT 1), 'import', '2025-07-15'::date, '2025-09-27'::date, 'delivered', 0, 200, NULL, 'Paxtabod tumani', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 404 42 12')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0084');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13287000.0)/1, 0, 0, 13287000.0
FROM orders o WHERE o.code='L-2507-0084' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-27'::date, 13287000.0, 'UZS', 13287000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0084' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0085', (SELECT id FROM customers WHERE phone='+998 88 666 07 71' LIMIT 1), 'import', '2025-07-16'::date, '2025-09-13'::date, 'delivered', 0, 200, NULL, 'QUVA TUMANI', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 666 07 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0085');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1240, (13343000.0)/1, 0, 0, 13343000.0
FROM orders o WHERE o.code='L-2507-0085' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-13'::date, 13343000.0, 'UZS', 13343000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0085' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0086', (SELECT id FROM customers WHERE phone='+998 91 655 95 00' LIMIT 1), 'import', '2025-07-17'::date, '2025-08-07'::date, 'delivered', 0, 150, NULL, 'Qushtepa tuman', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 655 95 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0086');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (11353000.0)/1, 0, 0, 11353000.0
FROM orders o WHERE o.code='L-2507-0086' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-07'::date, 11353000.0, 'UZS', 11353000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0086' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0087', (SELECT id FROM customers WHERE phone='+998 99 603 53 99' LIMIT 1), 'import', '2025-07-17'::date, '2025-09-06'::date, 'delivered', 0, 300, NULL, 'UZBEKISTON TUMANI', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 603 53 99')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0087');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (14078000.0)/1, 0, 0, 14078000.0
FROM orders o WHERE o.code='L-2507-0087' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-06'::date, 14078000.0, 'UZS', 14078000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0087' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0088', (SELECT id FROM customers WHERE phone='+998 99 507 80 05' LIMIT 1), 'import', '2025-07-17'::date, '2025-07-30'::date, 'delivered', 0, 300, NULL, 'XORAZM URGECHN', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 507 80 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0088');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (16640000.0)/1, 0, 0, 16640000.0
FROM orders o WHERE o.code='L-2507-0088' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-30'::date, 16640000.0, 'UZS', 16640000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0088' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0089', (SELECT id FROM customers WHERE phone='+998 99 507 80 05' LIMIT 1), 'import', '2025-07-17'::date, '2025-07-30'::date, 'delivered', 0, 200, NULL, 'XORAZM URGECHN', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 507 80 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0089');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 0, (15359000.0)/1, 0, 0, 15359000.0
FROM orders o WHERE o.code='L-2507-0089' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-30'::date, 15359000.0, 'UZS', 15359000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0089' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0090', (SELECT id FROM customers WHERE phone='+998 99 896 54 54' LIMIT 1), 'import', '2025-07-17'::date, '2025-09-11'::date, 'delivered', 0, 200, NULL, 'margilon', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 896 54 54')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0090');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12701000.0)/1, 0, 0, 12701000.0
FROM orders o WHERE o.code='L-2507-0090' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-11'::date, 12701000.0, 'UZS', 12701000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0090' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0091', (SELECT id FROM customers WHERE phone='+998 93 730 04 01' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-26'::date, 'delivered', 0, 300, NULL, 'buvayda', 0, 'Model (asl): BUNMER ULTRA, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 730 04 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0091');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNMER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNMER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (8682000.0)/1, 0, 0, 8682000.0
FROM orders o WHERE o.code='L-2507-0091' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-26'::date, 8682000.0, 'UZS', 8682000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0091' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0092', (SELECT id FROM customers WHERE phone='+998 91 669 88 05' LIMIT 1), 'import', '2025-07-18'::date, '2025-08-19'::date, 'delivered', 0, 150, NULL, 'fargona', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 669 88 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0092');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (12353000.0)/1, 0, 0, 12353000.0
FROM orders o WHERE o.code='L-2507-0092' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-19'::date, 12353000.0, 'UZS', 12353000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0092' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0093', (SELECT id FROM customers WHERE phone='+998 93 483 42 02' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-06'::date, 'delivered', 0, 200, NULL, 'yaypan', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 483 42 02')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0093');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (6480000.0)/1, 0, 0, 6480000.0
FROM orders o WHERE o.code='L-2507-0093' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-06'::date, 6480000.0, 'UZS', 6480000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0093' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0095', (SELECT id FROM customers WHERE phone='+998 91 600 19 94' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-24'::date, 'delivered', 0, 200, NULL, 'marxamat', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 600 19 94')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0095');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (9530000.0)/1, 0, 0, 9530000.0
FROM orders o WHERE o.code='L-2507-0095' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-24'::date, 9530000.0, 'UZS', 9530000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0095' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0096', (SELECT id FROM customers WHERE phone='+998 93 243 19 19' LIMIT 1), 'import', '2025-07-18'::date, '2025-10-04'::date, 'delivered', 0, 300, NULL, 'ANDIJON PAXTA OBOD', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 243 19 19')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0096');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (14497000.0)/1, 0, 0, 14497000.0
FROM orders o WHERE o.code='L-2507-0096' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-04'::date, 14497000.0, 'UZS', 14497000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0096' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0097', (SELECT id FROM customers WHERE phone='+998 90 272 70 50' LIMIT 1), 'import', '2025-07-18'::date, '2025-12-29'::date, 'delivered', 0, 200, NULL, 'Margilon', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 272 70 50')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0097');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14592000.0)/1, 0, 0, 14592000.0
FROM orders o WHERE o.code='L-2507-0097' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-29'::date, 14592000.0, 'UZS', 14592000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0097' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0098', (SELECT id FROM customers WHERE phone='+998 97 911 37 93' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-10'::date, 'delivered', 0, 200, NULL, 'samarqand tuman', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 911 37 93')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0098');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13387000.0)/1, 0, 0, 13387000.0
FROM orders o WHERE o.code='L-2507-0098' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-10'::date, 13387000.0, 'UZS', 13387000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0098' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0099', (SELECT id FROM customers WHERE phone='+998 90 407 29 94' LIMIT 1), 'import', '2025-07-18'::date, '2025-08-25'::date, 'delivered', 0, 400, NULL, 'YOZYOVON', 0, 'Model (asl): BUNKER 3, 400 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 407 29 94')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0099');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (15862000.0)/1, 0, 0, 15862000.0
FROM orders o WHERE o.code='L-2507-0099' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-25'::date, 15862000.0, 'UZS', 15862000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0099' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0100', (SELECT id FROM customers WHERE phone='+998 97 468 08 87' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-21'::date, 'delivered', 0, 150, NULL, 'UCHQURGON', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 468 08 87')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0100');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (12322000.0)/1, 0, 0, 12322000.0
FROM orders o WHERE o.code='L-2507-0100' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-21'::date, 12322000.0, 'UZS', 12322000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0100' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0101', (SELECT id FROM customers WHERE phone='+998 97 468 08 87' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-21'::date, 'delivered', 0, 200, NULL, 'UCHQURGON', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 468 08 87')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0101');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14227000.0)/1, 0, 0, 14227000.0
FROM orders o WHERE o.code='L-2507-0101' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-21'::date, 14227000.0, 'UZS', 14227000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0101' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0102', (SELECT id FROM customers WHERE phone='+998 93 677 99 22' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-05'::date, 'delivered', 0, 150, NULL, 'NAMANGAN UYCHI', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 677 99 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0102');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (11269000.0)/1, 0, 0, 11269000.0
FROM orders o WHERE o.code='L-2507-0102' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-05'::date, 11269000.0, 'UZS', 11269000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0102' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0103', (SELECT id FROM customers WHERE phone='+998 93 866 18 92' LIMIT 1), 'import', '2025-07-18'::date, '2025-10-05'::date, 'delivered', 0, 300, NULL, 'NAMANGAN NORIN', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 866 18 92')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0103');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (13902000.0)/1, 0, 0, 13902000.0
FROM orders o WHERE o.code='L-2507-0103' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-05'::date, 13902000.0, 'UZS', 13902000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0103' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0104', (SELECT id FROM customers WHERE phone='+998 97 345 20 42' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-17'::date, 'delivered', 0, 300, NULL, 'BUSTONLIQ TUMANI', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 345 20 42')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0104');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (13892000.0)/1, 0, 0, 13892000.0
FROM orders o WHERE o.code='L-2507-0104' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-17'::date, 13892000.0, 'UZS', 13892000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0104' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0105', (SELECT id FROM customers WHERE phone='+998 90 560 87 89' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-06'::date, 'delivered', 0, 200, NULL, 'Qushtepa tuman', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 560 87 89')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0105');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13167000.0)/1, 0, 0, 13167000.0
FROM orders o WHERE o.code='L-2507-0105' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-06'::date, 13167000.0, 'UZS', 13167000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0105' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0106', (SELECT id FROM customers WHERE phone='+998 94 199 31 91' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-03'::date, 'delivered', 0, 150, NULL, 'JIZZAX ZAFAROBOD', 0, 'Model (asl): BUNKER ULTRA, 150 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 199 31 91')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0106');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (13789000.0)/1, 0, 0, 13789000.0
FROM orders o WHERE o.code='L-2507-0106' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-03'::date, 13789000.0, 'UZS', 13789000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0106' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0107', (SELECT id FROM customers WHERE phone='+998 91 441 38 46' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-03'::date, 'delivered', 0, 200, NULL, 'BUXORO VOBKENT', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 441 38 46')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0107');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (10167000.0)/1, 0, 0, 10167000.0
FROM orders o WHERE o.code='L-2507-0107' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-03'::date, 10167000.0, 'UZS', 10167000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0107' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0108', (SELECT id FROM customers WHERE phone='+998 99 819 00 88' LIMIT 1), 'import', '2025-07-18'::date, '2025-10-08'::date, 'delivered', 0, 150, NULL, 'QUVA TUMANI', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 819 00 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0108');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (12269000.0)/1, 0, 0, 12269000.0
FROM orders o WHERE o.code='L-2507-0108' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-08'::date, 12269000.0, 'UZS', 12269000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0108' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0109', (SELECT id FROM customers WHERE phone='+998 99 819 00 88' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-30'::date, 'delivered', 0, 150, NULL, 'QUVA TUMANI', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 819 00 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0109');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (12269000.0)/1, 0, 0, 12269000.0
FROM orders o WHERE o.code='L-2507-0109' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-30'::date, 12269000.0, 'UZS', 12269000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0109' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0110', (SELECT id FROM customers WHERE phone='+998 97 819 00 88' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-30'::date, 'delivered', 0, 150, NULL, 'QUVA TUMANI', 0, 'Model (asl): BUNKER 4, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 819 00 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0110');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (13634000.0)/1, 0, 0, 13634000.0
FROM orders o WHERE o.code='L-2507-0110' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-30'::date, 13634000.0, 'UZS', 13634000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0110' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0111', (SELECT id FROM customers WHERE phone='+998 88 223 20 92' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-24'::date, 'delivered', 0, 150, NULL, 'SAMARQAND TOYLOQ', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 223 20 92')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0111');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (9027000.0)/1, 0, 0, 9027000.0
FROM orders o WHERE o.code='L-2507-0111' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-24'::date, 9027000.0, 'UZS', 9027000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0111' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0112', (SELECT id FROM customers WHERE phone='+998 99 303 52 37' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-27'::date, 'delivered', 0, 150, NULL, 'NAMANGAN YANGIQURGON', 0, 'Model (asl): BUNKER 3, 150 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 303 52 37')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0112');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (10749000.0)/1, 0, 0, 10749000.0
FROM orders o WHERE o.code='L-2507-0112' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-27'::date, 10749000.0, 'UZS', 10749000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0112' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0113', (SELECT id FROM customers WHERE phone='+998 90 366 43 43' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-10'::date, 'delivered', 0, 200, NULL, 'MANGIT', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 366 43 43')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0113');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (12637000.0)/1, 0, 0, 12637000.0
FROM orders o WHERE o.code='L-2507-0113' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-10'::date, 12637000.0, 'UZS', 12637000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0113' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0114', (SELECT id FROM customers WHERE phone='+998 93 942 15 00' LIMIT 1), 'import', '2025-07-18'::date, '2025-09-17'::date, 'delivered', 0, 300, NULL, 'NAMANGAN', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 942 15 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0114');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15432000.0)/1, 0, 0, 15432000.0
FROM orders o WHERE o.code='L-2507-0114' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-17'::date, 15432000.0, 'UZS', 15432000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0114' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0116', (SELECT id FROM customers WHERE phone='+998 99 657 77 00' LIMIT 1), 'import', '2025-07-18'::date, '2025-10-22'::date, 'delivered', 0, 500, NULL, 'samarqand', 0, 'Model (asl): BUNKER 3, 500 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 657 77 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0116');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1449, (16329000.0)/1, 0, 0, 16329000.0
FROM orders o WHERE o.code='L-2507-0116' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-22'::date, 16329000.0, 'UZS', 16329000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0116' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0117', (SELECT id FROM customers WHERE phone='+998 90 290 00 37' LIMIT 1), 'import', '2025-07-18'::date, '2025-10-06'::date, 'delivered', 0, 300, NULL, 'MARGILON', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 290 00 37')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0117');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15447000.0)/1, 0, 0, 15447000.0
FROM orders o WHERE o.code='L-2507-0117' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-06'::date, 15447000.0, 'UZS', 15447000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0117' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0118', (SELECT id FROM customers WHERE phone='+998 90 164 64 45' LIMIT 1), 'import', '2025-07-18'::date, '2025-10-06'::date, 'delivered', 0, 300, NULL, 'MARGILON', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 164 64 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0118');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15447000.0)/1, 0, 0, 15447000.0
FROM orders o WHERE o.code='L-2507-0118' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-06'::date, 15447000.0, 'UZS', 15447000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0118' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0119', (SELECT id FROM customers WHERE phone='+998 94 448 61 18' LIMIT 1), 'import', '2025-07-19'::date, '2025-10-08'::date, 'delivered', 0, 200, NULL, 'beshariq', 0, 'Model (asl): BUNKER 3, 200 kvm | ariston chapda', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 448 61 18')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0119');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1389, (15647000.0)/1, 0, 0, 15647000.0
FROM orders o WHERE o.code='L-2507-0119' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-08'::date, 15647000.0, 'UZS', 15647000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0119' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0120', (SELECT id FROM customers WHERE phone='+998 99 575 93 74' LIMIT 1), 'import', '2025-07-19'::date, '2025-10-13'::date, 'delivered', 0, 300, NULL, 'Qoraqalpogiston', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 575 93 74')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0120');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (14645000.0)/1, 0, 0, 14645000.0
FROM orders o WHERE o.code='L-2507-0120' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-13'::date, 14645000.0, 'UZS', 14645000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0120' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0121', (SELECT id FROM customers WHERE phone='+998 99 575 93 74' LIMIT 1), 'import', '2025-07-19'::date, '2025-10-13'::date, 'delivered', 0, 300, NULL, 'Qoraqalpogiston', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 575 93 74')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0121');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (14645000.0)/1, 0, 0, 14645000.0
FROM orders o WHERE o.code='L-2507-0121' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-13'::date, 14645000.0, 'UZS', 14645000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0121' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0122', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2025-07-20'::date, '2025-10-22'::date, 'delivered', 0, 200, NULL, 'SAMARQAND URGUT', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0122');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13239000.0)/1, 0, 0, 13239000.0
FROM orders o WHERE o.code='L-2507-0122' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-22'::date, 13239000.0, 'UZS', 13239000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0122' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0123', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2025-07-20'::date, '2025-10-22'::date, 'delivered', 0, 300, NULL, 'SAMARQAND URGUT', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0123');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (14510000.0)/1, 0, 0, 14510000.0
FROM orders o WHERE o.code='L-2507-0123' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-22'::date, 14510000.0, 'UZS', 14510000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0123' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0124', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2025-07-20'::date, '2025-08-25'::date, 'delivered', 0, 300, NULL, 'SAMARQAND URGUT', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0124');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (14510000.0)/1, 0, 0, 14510000.0
FROM orders o WHERE o.code='L-2507-0124' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-25'::date, 14510000.0, 'UZS', 14510000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0124' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0125', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2025-07-20'::date, '2025-08-25'::date, 'delivered', 0, 400, NULL, 'SAMARQAND URGUT', 0, 'Model (asl): BUNKER 3, 400 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0125');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (15800000.0)/1, 0, 0, 15800000.0
FROM orders o WHERE o.code='L-2507-0125' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-25'::date, 15800000.0, 'UZS', 15800000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0125' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0126', (SELECT id FROM customers WHERE phone='+998 91 138 24 70' LIMIT 1), 'import', '2025-07-21'::date, '2025-09-14'::date, 'delivered', 0, 150, NULL, 'yaypan', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 138 24 70')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0126');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (3154000.0)/1, 0, 0, 3154000.0
FROM orders o WHERE o.code='L-2507-0126' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-14'::date, 3154000.0, 'UZS', 3154000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0126' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0127', (SELECT id FROM customers WHERE phone='+998 99 446 23 48' LIMIT 1), 'import', '2025-07-21'::date, '2025-10-15'::date, 'delivered', 0, 200, NULL, 'Xorazim Xiva', 0, 'Model (asl): BUNKER 3, 200 kvm | ariston ungda', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 446 23 48')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0127');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1389, (15598000.0)/1, 0, 0, 15598000.0
FROM orders o WHERE o.code='L-2507-0127' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-15'::date, 15598000.0, 'UZS', 15598000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0127' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0128', (SELECT id FROM customers WHERE phone='+998 91 482 08 15' LIMIT 1), 'import', '2025-07-21'::date, '2025-09-14'::date, 'delivered', 0, 200, NULL, 'Andijon buloqboshi', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 482 08 15')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0128');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (13248000.0)/1, 0, 0, 13248000.0
FROM orders o WHERE o.code='L-2507-0128' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-14'::date, 13248000.0, 'UZS', 13248000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0128' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0129', (SELECT id FROM customers WHERE phone='+998 93 781 36 10' LIMIT 1), 'import', '2025-07-21'::date, '2025-09-29'::date, 'delivered', 0, 750, NULL, 'ANDIJON JALAQUDUQ', 0, 'Model (asl): BUNKER 3, 750 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 781 36 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0129');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=750 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1800, (25300000.0)/1, 0, 0, 25300000.0
FROM orders o WHERE o.code='L-2507-0129' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-29'::date, 25300000.0, 'UZS', 25300000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0129' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0130', (SELECT id FROM customers WHERE phone='+998 93 789 36 19' LIMIT 1), 'import', '2025-07-21'::date, '2025-09-29'::date, 'delivered', 0, 200, NULL, 'ANDIJON JALAQUDUQ', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 789 36 19')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0130');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2507-0130' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0131', (SELECT id FROM customers WHERE phone='+998 91 161 03 03' LIMIT 1), 'import', '2025-07-22'::date, '2025-10-16'::date, 'delivered', 0, 300, NULL, 'ANDIJON QURQONTEPA', 0, 'Model (asl): BUNKER 4, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 161 03 03')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0131');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (15837000.0)/1, 0, 0, 15837000.0
FROM orders o WHERE o.code='L-2507-0131' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-16'::date, 15837000.0, 'UZS', 15837000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0131' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0132', (SELECT id FROM customers WHERE phone='+998 88 791 60 20' LIMIT 1), 'import', '2025-07-22'::date, '2025-10-09'::date, 'delivered', 0, 200, NULL, 'Xorazim Xiva', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 791 60 20')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0132');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (5116000.0)/1, 0, 0, 5116000.0
FROM orders o WHERE o.code='L-2507-0132' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-09'::date, 5116000.0, 'UZS', 5116000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0132' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0133', (SELECT id FROM customers WHERE phone='+998 88 791 60 20' LIMIT 1), 'import', '2025-07-22'::date, '2025-10-09'::date, 'delivered', 0, 200, NULL, 'Xorazim Xiva', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 791 60 20')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0133');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (5116000.0)/1, 0, 0, 5116000.0
FROM orders o WHERE o.code='L-2507-0133' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-09'::date, 5116000.0, 'UZS', 5116000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0133' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0134', (SELECT id FROM customers WHERE phone='+998 88 117 58 83' LIMIT 1), 'import', '2025-07-25'::date, '2025-09-17'::date, 'delivered', 0, 200, NULL, 'Samarqand urgut', 0, 'Model (asl): BUNKER 3 pro, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 117 58 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0134');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 pro') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14859000.0)/1, 0, 0, 14859000.0
FROM orders o WHERE o.code='L-2507-0134' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-17'::date, 14859000.0, 'UZS', 14859000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0134' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0135', (SELECT id FROM customers WHERE phone='+998 99 971 76 68' LIMIT 1), 'import', '2025-07-25'::date, '2025-09-22'::date, 'delivered', 0, 300, NULL, 'andijon marxamat', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 971 76 68')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0135');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (14497000.0)/1, 0, 0, 14497000.0
FROM orders o WHERE o.code='L-2507-0135' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-22'::date, 14497000.0, 'UZS', 14497000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0135' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0136', (SELECT id FROM customers WHERE phone='+998 88 117 58 83' LIMIT 1), 'import', '2025-07-25'::date, '2025-09-17'::date, 'delivered', 0, 200, NULL, 'Samarqand urgut', 0, 'Model (asl): BUNKER 3 pro, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 117 58 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0136');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 pro') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14859000.0)/1, 0, 0, 14859000.0
FROM orders o WHERE o.code='L-2507-0136' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-17'::date, 14859000.0, 'UZS', 14859000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0136' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0137', (SELECT id FROM customers WHERE phone='NOPHONE-2507-137' LIMIT 1), 'import', '2025-07-25'::date, '2025-09-30'::date, 'delivered', 0, 300, NULL, 'andijon', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='NOPHONE-2507-137')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0137');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15997000.0)/1, 0, 0, 15997000.0
FROM orders o WHERE o.code='L-2507-0137' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-30'::date, 15997000.0, 'UZS', 15997000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0137' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0139', (SELECT id FROM customers WHERE phone='+998 94 447 81 11' LIMIT 1), 'import', '2025-07-25'::date, '2025-10-05'::date, 'delivered', 0, 300, NULL, 'mangit', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 447 81 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0139');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (16000000.0)/1, 0, 0, 16000000.0
FROM orders o WHERE o.code='L-2507-0139' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-05'::date, 16000000.0, 'UZS', 16000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0139' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0140', (SELECT id FROM customers WHERE phone='+998 50 108 10 00' LIMIT 1), 'import', '2025-07-25'::date, '2025-08-15'::date, 'delivered', 0, 200, NULL, 'Andijon marxamat', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 108 10 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0140');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14727000.0)/1, 0, 0, 14727000.0
FROM orders o WHERE o.code='L-2507-0140' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-15'::date, 14727000.0, 'UZS', 14727000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0140' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0141', (SELECT id FROM customers WHERE phone='+998 94 279 00 18' LIMIT 1), 'import', '2025-07-25'::date, '2025-10-11'::date, 'delivered', 0, 200, NULL, 'namangan shahar', 0, 'Model (asl): BUNKER 4, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 279 00 18')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0141');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15997000.0)/1, 0, 0, 15997000.0
FROM orders o WHERE o.code='L-2507-0141' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-11'::date, 15997000.0, 'UZS', 15997000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0141' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0142', (SELECT id FROM customers WHERE phone='+998 99 403 04 09' LIMIT 1), 'import', '2025-07-25'::date, '2025-09-30'::date, 'delivered', 0, 750, NULL, 'Toshkent shahar', 0, 'Model (asl): BUNKER 3, 750 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 403 04 09')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0142');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=750 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1799, (21847000.0)/1, 0, 0, 21847000.0
FROM orders o WHERE o.code='L-2507-0142' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-30'::date, 21847000.0, 'UZS', 21847000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0142' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0143', (SELECT id FROM customers WHERE phone='+998 93 733 45 07' LIMIT 1), 'import', '2025-07-25'::date, '2025-09-20'::date, 'delivered', 0, 400, NULL, 'MARGILON', 0, 'Model (asl): BUNKER 3, 400 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 733 45 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0143');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (15862000.0)/1, 0, 0, 15862000.0
FROM orders o WHERE o.code='L-2507-0143' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-20'::date, 15862000.0, 'UZS', 15862000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0143' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0145', (SELECT id FROM customers WHERE phone='+998 99 907 33 74' LIMIT 1), 'import', '2025-07-25'::date, '2025-10-13'::date, 'delivered', 0, 200, NULL, 'Andijon shaxar', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 907 33 74')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0145');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14667000.0)/1, 0, 0, 14667000.0
FROM orders o WHERE o.code='L-2507-0145' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-13'::date, 14667000.0, 'UZS', 14667000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0145' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0146', (SELECT id FROM customers WHERE phone='+998 90 622 47 49' LIMIT 1), 'import', '2025-07-25'::date, '2025-10-13'::date, 'delivered', 0, 300, NULL, 'Andijon shaxar', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 622 47 49')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0146');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15932000.0)/1, 0, 0, 15932000.0
FROM orders o WHERE o.code='L-2507-0146' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-13'::date, 15932000.0, 'UZS', 15932000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0146' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0147', (SELECT id FROM customers WHERE phone='+998 90 210 98 35' LIMIT 1), 'import', '2025-07-26'::date, '2025-10-01'::date, 'delivered', 0, 400, NULL, 'Andijon marhamat', 0, 'Model (asl): BUNKER 3, 400 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 210 98 35')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0147');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (16564000.0)/1, 0, 0, 16564000.0
FROM orders o WHERE o.code='L-2507-0147' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-01'::date, 16564000.0, 'UZS', 16564000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0147' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0148', (SELECT id FROM customers WHERE phone='+998 93 389 60 30' LIMIT 1), 'import', '2025-07-26'::date, '2025-09-18'::date, 'delivered', 0, 200, NULL, 'jizzah', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 389 60 30')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0148');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1234, (14346000.0)/1, 0, 0, 14346000.0
FROM orders o WHERE o.code='L-2507-0148' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-18'::date, 14346000.0, 'UZS', 14346000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0148' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0149', (SELECT id FROM customers WHERE phone='+998 93 389 60 30' LIMIT 1), 'import', '2025-07-26'::date, '2025-09-18'::date, 'delivered', 0, 200, NULL, 'jizzah', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 389 60 30')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0149');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1234, (14346000.0)/1, 0, 0, 14346000.0
FROM orders o WHERE o.code='L-2507-0149' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-18'::date, 14346000.0, 'UZS', 14346000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0149' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0151', (SELECT id FROM customers WHERE phone='+998 99 989 35 19' LIMIT 1), 'import', '2025-07-26'::date, '2025-10-15'::date, 'delivered', 0, 200, NULL, 'Andijon buloqboshi', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 989 35 19')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0151');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1249, (15299000.0)/1, 0, 0, 15299000.0
FROM orders o WHERE o.code='L-2507-0151' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-15'::date, 15299000.0, 'UZS', 15299000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0151' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0152', (SELECT id FROM customers WHERE phone='+998 91 205 55 77' LIMIT 1), 'import', '2025-07-27'::date, '2025-11-06'::date, 'delivered', 0, 300, NULL, 'UZBEKISTON TUMANI', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 205 55 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0152');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (12033000.0)/1, 0, 0, 12033000.0
FROM orders o WHERE o.code='L-2507-0152' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-06'::date, 12033000.0, 'UZS', 12033000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0152' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0154', (SELECT id FROM customers WHERE phone='+998 91 490 73 77' LIMIT 1), 'import', '2025-07-27'::date, '2025-09-26'::date, 'delivered', 0, 200, NULL, 'Andijon shaxar', 0, 'Model (asl): BUNKER 3, 200 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 490 73 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0154');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1240, (12478000.0)/1, 0, 0, 12478000.0
FROM orders o WHERE o.code='L-2507-0154' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-26'::date, 12478000.0, 'UZS', 12478000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0154' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0155', (SELECT id FROM customers WHERE phone='+998 94 496 74 00' LIMIT 1), 'import', '2025-07-28'::date, '2025-11-07'::date, 'delivered', 0, 400, NULL, 'Beshariq tumani', 0, 'Model (asl): BUNKER 4, 400 kvm | BUNKER UNGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 496 74 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0155');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1449, (15737000.0)/1, 0, 0, 15737000.0
FROM orders o WHERE o.code='L-2507-0155' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-07'::date, 15737000.0, 'UZS', 15737000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0155' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0158', (SELECT id FROM customers WHERE phone='+998 77 078 11 87' LIMIT 1), 'import', '2025-07-31'::date, '2025-08-15'::date, 'delivered', 0, 400, NULL, 'namanganb uchqurgon', 0, 'Model (asl): BUNKER 3, 400 kvm | yupes arston', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 078 11 87')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0158');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1964, (24982000.0)/1, 0, 0, 24982000.0
FROM orders o WHERE o.code='L-2507-0158' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-15'::date, 24982000.0, 'UZS', 24982000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0158' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2507-0159', (SELECT id FROM customers WHERE phone='+998 91 119 43 52' LIMIT 1), 'import', '2025-07-31'::date, '2025-10-07'::date, 'delivered', 0, 300, NULL, 'Toshloq tumani', 0, 'Model (asl): BUNKER 3, 300 kvm | BUNKER CHAP', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 119 43 52')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2507-0159');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (16632000.0)/1, 0, 0, 16632000.0
FROM orders o WHERE o.code='L-2507-0159' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-07'::date, 16632000.0, 'UZS', 16632000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2507-0159' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0002', (SELECT id FROM customers WHERE phone='+998 91 173 33 11' LIMIT 1), 'import', '2025-08-01'::date, '2025-07-29'::date, 'delivered', 0, 300, 'right', 'ANDIJON DILLLER', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 173 33 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (16049000.0)/1, 0, 0, 16049000.0
FROM orders o WHERE o.code='L-2508-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-29'::date, 16049000.0, 'UZS', 16049000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0003', (SELECT id FROM customers WHERE phone='+998 91 114 54 30' LIMIT 1), 'import', '2025-08-01'::date, '2025-07-29'::date, 'delivered', 0, 150, NULL, 'VODIL', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 114 54 30')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1049, (12349000.0)/1, 0, 0, 12349000.0
FROM orders o WHERE o.code='L-2508-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-07-29'::date, 12349000.0, 'UZS', 12349000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0004', (SELECT id FROM customers WHERE phone='+998 93 448 70 41' LIMIT 1), 'import', '2025-08-01'::date, '2025-10-02'::date, 'delivered', 0, 200, 'left', 'BALIQCHI TUMAN', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 448 70 41')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1199, (14638000.0)/1, 0, 0, 14638000.0
FROM orders o WHERE o.code='L-2508-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-02'::date, 14638000.0, 'UZS', 14638000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0005', (SELECT id FROM customers WHERE phone='+998 93 448 70 41' LIMIT 1), 'import', '2025-08-01'::date, '2025-10-02'::date, 'delivered', 0, 200, 'left', 'BALIQCHI TUMAN', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 448 70 41')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1199, (14638000.0)/1, 0, 0, 14638000.0
FROM orders o WHERE o.code='L-2508-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-02'::date, 14638000.0, 'UZS', 14638000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0006', (SELECT id FROM customers WHERE phone='+998 93 448 70 41' LIMIT 1), 'import', '2025-08-01'::date, '2025-10-02'::date, 'delivered', 0, 200, 'right', 'BALIQCHI TUMAN', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 448 70 41')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1199, (14638000.0)/1, 0, 0, 14638000.0
FROM orders o WHERE o.code='L-2508-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-02'::date, 14638000.0, 'UZS', 14638000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0007', (SELECT id FROM customers WHERE phone='+998 77 384 40 49' LIMIT 1), 'import', '2025-08-01'::date, '2025-09-23'::date, 'delivered', 0, 300, 'right', 'namangan', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 384 40 49')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (15275000.0)/1, 0, 0, 15275000.0
FROM orders o WHERE o.code='L-2508-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-23'::date, 15275000.0, 'UZS', 15275000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0008', (SELECT id FROM customers WHERE phone='+998 93 477 76 97' LIMIT 1), 'import', '2025-08-01'::date, '2025-10-14'::date, 'delivered', 0, 300, 'left', 'Samarqnd toyloq', 0, 'Model (asl): BUNKER 3, 300 kvm | yupes', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 477 76 97')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1299, (14702000.0)/1, 0, 0, 14702000.0
FROM orders o WHERE o.code='L-2508-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-14'::date, 14702000.0, 'UZS', 14702000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0010', (SELECT id FROM customers WHERE phone='+998 90 301 70 74' LIMIT 1), 'import', '2025-08-01'::date, '2025-09-26'::date, 'delivered', 0, 400, 'right', 'Qushtepa', 0, 'Model (asl): BUNKER 3, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 301 70 74')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (16686000.0)/1, 0, 0, 16686000.0
FROM orders o WHERE o.code='L-2508-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-26'::date, 16686000.0, 'UZS', 16686000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0011', (SELECT id FROM customers WHERE phone='+998 91 110 26 06' LIMIT 1), 'import', '2025-08-01'::date, '2025-09-13'::date, 'delivered', 0, 200, 'left', 'Margilon', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 110 26 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1199, (14275000.0)/1, 0, 0, 14275000.0
FROM orders o WHERE o.code='L-2508-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-13'::date, 14275000.0, 'UZS', 14275000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0012', (SELECT id FROM customers WHERE phone='+998 90 211 60 62' LIMIT 1), 'import', '2025-08-01'::date, '2025-11-04'::date, 'delivered', 0, 400, 'right', 'Marhamat tuman', 0, 'Model (asl): BUNKER 3, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 211 60 62')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (16686000.0)/1, 0, 0, 16686000.0
FROM orders o WHERE o.code='L-2508-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-04'::date, 16686000.0, 'UZS', 16686000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0013', (SELECT id FROM customers WHERE phone='+998 99 430 10 35' LIMIT 1), 'import', '2025-08-01'::date, '2025-10-20'::date, 'delivered', 0, 200, 'right', 'Yangiqurgon', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 430 10 35')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1239, (14700000.0)/1, 0, 0, 14700000.0
FROM orders o WHERE o.code='L-2508-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-20'::date, 14700000.0, 'UZS', 14700000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0015', (SELECT id FROM customers WHERE phone='+998 93 941 10 04' LIMIT 1), 'import', '2025-08-01'::date, '2025-10-17'::date, 'delivered', 0, 300, 'right', 'Namangan uychi', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 941 10 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (16049000.0)/1, 0, 0, 16049000.0
FROM orders o WHERE o.code='L-2508-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-17'::date, 16049000.0, 'UZS', 16049000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0016', (SELECT id FROM customers WHERE phone='+998 93 941 10 04' LIMIT 1), 'import', '2025-08-01'::date, '2025-10-17'::date, 'delivered', 0, 300, 'left', 'Namangan uychi', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 941 10 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1299, (16049000.0)/1, 0, 0, 16049000.0
FROM orders o WHERE o.code='L-2508-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-17'::date, 16049000.0, 'UZS', 16049000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0017', (SELECT id FROM customers WHERE phone='+998 99 690 85 70' LIMIT 1), 'import', '2025-08-02'::date, '2025-10-18'::date, 'delivered', 0, 150, 'left', 'UCHKUPRIK', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 690 85 70')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1099, (13512000.0)/1, 0, 0, 13512000.0
FROM orders o WHERE o.code='L-2508-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-18'::date, 13512000.0, 'UZS', 13512000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0018', (SELECT id FROM customers WHERE phone='+998 97 552 59 50' LIMIT 1), 'import', '2025-08-03'::date, '2025-10-13'::date, 'delivered', 0, 200, 'left', 'SURXANDARYO DENOV', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 552 59 50')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (15424000.0)/1, 0, 0, 15424000.0
FROM orders o WHERE o.code='L-2508-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-13'::date, 15424000.0, 'UZS', 15424000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0019', (SELECT id FROM customers WHERE phone='+998 91 684 13 90' LIMIT 1), 'import', '2025-08-03'::date, '2025-11-01'::date, 'delivered', 0, 200, 'left', 'UZBEKISTON TUMANI', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 684 13 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0019');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1240, (15173000.0)/1, 0, 0, 15173000.0
FROM orders o WHERE o.code='L-2508-0019' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-01'::date, 15173000.0, 'UZS', 15173000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0019' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0020', (SELECT id FROM customers WHERE phone='+998 99 992 05 24' LIMIT 1), 'import', '2025-08-03'::date, '2025-11-11'::date, 'delivered', 0, 300, 'left', 'UZBEKISTON TUMANI', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 992 05 24')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1340, (16447000.0)/1, 0, 0, 16447000.0
FROM orders o WHERE o.code='L-2508-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-11'::date, 16447000.0, 'UZS', 16447000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0021', (SELECT id FROM customers WHERE phone='+998 90 457 84 84' LIMIT 1), 'import', '2025-08-04'::date, '2025-10-04'::date, 'delivered', 0, 150, 'right', 'Margilon', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 457 84 84')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1099, (13322000.0)/1, 0, 0, 13322000.0
FROM orders o WHERE o.code='L-2508-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-04'::date, 13322000.0, 'UZS', 13322000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0022', (SELECT id FROM customers WHERE phone='+998 91 154 54 50' LIMIT 1), 'import', '2025-08-04'::date, '2025-09-14'::date, 'delivered', 0, 200, 'right', 'Yaypan', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 154 54 50')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1240, (15113000.0)/1, 0, 0, 15113000.0
FROM orders o WHERE o.code='L-2508-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-14'::date, 15113000.0, 'UZS', 15113000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0023', (SELECT id FROM customers WHERE phone='+998 95 960 21 10' LIMIT 1), 'import', '2025-08-05'::date, '2025-10-11'::date, 'delivered', 0, 200, 'left', 'Uchqurgon', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 960 21 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1299, (16888000.0)/1, 0, 0, 16888000.0
FROM orders o WHERE o.code='L-2508-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-11'::date, 16888000.0, 'UZS', 16888000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0023' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0024', (SELECT id FROM customers WHERE phone='+998 93 949 87 91' LIMIT 1), 'import', '2025-08-06'::date, '2025-10-16'::date, 'delivered', 0, 200, NULL, 'Andijon Qurgontepa', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 949 87 91')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0024');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (13847000.0)/1, 0, 0, 13847000.0
FROM orders o WHERE o.code='L-2508-0024' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-16'::date, 13847000.0, 'UZS', 13847000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0024' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0025', (SELECT id FROM customers WHERE phone='+998 77 001 39 16' LIMIT 1), 'import', '2025-08-07'::date, '2025-10-16'::date, 'delivered', 0, 300, 'left', 'Kosonsoy tumani', 0, 'Model (asl): BUNKER 3 PRO, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 001 39 16')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (17127000.0)/1, 0, 0, 17127000.0
FROM orders o WHERE o.code='L-2508-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-16'::date, 17127000.0, 'UZS', 17127000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0027', (SELECT id FROM customers WHERE phone='+998 95 645 20 20' LIMIT 1), 'import', '2025-08-07'::date, '2025-11-14'::date, 'delivered', 0, 200, 'right', 'Norin tumani', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 645 20 20')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0027');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1199, (14667000.0)/1, 0, 0, 14667000.0
FROM orders o WHERE o.code='L-2508-0027' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-14'::date, 14667000.0, 'UZS', 14667000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0027' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0029', (SELECT id FROM customers WHERE phone='+998 90 068 01 05' LIMIT 1), 'import', '2025-08-08'::date, '2025-10-17'::date, 'delivered', 0, 300, 'left', 'Uychi tuman', 0, 'Model (asl): BUNKER 3 PRO, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 068 01 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0029');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16564000.0)/1, 0, 0, 16564000.0
FROM orders o WHERE o.code='L-2508-0029' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-17'::date, 16564000.0, 'UZS', 16564000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0029' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0030', (SELECT id FROM customers WHERE phone='+998 91 348 17 77' LIMIT 1), 'import', '2025-08-08'::date, '2025-10-18'::date, 'delivered', 0, 300, 'right', 'Kosonsoy tumani', 0, 'Model (asl): BUNKER 3 PRO, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 348 17 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0030');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15799000.0)/1, 0, 0, 15799000.0
FROM orders o WHERE o.code='L-2508-0030' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-18'::date, 15799000.0, 'UZS', 15799000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0030' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0031', (SELECT id FROM customers WHERE phone='+998 91 994 66 63' LIMIT 1), 'import', '2025-08-08'::date, '2025-10-30'::date, 'delivered', 0, 300, 'left', 'Xiva tuman', 0, 'Model (asl): BUNKER 3 PRO, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 994 66 63')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0031');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (14464000.0)/1, 0, 0, 14464000.0
FROM orders o WHERE o.code='L-2508-0031' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-30'::date, 14464000.0, 'UZS', 14464000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0031' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0032', (SELECT id FROM customers WHERE phone='+998 94 277 08 07' LIMIT 1), 'import', '2025-08-08'::date, '2025-09-26'::date, 'delivered', 0, 200, NULL, 'chust tumani', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 277 08 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0032');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1449, (13269000.0)/1, 0, 0, 13269000.0
FROM orders o WHERE o.code='L-2508-0032' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-26'::date, 13269000.0, 'UZS', 13269000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0032' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0033', (SELECT id FROM customers WHERE phone='+998 93 496 42 42' LIMIT 1), 'import', '2025-08-08'::date, '2025-10-20'::date, 'delivered', 0, 150, 'right', 'Namangan tumani', 0, 'Model (asl): BUNKER 3 PRO, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 496 42 42')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0033');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1149, (13269000.0)/1, 0, 0, 13269000.0
FROM orders o WHERE o.code='L-2508-0033' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-20'::date, 13269000.0, 'UZS', 13269000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0033' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0034', (SELECT id FROM customers WHERE phone='+998 99 903 02 06' LIMIT 1), 'import', '2025-08-08'::date, '2025-08-24'::date, 'delivered', 0, 200, 'left', 'Andijon Jalaquduq', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 903 02 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0034');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1199, (15167000.0)/1, 0, 0, 15167000.0
FROM orders o WHERE o.code='L-2508-0034' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-24'::date, 15167000.0, 'UZS', 15167000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0034' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0036', (SELECT id FROM customers WHERE phone='+998 91 399 69 59' LIMIT 1), 'import', '2025-08-09'::date, '2025-08-06'::date, 'delivered', 0, 1000, NULL, 'Qoraqalpogiston', 0, 'Model (asl): BUNKER 3 PRO, 1000 kvm | yonish joyi chugunli', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 399 69 59')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0036');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=1000 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 2899, (31207000.0)/1, 0, 0, 31207000.0
FROM orders o WHERE o.code='L-2508-0036' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-06'::date, 31207000.0, 'UZS', 31207000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0036' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0037', (SELECT id FROM customers WHERE phone='+998 94 383 00 35' LIMIT 1), 'import', '2025-08-11'::date, '2025-10-18'::date, 'delivered', 0, 200, NULL, 'Andijon xonobod', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 383 00 35')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0037');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15263000.0)/1, 0, 0, 15263000.0
FROM orders o WHERE o.code='L-2508-0037' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-18'::date, 15263000.0, 'UZS', 15263000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0037' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0038', (SELECT id FROM customers WHERE phone='+998 93 794 33 00' LIMIT 1), 'import', '2025-08-11'::date, '2025-10-21'::date, 'delivered', 0, 200, 'left', 'Norin tumani', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 794 33 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0038');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (15805000.0)/1, 0, 0, 15805000.0
FROM orders o WHERE o.code='L-2508-0038' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-21'::date, 15805000.0, 'UZS', 15805000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0038' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0039', (SELECT id FROM customers WHERE phone='+998 99 162 77 07' LIMIT 1), 'import', '2025-08-12'::date, '2025-10-31'::date, 'delivered', 0, 200, 'right', 'SURXANDARYO termz', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 162 77 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0039');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (16267000.0)/1, 0, 0, 16267000.0
FROM orders o WHERE o.code='L-2508-0039' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-31'::date, 16267000.0, 'UZS', 16267000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0039' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0040', (SELECT id FROM customers WHERE phone='+998 99 762 00 26' LIMIT 1), 'import', '2025-08-12'::date, '2025-10-31'::date, 'delivered', 0, 150, 'right', 'SURXANDARYO termz', 0, 'Model (asl): BUNKER ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 762 00 26')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0040');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (14997000.0)/1, 0, 0, 14997000.0
FROM orders o WHERE o.code='L-2508-0040' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-31'::date, 14997000.0, 'UZS', 14997000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0040' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0041', (SELECT id FROM customers WHERE phone='+998 90 777 00 66' LIMIT 1), 'import', '2025-08-12'::date, '2025-08-30'::date, 'delivered', 0, 200, 'left', 'MAGILOB MAGAZIN', 0, 'Model (asl): BUNKER PRO, 200 kvm | diahod', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 777 00 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0041');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (13604000.0)/1, 0, 0, 13604000.0
FROM orders o WHERE o.code='L-2508-0041' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-30'::date, 13604000.0, 'UZS', 13604000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0041' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0042', (SELECT id FROM customers WHERE phone='+998 90 777 00 66' LIMIT 1), 'import', '2025-08-12'::date, '2025-09-08'::date, 'delivered', 0, 300, 'left', 'MAGILOB MAGAZIN', 0, 'Model (asl): BUNKER PRO, 300 kvm | diahod', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 777 00 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0042');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (14861000.0)/1, 0, 0, 14861000.0
FROM orders o WHERE o.code='L-2508-0042' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-08'::date, 14861000.0, 'UZS', 14861000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0042' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0043', (SELECT id FROM customers WHERE phone='+998 90 777 00 66' LIMIT 1), 'import', '2025-08-12'::date, '2025-08-30'::date, 'delivered', 0, 150, 'left', 'MAGILOB MAGAZIN', 0, 'Model (asl): BUNKER PRO, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 777 00 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0043');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1149, (12347000.0)/1, 0, 0, 12347000.0
FROM orders o WHERE o.code='L-2508-0043' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-08-30'::date, 12347000.0, 'UZS', 12347000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0043' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0044', (SELECT id FROM customers WHERE phone='+998 77 373 10 92' LIMIT 1), 'import', '2025-08-13'::date, '2025-10-24'::date, 'delivered', 0, 200, 'right', 'ANDIJON BUSTON TUMANI', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 373 10 92')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0044');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (16973000.0)/1, 0, 0, 16973000.0
FROM orders o WHERE o.code='L-2508-0044' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-24'::date, 16973000.0, 'UZS', 16973000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0044' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0045', (SELECT id FROM customers WHERE phone='+998 88 949 88 89' LIMIT 1), 'import', '2025-08-15'::date, '2025-10-28'::date, 'delivered', 0, 200, 'right', 'Toshloq tuman', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 949 88 89')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0045');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1249, (14534000.0)/1, 0, 0, 14534000.0
FROM orders o WHERE o.code='L-2508-0045' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-28'::date, 14534000.0, 'UZS', 14534000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0045' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0046', (SELECT id FROM customers WHERE phone='+998 91 202 18 92' LIMIT 1), 'import', '2025-08-15'::date, '2025-10-25'::date, 'delivered', 0, 300, 'left', 'Bogdod tuman', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 202 18 92')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0046');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1449, (15762000.0)/1, 0, 0, 15762000.0
FROM orders o WHERE o.code='L-2508-0046' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-25'::date, 15762000.0, 'UZS', 15762000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0046' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0047', (SELECT id FROM customers WHERE phone='+998 91 546 08 95' LIMIT 1), 'import', '2025-08-15'::date, '2025-11-01'::date, 'delivered', 0, 150, 'left', 'SAMARQAND JOMBOY', 0, 'Model (asl): BUNKER ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 546 08 95')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0047');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (15299000.0)/1, 0, 0, 15299000.0
FROM orders o WHERE o.code='L-2508-0047' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-01'::date, 15299000.0, 'UZS', 15299000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0047' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0048', (SELECT id FROM customers WHERE phone='+998 88 662 72 59' LIMIT 1), 'import', '2025-08-15'::date, '2025-09-30'::date, 'delivered', 0, 150, 'left', 'MARGILON SHAXAR', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 662 72 59')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0048');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1149, (11902000.0)/1, 0, 0, 11902000.0
FROM orders o WHERE o.code='L-2508-0048' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-30'::date, 11902000.0, 'UZS', 11902000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0048' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0049', (SELECT id FROM customers WHERE phone='+998 90 302 00 57' LIMIT 1), 'import', '2025-08-15'::date, '2025-10-29'::date, 'delivered', 0, 200, NULL, 'MARGILON SHAXAR', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 302 00 57')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0049');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (16564000.0)/1, 0, 0, 16564000.0
FROM orders o WHERE o.code='L-2508-0049' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-29'::date, 16564000.0, 'UZS', 16564000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0049' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0050', (SELECT id FROM customers WHERE phone='+998 93 490 50 02' LIMIT 1), 'import', '2025-08-15'::date, '2025-10-20'::date, 'delivered', 0, 200, NULL, 'TURAQURGON', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 490 50 02')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0050');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (16564000.0)/1, 0, 0, 16564000.0
FROM orders o WHERE o.code='L-2508-0050' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-20'::date, 16564000.0, 'UZS', 16564000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0050' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0051', (SELECT id FROM customers WHERE phone='+998 50 054 84 10' LIMIT 1), 'import', '2025-08-15'::date, '2025-10-24'::date, 'delivered', 0, 300, 'right', 'ANDIJON', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 054 84 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0051');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (12637000.0)/1, 0, 0, 12637000.0
FROM orders o WHERE o.code='L-2508-0051' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-24'::date, 12637000.0, 'UZS', 12637000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0051' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0052', (SELECT id FROM customers WHERE phone='+998 77 000 26 08' LIMIT 1), 'import', '2025-08-15'::date, '2025-10-29'::date, 'delivered', 0, 200, 'right', 'UZBEKISTON TUMANI', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 000 26 08')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0052');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1249, (15785000.0)/1, 0, 0, 15785000.0
FROM orders o WHERE o.code='L-2508-0052' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-29'::date, 15785000.0, 'UZS', 15785000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0052' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0053', (SELECT id FROM customers WHERE phone='+998 95 951 29 79' LIMIT 1), 'import', '2025-08-15'::date, '2025-10-23'::date, 'delivered', 0, 150, 'left', 'TURAQURGON', 0, 'Model (asl): BUNKER ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 951 29 79')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0053');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1299, (15932000.0)/1, 0, 0, 15932000.0
FROM orders o WHERE o.code='L-2508-0053' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-23'::date, 15932000.0, 'UZS', 15932000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0053' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0054', (SELECT id FROM customers WHERE phone='+998 99 972 14 45' LIMIT 1), 'import', '2025-08-15'::date, '2025-11-01'::date, 'delivered', 0, 200, NULL, 'Isboskan tuman', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 972 14 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0054');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (8064000.0)/1, 0, 0, 8064000.0
FROM orders o WHERE o.code='L-2508-0054' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-01'::date, 8064000.0, 'UZS', 8064000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0054' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0055', (SELECT id FROM customers WHERE phone='+998 91 914 24 44' LIMIT 1), 'import', '2025-08-15'::date, '2025-11-01'::date, 'delivered', 0, 300, NULL, 'Xiva tuman', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 914 24 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0055');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1499, (17462000.0)/1, 0, 0, 17462000.0
FROM orders o WHERE o.code='L-2508-0055' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-01'::date, 17462000.0, 'UZS', 17462000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0055' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0056', (SELECT id FROM customers WHERE phone='+998 93 100 52 41' LIMIT 1), 'import', '2025-08-15'::date, '2025-11-05'::date, 'delivered', 0, 300, 'left', 'Rishton', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 100 52 41')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0056');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1299, (15932000.0)/1, 0, 0, 15932000.0
FROM orders o WHERE o.code='L-2508-0056' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-05'::date, 15932000.0, 'UZS', 15932000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0056' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0057', (SELECT id FROM customers WHERE phone='+998 90 271 77 44' LIMIT 1), 'import', '2025-08-15'::date, '2025-12-16'::date, 'delivered', 0, 200, 'left', 'Rishton', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 271 77 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0057');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16564000.0)/1, 0, 0, 16564000.0
FROM orders o WHERE o.code='L-2508-0057' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-16'::date, 16564000.0, 'UZS', 16564000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0057' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0058', (SELECT id FROM customers WHERE phone='+998 88 662 72 59' LIMIT 1), 'import', '2025-08-15'::date, '2025-09-30'::date, 'delivered', 0, 150, 'right', 'Oltiariq', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 662 72 59')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0058');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1099, (11902000.0)/1, 0, 0, 11902000.0
FROM orders o WHERE o.code='L-2508-0058' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-30'::date, 11902000.0, 'UZS', 11902000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0058' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0059', (SELECT id FROM customers WHERE phone='+998 99 325 47 44' LIMIT 1), 'import', '2025-08-16'::date, '2025-10-18'::date, 'delivered', 0, 150, 'right', 'Asaka', 0, 'Model (asl): BUNKER 3 PRO, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 325 47 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0059');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1199, (14035000.0)/1, 0, 0, 14035000.0
FROM orders o WHERE o.code='L-2508-0059' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-18'::date, 14035000.0, 'UZS', 14035000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0059' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0060', (SELECT id FROM customers WHERE phone='+998 88 636 55 55' LIMIT 1), 'import', '2025-08-16'::date, '2025-10-21'::date, 'delivered', 0, 300, 'left', 'Namangan tumani', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 636 55 55')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0060');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (15202000.0)/1, 0, 0, 15202000.0
FROM orders o WHERE o.code='L-2508-0060' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-21'::date, 15202000.0, 'UZS', 15202000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0060' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0061', (SELECT id FROM customers WHERE phone='+998 98 558 77 84' LIMIT 1), 'import', '2025-08-18'::date, '2025-10-29'::date, 'delivered', 0, 200, 'right', 'uchkuprik', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 98 558 77 84')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0061');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (15767000.0)/1, 0, 0, 15767000.0
FROM orders o WHERE o.code='L-2508-0061' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-29'::date, 15767000.0, 'UZS', 15767000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0061' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0063', (SELECT id FROM customers WHERE phone='+998 97 812 65 66' LIMIT 1), 'import', '2025-08-20'::date, '2025-09-19'::date, 'delivered', 0, 200, 'right', 'Nurafshon qishlogi', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 812 65 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0063');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (16497000.0)/1, 0, 0, 16497000.0
FROM orders o WHERE o.code='L-2508-0063' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-19'::date, 16497000.0, 'UZS', 16497000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0063' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0064', (SELECT id FROM customers WHERE phone='+998 91 689 49 10' LIMIT 1), 'import', '2025-08-20'::date, '2025-09-26'::date, 'delivered', 0, 200, 'right', 'bogdod soy buyi', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 689 49 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0064');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (17099000.0)/1, 0, 0, 17099000.0
FROM orders o WHERE o.code='L-2508-0064' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-26'::date, 17099000.0, 'UZS', 17099000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0064' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0065', (SELECT id FROM customers WHERE phone='+998 91 313 17 71' LIMIT 1), 'import', '2025-08-21'::date, '2025-12-01'::date, 'delivered', 0, 200, 'left', 'Samarqand tuman', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 313 17 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0065');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16429000.0)/1, 0, 0, 16429000.0
FROM orders o WHERE o.code='L-2508-0065' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-01'::date, 16429000.0, 'UZS', 16429000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0065' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0066', (SELECT id FROM customers WHERE phone='+998 97 217 61 01' LIMIT 1), 'import', '2025-08-21'::date, '2025-10-22'::date, 'delivered', 0, 200, NULL, 'Namangan kosonsoy', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 217 61 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0066');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (17155000.0)/1, 0, 0, 17155000.0
FROM orders o WHERE o.code='L-2508-0066' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-22'::date, 17155000.0, 'UZS', 17155000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0066' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0067', (SELECT id FROM customers WHERE phone='+998 91 313 17 71' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-31'::date, 'delivered', 0, 300, 'right', 'Samarqand tuman', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 313 17 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0067');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1449, (17684000.0)/1, 0, 0, 17684000.0
FROM orders o WHERE o.code='L-2508-0067' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-31'::date, 17684000.0, 'UZS', 17684000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0067' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0068', (SELECT id FROM customers WHERE phone='+998 91 313 17 71' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-31'::date, 'delivered', 0, 300, 'left', 'Samarqand tuman', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 313 17 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0068');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1449, (17684000.0)/1, 0, 0, 17684000.0
FROM orders o WHERE o.code='L-2508-0068' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-31'::date, 17684000.0, 'UZS', 17684000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0068' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0069', (SELECT id FROM customers WHERE phone='+998 90 597 33 36' LIMIT 1), 'import', '2025-08-21'::date, '2025-10-17'::date, 'delivered', 0, 200, NULL, 'Namangan chortoq', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 597 33 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0069');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (16557000.0)/1, 0, 0, 16557000.0
FROM orders o WHERE o.code='L-2508-0069' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-17'::date, 16557000.0, 'UZS', 16557000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0069' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0070', (SELECT id FROM customers WHERE phone='+998 94 301 04 40' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-28'::date, 'delivered', 0, 300, 'left', 'Qashqar qishlogi', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 301 04 40')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0070');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (17992000.0)/1, 0, 0, 17992000.0
FROM orders o WHERE o.code='L-2508-0070' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-28'::date, 17992000.0, 'UZS', 17992000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0070' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0072', (SELECT id FROM customers WHERE phone='+998 91 201 83 00' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-15'::date, 'delivered', 0, 200, 'right', 'o''zbekston tumani', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 201 83 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0072');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (14419000.0)/1, 0, 0, 14419000.0
FROM orders o WHERE o.code='L-2508-0072' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-15'::date, 14419000.0, 'UZS', 14419000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0072' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0073', (SELECT id FROM customers WHERE phone='+998 91 140 46 02' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-11'::date, 'delivered', 0, 200, 'right', 'o''zbekston tumani', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 140 46 02')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0073');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15674000.0)/1, 0, 0, 15674000.0
FROM orders o WHERE o.code='L-2508-0073' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-11'::date, 15674000.0, 'UZS', 15674000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0073' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0074', (SELECT id FROM customers WHERE phone='+998 93 403 04 43' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-31'::date, 'delivered', 0, 200, 'left', 'namanagan', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 403 04 43')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0074');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16429000.0)/1, 0, 0, 16429000.0
FROM orders o WHERE o.code='L-2508-0074' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-31'::date, 16429000.0, 'UZS', 16429000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0074' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0075', (SELECT id FROM customers WHERE phone='+998 97 187 53 03' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-19'::date, 'delivered', 0, 200, 'right', 'namanagan', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 187 53 03')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0075');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1199, (14547000.0)/1, 0, 0, 14547000.0
FROM orders o WHERE o.code='L-2508-0075' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-19'::date, 14547000.0, 'UZS', 14547000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0075' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0076', (SELECT id FROM customers WHERE phone='+998 97 418 20 22' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-29'::date, 'delivered', 0, 200, 'left', 'beshariq', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 418 20 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0076');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16429000.0)/1, 0, 0, 16429000.0
FROM orders o WHERE o.code='L-2508-0076' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-29'::date, 16429000.0, 'UZS', 16429000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0076' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0077', (SELECT id FROM customers WHERE phone='+998 95 165 27 77' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-10'::date, 'delivered', 0, 200, 'left', 'uchkuprik', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 165 27 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0077');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (15929000.0)/1, 0, 0, 15929000.0
FROM orders o WHERE o.code='L-2508-0077' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-10'::date, 15929000.0, 'UZS', 15929000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0077' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0078', (SELECT id FROM customers WHERE phone='+998 94 644 15 61' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-13'::date, 'delivered', 0, 300, 'right', 'samarqand kattaqurgon', 0, 'Model (asl): BUNKER ULTRA, 300 kvm | arston 52 L', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 644 15 61')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0078');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1681, (18096000.0)/1, 0, 0, 18096000.0
FROM orders o WHERE o.code='L-2508-0078' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-13'::date, 18096000.0, 'UZS', 18096000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0078' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0079', (SELECT id FROM customers WHERE phone='+998 94 155 67 65' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-10'::date, 'delivered', 0, 150, 'right', 'NAMANGAN UYCHI', 0, 'Model (asl): BUNKER ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 155 67 65')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0079');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (3000000.0)/1, 0, 0, 3000000.0
FROM orders o WHERE o.code='L-2508-0079' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-10'::date, 3000000.0, 'UZS', 3000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0079' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0080', (SELECT id FROM customers WHERE phone='+998 93 651 78 00' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-23'::date, 'delivered', 0, 150, 'right', 'ANDIJON ASAKA', 0, 'Model (asl): BUNKER ULTRA, 150 kvm | YPS ACUM DIMHOD', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 651 78 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0080');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1884, (16026000.0)/1, 0, 0, 16026000.0
FROM orders o WHERE o.code='L-2508-0080' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-23'::date, 16026000.0, 'UZS', 16026000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0080' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0082', (SELECT id FROM customers WHERE phone='+998 91 360 62 00' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-10'::date, 'delivered', 0, 200, 'left', 'NAMANGAN SHAXAR', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 360 62 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0082');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (15174000.0)/1, 0, 0, 15174000.0
FROM orders o WHERE o.code='L-2508-0082' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-10'::date, 15174000.0, 'UZS', 15174000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0082' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0084', (SELECT id FROM customers WHERE phone='+998 91 563 04 04' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-22'::date, 'delivered', 0, 150, 'right', 'Margilon', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 563 04 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0084');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1099, (13792000.0)/1, 0, 0, 13792000.0
FROM orders o WHERE o.code='L-2508-0084' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-22'::date, 13792000.0, 'UZS', 13792000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0084' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0085', (SELECT id FROM customers WHERE phone='+998 97 640 27 27' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-12'::date, 'delivered', 0, 200, 'right', 'Margilon', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 640 27 27')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0085');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15674000.0)/1, 0, 0, 15674000.0
FROM orders o WHERE o.code='L-2508-0085' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-12'::date, 15674000.0, 'UZS', 15674000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0085' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0086', (SELECT id FROM customers WHERE phone='+998 91 601 00 11' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-05'::date, 'delivered', 0, 200, 'left', 'Andijon', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 601 00 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0086');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16429000.0)/1, 0, 0, 16429000.0
FROM orders o WHERE o.code='L-2508-0086' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-05'::date, 16429000.0, 'UZS', 16429000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0086' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0087', (SELECT id FROM customers WHERE phone='+998 33 266 80 07' LIMIT 1), 'import', '2025-08-22'::date, '2025-11-20'::date, 'delivered', 0, 200, 'left', 'Rishton', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 266 80 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0087');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (15274000.0)/1, 0, 0, 15274000.0
FROM orders o WHERE o.code='L-2508-0087' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-20'::date, 15274000.0, 'UZS', 15274000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0087' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0088', (SELECT id FROM customers WHERE phone='+998 95 141 00 89' LIMIT 1), 'import', '2025-08-22'::date, '2025-10-31'::date, 'delivered', 0, 300, NULL, 'Chust tumani', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 141 00 89')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0088');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15047000.0)/1, 0, 0, 15047000.0
FROM orders o WHERE o.code='L-2508-0088' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-31'::date, 15047000.0, 'UZS', 15047000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0088' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0094', (SELECT id FROM customers WHERE phone='+998 93 258 44 86' LIMIT 1), 'import', '2025-08-26'::date, '2025-11-17'::date, 'delivered', 0, 200, 'left', 'Namangan norin', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 258 44 86')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0094');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16847000.0)/1, 0, 0, 16847000.0
FROM orders o WHERE o.code='L-2508-0094' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-17'::date, 16847000.0, 'UZS', 16847000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0094' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0095', (SELECT id FROM customers WHERE phone='+998 93 258 44 86' LIMIT 1), 'import', '2025-08-26'::date, '2025-11-18'::date, 'delivered', 0, 200, 'left', 'Namangan norin', 0, 'Model (asl): BUNKER ULTRA, 200 kvm | turba 4*1', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 258 44 86')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0095');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16847000.0)/1, 0, 0, 16847000.0
FROM orders o WHERE o.code='L-2508-0095' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-18'::date, 16847000.0, 'UZS', 16847000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0095' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0096', (SELECT id FROM customers WHERE phone='+998 93 403 77 04' LIMIT 1), 'import', '2025-08-26'::date, '2025-11-18'::date, 'delivered', 0, 200, 'left', 'Namangan norin', 0, 'Model (asl): BUNKER ULTRA, 200 kvm | turba 4*1', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 403 77 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0096');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16847000.0)/1, 0, 0, 16847000.0
FROM orders o WHERE o.code='L-2508-0096' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-18'::date, 16847000.0, 'UZS', 16847000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0096' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0097', (SELECT id FROM customers WHERE phone='+998 93 432 17 05' LIMIT 1), 'import', '2025-08-27'::date, '2025-11-20'::date, 'delivered', 0, 200, 'left', 'Navoi Konimex', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 432 17 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0097');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16959000.0)/1, 0, 0, 16959000.0
FROM orders o WHERE o.code='L-2508-0097' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-20'::date, 16959000.0, 'UZS', 16959000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0097' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0098', (SELECT id FROM customers WHERE phone='+998 93 432 17 05' LIMIT 1), 'import', '2025-08-27'::date, '2025-11-20'::date, 'delivered', 0, 200, 'right', 'Navoi Konimex', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 432 17 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0098');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (16959000.0)/1, 0, 0, 16959000.0
FROM orders o WHERE o.code='L-2508-0098' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-20'::date, 16959000.0, 'UZS', 16959000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0098' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0099', (SELECT id FROM customers WHERE phone='+998 93 510 73 10' LIMIT 1), 'import', '2025-08-27'::date, '2025-11-25'::date, 'delivered', 0, 200, 'left', 'Namangan', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 510 73 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0099');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16211000.0)/1, 0, 0, 16211000.0
FROM orders o WHERE o.code='L-2508-0099' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-25'::date, 16211000.0, 'UZS', 16211000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0099' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0101', (SELECT id FROM customers WHERE phone='+998 95 973 01 50' LIMIT 1), 'import', '2025-08-28'::date, '2025-11-01'::date, 'delivered', 0, 150, 'left', 'Namangan', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 973 01 50')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0101');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1149, (5634000.0)/1, 0, 0, 5634000.0
FROM orders o WHERE o.code='L-2508-0101' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-01'::date, 5634000.0, 'UZS', 5634000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0101' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0102', (SELECT id FROM customers WHERE phone='+998 90 308 95 05' LIMIT 1), 'import', '2025-08-28'::date, '2025-11-05'::date, 'delivered', 0, 150, 'right', 'Yoyilma uchkoprik', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 308 95 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0102');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1099, (1400000.0)/1, 0, 0, 1400000.0
FROM orders o WHERE o.code='L-2508-0102' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-05'::date, 1400000.0, 'UZS', 1400000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0102' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0103', (SELECT id FROM customers WHERE phone='+998 99 393 92 92' LIMIT 1), 'import', '2025-08-29'::date, '2025-11-04'::date, 'delivered', 0, 200, 'left', 'Namangan Norin', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 393 92 92')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0103');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16429000.0)/1, 0, 0, 16429000.0
FROM orders o WHERE o.code='L-2508-0103' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-04'::date, 16429000.0, 'UZS', 16429000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0103' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0104', (SELECT id FROM customers WHERE phone='+998 88 999 87 81' LIMIT 1), 'import', '2025-08-29'::date, '2025-09-14'::date, 'delivered', 0, 200, 'left', 'ANDIJON BALIQCHI', 0, 'Model (asl): BUNKER ULTRA, 200 kvm | UP 2 KL AUM', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 999 87 81')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0104');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16835000.0)/1, 0, 0, 16835000.0
FROM orders o WHERE o.code='L-2508-0104' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-14'::date, 16835000.0, 'UZS', 16835000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0104' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0106', (SELECT id FROM customers WHERE phone='+998 91 563 04 04' LIMIT 1), 'import', '2025-08-29'::date, '2025-11-13'::date, 'delivered', 0, 150, 'right', 'Marg''ilon', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 563 04 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0106');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1099, (8772000.0)/1, 0, 0, 8772000.0
FROM orders o WHERE o.code='L-2508-0106' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-13'::date, 8772000.0, 'UZS', 8772000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0106' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0107', (SELECT id FROM customers WHERE phone='+998 91 563 04 04' LIMIT 1), 'import', '2025-08-29'::date, '2025-11-13'::date, 'delivered', 0, 150, 'left', 'Marg''ilon', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 563 04 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0107');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1099, (8772000.0)/1, 0, 0, 8772000.0
FROM orders o WHERE o.code='L-2508-0107' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-13'::date, 8772000.0, 'UZS', 8772000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0107' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0108', (SELECT id FROM customers WHERE phone='+996 552233360' LIMIT 1), 'import', '2025-08-29'::date, '2025-10-28'::date, 'delivered', 0, 300, 'right', 'QIRGIZISTON OSH', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+996 552233360')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0108');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (18707000.0)/1, 0, 0, 18707000.0
FROM orders o WHERE o.code='L-2508-0108' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-28'::date, 18707000.0, 'UZS', 18707000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0108' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0109', (SELECT id FROM customers WHERE phone='+996 558808071' LIMIT 1), 'import', '2025-08-29'::date, '2025-10-28'::date, 'delivered', 0, 300, 'right', 'QIRGIZISTON OSH', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+996 558808071')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0109');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (18707000.0)/1, 0, 0, 18707000.0
FROM orders o WHERE o.code='L-2508-0109' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-28'::date, 18707000.0, 'UZS', 18707000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0109' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0110', (SELECT id FROM customers WHERE phone='+996 558808071' LIMIT 1), 'import', '2025-08-29'::date, '2025-10-28'::date, 'delivered', 0, 300, 'left', 'QIRGIZISTON OSH', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+996 558808071')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0110');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (18707000.0)/1, 0, 0, 18707000.0
FROM orders o WHERE o.code='L-2508-0110' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-28'::date, 18707000.0, 'UZS', 18707000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0110' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0111', (SELECT id FROM customers WHERE phone='+998 91 176 75 79' LIMIT 1), 'import', '2025-08-29'::date, '2025-11-15'::date, 'delivered', 0, 150, 'right', 'Andijon Buloqboshi', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 176 75 79')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0111');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1099, (12489000.0)/1, 0, 0, 12489000.0
FROM orders o WHERE o.code='L-2508-0111' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-15'::date, 12489000.0, 'UZS', 12489000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0111' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0114', (SELECT id FROM customers WHERE phone='+998 99 138 26 68' LIMIT 1), 'import', '2025-08-30'::date, '2025-11-11'::date, 'delivered', 0, 300, 'right', 'Andijon Xonobod', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 138 26 68')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0114');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1549, (18862000.0)/1, 0, 0, 18862000.0
FROM orders o WHERE o.code='L-2508-0114' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-11'::date, 18862000.0, 'UZS', 18862000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0114' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0115', (SELECT id FROM customers WHERE phone='+998 94 376 00 04' LIMIT 1), 'import', '2025-08-30'::date, '2025-12-05'::date, 'delivered', 0, 300, 'left', 'olmaliq', 0, 'Model (asl): BUNKER 4, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 376 00 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0115');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1529, (673000.0)/1, 0, 0, 673000.0
FROM orders o WHERE o.code='L-2508-0115' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-05'::date, 673000.0, 'UZS', 673000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0115' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2508-0121', (SELECT id FROM customers WHERE phone='+998 91 652 35 45' LIMIT 1), 'import', '2025-08-31'::date, '2025-09-08'::date, 'delivered', 0, 300, 'left', 'MARGILON magazin', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2508-0121');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (16767000.0)/1, 0, 0, 16767000.0
FROM orders o WHERE o.code='L-2508-0121' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-08'::date, 16767000.0, 'UZS', 16767000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2508-0121' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0002', (SELECT id FROM customers WHERE phone='+998 99 507 80 05' LIMIT 1), 'import', '2025-09-01'::date, '2025-11-05'::date, 'delivered', 0, 300, 'left', 'XORAZM diller', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 507 80 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16902000.0)/1, 0, 0, 16902000.0
FROM orders o WHERE o.code='L-2509-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-05'::date, 16902000.0, 'UZS', 16902000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0003', (SELECT id FROM customers WHERE phone='+998 99 507 80 05' LIMIT 1), 'import', '2025-09-01'::date, '2025-11-05'::date, 'delivered', 0, 200, 'left', 'XORAZM diller', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 507 80 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (15649000.0)/1, 0, 0, 15649000.0
FROM orders o WHERE o.code='L-2509-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-05'::date, 15649000.0, 'UZS', 15649000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0004', (SELECT id FROM customers WHERE phone='+998 94 311 91 90' LIMIT 1), 'import', '2025-09-01'::date, '2025-11-21'::date, 'delivered', 0, 200, 'left', 'Fargona qushtepa', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 311 91 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (15774000.0)/1, 0, 0, 15774000.0
FROM orders o WHERE o.code='L-2509-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-21'::date, 15774000.0, 'UZS', 15774000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0007', (SELECT id FROM customers WHERE phone='+998 91 652 35 45' LIMIT 1), 'import', '2025-09-02'::date, '2025-09-22'::date, 'delivered', 0, 200, 'right', 'MARGILON magazin', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (15714490.0)/1, 0, 0, 15714490.0
FROM orders o WHERE o.code='L-2509-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-22'::date, 15714490.0, 'UZS', 15714490.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0009', (SELECT id FROM customers WHERE phone='+998 91 652 35 45' LIMIT 1), 'import', '2025-09-02'::date, '2025-09-22'::date, 'delivered', 0, 300, 'left', 'MARGILON magazin', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1549, (17590000.0)/1, 0, 0, 17590000.0
FROM orders o WHERE o.code='L-2509-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-22'::date, 17590000.0, 'UZS', 17590000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0010', (SELECT id FROM customers WHERE phone='+998 91 652 35 45' LIMIT 1), 'import', '2025-09-02'::date, '2025-10-05'::date, 'delivered', 0, 400, 'left', 'MARGILON magazin', 0, 'Model (asl): BUNKER ULTRA, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1699, (19467490.0)/1, 0, 0, 19467490.0
FROM orders o WHERE o.code='L-2509-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-05'::date, 19467490.0, 'UZS', 19467490.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0011', (SELECT id FROM customers WHERE phone='+998 91 652 35 45' LIMIT 1), 'import', '2025-09-02'::date, '2025-10-24'::date, 'delivered', 0, 400, 'right', 'MARGILON magazin', 0, 'Model (asl): BUNKER ULTRA, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1699, (19467490.0)/1, 0, 0, 19467490.0
FROM orders o WHERE o.code='L-2509-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-24'::date, 19467490.0, 'UZS', 19467490.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0012', (SELECT id FROM customers WHERE phone='+998 91 652 35 45' LIMIT 1), 'import', '2025-09-02'::date, '2025-10-29'::date, 'delivered', 0, 500, 'right', 'MARGILON magazin', 0, 'Model (asl): BUNKER ULTRA, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1749, (20092990.0)/1, 0, 0, 20092990.0
FROM orders o WHERE o.code='L-2509-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-29'::date, 20092990.0, 'UZS', 20092990.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0013', (SELECT id FROM customers WHERE phone='+998 97 583 01 23' LIMIT 1), 'import', '2025-09-03'::date, '2025-11-24'::date, 'delivered', 0, 200, 'left', 'ASAKA SHAHAR', 0, 'Model (asl): BUNKER PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 583 01 23')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (14507000.0)/1, 0, 0, 14507000.0
FROM orders o WHERE o.code='L-2509-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-24'::date, 14507000.0, 'UZS', 14507000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0014', (SELECT id FROM customers WHERE phone='+998 97 353 72 63' LIMIT 1), 'import', '2025-09-05'::date, '2025-11-24'::date, 'delivered', 0, 300, 'right', 'Qoraqolpog''iston', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 353 72 63')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (1843000.0)/1, 0, 0, 1843000.0
FROM orders o WHERE o.code='L-2509-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-24'::date, 1843000.0, 'UZS', 1843000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0015', (SELECT id FROM customers WHERE phone='+998 91 652 35 45' LIMIT 1), 'import', '2025-09-05'::date, '2025-09-22'::date, 'delivered', 0, 150, 'right', 'MARGILON magazin', 0, 'Model (asl): BUNKER PRO, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1149, (13562000.0)/1, 0, 0, 13562000.0
FROM orders o WHERE o.code='L-2509-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-22'::date, 13562000.0, 'UZS', 13562000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0016', (SELECT id FROM customers WHERE phone='+998 90 278 25 32' LIMIT 1), 'import', '2025-09-05'::date, '2025-11-26'::date, 'delivered', 0, 300, 'left', 'Namangan shahar', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 278 25 32')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (17997000.0)/1, 0, 0, 17997000.0
FROM orders o WHERE o.code='L-2509-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-26'::date, 17997000.0, 'UZS', 17997000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0017', (SELECT id FROM customers WHERE phone='+998 33 557 46 54' LIMIT 1), 'import', '2025-09-05'::date, '2025-11-22'::date, 'delivered', 0, 200, 'left', 'xorazim bogdod tumani', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 557 46 54')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (15862000.0)/1, 0, 0, 15862000.0
FROM orders o WHERE o.code='L-2509-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-22'::date, 15862000.0, 'UZS', 15862000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0018', (SELECT id FROM customers WHERE phone='+998 91 157 61 61' LIMIT 1), 'import', '2025-09-05'::date, '2025-11-18'::date, 'delivered', 0, 300, 'right', 'rishton tumani', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 157 61 61')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (17737000.0)/1, 0, 0, 17737000.0
FROM orders o WHERE o.code='L-2509-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-18'::date, 17737000.0, 'UZS', 17737000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0019', (SELECT id FROM customers WHERE phone='+998 94 279 00 18' LIMIT 1), 'import', '2025-09-05'::date, '2025-11-08'::date, 'delivered', 0, 500, NULL, 'Namangan shahar', 0, 'Model (asl): BUNKER 3 PRO, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 279 00 18')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0019');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1649, (20112000.0)/1, 0, 0, 20112000.0
FROM orders o WHERE o.code='L-2509-0019' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-08'::date, 20112000.0, 'UZS', 20112000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0019' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0020', (SELECT id FROM customers WHERE phone='+998 93 243 19 19' LIMIT 1), 'import', '2025-09-05'::date, '2025-11-25'::date, 'delivered', 0, 200, 'left', 'Andijon Paxtobod', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 243 19 19')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (14862000.0)/1, 0, 0, 14862000.0
FROM orders o WHERE o.code='L-2509-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-25'::date, 14862000.0, 'UZS', 14862000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0021', (SELECT id FROM customers WHERE phone='+998 99 749 23 96' LIMIT 1), 'import', '2025-09-05'::date, '2025-11-11'::date, 'delivered', 0, 150, 'left', 'Buxoro', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 749 23 96')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1099, (12737000.0)/1, 0, 0, 12737000.0
FROM orders o WHERE o.code='L-2509-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-11'::date, 12737000.0, 'UZS', 12737000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0022', (SELECT id FROM customers WHERE phone='+998 88 277 55 90' LIMIT 1), 'import', '2025-09-06'::date, '2025-11-22'::date, 'delivered', 0, 200, 'right', 'Namangan Uychi', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 277 55 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (16599000.0)/1, 0, 0, 16599000.0
FROM orders o WHERE o.code='L-2509-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-22'::date, 16599000.0, 'UZS', 16599000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0023', (SELECT id FROM customers WHERE phone='+998 99 326 63 48' LIMIT 1), 'import', '2025-09-08'::date, '2025-10-16'::date, 'delivered', 0, 200, NULL, 'Sux tumani', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 326 63 48')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (10515000.0)/1, 0, 0, 10515000.0
FROM orders o WHERE o.code='L-2509-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-16'::date, 10515000.0, 'UZS', 10515000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0023' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0024', (SELECT id FROM customers WHERE phone='+998 93 731 81 89' LIMIT 1), 'import', '2025-09-08'::date, '2025-11-29'::date, 'delivered', 0, 150, 'left', 'Andijon Xujabod', 0, 'Model (asl): BUNKER 4, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 731 81 89')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0024');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16945000.0)/1, 0, 0, 16945000.0
FROM orders o WHERE o.code='L-2509-0024' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-29'::date, 16945000.0, 'UZS', 16945000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0024' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0025', (SELECT id FROM customers WHERE phone='+998 91 290 67 77' LIMIT 1), 'import', '2025-09-09'::date, '2025-11-29'::date, 'delivered', 0, 200, 'right', 'Andijon Qorasuv', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 290 67 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (16417000.0)/1, 0, 0, 16417000.0
FROM orders o WHERE o.code='L-2509-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-29'::date, 16417000.0, 'UZS', 16417000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0026', (SELECT id FROM customers WHERE phone='+998 88 177 46 00' LIMIT 1), 'import', '2025-09-10'::date, '2025-11-25'::date, 'delivered', 0, 300, 'right', 'Buloqboshi', 0, 'Model (asl): BUNKER 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 177 46 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0026');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (10727000.0)/1, 0, 0, 10727000.0
FROM orders o WHERE o.code='L-2509-0026' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-25'::date, 10727000.0, 'UZS', 10727000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0026' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0027', (SELECT id FROM customers WHERE phone='+998 94 387 50 43' LIMIT 1), 'import', '2025-09-10'::date, '2025-11-10'::date, 'delivered', 0, 200, NULL, 'Andijon Marxamat', 0, 'Model (asl): BUNKER ULTRA, 200 kvm | 10 noyabr vada', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 387 50 43')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0027');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (15347000.0)/1, 0, 0, 15347000.0
FROM orders o WHERE o.code='L-2509-0027' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-10'::date, 15347000.0, 'UZS', 15347000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0027' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0028', (SELECT id FROM customers WHERE phone='+992 920147000' LIMIT 1), 'import', '2025-09-11'::date, '2025-11-08'::date, 'delivered', 0, 300, 'left', 'tojikiston spitamen', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+992 920147000')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0028');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (17361500.0)/1, 0, 0, 17361500.0
FROM orders o WHERE o.code='L-2509-0028' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-08'::date, 17361500.0, 'UZS', 17361500.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0028' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0029', (SELECT id FROM customers WHERE phone='+992 920147000' LIMIT 1), 'import', '2025-09-11'::date, '2025-11-08'::date, 'delivered', 0, 300, 'left', 'tojikiston spitamen', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+992 920147000')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0029');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (17361500.0)/1, 0, 0, 17361500.0
FROM orders o WHERE o.code='L-2509-0029' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-08'::date, 17361500.0, 'UZS', 17361500.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0029' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0030', (SELECT id FROM customers WHERE phone='+998 99 325 47 44' LIMIT 1), 'import', '2025-09-11'::date, '2025-11-26'::date, 'delivered', 0, 200, NULL, 'Asaka', 0, 'Model (asl): BUNKER ULTRA, 200 kvm | 3 tasi 1 ta ketadi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 325 47 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0030');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (15208000.0)/1, 0, 0, 15208000.0
FROM orders o WHERE o.code='L-2509-0030' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-26'::date, 15208000.0, 'UZS', 15208000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0030' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0032', (SELECT id FROM customers WHERE phone='+992 988802575' LIMIT 1), 'import', '2025-09-12'::date, '2025-10-25'::date, 'delivered', 0, 300, 'left', 'TOJIKSTON USTA RAVSHAN', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+992 988802575')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0032');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (6212000.0)/1, 0, 0, 6212000.0
FROM orders o WHERE o.code='L-2509-0032' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-25'::date, 6212000.0, 'UZS', 6212000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0032' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0033', (SELECT id FROM customers WHERE phone='+998 88 107 50 53' LIMIT 1), 'import', '2025-09-12'::date, '2025-12-06'::date, 'delivered', 0, 200, 'right', 'SAMARQAND SHAXAR', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 107 50 53')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0033');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1249, (15672000.0)/1, 0, 0, 15672000.0
FROM orders o WHERE o.code='L-2509-0033' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-06'::date, 15672000.0, 'UZS', 15672000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0033' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0034', (SELECT id FROM customers WHERE phone='+998 95 707 14 90' LIMIT 1), 'import', '2025-09-12'::date, '2025-11-30'::date, 'delivered', 0, 200, NULL, 'NAMANGAN', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 707 14 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0034');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (15550000.0)/1, 0, 0, 15550000.0
FROM orders o WHERE o.code='L-2509-0034' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-30'::date, 15550000.0, 'UZS', 15550000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0034' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0035', (SELECT id FROM customers WHERE phone='+998 95 212 05 05' LIMIT 1), 'import', '2025-09-12'::date, '2025-12-03'::date, 'delivered', 0, 500, 'right', 'XORAZIM YANGI BOZOR TUMANI', 0, 'Model (asl): BUNKER 4, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 212 05 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0035');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1689, (20028000.0)/1, 0, 0, 20028000.0
FROM orders o WHERE o.code='L-2509-0035' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-03'::date, 20028000.0, 'UZS', 20028000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0035' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0036', (SELECT id FROM customers WHERE phone='+998 97 280 87 90' LIMIT 1), 'import', '2025-09-12'::date, '2025-11-28'::date, 'delivered', 0, 300, 'right', 'Buxoro Jondor', 0, 'Model (asl): BUNKER 3 PRO, 300 kvm | keladi uzi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 280 87 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0036');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (16175000.0)/1, 0, 0, 16175000.0
FROM orders o WHERE o.code='L-2509-0036' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-28'::date, 16175000.0, 'UZS', 16175000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0036' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0037', (SELECT id FROM customers WHERE phone='+996 555655255' LIMIT 1), 'import', '2025-09-12'::date, '2025-09-24'::date, 'delivered', 0, 200, NULL, 'Qirgisizton', 0, 'Model (asl): BUNKER 3 PRO, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+996 555655255')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0037');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1330, (16558000.0)/1, 0, 0, 16558000.0
FROM orders o WHERE o.code='L-2509-0037' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-09-24'::date, 16558000.0, 'UZS', 16558000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0037' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0038', (SELECT id FROM customers WHERE phone='+998 94 953 94 94' LIMIT 1), 'import', '2025-09-12'::date, '2025-12-02'::date, 'delivered', 0, 150, 'left', 'NAMANGAN', 0, 'Model (asl): BUNKER ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 953 94 94')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0038');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (14378000.0)/1, 0, 0, 14378000.0
FROM orders o WHERE o.code='L-2509-0038' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-02'::date, 14378000.0, 'UZS', 14378000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0038' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0039', (SELECT id FROM customers WHERE phone='+998 97 615 00 11' LIMIT 1), 'import', '2025-09-12'::date, '2025-11-28'::date, 'delivered', 0, 200, 'left', 'Samarqand toyloq', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 615 00 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0039');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (15795000.0)/1, 0, 0, 15795000.0
FROM orders o WHERE o.code='L-2509-0039' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-28'::date, 15795000.0, 'UZS', 15795000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0039' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0040', (SELECT id FROM customers WHERE phone='+998 91 785 95 95' LIMIT 1), 'import', '2025-09-14'::date, '2025-10-11'::date, 'delivered', 0, 200, 'right', 'Uchkuprik', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 785 95 95')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0040');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (17389000.0)/1, 0, 0, 17389000.0
FROM orders o WHERE o.code='L-2509-0040' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-11'::date, 17389000.0, 'UZS', 17389000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0040' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0041', (SELECT id FROM customers WHERE phone='+998 93 206 98 83' LIMIT 1), 'import', '2025-09-16'::date, '2025-12-01'::date, 'delivered', 0, 150, 'left', 'Fargona', 0, 'Model (asl): BUNKER 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 206 98 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0041');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1099, (12605000.0)/1, 0, 0, 12605000.0
FROM orders o WHERE o.code='L-2509-0041' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-01'::date, 12605000.0, 'UZS', 12605000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0041' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0043', (SELECT id FROM customers WHERE phone='+998 93 260 32 22' LIMIT 1), 'import', '2025-09-17'::date, '2025-10-05'::date, 'delivered', 0, 200, 'left', 'namangan codak', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 260 32 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0043');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (17277000.0)/1, 0, 0, 17277000.0
FROM orders o WHERE o.code='L-2509-0043' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-05'::date, 17277000.0, 'UZS', 17277000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0043' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0045', (SELECT id FROM customers WHERE phone='+998 99 327 30 92' LIMIT 1), 'import', '2025-09-17'::date, '2025-11-05'::date, 'delivered', 0, 200, 'left', 'margilon toshloq', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 327 30 92')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0045');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (15000000.0)/1, 0, 0, 15000000.0
FROM orders o WHERE o.code='L-2509-0045' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-05'::date, 15000000.0, 'UZS', 15000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0045' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0046', (SELECT id FROM customers WHERE phone='+998 93 442 22 45' LIMIT 1), 'import', '2025-09-17'::date, '2025-11-24'::date, 'delivered', 0, 200, 'left', 'Namangan', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 442 22 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0046');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16777000.0)/1, 0, 0, 16777000.0
FROM orders o WHERE o.code='L-2509-0046' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-24'::date, 16777000.0, 'UZS', 16777000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0046' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0047', (SELECT id FROM customers WHERE phone='+998 91 176 15 40' LIMIT 1), 'import', '2025-09-18'::date, '2025-12-05'::date, 'delivered', 0, 200, 'right', 'andijon', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 176 15 40')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0047');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (14277000.0)/1, 0, 0, 14277000.0
FROM orders o WHERE o.code='L-2509-0047' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-05'::date, 14277000.0, 'UZS', 14277000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0047' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0048', (SELECT id FROM customers WHERE phone='+998 91 176 15 40' LIMIT 1), 'import', '2025-09-18'::date, '2025-12-05'::date, 'delivered', 0, 200, 'left', 'andijon', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 176 15 40')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0048');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (14277000.0)/1, 0, 0, 14277000.0
FROM orders o WHERE o.code='L-2509-0048' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-05'::date, 14277000.0, 'UZS', 14277000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0048' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0050', (SELECT id FROM customers WHERE phone='+998 94 310 92 29' LIMIT 1), 'import', '2025-09-19'::date, '2025-12-03'::date, 'delivered', 0, 200, 'left', 'Margilon', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 310 92 29')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0050');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (14000000.0)/1, 0, 0, 14000000.0
FROM orders o WHERE o.code='L-2509-0050' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-03'::date, 14000000.0, 'UZS', 14000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0050' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0051', (SELECT id FROM customers WHERE phone='+998 97 582 00 04' LIMIT 1), 'import', '2025-09-19'::date, '2025-12-09'::date, 'delivered', 0, 200, 'right', 'andijon qurgontepa', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 582 00 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0051');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (14714000.0)/1, 0, 0, 14714000.0
FROM orders o WHERE o.code='L-2509-0051' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-09'::date, 14714000.0, 'UZS', 14714000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0051' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0055', (SELECT id FROM customers WHERE phone='+998 93 913 70 17' LIMIT 1), 'import', '2025-09-19'::date, '2025-12-01'::date, 'delivered', 0, 200, NULL, 'Namangan', 0, 'Model (asl): BUNKER 4, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 913 70 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0055');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (16000000.0)/1, 0, 0, 16000000.0
FROM orders o WHERE o.code='L-2509-0055' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-01'::date, 16000000.0, 'UZS', 16000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0055' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0056', (SELECT id FROM customers WHERE phone='+998 88 956 00 05' LIMIT 1), 'import', '2025-09-19'::date, '2025-12-02'::date, 'delivered', 0, 300, 'left', 'Beshariq', 0, 'Model (asl): BUNKER 3 PRO, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 956 00 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0056');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (15687000.0)/1, 0, 0, 15687000.0
FROM orders o WHERE o.code='L-2509-0056' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-02'::date, 15687000.0, 'UZS', 15687000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0056' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0057', (SELECT id FROM customers WHERE phone='+998 90 407 39 34' LIMIT 1), 'import', '2025-09-19'::date, '2025-12-06'::date, 'delivered', 0, 200, NULL, 'Margilon', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 407 39 34')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0057');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (15687000.0)/1, 0, 0, 15687000.0
FROM orders o WHERE o.code='L-2509-0057' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-06'::date, 15687000.0, 'UZS', 15687000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0057' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0058', (SELECT id FROM customers WHERE phone='+998 91 313 17 71' LIMIT 1), 'import', '2025-09-19'::date, '2025-10-31'::date, 'delivered', 0, 200, 'left', 'Samarqand', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 313 17 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0058');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16187000.0)/1, 0, 0, 16187000.0
FROM orders o WHERE o.code='L-2509-0058' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-31'::date, 16187000.0, 'UZS', 16187000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0058' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0059', (SELECT id FROM customers WHERE phone='+998 94 108 00 07' LIMIT 1), 'import', '2025-09-20'::date, '2025-12-02'::date, 'delivered', 0, 200, NULL, 'Namangan Norin', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 108 00 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0059');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (16087000.0)/1, 0, 0, 16087000.0
FROM orders o WHERE o.code='L-2509-0059' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-02'::date, 16087000.0, 'UZS', 16087000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0059' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0061', (SELECT id FROM customers WHERE phone='+998 94 135 03 81' LIMIT 1), 'import', '2025-09-22'::date, '2025-11-05'::date, 'delivered', 0, 300, 'right', 'KOTTA TURK', 0, 'Model (asl): BUNKER ULTRA, 300 kvm | SERVIS XIZMATI', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 135 03 81')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0061');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1549, (1000000.0)/1, 0, 0, 1000000.0
FROM orders o WHERE o.code='L-2509-0061' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-05'::date, 1000000.0, 'UZS', 1000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0061' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0063', (SELECT id FROM customers WHERE phone='+998 97 211 17 17' LIMIT 1), 'import', '2025-09-24'::date, '2025-10-22'::date, 'delivered', 0, 400, 'right', 'Namangan', 0, 'Model (asl): BUNKER magnum, 400 kvm | 15 kun muddat', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 211 17 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0063');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER magnum') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER magnum') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1899, (23167000.0)/1, 0, 0, 23167000.0
FROM orders o WHERE o.code='L-2509-0063' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-22'::date, 23167000.0, 'UZS', 23167000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0063' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0064', (SELECT id FROM customers WHERE phone='+998 97 520 19 90' LIMIT 1), 'import', '2025-09-24'::date, '2025-10-08'::date, 'delivered', 0, 200, 'left', 'Namangan', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 520 19 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0064');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (17109000.0)/1, 0, 0, 17109000.0
FROM orders o WHERE o.code='L-2509-0064' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-08'::date, 17109000.0, 'UZS', 17109000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0064' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0065', (SELECT id FROM customers WHERE phone='+998 91 398 88 45' LIMIT 1), 'import', '2025-09-24'::date, '2025-12-01'::date, 'delivered', 0, 300, NULL, 'Margilon', 0, 'Model (asl): BUNKER magnum, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 398 88 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0065');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER magnum') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER magnum') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1699, (19778000.0)/1, 0, 0, 19778000.0
FROM orders o WHERE o.code='L-2509-0065' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-01'::date, 19778000.0, 'UZS', 19778000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0065' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0066', (SELECT id FROM customers WHERE phone='+998 93 195 99 09' LIMIT 1), 'import', '2025-09-25'::date, '2025-12-09'::date, 'delivered', 0, 200, 'right', 'Namangan norin', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 195 99 09')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0066');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (16637000.0)/1, 0, 0, 16637000.0
FROM orders o WHERE o.code='L-2509-0066' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-09'::date, 16637000.0, 'UZS', 16637000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0066' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0067', (SELECT id FROM customers WHERE phone='+998 50 575 52 44' LIMIT 1), 'import', '2025-09-25'::date, '2025-12-02'::date, 'delivered', 0, 200, 'left', 'yaypan', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 575 52 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0067');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16025000.0)/1, 0, 0, 16025000.0
FROM orders o WHERE o.code='L-2509-0067' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-02'::date, 16025000.0, 'UZS', 16025000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0067' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0068', (SELECT id FROM customers WHERE phone='+996 558808071' LIMIT 1), 'import', '2025-09-26'::date, '2025-12-05'::date, 'delivered', 0, 300, 'left', 'QIRGIZISTON OSH', 0, 'Model (asl): BUNKER ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+996 558808071')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0068');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (3672000.0)/1, 0, 0, 3672000.0
FROM orders o WHERE o.code='L-2509-0068' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-05'::date, 3672000.0, 'UZS', 3672000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0068' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0069', (SELECT id FROM customers WHERE phone='+998 91 113 57 77' LIMIT 1), 'import', '2025-09-26'::date, '2025-12-28'::date, 'delivered', 0, 200, 'left', 'Andijon viloyat', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 113 57 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0069');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (13000000.0)/1, 0, 0, 13000000.0
FROM orders o WHERE o.code='L-2509-0069' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-28'::date, 13000000.0, 'UZS', 13000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0069' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0071', (SELECT id FROM customers WHERE phone='+998 94 117 70 02' LIMIT 1), 'import', '2025-09-26'::date, '2025-10-14'::date, 'delivered', 0, 200, 'left', 'gurum saroy', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 117 70 02')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0071');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (18362750.0)/1, 0, 0, 18362750.0
FROM orders o WHERE o.code='L-2509-0071' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-14'::date, 18362750.0, 'UZS', 18362750.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0071' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0072', (SELECT id FROM customers WHERE phone='+998 91 563 04 04' LIMIT 1), 'import', '2025-09-26'::date, '2025-12-11'::date, 'delivered', 0, 200, 'left', 'Margilon', 0, 'Model (asl): BUNKER 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 563 04 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0072');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1199, (9175000.0)/1, 0, 0, 9175000.0
FROM orders o WHERE o.code='L-2509-0072' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-11'::date, 9175000.0, 'UZS', 9175000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0072' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0073', (SELECT id FROM customers WHERE phone='+998 93 595 21 02' LIMIT 1), 'import', '2025-09-26'::date, '2025-12-08'::date, 'delivered', 0, 200, 'right', 'furqat tumani', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 595 21 02')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0073');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15300000.0)/1, 0, 0, 15300000.0
FROM orders o WHERE o.code='L-2509-0073' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-08'::date, 15300000.0, 'UZS', 15300000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0073' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0074', (SELECT id FROM customers WHERE phone='+998 97 926 04 39' LIMIT 1), 'import', '2025-09-26'::date, '2025-12-06'::date, 'delivered', 0, 200, NULL, 'samarqand rayon', 0, 'Model (asl): BUNKER magnum, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 926 04 39')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0074');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER magnum') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER magnum') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1499, (17287000.0)/1, 0, 0, 17287000.0
FROM orders o WHERE o.code='L-2509-0074' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-06'::date, 17287000.0, 'UZS', 17287000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0074' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0076', (SELECT id FROM customers WHERE phone='+998 93 683 66 60' LIMIT 1), 'import', '2025-09-29'::date, '2025-10-01'::date, 'delivered', 0, 200, 'left', 'Namangan shahar', 0, 'Model (asl): BUNKER 3 Pro, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 683 66 60')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0076');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 Pro') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER 3 Pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1329, (15934000.0)/1, 0, 0, 15934000.0
FROM orders o WHERE o.code='L-2509-0076' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-01'::date, 15934000.0, 'UZS', 15934000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0076' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0077', (SELECT id FROM customers WHERE phone='+998 91 115 03 03' LIMIT 1), 'import', '2025-09-30'::date, '2025-10-25'::date, 'delivered', 0, 200, NULL, 'MARGILON', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 115 03 03')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0077');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (15704000.0)/1, 0, 0, 15704000.0
FROM orders o WHERE o.code='L-2509-0077' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-25'::date, 15704000.0, 'UZS', 15704000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0077' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2509-0078', (SELECT id FROM customers WHERE phone='+998 99 745 77 52' LIMIT 1), 'import', '2025-09-30'::date, '2025-12-03'::date, 'delivered', 0, 200, NULL, 'Buxoro Romitan', 0, 'Model (asl): BUNKER ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 745 77 52')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2509-0078');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('BUNKER ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (16441000.0)/1, 0, 0, 16441000.0
FROM orders o WHERE o.code='L-2509-0078' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-03'::date, 16441000.0, 'UZS', 16441000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2509-0078' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0002', (SELECT id FROM customers WHERE phone='+998 99 506 90 19' LIMIT 1), 'import', '2025-10-01'::date, '2025-12-10'::date, 'delivered', 0, 200, 'left', 'BUXORO OLOT', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 506 90 19')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (15927900.0)/1, 0, 0, 15927900.0
FROM orders o WHERE o.code='L-2510-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-10'::date, 15927900.0, 'UZS', 15927900.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0004', (SELECT id FROM customers WHERE phone='+998 91 497 27 28' LIMIT 1), 'import', '2025-10-03'::date, '2025-10-04'::date, 'delivered', 0, 300, 'right', 'Andilon Nurobod', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 497 27 28')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (17152000.0)/1, 0, 0, 17152000.0
FROM orders o WHERE o.code='L-2510-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-04'::date, 17152000.0, 'UZS', 17152000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0005', (SELECT id FROM customers WHERE phone='+998 33 200 15 14' LIMIT 1), 'import', '2025-10-03'::date, '2025-12-15'::date, 'delivered', 0, 200, 'right', 'toshloq fargona', 0, 'Model (asl): ULTRA, 200 kvm | 60 kunga', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 200 15 14')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (14500000.0)/1, 0, 0, 14500000.0
FROM orders o WHERE o.code='L-2510-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-15'::date, 14500000.0, 'UZS', 14500000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0006', (SELECT id FROM customers WHERE phone='+998 33 718 24 89' LIMIT 1), 'import', '2025-10-03'::date, '2025-12-14'::date, 'delivered', 0, 200, 'right', 'margilon shaxar', 0, 'Model (asl): ULTRA, 200 kvm | DIMAHOD 5 TA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 718 24 89')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15112000.0)/1, 0, 0, 15112000.0
FROM orders o WHERE o.code='L-2510-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-14'::date, 15112000.0, 'UZS', 15112000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0007', (SELECT id FROM customers WHERE phone='+998 88 844 75 45' LIMIT 1), 'import', '2025-10-03'::date, '2025-12-10'::date, 'delivered', 0, 300, 'left', 'surxandaryo denov', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 844 75 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (13137900.0)/1, 0, 0, 13137900.0
FROM orders o WHERE o.code='L-2510-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-10'::date, 13137900.0, 'UZS', 13137900.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0008', (SELECT id FROM customers WHERE phone='+998 94 514 12 34' LIMIT 1), 'import', '2025-10-03'::date, '2025-12-10'::date, 'delivered', 0, 300, 'left', 'buxoro Olot', 0, 'Model (asl): ULTRA, 300 kvm | 60 kunga', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 514 12 34')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1449, (15732000.0)/1, 0, 0, 15732000.0
FROM orders o WHERE o.code='L-2510-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-10'::date, 15732000.0, 'UZS', 15732000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0009', (SELECT id FROM customers WHERE phone='+998 90 899 89 08' LIMIT 1), 'import', '2025-10-03'::date, '2025-12-09'::date, 'delivered', 0, 150, NULL, 'Qashqadaryo Kitob', 0, 'Model (asl): PRO, 150 kvm | 60 kunga', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 899 89 08')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PRO') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12902000.0)/1, 0, 0, 12902000.0
FROM orders o WHERE o.code='L-2510-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-09'::date, 12902000.0, 'UZS', 12902000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0010', (SELECT id FROM customers WHERE phone='+998 90 625 50 31' LIMIT 1), 'import', '2025-10-03'::date, '2025-12-18'::date, 'delivered', 0, 200, 'right', 'andijon marxamat', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 625 50 31')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15322900.0)/1, 0, 0, 15322900.0
FROM orders o WHERE o.code='L-2510-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-18'::date, 15322900.0, 'UZS', 15322900.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0014', (SELECT id FROM customers WHERE phone='+996 558808071' LIMIT 1), 'import', '2025-10-06'::date, '2025-12-25'::date, 'delivered', 0, 300, 'right', 'Osh', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+996 558808071')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1549, (8379000.0)/1, 0, 0, 8379000.0
FROM orders o WHERE o.code='L-2510-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-25'::date, 8379000.0, 'UZS', 8379000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0015', (SELECT id FROM customers WHERE phone='+998 90 293 55 25' LIMIT 1), 'import', '2025-10-06'::date, '2025-10-25'::date, 'delivered', 0, 300, 'right', 'QO''QON SHAHAR', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 293 55 25')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1400, (15842000.0)/1, 0, 0, 15842000.0
FROM orders o WHERE o.code='L-2510-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-25'::date, 15842000.0, 'UZS', 15842000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0016', (SELECT id FROM customers WHERE phone='+998 90 700 04 44' LIMIT 1), 'import', '2025-10-07'::date, '2025-12-14'::date, 'delivered', 0, 150, 'left', 'o''zbekiston tumani', 0, 'Model (asl): PREMIUM 3, 150 kvm | UPS1Ta=AKM1ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 700 04 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1521, (8127000.0)/1, 0, 0, 8127000.0
FROM orders o WHERE o.code='L-2510-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-14'::date, 8127000.0, 'UZS', 8127000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0017', (SELECT id FROM customers WHERE phone='+998 90 039 19 63' LIMIT 1), 'import', '2025-10-08'::date, '2025-12-16'::date, 'delivered', 0, 150, 'right', 'Samarqand Payariq', 0, 'Model (asl): ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 039 19 63')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (15268000.0)/1, 0, 0, 15268000.0
FROM orders o WHERE o.code='L-2510-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-16'::date, 15268000.0, 'UZS', 15268000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0018', (SELECT id FROM customers WHERE phone='+998 77 786 08 88' LIMIT 1), 'import', '2025-10-09'::date, '2025-10-28'::date, 'delivered', 0, 200, 'right', 'ANDIJON BUSTON', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 786 08 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (2420000.0)/1, 0, 0, 2420000.0
FROM orders o WHERE o.code='L-2510-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-28'::date, 2420000.0, 'UZS', 2420000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0019', (SELECT id FROM customers WHERE phone='+998 90 380 22 23' LIMIT 1), 'import', '2025-10-10'::date, '2025-12-12'::date, 'delivered', 0, 300, 'right', 'ANDIJON JALAQUDUQ', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 380 22 23')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0019');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (17062000.0)/1, 0, 0, 17062000.0
FROM orders o WHERE o.code='L-2510-0019' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-12'::date, 17062000.0, 'UZS', 17062000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0019' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0020', (SELECT id FROM customers WHERE phone='+998 93 413 22 42' LIMIT 1), 'import', '2025-10-10'::date, '2025-12-30'::date, 'delivered', 0, 300, 'left', 'ANDIJON SHAXAR', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 413 22 42')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (17062000.0)/1, 0, 0, 17062000.0
FROM orders o WHERE o.code='L-2510-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-30'::date, 17062000.0, 'UZS', 17062000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0022', (SELECT id FROM customers WHERE phone='+998 99 673 71 23' LIMIT 1), 'import', '2025-10-10'::date, '2025-12-12'::date, 'delivered', 0, 200, 'left', 'SAMARQAND QUSHRABOT', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 673 71 23')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (17197000.0)/1, 0, 0, 17197000.0
FROM orders o WHERE o.code='L-2510-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-12'::date, 17197000.0, 'UZS', 17197000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0023', (SELECT id FROM customers WHERE phone='+998 77 500 70 40' LIMIT 1), 'import', '2025-10-10'::date, '2025-12-08'::date, 'delivered', 0, 300, 'right', 'Qoqon shahar', 0, 'Model (asl): MAGNUM, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 500 70 40')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1649, (18811000.0)/1, 0, 0, 18811000.0
FROM orders o WHERE o.code='L-2510-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-08'::date, 18811000.0, 'UZS', 18811000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0023' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0025', (SELECT id FROM customers WHERE phone='+998 91 113 77 00' LIMIT 1), 'import', '2025-10-10'::date, '2025-12-27'::date, 'delivered', 0, 150, 'right', 'QUSHTEPA TUMANI', 0, 'Model (asl): ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 113 77 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (13769000.0)/1, 0, 0, 13769000.0
FROM orders o WHERE o.code='L-2510-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-27'::date, 13769000.0, 'UZS', 13769000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0026', (SELECT id FROM customers WHERE phone='+998 95 155 30 30' LIMIT 1), 'import', '2025-10-10'::date, '2025-11-09'::date, 'delivered', 0, 200, 'right', 'DOIM OBOD', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 155 30 30')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0026');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (16376000.0)/1, 0, 0, 16376000.0
FROM orders o WHERE o.code='L-2510-0026' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-09'::date, 16376000.0, 'UZS', 16376000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0026' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0027', (SELECT id FROM customers WHERE phone='+998 94 153 00 70' LIMIT 1), 'import', '2025-10-10'::date, '2025-10-31'::date, 'delivered', 0, 200, NULL, 'Namangan', 0, 'Model (asl): ULTRA, 200 kvm | 20 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 153 00 70')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0027');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (16403000.0)/1, 0, 0, 16403000.0
FROM orders o WHERE o.code='L-2510-0027' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-31'::date, 16403000.0, 'UZS', 16403000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0027' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0028', (SELECT id FROM customers WHERE phone='+998 97 755 28 89' LIMIT 1), 'import', '2025-10-15'::date, '2025-11-08'::date, 'delivered', 0, 750, 'left', 'Bustonliq xumson', 0, 'Model (asl): ULTRA, 750 kvm | 20 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 755 28 89')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0028');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=750 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 2649, (27505000.0)/1, 0, 0, 27505000.0
FROM orders o WHERE o.code='L-2510-0028' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-08'::date, 27505000.0, 'UZS', 27505000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0028' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0029', (SELECT id FROM customers WHERE phone='+998 90 426 33 32' LIMIT 1), 'import', '2025-10-15'::date, '2025-12-18'::date, 'delivered', 0, 200, 'left', 'Qashqadaryo chiroqchi', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 426 33 32')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0029');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1549, (17716000.0)/1, 0, 0, 17716000.0
FROM orders o WHERE o.code='L-2510-0029' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-18'::date, 17716000.0, 'UZS', 17716000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0029' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0030', (SELECT id FROM customers WHERE phone='+998 94 930 80 21' LIMIT 1), 'import', '2025-10-16'::date, '2025-12-26'::date, 'delivered', 0, 200, 'right', 'Samarqand Toyloq', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 930 80 21')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0030');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1483, (15665000.0)/1, 0, 0, 15665000.0
FROM orders o WHERE o.code='L-2510-0030' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-26'::date, 15665000.0, 'UZS', 15665000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0030' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0031', (SELECT id FROM customers WHERE phone='+998 99 314 91 01' LIMIT 1), 'import', '2025-10-16'::date, '2025-12-18'::date, 'delivered', 0, 200, 'right', 'Namangan shahar', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 314 91 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0031');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1483, (17607000.0)/1, 0, 0, 17607000.0
FROM orders o WHERE o.code='L-2510-0031' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-18'::date, 17607000.0, 'UZS', 17607000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0031' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0032', (SELECT id FROM customers WHERE phone='+998 90 967 16 71' LIMIT 1), 'import', '2025-10-17'::date, '2025-12-26'::date, 'delivered', 0, 300, 'left', 'Buxoro Arabxona', 0, 'Model (asl): PREMIUM 4, 300 kvm | wifi ariston', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 967 16 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0032');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1553, (17868000.0)/1, 0, 0, 17868000.0
FROM orders o WHERE o.code='L-2510-0032' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-26'::date, 17868000.0, 'UZS', 17868000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0032' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0033', (SELECT id FROM customers WHERE phone='+998 97 964 87 00' LIMIT 1), 'import', '2025-10-17'::date, '2025-12-23'::date, 'delivered', 0, 200, 'left', 'andijon xuja obod', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 964 87 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0033');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1483, (7095000.0)/1, 0, 0, 7095000.0
FROM orders o WHERE o.code='L-2510-0033' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-23'::date, 7095000.0, 'UZS', 7095000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0033' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0034', (SELECT id FROM customers WHERE phone='+998 91 995 43 44' LIMIT 1), 'import', '2025-10-17'::date, '2025-12-18'::date, 'delivered', 0, 150, 'left', 'Xiva tumani', 0, 'Model (asl): PRO, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 995 43 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0034');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PRO') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1183, (13373000.0)/1, 0, 0, 13373000.0
FROM orders o WHERE o.code='L-2510-0034' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-18'::date, 13373000.0, 'UZS', 13373000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0034' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0035', (SELECT id FROM customers WHERE phone='+998 91 995 43 44' LIMIT 1), 'import', '2025-10-17'::date, '2025-12-18'::date, 'delivered', 0, 150, 'left', 'Xiva tumani', 0, 'Model (asl): PRO, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 995 43 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0035');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PRO') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1183, (13373000.0)/1, 0, 0, 13373000.0
FROM orders o WHERE o.code='L-2510-0035' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-18'::date, 13373000.0, 'UZS', 13373000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0035' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0036', (SELECT id FROM customers WHERE phone='+998 99 699 27 28' LIMIT 1), 'import', '2025-10-17'::date, '2025-12-19'::date, 'delivered', 0, 300, 'right', 'Namangan shahar', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 699 27 28')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0036');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1483, (16803000.0)/1, 0, 0, 16803000.0
FROM orders o WHERE o.code='L-2510-0036' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-19'::date, 16803000.0, 'UZS', 16803000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0036' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0037', (SELECT id FROM customers WHERE phone='+998 93 290 00 75' LIMIT 1), 'import', '2025-10-17'::date, '2025-12-20'::date, 'delivered', 0, 200, 'left', 'Fargona Quvasoy', 0, 'Model (asl): PREMIUM 4, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 290 00 75')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0037');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1233, (13980000.0)/1, 0, 0, 13980000.0
FROM orders o WHERE o.code='L-2510-0037' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-20'::date, 13980000.0, 'UZS', 13980000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0037' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0038', (SELECT id FROM customers WHERE phone='+998 88 325 00 11' LIMIT 1), 'import', '2025-10-18'::date, '2026-01-22'::date, 'delivered', 0, 200, 'left', 'jizzax', 0, 'Model (asl): ULTRA, 200 kvm | 15 yanvar', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 325 00 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0038');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16067000.0)/1, 0, 0, 16067000.0
FROM orders o WHERE o.code='L-2510-0038' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-22'::date, 16067000.0, 'UZS', 16067000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0038' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0039', (SELECT id FROM customers WHERE phone='+998 99 519 88 50' LIMIT 1), 'import', '2025-10-22'::date, '2025-10-28'::date, 'delivered', 0, 200, NULL, 'namangan', 0, 'Model (asl): premium 3, 200 kvm | 10 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 519 88 50')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0039');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (15717000.0)/1, 0, 0, 15717000.0
FROM orders o WHERE o.code='L-2510-0039' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-28'::date, 15717000.0, 'UZS', 15717000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0039' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0040', (SELECT id FROM customers WHERE phone='+998 99 130 00 15' LIMIT 1), 'import', '2025-10-22'::date, '2025-12-03'::date, 'delivered', 0, 500, 'left', 'Namangan', 0, 'Model (asl): MAGNUM, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 130 00 15')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0040');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 2050, (22805000.0)/1, 0, 0, 22805000.0
FROM orders o WHERE o.code='L-2510-0040' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-03'::date, 22805000.0, 'UZS', 22805000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0040' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0041', (SELECT id FROM customers WHERE phone='+998 99 826 62 47' LIMIT 1), 'import', '2025-10-24'::date, '2025-12-03'::date, 'delivered', 0, 200, 'left', 'Margilon', 0, 'Model (asl): premium 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 826 62 47')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0041');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1198, (13362000.0)/1, 0, 0, 13362000.0
FROM orders o WHERE o.code='L-2510-0041' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-03'::date, 13362000.0, 'UZS', 13362000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0041' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0042', (SELECT id FROM customers WHERE phone='+998 90 854 20 06' LIMIT 1), 'import', '2025-10-24'::date, '2025-12-17'::date, 'delivered', 0, 200, 'left', 'uchkuprik', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 854 20 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0042');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1518, (14821000.0)/1, 0, 0, 14821000.0
FROM orders o WHERE o.code='L-2510-0042' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-17'::date, 14821000.0, 'UZS', 14821000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0042' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0043', (SELECT id FROM customers WHERE phone='+998 90 790 76 67' LIMIT 1), 'import', '2025-10-24'::date, '2025-12-12'::date, 'delivered', 0, 300, 'left', 'Namnagan', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 790 76 67')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0043');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1448, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2510-0043' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0044', (SELECT id FROM customers WHERE phone='+998 99 325 47 44' LIMIT 1), 'import', '2025-10-24'::date, '2025-11-18'::date, 'delivered', 0, 200, 'right', 'ANDIJON', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 325 47 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0044');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1298, (15244000.0)/1, 0, 0, 15244000.0
FROM orders o WHERE o.code='L-2510-0044' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-18'::date, 15244000.0, 'UZS', 15244000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0044' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0045', (SELECT id FROM customers WHERE phone='+998 99 325 47 44' LIMIT 1), 'import', '2025-10-24'::date, '2025-11-18'::date, 'delivered', 0, 200, 'right', 'ANDIJON', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 325 47 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0045');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1248, (15244000.0)/1, 0, 0, 15244000.0
FROM orders o WHERE o.code='L-2510-0045' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-18'::date, 15244000.0, 'UZS', 15244000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0045' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0046', (SELECT id FROM customers WHERE phone='+992 110200123' LIMIT 1), 'import', '2025-10-24'::date, '2025-11-19'::date, 'delivered', 0, 200, NULL, 'tojikiston', 0, 'Model (asl): ULTRA, 200 kvm | 1 XAFTA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+992 110200123')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0046');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1298, (14744000.0)/1, 0, 0, 14744000.0
FROM orders o WHERE o.code='L-2510-0046' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-19'::date, 14744000.0, 'UZS', 14744000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0046' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0047', (SELECT id FROM customers WHERE phone='+998 90 597 86 82' LIMIT 1), 'import', '2025-10-25'::date, '2025-12-18'::date, 'delivered', 0, 150, 'left', 'chust', 0, 'Model (asl): ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 597 86 82')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0047');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1248, (13925000.0)/1, 0, 0, 13925000.0
FROM orders o WHERE o.code='L-2510-0047' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-18'::date, 13925000.0, 'UZS', 13925000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0047' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0048', (SELECT id FROM customers WHERE phone='+998 95 394 32 32' LIMIT 1), 'import', '2025-10-25'::date, '2025-10-27'::date, 'delivered', 0, 300, 'left', 'samarqand urgut', 0, 'Model (asl): ULTRA, 300 kvm | ariston 52', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 394 32 32')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0048');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1688, (20475000.0)/1, 0, 0, 20475000.0
FROM orders o WHERE o.code='L-2510-0048' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-10-27'::date, 20475000.0, 'UZS', 20475000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0048' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0049', (SELECT id FROM customers WHERE phone='+998 93 845 46 57' LIMIT 1), 'import', '2025-10-27'::date, '2025-11-22'::date, 'delivered', 0, 200, NULL, 'tojikiston', 0, 'Model (asl): ULTRA, 200 kvm | UPS1Ta=AKM1ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 845 46 57')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0049');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1786, (13140000.0)/1, 0, 0, 13140000.0
FROM orders o WHERE o.code='L-2510-0049' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-22'::date, 13140000.0, 'UZS', 13140000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0049' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0050', (SELECT id FROM customers WHERE phone='+998 97 468 00 44' LIMIT 1), 'import', '2025-10-27'::date, '2025-11-24'::date, 'delivered', 0, 200, 'right', 'namangan yangi qurg`on', 0, 'Model (asl): ULTRA, 200 kvm | 20 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 468 00 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0050');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1298, (15750000.0)/1, 0, 0, 15750000.0
FROM orders o WHERE o.code='L-2510-0050' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-24'::date, 15750000.0, 'UZS', 15750000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0050' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0051', (SELECT id FROM customers WHERE phone='+998 99 190 45 09' LIMIT 1), 'import', '2025-10-27'::date, '2025-11-08'::date, 'delivered', 0, 150, 'left', 'Namnagan', 0, 'Model (asl): ULTRA, 150 kvm | 25 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 190 45 09')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0051');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1248, (15100000.0)/1, 0, 0, 15100000.0
FROM orders o WHERE o.code='L-2510-0051' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-08'::date, 15100000.0, 'UZS', 15100000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0051' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0052', (SELECT id FROM customers WHERE phone='+998 91 462 97 77' LIMIT 1), 'import', '2025-10-27'::date, '2025-11-22'::date, 'delivered', 0, 200, 'right', 'Qashqadaryo', 0, 'Model (asl): ULTRA, 200 kvm | 20 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 462 97 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0052');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1298, (16000000.0)/1, 0, 0, 16000000.0
FROM orders o WHERE o.code='L-2510-0052' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-22'::date, 16000000.0, 'UZS', 16000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0052' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0054', (SELECT id FROM customers WHERE phone='+998 91 532 06 06' LIMIT 1), 'import', '2025-10-27'::date, '2025-12-05'::date, 'delivered', 0, 500, NULL, 'Samarqand', 0, 'Model (asl): ULTRA, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 532 06 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0054');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1648, (18000000.0)/1, 0, 0, 18000000.0
FROM orders o WHERE o.code='L-2510-0054' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-05'::date, 18000000.0, 'UZS', 18000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0054' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0055', (SELECT id FROM customers WHERE phone='+998 93 404 90 09' LIMIT 1), 'import', '2025-10-28'::date, '2025-12-25'::date, 'delivered', 0, 200, 'right', 'NAMANGAN', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 404 90 09')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0055');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1298, (15000000.0)/1, 0, 0, 15000000.0
FROM orders o WHERE o.code='L-2510-0055' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-25'::date, 15000000.0, 'UZS', 15000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0055' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0056', (SELECT id FROM customers WHERE phone='+998 93 678 77 66' LIMIT 1), 'import', '2025-10-28'::date, '2025-12-24'::date, 'delivered', 0, 200, 'right', 'NAMANGAN', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 678 77 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0056');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1298, (14000000.0)/1, 0, 0, 14000000.0
FROM orders o WHERE o.code='L-2510-0056' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-24'::date, 14000000.0, 'UZS', 14000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0056' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0057', (SELECT id FROM customers WHERE phone='+998 99 145 88 72' LIMIT 1), 'import', '2025-10-28'::date, '2025-12-23'::date, 'delivered', 0, 300, 'right', 'uzbekiston tumani', 0, 'Model (asl): MAGNUM, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 145 88 72')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0057');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1598, (16859000.0)/1, 0, 0, 16859000.0
FROM orders o WHERE o.code='L-2510-0057' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-23'::date, 16859000.0, 'UZS', 16859000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0057' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0058', (SELECT id FROM customers WHERE phone='+998 93 783 79 97' LIMIT 1), 'import', '2025-10-29'::date, '2025-12-27'::date, 'delivered', 0, 150, 'left', 'ANDIJON', 0, 'Model (asl): premium 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 783 79 97')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0058');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1098, (12197000.0)/1, 0, 0, 12197000.0
FROM orders o WHERE o.code='L-2510-0058' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-27'::date, 12197000.0, 'UZS', 12197000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0058' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0060', (SELECT id FROM customers WHERE phone='+998 90 217 40 00' LIMIT 1), 'import', '2025-10-31'::date, '2025-11-13'::date, 'delivered', 0, 400, 'right', 'ANDIJON', 0, 'Model (asl): MAGNUM, 400 kvm | 25 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 217 40 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0060');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1798, (16611000.0)/1, 0, 0, 16611000.0
FROM orders o WHERE o.code='L-2510-0060' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-13'::date, 16611000.0, 'UZS', 16611000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0060' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0061', (SELECT id FROM customers WHERE phone='+998 94 035 24 24' LIMIT 1), 'import', '2025-10-31'::date, '2025-12-12'::date, 'delivered', 0, 500, NULL, 'Namangan', 0, 'Model (asl): ULTRA, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 035 24 24')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0061');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1648, (18650000.0)/1, 0, 0, 18650000.0
FROM orders o WHERE o.code='L-2510-0061' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-12'::date, 18650000.0, 'UZS', 18650000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0061' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2510-0062', (SELECT id FROM customers WHERE phone='+998 97 996 52 86' LIMIT 1), 'import', '2025-10-31'::date, '2025-12-20'::date, 'delivered', 0, 200, NULL, 'Andijon', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 996 52 86')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2510-0062');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1448, (15000000.0)/1, 0, 0, 15000000.0
FROM orders o WHERE o.code='L-2510-0062' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-20'::date, 15000000.0, 'UZS', 15000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2510-0062' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0002', (SELECT id FROM customers WHERE phone='+998 93 870 60 07' LIMIT 1), 'import', '2025-11-02'::date, '2025-12-04'::date, 'delivered', 0, 300, 'right', 'andijon bus', 0, 'Model (asl): premium 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 870 60 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1250, (13087000.0)/1, 0, 0, 13087000.0
FROM orders o WHERE o.code='L-2511-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-04'::date, 13087000.0, 'UZS', 13087000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0003', (SELECT id FROM customers WHERE phone='+998 97 168 37 37' LIMIT 1), 'import', '2025-11-02'::date, '2025-12-22'::date, 'delivered', 0, 300, 'left', 'andijon ulugnor', 0, 'Model (asl): pro, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 168 37 37')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1350, (12060000.0)/1, 0, 0, 12060000.0
FROM orders o WHERE o.code='L-2511-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-22'::date, 12060000.0, 'UZS', 12060000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0004', (SELECT id FROM customers WHERE phone='+998 93 173 73 73' LIMIT 1), 'import', '2025-11-02'::date, '2025-12-25'::date, 'delivered', 0, 300, 'right', 'namangan', 0, 'Model (asl): MAGNUM, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 173 73 73')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1600, (17412000.0)/1, 0, 0, 17412000.0
FROM orders o WHERE o.code='L-2511-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-25'::date, 17412000.0, 'UZS', 17412000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0005', (SELECT id FROM customers WHERE phone='+998 93 407 41 40' LIMIT 1), 'import', '2025-11-03'::date, '2025-12-24'::date, 'delivered', 0, 300, 'right', 'namangan', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 407 41 40')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1450, (17349000.0)/1, 0, 0, 17349000.0
FROM orders o WHERE o.code='L-2511-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-24'::date, 17349000.0, 'UZS', 17349000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0007', (SELECT id FROM customers WHERE phone='+998 94 305 55 00' LIMIT 1), 'import', '2025-11-03'::date, '2025-11-28'::date, 'delivered', 0, 200, 'left', 'buxoro', 0, 'Model (asl): premium 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 305 55 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1200, (13460000.0)/1, 0, 0, 13460000.0
FROM orders o WHERE o.code='L-2511-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-28'::date, 13460000.0, 'UZS', 13460000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0008', (SELECT id FROM customers WHERE phone='+998 99 660 19 77' LIMIT 1), 'import', '2025-11-03'::date, '2026-01-05'::date, 'delivered', 0, 150, 'right', 'Shahrisabz', 0, 'Model (asl): premium 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 660 19 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1100, (12200000.0)/1, 0, 0, 12200000.0
FROM orders o WHERE o.code='L-2511-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-05'::date, 12200000.0, 'UZS', 12200000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0009', (SELECT id FROM customers WHERE phone='+998 94 501 32 00' LIMIT 1), 'import', '2025-11-03'::date, '2025-12-28'::date, 'delivered', 0, 200, NULL, 'NAMANGAN CHORTOQ', 0, 'Model (asl): premium 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 501 32 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1200, (13472000.0)/1, 0, 0, 13472000.0
FROM orders o WHERE o.code='L-2511-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-28'::date, 13472000.0, 'UZS', 13472000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0010', (SELECT id FROM customers WHERE phone='+998 99 975 91 91' LIMIT 1), 'import', '2025-11-04'::date, '2025-12-16'::date, 'delivered', 0, 300, 'left', 'pop tumani', 0, 'Model (asl): MAGNUM, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 975 91 91')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1699, (5983000.0)/1, 0, 0, 5983000.0
FROM orders o WHERE o.code='L-2511-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-16'::date, 5983000.0, 'UZS', 5983000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0011', (SELECT id FROM customers WHERE phone='+998 95 673 22 44' LIMIT 1), 'import', '2025-11-05'::date, '2026-01-03'::date, 'delivered', 0, 200, 'left', 'Namangan tumani', 0, 'Model (asl): pro, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 673 22 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1329, (13525000.0)/1, 0, 0, 13525000.0
FROM orders o WHERE o.code='L-2511-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-03'::date, 13525000.0, 'UZS', 13525000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0012', (SELECT id FROM customers WHERE phone='+998 95 673 22 44' LIMIT 1), 'import', '2025-11-05'::date, '2026-01-05'::date, 'delivered', 0, 200, 'left', 'Namangan tumani', 0, 'Model (asl): pro, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 673 22 44')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1329, (13525000.0)/1, 0, 0, 13525000.0
FROM orders o WHERE o.code='L-2511-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-05'::date, 13525000.0, 'UZS', 13525000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0013', (SELECT id FROM customers WHERE phone='+998 95 679 19 74' LIMIT 1), 'import', '2025-11-05'::date, '2025-12-11'::date, 'delivered', 0, 200, NULL, 'Samarqand pstargom', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 679 19 74')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (1088000.0)/1, 0, 0, 1088000.0
FROM orders o WHERE o.code='L-2511-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-11'::date, 1088000.0, 'UZS', 1088000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0015', (SELECT id FROM customers WHERE phone='+998 50 997 30 01' LIMIT 1), 'import', '2025-11-08'::date, '2026-01-06'::date, 'delivered', 0, 150, NULL, 'Buxoro Olot', 0, 'Model (asl): MAGNUM, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 997 30 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1499, (17667000.0)/1, 0, 0, 17667000.0
FROM orders o WHERE o.code='L-2511-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-06'::date, 17667000.0, 'UZS', 17667000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0016', (SELECT id FROM customers WHERE phone='+998 90 136 76 45' LIMIT 1), 'import', '2025-11-11'::date, '2026-01-14'::date, 'delivered', 0, 300, 'right', 'Andijon Marhamat', 0, 'Model (asl): premium 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 136 76 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15012000.0)/1, 0, 0, 15012000.0
FROM orders o WHERE o.code='L-2511-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-14'::date, 15012000.0, 'UZS', 15012000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0017', (SELECT id FROM customers WHERE phone='+998 91 136 49 39' LIMIT 1), 'import', '2025-11-12'::date, '2025-12-16'::date, 'delivered', 0, 200, 'right', 'Andijon Shahrihon', 0, 'Model (asl): ULTRA, 200 kvm | 25 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 136 49 39')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (15715000.0)/1, 0, 0, 15715000.0
FROM orders o WHERE o.code='L-2511-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-16'::date, 15715000.0, 'UZS', 15715000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0018', (SELECT id FROM customers WHERE phone='+998 90 525 29 29' LIMIT 1), 'import', '2025-11-12'::date, '2026-01-07'::date, 'delivered', 0, 300, 'right', 'ANDIJON JALAQUDOQ', 0, 'Model (asl): MAGNUM, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 525 29 29')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1649, (2700000.0)/1, 0, 0, 2700000.0
FROM orders o WHERE o.code='L-2511-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-07'::date, 2700000.0, 'UZS', 2700000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0019', (SELECT id FROM customers WHERE phone='+998 90 534 04 09' LIMIT 1), 'import', '2025-11-14'::date, '2026-01-07'::date, 'delivered', 0, 150, 'left', 'Quva shahar', 0, 'Model (asl): premium 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 534 04 09')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0019');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1149, (10196000.0)/1, 0, 0, 10196000.0
FROM orders o WHERE o.code='L-2511-0019' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-07'::date, 10196000.0, 'UZS', 10196000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0019' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0020', (SELECT id FROM customers WHERE phone='+998 90 272 11 19' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-28'::date, 'delivered', 0, 300, 'left', 'FURQAT TUMANI', 0, 'Model (asl): ULTRA, 300 kvm | 28 dekabr', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 272 11 19')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (16788000.0)/1, 0, 0, 16788000.0
FROM orders o WHERE o.code='L-2511-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-28'::date, 16788000.0, 'UZS', 16788000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0021', (SELECT id FROM customers WHERE phone='+998 93 446 04 97' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-14'::date, 'delivered', 0, 200, 'left', 'ANDIJON', 0, 'Model (asl): ULTRA, 200 kvm | 1 OY', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 446 04 97')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (15255000.0)/1, 0, 0, 15255000.0
FROM orders o WHERE o.code='L-2511-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-14'::date, 15255000.0, 'UZS', 15255000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0022', (SELECT id FROM customers WHERE phone='+998 90 526 20 36' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-14'::date, 'delivered', 0, 400, 'right', 'ANDIJON', 0, 'Model (asl): ULTRA, 400 kvm | 1 OY', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 526 20 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1649, (18870000.0)/1, 0, 0, 18870000.0
FROM orders o WHERE o.code='L-2511-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-14'::date, 18870000.0, 'UZS', 18870000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0023', (SELECT id FROM customers WHERE phone='+998 90 773 06 89' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-28'::date, 'delivered', 0, 200, 'right', 'ANDIJON ASAKA', 0, 'Model (asl): ULTRA, 200 kvm | 1 OY', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 773 06 89')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15255000.0)/1, 0, 0, 15255000.0
FROM orders o WHERE o.code='L-2511-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-28'::date, 15255000.0, 'UZS', 15255000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0023' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0024', (SELECT id FROM customers WHERE phone='+998 94 389 10 07' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-19'::date, 'delivered', 0, 200, 'right', 'NAMANAGN UYCHI', 0, 'Model (asl): ULTRA, 200 kvm | 1 OY', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 389 10 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0024');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15000000.0)/1, 0, 0, 15000000.0
FROM orders o WHERE o.code='L-2511-0024' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-19'::date, 15000000.0, 'UZS', 15000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0024' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0025', (SELECT id FROM customers WHERE phone='+998 90 405 11 75' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-16'::date, 'delivered', 0, 500, 'right', 'MARGILON QUMTEPA', 0, 'Model (asl): ULTRA, 500 kvm | 20 KUN', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 405 11 75')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1944, (11346000.0)/1, 0, 0, 11346000.0
FROM orders o WHERE o.code='L-2511-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-16'::date, 11346000.0, 'UZS', 11346000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0026', (SELECT id FROM customers WHERE phone='+998 99 447 18 55' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-26'::date, 'delivered', 0, 200, NULL, 'Samarqand', 0, 'Model (asl): pro, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 447 18 55')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0026');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1279, (14448000.0)/1, 0, 0, 14448000.0
FROM orders o WHERE o.code='L-2511-0026' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-26'::date, 14448000.0, 'UZS', 14448000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0026' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0027', (SELECT id FROM customers WHERE phone='+998 99 447 18 55' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-26'::date, 'delivered', 0, 300, NULL, 'Samarqand', 0, 'Model (asl): pro, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 447 18 55')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0027');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (15890000.0)/1, 0, 0, 15890000.0
FROM orders o WHERE o.code='L-2511-0027' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-26'::date, 15890000.0, 'UZS', 15890000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0027' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0028', (SELECT id FROM customers WHERE phone='+998 95 038 02 51' LIMIT 1), 'import', '2025-11-14'::date, '2025-12-29'::date, 'delivered', 0, 500, 'right', 'Qarshi shahar', 0, 'Model (asl): ULTRA, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 038 02 51')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0028');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1699, (18021000.0)/1, 0, 0, 18021000.0
FROM orders o WHERE o.code='L-2511-0028' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-29'::date, 18021000.0, 'UZS', 18021000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0028' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0029', (SELECT id FROM customers WHERE phone='+998 94 922 70 70' LIMIT 1), 'import', '2025-11-15'::date, '2025-12-11'::date, 'delivered', 0, 200, NULL, 'namangan', 0, 'Model (asl): ULTRA, 200 kvm | 20-25 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 922 70 70')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0029');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (16857000.0)/1, 0, 0, 16857000.0
FROM orders o WHERE o.code='L-2511-0029' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-11'::date, 16857000.0, 'UZS', 16857000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0029' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0030', (SELECT id FROM customers WHERE phone='+998 94 453 00 07' LIMIT 1), 'import', '2025-11-15'::date, '2026-01-02'::date, 'delivered', 0, 150, NULL, 'Namangan', 0, 'Model (asl): premium 3, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 453 00 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0030');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1149, (12845000.0)/1, 0, 0, 12845000.0
FROM orders o WHERE o.code='L-2511-0030' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-02'::date, 12845000.0, 'UZS', 12845000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0030' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0031', (SELECT id FROM customers WHERE phone='+998 90 589 83 33' LIMIT 1), 'import', '2025-11-15'::date, '2025-12-15'::date, 'delivered', 0, 300, 'right', 'Uchkuprik', 0, 'Model (asl): premium 4, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 589 83 33')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0031');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (15000000.0)/1, 0, 0, 15000000.0
FROM orders o WHERE o.code='L-2511-0031' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-15'::date, 15000000.0, 'UZS', 15000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0031' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0032', (SELECT id FROM customers WHERE phone='+998 91 120 39 77' LIMIT 1), 'import', '2025-11-15'::date, '2025-12-17'::date, 'delivered', 0, 200, 'right', 'Oltiariq', 0, 'Model (asl): premium 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 120 39 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0032');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2511-0032' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0034', (SELECT id FROM customers WHERE phone='+998 91 155 02 16' LIMIT 1), 'import', '2025-11-17'::date, '2025-12-11'::date, 'delivered', 0, 200, 'right', 'Uchkuprik', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 155 02 16')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0034');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15037000.0)/1, 0, 0, 15037000.0
FROM orders o WHERE o.code='L-2511-0034' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-11'::date, 15037000.0, 'UZS', 15037000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0034' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0035', (SELECT id FROM customers WHERE phone='+998 91 652 35 45' LIMIT 1), 'import', '2025-11-17'::date, '2025-12-20'::date, 'delivered', 0, 300, 'left', 'Margilon', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0035');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (16262000.0)/1, 0, 0, 16262000.0
FROM orders o WHERE o.code='L-2511-0035' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-20'::date, 16262000.0, 'UZS', 16262000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0035' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0036', (SELECT id FROM customers WHERE phone='+998 91 120 39 77' LIMIT 1), 'import', '2025-11-18'::date, '2025-11-18'::date, 'delivered', 0, 200, 'right', 'Fargona', 0, 'Model (asl): premium 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 120 39 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0036');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, (500.0)/1, 0, 0, 500.0
FROM orders o WHERE o.code='L-2511-0036' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-18'::date, 500.0, 'UZS', 500.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0036' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0038', (SELECT id FROM customers WHERE phone='+998 97 790 48 68' LIMIT 1), 'import', '2025-11-19'::date, '2026-01-05'::date, 'delivered', 0, 300, NULL, 'Xorazim', 0, 'Model (asl): premium 4, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 790 48 68')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0038');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1399, (15788000.0)/1, 0, 0, 15788000.0
FROM orders o WHERE o.code='L-2511-0038' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-05'::date, 15788000.0, 'UZS', 15788000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0038' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0039', (SELECT id FROM customers WHERE phone='+998 94 325 12 78' LIMIT 1), 'import', '2025-11-19'::date, '2026-01-02'::date, 'delivered', 0, 200, 'right', 'Buxoro', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 325 12 78')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0039');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1549, (17422000.0)/1, 0, 0, 17422000.0
FROM orders o WHERE o.code='L-2511-0039' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-02'::date, 17422000.0, 'UZS', 17422000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0039' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0040', (SELECT id FROM customers WHERE phone='+998 91 141 68 68' LIMIT 1), 'import', '2025-11-20'::date, '2025-12-07'::date, 'delivered', 0, 300, 'left', 'uchkuprik kenagaz', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 141 68 68')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0040');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (5432000.0)/1, 0, 0, 5432000.0
FROM orders o WHERE o.code='L-2511-0040' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-07'::date, 5432000.0, 'UZS', 5432000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0040' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0041', (SELECT id FROM customers WHERE phone='+998 93 683 66 60' LIMIT 1), 'import', '2025-11-21'::date, '2025-11-27'::date, 'delivered', 0, 200, 'left', 'Namngan', 0, 'Model (asl): ULTRA, 200 kvm | CHorshanba kuni', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 683 66 60')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0041');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (16188000.0)/1, 0, 0, 16188000.0
FROM orders o WHERE o.code='L-2511-0041' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-27'::date, 16188000.0, 'UZS', 16188000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0041' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0042', (SELECT id FROM customers WHERE phone='+998 90 205 55 87' LIMIT 1), 'import', '2025-11-21'::date, '2025-12-30'::date, 'delivered', 0, 200, 'left', 'Andijon', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 205 55 87')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0042');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (16988000.0)/1, 0, 0, 16988000.0
FROM orders o WHERE o.code='L-2511-0042' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-30'::date, 16988000.0, 'UZS', 16988000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0042' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0043', (SELECT id FROM customers WHERE phone='+998 99 515 65 03' LIMIT 1), 'import', '2025-11-24'::date, '2025-11-28'::date, 'delivered', 0, 400, 'right', 'DANGARA ISTIQOL', 0, 'Model (asl): MAGNUM, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 515 65 03')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0043');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1899, (22825000.0)/1, 0, 0, 22825000.0
FROM orders o WHERE o.code='L-2511-0043' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-11-28'::date, 22825000.0, 'UZS', 22825000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0043' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0044', (SELECT id FROM customers WHERE phone='+998 33 637 60 89' LIMIT 1), 'import', '2025-11-24'::date, '2025-12-04'::date, 'delivered', 0, 400, 'left', 'DANGARA ISTIQOL', 0, 'Model (asl): ULTRA, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 637 60 89')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0044');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1699, (20420000.0)/1, 0, 0, 20420000.0
FROM orders o WHERE o.code='L-2511-0044' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-04'::date, 20420000.0, 'UZS', 20420000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0044' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0045', (SELECT id FROM customers WHERE phone='+998 99 190 36 33' LIMIT 1), 'import', '2025-11-25'::date, '2025-12-29'::date, 'delivered', 0, 200, NULL, 'Namangan Uychi', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 190 36 33')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0045');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1549, (17557000.0)/1, 0, 0, 17557000.0
FROM orders o WHERE o.code='L-2511-0045' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-29'::date, 17557000.0, 'UZS', 17557000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0045' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0046', (SELECT id FROM customers WHERE phone='NOPHONE-2511-46' LIMIT 1), 'import', '2025-11-25'::date, '2025-11-26'::date, 'delivered', 0, 200, 'right', 'QOQON', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='NOPHONE-2511-46')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0046');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1299, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2511-0046' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2511-0047', (SELECT id FROM customers WHERE phone='+7 917 016 64 69' LIMIT 1), 'import', '2025-11-26'::date, '2026-01-06'::date, 'delivered', 0, 200, 'left', 'SOGK TOJIK', 0, 'Model (asl): premium 4, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+7 917 016 64 69')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2511-0047');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (11648000.0)/1, 0, 0, 11648000.0
FROM orders o WHERE o.code='L-2511-0047' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-06'::date, 11648000.0, 'UZS', 11648000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2511-0047' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0002', (SELECT id FROM customers WHERE phone='+998 90 627 57 11' LIMIT 1), 'import', '2025-12-02'::date, '2025-12-19'::date, 'delivered', 0, 200, 'left', 'Eski shildir', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 627 57 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1450, (15000000.0)/1, 0, 0, 15000000.0
FROM orders o WHERE o.code='L-2512-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-19'::date, 15000000.0, 'UZS', 15000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0003', (SELECT id FROM customers WHERE phone='+998 91 244 44 15' LIMIT 1), 'import', '2025-12-02'::date, '2026-01-08'::date, 'delivered', 0, 300, 'right', 'Buxoro viloyati', 0, 'Model (asl): 3PRO, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 244 44 15')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('3PRO') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('3PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1350, (15065000.0)/1, 0, 0, 15065000.0
FROM orders o WHERE o.code='L-2512-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-08'::date, 15065000.0, 'UZS', 15065000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0004', (SELECT id FROM customers WHERE phone='+998 88 007 17 55' LIMIT 1), 'import', '2025-12-04'::date, '2026-01-08'::date, 'delivered', 0, 300, 'left', 'Buxoro Qorakul', 0, 'Model (asl): MAGNUM, 300 kvm | 20-25 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 007 17 55')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1600, (18028000.0)/1, 0, 0, 18028000.0
FROM orders o WHERE o.code='L-2512-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-08'::date, 18028000.0, 'UZS', 18028000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0006', (SELECT id FROM customers WHERE phone='+998 94 603 88 22' LIMIT 1), 'import', '2025-12-05'::date, '2025-12-15'::date, 'delivered', 0, 400, 'left', 'Baliqchi tuman', 0, 'Model (asl): ULTRA, 400 kvm | 15kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 603 88 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1600, (19200000.0)/1, 0, 0, 19200000.0
FROM orders o WHERE o.code='L-2512-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-15'::date, 19200000.0, 'UZS', 19200000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0007', (SELECT id FROM customers WHERE phone='+998 97 214 77 02' LIMIT 1), 'import', '2025-12-06'::date, '2026-01-06'::date, 'delivered', 0, 400, 'left', 'Xujand Tojikiston', 0, 'Model (asl): PREMIUM 3, 400 kvm | 30kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 214 77 02')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (1299.0)/1, 0, 0, 1299.0
FROM orders o WHERE o.code='L-2512-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-06'::date, 1299.0, 'UZS', 1299.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0008', (SELECT id FROM customers WHERE phone='+998 93 218 83 83' LIMIT 1), 'import', '2025-12-08'::date, '2026-01-08'::date, 'delivered', 0, 300, 'right', 'Andijon', 0, 'Model (asl): ULTRA, 300 kvm | 30kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 218 83 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1438, (12456000.0)/1, 0, 0, 12456000.0
FROM orders o WHERE o.code='L-2512-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-08'::date, 12456000.0, 'UZS', 12456000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0009', (SELECT id FROM customers WHERE phone='+998 93 714 30 36' LIMIT 1), 'import', '2025-12-09'::date, '2026-01-08'::date, 'delivered', 0, 200, 'right', 'Samarqand', 0, 'Model (asl): PREMIUM 4, 200 kvm | 35kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 714 30 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (15788000.0)/1, 0, 0, 15788000.0
FROM orders o WHERE o.code='L-2512-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-08'::date, 15788000.0, 'UZS', 15788000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0010', (SELECT id FROM customers WHERE phone='+998 99 603 73 03' LIMIT 1), 'import', '2025-12-11'::date, '2025-12-24'::date, 'delivered', 0, 200, 'left', 'Beshariq', 0, 'Model (asl): MAGNUM, 200 kvm | 10kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 603 73 03')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1571, (9252000.0)/1, 0, 0, 9252000.0
FROM orders o WHERE o.code='L-2512-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-24'::date, 9252000.0, 'UZS', 9252000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0011', (SELECT id FROM customers WHERE phone='+998 94 305 50 30' LIMIT 1), 'import', '2025-12-12'::date, '2026-01-10'::date, 'delivered', 0, 300, 'left', 'Namangan Kosonsoy', 0, 'Model (asl): PREMIUM 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 305 50 30')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1299, (13158000.0)/1, 0, 0, 13158000.0
FROM orders o WHERE o.code='L-2512-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-10'::date, 13158000.0, 'UZS', 13158000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0012', (SELECT id FROM customers WHERE phone='+998 94 305 50 30' LIMIT 1), 'import', '2025-12-12'::date, '2026-01-10'::date, 'delivered', 0, 300, NULL, 'Namangan Kosonsoy', 0, 'Model (asl): PREMIUM 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 305 50 30')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1299, (13158000.0)/1, 0, 0, 13158000.0
FROM orders o WHERE o.code='L-2512-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-10'::date, 13158000.0, 'UZS', 13158000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0013', (SELECT id FROM customers WHERE phone='+998 91 044 84 04' LIMIT 1), 'import', '2025-12-12'::date, '2026-01-10'::date, 'delivered', 0, 200, NULL, 'Marg"ilon', 0, 'Model (asl): 3 pro, 200 kvm | 30kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 044 84 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('3 pro') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('3 pro') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1279, (14148000.0)/1, 0, 0, 14148000.0
FROM orders o WHERE o.code='L-2512-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-10'::date, 14148000.0, 'UZS', 14148000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0014', (SELECT id FROM customers WHERE phone='+998 99 575 64 22' LIMIT 1), 'import', '2025-12-15'::date, '2026-01-12'::date, 'delivered', 0, 200, 'right', 'Samarqand', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 575 64 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (15927000.0)/1, 0, 0, 15927000.0
FROM orders o WHERE o.code='L-2512-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-12'::date, 15927000.0, 'UZS', 15927000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0015', (SELECT id FROM customers WHERE phone='+998 99 716 48 24' LIMIT 1), 'import', '2025-12-15'::date, '2026-01-14'::date, 'delivered', 0, 300, NULL, 'Buxoror Kogon', 0, 'Model (asl): MAGNUM, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 716 48 24')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1699, (17557000.0)/1, 0, 0, 17557000.0
FROM orders o WHERE o.code='L-2512-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-14'::date, 17557000.0, 'UZS', 17557000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0016', (SELECT id FROM customers WHERE phone='+998 91 142 00 01' LIMIT 1), 'import', '2025-12-15'::date, '2026-01-15'::date, 'delivered', 0, 300, NULL, 'Marg"ilon', 0, 'Model (asl): PREMIUM 3, 300 kvm | 30kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 142 00 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1349, (15112000.0)/1, 0, 0, 15112000.0
FROM orders o WHERE o.code='L-2512-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-15'::date, 15112000.0, 'UZS', 15112000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0018', (SELECT id FROM customers WHERE phone='+998 50 030 11 33' LIMIT 1), 'import', '2025-12-17'::date, '2025-12-29'::date, 'delivered', 0, 300, 'right', 'Andijon shaxrihon', 0, 'Model (asl): ULTRA, 300 kvm | Oy yakuniga', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 030 11 33')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1438, (16940000.0)/1, 0, 0, 16940000.0
FROM orders o WHERE o.code='L-2512-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-29'::date, 16940000.0, 'UZS', 16940000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0019', (SELECT id FROM customers WHERE phone='+998 50 030 11 33' LIMIT 1), 'import', '2025-12-18'::date, '2025-12-29'::date, 'delivered', 0, 300, 'right', 'Andijon shaxrihon', 0, 'Model (asl): ULTRA, 300 kvm | Oy yakuniga', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 030 11 33')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0019');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1438, (16940000.0)/1, 0, 0, 16940000.0
FROM orders o WHERE o.code='L-2512-0019' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-29'::date, 16940000.0, 'UZS', 16940000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0019' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0020', (SELECT id FROM customers WHERE phone='+998 90 920 64 10' LIMIT 1), 'import', '2025-12-18'::date, '2026-01-10'::date, 'delivered', 0, 200, 'right', 'Buvqayda', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 920 64 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1288, (12964000.0)/1, 0, 0, 12964000.0
FROM orders o WHERE o.code='L-2512-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-10'::date, 12964000.0, 'UZS', 12964000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0021', (SELECT id FROM customers WHERE phone='+998 91 624 45 41' LIMIT 1), 'import', '2025-12-20'::date, '2026-02-26'::date, 'delivered', 0, 200, 'right', 'Sirdaryo Guliston', 0, 'Model (asl): MAGNUM, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 624 45 41')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1438, (14327000.0)/1, 0, 0, 14327000.0
FROM orders o WHERE o.code='L-2512-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-26'::date, 14327000.0, 'UZS', 14327000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0022', (SELECT id FROM customers WHERE phone='+998 93 683 08 82' LIMIT 1), 'import', '2025-12-20'::date, '2026-01-16'::date, 'delivered', 0, 300, 'right', 'Buxoro tuman', 0, 'Model (asl): PREMIUM 4, 300 kvm | 25kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 683 08 82')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1338, (15122000.0)/1, 0, 0, 15122000.0
FROM orders o WHERE o.code='L-2512-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-16'::date, 15122000.0, 'UZS', 15122000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0023', (SELECT id FROM customers WHERE phone='+998 91 660 38 88' LIMIT 1), 'import', '2025-12-22'::date, '2025-12-23'::date, 'delivered', 0, 300, 'left', 'Marg''ilon', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 660 38 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1438, (18511000.0)/1, 0, 0, 18511000.0
FROM orders o WHERE o.code='L-2512-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-23'::date, 18511000.0, 'UZS', 18511000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0023' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0024', (SELECT id FROM customers WHERE phone='+998 91 681 38 06' LIMIT 1), 'import', '2025-12-23'::date, '2025-12-23'::date, 'delivered', 0, 300, 'left', 'Farg''ona tuman', 0, 'Model (asl): MAGNUM, 300 kvm | 30kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 681 38 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0024');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1588, (7397000.0)/1, 0, 0, 7397000.0
FROM orders o WHERE o.code='L-2512-0024' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-23'::date, 7397000.0, 'UZS', 7397000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0024' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0025', (SELECT id FROM customers WHERE phone='+998 91 606 07 06' LIMIT 1), 'import', '2025-12-25'::date, '2025-12-29'::date, 'delivered', 0, 300, NULL, 'ANDIJON BALIQCHI', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 606 07 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1438, (10000000.0)/1, 0, 0, 10000000.0
FROM orders o WHERE o.code='L-2512-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-29'::date, 10000000.0, 'UZS', 10000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0026', (SELECT id FROM customers WHERE phone='+998 77 268 85 77' LIMIT 1), 'import', '2025-12-26'::date, '2026-01-09'::date, 'delivered', 0, 150, 'left', 'Andijon Jalaquduq', 0, 'Model (asl): ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 268 85 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0026');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1238, (13967000.0)/1, 0, 0, 13967000.0
FROM orders o WHERE o.code='L-2512-0026' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-09'::date, 13967000.0, 'UZS', 13967000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0026' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0027', (SELECT id FROM customers WHERE phone='+998 33 631 53 62' LIMIT 1), 'import', '2025-12-27'::date, '2026-01-09'::date, 'delivered', 0, 300, 'right', 'SUX TUMANI', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 631 53 62')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0027');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1438, (11349000.0)/1, 0, 0, 11349000.0
FROM orders o WHERE o.code='L-2512-0027' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-09'::date, 11349000.0, 'UZS', 11349000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0027' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0028', (SELECT id FROM customers WHERE phone='+998 99 990 20 33' LIMIT 1), 'import', '2025-12-27'::date, '2026-01-09'::date, 'delivered', 0, 200, 'right', 'SUX TUMANI', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 990 20 33')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0028');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1238, (10468000.0)/1, 0, 0, 10468000.0
FROM orders o WHERE o.code='L-2512-0028' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-09'::date, 10468000.0, 'UZS', 10468000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0028' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0029', (SELECT id FROM customers WHERE phone='+998 94 414 04 04' LIMIT 1), 'import', '2025-12-29'::date, '2025-12-30'::date, 'delivered', 0, 200, 'left', 'Namangan shahar', 0, 'Model (asl): PREMIUM 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 414 04 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0029');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1188, (13351000.0)/1, 0, 0, 13351000.0
FROM orders o WHERE o.code='L-2512-0029' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2025-12-30'::date, 13351000.0, 'UZS', 13351000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0029' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2512-0030', (SELECT id FROM customers WHERE phone='+998 92 144 08 29' LIMIT 1), 'import', '2025-12-29'::date, '2026-01-06'::date, 'delivered', 0, 300, 'right', 'BESHARIQ KAPAYANGI', 0, 'Model (asl): MAGNUM, 300 kvm | 5 YANVARGA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 92 144 08 29')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2512-0030');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1588, (9519000.0)/1, 0, 0, 9519000.0
FROM orders o WHERE o.code='L-2512-0030' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-06'::date, 9519000.0, 'UZS', 9519000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2512-0030' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0002', (SELECT id FROM customers WHERE phone='+998 91 645 52 56' LIMIT 1), 'import', '2026-01-03'::date, '2026-01-08'::date, 'delivered', 0, 300, 'right', 'Buxoro Romitan', 0, 'Model (asl): PREMIUM 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 645 52 56')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1250, (14062000.0)/1, 0, 0, 14062000.0
FROM orders o WHERE o.code='L-2601-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-08'::date, 14062000.0, 'UZS', 14062000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0004', (SELECT id FROM customers WHERE phone='+998 50 757 39 29' LIMIT 1), 'import', '2026-01-05'::date, '2026-01-10'::date, 'delivered', 0, 400, 'right', 'ANDIJON XUJABOT', 0, 'Model (asl): ULTRA, 400 kvm | ARSTON 52', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 757 39 29')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1879, (21881000.0)/1, 0, 0, 21881000.0
FROM orders o WHERE o.code='L-2601-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-10'::date, 21881000.0, 'UZS', 21881000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0005', (SELECT id FROM customers WHERE phone='+998 88 300 01 62' LIMIT 1), 'import', '2026-01-05'::date, '2026-01-22'::date, 'delivered', 0, 300, 'left', 'Buxoro Jondor', 0, 'Model (asl): OPTIMA, 300 kvm | 15 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 300 01 62')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 2199, (24071000.0)/1, 0, 0, 24071000.0
FROM orders o WHERE o.code='L-2601-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-22'::date, 24071000.0, 'UZS', 24071000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0006', (SELECT id FROM customers WHERE phone='+998 97 562 71 71' LIMIT 1), 'import', '2026-01-05'::date, '2026-01-10'::date, 'delivered', 0, 300, 'left', 'ANDIJON QURQONTEPA', 0, 'Model (asl): MAGNUM, 300 kvm | 5 KUN', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 562 71 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1550, (16800000.0)/1, 0, 0, 16800000.0
FROM orders o WHERE o.code='L-2601-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-10'::date, 16800000.0, 'UZS', 16800000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0007', (SELECT id FROM customers WHERE phone='+998 99 710 06 66' LIMIT 1), 'import', '2026-01-06'::date, '2026-01-18'::date, 'delivered', 0, 300, 'right', 'Termiz shahar', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 710 06 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1200, (13400000.0)/1, 0, 0, 13400000.0
FROM orders o WHERE o.code='L-2601-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-18'::date, 13400000.0, 'UZS', 13400000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0009', (SELECT id FROM customers WHERE phone='+998 93 997 77 05' LIMIT 1), 'import', '2026-01-07'::date, '2026-01-15'::date, 'delivered', 0, 300, 'left', 'Samarqand selski rayon', 0, 'Model (asl): ULTRA, 300 kvm | wifi', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 997 77 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1400, (17213000.0)/1, 0, 0, 17213000.0
FROM orders o WHERE o.code='L-2601-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-15'::date, 17213000.0, 'UZS', 17213000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0010', (SELECT id FROM customers WHERE phone='+998 70 014 88 55' LIMIT 1), 'import', '2026-01-07'::date, '2026-01-14'::date, 'delivered', 0, 300, 'left', 'Andijon asaka', 0, 'Model (asl): MAGNUM, 300 kvm | 13 YANVAR', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 70 014 88 55')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1550, (17405000.0)/1, 0, 0, 17405000.0
FROM orders o WHERE o.code='L-2601-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-14'::date, 17405000.0, 'UZS', 17405000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0012', (SELECT id FROM customers WHERE phone='+998 97 826 19 19' LIMIT 1), 'import', '2026-01-07'::date, '2026-01-20'::date, 'delivered', 0, 200, 'left', 'Buxoro tumani', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 826 19 19')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1250, (13812000.0)/1, 0, 0, 13812000.0
FROM orders o WHERE o.code='L-2601-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-20'::date, 13812000.0, 'UZS', 13812000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0013', (SELECT id FROM customers WHERE phone='+998 50 020 86 76' LIMIT 1), 'import', '2026-01-08'::date, '2026-01-17'::date, 'delivered', 0, 300, 'right', 'Namangan shahar', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 020 86 76')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1400, (1200000.0)/1, 0, 0, 1200000.0
FROM orders o WHERE o.code='L-2601-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-17'::date, 1200000.0, 'UZS', 1200000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0014', (SELECT id FROM customers WHERE phone='+998 99 142 70 91' LIMIT 1), 'import', '2026-01-08'::date, '2026-01-15'::date, 'delivered', 0, 300, 'right', 'Angren shahar', 0, 'Model (asl): ULTRA, 300 kvm | 10 kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 142 70 91')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1400, (15604000.0)/1, 0, 0, 15604000.0
FROM orders o WHERE o.code='L-2601-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-15'::date, 15604000.0, 'UZS', 15604000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0015', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-01-08'::date, '2026-01-16'::date, 'delivered', 0, 200, NULL, 'Muhammadjon santexnik', 0, 'Model (asl): PREMIUM 3, 200 kvm | tezlik bn', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1150, (12811000.0)/1, 0, 0, 12811000.0
FROM orders o WHERE o.code='L-2601-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-16'::date, 12811000.0, 'UZS', 12811000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0016', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-01-08'::date, '2026-01-16'::date, 'delivered', 0, 300, NULL, 'Muhammadjon santexnik', 0, 'Model (asl): PREMIUM 3, 300 kvm | tezlik bn', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1200, (13412000.0)/1, 0, 0, 13412000.0
FROM orders o WHERE o.code='L-2601-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-16'::date, 13412000.0, 'UZS', 13412000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0017', (SELECT id FROM customers WHERE phone='+998 91 667 90 01' LIMIT 1), 'import', '2026-01-09'::date, '2026-01-15'::date, 'delivered', 0, 200, 'left', 'Margilon shahar', 0, 'Model (asl): ULTRA, 200 kvm | seshanba', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 667 90 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1250, (10000000.0)/1, 0, 0, 10000000.0
FROM orders o WHERE o.code='L-2601-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-15'::date, 10000000.0, 'UZS', 10000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0018', (SELECT id FROM customers WHERE phone='+998 95 887 11 00' LIMIT 1), 'import', '2026-01-10'::date, '2026-01-24'::date, 'delivered', 0, 400, 'left', 'uzb tumani yaypan', 0, 'Model (asl): OPTIMA, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 887 11 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 2199, (22780000.0)/1, 0, 0, 22780000.0
FROM orders o WHERE o.code='L-2601-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-24'::date, 22780000.0, 'UZS', 22780000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0020', (SELECT id FROM customers WHERE phone='+998 99 348 97 26' LIMIT 1), 'import', '2026-01-11'::date, '2026-01-18'::date, 'delivered', 0, 200, 'right', 'Qoraqalpogiston', 0, 'Model (asl): PREMIUM 4, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 348 97 26')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 4') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1250, (14212000.0)/1, 0, 0, 14212000.0
FROM orders o WHERE o.code='L-2601-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-18'::date, 14212000.0, 'UZS', 14212000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0021', (SELECT id FROM customers WHERE phone='+998 90 540 94 94' LIMIT 1), 'import', '2026-01-12'::date, '2026-01-20'::date, 'delivered', 0, 400, 'right', 'Namangan Mingbuloq', 0, 'Model (asl): ULTRA, 400 kvm | Bot orqali', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 540 94 94')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1699, (19610000.0)/1, 0, 0, 19610000.0
FROM orders o WHERE o.code='L-2601-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-20'::date, 19610000.0, 'UZS', 19610000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0022', (SELECT id FROM customers WHERE phone='+998 97 547 40 04' LIMIT 1), 'import', '2026-01-14'::date, '2026-01-19'::date, 'delivered', 0, 400, 'left', 'Andijon buloqboshi', 0, 'Model (asl): ULTRA, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 547 40 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1600, (14280000.0)/1, 0, 0, 14280000.0
FROM orders o WHERE o.code='L-2601-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-19'::date, 14280000.0, 'UZS', 14280000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0023', (SELECT id FROM customers WHERE phone='+998 93 455 00 00' LIMIT 1), 'import', '2026-01-14'::date, '2026-01-22'::date, 'delivered', 0, 150, NULL, 'BUXORO diller', 0, 'Model (asl): ULTRA, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 455 00 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1199, (14447000.0)/1, 0, 0, 14447000.0
FROM orders o WHERE o.code='L-2601-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-22'::date, 14447000.0, 'UZS', 14447000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0023' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0024', (SELECT id FROM customers WHERE phone='+998 93 455 00 00' LIMIT 1), 'import', '2026-01-14'::date, '2026-01-22'::date, 'delivered', 0, 200, 'left', 'BUXORO diller', 0, 'Model (asl): ULTRA, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 455 00 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0024');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, (15050000.0)/1, 0, 0, 15050000.0
FROM orders o WHERE o.code='L-2601-0024' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-22'::date, 15050000.0, 'UZS', 15050000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0024' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0025', (SELECT id FROM customers WHERE phone='+998 93 455 00 00' LIMIT 1), 'import', '2026-01-14'::date, '2026-01-22'::date, 'delivered', 0, 300, 'left', 'BUXORO diller', 0, 'Model (asl): ULTRA, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 455 00 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16857000.0)/1, 0, 0, 16857000.0
FROM orders o WHERE o.code='L-2601-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-22'::date, 16857000.0, 'UZS', 16857000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0027', (SELECT id FROM customers WHERE phone='+998 94 150 85 46' LIMIT 1), 'import', '2026-01-16'::date, '2026-01-17'::date, 'delivered', 0, 300, 'right', 'Pop tumani', 0, 'Model (asl): PRO3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 150 85 46')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0027');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PRO3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PRO3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1599, (16066000.0)/1, 0, 0, 16066000.0
FROM orders o WHERE o.code='L-2601-0027' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-17'::date, 16066000.0, 'UZS', 16066000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0027' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0028', (SELECT id FROM customers WHERE phone='+998 90 157 25 35' LIMIT 1), 'import', '2026-01-16'::date, '2026-01-17'::date, 'delivered', 0, 300, 'left', 'Yaypan', 0, 'Model (asl): Magnum, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 157 25 35')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0028');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Magnum') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Magnum') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1550, (18600000.0)/1, 0, 0, 18600000.0
FROM orders o WHERE o.code='L-2601-0028' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-17'::date, 18600000.0, 'UZS', 18600000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0028' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0029', (SELECT id FROM customers WHERE phone='+998 97 331 28 68' LIMIT 1), 'import', '2026-01-17'::date, '2026-02-05'::date, 'delivered', 0, 300, 'left', 'Qashqadaryo', 0, 'Model (asl): OPTIMA, 300 kvm | 4kun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 331 28 68')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0029');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1900, (18000000.0)/1, 0, 0, 18000000.0
FROM orders o WHERE o.code='L-2601-0029' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-05'::date, 18000000.0, 'UZS', 18000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0029' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0030', (SELECT id FROM customers WHERE phone='+998 91 181 23 01' LIMIT 1), 'import', '2026-01-17'::date, '2026-01-27'::date, 'delivered', 0, 300, 'left', 'Norin tumani', 0, 'Model (asl): Magnum, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 181 23 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0030');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Magnum') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Magnum') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1699, (19188000.0)/1, 0, 0, 19188000.0
FROM orders o WHERE o.code='L-2601-0030' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-27'::date, 19188000.0, 'UZS', 19188000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0030' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0031', (SELECT id FROM customers WHERE phone='+996 550883110' LIMIT 1), 'import', '2026-01-19'::date, '2026-01-27'::date, 'delivered', 0, 300, 'left', 'Qirgiziston', 0, 'Model (asl): OPTIMA 26, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+996 550883110')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0031');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 2150, (19882000.0)/1, 0, 0, 19882000.0
FROM orders o WHERE o.code='L-2601-0031' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-27'::date, 19882000.0, 'UZS', 19882000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0031' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0032', (SELECT id FROM customers WHERE phone='+998 97 230 67 67' LIMIT 1), 'import', '2026-01-20'::date, '2026-01-27'::date, 'delivered', 0, 300, 'right', 'Namangan Turaqurg''on', 0, 'Model (asl): OPTIMA 26, 300 kvm | bazalt 2ta def 1ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 230 67 67')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0032');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 2200, (7280000.0)/1, 0, 0, 7280000.0
FROM orders o WHERE o.code='L-2601-0032' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-27'::date, 7280000.0, 'UZS', 7280000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0032' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0033', (SELECT id FROM customers WHERE phone='+998 93 912 41 12' LIMIT 1), 'import', '2026-01-20'::date, '2026-02-01'::date, 'delivered', 0, 400, 'right', 'Namangan', 0, 'Model (asl): OPTIMA 26, 400 kvm | bazalt 3ta def 1ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 912 41 12')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0033');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 2399, (24488000.0)/1, 0, 0, 24488000.0
FROM orders o WHERE o.code='L-2601-0033' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-01'::date, 24488000.0, 'UZS', 24488000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0033' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0034', (SELECT id FROM customers WHERE phone='+998 50 300 16 71' LIMIT 1), 'import', '2026-01-22'::date, '2026-02-09'::date, 'delivered', 0, 150, 'left', 'Samarqand pasturgon', 0, 'Model (asl): OPTIMA 26, 150 kvm | bazalt 5ta def 1ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 300 16 71')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0034');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1850, (15725000.0)/1, 0, 0, 15725000.0
FROM orders o WHERE o.code='L-2601-0034' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-09'::date, 15725000.0, 'UZS', 15725000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0034' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0035', (SELECT id FROM customers WHERE phone='+998 99 593 51 53' LIMIT 1), 'import', '2026-01-22'::date, '2026-01-26'::date, 'delivered', 0, 200, 'left', 'Samarqand Jomboy', 0, 'Model (asl): ULTRA 26, 200 kvm | steklavatalik 4ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 593 51 53')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0035');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1350, (13767000.0)/1, 0, 0, 13767000.0
FROM orders o WHERE o.code='L-2601-0035' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-26'::date, 13767000.0, 'UZS', 13767000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0035' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0036', (SELECT id FROM customers WHERE phone='+998 90 286 83 83' LIMIT 1), 'import', '2026-01-24'::date, '2026-01-26'::date, 'delivered', 0, 300, 'left', 'samarqand toyloq', 0, 'Model (asl): prumum 3, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 286 83 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0036');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('prumum 3') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('prumum 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (15335000.0)/1, 0, 0, 15335000.0
FROM orders o WHERE o.code='L-2601-0036' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-26'::date, 15335000.0, 'UZS', 15335000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0036' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0037', (SELECT id FROM customers WHERE phone='+998 91 129 32 10' LIMIT 1), 'import', '2026-01-24'::date, '2026-01-29'::date, 'delivered', 0, 300, 'left', 'Fargona Mingdon', 0, 'Model (asl): ULTRA 26, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 129 32 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0037');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1500, (15704000.0)/1, 0, 0, 15704000.0
FROM orders o WHERE o.code='L-2601-0037' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-29'::date, 15704000.0, 'UZS', 15704000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0037' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0038', (SELECT id FROM customers WHERE phone='+998 90 633 06 90' LIMIT 1), 'import', '2026-01-24'::date, '2026-01-29'::date, 'delivered', 0, 300, 'right', 'Fargona Mingdon', 0, 'Model (asl): ULTRA 26, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 633 06 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0038');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1500, (15704000.0)/1, 0, 0, 15704000.0
FROM orders o WHERE o.code='L-2601-0038' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-29'::date, 15704000.0, 'UZS', 15704000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0038' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0039', (SELECT id FROM customers WHERE phone='+998 94 297 90 90' LIMIT 1), 'import', '2026-01-24'::date, '2026-01-25'::date, 'delivered', 0, 200, 'left', 'Namangan shahar', 0, 'Model (asl): prumum 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 297 90 90')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0039');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('prumum 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('prumum 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1200, (13496000.0)/1, 0, 0, 13496000.0
FROM orders o WHERE o.code='L-2601-0039' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-25'::date, 13496000.0, 'UZS', 13496000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0039' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0040', (SELECT id FROM customers WHERE phone='+998 91 126 20 06' LIMIT 1), 'import', '2026-01-26'::date, '2026-01-26'::date, 'delivered', 0, 300, 'right', 'QUVA TUMANI', 0, 'Model (asl): MAGNUM, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 126 20 06')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0040');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1600, (19267000.0)/1, 0, 0, 19267000.0
FROM orders o WHERE o.code='L-2601-0040' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-26'::date, 19267000.0, 'UZS', 19267000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0040' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0041', (SELECT id FROM customers WHERE phone='+998 95 185 31 95' LIMIT 1), 'import', '2026-01-26'::date, '2026-01-27'::date, 'delivered', 0, 300, 'left', 'SAMARQAND ISHTIXON', 0, 'Model (asl): OPTIMA 26, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 185 31 95')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0041');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 2200, (26576000.0)/1, 0, 0, 26576000.0
FROM orders o WHERE o.code='L-2601-0041' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-27'::date, 26576000.0, 'UZS', 26576000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0041' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0042', (SELECT id FROM customers WHERE phone='+998 93 058 88 72' LIMIT 1), 'import', '2026-01-27'::date, '2026-01-29'::date, 'delivered', 0, 500, 'left', 'ANDIJON V IZBOSGAN', 0, 'Model (asl): ULTRA 26, 500 kvm | Bazalt 5ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 058 88 72')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0042');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1800, (21740000.0)/1, 0, 0, 21740000.0
FROM orders o WHERE o.code='L-2601-0042' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-01-29'::date, 21740000.0, 'UZS', 21740000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0042' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0043', (SELECT id FROM customers WHERE phone='+998 91 176 15 40' LIMIT 1), 'import', '2026-01-28'::date, '2026-02-01'::date, 'delivered', 0, 300, NULL, 'Andijon shahar', 0, 'Model (asl): prumum 3 26, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 176 15 40')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0043');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('prumum 3 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('prumum 3 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1350, (12693000.0)/1, 0, 0, 12693000.0
FROM orders o WHERE o.code='L-2601-0043' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-01'::date, 12693000.0, 'UZS', 12693000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0043' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0044', (SELECT id FROM customers WHERE phone='+998 97 350 66 82' LIMIT 1), 'import', '2026-01-28'::date, '2026-02-06'::date, 'delivered', 0, 150, 'right', 'Surxandaryo Sarosiyo', 0, 'Model (asl): 2026 PRO, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 350 66 82')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0044');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('2026 PRO') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('2026 PRO') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1250, (7625000.0)/1, 0, 0, 7625000.0
FROM orders o WHERE o.code='L-2601-0044' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-06'::date, 7625000.0, 'UZS', 7625000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0044' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0045', (SELECT id FROM customers WHERE phone='+998 90 156 70 15' LIMIT 1), 'import', '2026-01-29'::date, '2026-02-04'::date, 'delivered', 0, 300, 'left', 'Namangan chust', 0, 'Model (asl): OPTIMA 26, 300 kvm | 4 fevralga', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 156 70 15')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0045');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 2200, (20604000.0)/1, 0, 0, 20604000.0
FROM orders o WHERE o.code='L-2601-0045' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-04'::date, 20604000.0, 'UZS', 20604000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0045' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2601-0046', (SELECT id FROM customers WHERE phone='+998 99 699 27 28' LIMIT 1), 'import', '2026-01-30'::date, '2026-02-05'::date, 'delivered', 0, 200, 'right', 'Namangan shahar', 0, 'Model (asl): ULTRA 25, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 699 27 28')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2601-0046');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 25') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 25') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1250, (14487000.0)/1, 0, 0, 14487000.0
FROM orders o WHERE o.code='L-2601-0046' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-05'::date, 14487000.0, 'UZS', 14487000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2601-0046' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0002', (SELECT id FROM customers WHERE phone='+998 93 520 01 93' LIMIT 1), 'import', '2026-02-01'::date, '2026-02-02'::date, 'delivered', 0, 200, 'right', 'Samarqand', 0, 'Model (asl): Ultra 25, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 520 01 93')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 25') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 25') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1250, (14775000.0)/1, 0, 0, 14775000.0
FROM orders o WHERE o.code='L-2602-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-02'::date, 14775000.0, 'UZS', 14775000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0003', (SELECT id FROM customers WHERE phone='+998 94 660 54 87' LIMIT 1), 'import', '2026-02-04'::date, '2026-02-05'::date, 'delivered', 0, 200, 'left', 'NAMMANGAN QUMQURGON', 0, 'Model (asl): MAGNUM, 200 kvm | bazalt 4ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 660 54 87')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (17094000.0)/1, 0, 0, 17094000.0
FROM orders o WHERE o.code='L-2602-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-05'::date, 17094000.0, 'UZS', 17094000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0004', (SELECT id FROM customers WHERE phone='+998 93 144 86 18' LIMIT 1), 'import', '2026-02-07'::date, '2026-02-09'::date, 'delivered', 0, 200, 'right', 'DANGARA OGJAR', 0, 'Model (asl): Ultra 26, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 144 86 18')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1300, (15964000.0)/1, 0, 0, 15964000.0
FROM orders o WHERE o.code='L-2602-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-09'::date, 15964000.0, 'UZS', 15964000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0005', (SELECT id FROM customers WHERE phone='+998 94 619 86 62' LIMIT 1), 'import', '2026-02-09'::date, '2026-02-10'::date, 'delivered', 0, 200, 'right', 'Andijon Buloqboshi', 0, 'Model (asl): Ultra 26, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 619 86 62')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1300, (15477000.0)/1, 0, 0, 15477000.0
FROM orders o WHERE o.code='L-2602-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-10'::date, 15477000.0, 'UZS', 15477000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0006', (SELECT id FROM customers WHERE phone='+998 90 384 33 63' LIMIT 1), 'import', '2026-02-09'::date, '2026-02-10'::date, 'delivered', 0, 400, 'left', 'andijon shaxrixon', 0, 'Model (asl): Ultra 26, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 384 33 63')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1650, (20295000.0)/1, 0, 0, 20295000.0
FROM orders o WHERE o.code='L-2602-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-10'::date, 20295000.0, 'UZS', 20295000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0007', (SELECT id FROM customers WHERE phone='+998 90 507 14 19' LIMIT 1), 'import', '2026-02-10'::date, '2026-02-27'::date, 'delivered', 0, 300, 'left', 'Qoqon', 0, 'Model (asl): Ultra 26, 300 kvm | 296*5+420', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 507 14 19')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1500, (18450000.0)/1, 0, 0, 18450000.0
FROM orders o WHERE o.code='L-2602-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-27'::date, 18450000.0, 'UZS', 18450000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0008', (SELECT id FROM customers WHERE phone='+998 88 911 20 00' LIMIT 1), 'import', '2026-02-11'::date, '2026-02-20'::date, 'delivered', 0, 200, 'right', 'Samarqand', 0, 'Model (asl): Ultra 26, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 911 20 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1350, (15605000.0)/1, 0, 0, 15605000.0
FROM orders o WHERE o.code='L-2602-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-20'::date, 15605000.0, 'UZS', 15605000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0009', (SELECT id FROM customers WHERE phone='+998 97 391 91 66' LIMIT 1), 'import', '2026-02-13'::date, '2026-02-16'::date, 'delivered', 0, 500, 'right', 'Samarqand', 0, 'Model (asl): Ultra 26, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 391 91 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1650, (3995000.0)/1, 0, 0, 3995000.0
FROM orders o WHERE o.code='L-2602-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-16'::date, 3995000.0, 'UZS', 3995000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0010', (SELECT id FROM customers WHERE phone='+998 99 518 11 26' LIMIT 1), 'import', '2026-02-13'::date, '2026-02-16'::date, 'delivered', 0, 200, 'left', 'BESHKAPA', 0, 'Model (asl): Ultra 26, 200 kvm | bazalt 3ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 518 11 26')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1400, (18421000.0)/1, 0, 0, 18421000.0
FROM orders o WHERE o.code='L-2602-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-16'::date, 18421000.0, 'UZS', 18421000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0011', (SELECT id FROM customers WHERE phone='+998 97 060 81 31' LIMIT 1), 'import', '2026-02-14'::date, '2026-02-15'::date, 'delivered', 0, 300, 'right', 'andijon shaxrixon', 0, 'Model (asl): Ultra 26, 300 kvm | 296*6+420', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 060 81 31')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1500, (18330000.0)/1, 0, 0, 18330000.0
FROM orders o WHERE o.code='L-2602-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-15'::date, 18330000.0, 'UZS', 18330000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0012', (SELECT id FROM customers WHERE phone='+998 90 277 78 55' LIMIT 1), 'import', '2026-02-15'::date, '2026-02-15'::date, 'delivered', 0, 300, 'right', 'Qo''shtepa tuman', 0, 'Model (asl): Pr 3 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 277 78 55')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1350, (15470000.0)/1, 0, 0, 15470000.0
FROM orders o WHERE o.code='L-2602-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-15'::date, 15470000.0, 'UZS', 15470000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0013', (SELECT id FROM customers WHERE phone='+998 95 859 80 99' LIMIT 1), 'import', '2026-02-16'::date, '2026-02-20'::date, 'delivered', 0, 200, 'right', 'ANDIJON BALIQCHI', 0, 'Model (asl): OPTIMA 1, 200 kvm | bazalt 3ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 859 80 99')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 2000, (26100000.0)/1, 0, 0, 26100000.0
FROM orders o WHERE o.code='L-2602-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-20'::date, 26100000.0, 'UZS', 26100000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0014', (SELECT id FROM customers WHERE phone='+998 33 989 30 30' LIMIT 1), 'import', '2026-02-20'::date, '2026-02-20'::date, 'delivered', 0, 400, 'right', 'ANDIJON OLTINKUL', 0, 'Model (asl): Pr 3 2026, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 989 30 30')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1400, (17038000.0)/1, 0, 0, 17038000.0
FROM orders o WHERE o.code='L-2602-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-20'::date, 17038000.0, 'UZS', 17038000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0015', (SELECT id FROM customers WHERE phone='+998 91 143 87 57' LIMIT 1), 'import', '2026-02-21'::date, '2026-02-20'::date, 'delivered', 0, 150, 'left', 'Andijon Marxamat', 0, 'Model (asl): Pr 3 2026, 150 kvm | 296*3ta + 420', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 143 87 57')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1200, (15948000.0)/1, 0, 0, 15948000.0
FROM orders o WHERE o.code='L-2602-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-20'::date, 15948000.0, 'UZS', 15948000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0016', (SELECT id FROM customers WHERE phone='+998 90 163 83 83' LIMIT 1), 'import', '2026-02-26'::date, '2026-02-26'::date, 'delivered', 0, 200, 'right', 'FARGONA TOSHLOQ', 0, 'Model (asl): Pr 3 2025, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 163 83 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2025') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2025') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1200, (14520000.0)/1, 0, 0, 14520000.0
FROM orders o WHERE o.code='L-2602-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-26'::date, 14520000.0, 'UZS', 14520000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0017', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-02-27'::date, '2026-02-28'::date, 'delivered', 0, 300, 'right', 'Samarqand shahar', 0, 'Model (asl): Pr 3 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1339, (16268000.0)/1, 0, 0, 16268000.0
FROM orders o WHERE o.code='L-2602-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-28'::date, 16268000.0, 'UZS', 16268000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2602-0018', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-02-27'::date, '2026-02-28'::date, 'delivered', 0, 300, 'right', 'Samarqand shahar', 0, 'Model (asl): Pr 3 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2602-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Pr 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1339, (16268000.0)/1, 0, 0, 16268000.0
FROM orders o WHERE o.code='L-2602-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-02-28'::date, 16268000.0, 'UZS', 16268000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2602-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0002', (SELECT id FROM customers WHERE phone='+998 91 652 60 66' LIMIT 1), 'import', '2026-03-04'::date, '2026-03-07'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): ULTRA 25, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 60 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 25') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 25') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1300, (15860000.0)/1, 0, 0, 15860000.0
FROM orders o WHERE o.code='L-2603-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-07'::date, 15860000.0, 'UZS', 15860000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0003', (SELECT id FROM customers WHERE phone='+998 88 573 20 20' LIMIT 1), 'import', '2026-03-05'::date, '2026-03-07'::date, 'delivered', 0, 200, 'left', 'Namangan', 0, 'Model (asl): ULTRA 26, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 573 20 20')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1388, (16905000.0)/1, 0, 0, 16905000.0
FROM orders o WHERE o.code='L-2603-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-07'::date, 16905000.0, 'UZS', 16905000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0004', (SELECT id FROM customers WHERE phone='+998 93 129 80 08' LIMIT 1), 'import', '2026-03-05'::date, '2026-03-07'::date, 'delivered', 0, 300, 'right', 'Samarqand', 0, 'Model (asl): OPTIMA 1, 300 kvm | 296 X3', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 129 80 08')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 2188, (27500000.0)/1, 0, 0, 27500000.0
FROM orders o WHERE o.code='L-2603-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-07'::date, 27500000.0, 'UZS', 27500000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0005', (SELECT id FROM customers WHERE phone='+998 99 627 73 77' LIMIT 1), 'import', '2026-03-09'::date, '2026-03-13'::date, 'delivered', 0, 400, 'left', 'Samarqand', 0, 'Model (asl): MAGNUM 26, 400 kvm | Dimahod maxsus', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 627 73 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1831, (16210000.0)/1, 0, 0, 16210000.0
FROM orders o WHERE o.code='L-2603-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-13'::date, 16210000.0, 'UZS', 16210000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0006', (SELECT id FROM customers WHERE phone='+998 90 737 37 00' LIMIT 1), 'import', '2026-03-09'::date, '2026-03-13'::date, 'delivered', 0, 300, 'left', 'Xorazm', 0, 'Model (asl): ULTRA 26, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 737 37 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1449, (16692000.0)/1, 0, 0, 16692000.0
FROM orders o WHERE o.code='L-2603-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-13'::date, 16692000.0, 'UZS', 16692000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0007', (SELECT id FROM customers WHERE phone='+998 93 201 00 33' LIMIT 1), 'import', '2026-03-09'::date, '2026-03-13'::date, 'delivered', 0, 300, 'right', 'Xorazm', 0, 'Model (asl): ULTRA 26, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 201 00 33')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1449, (16689000.0)/1, 0, 0, 16689000.0
FROM orders o WHERE o.code='L-2603-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-13'::date, 16689000.0, 'UZS', 16689000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0008', (SELECT id FROM customers WHERE phone='+992 900889168' LIMIT 1), 'import', '2026-03-13'::date, '2026-03-27'::date, 'delivered', 0, 150, 'right', 'Tojikiston', 0, 'Model (asl): PREMIUM 3 2026, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+992 900889168')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1199, (3377000.0)/1, 0, 0, 3377000.0
FROM orders o WHERE o.code='L-2603-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-27'::date, 3377000.0, 'UZS', 3377000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0009', (SELECT id FROM customers WHERE phone='+998 93 046 72 22' LIMIT 1), 'import', '2026-03-14'::date, '2026-03-28'::date, 'delivered', 0, 500, 'right', 'Farg''ona', 0, 'Model (asl): MAGNUM, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 046 72 22')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 2100, (19520000.0)/1, 0, 0, 19520000.0
FROM orders o WHERE o.code='L-2603-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-28'::date, 19520000.0, 'UZS', 19520000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0010', (SELECT id FROM customers WHERE phone='+998 94 278 88 18' LIMIT 1), 'import', '2026-03-15'::date, '2026-03-17'::date, 'delivered', 0, 150, 'left', 'Namangan', 0, 'Model (asl): PREMIUM 3 2026, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 278 88 18')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1200, (12100000.0)/1, 0, 0, 12100000.0
FROM orders o WHERE o.code='L-2603-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-17'::date, 12100000.0, 'UZS', 12100000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0011', (SELECT id FROM customers WHERE phone='+998 33 150 50 52' LIMIT 1), 'import', '2026-03-15'::date, '2026-04-22'::date, 'delivered', 0, 200, 'right', 'Andijon', 0, 'Model (asl): Ultra 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 150 50 52')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('Ultra 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1400, (15730000.0)/1, 0, 0, 15730000.0
FROM orders o WHERE o.code='L-2603-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-22'::date, 15730000.0, 'UZS', 15730000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0012', (SELECT id FROM customers WHERE phone='+998 94 303 78 05' LIMIT 1), 'import', '2026-03-16'::date, '2026-03-28'::date, 'delivered', 0, 300, 'right', 'Namangan', 0, 'Model (asl): ULTRA 26, 300 kvm | SHANBA', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 303 78 05')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1500, (16150000.0)/1, 0, 0, 16150000.0
FROM orders o WHERE o.code='L-2603-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-28'::date, 16150000.0, 'UZS', 16150000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0013', (SELECT id FROM customers WHERE phone='+998 90 155 07 11' LIMIT 1), 'import', '2026-03-16'::date, '2026-03-28'::date, 'delivered', 0, 400, 'left', 'Farg''ona', 0, 'Model (asl): ULTRA 26, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 155 07 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1649, (17605000.0)/1, 0, 0, 17605000.0
FROM orders o WHERE o.code='L-2603-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-28'::date, 17605000.0, 'UZS', 17605000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0014', (SELECT id FROM customers WHERE phone='+998 33 212 07 17' LIMIT 1), 'import', '2026-03-17'::date, '2026-04-25'::date, 'delivered', 0, 200, 'right', 'Jizzax', 0, 'Model (asl): MAGNUM 26, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 212 07 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1449, (3005000.0)/1, 0, 0, 3005000.0
FROM orders o WHERE o.code='L-2603-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-25'::date, 3005000.0, 'UZS', 3005000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0015', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-03-21'::date, '2026-03-25'::date, 'delivered', 0, 400, 'right', 'Samarqand', 0, 'Model (asl): PREMIUM 3 2026, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3 2026') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (16390000.0)/1, 0, 0, 16390000.0
FROM orders o WHERE o.code='L-2603-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-25'::date, 16390000.0, 'UZS', 16390000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0016', (SELECT id FROM customers WHERE phone='+998 94 010 76 98' LIMIT 1), 'import', '2026-03-21'::date, '2026-04-23'::date, 'delivered', 0, 300, 'left', 'Andijon', 0, 'Model (asl): MAGNUM 26, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 010 76 98')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (15847000.0)/1, 0, 0, 15847000.0
FROM orders o WHERE o.code='L-2603-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-23'::date, 15847000.0, 'UZS', 15847000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0017', (SELECT id FROM customers WHERE phone='+998 97 661 41 14' LIMIT 1), 'import', '2026-03-22'::date, '2026-03-24'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): ULTRA 26, 200 kvm | 35x3 440 000', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 661 41 14')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1299, (13394000.0)/1, 0, 0, 13394000.0
FROM orders o WHERE o.code='L-2603-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-24'::date, 13394000.0, 'UZS', 13394000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0018', (SELECT id FROM customers WHERE phone='+998 93 816 10 10' LIMIT 1), 'import', '2026-03-22'::date, '2026-03-25'::date, 'delivered', 0, 200, 'right', 'Andijon', 0, 'Model (asl): MAGNUM 26, 200 kvm | 296 X3 440 000', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 816 10 10')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1449, (19262000.0)/1, 0, 0, 19262000.0
FROM orders o WHERE o.code='L-2603-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-25'::date, 19262000.0, 'UZS', 19262000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0019', (SELECT id FROM customers WHERE phone='+998 93 789 10 02' LIMIT 1), 'import', '2026-03-24'::date, '2026-03-28'::date, 'delivered', 0, 400, NULL, 'Andijon', 0, 'Model (asl): MAGNUM 26, 400 kvm | bunker orqa', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 789 10 02')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0019');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('MAGNUM 26') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, NULL, 1999, (21870000.0)/1, 0, 0, 21870000.0
FROM orders o WHERE o.code='L-2603-0019' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-28'::date, 21870000.0, 'UZS', 21870000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0019' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0020', (SELECT id FROM customers WHERE phone='+998 91 680 34 03' LIMIT 1), 'import', '2026-03-27'::date, '2026-03-30'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): premium 4 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 680 34 03')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 4 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 4 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (15039000.0)/1, 0, 0, 15039000.0
FROM orders o WHERE o.code='L-2603-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-03-30'::date, 15039000.0, 'UZS', 15039000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0021', (SELECT id FROM customers WHERE phone='+998 97 395 31 11' LIMIT 1), 'import', '2026-03-31'::date, '2026-04-04'::date, 'delivered', 0, 400, 'right', 'Samarqand', 0, 'Model (asl): ULTRA 26 2 model, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 395 31 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26 2 model') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 26 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1800, (19960000.0)/1, 0, 0, 19960000.0
FROM orders o WHERE o.code='L-2603-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-04'::date, 19960000.0, 'UZS', 19960000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2603-0022', (SELECT id FROM customers WHERE phone='+998 77 577 00 62' LIMIT 1), 'import', '2026-03-31'::date, '2026-04-10'::date, 'delivered', 0, 200, 'left', 'Namangan', 0, 'Model (asl): ULTRA 25, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 577 00 62')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2603-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 25') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 25') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1299, (15347000.0)/1, 0, 0, 15347000.0
FROM orders o WHERE o.code='L-2603-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-10'::date, 15347000.0, 'UZS', 15347000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2603-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0002', (SELECT id FROM customers WHERE phone='+998 93 368 38 63' LIMIT 1), 'import', '2026-04-01'::date, '2026-04-07'::date, 'delivered', 0, 200, 'right', 'Qoraqalpog''iston', 0, 'Model (asl): ULTRA 1, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 368 38 63')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1400, (1000000.0)/1, 0, 0, 1000000.0
FROM orders o WHERE o.code='L-2604-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-07'::date, 1000000.0, 'UZS', 1000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0003', (SELECT id FROM customers WHERE phone='+998 93 799 81 20' LIMIT 1), 'import', '2026-04-02'::date, '2026-04-02'::date, 'delivered', 0, 200, 'right', 'Surxondaryo', 0, 'Model (asl): ULTRA 1, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 799 81 20')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1400, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2604-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0004', (SELECT id FROM customers WHERE phone='+998 90 571 11 14' LIMIT 1), 'import', '2026-04-02'::date, '2026-04-04'::date, 'delivered', 0, 300, 'right', 'Andijon', 0, 'Model (asl): OPTIMA 1, 300 kvm | 35*3(1)', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 571 11 14')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 2200, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2604-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0005', (SELECT id FROM customers WHERE phone='+998 93 645 00 20' LIMIT 1), 'import', '2026-04-03'::date, '2026-04-16'::date, 'delivered', 0, 200, 'right', 'Namangan', 0, 'Model (asl): ULTRA 25, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 645 00 20')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 25') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 25') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1300, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2604-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0006', (SELECT id FROM customers WHERE phone='+998 70 051 78 77' LIMIT 1), 'import', '2026-04-04'::date, '2026-04-07'::date, 'delivered', 0, 200, 'left', 'Xorazm', 0, 'Model (asl): magnum 1, 200 kvm | 296x3 1 defzor', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 70 051 78 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (1580000.0)/1, 0, 0, 1580000.0
FROM orders o WHERE o.code='L-2604-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-07'::date, 1580000.0, 'UZS', 1580000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0007', (SELECT id FROM customers WHERE phone='+998 94 496 17 34' LIMIT 1), 'import', '2026-04-06'::date, '2026-04-17'::date, 'delivered', 0, 200, 'right', 'Farg''ona', 0, 'Model (asl): ultra 26 2 model, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 496 17 34')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 26 2 model') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 26 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1599, (1000000.0)/1, 0, 0, 1000000.0
FROM orders o WHERE o.code='L-2604-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-17'::date, 1000000.0, 'UZS', 1000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0008', (SELECT id FROM customers WHERE phone='+998 91 149 50 17' LIMIT 1), 'import', '2026-04-09'::date, '2026-04-10'::date, 'delivered', 0, 200, 'right', 'Farg''ona', 0, 'Model (asl): ULTRA 1, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 149 50 17')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1400, (1220000.0)/1, 0, 0, 1220000.0
FROM orders o WHERE o.code='L-2604-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-10'::date, 1220000.0, 'UZS', 1220000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0009', (SELECT id FROM customers WHERE phone='+998 91 647 59 36' LIMIT 1), 'import', '2026-04-10'::date, '2026-04-16'::date, 'delivered', 0, 200, 'left', 'Buxoro', 0, 'Model (asl): ultra 2 model, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 647 59 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1599, (3654000.0)/1, 0, 0, 3654000.0
FROM orders o WHERE o.code='L-2604-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-16'::date, 3654000.0, 'UZS', 3654000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0009' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0010', (SELECT id FROM customers WHERE phone='+998 95 480 55 65' LIMIT 1), 'import', '2026-04-10'::date, '2026-04-23'::date, 'delivered', 0, 300, 'left', 'Buxoro', 0, 'Model (asl): ultra 2 model, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 480 55 65')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1699, (300000.0)/1, 0, 0, 300000.0
FROM orders o WHERE o.code='L-2604-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-23'::date, 300000.0, 'UZS', 300000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0011', (SELECT id FROM customers WHERE phone='+998 94 947 77 11' LIMIT 1), 'import', '2026-04-12'::date, '2026-04-13'::date, 'delivered', 0, 150, 'right', 'Farg''ona', 0, 'Model (asl): magnum 1, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 947 77 11')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2604-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0012', (SELECT id FROM customers WHERE phone='+998 50 599 84 48' LIMIT 1), 'import', '2026-04-13'::date, '2026-04-16'::date, 'delivered', 0, 200, 'right', 'Qoraqalpog''iston', 0, 'Model (asl): OPTIMA 1, 200 kvm | 296x5 1 defzor', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 599 84 48')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 2049, (3000000.0)/1, 0, 0, 3000000.0
FROM orders o WHERE o.code='L-2604-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-16'::date, 3000000.0, 'UZS', 3000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0013', (SELECT id FROM customers WHERE phone='+998 90 360 00 53' LIMIT 1), 'import', '2026-04-15'::date, '2026-04-16'::date, 'delivered', 0, 300, 'right', 'Farg''ona', 0, 'Model (asl): magnum 1, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 360 00 53')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1550, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2604-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0014', (SELECT id FROM customers WHERE phone='+998 99 416 70 70' LIMIT 1), 'import', '2026-04-17'::date, '2026-04-20'::date, 'delivered', 0, 300, 'left', 'Surxondaryo', 0, 'Model (asl): OPTIMA 1, 300 kvm | 4 x 35 $ 28$', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 416 70 70')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 2188, (1000000.0)/1, 0, 0, 1000000.0
FROM orders o WHERE o.code='L-2604-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-20'::date, 1000000.0, 'UZS', 1000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0015', (SELECT id FROM customers WHERE phone='+998 93 219 94 26' LIMIT 1), 'import', '2026-04-20'::date, '2026-04-21'::date, 'delivered', 0, 200, 'left', 'Namangan', 0, 'Model (asl): ultra 2 model, 200 kvm | 4 x 35 $ 25$', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 219 94 26')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1588, (1215000.0)/1, 0, 0, 1215000.0
FROM orders o WHERE o.code='L-2604-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-21'::date, 1215000.0, 'UZS', 1215000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0015' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0016', (SELECT id FROM customers WHERE phone='+998 91 282 08 43' LIMIT 1), 'import', '2026-04-22'::date, '2026-04-24'::date, 'delivered', 0, 150, 'right', 'Farg''ona', 0, 'Model (asl): ultra 1 model, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 282 08 43')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 model') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (500000.0)/1, 0, 0, 500000.0
FROM orders o WHERE o.code='L-2604-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-24'::date, 500000.0, 'UZS', 500000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0017', (SELECT id FROM customers WHERE phone='+998 93 730 67 76' LIMIT 1), 'import', '2026-04-23'::date, '2026-04-29'::date, 'delivered', 0, 400, 'left', 'Qirg''iziston', 0, 'Model (asl): magnum 1, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 730 67 76')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0017');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1788, (2412000.0)/1, 0, 0, 2412000.0
FROM orders o WHERE o.code='L-2604-0017' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-29'::date, 2412000.0, 'UZS', 2412000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0017' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0018', (SELECT id FROM customers WHERE phone='+998 97 030 07 69' LIMIT 1), 'import', '2026-04-24'::date, '2026-04-25'::date, 'delivered', 0, 300, 'left', 'Samarqand', 0, 'Model (asl): magnum 2 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 030 07 69')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0018');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 2 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 2 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1688, (1200000.0)/1, 0, 0, 1200000.0
FROM orders o WHERE o.code='L-2604-0018' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-25'::date, 1200000.0, 'UZS', 1200000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0018' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0019', (SELECT id FROM customers WHERE phone='+998 99 157 34 34' LIMIT 1), 'import', '2026-04-25'::date, '2026-04-28'::date, 'delivered', 0, 300, 'right', 'Samarqand', 0, 'Model (asl): ultra 2 model, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 157 34 34')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0019');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1688, (1200000.0)/1, 0, 0, 1200000.0
FROM orders o WHERE o.code='L-2604-0019' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-28'::date, 1200000.0, 'UZS', 1200000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0019' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0020', (SELECT id FROM customers WHERE phone='+998 95 665 01 01' LIMIT 1), 'import', '2026-04-26'::date, '2026-04-27'::date, 'delivered', 0, 300, 'right', 'Farg''ona', 0, 'Model (asl): ultra 2 model, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 665 01 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0020');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1688, (1200000.0)/1, 0, 0, 1200000.0
FROM orders o WHERE o.code='L-2604-0020' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-27'::date, 1200000.0, 'UZS', 1200000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0020' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0021', (SELECT id FROM customers WHERE phone='+998 90 221 27 62' LIMIT 1), 'import', '2026-04-27'::date, '2026-04-29'::date, 'delivered', 0, 200, 'left', 'Andijon', 0, 'Model (asl): ultra 2 model, 200 kvm | 3 x 25$ 19 $', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 221 27 62')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1588, (4832000.0)/1, 0, 0, 4832000.0
FROM orders o WHERE o.code='L-2604-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-29'::date, 4832000.0, 'UZS', 4832000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0022', (SELECT id FROM customers WHERE phone='+998 91 147 51 40' LIMIT 1), 'import', '2026-04-28'::date, '2026-04-29'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): pro 26 2 model, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 147 51 40')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro 26 2 model') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('pro 26 2 model') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1338, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2604-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0023', (SELECT id FROM customers WHERE phone='+992 171455504' LIMIT 1), 'import', '2026-04-29'::date, '2026-05-01'::date, 'delivered', 0, 200, 'left', 'Tojikiston', 0, 'Model (asl): magnum 1, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+992 171455504')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1488, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2604-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0024', (SELECT id FROM customers WHERE phone='+998 99 864 90 24' LIMIT 1), 'import', '2026-04-30'::date, '2026-04-30'::date, 'delivered', 0, 200, 'right', 'Farg''ona', 0, 'Model (asl): PREMIUM 3, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 864 90 24')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0024');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('PREMIUM 3') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1238, (14300000.0)/1, 0, 0, 14300000.0
FROM orders o WHERE o.code='L-2604-0024' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-30'::date, 14300000.0, 'UZS', 14300000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0024' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0025', (SELECT id FROM customers WHERE phone='+998 90 549 80 37' LIMIT 1), 'import', '2026-04-30'::date, '2026-04-30'::date, 'delivered', 0, 300, 'right', 'Andijon', 0, 'Model (asl): ULTRA 2, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 549 80 37')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 2') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 2') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1688, (500000.0)/1, 0, 0, 500000.0
FROM orders o WHERE o.code='L-2604-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-04-30'::date, 500000.0, 'UZS', 500000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2604-0026', (SELECT id FROM customers WHERE phone='+998 91 045 09 73' LIMIT 1), 'import', '2026-04-30'::date, '2026-05-01'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): magnum 1, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 045 09 73')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2604-0026');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1479, (10750000.0)/1, 0, 0, 10750000.0
FROM orders o WHERE o.code='L-2604-0026' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-01'::date, 10750000.0, 'UZS', 10750000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2604-0026' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0002', (SELECT id FROM customers WHERE phone='+998 91 118 43 21' LIMIT 1), 'import', '2026-05-01'::date, '2026-05-02'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): magnum 1, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 118 43 21')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1488, (17356000.0)/1, 0, 0, 17356000.0
FROM orders o WHERE o.code='L-2605-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-02'::date, 17356000.0, 'UZS', 17356000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0003', (SELECT id FROM customers WHERE phone='+998 97 990 07 60' LIMIT 1), 'import', '2026-05-03'::date, '2026-05-04'::date, 'delivered', 0, 150, 'left', 'Andijon', 0, 'Model (asl): magnum 1, 150 kvm | 35$ 3 ta 28 $', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 990 07 60')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1489, (17868000.0)/1, 0, 0, 17868000.0
FROM orders o WHERE o.code='L-2605-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-04'::date, 17868000.0, 'UZS', 17868000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0004', (SELECT id FROM customers WHERE phone='+998 91 652 60 66' LIMIT 1), 'import', '2026-05-04'::date, '2026-05-05'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): ULTRA 2025, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 60 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 2025') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ULTRA 2025') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1300, (14588000.0)/1, 0, 0, 14588000.0
FROM orders o WHERE o.code='L-2605-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-05'::date, 14588000.0, 'UZS', 14588000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0005', (SELECT id FROM customers WHERE phone='+998 90 552 06 07' LIMIT 1), 'import', '2026-05-04'::date, '2026-05-05'::date, 'delivered', 0, 300, 'right', 'Namangan', 0, 'Model (asl): ultra 1 2026, 300 kvm | 30$ 4 ta 20 $', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 552 06 07')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (19668000.0)/1, 0, 0, 19668000.0
FROM orders o WHERE o.code='L-2605-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-05'::date, 19668000.0, 'UZS', 19668000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0006', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-05'::date, '2026-05-07'::date, 'delivered', 0, 200, 'right', 'Samarqand', 0, 'Model (asl): premium3 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1249, (62144000.0)/1, 0, 0, 62144000.0
FROM orders o WHERE o.code='L-2605-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-07'::date, 62144000.0, 'UZS', 62144000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0007', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-05'::date, '2026-05-07'::date, 'delivered', 0, 200, 'left', 'Samarqand', 0, 'Model (asl): premium3 2026, 200 kvm | 4 ta chugun gtarelka', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1249, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2605-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0008', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-05'::date, '2026-05-07'::date, 'delivered', 0, 300, 'right', 'Samarqand', 0, 'Model (asl): premium3 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2605-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0009', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-05'::date, '2026-05-07'::date, 'delivered', 0, 300, 'left', 'Samarqand', 0, 'Model (asl): premium3 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0009');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2605-0009' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0010', (SELECT id FROM customers WHERE phone='+998 94 407 00 23' LIMIT 1), 'import', '2026-05-06'::date, '2026-05-07'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): OPTIMA 1, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 407 00 23')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('OPTIMA 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1999, (20000000.0)/1, 0, 0, 20000000.0
FROM orders o WHERE o.code='L-2605-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-07'::date, 20000000.0, 'UZS', 20000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0011', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-06'::date, '2026-05-14'::date, 'delivered', 0, 500, 'right', 'Samarqand', 0, 'Model (asl): premium3 2026, 500 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0011');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=500 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (18062000.0)/1, 0, 0, 18062000.0
FROM orders o WHERE o.code='L-2605-0011' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-14'::date, 18062000.0, 'UZS', 18062000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0011' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0012', (SELECT id FROM customers WHERE phone='+998 93 482 35 00' LIMIT 1), 'import', '2026-05-06'::date, '2026-05-14'::date, 'delivered', 0, 200, 'left', 'Namangan', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 482 35 00')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0012');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (15857000.0)/1, 0, 0, 15857000.0
FROM orders o WHERE o.code='L-2605-0012' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-14'::date, 15857000.0, 'UZS', 15857000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0012' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0013', (SELECT id FROM customers WHERE phone='+998 94 307 44 77' LIMIT 1), 'import', '2026-05-07'::date, '2026-05-07'::date, 'delivered', 0, 300, 'left', 'Namangan', 0, 'Model (asl): premium3 2026, 300 kvm | 35$ 4ta 25$', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 307 44 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0013');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1514, (17243000.0)/1, 0, 0, 17243000.0
FROM orders o WHERE o.code='L-2605-0013' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-07'::date, 17243000.0, 'UZS', 17243000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0013' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0014', (SELECT id FROM customers WHERE phone='+998 93 405 51 45' LIMIT 1), 'import', '2026-05-07'::date, '2026-05-08'::date, 'delivered', 0, 200, 'right', 'Namangan', 0, 'Model (asl): magnum 1, 200 kvm | 35$ 4ta 25$', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 405 51 45')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0014');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (17137000.0)/1, 0, 0, 17137000.0
FROM orders o WHERE o.code='L-2605-0014' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-08'::date, 17137000.0, 'UZS', 17137000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0014' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0015', (SELECT id FROM customers WHERE phone='NOPHONE-2605-15' LIMIT 1), 'import', '2026-05-08'::date, '2026-05-08'::date, 'delivered', 0, 400, 'left', 'Farg''ona', 0, 'Model (asl): magnum 1, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='NOPHONE-2605-15')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0015');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('magnum 1') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 0, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2605-0015' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0016', (SELECT id FROM customers WHERE phone='+998 77 105 37 77' LIMIT 1), 'import', '2026-05-08'::date, '2026-05-09'::date, 'delivered', 0, 200, 'left', 'Samarqand', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 105 37 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0016');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, (15858000.0)/1, 0, 0, 15858000.0
FROM orders o WHERE o.code='L-2605-0016' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-09'::date, 15858000.0, 'UZS', 15858000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0016' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0021', (SELECT id FROM customers WHERE phone='+998 91 143 73 78' LIMIT 1), 'import', '2026-05-11'::date, '2026-05-11'::date, 'delivered', 0, 150, 'right', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 143 73 78')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0021');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (1318000.0)/1, 0, 0, 1318000.0
FROM orders o WHERE o.code='L-2605-0021' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-11'::date, 1318000.0, 'UZS', 1318000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0021' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0022', (SELECT id FROM customers WHERE phone='+998 94 730 71 77' LIMIT 1), 'import', '2026-05-11'::date, '2026-05-11'::date, 'delivered', 0, 300, 'right', 'Namangan', 0, 'Model (asl): premium4 2026, 300 kvm | 35$ 4ta 25$', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 730 71 77')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0022');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium4 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium4 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1549, (20323000.0)/1, 0, 0, 20323000.0
FROM orders o WHERE o.code='L-2605-0022' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-11'::date, 20323000.0, 'UZS', 20323000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0022' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0023', (SELECT id FROM customers WHERE phone='+998 99 395 19 63' LIMIT 1), 'import', '2026-05-11'::date, '2026-05-13'::date, 'delivered', 0, 200, 'left', 'Namangan', 0, 'Model (asl): ultra 1 2026, 200 kvm | 25$ 4ta 20$', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 395 19 63')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0023');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1519, (18383000.0)/1, 0, 0, 18383000.0
FROM orders o WHERE o.code='L-2605-0023' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-13'::date, 18383000.0, 'UZS', 18383000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0023' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0024', (SELECT id FROM customers WHERE phone='+998 91 652 46 36' LIMIT 1), 'import', '2026-05-11'::date, '2026-05-12'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 46 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0024');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (15782000.0)/1, 0, 0, 15782000.0
FROM orders o WHERE o.code='L-2605-0024' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-12'::date, 15782000.0, 'UZS', 15782000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0024' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0025', (SELECT id FROM customers WHERE phone='+998 88 704 05 55' LIMIT 1), 'import', '2026-05-11'::date, '2026-05-12'::date, 'delivered', 0, 300, 'left', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 704 05 55')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0025');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (15100000.0)/1, 0, 0, 15100000.0
FROM orders o WHERE o.code='L-2605-0025' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-12'::date, 15100000.0, 'UZS', 15100000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0025' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0026', (SELECT id FROM customers WHERE phone='+998 94 978 54 04' LIMIT 1), 'import', '2026-05-11'::date, '2026-05-12'::date, 'delivered', 0, 300, 'right', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 978 54 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0026');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (6052000.0)/1, 0, 0, 6052000.0
FROM orders o WHERE o.code='L-2605-0026' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-12'::date, 6052000.0, 'UZS', 6052000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0026' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0027', (SELECT id FROM customers WHERE phone='+998 90 278 25 75' LIMIT 1), 'import', '2026-05-13'::date, '2026-05-19'::date, 'delivered', 0, 400, 'right', 'Namangan', 0, 'Model (asl): ultra 1 2026, 400 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 278 25 75')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0027');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1649, (19452000.0)/1, 0, 0, 19452000.0
FROM orders o WHERE o.code='L-2605-0027' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-19'::date, 19452000.0, 'UZS', 19452000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0027' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0028', (SELECT id FROM customers WHERE phone='+998 94 252 40 31' LIMIT 1), 'import', '2026-05-13'::date, '2026-05-14'::date, 'delivered', 0, 200, 'left', 'Andijon', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 252 40 31')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0028');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (15927000.0)/1, 0, 0, 15927000.0
FROM orders o WHERE o.code='L-2605-0028' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-14'::date, 15927000.0, 'UZS', 15927000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0028' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0029', (SELECT id FROM customers WHERE phone='+998 99 162 50 50' LIMIT 1), 'import', '2026-05-15'::date, '2026-05-15'::date, 'delivered', 0, 150, 'right', 'Namangan', 0, 'Model (asl): ultra 1 2026, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 162 50 50')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0029');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, (15755000.0)/1, 0, 0, 15755000.0
FROM orders o WHERE o.code='L-2605-0029' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-15'::date, 15755000.0, 'UZS', 15755000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0029' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0032', (SELECT id FROM customers WHERE phone='+998 91 151 11 88' LIMIT 1), 'import', '2026-05-19'::date, '2026-05-22'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 151 11 88')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0032');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1388, (15520000.0)/1, 0, 0, 15520000.0
FROM orders o WHERE o.code='L-2605-0032' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-22'::date, 15520000.0, 'UZS', 15520000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0032' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0033', (SELECT id FROM customers WHERE phone='+998 77 253 70 66' LIMIT 1), 'import', '2026-05-22'::date, '2026-06-01'::date, 'delivered', 0, 200, 'right', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 200 kvm | tent', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 253 70 66')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0033');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1388, (16739000.0)/1, 0, 0, 16739000.0
FROM orders o WHERE o.code='L-2605-0033' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-01'::date, 16739000.0, 'UZS', 16739000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0033' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0035', (SELECT id FROM customers WHERE phone='+998 88 308 69 96' LIMIT 1), 'import', '2026-05-24'::date, '2026-05-25'::date, 'delivered', 0, 150, 'right', 'Samarqand', 0, 'Model (asl): premium3 2026, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 308 69 96')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0035');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1188, (13067000.0)/1, 0, 0, 13067000.0
FROM orders o WHERE o.code='L-2605-0035' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-25'::date, 13067000.0, 'UZS', 13067000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0035' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0036', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-25'::date, '2026-05-28'::date, 'delivered', 0, 150, 'right', 'Samarqand', 0, 'Model (asl): premium3 2026, 150 kvm | 5 ta chugun', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0036');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1199, (51869000.0)/1, 0, 0, 51869000.0
FROM orders o WHERE o.code='L-2605-0036' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-28'::date, 51869000.0, 'UZS', 51869000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0036' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0037', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-25'::date, '2026-05-28'::date, 'delivered', 0, 300, 'right', 'Samarqand', 0, 'Model (asl): premium3 2026, 300 kvm | 2 ta tent', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0037');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1349, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2605-0037' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0038', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-25'::date, '2026-05-28'::date, 'delivered', 0, 300, 'left', 'Samarqand', 0, 'Model (asl): premium3 2026, 300 kvm | 2 ta tarelka', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0038');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1349, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2605-0038' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0039', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-05-25'::date, '2026-05-28'::date, 'delivered', 0, 400, 'right', 'Samarqand', 0, 'Model (asl): premium3 2026, 400 kvm | 2 ta stablizator', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0039');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') AND kvm=400 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, 0, 0, 0, 0.0
FROM orders o WHERE o.code='L-2605-0039' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0040', (SELECT id FROM customers WHERE phone='+998 91 647 59 36' LIMIT 1), 'import', '2026-05-25'::date, '2026-06-01'::date, 'delivered', 0, 300, 'right', 'Buxoro', 0, 'Model (asl): ultra 1 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 647 59 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0040');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (16988000.0)/1, 0, 0, 16988000.0
FROM orders o WHERE o.code='L-2605-0040' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-01'::date, 16988000.0, 'UZS', 16988000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0040' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0041', (SELECT id FROM customers WHERE phone='+998 91 647 59 36' LIMIT 1), 'import', '2026-05-25'::date, '2026-06-01'::date, 'delivered', 0, 200, 'right', 'Buxoro', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 647 59 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0041');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1399, (15788000.0)/1, 0, 0, 15788000.0
FROM orders o WHERE o.code='L-2605-0041' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-01'::date, 15788000.0, 'UZS', 15788000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0041' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0042', (SELECT id FROM customers WHERE phone='+998 97 346 44 43' LIMIT 1), 'import', '2026-05-25'::date, '2026-05-28'::date, 'delivered', 0, 200, 'right', 'Andijon', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 346 44 43')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0042');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1388, (10700000.0)/1, 0, 0, 10700000.0
FROM orders o WHERE o.code='L-2605-0042' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-05-28'::date, 10700000.0, 'UZS', 10700000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0042' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0044', (SELECT id FROM customers WHERE phone='+998 97 595 39 83' LIMIT 1), 'import', '2026-05-26'::date, '2026-06-01'::date, 'delivered', 0, 300, 'right', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 595 39 83')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0044');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1488, (16656000.0)/1, 0, 0, 16656000.0
FROM orders o WHERE o.code='L-2605-0044' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-01'::date, 16656000.0, 'UZS', 16656000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0044' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0045', (SELECT id FROM customers WHERE phone='+998 91 647 59 36' LIMIT 1), 'import', '2026-05-29'::date, '2026-06-01'::date, 'delivered', 0, 300, 'right', 'Buxoro', 0, 'Model (asl): ultra 1 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 647 59 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0045');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (17062000.0)/1, 0, 0, 17062000.0
FROM orders o WHERE o.code='L-2605-0045' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-01'::date, 17062000.0, 'UZS', 17062000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0045' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2605-0046', (SELECT id FROM customers WHERE phone='+998 91 109 38 91' LIMIT 1), 'import', '2026-05-30'::date, '2026-06-01'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 200 kvm | 25$ 4 ta', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 109 38 91')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2605-0046');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (15764000.0)/1, 0, 0, 15764000.0
FROM orders o WHERE o.code='L-2605-0046' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-01'::date, 15764000.0, 'UZS', 15764000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2605-0046' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2606-0002', (SELECT id FROM customers WHERE phone='+998 94 203 15 15' LIMIT 1), 'import', '2026-06-02'::date, '2026-06-04'::date, 'delivered', 0, 200, 'right', 'Namangan', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 203 15 15')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2606-0002');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1478, (17000000.0)/1, 0, 0, 17000000.0
FROM orders o WHERE o.code='L-2606-0002' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-04'::date, 17000000.0, 'UZS', 17000000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2606-0002' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2606-0003', (SELECT id FROM customers WHERE phone='+998 99 196 40 60' LIMIT 1), 'import', '2026-06-03'::date, '2026-06-04'::date, 'delivered', 0, 200, 'left', 'Buxoro', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 196 40 60')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2606-0003');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16746000.0)/1, 0, 0, 16746000.0
FROM orders o WHERE o.code='L-2606-0003' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-04'::date, 16746000.0, 'UZS', 16746000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2606-0003' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2606-0004', (SELECT id FROM customers WHERE phone='+998 91 563 04 04' LIMIT 1), 'import', '2026-06-03'::date, '2026-06-04'::date, 'delivered', 0, 200, 'left', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 563 04 04')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2606-0004');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16746000.0)/1, 0, 0, 16746000.0
FROM orders o WHERE o.code='L-2606-0004' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-04'::date, 16746000.0, 'UZS', 16746000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2606-0004' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2606-0005', (SELECT id FROM customers WHERE phone='+998 91 647 59 36' LIMIT 1), 'import', '2026-06-03'::date, '2026-06-04'::date, 'delivered', 0, 200, 'left', 'Buxoro', 0, 'Model (asl): ultra 1 2026, 200 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 647 59 36')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2606-0005');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=200 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1399, (16788000.0)/1, 0, 0, 16788000.0
FROM orders o WHERE o.code='L-2606-0005' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-04'::date, 16788000.0, 'UZS', 16788000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2606-0005' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2606-0006', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-06-03'::date, '2026-06-04'::date, 'delivered', 0, 150, 'right', 'Samarqand', 0, 'Model (asl): premium 3 2026, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2606-0006');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1199, (14388000.0)/1, 0, 0, 14388000.0
FROM orders o WHERE o.code='L-2606-0006' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-04'::date, 14388000.0, 'UZS', 14388000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2606-0006' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2606-0007', (SELECT id FROM customers WHERE phone='+998 90 251 08 01' LIMIT 1), 'import', '2026-06-03'::date, '2026-06-04'::date, 'delivered', 0, 150, 'left', 'Samarqand', 0, 'Model (asl): premium 3 2026, 150 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2606-0007');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3 2026') AND kvm=150 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('premium 3 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1199, (14388000.0)/1, 0, 0, 14388000.0
FROM orders o WHERE o.code='L-2606-0007' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-04'::date, 14388000.0, 'UZS', 14388000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2606-0007' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2606-0008', (SELECT id FROM customers WHERE phone='+998 97 271 66 54' LIMIT 1), 'import', '2026-06-03'::date, '2026-06-08'::date, 'delivered', 0, 300, 'left', 'Farg''ona', 0, 'Model (asl): ultra 1 2026, 300 kvm', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 271 66 54')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2606-0008');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'left', 1499, (17988000.0)/1, 0, 0, 17988000.0
FROM orders o WHERE o.code='L-2606-0008' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-08'::date, 17988000.0, 'UZS', 17988000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2606-0008' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);
INSERT INTO orders (id, code, customer_id, source, order_date, delivered_at, status, priority, area_m2, bunker_direction, delivery_address, exchange_rate, additional_info, note, has_stamp_ruc, has_stamp_avt, has_online, has_video)
SELECT gen_random_uuid(), 'L-2606-0010', (SELECT id FROM customers WHERE phone='+998 95 640 06 15' LIMIT 1), 'import', '2026-06-06'::date, '2026-06-06'::date, 'delivered', 0, 300, 'right', 'Andijon', 0, 'Model (asl): ultra 1 2026, 300 kvm | 35 $ 5ta 25 $', NULL, false, false, false, false
WHERE EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 640 06 15')
  AND NOT EXISTS (SELECT 1 FROM orders WHERE code='L-2606-0010');
INSERT INTO order_items (id, order_id, product_id, quantity, bunker_direction, unit_price_usd, unit_price_uzs, discount_usd, discount, total_uzs)
SELECT gen_random_uuid(), o.id, COALESCE((SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') AND kvm=300 LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND lower(model)=lower('ultra 1 2026') LIMIT 1),(SELECT id FROM products WHERE product_type='main' AND model='Eski model (import)' LIMIT 1)), 1, 'right', 1499, (19188000.0)/1, 0, 0, 19188000.0
FROM orders o WHERE o.code='L-2606-0010' AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id=o.id);
INSERT INTO payments (id, order_id, date, amount, currency, amount_uzs_equiv, method, note)
SELECT gen_random_uuid(), o.id, '2026-06-06'::date, 19188000.0, 'UZS', 19188000.0, 'cash', 'Eski baza — yetkazilgan, to''liq to''langan'
FROM orders o WHERE o.code='L-2606-0010' AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id=o.id);

SELECT (SELECT count(*) FROM orders WHERE source='import' AND status='delivered') AS sotuv, (SELECT count(*) FROM order_items oi JOIN orders o ON o.id=oi.order_id WHERE o.code LIKE 'L-%') AS item, (SELECT count(*) FROM payments p JOIN orders o ON o.id=p.order_id WHERE o.code LIKE 'L-%') AS tolov;
COMMIT;