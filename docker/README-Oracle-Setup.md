# Oracle版Seata AT模式学习环境

## 📋 数据库初始化

### 方式一：使用完整脚本（推荐）
```bash
# 在Oracle数据库工具中执行
docker/oracle-seata-complete.sql
```

### 方式二：手动连接执行
**连接信息：**
- 主机: 47.86.4.117
- 端口: 1521  
- 数据库: XEPDB1
- 用户: seata_user
- 密码: seata_pass

## 🗃️ 表结构说明

### 业务表
- `orders` - 订单表
- `stock` - 库存表（包含测试数据）

### Seata AT模式核心表
- `global_table` - 全局事务表
- `branch_table` - 分支事务表  
- `lock_table` - 分布式锁表
- `undo_log` - AT模式回滚日志表

## 🚀 服务启动

执行完SQL脚本后，重启Seata服务器：
```bash
docker-compose restart seata-server
```

## 📊 访问端口

- **Seata Server**: http://47.86.4.117:8091
- **Seata Console**: http://47.86.4.117:7091  
- **Oracle数据库**: 47.86.4.117:1521/XEPDB1
- **Oracle EM**: http://47.86.4.117:5500/em/

## 🎯 学习目标

通过Oracle版本学习Seata AT模式：
1. 观察`undo_log`表的记录变化
2. 理解分布式事务的两阶段提交
3. 测试事务回滚机制
4. 对比Oracle与PostgreSQL的差异

## 📚 测试建议

1. 正常事务提交流程
2. 异常事务回滚流程  
3. 观察各个表的数据变化
4. 学习AT模式的工作原理
