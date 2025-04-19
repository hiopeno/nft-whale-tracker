-- 查询特定钱包地址的买入和卖出交易记录
SET 'sql-client.execution.result-mode'='TABLEAU';
-- 设置执行参数
SET 'execution.checkpointing.interval' = '10s';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'pipeline.name' = 'Wallet_Transactions_Query';

-- 增加内存配置，避免OOM
SET 'jobmanager.memory.process.size' = '4096m';
SET 'taskmanager.memory.process.size' = '8192m';
SET 'taskmanager.memory.jvm-metaspace.size' = '512m';
SET 'taskmanager.memory.task.off-heap.size' = '1024m';

-- 使用Paimon Catalog
CREATE CATALOG paimon_hive WITH (
    'type' = 'paimon',
    'metastore' = 'hive',
    'uri' = 'thrift://192.168.254.133:9083',
    'hive-conf-dir' = '/opt/software/apache-hive-3.1.3-bin/conf',
    'hadoop-conf-dir' = '/opt/software/hadoop-3.1.3/etc/hadoop',
    'warehouse' = 'hdfs:////user/hive/warehouse'
);

USE CATALOG paimon_hive;
USE ods;

-- 接收传入的钱包地址参数
-- 此参数将通过shell脚本传入: '${WALLET_ADDRESS}'

-- 查询总共有多少交易记录
SELECT 
    '${WALLET_ADDRESS}' AS wallet_address,
    COUNT(*) AS total_records,
    SUM(CASE WHEN to_address = '${WALLET_ADDRESS}' THEN 1 ELSE 0 END) AS buy_count,
    SUM(CASE WHEN from_address = '${WALLET_ADDRESS}' THEN 1 ELSE 0 END) AS sell_count
FROM ods_collection_transaction_inc
WHERE to_address = '${WALLET_ADDRESS}' OR from_address = '${WALLET_ADDRESS}';

-- 查询买入记录（钱包地址作为to_address）
SELECT 
    '买入记录' AS transaction_type,
    TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))) AS tx_date,
    FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT)) AS tx_time,
    hash AS tx_hash,
    from_address AS seller,
    to_address AS buyer,
    contract_address,
    contract_name AS collection_name,
    token_id,
    trade_price AS price_eth,
    trade_price * 2500.00 AS price_usd,
    trade_symbol,
    exchange_name AS platform
FROM ods_collection_transaction_inc
WHERE to_address = '${WALLET_ADDRESS}'
ORDER BY tx_timestamp DESC;

-- 查询卖出记录（钱包地址作为from_address）
SELECT 
    '卖出记录' AS transaction_type,
    TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))) AS tx_date,
    FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT)) AS tx_time,
    hash AS tx_hash,
    from_address AS seller,
    to_address AS buyer,
    contract_address,
    contract_name AS collection_name,
    token_id,
    trade_price AS price_eth,
    trade_price * 2500.00 AS price_usd,
    trade_symbol,
    exchange_name AS platform
FROM ods_collection_transaction_inc
WHERE from_address = '${WALLET_ADDRESS}'
ORDER BY tx_timestamp DESC;

-- 查询交易量统计
SELECT 
    '${WALLET_ADDRESS}' AS wallet_address,
    SUM(CASE WHEN to_address = '${WALLET_ADDRESS}' THEN trade_price ELSE 0 END) AS total_buy_volume_eth,
    SUM(CASE WHEN from_address = '${WALLET_ADDRESS}' THEN trade_price ELSE 0 END) AS total_sell_volume_eth,
    SUM(CASE WHEN to_address = '${WALLET_ADDRESS}' THEN trade_price ELSE 0 END) - 
    SUM(CASE WHEN from_address = '${WALLET_ADDRESS}' THEN trade_price ELSE 0 END) AS net_flow_eth,
    COUNT(DISTINCT CASE WHEN to_address = '${WALLET_ADDRESS}' THEN contract_address END) AS buy_collections_count,
    COUNT(DISTINCT CASE WHEN from_address = '${WALLET_ADDRESS}' THEN contract_address END) AS sell_collections_count
FROM ods_collection_transaction_inc
WHERE to_address = '${WALLET_ADDRESS}' OR from_address = '${WALLET_ADDRESS}'; 