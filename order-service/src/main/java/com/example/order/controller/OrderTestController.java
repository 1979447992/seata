package com.example.order.controller;

import com.example.order.service.OrderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 🎓 Seata AT模式学习测试控制器
 * 
 * 提供多种测试场景，帮助理解分布式事务的不同情况
 */
@RestController
@RequestMapping("/api/order/test")
public class OrderTestController {

    private static final Logger log = LoggerFactory.getLogger(OrderTestController.class);

    @Autowired
    private OrderService orderService;

    /**
     * 🎯 测试场景1：正常事务成功
     * 库存充足，事务正常完成
     * 
     * 学习要点：
     * - 观察undo_log表的记录和清理过程
     * - 理解两阶段提交的成功流程
     */
    @PostMapping("/success")
    public String testSuccessScenario() {
        log.info("🧪 ========== 测试场景1：事务成功场景 ==========");
        log.info("📝 预期结果：订单创建成功，库存正常扣减，undo_log自动清理");
        
        try {
            String result = orderService.createOrder("test_user", 1001L, 5);
            log.info("✅ 测试场景1完成：{}", result);
            return result;
        } catch (Exception e) {
            log.error("❌ 测试场景1意外失败：{}", e.getMessage());
            return "测试失败：" + e.getMessage();
        }
    }

    /**
     * 🎯 测试场景2：库存不足导致回滚
     * 故意扣减超出库存的数量，触发分布式事务回滚
     * 
     * 学习要点：
     * - 观察Seata如何基于undo_log执行回滚
     * - 理解异常传播如何触发全局事务回滚
     * - 验证所有操作都被正确回滚
     */
    @PostMapping("/rollback-insufficient-stock")
    public String testRollbackScenario() {
        log.info("🧪 ========== 测试场景2：库存不足回滚场景 ==========");
        log.info("📝 预期结果：库存服务异常 → 全局事务回滚 → 订单数据被删除");
        log.info("💡 学习提示：观察undo_log表的回滚过程");
        
        try {
            // 故意扣减一个很大的数量，必定会库存不足
            String result = orderService.createOrder("test_user", 1003L, 999);
            log.warn("⚠️ 意外成功：这不应该发生，请检查库存数据");
            return result;
        } catch (Exception e) {
            log.info("✅ 测试场景2按预期失败：{}", e.getMessage());
            log.info("🔍 请检查数据库：订单表应该没有新记录，库存表应该没有变化");
            return "按预期回滚：" + e.getMessage();
        }
    }

    /**
     * 🎯 测试场景3：边界情况测试
     * 恰好扣减完所有库存
     * 
     * 学习要点：
     * - 理解原子更新的重要性
     * - 观察边界情况下的事务行为
     */
    @PostMapping("/boundary-test")
    public String testBoundaryScenario() {
        log.info("🧪 ========== 测试场景3：边界情况测试 ==========");
        log.info("📝 测试目标：精确扣减剩余库存，测试边界处理");
        
        try {
            // 产品1003初始库存是10，这里恰好扣减10个
            String result = orderService.createOrder("test_user", 1003L, 10);
            log.info("✅ 测试场景3完成：{}", result);
            log.info("🔍 库存应该变为0，订单状态应该为SUCCESS");
            return result;
        } catch (Exception e) {
            log.error("❌ 测试场景3失败：{}", e.getMessage());
            return "测试失败：" + e.getMessage();
        }
    }

    /**
     * 🎯 测试场景4：数据验证
     * 提供查询接口，验证事务结果
     */
    @GetMapping("/verify/{orderId}")
    public String verifyOrder(@PathVariable Long orderId) {
        log.info("🔍 验证订单状态：orderId = {}", orderId);
        
        try {
            var order = orderService.getOrderById(orderId);
            if (order == null) {
                return "❌ 订单不存在（可能已被回滚删除）";
            }
            
            String status = order.getStatus();
            return String.format("📋 订单验证结果 - ID: %d, 用户: %s, 产品: %d, 数量: %d, 状态: %s", 
                order.getId(), order.getUserId(), order.getProductId(), order.getQuantity(), status);
                
        } catch (Exception e) {
            log.error("查询订单失败：{}", e.getMessage());
            return "查询失败：" + e.getMessage();
        }
    }

    /**
     * 🎯 学习指导：如何观察Seata AT模式
     */
    @GetMapping("/learning-guide")
    public String getLearningGuide() {
        return """
            📚 Seata AT模式学习指南
            
            🔍 观察要点：
            1. 查看undo_log表：SELECT * FROM undo_log;
               - 事务开始时会插入记录
               - 成功时会删除记录
               - 失败时用于回滚
            
            2. 对比测试前后的数据：
               - SELECT * FROM orders;
               - SELECT * FROM stock;
            
            3. 观察日志输出：
               - 全局事务XID
               - 分支事务注册过程
               - 二阶段提交/回滚过程
            
            🧪 建议测试顺序：
            1. /api/order/test/success （正常成功）
            2. /api/order/test/rollback-insufficient-stock （回滚）
            3. /api/order/test/boundary-test （边界测试）
            4. /api/order/test/verify/{orderId} （验证结果）
            
            💡 深入理解：
            - AT模式 vs TCC模式的区别
            - 一阶段提交 vs 二阶段提交
            - undo_log的生成和使用机制
            """;
    }
}