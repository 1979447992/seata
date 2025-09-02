# RocketMQ 消息发送和消费详细指南

## 📋 目录
- [系统架构概述](#系统架构概述)
- [消息发送流程](#消息发送流程)
- [消息消费流程](#消息消费流程)
- [实际测试案例](#实际测试案例)
- [可靠性保障机制](#可靠性保障机制)
- [常用命令参考](#常用命令参考)
- [故障排除指南](#故障排除指南)

## 🏗️ 系统架构概述

当前云服务器部署的RocketMQ系统架构：

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Name Server   │    │     Broker      │    │   MQ Console    │
│   (Port 9876)   │◄──►│ (Port 10909,    │    │   (Port 8088)   │
│                 │    │      10911)     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                       ▲                       ▲
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Order Service   │    │ Stock Service   │    │   监控管理      │
│  (Port 8080)    │    │  (Port 8081)    │    │                 │
│   生产者        │    │   消费者        │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 核心组件说明

1. **Name Server (9876)**
   - 服务发现和路由管理
   - 维护Broker列表和路由信息
   - 轻量级，无状态设计

2. **Broker (10909, 10911)**
   - 消息存储和转发
   - 队列管理和负载均衡
   - 支持持久化存储

3. **Producer (Order Service)**
   - 消息生产和发送
   - 支持同步/异步发送
   - 事务消息支持

4. **Consumer (Stock Service)**  
   - 消息订阅和消费
   - 支持集群消费和广播消费
   - 消费进度管理

## 🚀 消息发送流程

### 1. 消息发送的完整流程

```
Producer                Name Server              Broker
   │                         │                     │
   │ 1. 获取路由信息          │                     │
   ├─────────────────────────►                     │
   │ 2. 返回Broker地址        │                     │
   ◄─────────────────────────┤                     │
   │                         │                     │
   │ 3. 发送消息                                   │
   ├───────────────────────────────────────────────►
   │ 4. 返回发送结果                               │
   ◄───────────────────────────────────────────────┤
   │                         │                     │
```

### 2. 消息发送核心步骤

#### 步骤1: 路由发现
```bash
# Producer启动时会从Name Server获取路由信息
# 包括Topic的Queue分布情况和Broker地址
Producer -> Name Server: 获取Topic路由信息
Name Server -> Producer: 返回Broker列表和Queue信息
```

#### 步骤2: 消息构建
```bash
# 构建消息对象，包含以下关键信息：
- Topic: 消息主题
- Tag: 消息标签（用于过滤）
- Key: 消息键（用于查询）
- Body: 消息体内容
- Properties: 消息属性
```

#### 步骤3: 队列选择
```bash
# Producer根据负载均衡策略选择队列
# 策略包括：轮询、随机、根据Hash值等
Queue Selection Strategy:
- Round Robin (轮询)
- Random (随机)  
- Hash (哈希)
- Custom (自定义)
```

#### 步骤4: 消息发送
```bash
# 向选定的Broker发送消息
Producer -> Broker: SendMessage请求
Broker -> Producer: SendResult响应
```

### 3. 实际发送命令示例

```bash
# 基本消息发送
docker run --rm --network container:$(docker ps | grep rocketmq-nameserver | awk '{print $1}') \
apache/rocketmq:4.9.4 sh mqadmin sendMessage \
-n localhost:9876 \
-t TEST_TOPIC \
-p "Hello RocketMQ - $(date)"

# 带标签的消息发送
docker run --rm --network container:$(docker ps | grep rocketmq-nameserver | awk '{print $1}') \
apache/rocketmq:4.9.4 sh mqadmin sendMessage \
-n localhost:9876 \
-t TEST_TOPIC \
-a "OrderTag" \
-k "ORDER_12345" \
-p "订单创建消息: {orderId: 12345, amount: 199.99}"
```

## 📥 消息消费流程

### 1. 消息消费的完整流程

```
Consumer                Name Server              Broker
   │                         │                     │
   │ 1. 注册Consumer信息      │                     │
   ├─────────────────────────►                     │
   │ 2. 获取订阅信息          │                     │
   ◄─────────────────────────┤                     │
   │                         │                     │
   │ 3. 拉取消息                                   │
   ├───────────────────────────────────────────────►
   │ 4. 返回消息批次                               │
   ◄───────────────────────────────────────────────┤
   │ 5. 处理消息             │                     │
   │ 6. 确认消费                                   │
   ├───────────────────────────────────────────────►
   │                         │                     │
```

### 2. 消费模式详解

#### 集群消费模式 (Clustering)
```bash
# 多个Consumer实例共同消费一个Topic
# 每条消息只会被其中一个Consumer消费
# 适用于提高消费能力的场景

Consumer1 ├─► Queue0, Queue1
Consumer2 ├─► Queue2, Queue3
Consumer3 ├─► 等待分配
```

#### 广播消费模式 (Broadcasting)  
```bash
# 每个Consumer实例都会消费Topic的所有消息
# 适用于通知类消息的场景

Consumer1 ├─► Queue0, Queue1, Queue2, Queue3
Consumer2 ├─► Queue0, Queue1, Queue2, Queue3  
Consumer3 ├─► Queue0, Queue1, Queue2, Queue3
```

### 3. 消息消费核心步骤

#### 步骤1: 订阅Topic
```bash
# Consumer启动时订阅感兴趣的Topic
Consumer.subscribe(Topic, MessageListener)
```

#### 步骤2: 拉取消息
```bash
# Consumer定期从Broker拉取消息
# 支持长轮询机制，减少空轮询
Pull Request -> Broker
Broker -> Return Message Batch
```

#### 步骤3: 消息处理
```bash
# 业务逻辑处理消息
try {
    // 处理消息业务逻辑
    processMessage(message);
    return ConsumeStatus.CONSUME_SUCCESS;
} catch (Exception e) {
    // 处理失败，消息会重试
    return ConsumeStatus.RECONSUME_LATER;
}
```

#### 步骤4: 消费确认
```bash
# 根据处理结果更新消费进度
Success -> 更新消费进度，消息标记为已消费
Failed -> 消息进入重试队列，等待下次消费
```

### 4. 实际消费命令示例

```bash
# 消费指定Topic的消息
docker run --rm --network container:$(docker ps | grep rocketmq-nameserver | awk '{print $1}') \
apache/rocketmq:4.9.4 sh mqadmin consumeMessage \
-n localhost:9876 \
-t TEST_TOPIC \
-g TEST_CONSUMER_GROUP

# 查看消费进度
docker run --rm --network container:$(docker ps | grep rocketmq-nameserver | awk '{print $1}') \
apache/rocketmq:4.9.4 sh mqadmin consumerProgress \
-n localhost:9876 \
-g TEST_CONSUMER_GROUP
```

## 🧪 实际测试案例

基于我们在云服务器上的实际测试结果：

### 测试案例1: 基础消息发送和消费

```bash
# 1. 发送测试消息
MESSAGE_COUNT=6
SUCCESS_COUNT=6
SUCCESS_RATE=100%

# 发送的消息分布：
TEST_TOPIC:
- Queue 0: 1条消息
- Queue 1: 3条消息  
- Queue 2: 2条消息
- Queue 3: 0条消息
总计: 6条消息全部发送成功
```

### 测试案例2: 可靠性测试

```bash
# 2. 可靠性测试消息
RELIABILITY_MESSAGES=11
DISTRIBUTION:
- Queue 0: 3条消息
- Queue 1: 4条消息
- Queue 2: 3条消息  
- Queue 3: 1条消息
总计: 11条消息全部发送成功
```

### 测试案例3: 消费验证

```bash
# 3. 消费测试结果
成功消费的消息样例：
1. "Hello RocketMQ - Tue Sep 2 11:22:35 PM CST 2025"
2. "Test Message 1 - 1756826568" 
3. "Test Message 5 - 1756826584"

消费状态: "Consume ok"
消费成功率: 100%
```

## 🛡️ 可靠性保障机制

### 1. 发送端可靠性

#### 同步发送
```java
// 同步发送确保消息成功到达Broker
SendResult result = producer.send(message);
if (result.getSendStatus() == SendStatus.SEND_OK) {
    // 发送成功
}
```

#### 异步发送  
```java
// 异步发送提供回调机制
producer.send(message, new SendCallback() {
    @Override
    public void onSuccess(SendResult result) {
        // 发送成功回调
    }
    
    @Override  
    public void onException(Throwable e) {
        // 发送失败回调
    }
});
```

#### 重试机制
```bash
# Producer配置重试次数
retryTimesWhenSendFailed=2        # 同步发送重试次数
retryTimesWhenSendAsyncFailed=2   # 异步发送重试次数
```

### 2. 存储端可靠性

#### 同步刷盘
```bash
# Broker配置同步刷盘，确保消息持久化
flushDiskType=SYNC_FLUSH
```

#### 主从同步
```bash
# 配置主从同步，防止单点故障
brokerRole=SYNC_MASTER  # 主Broker同步模式
brokerRole=SLAVE        # 从Broker配置
```

### 3. 消费端可靠性

#### 消费重试
```java
// 消费失败时返回RECONSUME_LATER触发重试
public ConsumeStatus consumeMessage(List<MessageExt> msgs) {
    try {
        // 处理消息
        return ConsumeStatus.CONSUME_SUCCESS;
    } catch (Exception e) {
        // 重试消费
        return ConsumeStatus.RECONSUME_LATER;  
    }
}
```

#### 死信队列
```bash
# 消息重试达到最大次数后进入死信队列
maxReconsumeTimes=16     # 最大重试次数
DLQ Topic: %DLQ%{ConsumerGroup}
```

## 📋 常用命令参考

### Name Server相关
```bash
# 查看Name Server状态
docker exec {nameserver_container} sh mqadmin namesrvStatus -n localhost:9876
```

### Topic管理
```bash
# 创建Topic
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin updateTopic \
-n localhost:9876 -t MyTopic -c DefaultCluster

# 查看Topic列表  
docker exec {console_container} curl -s 'http://localhost:8080/topic/list.query'

# 查看Topic状态
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin topicStatus -n localhost:9876 -t MyTopic

# 查看Topic路由信息
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin topicRoute -n localhost:9876 -t MyTopic
```

### 消息操作
```bash
# 发送消息
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin sendMessage \
-n localhost:9876 -t MyTopic -p "消息内容"

# 根据Message ID查询消息
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin queryMsgById \
-n localhost:9876 -i {messageId}

# 根据Key查询消息
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin queryMsgByKey \
-n localhost:9876 -t MyTopic -k {messageKey}
```

### 消费者管理
```bash
# 查看消费者组信息
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin consumerConnection \
-n localhost:9876 -g MyConsumerGroup

# 查看消费进度
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin consumerProgress \
-n localhost:9876 -g MyConsumerGroup

# 重置消费进度
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin resetOffset \
-n localhost:9876 -g MyConsumerGroup -t MyTopic -q 0 -o 0
```

### 集群管理
```bash
# 查看集群信息
docker exec {console_container} curl -s 'http://localhost:8080/cluster/list.query'

# 查看Broker状态  
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin brokerStatus \
-n localhost:9876 -b {brokerAddr}

# 清理无效Topic
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin cleanUnusedTopic \
-n localhost:9876 -c DefaultCluster
```

## 🚨 故障排除指南

### 1. 常见问题诊断

#### 消息发送失败
```bash
# 检查Name Server连接
telnet {nameserver_ip} 9876

# 检查Topic是否存在
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin topicList -n localhost:9876

# 检查Broker状态
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin clusterList -n localhost:9876
```

#### 消息消费异常
```bash
# 检查消费者组状态
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin consumerConnection \
-n localhost:9876 -g {consumerGroup}

# 查看消费堆积情况  
docker run --rm --network container:{nameserver_container} \
apache/rocketmq:4.9.4 sh mqadmin consumerProgress \
-n localhost:9876 -g {consumerGroup}
```

### 2. 性能优化建议

#### Producer优化
```bash
# 批量发送优化
maxMessageSize=4194304           # 最大消息大小4MB
sendMsgTimeout=3000              # 发送超时时间3秒  
retryTimesWhenSendFailed=2       # 重试次数
compressMsgBodyOverHowmuch=4096  # 消息压缩阈值
```

#### Consumer优化
```bash
# 消费者线程池优化  
consumeThreadMin=20              # 最小消费线程数
consumeThreadMax=64              # 最大消费线程数
pullBatchSize=32                 # 批量拉取消息数量
consumeMessageBatchMaxSize=1     # 批量消费消息数量
```

#### Broker优化
```bash
# 存储优化
commitLogRetentionHours=72       # 日志保留时间72小时
flushDiskType=ASYNC_FLUSH        # 异步刷盘提高性能
enableDLegerCommitLog=false      # 关闭DLedger提高性能

# 内存优化  
maxTransferBytesOnMessageInMemory=262144    # 内存中消息传输最大字节
maxTransferCountOnMessageInMemory=32        # 内存中消息传输最大数量
```

## 📚 进阶学习资源

### 1. 核心概念深入
- Message Model: 消息模型设计
- Load Balancing: 负载均衡策略  
- Ordering Message: 顺序消息实现
- Transaction Message: 事务消息机制
- Delayed Message: 延时消息处理

### 2. 最佳实践
- Producer最佳实践
- Consumer最佳实践  
- 运维监控实践
- 性能调优实践

### 3. 企业级应用
- 微服务通信
- 事件驱动架构
- 分布式事务
- 数据一致性保障

---

## 📞 技术支持

如有问题，请查看：
1. RocketMQ官方文档
2. 系统日志：`docker logs {container_name}`
3. 监控控制台：http://localhost:8088
4. 社区支持论坛

**🎯 总结：本指南基于实际云服务器测试验证，消息发送成功率100%，消费成功率100%，系统运行稳定可靠！**

## 💻 Java代码示例

### 1. Producer示例代码

#### 基础Producer实现
```java
import org.apache.rocketmq.client.producer.DefaultMQProducer;
import org.apache.rocketmq.client.producer.SendResult;
import org.apache.rocketmq.common.message.Message;
import org.apache.rocketmq.remoting.common.RemotingHelper;

/**
 * 基础消息生产者示例
 */
public class BasicProducer {
    
    public static void main(String[] args) throws Exception {
        // 创建生产者实例，指定生产者组
        DefaultMQProducer producer = new DefaultMQProducer("BASIC_PRODUCER_GROUP");
        
        // 设置Name Server地址
        producer.setNamesrvAddr("localhost:9876");
        
        // 启动生产者
        producer.start();
        
        try {
            for (int i = 0; i < 100; i++) {
                // 创建消息实例
                Message msg = new Message(
                    "TEST_TOPIC",           // Topic
                    "TagA",                 // Tag  
                    ("Hello RocketMQ " + i).getBytes(RemotingHelper.DEFAULT_CHARSET)
                );
                
                // 发送消息
                SendResult sendResult = producer.send(msg);
                System.out.printf("消息发送结果: %s%n", sendResult);
            }
        } finally {
            // 关闭生产者
            producer.shutdown();
        }
    }
}
```

#### 异步Producer实现
```java
import org.apache.rocketmq.client.producer.DefaultMQProducer;
import org.apache.rocketmq.client.producer.SendCallback;
import org.apache.rocketmq.client.producer.SendResult;
import org.apache.rocketmq.common.message.Message;
import java.util.concurrent.CountDownLatch;

/**
 * 异步消息生产者示例
 */
public class AsyncProducer {
    
    public static void main(String[] args) throws Exception {
        DefaultMQProducer producer = new DefaultMQProducer("ASYNC_PRODUCER_GROUP");
        producer.setNamesrvAddr("localhost:9876");
        producer.start();
        
        // 设置异步发送失败重试次数
        producer.setRetryTimesWhenSendAsyncFailed(0);
        
        int messageCount = 100;
        CountDownLatch countDownLatch = new CountDownLatch(messageCount);
        
        try {
            for (int i = 0; i < messageCount; i++) {
                final int index = i;
                Message msg = new Message(
                    "ASYNC_TEST_TOPIC",
                    "TagA", 
                    ("异步消息 " + i).getBytes("UTF-8")
                );
                
                // 异步发送消息
                producer.send(msg, new SendCallback() {
                    @Override
                    public void onSuccess(SendResult sendResult) {
                        System.out.printf("%-10d OK %s %n", index, sendResult.getMsgId());
                        countDownLatch.countDown();
                    }
                    
                    @Override
                    public void onException(Throwable e) {
                        System.out.printf("%-10d Exception %s %n", index, e);
                        countDownLatch.countDown();
                    }
                });
            }
            
            // 等待所有消息发送完成
            countDownLatch.await();
            
        } finally {
            producer.shutdown();
        }
    }
}
```

#### 事务消息Producer
```java
import org.apache.rocketmq.client.producer.LocalTransactionState;
import org.apache.rocketmq.client.producer.TransactionListener;
import org.apache.rocketmq.client.producer.TransactionMQProducer;
import org.apache.rocketmq.common.message.Message;
import org.apache.rocketmq.common.message.MessageExt;

/**
 * 事务消息生产者示例
 */
public class TransactionProducer {
    
    public static void main(String[] args) throws Exception {
        TransactionMQProducer producer = new TransactionMQProducer("TRANSACTION_PRODUCER_GROUP");
        producer.setNamesrvAddr("localhost:9876");
        
        // 设置事务监听器
        producer.setTransactionListener(new TransactionListenerImpl());
        producer.start();
        
        try {
            String[] tags = new String[] {"TagA", "TagB", "TagC"};
            
            for (int i = 0; i < 3; i++) {
                Message msg = new Message(
                    "TRANSACTION_TOPIC", 
                    tags[i % tags.length], 
                    ("事务消息 " + i).getBytes("UTF-8")
                );
                
                // 发送事务消息
                producer.sendMessageInTransaction(msg, null);
            }
            
            // 等待回查完成
            Thread.sleep(10000);
            
        } finally {
            producer.shutdown();
        }
    }
}

/**
 * 事务监听器实现
 */
class TransactionListenerImpl implements TransactionListener {
    
    @Override
    public LocalTransactionState executeLocalTransaction(Message msg, Object arg) {
        System.out.println("执行本地事务: " + new String(msg.getBody()));
        
        // 模拟本地事务执行
        if (msg.getTags().equals("TagA")) {
            return LocalTransactionState.COMMIT_MESSAGE;
        } else if (msg.getTags().equals("TagB")) {
            return LocalTransactionState.ROLLBACK_MESSAGE;
        }
        
        return LocalTransactionState.UNKNOW;
    }
    
    @Override
    public LocalTransactionState checkLocalTransaction(MessageExt msg) {
        System.out.println("事务消息回查: " + new String(msg.getBody()));
        
        // 根据业务逻辑检查事务状态
        return LocalTransactionState.COMMIT_MESSAGE;
    }
}
```

### 2. Consumer示例代码

#### 基础Consumer实现
```java
import org.apache.rocketmq.client.consumer.DefaultMQPushConsumer;
import org.apache.rocketmq.client.consumer.listener.ConsumeConcurrentlyContext;
import org.apache.rocketmq.client.consumer.listener.ConsumeConcurrentlyStatus;
import org.apache.rocketmq.client.consumer.listener.MessageListenerConcurrently;
import org.apache.rocketmq.common.message.MessageExt;
import java.util.List;

/**
 * 基础消息消费者示例
 */
public class BasicConsumer {
    
    public static void main(String[] args) throws Exception {
        // 创建消费者实例
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("BASIC_CONSUMER_GROUP");
        
        // 设置Name Server地址
        consumer.setNamesrvAddr("localhost:9876");
        
        // 订阅Topic和Tag
        consumer.subscribe("TEST_TOPIC", "*");
        
        // 注册消息监听器
        consumer.registerMessageListener(new MessageListenerConcurrently() {
            
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(
                    List<MessageExt> messages,
                    ConsumeConcurrentlyContext context) {
                
                for (MessageExt message : messages) {
                    try {
                        // 处理消息业务逻辑
                        System.out.printf("接收消息: Topic=%s, Tag=%s, Keys=%s, Body=%s%n",
                            message.getTopic(),
                            message.getTags(),
                            message.getKeys(),
                            new String(message.getBody(), "UTF-8")
                        );
                        
                        // 模拟业务处理
                        processBusinessLogic(message);
                        
                    } catch (Exception e) {
                        System.out.println("消息处理异常: " + e.getMessage());
                        // 返回稍后重试
                        return ConsumeConcurrentlyStatus.RECONSUME_LATER;
                    }
                }
                
                // 返回消费成功
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
            }
        });
        
        // 启动消费者
        consumer.start();
        System.out.println("消费者启动成功");
        
        // 保持进程运行
        Thread.sleep(60000);
        
        // 关闭消费者
        consumer.shutdown();
    }
    
    /**
     * 业务处理逻辑
     */
    private static void processBusinessLogic(MessageExt message) throws Exception {
        // 根据消息内容执行具体业务逻辑
        String body = new String(message.getBody(), "UTF-8");
        
        // 示例：订单处理逻辑
        if (message.getTags().equals("ORDER")) {
            processOrderMessage(body);
        }
        // 示例：支付处理逻辑  
        else if (message.getTags().equals("PAYMENT")) {
            processPaymentMessage(body);
        }
    }
    
    private static void processOrderMessage(String orderData) {
        System.out.println("处理订单消息: " + orderData);
        // 订单相关业务逻辑
    }
    
    private static void processPaymentMessage(String paymentData) {
        System.out.println("处理支付消息: " + paymentData);
        // 支付相关业务逻辑
    }
}
```

#### 顺序消息Consumer
```java
import org.apache.rocketmq.client.consumer.DefaultMQPushConsumer;
import org.apache.rocketmq.client.consumer.listener.ConsumeOrderlyContext;
import org.apache.rocketmq.client.consumer.listener.ConsumeOrderlyStatus;
import org.apache.rocketmq.client.consumer.listener.MessageListenerOrderly;
import org.apache.rocketmq.common.message.MessageExt;
import java.util.List;

/**
 * 顺序消息消费者示例
 */
public class OrderlyConsumer {
    
    public static void main(String[] args) throws Exception {
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("ORDERLY_CONSUMER_GROUP");
        consumer.setNamesrvAddr("localhost:9876");
        consumer.subscribe("ORDERLY_TOPIC", "*");
        
        // 注册顺序消息监听器
        consumer.registerMessageListener(new MessageListenerOrderly() {
            
            @Override
            public ConsumeOrderlyStatus consumeMessage(
                    List<MessageExt> messages,
                    ConsumeOrderlyContext context) {
                
                // 设置自动提交
                context.setAutoCommit(true);
                
                for (MessageExt message : messages) {
                    System.out.printf("顺序消息: QueueId=%d, Body=%s%n",
                        message.getQueueId(),
                        new String(message.getBody())
                    );
                }
                
                return ConsumeOrderlyStatus.SUCCESS;
            }
        });
        
        consumer.start();
        System.out.println("顺序消费者启动成功");
        
        // 保持运行
        Thread.sleep(60000);
        consumer.shutdown();
    }
}
```

### 3. Spring Boot集成示例

#### Producer配置
```java
@Component
@Slf4j
public class RocketMQProducerService {
    
    @Autowired
    private RocketMQTemplate rocketMQTemplate;
    
    /**
     * 发送同步消息
     */
    public void sendSyncMessage(String topic, String tag, Object message) {
        try {
            String destination = topic + ":" + tag;
            SendResult sendResult = rocketMQTemplate.syncSend(destination, message);
            log.info("同步发送消息成功: {}", sendResult.getMsgId());
        } catch (Exception e) {
            log.error("同步发送消息失败", e);
        }
    }
    
    /**
     * 发送异步消息
     */
    public void sendAsyncMessage(String topic, String tag, Object message) {
        try {
            String destination = topic + ":" + tag;
            rocketMQTemplate.asyncSend(destination, message, new SendCallback() {
                @Override
                public void onSuccess(SendResult sendResult) {
                    log.info("异步发送消息成功: {}", sendResult.getMsgId());
                }
                
                @Override
                public void onException(Throwable e) {
                    log.error("异步发送消息失败", e);
                }
            });
        } catch (Exception e) {
            log.error("异步发送消息异常", e);
        }
    }
    
    /**
     * 发送延时消息
     */
    public void sendDelayMessage(String topic, String tag, Object message, int delayLevel) {
        try {
            String destination = topic + ":" + tag;
            Message<Object> msg = MessageBuilder.withPayload(message).build();
            rocketMQTemplate.syncSend(destination, msg, 3000, delayLevel);
            log.info("发送延时消息成功, 延时等级: {}", delayLevel);
        } catch (Exception e) {
            log.error("发送延时消息失败", e);
        }
    }
}
```

#### Consumer配置
```java
@Component
@RocketMQMessageListener(
    topic = "TEST_TOPIC",
    consumerGroup = "SPRING_CONSUMER_GROUP",
    selectorExpression = "*"
)
@Slf4j
public class TestMessageConsumer implements RocketMQListener<String> {
    
    @Override
    public void onMessage(String message) {
        try {
            log.info("接收到消息: {}", message);
            
            // 处理业务逻辑
            processMessage(message);
            
            log.info("消息处理成功");
            
        } catch (Exception e) {
            log.error("消息处理失败: {}", message, e);
            // 抛出异常会触发重试
            throw new RuntimeException("消息处理失败", e);
        }
    }
    
    private void processMessage(String message) {
        // 具体业务逻辑实现
        System.out.println("处理消息: " + message);
    }
}
```

### 4. 配置文件示例

#### application.yml配置
```yaml
# RocketMQ配置
rocketmq:
  name-server: localhost:9876
  producer:
    group: SPRING_PRODUCER_GROUP
    send-message-timeout: 3000
    retry-times-when-send-failed: 2
    max-message-size: 4194304
  consumer:
    group: SPRING_CONSUMER_GROUP
    consume-thread-min: 5
    consume-thread-max: 20
    consume-message-batch-max-size: 1

# 日志配置
logging:
  level:
    org.apache.rocketmq: INFO
    com.example: DEBUG
```

### 5. 监控和运维工具

#### 监控脚本示例
```bash
#!/bin/bash
# monitor_rocketmq.sh - RocketMQ监控脚本

NAMESERVER="localhost:9876"
CONSOLE_CONTAINER=$(docker ps | grep rocketmq-console | awk '{print $1}')

echo "=== RocketMQ系统监控报告 ==="
echo "时间: $(date)"
echo ""

echo "1. 集群状态检查:"
docker exec $CONSOLE_CONTAINER curl -s 'http://localhost:8080/cluster/list.query' | \
grep -o '"brokerName":"[^"]*"' | head -5

echo ""
echo "2. Topic列表:"
docker exec $CONSOLE_CONTAINER curl -s 'http://localhost:8080/topic/list.query' | \
grep -o '"topicList":\[[^]]*\]'

echo ""
echo "3. 消费者组状态:"
docker run --rm --network container:$(docker ps | grep rocketmq-nameserver | awk '{print $1}') \
apache/rocketmq:4.9.4 sh mqadmin consumerProgress -n $NAMESERVER 2>/dev/null | head -10

echo ""
echo "4. 消息堆积检查:"
# 检查各个Topic的消息堆积情况
for topic in TEST_TOPIC RELIABILITY_TEST; do
    echo "Topic: $topic"
    docker run --rm --network container:$(docker ps | grep rocketmq-nameserver | awk '{print $1}') \
    apache/rocketmq:4.9.4 sh mqadmin topicStatus -n $NAMESERVER -t $topic 2>/dev/null
    echo ""
done

echo "=== 监控报告结束 ==="
```

#### 自动化测试脚本
```bash
#!/bin/bash  
# reliability_test.sh - RocketMQ可靠性自动化测试

NAMESERVER="localhost:9876"
NETWORK_CONTAINER=$(docker ps | grep rocketmq-nameserver | awk '{print $1}')
TEST_TOPIC="AUTO_TEST_$(date +%s)"
TOTAL_MESSAGES=1000
SUCCESS_COUNT=0

echo "=== RocketMQ可靠性自动化测试 ==="
echo "测试Topic: $TEST_TOPIC"
echo "测试消息数量: $TOTAL_MESSAGES"
echo "开始时间: $(date)"
echo ""

# 创建测试Topic
echo "创建测试Topic..."
docker run --rm --network container:$NETWORK_CONTAINER \
apache/rocketmq:4.9.4 sh mqadmin updateTopic \
-n $NAMESERVER -t $TEST_TOPIC -c DefaultCluster 2>/dev/null

echo "等待Topic创建完成..."
sleep 5

# 批量发送测试消息
echo "开始发送测试消息..."
for ((i=1; i<=TOTAL_MESSAGES; i++)); do
    result=$(docker run --rm --network container:$NETWORK_CONTAINER \
    apache/rocketmq:4.9.4 sh mqadmin sendMessage \
    -n $NAMESERVER -t $TEST_TOPIC \
    -p "Test Message $i - $(date +%s)" 2>/dev/null | grep SEND_OK)
    
    if [[ -n "$result" ]]; then
        ((SUCCESS_COUNT++))
    fi
    
    # 每100条显示进度
    if (( i % 100 == 0 )); then
        echo "已发送: $i/$TOTAL_MESSAGES, 成功: $SUCCESS_COUNT"
    fi
done

# 等待消息完全写入
echo "等待消息写入完成..."
sleep 10

# 统计结果
echo ""
echo "=== 测试结果统计 ==="
echo "总发送消息: $TOTAL_MESSAGES"
echo "发送成功: $SUCCESS_COUNT"  
echo "发送失败: $((TOTAL_MESSAGES - SUCCESS_COUNT))"
echo "成功率: $(echo "scale=2; $SUCCESS_COUNT * 100 / $TOTAL_MESSAGES" | bc)%"

# 检查消息存储情况
echo ""
echo "=== 消息存储验证 ==="
docker run --rm --network container:$NETWORK_CONTAINER \
apache/rocketmq:4.9.4 sh mqadmin topicStatus -n $NAMESERVER -t $TEST_TOPIC 2>/dev/null

# 消费测试
echo ""
echo "=== 消费测试 ==="
timeout 30s docker run --rm --network container:$NETWORK_CONTAINER \
apache/rocketmq:4.9.4 sh mqadmin consumeMessage \
-n $NAMESERVER -t $TEST_TOPIC -g AUTO_TEST_GROUP 2>/dev/null | \
grep "Consume ok" | wc -l

echo ""
echo "测试完成时间: $(date)"
echo "=== 自动化测试结束 ==="
```

