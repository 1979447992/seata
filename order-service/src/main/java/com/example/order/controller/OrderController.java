package com.example.order.controller;

import com.example.order.entity.Order;
import com.example.order.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/order")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @PostMapping("/create")
    public String createOrder(@RequestParam String userId,
                             @RequestParam Long productId,
                             @RequestParam Integer quantity) {
        System.out.println("📨 收到创建订单请求 - 用户ID: " + userId + ", 产品ID: " + productId + ", 数量: " + quantity);
        
        try {
            String result = orderService.createOrder(userId, productId, quantity);
            System.out.println("✅ 接口返回成功: " + result);
            return result;
            
        } catch (Exception e) {
            String errorMsg = "❌ 订单创建失败 - 已触发Seata AT模式回滚: " + e.getMessage();
            System.err.println("❌ 接口返回失败: " + errorMsg);
            return errorMsg;
        }
    }

    @GetMapping("/{orderId}")
    public Order getOrder(@PathVariable Long orderId) {
        return orderService.getOrderById(orderId);
    }

    @GetMapping("/test")
    public String test() {
        return "Order Service is running!";
    }
}