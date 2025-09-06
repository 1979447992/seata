#!/bin/bash

# Seata AT模式实时监控脚本

echo "=========================================="
echo "Seata AT Mode Real-time Monitor"  
echo "Press Ctrl+C to stop"
echo "=========================================="

while true; do
    echo ""
    echo "=== $(date '+%H:%M:%S') ==="
    
    echo "Global Transactions:"
    docker exec seata-oracle sqlplus -s seata_user/seata_pass@XEPDB1 << 'EOSQL' 2>/dev/null
SELECT COUNT(*) || ' active global transactions' FROM global_table;
SELECT xid, status FROM global_table WHERE rownum <= 3;
EOSQL

    echo ""
    echo "Undo Logs:"
    docker exec seata-oracle sqlplus -s seata_user/seata_pass@XEPDB1 << 'EOSQL' 2>/dev/null  
SELECT COUNT(*) || ' undo log records' FROM undo_log;
EOSQL

    echo ""
    echo "Locks:"
    docker exec seata-oracle sqlplus -s seata_user/seata_pass@XEPDB1 << 'EOSQL' 2>/dev/null
SELECT COUNT(*) || ' active locks' FROM lock_table;
EOSQL

    echo ""
    echo "Stock Status:"
    docker exec seata-oracle sqlplus -s seata_user/seata_pass@XEPDB1 << 'EOSQL' 2>/dev/null
SELECT product_id, total, used, residue FROM stock ORDER BY product_id;
EOSQL

    sleep 2
done
