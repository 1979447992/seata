-- =====================================================
-- Oracle 版本的 Seata Demo 初始化脚本
-- 支持完整的 Seata AT 模式 (数据库模式)
-- =====================================================

-- 创建业务表：订单表
CREATE TABLE orders (
    id NUMBER(19) PRIMARY KEY,
    user_id VARCHAR2(100) NOT NULL,
    product_id NUMBER(19) NOT NULL,
    quantity NUMBER(10) NOT NULL,
    status VARCHAR2(50) DEFAULT 'PENDING' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建订单表序列
CREATE SEQUENCE orders_seq START WITH 1 INCREMENT BY 1;

-- 创建订单表触发器（自动递增ID）
CREATE OR REPLACE TRIGGER orders_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := orders_seq.NEXTVAL;
    END IF;
END;
/

-- 创建业务表：库存表
CREATE TABLE stock (
    id NUMBER(19) PRIMARY KEY,
    product_id NUMBER(19) NOT NULL UNIQUE,
    quantity NUMBER(10) DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建库存表序列
CREATE SEQUENCE stock_seq START WITH 1 INCREMENT BY 1;

-- 创建库存表触发器
CREATE OR REPLACE TRIGGER stock_trigger
    BEFORE INSERT ON stock
    FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := stock_seq.NEXTVAL;
    END IF;
END;
/

-- =====================================================
-- Seata AT 模式核心表 (Oracle 版本)
-- =====================================================

-- 1. undo_log 表 (回滚日志表)
CREATE TABLE undo_log (
    branch_id NUMBER(19) NOT NULL,
    xid VARCHAR2(128) NOT NULL,
    context VARCHAR2(128) NOT NULL,
    rollback_info BLOB NOT NULL,
    log_status NUMBER(10) NOT NULL,
    log_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_undo_log PRIMARY KEY (branch_id, xid)
);

-- undo_log 索引
CREATE INDEX idx_undo_log_xid ON undo_log(xid);

-- 2. global_table 表 (全局事务表)
CREATE TABLE global_table (
    xid VARCHAR2(128) NOT NULL,
    transaction_id NUMBER(19) NOT NULL,
    status NUMBER(10) NOT NULL,
    application_id VARCHAR2(32),
    transaction_service_group VARCHAR2(32),
    transaction_name VARCHAR2(128),
    timeout NUMBER(10),
    begin_time NUMBER(19),
    application_data VARCHAR2(2000),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_global_table PRIMARY KEY (xid)
);

-- global_table 索引
CREATE INDEX idx_global_table_status ON global_table(status);

-- 3. branch_table 表 (分支事务表)
CREATE TABLE branch_table (
    branch_id NUMBER(19) NOT NULL,
    xid VARCHAR2(128) NOT NULL,
    transaction_id NUMBER(19) NOT NULL,
    resource_group_id VARCHAR2(32),
    resource_id VARCHAR2(256),
    branch_type VARCHAR2(8),
    status NUMBER(10),
    client_id VARCHAR2(64),
    application_data VARCHAR2(2000),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_branch_table PRIMARY KEY (branch_id)
);

-- branch_table 索引
CREATE INDEX idx_branch_table_xid ON branch_table(xid);

-- =====================================================
-- 插入初始测试数据
-- =====================================================

-- 清空现有数据
DELETE FROM orders;
DELETE FROM stock;

-- 插入初始库存数据
INSERT INTO stock (product_id, quantity) VALUES (1001, 100);
INSERT INTO stock (product_id, quantity) VALUES (1002, 50);
INSERT INTO stock (product_id, quantity) VALUES (1003, 10);

-- 提交事务
COMMIT;

-- =====================================================
-- 验证表创建
-- =====================================================

-- 显示初始化完成信息
SELECT 'Oracle Database initialized successfully!' as message FROM dual;

-- 显示业务表信息
SELECT 'Business Tables:' as info FROM dual;
SELECT table_name, num_rows FROM user_tables WHERE table_name IN ('ORDERS', 'STOCK');

-- 显示Seata表信息
SELECT 'Seata AT Mode Tables:' as info FROM dual;
SELECT table_name FROM user_tables WHERE table_name IN ('UNDO_LOG', 'GLOBAL_TABLE', 'BRANCH_TABLE');

-- 显示初始库存数据
SELECT 'Initial Stock Data:' as info FROM dual;
SELECT * FROM stock;

-- 4. lock_table 表 (锁表 - Seata数据库模式必需)
CREATE TABLE lock_table (
    row_key VARCHAR2(128) NOT NULL,
    xid VARCHAR2(128),
    transaction_id NUMBER(19),
    branch_id NUMBER(19) NOT NULL,
    resource_id VARCHAR2(256),
    table_name VARCHAR2(32),
    pk VARCHAR2(36),
    row_key_hash NUMBER(10),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_lock_table PRIMARY KEY (row_key)
);

-- lock_table 索引
CREATE INDEX idx_lock_table_branch_id ON lock_table(branch_id);
CREATE INDEX idx_lock_table_xid ON lock_table(xid);

COMMIT;
