-- 交易清洗明细数据 - DWD层重构

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

-- 交易清洗明细表
-- 该表包含所有清洗后的交易数据，不限于鲸鱼交易
--DROP TABLE IF EXISTS dwd_transaction_clean;

CREATE TABLE IF NOT EXISTS dwd_transaction_clean (
    tx_date DATE,                           -- 交易日期
    tx_id VARCHAR(255),                     -- 交易ID
    tx_hash VARCHAR(255),                   -- 交易哈希
    tx_timestamp TIMESTAMP,                 -- 交易时间戳
    from_address VARCHAR(255),              -- 卖方地址
    to_address VARCHAR(255),                -- 买方地址
    contract_address VARCHAR(255),          -- NFT合约地址
    collection_name VARCHAR(255),           -- 收藏集名称
    token_id VARCHAR(255),                  -- NFT代币ID
    trade_price_eth DECIMAL(30,10),         -- 交易价格(ETH)
    trade_price_usd DECIMAL(30,10),         -- 交易价格(USD)
    trade_symbol VARCHAR(50),               -- 交易代币符号
    event_type VARCHAR(50),                 -- 事件类型
    platform VARCHAR(100),                  -- 交易平台
    is_in_working_set BOOLEAN,              -- 是否属于工作集
    etl_time TIMESTAMP,                     -- ETL处理时间
    PRIMARY KEY (tx_date, tx_id, contract_address) NOT ENFORCED
) WITH (
    'bucket' = '10',
    'bucket-key' = 'contract_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 插入数据
INSERT INTO dwd_transaction_clean
SELECT
    TO_DATE(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT))) AS tx_date,
    t.nftscan_tx_id AS tx_id,
    t.hash AS tx_hash,
    CAST(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT)) AS TIMESTAMP(6)) AS tx_timestamp,
    t.from_address,
    t.to_address,
    t.contract_address,
    t.contract_name AS collection_name,
    t.token_id,
    CAST(t.trade_price AS DECIMAL(30,10)) AS trade_price_eth,
    CAST(t.trade_price * 2500.00 AS DECIMAL(30,10)) AS trade_price_usd, -- 使用固定汇率做示例，实际应从外部获取
    CAST(t.trade_symbol AS VARCHAR(50)) AS trade_symbol,
    CAST(t.event_type AS VARCHAR(50)) AS event_type,
    CAST(t.exchange_name AS VARCHAR(100)) AS platform,
    CASE WHEN cws.collection_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_in_working_set,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP(6)) AS etl_time
FROM 
    ods.ods_collection_transaction_inc t
LEFT JOIN 
    ods.ods_collection_working_set cws ON t.contract_address = cws.collection_address
WHERE 
    t.trade_price > 0 -- 过滤无效交易
    AND t.tx_timestamp > 0 -- 确保时间戳为正数
    AND t.tx_timestamp < 253402271999000 -- 排除过大的时间戳（2023年之后的8000年左右）
; 