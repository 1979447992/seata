package com.example.order.entity;

import com.baomidou.mybatisplus.annotation.*;

@TableName("orders")
public class Order {
    
    @TableId(value = "ID", type = IdType.NONE)
    private Long id;
    
    @TableField("USER_ID")
    private String userId;
    
    @TableField("PRODUCT_ID")
    private Long productId;
    
    @TableField("QUANTITY")
    private Integer quantity;
    
    @TableField("STATUS")
    private String status;
    
    public Order() {}
    
    public Order(String userId, Long productId, Integer quantity, String status) {
        this.userId = userId;
        this.productId = productId;
        this.quantity = quantity;
        this.status = status;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public Long getProductId() {
        return productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}