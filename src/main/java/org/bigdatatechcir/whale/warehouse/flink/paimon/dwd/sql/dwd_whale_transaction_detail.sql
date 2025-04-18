-- 鲸鱼交易明细数据 - DWD层重构

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

-- 鲸鱼交易明细表 - 重构版
-- 该表专注于鲸鱼相关交易，移除了计算字段和管理字段
--DROP TABLE IF EXISTS dwd_whale_transaction_detail;

CREATE TABLE IF NOT EXISTS dwd_whale_transaction_detail (
    tx_date DATE,                           -- 交易日期
    tx_id VARCHAR(255),                     -- 交易ID
    tx_hash VARCHAR(255),                   -- 交易哈希
    tx_timestamp TIMESTAMP,                 -- 交易时间戳
    from_address VARCHAR(255),              -- 卖方地址
    to_address VARCHAR(255),                -- 买方地址
    from_is_whale BOOLEAN,                  -- 卖方是否鲸鱼
    to_is_whale BOOLEAN,                    -- 买方是否鲸鱼
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

-- 插入数据：从交易清洗表关联鲸鱼信息
INSERT INTO dwd_whale_transaction_detail
SELECT
    t.tx_date,
    t.tx_id,
    t.tx_hash,
    t.tx_timestamp,
    t.from_address,
    t.to_address,
    CASE WHEN vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS from_is_whale,
    CASE WHEN vw2.account_address IS NOT NULL OR bw2.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS to_is_whale,
    t.contract_address,
    t.collection_name,
    t.token_id,
    t.trade_price_eth,
    t.trade_price_usd,
    t.trade_symbol,
    t.event_type,
    t.platform,
    t.is_in_working_set,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dwd_transaction_clean t
LEFT JOIN 
    ods.ods_daily_top30_volume_wallets vw ON t.from_address = vw.account_address 
 --   AND CAST(t.tx_date AS VARCHAR) = vw.rank_date
LEFT JOIN 
    ods.ods_top100_balance_wallets bw ON t.from_address = bw.account_address 
--    AND CAST(t.tx_date AS VARCHAR) = bw.rank_date
LEFT JOIN 
    ods.ods_daily_top30_volume_wallets vw2 ON t.to_address = vw2.account_address 
--    AND CAST(t.tx_date AS VARCHAR) = vw2.rank_date
LEFT JOIN 
    ods.ods_top100_balance_wallets bw2 ON t.to_address = bw2.account_address 
--    AND CAST(t.tx_date AS VARCHAR) = bw2.rank_date
WHERE 
    -- 至少有一方是鲸鱼
    (vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL OR 
     vw2.account_address IS NOT NULL OR bw2.account_address IS NOT NULL); 