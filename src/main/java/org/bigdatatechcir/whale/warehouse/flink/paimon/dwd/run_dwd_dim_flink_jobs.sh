#!/bin/bash

# 设置Flink安装路径
FLINK_HOME=/opt/software/flink-1.18.1

# 设置项目根目录
PROJECT_ROOT=/root/nft-whale-tracker

# 设置SQL脚本目录
DWD_DIR=${PROJECT_ROOT}/src/main/java/org/bigdatatechcir/whale/warehouse/flink/paimon/dwd
DIM_DIR=${PROJECT_ROOT}/src/main/java/org/bigdatatechcir/whale/warehouse/flink/paimon/dim

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
mkdir -p ${DWD_DIR}/logs
mkdir -p ${DIM_DIR}/logs

# 输出依赖信息
echo "=========================="
echo "开始执行DWD和DIM层任务"
echo "=========================="
echo "使用的JAR依赖: ${KAFKA_CONNECTOR_JAR}"
echo "使用的JAR依赖: ${PAIMON_JAR}"
echo "=========================="

# 确保ODS层数据存在 - 已注释掉以跳过检查
# echo "检查ODS层数据..."
# $FLINK_HOME/bin/sql-client.sh embedded -e "CREATE CATALOG paimon_hive WITH ('type' = 'paimon', 'metastore' = 'hive', 'uri' = 'thrift://192.168.254.133:9083', 'warehouse' = 'hdfs:////user/hive/warehouse'); USE CATALOG paimon_hive; SHOW DATABASES;" > ${DWD_DIR}/logs/check_ods.log 2>&1
# cat ${DWD_DIR}/logs/check_ods.log
# echo "=========================="

echo "跳过ODS层数据检查，直接执行任务..."
echo "=========================="

# 1. 运行NFT交易明细表作业
echo "Step 1: 运行NFT交易明细表(DWD)作业..."
$FLINK_HOME/bin/sql-client.sh embedded -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${DWD_DIR}/dwd_nft_transaction_inc.sql > ${DWD_DIR}/logs/dwd_nft_transaction_inc.log 2>&1
if [ $? -ne 0 ]; then
    echo "错误: NFT交易明细表作业执行失败"
    echo "查看日志: ${DWD_DIR}/logs/dwd_nft_transaction_inc.log"
    echo "最后10行日志:"
    tail -10 ${DWD_DIR}/logs/dwd_nft_transaction_inc.log
    exit 1
fi
echo "NFT交易明细表(DWD)作业执行完成"
echo "=========================="

# 2. 运行价格行为表作业
echo "Step 2: 运行价格行为表(DWD)作业..."
$FLINK_HOME/bin/sql-client.sh embedded -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${DWD_DIR}/dwd_price_behavior_inc.sql > ${DWD_DIR}/logs/dwd_price_behavior_inc.log 2>&1
if [ $? -ne 0 ]; then
    echo "错误: 价格行为表作业执行失败"
    echo "查看日志: ${DWD_DIR}/logs/dwd_price_behavior_inc.log"
    echo "最后10行日志:"
    tail -10 ${DWD_DIR}/logs/dwd_price_behavior_inc.log
    exit 1
fi
echo "价格行为表(DWD)作业执行完成"
echo "=========================="

# 3. 运行钱包维度表作业
echo "Step 3: 运行钱包维度表(DIM)作业..."
$FLINK_HOME/bin/sql-client.sh embedded -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${DIM_DIR}/dim_wallet_full.sql > ${DIM_DIR}/logs/dim_wallet_full.log 2>&1
if [ $? -ne 0 ]; then
    echo "错误: 钱包维度表作业执行失败"
    echo "查看日志: ${DIM_DIR}/logs/dim_wallet_full.log"
    echo "最后10行日志:"
    tail -10 ${DIM_DIR}/logs/dim_wallet_full.log
    exit 1
fi
echo "钱包维度表(DIM)作业执行完成"
echo "=========================="

# 4. 运行NFT维度表作业
echo "Step 4: 运行NFT维度表(DIM)作业..."
$FLINK_HOME/bin/sql-client.sh embedded -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${DIM_DIR}/dim_nft_full.sql > ${DIM_DIR}/logs/dim_nft_full.log 2>&1
if [ $? -ne 0 ]; then
    echo "错误: NFT维度表作业执行失败"
    echo "查看日志: ${DIM_DIR}/logs/dim_nft_full.log"
    echo "最后10行日志:"
    tail -10 ${DIM_DIR}/logs/dim_nft_full.log
    exit 1
fi
echo "NFT维度表(DIM)作业执行完成"
echo "=========================="

# 5. 运行市场维度表作业
echo "Step 5: 运行市场维度表(DIM)作业..."
$FLINK_HOME/bin/sql-client.sh embedded -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${DIM_DIR}/dim_marketplace_full.sql > ${DIM_DIR}/logs/dim_marketplace_full.log 2>&1
if [ $? -ne 0 ]; then
    echo "错误: 市场维度表作业执行失败"
    echo "查看日志: ${DIM_DIR}/logs/dim_marketplace_full.log"
    echo "最后10行日志:"
    tail -10 ${DIM_DIR}/logs/dim_marketplace_full.log
    exit 1
fi
echo "市场维度表(DIM)作业执行完成"
echo "=========================="

echo "所有DWD和DIM层作业已成功执行完成!"
echo "可以使用以下命令查看详细日志:"
echo "  - DWD日志: cat ${DWD_DIR}/logs/*"
echo "  - DIM日志: cat ${DIM_DIR}/logs/*"
echo "==========================" 