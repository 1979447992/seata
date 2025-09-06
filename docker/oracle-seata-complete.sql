-- =====================================================
-- Oracle 版本的 Seata AT 模式完整初始化脚本
-- 包含业务表和所有Seata核心表
-- =====================================================

-- 清理已存在的表（如果存在）
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE orders CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE stock CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE global_table CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE branch_table CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE lock_table CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE undo_log CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- =====================================================
-- 业务表创建
-- =====================================================

-- 1. 订单表
CREATE TABLE orders (
    id NUMBER(19) NOT NULL,
    user_id VARCHAR2(50) NOT NULL,
    product_id NUMBER(19) NOT NULL,
    count NUMBER(10) NOT NULL,
    money NUMBER(10,2) NOT NULL,
    status NUMBER(1) DEFAULT 0,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE orders ADD CONSTRAINT pk_orders PRIMARY KEY (id);

-- 2. 库存表
CREATE TABLE stock (
    id NUMBER(19) NOT NULL,
    product_id NUMBER(19) NOT NULL,
    total NUMBER(10) NOT NULL,
    used NUMBER(10) DEFAULT 0 NOT NULL,
    residue NUMBER(10) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE stock ADD CONSTRAINT pk_stock PRIMARY KEY (id);
ALTER TABLE stock ADD CONSTRAINT uk_stock_product_id UNIQUE (product_id);

-- =====================================================
-- Seata AT 模式核心表 (数据库模式)
-- =====================================================

-- 1. 全局事务表
CREATE TABLE global_table (
    xid VARCHAR2(128) NOT NULL,
    transaction_id NUMBER(19) NOT NULL,
    status NUMBER(3) NOT NULL,
    application_id VARCHAR2(32),
    transaction_service_group VARCHAR2(32),
    transaction_name VARCHAR2(128),
    timeout NUMBER(10),
    begin_time NUMBER(19),
    application_data VARCHAR2(2000),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE global_table ADD CONSTRAINT pk_global_table PRIMARY KEY (xid);

-- 2. 分支事务表
CREATE TABLE branch_table (
    branch_id NUMBER(19) NOT NULL,
    xid VARCHAR2(128) NOT NULL,
    transaction_id NUMBER(19),
    resource_group_id VARCHAR2(32),
    resource_id VARCHAR2(256),
    branch_type VARCHAR2(8),
    status NUMBER(3),
    client_id VARCHAR2(64),
    application_data VARCHAR2(2000),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE branch_table ADD CONSTRAINT pk_branch_table PRIMARY KEY (branch_id);

-- 3. 分布式锁表
CREATE TABLE lock_table (
    row_key VARCHAR2(128) NOT NULL,
    xid VARCHAR2(128),
    transaction_id NUMBER(19),
    branch_id NUMBER(19) NOT NULL,
    resource_id VARCHAR2(256),
    table_name VARCHAR2(32),
    pk VARCHAR2(36),
    gmt_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    gmt_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE lock_table ADD CONSTRAINT pk_lock_table PRIMARY KEY (row_key);

-- 4. AT模式回滚日志表 (最重要)
CREATE TABLE undo_log (
    branch_id NUMBER(19) NOT NULL,
    xid VARCHAR2(128) NOT NULL,
    context VARCHAR2(128) NOT NULL,
    rollback_info BLOB NOT NULL,
    log_status NUMBER(10) NOT NULL,
    log_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE undo_log ADD CONSTRAINT pk_undo_log PRIMARY KEY (branch_id, xid);

-- =====================================================
-- 创建序列和索引
-- =====================================================

-- 订单表序列
CREATE SEQUENCE orders_seq START WITH 1 INCREMENT BY 1;

-- 索引优化
CREATE INDEX idx_global_table_status ON global_table(status);
CREATE INDEX idx_branch_table_xid ON branch_table(xid);
CREATE INDEX idx_lock_table_branch_id ON lock_table(branch_id);
CREATE INDEX idx_undo_log_xid ON undo_log(xid);

-- =====================================================
-- 插入初始测试数据
-- =====================================================

-- 插入库存数据
INSERT INTO stock (id, product_id, total, used, residue) VALUES (1, 1, 1000, 0, 1000);
INSERT INTO stock (id, product_id, total, used, residue) VALUES (2, 2, 500, 0, 500);
INSERT INTO stock (id, product_id, total, used, residue) VALUES (3, 3, 200, 0, 200);

COMMIT;

-- =====================================================
-- 验证创建结果
-- =====================================================

SELECT 'Oracle Seata AT Mode Database Initialized Successfully!' as message FROM dual;

SELECT 'Created Tables:' as info FROM dual;
SELECT table_name FROM user_tables 
WHERE table_name IN ('ORDERS','STOCK','GLOBAL_TABLE','BRANCH_TABLE','LOCK_TABLE','UNDO_LOG')
ORDER BY table_name;

SELECT 'Initial Stock Data:' as info FROM dual;
SELECT * FROM stock;

SELECT 'Ready for Seata AT Mode Learning!' as status FROM dual;
