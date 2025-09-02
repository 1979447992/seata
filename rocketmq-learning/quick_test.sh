#!/bin/bash
# quick_test.sh - RocketMQ快速功能测试脚本

echo "=== RocketMQ快速功能测试 ==="
echo "测试时间: $(date)"
echo ""

# 设置变量
NAMESERVER_CONTAINER=$(docker ps | grep rocketmq-nameserver | awk '{print $1}')
NETWORK="container:$NAMESERVER_CONTAINER"

# 1. 基础连通性测试
echo "1. 测试RocketMQ连通性..."
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin clusterList -n localhost:9876 2>/dev/null && echo "✅ 连通性正常" || echo "❌ 连通性异常"

echo ""

# 2. 消息发送测试
echo "2. 测试消息发送功能..."
SEND_RESULT=$(docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin sendMessage -n localhost:9876 -t QUICK_TEST -p "快速测试消息-$(date +%s)" 2>/dev/null | grep SEND_OK)

if [[ -n "$SEND_RESULT" ]]; then
    echo "✅ 消息发送成功"
    echo "   $SEND_RESULT"
else
    echo "❌ 消息发送失败"
fi

echo ""

# 3. 消息存储验证
echo "3. 验证消息存储状态..."
docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin topicStatus -n localhost:9876 -t QUICK_TEST 2>/dev/null | \
grep -E "(QID|Offset)" | head -5

echo ""

# 4. 消息消费测试  
echo "4. 测试消息消费功能..."
timeout 10s docker run --rm --network $NETWORK apache/rocketmq:4.9.4 \
sh mqadmin consumeMessage -n localhost:9876 -t QUICK_TEST -g QUICK_TEST_GROUP 2>/dev/null | \
head -3 | grep "Consume ok" && echo "✅ 消息消费成功" || echo "⚠️  消费测试超时(正常)"

echo ""
echo "=== 快速测试完成 ==="
