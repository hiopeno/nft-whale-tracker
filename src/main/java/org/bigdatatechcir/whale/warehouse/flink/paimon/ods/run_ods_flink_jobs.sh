#!/bin/bash

# 设置Flink安装路径
FLINK_HOME=/opt/software/flink-1.18.1

# 设置项目根目录
PROJECT_ROOT=/root/nft-whale-tracker

# 设置SQL脚本目录
SQL_DIR=${PROJECT_ROOT}/src/main/java/org/bigdatatechcir/whale/warehouse/flink/paimon/ods

# 设置依赖JAR
KAFKA_CONNECTOR_JAR="${FLINK_HOME}/lib/flink-sql-connector-kafka-3.1.0-1.18.jar"
# KAFKA_CLIENTS_JAR="${FLINK_HOME}/lib/kafka-clients-3.6.1.jar"  # 注释掉，避免显式加载
PAIMON_JAR=$(ls ${FLINK_HOME}/lib/paimon-flink-1.18-1.1-20250228.002641-69.jar)

# 创建日志目录
mkdir -p ${SQL_DIR}/logs

# 输出依赖信息
echo "使用的JAR依赖: ${KAFKA_CONNECTOR_JAR}, ${PAIMON_JAR}"

# 运行NFT交易表作业
echo "开始运行NFT交易ODS层作业..."
$FLINK_HOME/bin/sql-client.sh -j ${KAFKA_CONNECTOR_JAR} -j ${PAIMON_JAR} -f ${SQL_DIR}/ods_nft_transaction_inc.sql > ${SQL_DIR}/logs/ods_nft_transaction_inc.log 2>&1 &
echo "NFT交易ODS层作业已启动，日志保存在 ${SQL_DIR}/logs/ods_nft_transaction_inc.log"

# 以下作业暂时注释，根据用户需求只保留NFT交易作业
# sleep 5

# # 运行NFT表作业
# echo "开始运行NFT ODS层作业..."
# $FLINK_HOME/bin/sql-client.sh -j ${KAFKA_CONNECTOR_JAR} -j ${KAFKA_CLIENTS_JAR} -j ${PAIMON_JAR} -f ${SQL_DIR}/ods_nft_inc.sql > ${SQL_DIR}/logs/ods_nft_inc.log 2>&1 &
# echo "NFT ODS层作业已启动，日志保存在 ${SQL_DIR}/logs/ods_nft_inc.log"

# sleep 5

# # 运行NFT Collection表作业
# echo "开始运行NFT收藏集ODS层作业..."
# $FLINK_HOME/bin/sql-client.sh -j ${KAFKA_CONNECTOR_JAR} -j ${KAFKA_CLIENTS_JAR} -j ${PAIMON_JAR} -f ${SQL_DIR}/ods_nft_collection_inc.sql > ${SQL_DIR}/logs/ods_nft_collection_inc.log 2>&1 &
# echo "NFT收藏集ODS层作业已启动，日志保存在 ${SQL_DIR}/logs/ods_nft_collection_inc.log"

# sleep 5

# # 运行鲸鱼钱包表作业
# echo "开始运行鲸鱼钱包ODS层作业..."
# $FLINK_HOME/bin/sql-client.sh -j ${KAFKA_CONNECTOR_JAR} -j ${KAFKA_CLIENTS_JAR} -j ${PAIMON_JAR} -f ${SQL_DIR}/ods_whale_wallet_inc.sql > ${SQL_DIR}/logs/ods_whale_wallet_inc.log 2>&1 &
# echo "鲸鱼钱包ODS层作业已启动，日志保存在 ${SQL_DIR}/logs/ods_whale_wallet_inc.log"

echo "NFT交易ODS层作业已启动."
echo "使用 jps 命令查看作业运行状态."
echo "使用 tail -f ${SQL_DIR}/logs/ods_nft_transaction_inc.log 查看作业日志." 