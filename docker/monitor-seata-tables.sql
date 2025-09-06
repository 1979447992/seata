-- =====================================================
-- Seata AT模式表监控脚本
-- 用于观察事务执行过程中的表变化
-- =====================================================

-- 显示当前时间
SELECT TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF3') as current_time FROM dual;

PROMPT ===============================================
PROMPT 1. 全局事务状态 (Global Transactions)
PROMPT ===============================================
SELECT 
    xid,
    transaction_id,
    CASE status 
        WHEN 0 THEN 'Begin'
        WHEN 1 THEN 'Committing' 
        WHEN 2 THEN 'Committed'
        WHEN 3 THEN 'Rollbacking'
        WHEN 4 THEN 'Rollbacked'
        ELSE 'Unknown'
    END as status_desc,
    application_id,
    transaction_service_group,
    TO_CHAR(gmt_create, 'HH24:MI:SS') as created_time
FROM global_table
ORDER BY gmt_create DESC;

PROMPT ===============================================  
PROMPT 2. 分支事务状态 (Branch Transactions)
PROMPT ===============================================
SELECT 
    branch_id,
    SUBSTR(xid, 1, 20) || '...' as xid_short,
    resource_id,
    branch_type,
    CASE status
        WHEN 0 THEN 'Registered'
        WHEN 1 THEN 'Phase1_Done'  
        WHEN 2 THEN 'Phase1_Failed'
        WHEN 3 THEN 'Phase1_Timeout'
        WHEN 4 THEN 'Phase2_Committed'
        WHEN 5 THEN 'Phase2_Rollbacked'
        WHEN 6 THEN 'Phase2_RollbackFailed_Retryable'
        WHEN 7 THEN 'Phase2_RollbackFailed_Unretryable'
        ELSE 'Unknown'
    END as status_desc,
    TO_CHAR(gmt_create, 'HH24:MI:SS') as created_time
FROM branch_table  
ORDER BY gmt_create DESC;

PROMPT ===============================================
PROMPT 3. AT模式回滚日志 (Undo Logs)  
PROMPT ===============================================
SELECT 
    branch_id,
    SUBSTR(xid, 1, 20) || '...' as xid_short,
    context,
    CASE log_status
        WHEN 0 THEN 'Normal'
        WHEN 1 THEN 'GlobalFinished' 
        ELSE 'Unknown'
    END as log_status_desc,
    LENGTH(rollback_info) as rollback_data_size,
    TO_CHAR(log_created, 'HH24:MI:SS') as created_time
FROM undo_log
ORDER BY log_created DESC;

PROMPT ===============================================
PROMPT 4. 分布式锁状态 (Distributed Locks)
PROMPT ===============================================  
SELECT 
    SUBSTR(row_key, 1, 30) || '...' as row_key_short,
    SUBSTR(xid, 1, 20) || '...' as xid_short,
    table_name,
    pk,
    TO_CHAR(gmt_create, 'HH24:MI:SS') as created_time
FROM lock_table
ORDER BY gmt_create DESC;

PROMPT ===============================================
PROMPT 5. 业务数据状态 (Business Data)
PROMPT ===============================================

PROMPT --- 订单表 ---
SELECT 
    id,
    user_id, 
    product_id,
    count,
    money,
    CASE status
        WHEN 0 THEN 'Created'
        WHEN 1 THEN 'Finished' 
        ELSE 'Unknown'
    END as status_desc,
    TO_CHAR(create_time, 'HH24:MI:SS') as created_time
FROM orders 
ORDER BY create_time DESC;

PROMPT --- 库存表 ---
SELECT 
    id,
    product_id,
    total,
    used, 
    residue,
    TO_CHAR(update_time, 'HH24:MI:SS') as updated_time
FROM stock
ORDER BY product_id;

PROMPT ===============================================
PROMPT 监控完成 - 每次调用接口后执行此脚本观察变化
PROMPT ===============================================
