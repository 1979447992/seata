FROM openjdk:17-jdk-slim

WORKDIR /app

# 复制 Maven 配置文件
COPY pom.xml .

# 复制源代码
COPY src ./src

# 安装 Maven 并构建项目
RUN apt-get update && apt-get install -y maven && \
    mvn clean package -DskipTests && \
    mv target/*.jar app.jar && \
    rm -rf target && \
    apt-get remove -y maven && \
    rm -rf /var/lib/apt/lists/*

# 暴露端口
EXPOSE 8081

# 启动命令
CMD ["java", "-jar", "app.jar"]