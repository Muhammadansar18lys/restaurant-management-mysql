-- Sample records for restaurant_manager.
-- Explicit IDs make the example reports easy to follow.
USE restaurant_manager;

INSERT INTO menu_categories (category_id, category_name, description) VALUES
(1, 'Starters', 'Small plates and soups'),
(2, 'Mains', 'Main courses'),
(3, 'Desserts', 'Sweet finishes'),
(4, 'Drinks', 'Non-alcoholic drinks')
ON DUPLICATE KEY UPDATE description = VALUES(description);

INSERT INTO menu_items (menu_item_id, category_id, item_name, description, price, is_available) VALUES
(1, 1, 'Roasted Tomato Soup', 'Roasted tomatoes, basil, sourdough', 8.50, TRUE),
(2, 1, 'Garden Herb Salad', 'Seasonal greens, herbs, house dressing', 11.00, TRUE),
(3, 2, 'Mushroom Risotto', 'Arborio rice, mushrooms, parmesan', 18.00, TRUE),
(4, 2, 'Grilled Chicken Plate', 'Herb chicken, potatoes, greens', 21.50, TRUE),
(5, 2, 'Seared Salmon', 'Salmon, lemon, seasonal vegetables', 24.00, TRUE),
(6, 3, 'Lemon Olive Cake', 'Olive oil cake with lemon glaze', 9.00, TRUE),
(7, 4, 'Sparkling Water', '750 ml bottle', 4.00, TRUE)
ON DUPLICATE KEY UPDATE description = VALUES(description), price = VALUES(price), is_available = VALUES(is_available);

INSERT INTO dining_tables (table_id, table_number, capacity, is_active) VALUES
(1, 1, 2, TRUE), (2, 2, 2, TRUE), (3, 3, 4, TRUE), (4, 4, 4, TRUE),
(5, 5, 4, TRUE), (6, 6, 6, TRUE), (7, 7, 6, TRUE), (8, 8, 8, TRUE)
ON DUPLICATE KEY UPDATE capacity = VALUES(capacity), is_active = VALUES(is_active);

INSERT INTO staff_members (staff_id, first_name, last_name, role, email, is_active) VALUES
(1, 'Ava', 'Morgan', 'manager', 'ava@example.test', TRUE),
(2, 'Noah', 'Reed', 'server', 'noah@example.test', TRUE),
(3, 'Mia', 'Patel', 'chef', 'mia@example.test', TRUE),
(4, 'Leo', 'Brooks', 'cashier', 'leo@example.test', TRUE)
ON DUPLICATE KEY UPDATE first_name = VALUES(first_name), last_name = VALUES(last_name), role = VALUES(role), is_active = VALUES(is_active);

INSERT INTO customers (customer_id, full_name, phone, email) VALUES
(1, 'Jordan Lee', '555-0101', 'jordan@example.test'),
(2, 'Sam Rivera', '555-0102', 'sam@example.test'),
(3, 'Taylor Chen', '555-0103', 'taylor@example.test')
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), phone = VALUES(phone), email = VALUES(email);

INSERT INTO orders (order_id, table_id, staff_id, customer_id, order_type, status, placed_at, closed_at, notes) VALUES
(1001, 1, 2, 1, 'dine_in', 'served', TIMESTAMP(CURRENT_DATE, '11:20:00'), TIMESTAMP(CURRENT_DATE, '11:55:00'), NULL),
(1002, 3, 2, 2, 'dine_in', 'preparing', TIMESTAMP(CURRENT_DATE, '12:05:00'), NULL, 'Dressing on the side'),
(1003, 6, 1, NULL, 'dine_in', 'ready', TIMESTAMP(CURRENT_DATE, '12:12:00'), NULL, NULL),
(1004, NULL, 4, 3, 'takeaway', 'served', TIMESTAMP(CURRENT_DATE, '12:18:00'), TIMESTAMP(CURRENT_DATE, '12:40:00'), 'Pickup at front counter'),
(1005, 4, 2, NULL, 'dine_in', 'placed', TIMESTAMP(CURRENT_DATE, '12:27:00'), NULL, NULL)
ON DUPLICATE KEY UPDATE status = VALUES(status), notes = VALUES(notes);

INSERT INTO order_items (order_item_id, order_id, menu_item_id, quantity, unit_price, special_instructions) VALUES
(1, 1001, 4, 2, 21.50, NULL),
(2, 1001, 7, 2, 4.00, NULL),
(3, 1002, 3, 1, 18.00, NULL),
(4, 1002, 2, 1, 11.00, 'Dressing on the side'),
(5, 1003, 5, 2, 24.00, NULL),
(6, 1003, 6, 1, 9.00, NULL),
(7, 1004, 1, 1, 8.50, NULL),
(8, 1004, 3, 1, 18.00, 'No parmesan'),
(9, 1005, 2, 2, 11.00, NULL)
ON DUPLICATE KEY UPDATE quantity = VALUES(quantity), unit_price = VALUES(unit_price), special_instructions = VALUES(special_instructions);

INSERT INTO payments (payment_id, order_id, payment_method, amount, payment_status, paid_at) VALUES
(1, 1001, 'card', 51.00, 'paid', TIMESTAMP(CURRENT_DATE, '11:55:00')),
(2, 1004, 'cash', 26.50, 'paid', TIMESTAMP(CURRENT_DATE, '12:40:00'))
ON DUPLICATE KEY UPDATE amount = VALUES(amount), payment_status = VALUES(payment_status);
