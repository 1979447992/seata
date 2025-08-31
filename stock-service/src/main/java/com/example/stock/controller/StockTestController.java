package com.example.stock.controller;

import com.example.stock.service.StockService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 🎓 库存服务学习测试控制器
 */
@RestController
@RequestMapping("/api/stock/test")
public class StockTestController {

    private static final Logger log = LoggerFactory.getLogger(StockTestController.class);

    @Autowired
    private StockService stockService;

    /**
     * 🔍 查看当前库存状态
     * 帮助学习者了解测试前后的数据变化
     */
    @GetMapping("/status")
    public String getStockStatus() {
        log.info("📊 查询所有产品库存状态");
        
        try {
            StringBuilder result = new StringBuilder("📦 当前库存状态：\n");
            
            // 查询三个测试产品的库存
            Long[] productIds = {1001L, 1002L, 1003L};
            for (Long productId : productIds) {
                var stock = stockService.getStockByProductId(productId);
                if (stock != null) {
                    result.append(String.format("产品%d: %d件\n", productId, stock.getQuantity()));
                } else {
                    result.append(String.format("产品%d: 未找到\n", productId));
                }
            }
            
            result.append("\n💡 观察提示：");
            result.append("\n- 产品1001：库存充足，适合成功测试");
            result.append("\n- 产品1002：中等库存，可测试部分扣减");
            result.append("\n- 产品1003：少量库存，适合回滚测试");
            
            return result.toString();
            
        } catch (Exception e) {
            log.error("查询库存失败：{}", e.getMessage());
            return "❌ 查询失败：" + e.getMessage();
        }
    }

    /**
     * 🎯 模拟并发测试场景说明
     */
    @GetMapping("/concurrency-guide")
    public String getConcurrencyGuide() {
        return """
            🚀 并发测试指南
            
            🔧 如何模拟并发场景：
            1. 使用工具（如JMeter、curl）同时发送多个请求
            2. 观察库存扣减的原子性
            3. 检查是否出现超卖现象
            
            📝 测试命令示例：
            # 同时发送5个请求扣减产品1002库存
            for i in {1..5}; do
                curl -X POST "http://localhost:8080/api/order/create?userId=user$i&productId=1002&quantity=15" &
            done
            wait
            
            🔍 观察要点：
            - 只有部分请求成功（不超卖）
            - 失败的请求触发回滚
            - undo_log表的并发处理
            
            ⚠️ 注意：
            当前Demo使用简化的库存扣减逻辑
            生产环境建议使用版本号乐观锁
            """;
    }
}