#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 设置环境变量
FLINK_HOME=/opt/software/flink-1.18.1

# 函数定义：打印带颜色的消息
print_message() {
    echo -e "${2}${1}${NC}"
}

# 函数定义：关闭所有SQL Client进程
kill_sql_clients() {
    print_message "关闭已有的SQL Client进程..." $YELLOW
    
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

# 主函数
main() {
    print_message "开始查询Paimon中的NFT交易数据..." $YELLOW
    
    # 先关闭已有的SQL Client进程
    kill_sql_clients
    
    # 执行查询
    print_message "执行SQL查询..." $YELLOW
    $FLINK_HOME/bin/sql-client.sh -j $FLINK_HOME/lib/flink-sql-connector-kafka-3.1.0-1.18.jar -j $FLINK_HOME/lib/paimon-flink-1.18-1.1-20250228.002641-69.jar -f paimon_query.sql
    
    # 查询完成后关闭SQL Client
    kill_sql_clients
    
    print_message "查询完成" $GREEN
}

# 执行主函数
main 