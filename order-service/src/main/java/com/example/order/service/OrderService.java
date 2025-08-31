package com.example.order.service;

import com.example.order.entity.Order;
import com.example.order.feign.StockFeignClient;
import com.example.order.mapper.OrderMapper;
import io.seata.spring.annotation.GlobalTransactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);
    
    @Autowired
    private OrderMapper orderMapper;
    
    @Autowired
    private StockFeignClient stockFeignClient;

    /**
     * 🌟 Seata AT模式分布式事务演示
     * 
     * @GlobalTransactional 注解的作用：
     * 1. 开启全局事务，获得全局事务ID (XID)
     * 2. 协调各个分支事务的提交或回滚
     * 3. rollbackFor: 指定哪些异常触发回滚
     * 4. timeoutMills: 全局事务超时时间
     * 
     * AT模式工作流程：
     * 第一阶段：各服务执行业务SQL并记录undo_log
     * 第二阶段：根据第一阶段结果，决定提交或回滚
     */
    @GlobalTransactional(rollbackFor = Exception.class, timeoutMills = 30000)
    public String createOrder(String userId, Long productId, Integer quantity) {
        Order order = null;
        try {
            log.info("====== 🚀 开始分布式事务：创建订单 ======");
            log.info("📋 事务参数 - 用户ID: {}, 产品ID: {}, 数量: {}", userId, productId, quantity);
            
            // 步骤1: 创建订单记录 (会在undo_log中记录回滚信息)
            order = new Order(userId, productId, quantity, "PENDING");
            orderMapper.insert(order);
            log.info("✅ 步骤1完成: 订单创建成功，订单ID: {}", order.getId());
            
            // 步骤2: 远程调用库存服务扣减库存 (跨服务的分支事务)
            log.info("🔄 步骤2开始: 调用库存服务扣减库存...");
            stockFeignClient.deductStock(productId, quantity);
            log.info("✅ 步骤2完成: 库存扣减成功");
            
            // 步骤3: 更新订单状态为成功
            order.setStatus("SUCCESS");
            orderMapper.updateById(order);
            log.info("✅ 步骤3完成: 订单状态更新为SUCCESS");
            
            log.info("🎉 ====== 分布式事务成功完成 ======");
            return "✅ 订单创建成功！订单ID: " + order.getId() + ", 产品ID: " + productId + ", 数量: " + quantity;
            
        } catch (Exception e) {
            log.error("💥 ====== 分布式事务失败，触发Seata AT模式自动回滚 ======");
            log.error("❌ 失败原因: {}", e.getMessage());
            
            if (order != null) {
                log.error("🔄 Seata将自动回滚订单: {}", order.getId());
            }
            log.error("🔄 Seata将自动回滚库存扣减操作");
            log.error("⏳ ====== 等待Seata执行AT模式二阶段回滚 ======");
            log.error("💡 回滚原理：Seata会根据undo_log表中的记录生成反向SQL自动执行");
            
            // 重新抛出异常，让Seata感知到事务失败
            throw new RuntimeException("❌ 订单创建失败 - 已触发Seata AT模式回滚: " + e.getMessage(), e);
        }
    }

    public Order getOrderById(Long orderId) {
        return orderMapper.selectById(orderId);
    }
}