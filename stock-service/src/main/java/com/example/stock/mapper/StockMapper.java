package com.example.stock.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.stock.entity.Stock;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface StockMapper extends BaseMapper<Stock> {
    
    /**
     * 🌟 原子库存扣减操作 - 防止超卖的关键SQL
     * 
     * 这个SQL的巧妙之处：
     * 1. residue = residue - #{quantity}：原子性地减少库存
     * 2. WHERE residue >= #{quantity}：确保扣减时库存充足
     * 3. 如果库存不足，WHERE条件不满足，update返回0，表示扣减失败
     * 
     * 在Seata AT模式中：
     * - 执行前会记录原始数据到undo_log
     * - 如果全局事务回滚，会根据undo_log自动恢复库存
     * 
     * 注意：这是Demo简化版本，生产环境建议使用乐观锁版本号控制
     */
    @Update("UPDATE stock SET residue = residue - #{quantity} WHERE product_id = #{productId} AND residue >= #{quantity}")
    int deductStock(@Param("productId") Long productId, @Param("quantity") Integer quantity);
}