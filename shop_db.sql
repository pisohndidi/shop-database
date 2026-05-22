-- ============================================================
--  База данных: Интернет-магазин
--  СУБД: MySQL 8.x
--  Автор: учебная практика УП.11
-- ============================================================

CREATE DATABASE IF NOT EXISTS shop_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE shop_db;

-- ------------------------------------------------------------
-- 1. Категории товаров
-- ------------------------------------------------------------
CREATE TABLE categories (
    id          INT           NOT NULL AUTO_INCREMENT,
    name        VARCHAR(100)  NOT NULL,
    description TEXT,
    PRIMARY KEY (id)
);

-- ------------------------------------------------------------
-- 2. Товары
-- ------------------------------------------------------------
CREATE TABLE products (
    id          INT            NOT NULL AUTO_INCREMENT,
    category_id INT            NOT NULL,
    name        VARCHAR(200)   NOT NULL,
    description TEXT,
    price       DECIMAL(10,2)  NOT NULL,
    stock_qty   INT            NOT NULL DEFAULT 0,
    created_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id) REFERENCES categories(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 3. Покупатели
-- ------------------------------------------------------------
CREATE TABLE customers (
    id         INT          NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(80)  NOT NULL,
    last_name  VARCHAR(80)  NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    phone      VARCHAR(20),
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

-- ------------------------------------------------------------
-- 4. Заказы
-- ------------------------------------------------------------
CREATE TABLE orders (
    id          INT          NOT NULL AUTO_INCREMENT,
    customer_id INT          NOT NULL,
    status      ENUM('new','paid','shipped','delivered','cancelled')
                             NOT NULL DEFAULT 'new',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 5. Состав заказа (связующая таблица M:N → orders ↔ products)
-- ------------------------------------------------------------
CREATE TABLE order_items (
    id         INT           NOT NULL AUTO_INCREMENT,
    order_id   INT           NOT NULL,
    product_id INT           NOT NULL,
    quantity   INT           NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_item_order
        FOREIGN KEY (order_id)   REFERENCES orders(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_item_product
        FOREIGN KEY (product_id) REFERENCES products(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- ============================================================

INSERT INTO categories (name, description) VALUES
('Электроника',    'Смартфоны, ноутбуки, аксессуары'),
('Книги',          'Художественная и учебная литература'),
('Одежда',         'Мужская и женская одежда'),
('Спорт и досуг',  'Тренажёры, спортивный инвентарь');

INSERT INTO products (category_id, name, description, price, stock_qty) VALUES
(1, 'Смартфон Samsung Galaxy A55', '6.6" AMOLED, 128 GB', 34990.00, 50),
(1, 'Ноутбук Lenovo IdeaPad 3',    '15.6", Core i5, 8 GB RAM', 59990.00, 20),
(1, 'Наушники Sony WH-1000XM5',    'Беспроводные, шумоподавление', 24990.00, 35),
(2, 'Мастер и Маргарита',          'М. А. Булгаков', 420.00, 100),
(2, 'Чистый код',                  'Роберт Мартин, IT-бестселлер', 890.00, 80),
(3, 'Футболка Adidas Essentials',  'Хлопок 100%, р. S–XL', 1290.00, 200),
(3, 'Джинсы Levi\'s 501',          'Классический крой, синий', 5490.00, 60),
(4, 'Скакалка скоростная',         'Алюминиевые ручки, трос 3 м', 850.00, 150),
(4, 'Гиря 16 кг',                  'Чугун, покрытие эмаль', 2200.00, 40);

INSERT INTO customers (first_name, last_name, email, phone) VALUES
('Иван',     'Петров',   'petrov@mail.ru',  '+79161234567'),
('Мария',    'Сидорова', 'sidorova@ya.ru',  '+79269876543'),
('Алексей',  'Козлов',   'kozlov@gmail.com','+79031112233'),
('Наталья',  'Орлова',   'orlova@mail.ru',  '+79037778899');

INSERT INTO orders (customer_id, status) VALUES
(1, 'delivered'),
(2, 'paid'),
(3, 'new'),
(1, 'shipped'),
(4, 'cancelled');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 34990.00),
(1, 4, 2,   420.00),
(2, 3, 1, 24990.00),
(2, 5, 1,   890.00),
(3, 6, 3,  1290.00),
(3, 8, 2,   850.00),
(4, 2, 1, 59990.00),
(4, 9, 1,  2200.00),
(5, 7, 1,  5490.00);

-- ============================================================
-- SQL-ЗАПРОСЫ
-- ============================================================

-- Запрос 1: SELECT с условием (WHERE)
-- Товары дороже 5 000 руб. в наличии
SELECT id, name, price, stock_qty
FROM products
WHERE price > 5000.00
  AND stock_qty > 0
ORDER BY price DESC;

-- Запрос 2: INSERT — новый покупатель
INSERT INTO customers (first_name, last_name, email, phone)
VALUES ('Дмитрий', 'Новиков', 'novikov@inbox.ru', '+79151234567');

-- Запрос 3: UPDATE — изменить статус заказа №3 на 'paid'
UPDATE orders
SET status = 'paid'
WHERE id = 3;

-- Запрос 4: DELETE — удалить отменённые заказы
DELETE FROM orders
WHERE status = 'cancelled';

-- Запрос 5: SELECT с JOIN
-- Детальный список всех доставленных и оплаченных заказов
-- с именем покупателя, товарами и итоговой суммой
SELECT
    o.id                                      AS order_id,
    CONCAT(c.first_name, ' ', c.last_name)    AS customer,
    c.email,
    o.status,
    p.name                                    AS product,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price)             AS line_total
FROM orders        o
JOIN customers     c  ON c.id  = o.customer_id
JOIN order_items   oi ON oi.order_id  = o.id
JOIN products      p  ON p.id  = oi.product_id
WHERE o.status IN ('paid', 'delivered')
ORDER BY o.id, p.name;
