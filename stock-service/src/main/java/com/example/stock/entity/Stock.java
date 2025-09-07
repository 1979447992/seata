package com.example.stock.entity;

import com.baomidou.mybatisplus.annotation.*;

@TableName("stock")
public class Stock {
    
    @TableId(value = "ID", type = IdType.NONE)
    private Long id;
    
    @TableField("PRODUCT_ID")
    private Long productId;
    
    @TableField("TOTAL")
    private Integer total;
    
    @TableField("RESIDUE")
    private Integer residue;
    
    
    
    public Stock() {}
    
    public Stock(Long productId, Integer total) {
        this.productId = productId;
        this.total = total;
        this.residue = total; // 初始时剩余量等于总量
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getProductId() {
        return productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public Integer getTotal() {
        return total;
    }

    public void setTotal(Integer total) {
        this.total = total;
    }

    public Integer getResidue() {
        return residue;
    }

    public void setResidue(Integer residue) {
        this.residue = residue;
    }
}