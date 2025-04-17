-- 鲸鱼交易明细数据

-- NFT API数据表结构定义和数据导入

-- 设置执行参数
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
-- 设置为批处理模式
SET 'execution.runtime-mode' = 'batch';
-- 设置忽略NULL值
SET 'table.exec.sink.not-null-enforcer' = 'DROP';
-- 设置Paimon sink配置
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'jobmanager.memory.process.size' = '4096m';
SET 'taskmanager.memory.process.size' = '8192m';
SET 'taskmanager.memory.jvm-metaspace.size' = '512m';
SET 'taskmanager.memory.task.off-heap.size' = '1024m';
/* 创建Paimon Catalog */
CREATE CATALOG paimon_hive WITH (
    'type' = 'paimon',
    'metastore' = 'hive',
    'uri' = 'thrift://192.168.254.133:9083',
    'hive-conf-dir' = '/opt/software/apache-hive-3.1.3-bin/conf',
    'hadoop-conf-dir' = '/opt/software/hadoop-3.1.3/etc/hadoop',
    'warehouse' = 'hdfs:////user/hive/warehouse'
);

USE CATALOG paimon_hive;
CREATE DATABASE IF NOT EXISTS dwd;
USE dwd;

-- 鲸鱼交易明细表
CREATE TABLE IF NOT EXISTS dwd_whale_transaction_detail (
    tx_date DATE,
    tx_id VARCHAR(255),
    tx_hash VARCHAR(255),
    tx_timestamp TIMESTAMP,
    tx_week VARCHAR(20),
    tx_month VARCHAR(10),
    from_address VARCHAR(255),
    to_address VARCHAR(255),
    from_is_whale BOOLEAN,
    to_is_whale BOOLEAN,
    contract_address VARCHAR(255),
    collection_name VARCHAR(255),
    token_id VARCHAR(255),
    trade_price_eth DECIMAL(30,10),
    trade_price_usd DECIMAL(30,10),
    trade_symbol VARCHAR(50),
    floor_price_eth DECIMAL(30,10),
    profit_potential DECIMAL(30,10),
    event_type VARCHAR(50),
    platform VARCHAR(100),
    is_in_working_set BOOLEAN,
    data_source VARCHAR(50),
    is_deleted BOOLEAN,
    etl_time TIMESTAMP,
    PRIMARY KEY (tx_date, tx_id, contract_address, token_id) NOT ENFORCED
) WITH (
    'bucket' = '8',
    'bucket-key' = 'contract_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 插入数据
INSERT INTO dwd_whale_transaction_detail
SELECT
    TO_DATE(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT))) AS tx_date,
    t.nftscan_tx_id AS tx_id,
    t.hash AS tx_hash,
    CAST(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT)) AS TIMESTAMP(6)) AS tx_timestamp,
    CAST(DATE_FORMAT(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT)), 'YYYY-ww') AS VARCHAR(20)) AS tx_week,
    CAST(DATE_FORMAT(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT)), 'YYYY-MM') AS VARCHAR(10)) AS tx_month,
    t.from_address,
    t.to_address,
    CASE WHEN vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS from_is_whale,
    CASE WHEN vw2.account_address IS NOT NULL OR bw2.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS to_is_whale,
    t.contract_address,
    t.contract_name AS collection_name,
    t.token_id,
    CAST(t.trade_price AS DECIMAL(30,10)) AS trade_price_eth,
    CAST(t.trade_price * 2500.00 AS DECIMAL(30,10)) AS trade_price_usd, -- 使用固定汇率做示例，实际应从外部获取
    CAST(t.trade_symbol AS VARCHAR(50)) AS trade_symbol,
    CAST(COALESCE(c.floor_price, 0) AS DECIMAL(30,10)) AS floor_price_eth,
    CAST((t.trade_price - COALESCE(c.floor_price, 0)) AS DECIMAL(30,10)) AS profit_potential,
    CAST(t.event_type AS VARCHAR(50)) AS event_type,
    CAST(t.exchange_name AS VARCHAR(100)) AS platform,
    CASE WHEN cws.collection_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_in_working_set,
    CAST('ods_collection_transaction_inc' AS VARCHAR(50)) AS data_source,
    FALSE AS is_deleted,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP(6)) AS etl_time
FROM 
    ods.ods_collection_transaction_inc t
LEFT JOIN 
    ods.ods_daily_top30_volume_wallets vw ON t.from_address = vw.account_address 
LEFT JOIN 
    ods.ods_top100_balance_wallets bw ON t.from_address = bw.account_address 
LEFT JOIN 
    ods.ods_daily_top30_volume_wallets vw2 ON t.to_address = vw2.account_address 
LEFT JOIN 
    ods.ods_top100_balance_wallets bw2 ON t.to_address = bw2.account_address 
LEFT JOIN 
    ods.ods_collection_working_set cws ON t.contract_address = cws.collection_address
LEFT JOIN 
    (SELECT contract_address, floor_price, record_time 
     FROM ods.ods_daily_top30_volume_collections
     UNION 
     SELECT contract_address, floor_price, record_time 
     FROM ods.ods_daily_top30_transaction_collections) c 
    ON t.contract_address = c.contract_address 
    AND DATE_FORMAT(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT)), 'yyyy-MM-dd') = DATE_FORMAT(c.record_time, 'yyyy-MM-dd')
WHERE 
    t.trade_price > 0 -- 过滤无效交易
    -- 删除鲸鱼账户限制，先加载所有有效交易数据
    AND t.tx_timestamp > 0 -- 确保时间戳为正数
    AND t.tx_timestamp < 253402271999000 -- 排除过大的时间戳（2023年之后的8000年左右）
; 