-- ===========================================
-- Oracle + Seata 环境清理脚本
-- 清理所有Seata事务数据，重置环境
-- ===========================================

SET SERVEROUTPUT ON;

-- ================================ 清理Seata事务数据 ================================
SELECT '=== 开始清理Seata事务数据 ===' as info FROM DUAL;

-- 1. 查看清理前的数据状态
SELECT '清理前数据统计:' as info FROM dual;
SELECT 'global_table(全局事务)' as 表名, COUNT(*) as 记录数 FROM global_table
UNION ALL
SELECT 'branch_table(分支事务)', COUNT(*) FROM branch_table  
UNION ALL
SELECT 'lock_table(资源锁)', COUNT(*) FROM lock_table
UNION ALL
SELECT 'undo_log(回滚日志)', COUNT(*) FROM undo_log
UNION ALL
SELECT 'orders(业务订单)', COUNT(*) FROM orders;

-- 2. 清理未完成的事务数据
-- 清理分支事务表中未完成的事务 (4=二阶段已提交, 7=二阶段已回滚)
DELETE FROM branch_table WHERE status NOT IN (4, 7);

-- 清理全局事务表中未完成的事务 (4=已提交, 6=已回滚)
DELETE FROM global_table WHERE status NOT IN (4, 6);

-- 清理所有资源锁
DELETE FROM lock_table;

-- 清理所有回滚日志
DELETE FROM undo_log;

-- 3. 可选：清理业务数据（取消注释下面的行来清理业务表）
-- DELETE FROM orders;
-- ALTER SEQUENCE seq_orders RESTART START WITH 1;

-- 4. 重置序列（如果需要从1开始）
-- 注意：Oracle没有RESTART，需要删除重建
/*
DROP SEQUENCE seq_undo_log_id;
CREATE SEQUENCE seq_undo_log_id START WITH 1 INCREMENT BY 1 MAXVALUE 999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER;

DROP SEQUENCE undo_log_seq;  
CREATE SEQUENCE undo_log_seq START WITH 1 INCREMENT BY 1 MAXVALUE 999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER;

DROP SEQUENCE seata_undo_log_seq;
CREATE SEQUENCE seata_undo_log_seq START WITH 1 INCREMENT BY 1 MAXVALUE 999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER;
*/

-- ================================ 验证清理结果 ================================
SELECT '=== 清理后数据统计 ===' as info FROM dual;

SELECT 'global_table' as 表名, COUNT(*) as 剩余记录数 FROM global_table
UNION ALL
SELECT 'branch_table', COUNT(*) FROM branch_table  
UNION ALL
SELECT 'lock_table', COUNT(*) FROM lock_table
UNION ALL
SELECT 'undo_log', COUNT(*) FROM undo_log
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL  
SELECT 'stock', COUNT(*) FROM stock;

-- 显示当前库存状态
SELECT '当前库存状态:' as info FROM dual;
SELECT product_id as 商品ID, quantity as 库存数量, 
       create_time as 创建时间, update_time as 更新时间 
FROM stock ORDER BY product_id;

-- 提交清理操作
COMMIT;

SELECT '✅ Seata环境清理完成！可以重新开始测试分布式事务' as status FROM dual;