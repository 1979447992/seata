#!/bin/bash
# learning_exercises.sh - RocketMQ学习练习脚本

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 设置变量
NAMESERVER_CONTAINER=$(docker ps | grep rocketmq-nameserver | awk '{print $1}')
NETWORK="container:$NAMESERVER_CONTAINER"

echo "=================================="
echo "   RocketMQ 学习练习指南"
echo "=================================="
echo ""

# 练习1: Topic管理
print_step "练习1: Topic管理操作"
echo ""

echo "1.1 查看现有Topic列表"
docker exec $(docker ps | grep rocketmq-console | awk '{print $1}') \
curl -s 'http://localhost:8080/topic/list.query' | grep -o '"topicList":\[[^]]*\]' | \
sed 's/"topicList":\[/Topics: /' | sed 's/\]$//' | tr -d '"'

echo ""
echo "1.2 创建学习用Topic"
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin updateTopic -n localhost:9876 -t LEARNING_TOPIC -c DefaultCluster 2>/dev/null && \
print_success "创建LEARNING_TOPIC成功" || print_error "创建Topic失败"

echo ""
echo "1.3 查看Topic详细信息"
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin topicRoute -n localhost:9876 -t LEARNING_TOPIC 2>/dev/null | \
grep -E "(writeQueueNums|readQueueNums)" | head -2

echo ""
echo "按回车继续下一个练习..."
read

# 练习2: 消息发送练习
print_step "练习2: 不同类型消息发送练习"
echo ""

echo "2.1 发送普通消息"
for i in {1..3}; do
    RESULT=$(docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
    sh mqadmin sendMessage -n localhost:9876 -t LEARNING_TOPIC \
    -p "学习消息 $i - $(date)" 2>/dev/null | grep SEND_OK)
    
    if [[ -n "$RESULT" ]]; then
        print_success "消息 $i 发送成功"
    else
        print_error "消息 $i 发送失败"
    fi
done

echo ""
echo "2.2 发送带Tag的消息"
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin sendMessage -n localhost:9876 -t LEARNING_TOPIC \
-a "LearningTag" -p "带标签的学习消息" 2>/dev/null | grep SEND_OK && \
print_success "带Tag消息发送成功" || print_error "带Tag消息发送失败"

echo ""
echo "2.3 发送带Key的消息"  
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin sendMessage -n localhost:9876 -t LEARNING_TOPIC \
-k "LEARNING_KEY_001" -p "带Key的学习消息" 2>/dev/null | grep SEND_OK && \
print_success "带Key消息发送成功" || print_error "带Key消息发送失败"

echo ""
echo "按回车继续下一个练习..."
read

# 练习3: 消息查询练习
print_step "练习3: 消息查询和管理练习"
echo ""

echo "3.1 查看Topic消息统计"
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin topicStatus -n localhost:9876 -t LEARNING_TOPIC 2>/dev/null

echo ""
echo "3.2 根据Key查询消息"
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin queryMsgByKey -n localhost:9876 -t LEARNING_TOPIC -k LEARNING_KEY_001 2>/dev/null | \
head -5

echo ""
echo "按回车继续下一个练习..."
read

# 练习4: 消息消费练习
print_step "练习4: 消息消费练习"
echo ""

echo "4.1 消费LEARNING_TOPIC的消息"
print_warning "将显示前3条消费的消息，然后自动停止"
timeout 15s docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin consumeMessage -n localhost:9876 -t LEARNING_TOPIC -g LEARNING_GROUP 2>/dev/null | \
head -10

echo ""
echo "4.2 查看消费进度"
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin consumerProgress -n localhost:9876 -g LEARNING_GROUP 2>/dev/null | head -8

echo ""
echo "按回车继续下一个练习..."
read

# 练习5: 监控和运维练习
print_step "练习5: 监控和运维练习"
echo ""

echo "5.1 查看集群状态"
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin clusterList -n localhost:9876 2>/dev/null | head -10

echo ""
echo "5.2 查看Broker状态"
BROKER_ADDR=$(docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin clusterList -n localhost:9876 2>/dev/null | grep -E "brokerAddrs|BrokerName" | head -1)
echo "Broker信息: $BROKER_ADDR"

echo ""
echo "5.3 查看系统性能指标"
echo "内存使用:"
free -h | head -2

echo ""
echo "磁盘使用:"
df -h | head -5

echo ""
echo "Docker容器状态:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep rocketmq

echo ""
print_step "🎉 恭喜! 完成所有RocketMQ学习练习"
echo ""
echo "学习总结:"
print_success "1. Topic管理 - 学会创建和查看Topic"
print_success "2. 消息发送 - 掌握不同类型消息发送"  
print_success "3. 消息查询 - 学会根据Key查询消息"
print_success "4. 消息消费 - 理解消费者工作原理"
print_success "5. 系统监控 - 掌握基本运维操作"

echo ""
echo "下一步学习建议:"
echo "- 阅读README.md中的Java代码示例"
echo "- 尝试编写自己的Producer和Consumer程序"
echo "- 学习事务消息和顺序消息的使用"
echo "- 了解Spring Boot集成方式"

echo ""
echo "=================================="
echo "   学习练习完成!"
echo "=================================="
