FROM seataio/seata-server:1.7.1

# 切换到root用户添加Oracle驱动
USER root

# 复制本地下载的Oracle JDBC驱动
COPY ojdbc8.jar /seata-server/lib/ojdbc8.jar

# 设置权限
RUN chmod 644 /seata-server/lib/ojdbc8.jar

# 回到seata用户
USER 1000

EXPOSE 8091 7091
