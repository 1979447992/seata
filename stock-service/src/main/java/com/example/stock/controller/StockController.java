package com.example.stock.controller;

import com.example.stock.entity.Stock;
import com.example.stock.service.StockService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/stock")
public class StockController {

    @Autowired
    private StockService stockService;

    @PostMapping("/deduct")
    public String deductStock(@RequestParam Long productId,
                             @RequestParam Integer quantity) {
        System.out.println("📨 库存服务收到扣减请求 - 产品ID: " + productId + ", 数量: " + quantity);
        
        try {
            stockService.deductStock(productId, quantity);
            String successMsg = "✅ 库存扣减成功 - 产品ID: " + productId + ", 扣减数量: " + quantity;
            System.out.println("✅ 库存接口返回成功: " + successMsg);
            return successMsg;
            
        } catch (Exception e) {
            String errorMsg = "❌ 库存扣减失败: " + e.getMessage();
            System.err.println("❌ 库存接口返回失败: " + errorMsg);
            throw new RuntimeException(errorMsg, e); // 重新抛出给调用方
        }
    }

    @GetMapping("/{productId}")
    public Stock getStock(@PathVariable Long productId) {
        return stockService.getStockByProductId(productId);
    }

    @GetMapping("/test")
    public String test() {
        return "Stock Service is running!";
    }
}