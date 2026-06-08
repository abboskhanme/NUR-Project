-- FAQAT import SOTUV qismini o'chiradi (buyurtma + item + to'lov + "Eski model").
-- MIJOZLAR saqlanadi (source='import' mijozlar o'chmaydi).
-- Lokal:  docker compose exec -T postgres psql -U postgres -d nur_erp < backend/scripts/cleanup_orders_only.sql
-- Server: docker compose -f docker-compose.prod.yml exec -T postgres psql -U postgres -d nur_erp < backend/scripts/cleanup_orders_only.sql
\set ON_ERROR_STOP on
BEGIN;

SELECT 'OLDIN' bosqich,
  (SELECT count(*) FROM customers WHERE source='import') AS mijoz,
  (SELECT count(*) FROM orders WHERE code LIKE 'L-%') AS buyurtma,
  (SELECT count(*) FROM order_items oi JOIN orders o ON o.id=oi.order_id WHERE o.code LIKE 'L-%') AS item,
  (SELECT count(*) FROM payments p JOIN orders o ON o.id=p.order_id WHERE o.code LIKE 'L-%') AS tolov,
  (SELECT count(*) FROM products WHERE model='Eski model (import)') AS eski_model;

-- Faqat sotuv (FK tartibida). Mijozlarga TEGILMAYDI.
DELETE FROM payments    WHERE order_id IN (SELECT id FROM orders WHERE code LIKE 'L-%');
DELETE FROM order_items WHERE order_id IN (SELECT id FROM orders WHERE code LIKE 'L-%');
DELETE FROM orders      WHERE code LIKE 'L-%';
DELETE FROM products    WHERE model='Eski model (import)'
  AND NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = products.id);

SELECT 'KEYIN' bosqich,
  (SELECT count(*) FROM customers WHERE source='import') AS mijoz_saqlandi,
  (SELECT count(*) FROM orders WHERE code LIKE 'L-%') AS buyurtma,
  (SELECT count(*) FROM products WHERE model='Eski model (import)') AS eski_model;

COMMIT;
