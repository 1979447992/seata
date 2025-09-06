package com.example.stock.controller;

import com.example.stock.service.StockService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/stock")
public class StockTestController {

    @Autowired
    private StockService stockService;

    /**
     * Deduct stock
     */
    @PostMapping("/deduct")
    public String deductStock(@RequestParam Long productId, @RequestParam Integer count) {
        try {
            stockService.deductStock(productId, count);
            return "Stock deducted successfully. Product ID: " + productId + ", Count: " + count;
        } catch (Exception e) {
            return "Stock deduction failed: " + e.getMessage();
        }
    }

    /**
     * Query stock
     */
    @GetMapping("/query/{productId}")
    public String queryStock(@PathVariable Long productId) {
        try {
            // Add query logic here if needed
            return "Stock query for product " + productId + " completed";
        } catch (Exception e) {
            return "Stock query failed: " + e.getMessage();
        }
    }

    /**
     * Test endpoint
     */
    @GetMapping("/test")
    public String test() {
        return "Stock Service Test Guide\n\n" +
               "Available endpoints:\n" +
               "1. POST /api/stock/deduct?productId=1&count=1 - Deduct stock\n" +
               "2. GET /api/stock/query/{productId} - Query stock\n\n" +
               "Database operations:\n" +
               "- Check stock table: SELECT * FROM stock;\n" +
               "- Monitor undo_log: SELECT * FROM undo_log;\n\n" +
               "Testing scenarios:\n" +
               "1. Normal deduction (sufficient stock)\n" +
               "2. Insufficient stock (should fail)\n" +
               "3. Concurrent deductions\n\n" +
               "Note:\n" +
               "- This service participates in Seata distributed transactions\n" +
               "- Stock deduction creates undo_log entries for rollback\n" +
               "- Failed transactions will trigger automatic rollback";
    }
}
