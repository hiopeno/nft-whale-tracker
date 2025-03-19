#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 设置环境变量
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 函数定义：打印带颜色的消息
print_message() {
    echo -e "${2}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# 主函数
main() {
    echo "====================================================="
    echo "        NFT鲸鱼钱包监控系统一键启动脚本              "
    echo "====================================================="
    echo ""
    
    print_message "第1步: 启动大数据组件..." $YELLOW
    bash "$SCRIPT_DIR/restart_bigdata.sh"
    
    # 检查大数据组件启动状态
    if [ $? -ne 0 ]; then
        print_message "大数据组件启动失败，请检查错误信息" $RED
        exit 1
    fi
    
    print_message "等待30秒确保所有大数据组件完全启动..." $YELLOW
    sleep 30
    
    print_message "第2步: 启动Flink作业..." $YELLOW
    bash "$SCRIPT_DIR/restart_jobs.sh"
    
    if [ $? -ne 0 ]; then
        print_message "Flink作业启动失败，请检查错误信息" $RED
        exit 1
    fi
    
    print_message "系统启动完成!" $GREEN
    print_message "可通过Flink WebUI查看作业状态: http://192.168.254.133:8081" $GREEN
    print_message "可通过Hadoop WebUI查看HDFS状态: http://192.168.254.133:50070" $GREEN
    print_message "使用 ./query.sh 查询Paimon数据" $GREEN
    echo ""
    print_message "系统已全部启动，祝您使用愉快！" $GREEN
}

# 执行主函数
main 