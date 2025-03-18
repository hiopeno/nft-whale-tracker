#!/bin/bash

echo "===== NFT鲸鱼追踪项目编译运行脚本 ====="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# Kafka配置
KAFKA_HOME="/opt/software/kafka_2.12-3.6.1"
KAFKA_TOPIC="NFT_TRANSACTIONS"
KAFKA_BOOTSTRAP_SERVER="192.168.254.133:9092"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}用法:${NC} $0 [选项]"
    echo
    echo -e "${BLUE}选项:${NC}"
    echo "  -c, --compile      仅编译项目"
    echo "  -r, --run          仅运行项目（不编译）"
    echo "  -i, --interval N   设置生成间隔（毫秒，默认1000）"
    echo "  -n, --collections N 设置收藏集数量（默认10）"
    echo "  -b, --boot         使用Spring Boot JAR运行（默认）"
    echo "  -s, --standard     使用标准JAR运行"
    echo "  -k, --clean-kafka  清空Kafka主题数据后再启动"
    echo "  -h, --help         显示此帮助信息"
    echo
    echo -e "${BLUE}示例:${NC}"
    echo "  $0                 使用默认参数编译并运行"
    echo "  $0 -r -i 2000      使用2000毫秒间隔运行（不编译）"
    echo "  $0 -c              仅编译不运行"
    echo "  $0 -s -i 500       使用标准JAR运行，间隔500毫秒"
    echo "  $0 -k              清空Kafka数据后运行"
    echo
}

# 清空Kafka主题数据
clean_kafka_topic() {
    echo -e "${YELLOW}正在清空Kafka主题 ${KAFKA_TOPIC} 的数据...${NC}"

    # 检查Kafka安装目录是否存在
    if [ ! -d "$KAFKA_HOME" ]; then
        echo -e "${RED}错误: Kafka安装目录不存在: $KAFKA_HOME${NC}"
        return 1
    fi

    # 检查主题是否存在
    TOPIC_EXISTS=$($KAFKA_HOME/bin/kafka-topics.sh --list --bootstrap-server $KAFKA_BOOTSTRAP_SERVER | grep -w "$KAFKA_TOPIC")
    
    if [ -n "$TOPIC_EXISTS" ]; then
        echo "主题 $KAFKA_TOPIC 存在，正在删除..."
        $KAFKA_HOME/bin/kafka-topics.sh --delete --topic $KAFKA_TOPIC --bootstrap-server $KAFKA_BOOTSTRAP_SERVER
        
        # 等待删除完成
        echo "等待主题删除完成..."
        sleep 3
    else
        echo "主题 $KAFKA_TOPIC 不存在，将创建新主题"
    fi
    
    # 创建新主题
    echo "创建新主题 $KAFKA_TOPIC..."
    $KAFKA_HOME/bin/kafka-topics.sh --create --topic $KAFKA_TOPIC --bootstrap-server $KAFKA_BOOTSTRAP_SERVER --partitions 1 --replication-factor 1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Kafka主题 $KAFKA_TOPIC 已清空并重新创建!${NC}"
        return 0
    else
        echo -e "${RED}清空Kafka主题失败!${NC}"
        return 1
    fi
}

# 默认参数
COMPILE=true
RUN=true
INTERVAL=1000
COLLECTIONS=10
USE_STANDARD_JAR=false
CLEAN_KAFKA=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--compile)
            COMPILE=true
            RUN=false
            shift
            ;;
        -r|--run)
            COMPILE=false
            RUN=true
            shift
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -n|--collections)
            COLLECTIONS="$2"
            shift 2
            ;;
        -b|--boot)
            USE_STANDARD_JAR=false
            shift
            ;;
        -s|--standard)
            USE_STANDARD_JAR=true
            shift
            ;;
        -k|--clean-kafka)
            CLEAN_KAFKA=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知选项 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查Java是否安装
if ! command -v java &> /dev/null; then
    echo -e "${RED}错误: Java未安装${NC}"
    echo "请安装JDK 8或更高版本后再运行此脚本"
    exit 1
fi

# 检查Maven是否安装（如果需要编译）
if [ "$COMPILE" = true ] && ! command -v mvn &> /dev/null; then
    echo -e "${RED}错误: Maven未安装${NC}"
    echo "请安装Maven 3.6+后再运行此脚本"
    exit 1
fi

# 清空Kafka主题
if [ "$CLEAN_KAFKA" = true ]; then
    clean_kafka_topic
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}警告: Kafka主题清理失败，但将继续执行...${NC}"
    fi
fi

# 编译项目
if [ "$COMPILE" = true ]; then
    # 显示当前配置
    echo -e "${YELLOW}正在使用以下配置:${NC}"
    java -version
    mvn -version

    echo -e "\n${YELLOW}正在编译项目...${NC}"
    if mvn clean package; then
        echo -e "${GREEN}编译成功!${NC}"
    else
        echo -e "${RED}编译失败!${NC}"
        exit 1
    fi
fi

# 如果不需要运行，则退出
if [ "$RUN" = false ]; then
    echo -e "${GREEN}编译完成，未指定运行选项，退出脚本${NC}"
    exit 0
fi

# 运行项目
echo -e "\n${YELLOW}正在启动NFT鲸鱼追踪项目...${NC}"
echo "项目将在后台运行，输出将重定向到nft-tracker.log文件"
echo "你可以使用 'tail -f nft-tracker.log' 命令查看日志"

# 根据选择的JAR类型运行
if [ "$USE_STANDARD_JAR" = true ]; then
    echo -e "${BLUE}使用标准JAR运行项目${NC}"
    JAR_FILE="target/nft-whale-tracker-1.0-SNAPSHOT.jar"
    RUN_CMD="java -cp $JAR_FILE:target/lib/* -Dgenerator.interval=$INTERVAL -Dgenerator.collections=$COLLECTIONS org.bigdatatechcir.whale.NFTDataGeneratorApplication"
else
    echo -e "${BLUE}使用Spring Boot JAR运行项目${NC}"
    JAR_FILE="target/nft-whale-tracker-1.0-SNAPSHOT-spring-boot.jar"
    RUN_CMD="java -Dgenerator.interval=$INTERVAL -Dgenerator.collections=$COLLECTIONS -jar $JAR_FILE"
fi

# 使用nohup在后台运行
nohup $RUN_CMD > nft-tracker.log 2>&1 &

PID=$!
echo -e "${GREEN}项目已启动! 进程ID: $PID${NC}"
echo "配置参数: 间隔=$INTERVAL毫秒, 收藏集数量=$COLLECTIONS"
echo -e "\n使用以下命令查看日志:"
echo "tail -f nft-tracker.log"
echo -e "\n使用以下命令停止服务:"
echo "kill $PID"

# 创建停止脚本
echo "#!/bin/bash" > stop.sh
echo "# 停止NFT鲸鱼追踪项目" >> stop.sh
echo "PID=\$(ps -ef | grep nft-whale-tracker | grep -v grep | awk '{print \$2}')" >> stop.sh
echo "if [ -z \"\$PID\" ]; then" >> stop.sh
echo "  echo \"没有发现正在运行的NFT鲸鱼追踪进程\"" >> stop.sh
echo "  exit 0" >> stop.sh
echo "fi" >> stop.sh
echo "echo \"正在停止NFT鲸鱼追踪进程 \$PID...\"" >> stop.sh
echo "kill \$PID" >> stop.sh
echo "echo \"进程已停止\"" >> stop.sh
chmod +x stop.sh

echo -e "${GREEN}已创建停止脚本 stop.sh${NC}" 
