-- Reporting and practice queries for restaurant_manager.
USE restaurant_manager;

-- 1. Kitchen queue: newest open tickets with their current totals.
SELECT order_id, order_type, table_id, status, placed_at, order_total
FROM v_order_totals
WHERE status IN ('placed', 'preparing', 'ready')
ORDER BY FIELD(status, 'placed', 'preparing', 'ready'), placed_at;

-- 2. Order detail: menu items, quantities, and saved-at-order prices.
SELECT o.order_id, o.placed_at, mi.item_name, oi.quantity,
       oi.unit_price, oi.quantity * oi.unit_price AS line_total,
       oi.special_instructions
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
JOIN menu_items AS mi ON mi.menu_item_id = oi.menu_item_id
WHERE o.order_id = 1002
ORDER BY oi.order_item_id;

-- 3. Sales by date and payment method.
SELECT DATE(p.paid_at) AS sales_date, p.payment_method,
       COUNT(*) AS payment_count, SUM(p.amount) AS gross_sales
FROM payments AS p
WHERE p.payment_status = 'paid'
GROUP BY DATE(p.paid_at), p.payment_method
ORDER BY sales_date DESC, gross_sales DESC;

-- 4. Most ordered dishes (include items that have never been sold).
SELECT mi.item_name, mc.category_name,
       COALESCE(SUM(CASE WHEN o.status <> 'cancelled' THEN oi.quantity ELSE 0 END), 0) AS units_ordered
FROM menu_items AS mi
JOIN menu_categories AS mc ON mc.category_id = mi.category_id
LEFT JOIN order_items AS oi ON oi.menu_item_id = mi.menu_item_id
LEFT JOIN orders AS o ON o.order_id = oi.order_id
GROUP BY mi.menu_item_id, mi.item_name, mc.category_name
ORDER BY units_ordered DESC, mi.item_name;

-- 5. Table availability and current open order counts.
SELECT t.table_number, t.capacity, t.table_status,
       COUNT(o.order_id) AS open_order_count
FROM v_table_status AS t
LEFT JOIN orders AS o
  ON o.table_id = t.table_id
 AND o.order_type = 'dine_in'
 AND o.status IN ('placed', 'preparing', 'ready')
GROUP BY t.table_id, t.table_number, t.capacity, t.table_status
ORDER BY t.table_number;

-- 6. Customer order history and total spend from successful payments.
SELECT c.customer_id, c.full_name, COUNT(DISTINCT o.order_id) AS order_count,
       COALESCE(SUM(CASE WHEN p.payment_status = 'paid' THEN p.amount ELSE 0 END), 0) AS amount_paid
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
LEFT JOIN payments AS p ON p.order_id = o.order_id
GROUP BY c.customer_id, c.full_name
ORDER BY amount_paid DESC;

-- 7. Unavailable menu items, useful when updating the menu.
SELECT item_name, price
FROM menu_items
WHERE is_available = FALSE
ORDER BY item_name;

-- 8. Transaction pattern: create an order and its line items as one unit.
-- Uncomment and adjust IDs/values to try it. Rollback prevents a half-saved ticket.
-- START TRANSACTION;
-- INSERT INTO orders (table_id, staff_id, order_type, status)
-- VALUES (2, 2, 'dine_in', 'placed');
-- SET @new_order_id = LAST_INSERT_ID();
-- INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price)
-- SELECT @new_order_id, menu_item_id, 1, price
-- FROM menu_items WHERE menu_item_id = 3;
-- COMMIT;
-- If an insert fails before COMMIT, run: ROLLBACK;
