package com.example.order.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(name = "stock-service", url = "${stock.service.url:http://stock-service:8081}")
public interface StockFeignClient {
    
    @PostMapping("/api/stock/deduct")
    void deductStock(@RequestParam("productId") Long productId, 
                     @RequestParam("quantity") Integer quantity);
}