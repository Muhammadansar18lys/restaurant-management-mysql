-- Restaurant Management Database
-- Compatible with MySQL 8.0.16+.
-- Safe to run more than once: it creates the database and tables if missing.

CREATE DATABASE IF NOT EXISTS restaurant_manager
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE restaurant_manager;

CREATE TABLE IF NOT EXISTS menu_categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE,
    description VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS menu_items (
    menu_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    item_name VARCHAR(120) NOT NULL,
    description VARCHAR(255),
    price DECIMAL(9,2) NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_menu_item_price CHECK (price >= 0),
    CONSTRAINT uq_menu_item_category_name UNIQUE (category_id, item_name),
    CONSTRAINT fk_menu_items_category FOREIGN KEY (category_id)
        REFERENCES menu_categories(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_menu_items_available (is_available, category_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dining_tables (
    table_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_number SMALLINT UNSIGNED NOT NULL UNIQUE,
    capacity TINYINT UNSIGNED NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_table_capacity CHECK (capacity BETWEEN 1 AND 20)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS staff_members (
    staff_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    role ENUM('manager','server','chef','cashier') NOT NULL,
    email VARCHAR(160) UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    hired_at DATE NOT NULL DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customers (
    customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    phone VARCHAR(30) UNIQUE,
    email VARCHAR(160) UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS orders (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_id INT UNSIGNED NULL,
    staff_id INT UNSIGNED NOT NULL,
    customer_id INT UNSIGNED NULL,
    order_type ENUM('dine_in','takeaway','delivery') NOT NULL DEFAULT 'dine_in',
    status ENUM('placed','preparing','ready','served','cancelled') NOT NULL DEFAULT 'placed',
    placed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at DATETIME NULL,
    notes VARCHAR(500),
    CONSTRAINT fk_orders_table FOREIGN KEY (table_id)
        REFERENCES dining_tables(table_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_orders_staff FOREIGN KEY (staff_id)
        REFERENCES staff_members(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_orders_status_time (status, placed_at),
    INDEX idx_orders_table_status (table_id, status),
    INDEX idx_orders_customer_time (customer_id, placed_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    menu_item_id INT UNSIGNED NOT NULL,
    quantity SMALLINT UNSIGNED NOT NULL,
    unit_price DECIMAL(9,2) NOT NULL,
    special_instructions VARCHAR(255),
    CONSTRAINT chk_order_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_item_price CHECK (unit_price >= 0),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_items_menu FOREIGN KEY (menu_item_id)
        REFERENCES menu_items(menu_item_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_order_items_order (order_id),
    INDEX idx_order_items_menu (menu_item_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    payment_method ENUM('cash','card','online') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_status ENUM('pending','paid','refunded') NOT NULL DEFAULT 'paid',
    paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    INDEX idx_payments_date_status (paid_at, payment_status)
) ENGINE=InnoDB;

-- A reusable order summary: one row per order, including orders with no lines yet.
CREATE OR REPLACE VIEW v_order_totals AS
SELECT o.order_id,
       o.order_type,
       o.status,
       o.placed_at,
       o.table_id,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0.00) AS order_total
FROM orders AS o
LEFT JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_type, o.status, o.placed_at, o.table_id;

-- A table is occupied while it has a dine-in order that is not finished or cancelled.
CREATE OR REPLACE VIEW v_table_status AS
SELECT t.table_id,
       t.table_number,
       t.capacity,
       t.is_active,
       CASE WHEN EXISTS (
           SELECT 1 FROM orders AS o
           WHERE o.table_id = t.table_id
             AND o.order_type = 'dine_in'
             AND o.status IN ('placed','preparing','ready')
       ) THEN 'occupied' ELSE 'available' END AS table_status
FROM dining_tables AS t;
