-- ============================================================
-- PartsDepot サンプルデータベース: スキーマ定義
-- 自動車部品商社を想定した在庫・受発注管理DB
-- PostgreSQL 16 で動作確認済み
-- ============================================================

DROP TABLE IF EXISTS price_history CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;
DROP TABLE IF EXISTS parts CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- 部品カテゴリ（自己参照で親カテゴリを持てる = 階層構造）
CREATE TABLE categories (
    category_id     SERIAL PRIMARY KEY,
    category_name   VARCHAR(50) NOT NULL,
    parent_category_id INTEGER REFERENCES categories(category_id)
);

-- 仕入先
CREATE TABLE suppliers (
    supplier_id     SERIAL PRIMARY KEY,
    supplier_name   VARCHAR(100) NOT NULL,
    country         VARCHAR(50) NOT NULL DEFAULT '日本',
    contact_email   VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 部品マスタ
CREATE TABLE parts (
    part_id         SERIAL PRIMARY KEY,
    part_number     VARCHAR(20) NOT NULL UNIQUE,
    part_name       VARCHAR(100) NOT NULL,
    category_id     INTEGER NOT NULL REFERENCES categories(category_id),
    supplier_id     INTEGER NOT NULL REFERENCES suppliers(supplier_id),
    unit_price      NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    weight_kg       NUMERIC(6, 3),
    specs           JSONB NOT NULL DEFAULT '{}',   -- 材質・サイズ等の可変属性
    tags            TEXT[] NOT NULL DEFAULT '{}',  -- 検索用タグ
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parts_category ON parts(category_id);
CREATE INDEX idx_parts_specs_gin ON parts USING GIN (specs);

-- 倉庫
CREATE TABLE warehouses (
    warehouse_id    SERIAL PRIMARY KEY,
    warehouse_name  VARCHAR(50) NOT NULL,
    location        VARCHAR(100) NOT NULL
);

-- 在庫（倉庫×部品の複合主キー）
CREATE TABLE inventory (
    part_id         INTEGER NOT NULL REFERENCES parts(part_id),
    warehouse_id    INTEGER NOT NULL REFERENCES warehouses(warehouse_id),
    quantity        INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (part_id, warehouse_id)
);

-- 顧客（法人ディーラーと個人客が混在）
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    customer_name   VARCHAR(100) NOT NULL,
    customer_type   VARCHAR(10) NOT NULL CHECK (customer_type IN ('dealer', 'retail')),
    email           VARCHAR(100) UNIQUE,
    phone           VARCHAR(20),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 従業員（自己参照で上司=部下の階層構造）
CREATE TABLE employees (
    employee_id     SERIAL PRIMARY KEY,
    employee_name   VARCHAR(50) NOT NULL,
    department      VARCHAR(20) NOT NULL,
    manager_id      INTEGER REFERENCES employees(employee_id),
    hire_date       DATE NOT NULL
);

-- 受注ヘッダ
CREATE TABLE orders (
    order_id        SERIAL PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES customers(customer_id),
    employee_id     INTEGER NOT NULL REFERENCES employees(employee_id),
    order_date      TIMESTAMP NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'shipped', 'completed', 'cancelled'))
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);

-- 受注明細
CREATE TABLE order_items (
    order_item_id   SERIAL PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    part_id         INTEGER NOT NULL REFERENCES parts(part_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10, 2) NOT NULL  -- 受注時点の単価（部品マスタと切り離して履歴を保持）
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_part ON order_items(part_id);

-- 価格改定履歴（ウィンドウ関数の練習用）
CREATE TABLE price_history (
    price_history_id SERIAL PRIMARY KEY,
    part_id          INTEGER NOT NULL REFERENCES parts(part_id),
    price            NUMERIC(10, 2) NOT NULL,
    effective_date   DATE NOT NULL
);

CREATE INDEX idx_price_history_part ON price_history(part_id, effective_date);
