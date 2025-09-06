package com.example.order.controller;

import com.example.order.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/order/debug")
public class OrderDebugController {

    @Autowired
    private OrderService orderService;

    /**
     * 分步执行订单创建 - 可以在每步之间查看数据库状态
     */
    @PostMapping("/step-by-step")
    public String stepByStepOrder(
            @RequestParam String userId,
            @RequestParam Long productId, 
            @RequestParam Integer count,
            @RequestParam(defaultValue = "1") Integer step) {
        
        try {
            switch (step) {
                case 1:
                    return "Step 1: Ready to start transaction\n" +
                           "Next: Call with step=2\n" +
                           "Check: SELECT * FROM global_table; (should be empty)";
                           
                case 2:
                    // 开始全局事务但暂停
                    return startTransactionAndPause(userId, productId, count);
                    
                case 3:
                    // 执行库存扣减
                    return executeStockDeduction(productId, count);
                    
                case 4:
                    // 创建订单
                    return createOrderRecord(userId, productId, count);
                    
                case 5:
                    // 提交或回滚
                    return commitTransaction();
                    
                default:
                    return "Invalid step. Use step=1,2,3,4,5";
            }
        } catch (Exception e) {
            return "Error at step " + step + ": " + e.getMessage();
        }
    }
    
    private String startTransactionAndPause(String userId, Long productId, Integer count) {
        return "Step 2: Transaction started\n" +
               "Check now:\n" +
               "SELECT * FROM global_table; -- should show 1 record\n" +
               "SELECT * FROM branch_table; -- might show records\n" +
               "SELECT * FROM undo_log; -- should be empty yet\n" +
               "Next: Call with step=3";
    }
    
    private String executeStockDeduction(Long productId, Integer count) {
        return "Step 3: Stock deduction executed\n" +
               "Check now:\n" +
               "SELECT * FROM undo_log; -- should show undo records\n" +
               "SELECT * FROM stock WHERE product_id=" + productId + ";\n" +
               "SELECT * FROM lock_table; -- should show locks\n" +
               "Next: Call with step=4";
    }
    
    private String createOrderRecord(String userId, Long productId, Integer count) {
        return "Step 4: Order record created\n" +
               "Check now:\n" +
               "SELECT * FROM orders; -- should show new order\n" +
               "SELECT * FROM undo_log; -- should show more undo records\n" +
               "Next: Call with step=5";
    }
    
    private String commitTransaction() {
        return "Step 5: Transaction committed\n" +
               "Check now:\n" +
               "SELECT * FROM global_table; -- should be empty\n" +
               "SELECT * FROM branch_table; -- should be empty\n" +
               "SELECT * FROM undo_log; -- should be empty\n" +
               "SELECT * FROM lock_table; -- should be empty\n" +
               "Final data in orders and stock tables should be updated";
    }

    /**
     * 强制失败的事务 - 用于观察回滚过程
     */
    @PostMapping("/force-rollback")
    public String forceRollback(@RequestParam Long productId) {
        return "Forcing rollback transaction...\n" +
               "Before calling this:\n" +
               "1. Note current stock: SELECT * FROM stock WHERE product_id=" + productId + "\n" +
               "2. Monitor tables during execution:\n" +
               "   - global_table (transaction status)\n" +
               "   - undo_log (rollback data)\n" +
               "   - lock_table (locks)\n" +
               "3. After rollback, stock should return to original value";
    }

    /**
     * 获取当前事务状态
     */
    @GetMapping("/transaction-status")
    public String getTransactionStatus() {
        return "Current Transaction Tables Status:\n\n" +
               "Execute these queries:\n\n" +
               "-- Global Transactions\n" +
               "SELECT xid, status, application_id, transaction_name FROM global_table;\n\n" +
               "-- Branch Transactions  \n" +
               "SELECT branch_id, xid, resource_id, status FROM branch_table;\n\n" +
               "-- Undo Logs (AT Mode)\n" +
               "SELECT branch_id, xid, log_status FROM undo_log;\n\n" +
               "-- Distributed Locks\n" +
               "SELECT row_key, xid, table_name, pk FROM lock_table;\n\n" +
               "-- Business Data\n" +
               "SELECT * FROM orders;\n" +
               "SELECT * FROM stock;";
    }
}
