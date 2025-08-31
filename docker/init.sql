-- 数据库初始化脚本

-- 创建数据库 (如果需要)
-- CREATE DATABASE seata_demo;

-- 使用数据库
\c seata_demo;

-- 创建订单表
CREATE TABLE IF NOT EXISTS orders (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建库存表
CREATE TABLE IF NOT EXISTS stock (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL UNIQUE,
    quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建 Seata AT模式回滚日志表
CREATE TABLE IF NOT EXISTS undo_log (
    id BIGSERIAL PRIMARY KEY,
    branch_id BIGINT NOT NULL,
    xid VARCHAR(100) NOT NULL,
    context VARCHAR(128) NOT NULL,
    rollback_info BYTEA NOT NULL,
    log_status INTEGER NOT NULL,
    log_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_undo_log_xid ON undo_log (xid);

-- 插入测试数据
-- 清空现有数据
DELETE FROM orders;
DELETE FROM stock;

-- 插入初始库存数据
INSERT INTO stock (product_id, quantity) VALUES 
(1001, 100),  -- 产品1001，库存100
(1002, 50),   -- 产品1002，库存50
(1003, 10);   -- 产品1003，库存10（用于测试库存不足场景）

-- 显示初始化完成信息
SELECT 'Database initialized successfully!' as message;

-- 显示库存信息
SELECT 'Initial stock data:' as info;
SELECT * FROM stock;