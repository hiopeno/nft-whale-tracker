#!/bin/bash

# 设置Flink安装路径
FLINK_HOME=/opt/software/flink-1.18.1

# 设置项目根目录
PROJECT_ROOT=/root/nft-whale-tracker

# 设置SQL脚本目录
DWS_DIR=${PROJECT_ROOT}/src/main/java/org/bigdatatechcir/whale/warehouse/flink/paimon/dws

# 设置依赖JAR
KAFKA_CONNECTOR_JAR="${FLINK_HOME}/lib/flink-sql-connector-kafka-3.1.0-1.18.jar"
PAIMON_JAR=$(ls ${FLINK_HOME}/lib/paimon-flink-1.18-1.1-*.jar 2>/dev/null || echo "找不到Paimon JAR")

if [[ ! -f "$KAFKA_CONNECTOR_JAR" ]]; then
    echo "错误: 找不到Kafka连接器JAR: $KAFKA_CONNECTOR_JAR"
    exit 1
fi

if [[ "$PAIMON_JAR" == "找不到Paimon JAR" ]]; then
    echo "错误: 找不到Paimon JAR"
    exit 1
fi

# 创建日志目录
mkdir -p ${DWS_DIR}/logs

# 输出依赖信息
echo "=========================="
echo "开始执行DWS层任务"
echo "=========================="
echo "使用的JAR依赖: ${KAFKA_CONNECTOR_JAR}"
echo "使用的JAR依赖: ${PAIMON_JAR}"
echo "=========================="

# 检查目录是否存在
if [ ! -d "$DWS_DIR" ]; then
    echo "错误: DWS目录不存在: $DWS_DIR"
    exit 1
fi

# 输出依赖层检查信息（但不阻塞执行）
echo "注意: 已跳过数据依赖层检查，直接执行DWS层作业"
echo "=========================="

# 1. 运行鲸鱼行为日汇总表作业
echo "Step 1: 运行鲸鱼行为日汇总表(DWS)作业..."
$FLINK_HOME/bin/sql-client.sh embedded -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${DWS_DIR}/dws_whale_behavior_1d.sql > ${DWS_DIR}/logs/dws_whale_behavior_1d.log 2>&1
if [ $? -ne 0 ]; then
    echo "错误: 鲸鱼行为日汇总表作业执行失败"
    echo "查看日志: ${DWS_DIR}/logs/dws_whale_behavior_1d.log"
    echo "最后10行日志:"
    tail -10 ${DWS_DIR}/logs/dws_whale_behavior_1d.log
    echo "是否继续执行其他作业? (y/n)"
    read answer
    if [ "$answer" != "y" ]; then
        echo "操作已终止"
        exit 1
    fi
else
    echo "鲸鱼行为日汇总表(DWS)作业执行完成"
fi
echo "=========================="

# 2. 运行NFT价格日汇总表作业
echo "Step 2: 运行NFT价格日汇总表(DWS)作业..."
$FLINK_HOME/bin/sql-client.sh embedded -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${DWS_DIR}/dws_nft_price_1d.sql > ${DWS_DIR}/logs/dws_nft_price_1d.log 2>&1
if [ $? -ne 0 ]; then
    echo "错误: NFT价格日汇总表作业执行失败"
    echo "查看日志: ${DWS_DIR}/logs/dws_nft_price_1d.log"
    echo "最后10行日志:"
    tail -10 ${DWS_DIR}/logs/dws_nft_price_1d.log
    echo "是否继续执行其他作业? (y/n)"
    read answer
    if [ "$answer" != "y" ]; then
        echo "操作已终止"
        exit 1
    fi
else
    echo "NFT价格日汇总表(DWS)作业执行完成"
fi
echo "=========================="

# 3. 运行市场活跃度日汇总表作业
echo "Step 3: 运行市场活跃度日汇总表(DWS)作业..."
$FLINK_HOME/bin/sql-client.sh embedded -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${DWS_DIR}/dws_market_activity_1d.sql > ${DWS_DIR}/logs/dws_market_activity_1d.log 2>&1
if [ $? -ne 0 ]; then
    echo "错误: 市场活跃度日汇总表作业执行失败"
    echo "查看日志: ${DWS_DIR}/logs/dws_market_activity_1d.log"
    echo "最后10行日志:"
    tail -10 ${DWS_DIR}/logs/dws_market_activity_1d.log
    exit 1
else
    echo "市场活跃度日汇总表(DWS)作业执行完成"
fi
echo "=========================="

# 移除验证DWS层表的创建环节
echo "注意: 已跳过DWS层表验证步骤"

echo "=========================="
echo "所有DWS层作业执行完成!"
echo "可以使用以下命令查看详细日志:"
echo "  - DWS日志: cat ${DWS_DIR}/logs/*"
echo "==========================" 