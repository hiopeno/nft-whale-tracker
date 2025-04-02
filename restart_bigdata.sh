#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 设置环境变量
HADOOP_HOME=/opt/software/hadoop-3.1.3
HIVE_HOME=/opt/software/apache-hive-3.1.3-bin
ZOOKEEPER_HOME=/opt/software/zookeeper-3.9.1
KAFKA_HOME=/opt/software/kafka_2.12-3.6.1
FLINK_HOME=/opt/software/flink-1.18.1
DINKY_HOME=/opt/software/dinky-1.2.2
# KAFKA_UI_HOME=/opt/software/kafka-ui  # 删除Kafka UI目录设置，因为使用Docker

# 函数定义：打印带颜色的消息
print_message() {
    echo -e "${2}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# 函数定义：检查服务是否运行
check_service() {
    service_name=$1
    pid_count=$(ps -ef | grep -i "$service_name" | grep -v grep | wc -l)
    if [ $pid_count -gt 0 ]; then
        return 0 # 服务正在运行
    else
        return 1 # 服务未运行
    fi
}

# 函数定义：关闭所有SQL Client进程
kill_sql_clients() {
    print_message "关闭所有SQL Client进程..." $YELLOW
    
    # 查找所有SQL Client进程
    SQL_CLIENT_PIDS=$(ps -ef | grep 'sql-client' | grep -v grep | awk '{print $2}')
    
    if [ -z "$SQL_CLIENT_PIDS" ]; then
        print_message "没有SQL Client进程在运行" $GREEN
    else
        for PID in $SQL_CLIENT_PIDS; do
            print_message "关闭SQL Client进程: $PID" $YELLOW
            kill -9 $PID
            sleep 1
        done
        print_message "所有SQL Client进程已关闭" $GREEN
    fi
}

# 函数定义：停止所有服务
stop_all_services() {
    print_message "开始停止所有服务..." $YELLOW

    # 停止Dinky
    print_message "停止Dinky服务..." $YELLOW
    if check_service "dinky"; then
        cd $DINKY_HOME
        ./bin/auto.sh stop
        sleep 3
        print_message "Dinky服务已停止" $GREEN
    else
        print_message "Dinky服务未运行" $GREEN
    fi

    # 停止Flink
    print_message "停止Flink服务..." $YELLOW
    if check_service "flink"; then
        $FLINK_HOME/bin/stop-cluster.sh
        sleep 5
        print_message "Flink服务已停止" $GREEN
    else
        print_message "Flink服务未运行" $GREEN
    fi
    
    # 关闭所有SQL Client进程
    kill_sql_clients

    # 停止Kafka UI
    print_message "停止Kafka UI服务..." $YELLOW
    if docker ps | grep -q "kafka-ui"; then
        docker stop kafka-ui
        sleep 3
        print_message "Kafka UI服务已停止" $GREEN
    else
        print_message "Kafka UI服务未运行" $GREEN
    fi

    # 停止Kafka
    print_message "停止Kafka服务..." $YELLOW
    if check_service "kafka.Kafka"; then
        $KAFKA_HOME/bin/kafka-server-stop.sh
        sleep 5
        print_message "Kafka服务已停止" $GREEN
    else
        print_message "Kafka服务未运行" $GREEN
    fi

    # 停止Hive Metastore
    print_message "停止Hive Metastore服务..." $YELLOW
    if check_service "org.apache.hadoop.hive.metastore.HiveMetaStore"; then
        pid=$(ps -ef | grep -i "org.apache.hadoop.hive.metastore.HiveMetaStore" | grep -v grep | awk '{print $2}')
        if [ ! -z "$pid" ]; then
            kill -15 $pid
            sleep 3
            print_message "Hive Metastore服务已停止" $GREEN
        fi
    else
        print_message "Hive Metastore服务未运行" $GREEN
    fi

    # 停止Hadoop
    print_message "停止Hadoop服务..." $YELLOW
    if check_service "hadoop"; then
        $HADOOP_HOME/sbin/stop-all.sh
        sleep 5
        print_message "Hadoop服务已停止" $GREEN
    else
        print_message "Hadoop服务未运行" $GREEN
    fi

    # 停止ZooKeeper
    print_message "停止ZooKeeper服务..." $YELLOW
    if check_service "QuorumPeerMain"; then
        $ZOOKEEPER_HOME/bin/zkServer.sh stop
        sleep 3
        print_message "ZooKeeper服务已停止" $GREEN
    else
        print_message "ZooKeeper服务未运行" $GREEN
    fi

    # 检查是否需要关闭Docker服务
    print_message "注意: Docker服务保持运行状态以支持其他应用" $YELLOW

    print_message "所有服务已停止" $GREEN
    echo ""
}

# 函数定义：启动所有服务
start_all_services() {
    print_message "开始启动所有服务..." $YELLOW

    # 检查并启动Docker服务
    print_message "检查Docker服务状态..." $YELLOW
    if systemctl is-active docker > /dev/null 2>&1; then
        print_message "Docker服务已运行" $GREEN
    else
        print_message "启动Docker服务..." $YELLOW
        systemctl start docker
        sleep 5
        if systemctl is-active docker > /dev/null 2>&1; then
            print_message "Docker服务已启动" $GREEN
        else
            print_message "Docker服务启动失败" $RED
            exit 1
        fi
    fi

    # 启动ZooKeeper
    print_message "启动ZooKeeper服务..." $YELLOW
    $ZOOKEEPER_HOME/bin/zkServer.sh start
    sleep 5
    if check_service "QuorumPeerMain"; then
        print_message "ZooKeeper服务已启动" $GREEN
    else
        print_message "ZooKeeper服务启动失败" $RED
        exit 1
    fi

    # 启动Hadoop
    print_message "启动Hadoop服务..." $YELLOW
    $HADOOP_HOME/sbin/start-all.sh
    sleep 10
    if check_service "NameNode"; then
        print_message "Hadoop服务已启动" $GREEN
    else
        print_message "Hadoop服务启动失败" $RED
        exit 1
    fi

    # 启动Hive Metastore
    print_message "启动Hive Metastore服务..." $YELLOW
    nohup $HIVE_HOME/bin/hive --service metastore > /dev/null 2>&1 &
    sleep 5
    if check_service "org.apache.hadoop.hive.metastore.HiveMetaStore"; then
        print_message "Hive Metastore服务已启动" $GREEN
    else
        print_message "Hive Metastore服务启动失败" $RED
        exit 1
    fi

    # 启动Kafka
    print_message "启动Kafka服务..." $YELLOW
    nohup $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties > /dev/null 2>&1 &
    sleep 10
    if check_service "kafka.Kafka"; then
        print_message "Kafka服务已启动" $GREEN
    else
        print_message "Kafka服务启动失败" $RED
        exit 1
    fi

    # 启动Flink
    print_message "启动Flink服务..." $YELLOW
    $FLINK_HOME/bin/start-cluster.sh
    sleep 5
    if check_service "ClusterEntrypoint"; then
        print_message "Flink服务已启动" $GREEN
    else
        print_message "Flink服务启动失败" $RED
        exit 1
    fi

    # 启动Kafka UI
    print_message "启动Kafka UI服务..." $YELLOW
    docker start kafka-ui
    sleep 5
    if docker ps | grep -q "kafka-ui"; then
        print_message "Kafka UI服务已启动" $GREEN
    else
        print_message "Kafka UI服务启动失败" $RED
        exit 1
    fi

    # 启动Dinky
    print_message "启动Dinky服务..." $YELLOW
    cd $DINKY_HOME
    ./bin/auto.sh start 1.18
    sleep 5
    if check_service "dinky"; then
        print_message "Dinky服务已启动" $GREEN
    else
        print_message "Dinky服务启动失败" $RED
        exit 1
    fi
    cd - > /dev/null

    print_message "所有服务已成功启动" $GREEN
    echo ""
}

# 主函数
main() {
    echo "====================================================="
    echo "          大数据组件一键重启脚本                     "
    echo "====================================================="
    echo ""

    # 停止所有服务
    stop_all_services

    # 稍等片刻确保所有服务都已停止
    print_message "等待5秒钟确保所有服务完全停止..." $YELLOW
    sleep 5

    # 启动所有服务
    start_all_services

    # 检查所有服务
    print_message "所有大数据组件已重启完成。" $GREEN
    print_message "当前运行的相关进程:" $YELLOW
    ps -ef | grep -E "zookeeper|kafka|hadoop|hive|flink|kafka-ui|dinky" | grep -v grep
    echo ""
    print_message "Flink WebUI访问地址: http://192.168.254.133:8081" $GREEN
    print_message "Kafka UI访问地址: http://192.168.254.133:8080" $GREEN
    print_message "Dinky访问地址: http://192.168.254.133:8888" $GREEN
}

# 执行主函数
main 