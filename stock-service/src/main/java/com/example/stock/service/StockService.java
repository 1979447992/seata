package com.example.stock.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.stock.entity.Stock;
import com.example.stock.mapper.StockMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class StockService {

    private static final Logger log = LoggerFactory.getLogger(StockService.class);

    @Autowired
    private StockMapper stockMapper;

    /**
     * 🌟 库存扣减 - Seata AT模式分支事务
     * 
     * @Transactional 本地事务注解的作用：
     * 1. 在Seata分布式事务框架下，这是一个"分支事务"
     * 2. Seata会在执行前记录undo_log，用于可能的回滚
     * 3. 如果全局事务失败，Seata会根据undo_log自动生成回滚SQL
     * 
     * 注意：本方法看似简单，但在分布式事务中承担重要角色
     */
    @Transactional(rollbackFor = Exception.class)
    public void deductStock(Long productId, Integer quantity) {
        log.info("🏪 ====== 库存服务：开始扣减库存 ======");
        log.info("📦 扣减参数 - 产品ID: {}, 数量: {}", productId, quantity);
        
        // 查询当前库存 (这里会被Seata记录到undo_log中)
        Stock stock = stockMapper.selectOne(
            new QueryWrapper<Stock>().eq("product_id", productId)
        );
        
        if (stock == null) {
            log.error("❌ 库存服务错误：产品不存在 - {}", productId);
            throw new RuntimeException("产品不存在: " + productId);
        }
        
        log.info("📊 库存检查 - 当前库存: {}, 需要扣减: {}", stock.getQuantity(), quantity);
        
        // 💡 库存不足检查：这里会触发Seata分布式事务回滚
        if (stock.getQuantity() < quantity) {
            log.error("💥 库存不足！将触发Seata分布式事务回滚");
            log.error("📊 库存不足详情：当前库存 {} < 需要数量 {}", stock.getQuantity(), quantity);
            log.error("🔄 此异常会传播到全局事务，触发所有服务回滚");
            throw new RuntimeException("库存不足! 当前库存: " + stock.getQuantity() + ", 需要: " + quantity);
        }
        
        // 执行库存扣减 (原子更新，防止并发问题)
        // 💡 这个操作会被Seata记录，如果全局事务回滚，会自动恢复
        log.info("⚡ 执行原子库存扣减操作...");
        int updated = stockMapper.deductStock(productId, quantity);
        
        if (updated == 0) {
            log.error("❌ 库存扣减失败：可能是并发更新导致，或库存在扣减过程中变化");
            throw new RuntimeException("库存扣减失败，可能库存不足或并发冲突");
        }
        
        // 确认扣减结果
        Stock updatedStock = stockMapper.selectOne(
            new QueryWrapper<Stock>().eq("product_id", productId)
        );
        
        log.info("✅ 库存扣减成功！");
        log.info("📊 扣减结果：{} → {} (减少了{})", stock.getQuantity(), updatedStock.getQuantity(), quantity);
        log.info("💾 Seata已记录此操作到undo_log，支持自动回滚");
        log.info("🏪 ====== 库存服务：扣减完成 ======");
    }

    public Stock getStockByProductId(Long productId) {
        return stockMapper.selectOne(
            new QueryWrapper<Stock>().eq("product_id", productId)
        );
    }
}