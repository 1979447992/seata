# Seata Oracle 分布式事务演示项目

## 📋 项目简介

这是一个基于 Seata AT 模式的分布式事务演示项目，使用 Oracle 数据库进行事务管理。项目包含订单服务（order-service）和库存服务（stock-service）两个微服务，演示分布式事务的提交和回滚机制。

## 🏗️ 项目架构

```
seata-demo/
├── order-service/          # 订单服务
├── stock-service/          # 库存服务
├── docker/                 # Docker配置和脚本
├── docker-compose.yml      # 容器编排配置
├── seata_init.sql          # Oracle数据库初始化脚本
└── README.md              # 项目说明文档
```

## 🛠️ 技术栈

- **Spring Boot**: 2.7.17
- **Spring Cloud**: 2021.0.8
- **Seata**: 1.7.1
- **Oracle Database**: 21c Express Edition
- **MyBatis Plus**: 3.5.4
- **Maven**: 项目管理工具

## 🚀 本地开发环境配置

### 1. 前置条件

- JDK 11+
- IntelliJ IDEA 2025 社区版
- Maven 3.6+
- Navicat 或其他 Oracle 数据库客户端

### 2. IDEA 运行配置

#### 2.1 配置 order-service

1. **打开 Run Configuration**：
   - 点击 **Run** → **Edit Configurations...**
   - 点击 **+** → 选择 **Application**

2. **Basic Settings**：
   - **Name**: `OrderService-Local`
   - **Main class**: `com.example.order.OrderServiceApplication`
   - **Working directory**: `C:\Users\quan\Desktop\seata\seata-demo\order-service`
   - **Use classpath of module**: 选择 `order-service`

3. **VM Options**:
   ```
   -Dspring.profiles.active=local
   ```

4. **Program Arguments**: (留空)

#### 2.2 配置 stock-service

重复上述步骤，创建另一个配置：

- **Name**: `StockService-Local`
- **Main class**: `com.example.stock.StockServiceApplication`
- **Working directory**: `C:\Users\quan\Desktop\seata\seata-demo\stock-service`
- **Use classpath of module**: 选择 `stock-service`
- **VM Options**: `-Dspring.profiles.active=local`

#### 2.3 应用和保存

1. 点击 **Apply**
2. 点击 **OK**

### 3. 启动顺序

1. **先启动 stock-service** (端口 8081)
2. **再启动 order-service** (端口 8080)

## 🗄️ 数据库配置

### Oracle 连接信息

- **主机**: `47.86.4.117`
- **端口**: `1521`
- **服务名**: `XEPDB1`
- **用户名**: `seata_user`
- **密码**: `seata_pass`

### Navicat 连接配置

1. 创建新连接
2. 选择 **Oracle**
3. 填入上述连接信息
4. 连接类型选择 **Service Name**

## 📊 数据库表结构

### 业务表

- `t_order` - 订单表
- `t_stock` - 库存表

### Seata 事务表

- `global_table` - 全局事务表
- `branch_table` - 分支事务表
- `lock_table` - 分布式锁表
- `undo_log` - AT模式回滚日志表

## 🧪 测试接口

### 1. 创建订单（完整流程）

```bash
POST http://localhost:8080/api/order/create
Content-Type: application/json

{
  "userId": "user123",
  "productId": 1,
  "count": 2
}
```

### 2. 调试接口（分步观察事务）

```bash
POST http://localhost:8080/order/debug/step-by-step?userId=user123&productId=1&count=2&step=1
```

支持的步骤参数：
- `step=1` - 查看当前库存
- `step=2` - 创建订单记录
- `step=3` - 扣减库存
- `step=4` - 完成事务提交
- `step=5` - 查看最终状态

### 3. 库存相关接口

```bash
# 扣减库存
POST http://localhost:8081/api/stock/deduct?productId=1&quantity=2

# 查询库存
GET http://localhost:8081/api/stock/1

# 健康检查
GET http://localhost:8081/api/stock/test
```

## 🔍 分布式事务监控

### 在 Navicat 中监控事务状态

实时刷新以下表观察事务变化：

1. **global_table** - 查看全局事务状态
   ```sql
   SELECT xid, status, application_id, transaction_name, gmt_create FROM global_table ORDER BY gmt_create DESC;
   ```

2. **branch_table** - 查看分支事务状态
   ```sql
   SELECT branch_id, xid, resource_id, status, gmt_create FROM branch_table ORDER BY gmt_create DESC;
   ```

3. **undo_log** - 查看回滚日志
   ```sql
   SELECT branch_id, xid, context, log_status, log_created FROM undo_log ORDER BY log_created DESC;
   ```

4. **业务表变化**
   ```sql
   SELECT * FROM t_order ORDER BY create_time DESC;
   SELECT * FROM t_stock WHERE product_id = 1;
   ```

## 🚨 常见问题

### 1. 启动失败

- 确认 Oracle 数据库连接正常
- 检查远程 Seata 服务器状态 (47.86.4.117:8091)
- 验证 VM Options 中的 `-Dspring.profiles.active=local` 配置

### 2. 事务回滚测试

模拟库存不足场景：
```bash
POST http://localhost:8080/api/order/create
{
  "userId": "user123",
  "productId": 1,
  "count": 9999
}
```

观察：
- global_table 中事务状态变为回滚
- undo_log 中的回滚记录
- 业务表数据保持一致性

### 3. 并发测试

使用 JMeter 或 Postman 发送并发请求，观察：
- lock_table 中的锁记录
- 事务的排队和执行情况
- 数据最终一致性

## 📈 性能调优建议

1. **数据库连接池配置**
   - 调整 `hikari.maximum-pool-size`
   - 优化 `connection-timeout`

2. **Seata 配置优化**
   - 调整事务超时时间
   - 优化批量操作大小

3. **监控指标**
   - 事务成功率
   - 平均响应时间
   - 数据库连接池使用率

## 🔗 相关资源

- [Seata 官方文档](https://seata.io/zh-cn/)
- [Spring Cloud Alibaba](https://spring-cloud-alibaba-group.github.io/)
- [Oracle Database Documentation](https://docs.oracle.com/en/database/)

## 📝 更新日志

- **v1.0.0** - 初始版本，支持 Oracle 数据库的 Seata AT 模式演示
- **v1.1.0** - 添加分步调试接口，优化事务监控体验

---

🎯 **学习目标**: 通过本项目掌握 Seata 分布式事务在 Oracle 环境下的实际应用，理解 AT 模式的工作原理和最佳实践。
