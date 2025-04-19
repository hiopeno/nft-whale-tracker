-- 鲸鱼交易数据表

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

-- 添加重启策略配置
SET 'restart-strategy' = 'fixed-delay';
SET 'restart-strategy.fixed-delay.attempts' = '3';
SET 'restart-strategy.fixed-delay.delay' = '10s';

-- 优化资源配置
SET 'jobmanager.memory.process.size' = '2g';
SET 'taskmanager.memory.process.size' = '4g';
SET 'taskmanager.numberOfTaskSlots' = '2';

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
CREATE DATABASE IF NOT EXISTS ads;
USE ads;

-- 创建鲸鱼交易数据表
CREATE TABLE IF NOT EXISTS ads_whale_transactions (
    -- 主键部分
    snapshot_date DATE,                              -- 快照日期
    tx_hash VARCHAR(255),                            -- 交易哈希
    contract_address VARCHAR(255),                   -- NFT合约地址
    token_id VARCHAR(255),                           -- NFT代币ID
    
    -- 时间维度
    tx_timestamp TIMESTAMP,                          -- 交易发生时间戳
    
    -- 交易方信息
    from_address VARCHAR(255),                       -- 卖方钱包地址
    to_address VARCHAR(255),                         -- 买方钱包地址
    from_whale_type VARCHAR(50),                     -- 卖方鲸鱼类型(SMART/DUMB/TRACKING/NO_WHALE)
    to_whale_type VARCHAR(50),                       -- 买方鲸鱼类型(SMART/DUMB/TRACKING/NO_WHALE)
    from_influence_score DECIMAL(10,2),              -- 卖方影响力评分
    to_influence_score DECIMAL(10,2),                -- 买方影响力评分
    
    -- 收藏集信息
    collection_name VARCHAR(255),                    -- 收藏集名称
    
    -- 交易详情
    trade_price_eth DECIMAL(30,10),                  -- 交易价格(ETH)
    trade_price_usd DECIMAL(30,10),                  -- 交易价格(USD)
    floor_price_eth DECIMAL(30,10),                  -- 交易时地板价(ETH)
    price_to_floor_ratio DECIMAL(10,2),              -- 价格/地板价比率
    
    -- 平台信息
    marketplace VARCHAR(100),                        -- 交易平台
    
    -- 数据源和处理时间
    data_source VARCHAR(255),                        -- 数据来源
    etl_time TIMESTAMP,                              -- ETL处理时间
    
    PRIMARY KEY (snapshot_date, tx_hash, contract_address, token_id) NOT ENFORCED
) WITH (
    'bucket' = '8',
    'bucket-key' = 'contract_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '100',
    'compaction.target-file-size' = '128MB'
);

-- 创建临时视图，关联鲸鱼钱包数据
CREATE TEMPORARY VIEW IF NOT EXISTS tmp_whale_info AS
SELECT 
    dwa.wallet_address,
    dwa.whale_type,
    CAST(COALESCE(dws.influence_score, 50) AS DECIMAL(10,2)) AS influence_score
FROM 
    dim.dim_whale_address dwa
LEFT JOIN
    dws.dws_whale_daily_stats dws ON dwa.wallet_address = dws.wallet_address 
    AND dws.stat_date = CURRENT_DATE
WHERE 
    dwa.status = 'ACTIVE'
    AND dwa.is_whale = TRUE;

-- 查询DWS层收藏集数据获取地板价
CREATE TEMPORARY VIEW IF NOT EXISTS tmp_collection_info AS
SELECT 
    c.contract_address,
    CAST(COALESCE(c.floor_price_eth, 0) AS DECIMAL(30,10)) AS floor_price_eth
FROM 
    dws.dws_collection_daily_stats c
WHERE 
    c.collection_date = CURRENT_DATE;

-- 插入数据到目标表
INSERT INTO ads_whale_transactions
SELECT 
    -- 主键
    CURRENT_DATE AS snapshot_date,
    t.tx_hash,
    t.contract_address,
    t.token_id,
    
    -- 时间维度
    t.tx_timestamp,
    
    -- 交易方信息
    t.from_address,
    t.to_address,
    COALESCE(from_whale.whale_type, 'NO_WHALE') AS from_whale_type,
    COALESCE(to_whale.whale_type, 'NO_WHALE') AS to_whale_type,
    CAST(COALESCE(from_whale.influence_score, 0) AS DECIMAL(10,2)) AS from_influence_score,
    CAST(COALESCE(to_whale.influence_score, 0) AS DECIMAL(10,2)) AS to_influence_score,
    
    -- 收藏集信息
    t.collection_name,
    
    -- 交易详情
    t.trade_price_eth,
    t.trade_price_usd,
    COALESCE(c.floor_price_eth, CAST(0 AS DECIMAL(30,10))) AS floor_price_eth,
    CASE 
        WHEN COALESCE(c.floor_price_eth, 0) > 0 THEN CAST(t.trade_price_eth / c.floor_price_eth AS DECIMAL(10,2))
        ELSE CAST(0 AS DECIMAL(10,2))
    END AS price_to_floor_ratio,
    
    -- 平台信息
    t.platform AS marketplace,
    
    -- 数据源和处理时间
    'dwd_whale_transaction_detail,dim_whale_address,dws_collection_daily_stats' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dwd.dwd_whale_transaction_detail t
    LEFT JOIN tmp_whale_info from_whale ON t.from_address = from_whale.wallet_address
    LEFT JOIN tmp_whale_info to_whale ON t.to_address = to_whale.wallet_address
    LEFT JOIN tmp_collection_info c ON t.contract_address = c.contract_address
WHERE 
    -- 筛选鲸鱼相关交易
    (t.from_is_whale = TRUE OR t.to_is_whale = TRUE)
    -- 只处理最近两周的数据
    AND t.tx_date BETWEEN CURRENT_DATE - INTERVAL '14' DAY AND CURRENT_DATE;

-- 删除临时视图
DROP TEMPORARY VIEW IF EXISTS tmp_whale_info;
DROP TEMPORARY VIEW IF EXISTS tmp_collection_info; 