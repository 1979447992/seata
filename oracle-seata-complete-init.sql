-- ===========================================
-- Oracle + Seata AT模式 完整初始化脚本
-- 包含业务表、Seata系统表、序列、触发器、初始数据
-- 适用于本地开发环境学习使用
-- ===========================================

-- ================================ 清理现有对象 ================================
-- 1. 清理触发器
BEGIN
    FOR rec IN (SELECT trigger_name FROM user_triggers WHERE trigger_name IN (
        'TRG_ORDERS_ID', 'TRG_STOCK_ID', 'TRG_UNDO_LOG_ID'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || rec.trigger_name;
        DBMS_OUTPUT.PUT_LINE('已删除触发器: ' || rec.trigger_name);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('删除触发器时出错: ' || SQLERRM);
END;
/

-- 2. 清理表（如果存在）
BEGIN
    FOR rec IN (SELECT table_name FROM user_tables WHERE table_name IN (
        'ORDERS', 'STOCK', 'GLOBAL_TABLE', 'BRANCH_TABLE', 'LOCK_TABLE', 'UNDO_LOG'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS';
        DBMS_OUTPUT.PUT_LINE('已删除表: ' || rec.table_name);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('删除表时出错: ' || SQLERRM);
END;
/

-- 3. 清理序列
BEGIN
    FOR rec IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN (
        'SEQ_ORDERS', 'SEQ_STOCK', 'SEQ_UNDO_LOG_ID', 'UNDO_LOG_SEQ', 'SEQ_UNDO_LOG', 'SEATA_UNDO_LOG_SEQ'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || rec.sequence_name;
        DBMS_OUTPUT.PUT_LINE('已删除序列: ' || rec.sequence_name);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('删除序列时出错: ' || SQLERRM);
END;
/

-- ================================ 创建业务表 ================================
-- 1. 创建订单表
CREATE TABLE orders (
    id NUMBER(19) PRIMARY KEY,          -- 订单ID（主键）
    user_id VARCHAR2(50) NOT NULL,      -- 用户ID
    product_id NUMBER(19) NOT NULL,     -- 产品ID
    quantity NUMBER(10) NOT NULL,       -- 订购数量
    status VARCHAR2(20) DEFAULT 'PENDING', -- 订单状态
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- 更新时间
);

COMMENT ON TABLE orders IS '订单表 - 存储用户订单信息';
COMMENT ON COLUMN orders.id IS '订单唯一标识ID';
COMMENT ON COLUMN orders.user_id IS '下单用户的唯一标识';
COMMENT ON COLUMN orders.product_id IS '订购商品的ID';
COMMENT ON COLUMN orders.quantity IS '订购商品的数量';
COMMENT ON COLUMN orders.status IS '订单状态：PENDING-待处理，COMPLETED-已完成，FAILED-失败';

-- 2. 创建库存表
CREATE TABLE stock (
    id NUMBER(19) PRIMARY KEY,          -- 库存ID（主键）
    product_id NUMBER(19) UNIQUE NOT NULL, -- 产品ID（唯一）
    quantity NUMBER(10) NOT NULL,       -- 库存数量
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 创建时间
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- 更新时间
);

COMMENT ON TABLE stock IS '库存表 - 存储商品库存信息';
COMMENT ON COLUMN stock.id IS '库存记录唯一标识ID';
COMMENT ON COLUMN stock.product_id IS '商品ID，与订单表关联';
COMMENT ON COLUMN stock.quantity IS '当前库存数量';

-- ================================ 创建Seata系统表 ================================
-- 1. 全局事务表 - 存储全局事务信息
CREATE TABLE global_table (
    xid VARCHAR2(128) PRIMARY KEY,      -- 全局事务ID
    transaction_id NUMBER(19),          -- 事务ID
    status NUMBER(10) NOT NULL,         -- 事务状态
    application_id VARCHAR2(32),        -- 应用ID
    transaction_service_group VARCHAR2(32), -- 事务服务组
    transaction_name VARCHAR2(128),     -- 事务名称
    timeout NUMBER(10),                 -- 超时时间
    begin_time NUMBER(19),              -- 开始时间
    application_data VARCHAR2(2000),    -- 应用数据
    gmt_create TIMESTAMP,               -- 创建时间
    gmt_modified TIMESTAMP              -- 修改时间
);

COMMENT ON TABLE global_table IS 'Seata全局事务表 - 记录分布式事务的全局信息';

-- 2. 分支事务表 - 存储分支事务信息
CREATE TABLE branch_table (
    branch_id NUMBER(19) PRIMARY KEY,   -- 分支事务ID
    xid VARCHAR2(128) NOT NULL,         -- 全局事务ID
    transaction_id NUMBER(19),          -- 事务ID
    resource_group_id VARCHAR2(32),     -- 资源组ID
    resource_id VARCHAR2(256),          -- 资源ID
    branch_type VARCHAR2(8),            -- 分支类型
    status NUMBER(10),                  -- 分支状态
    client_id VARCHAR2(64),             -- 客户端ID
    application_data VARCHAR2(2000),    -- 应用数据
    gmt_create TIMESTAMP,               -- 创建时间
    gmt_modified TIMESTAMP              -- 修改时间
);

COMMENT ON TABLE branch_table IS 'Seata分支事务表 - 记录分布式事务的分支信息';

-- 3. 锁表 - 存储资源锁信息
CREATE TABLE lock_table (
    row_key VARCHAR2(128) PRIMARY KEY,  -- 行锁键
    xid VARCHAR2(96),                   -- 全局事务ID
    transaction_id NUMBER(19),          -- 事务ID
    branch_id NUMBER(19),               -- 分支事务ID
    resource_id VARCHAR2(256),          -- 资源ID
    table_name VARCHAR2(32),            -- 表名
    pk VARCHAR2(36),                    -- 主键值
    row_key_2 VARCHAR2(128),            -- 行锁键2（扩展）
    gmt_create TIMESTAMP,               -- 创建时间
    gmt_modified TIMESTAMP              -- 修改时间
);

COMMENT ON TABLE lock_table IS 'Seata锁表 - 管理分布式事务的资源锁定';

-- 4. 回滚日志表 - 存储AT模式的回滚信息
CREATE TABLE undo_log (
    id NUMBER(19) PRIMARY KEY,          -- 主键ID
    branch_id NUMBER(19) NOT NULL,      -- 分支事务ID
    xid VARCHAR2(128) NOT NULL,         -- 全局事务ID
    context VARCHAR2(128) NOT NULL,     -- 上下文
    rollback_info BLOB NOT NULL,        -- 回滚信息
    log_status NUMBER(10) NOT NULL,     -- 日志状态
    log_created TIMESTAMP,              -- 日志创建时间
    log_modified TIMESTAMP              -- 日志修改时间
);

COMMENT ON TABLE undo_log IS 'Seata回滚日志表 - AT模式回滚时使用的数据快照';

-- ================================ 创建序列 ================================
-- 1. 业务表序列
CREATE SEQUENCE seq_orders
    START WITH 1 INCREMENT BY 1 MAXVALUE 999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER;

CREATE SEQUENCE seq_stock  
    START WITH 1 INCREMENT BY 1 MAXVALUE 999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER;

-- 2. Seata系统表序列
CREATE SEQUENCE seq_undo_log_id
    START WITH 1 INCREMENT BY 1 MAXVALUE 999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER;

-- 3. 兼容性序列（Seata可能使用的不同命名）
CREATE SEQUENCE undo_log_seq
    START WITH 1 INCREMENT BY 1 MAXVALUE 999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER;

CREATE SEQUENCE seata_undo_log_seq
    START WITH 1 INCREMENT BY 1 MAXVALUE 999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER;

-- ================================ 创建触发器 ================================
-- 1. 订单表ID自动生成
CREATE OR REPLACE TRIGGER trg_orders_id
    BEFORE INSERT ON orders
    FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_orders.NEXTVAL;
    END IF;
END;
/

-- 2. 库存表ID自动生成
CREATE OR REPLACE TRIGGER trg_stock_id
    BEFORE INSERT ON stock
    FOR EACH ROW  
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_stock.NEXTVAL;
    END IF;
END;
/

-- 3. undo_log表ID自动生成（支持多种序列）
CREATE OR REPLACE TRIGGER trg_undo_log_id
    BEFORE INSERT ON undo_log
    FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        -- 尝试使用主要序列
        BEGIN
            :NEW.id := seq_undo_log_id.NEXTVAL;
        EXCEPTION
            WHEN OTHERS THEN
                -- 如果主要序列失败，尝试备用序列
                BEGIN
                    :NEW.id := undo_log_seq.NEXTVAL;
                EXCEPTION
                    WHEN OTHERS THEN
                        :NEW.id := seata_undo_log_seq.NEXTVAL;
                END;
        END;
    END IF;
END;
/

-- ================================ 插入初始数据 ================================
-- 1. 初始化商品库存
INSERT INTO stock (product_id, quantity) VALUES (1, 1000);  -- 商品1：库存1000
INSERT INTO stock (product_id, quantity) VALUES (2, 500);   -- 商品2：库存500
INSERT INTO stock (product_id, quantity) VALUES (3, 200);   -- 商品3：库存200

-- ================================ 验证安装结果 ================================
SELECT '=== Oracle + Seata AT模式环境初始化完成 ===' as status FROM dual;

-- 显示创建的表
SELECT '业务表:' as info FROM dual;
SELECT table_name FROM user_tables WHERE table_name IN ('ORDERS', 'STOCK');

SELECT 'Seata系统表:' as info FROM dual;
SELECT table_name FROM user_tables WHERE table_name IN ('GLOBAL_TABLE', 'BRANCH_TABLE', 'LOCK_TABLE', 'UNDO_LOG');

-- 显示创建的序列
SELECT '创建的序列:' as info FROM dual;
SELECT sequence_name FROM user_sequences 
WHERE sequence_name IN ('SEQ_ORDERS', 'SEQ_STOCK', 'SEQ_UNDO_LOG_ID', 'UNDO_LOG_SEQ', 'SEATA_UNDO_LOG_SEQ')
ORDER BY sequence_name;

-- 显示初始库存数据
SELECT '初始库存数据:' as info FROM dual;
SELECT product_id as 商品ID, quantity as 库存数量 FROM stock ORDER BY product_id;

-- 提交所有更改
COMMIT;

SELECT '🎉 初始化成功！现在可以测试Seata AT模式分布式事务了！' as final_status FROM dual;