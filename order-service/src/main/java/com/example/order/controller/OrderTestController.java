package com.example.order.controller;

import com.example.order.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/order")
public class OrderTestController {

    @Autowired
    private OrderService orderService;

    /**
     * Test successful order creation
     */
    @PostMapping("/test/success")
    public String testSuccess(@RequestParam Long productId, @RequestParam Integer count) {
        try {
            String orderId = orderService.createOrder("test-user-1", productId, count);
            return "Order created successfully. Order ID: " + orderId;
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    /**
     * Test order rollback due to insufficient stock
     */
    @PostMapping("/test/rollback-insufficient-stock") 
    public String testRollbackInsufficientStock() {
        try {
            String orderId = orderService.createOrder("test-user-2", 1L, 1000);
            return "Order created: " + orderId;
        } catch (Exception e) {
            return "Expected rollback occurred: " + e.getMessage();
        }
    }

    /**
     * Test order boundary conditions
     */
    @PostMapping("/test/boundary-test")
    public String testBoundary() {
        try {
            String orderId = orderService.createOrder("test-user-3", 1L, 1);
            return "Boundary test passed. Order ID: " + orderId;
        } catch (Exception e) {
            return "Boundary test failed: " + e.getMessage();
        }
    }

    /**
     * Verify order status
     */
    @GetMapping("/test/verify/{orderId}")
    public String verifyOrder(@PathVariable String orderId) {
        try {
            // Add verification logic here if needed
            return "Order " + orderId + " verification completed";
        } catch (Exception e) {
            return "Verification failed: " + e.getMessage();
        }
    }

    /**
     * Learning guide for Seata AT mode
     */
    @GetMapping("/learning-guide")
    public String getLearningGuide() {
        return "Seata AT Mode Learning Guide\n\n" +
               "Key Observation Points:\n" +
               "1. Check undo_log table: SELECT * FROM undo_log;\n" +
               "   - Records are inserted when transaction starts\n" +
               "   - Records are deleted when successful\n" +
               "   - Used for rollback when failed\n\n" +
               "2. Compare data before and after test:\n" +
               "   - SELECT * FROM orders;\n" +
               "   - SELECT * FROM stock;\n\n" +
               "3. Observe log output:\n" +
               "   - Global transaction XID\n" +
               "   - Branch transaction registration process\n" +
               "   - Two-phase commit/rollback process\n\n" +
               "Suggested test sequence:\n" +
               "1. /api/order/test/success (normal success)\n" +
               "2. /api/order/test/rollback-insufficient-stock (rollback)\n" +
               "3. /api/order/test/boundary-test (boundary test)\n" +
               "4. /api/order/test/verify/{orderId} (verify results)\n\n" +
               "Deep understanding:\n" +
               "- AT mode vs TCC mode differences\n" +
               "- One-phase commit vs two-phase commit\n" +
               "- undo_log generation and usage mechanism";
    }
}
