# Seata AT模式分布式事务Demo

这是一个基于Seata AT模式的分布式事务演示项目，展示了微服务架构下的事务一致性解决方案。

## 🎓 学习目标

通过这个Demo，你将学会：
1. **Seata AT模式的工作原理**：理解两阶段提交机制
2. **分布式事务的配置**：掌握Seata与Spring Boot的集成
3. **undo_log的作用**：了解自动回滚的实现机制
4. **异常处理与回滚**：观察分布式事务的回滚过程

## 项目架构

```
seata-demo/
├── order-service/          # 订单服务 (端口8080)
├── stock-service/          # 库存服务 (端口8081)
├── docker/                 # Docker配置
│   ├── init.sql            # 数据库初始化脚本
│   └── seata-server.conf   # Seata服务配置
├── docker-compose.yml      # Docker编排文件
└── README.md               # 使用说明
```

## 技术栈

- **Spring Boot**: 3.1.5
- **JDK**: 17
- **Seata**: 1.7.1 (AT模式)
- **数据库**: PostgreSQL 15
- **构建工具**: Maven
- **容器化**: Docker

## 业务场景

模拟电商下单场景：
1. **订单服务** 创建订单
2. **订单服务** 调用 **库存服务** 扣减库存
3. 当库存不足时触发 **Seata AT模式自动回滚**

## 🚀 快速开始

### 1. 启动服务

```bash
# 进入项目目录
cd seata-demo

# 启动所有服务 (PostgreSQL + Seata Server + 两个微服务)
docker-compose up -d

# 查看启动状态
docker-compose ps
```

### 2. 验证服务状态

```bash
# 检查订单服务
curl http://localhost:8080/api/order/test
# 应返回: Order Service is running!

# 检查库存服务
curl http://localhost:8081/api/stock/test
# 应返回: Stock Service is running!

# 查看库存状态
curl http://localhost:8081/api/stock/test/status
```

## 🎯 学习测试场景

### 📚 获取学习指南
```bash
curl http://localhost:8080/api/order/test/learning-guide
```

### 场景1：正常事务成功 ✅
```bash
# 库存充足，事务正常完成
curl -X POST http://localhost:8080/api/order/test/success

# 🔍 观察要点：
# - undo_log表会先插入记录，成功后自动删除
# - 订单状态从PENDING变为SUCCESS
# - 库存正常扣减
```

### 场景2：库存不足回滚 🔄
```bash
# 故意扣减超量库存，触发回滚
curl -X POST http://localhost:8080/api/order/test/rollback-insufficient-stock

# 🔍 观察要点：
# - 库存服务抛出异常
# - 全局事务自动回滚
# - 订单记录被删除（基于undo_log）
# - 库存数量保持不变
```

### 场景3：边界测试 ⚖️
```bash
# 精确扣减剩余库存
curl -X POST http://localhost:8080/api/order/test/boundary-test

# 🔍 观察要点：
# - 库存恰好变为0
# - 事务正常完成
# - 测试原子更新的准确性
```

### 场景4：验证结果 🔍
```bash
# 验证指定订单状态
curl http://localhost:8080/api/order/test/verify/{orderId}

# 查看当前库存
curl http://localhost:8081/api/stock/test/status
```

## 📊 数据库观察

连接PostgreSQL查看Seata AT模式的核心表：

```bash
# 连接数据库
docker exec -it seata-postgres psql -U postgres -d seata_demo

# 查看订单表
SELECT * FROM orders ORDER BY created_at DESC;

# 查看库存表
SELECT * FROM stock;

# 🔥 重点观察：Seata AT模式核心表
SELECT * FROM undo_log ORDER BY log_created DESC;
```

### undo_log表说明
- **事务开始时**：插入before image记录
- **事务成功时**：删除undo_log记录
- **事务回滚时**：基于undo_log生成反向SQL执行回滚

## 🔧 配置要点解析

### 关键配置1：数据库连接
```yaml
# ⚠️ 重要：分布式事务必须关闭自动提交
auto-commit: false
```

### 关键配置2：事务组
```yaml
seata:
  tx-service-group: seata_demo_tx_group  # 两个服务必须使用相同事务组
```

### 关键配置3：全局事务注解
```java
@GlobalTransactional(rollbackFor = Exception.class, timeoutMills = 30000)
```

## 📈 进阶学习

### 并发测试
```bash
# 模拟并发扣减库存
curl http://localhost:8081/api/stock/test/concurrency-guide
```

### 性能监控
- 观察undo_log表大小变化
- 监控事务处理时间
- 分析回滚频率和原因

### 对比学习
- **AT模式** vs **TCC模式**：业务侵入性对比
- **XA协议** vs **AT模式**：性能差异分析
- **本地事务** vs **分布式事务**：一致性保证对比

## 🎯 学习检查清单

- [ ] 理解@GlobalTransactional注解的作用
- [ ] 观察到undo_log表的插入和删除
- [ ] 成功触发分布式事务回滚
- [ ] 验证数据最终一致性
- [ ] 理解两阶段提交的完整流程
- [ ] 掌握异常如何影响全局事务
- [ ] 了解AT模式的优缺点

## 🔍 故障排除

### 1. 服务启动失败
- 检查端口占用: `docker-compose ps`
- 查看日志: `docker-compose logs [service_name]`

### 2. Seata连接失败
- 确认seata-server容器正常运行
- 检查事务组配置是否一致

### 3. 事务不回滚
- 确认`auto-commit: false`配置
- 检查异常是否被正确抛出
- 验证@GlobalTransactional注解

### 4. undo_log表异常
- 检查表结构是否正确创建
- 确认Seata版本兼容性

## 📚 深入学习资源

1. **Seata官方文档**：[https://seata.io/zh-cn/docs/overview/what-is-seata.html](https://seata.io/zh-cn/docs/overview/what-is-seata.html)
2. **AT模式详解**：理解Seata如何实现自动回滚
3. **分布式事务理论**：CAP定理、BASE理论
4. **微服务事务模式**：Saga、TCC、AT模式对比

## 停止服务

```bash
# 停止所有服务
docker-compose down

# 停止服务并删除数据卷
docker-compose down -v
```

---

🎉 **Happy Learning!** 通过这个Demo，你已经掌握了Seata AT模式的核心概念和实际应用！