-- 收藏集每日统计表 - 从DWD层迁移到DWS层

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
CREATE DATABASE IF NOT EXISTS dws;
USE dws;

-- 创建收藏集每日统计表
CREATE TABLE IF NOT EXISTS dws_collection_daily_stats (
    collection_date DATE,                   -- 统计日期
    contract_address VARCHAR(255),          -- NFT合约地址
    collection_name VARCHAR(255),           -- 收藏集名称
    sales_count INT,                        -- 当日销售数量
    volume_eth DECIMAL(30,10),              -- 当日交易额(ETH)
    volume_usd DECIMAL(30,10),              -- 当日交易额(USD)
    avg_price_eth DECIMAL(30,10),           -- 当日平均价格(ETH)
    min_price_eth DECIMAL(30,10),           -- 当日最低价格(ETH)
    max_price_eth DECIMAL(30,10),           -- 当日最高价格(ETH)
    floor_price_eth DECIMAL(30,10),         -- 当日地板价(ETH)
    unique_buyers INT,                      -- 唯一买家数量
    unique_sellers INT,                     -- 唯一卖家数量
    whale_buyers INT,                       -- 鲸鱼买家数量
    whale_sellers INT,                      -- 鲸鱼卖家数量
    whale_volume_eth DECIMAL(30,10),        -- 鲸鱼交易额(ETH)
    whale_percentage DECIMAL(10,2),         -- 鲸鱼交易额占比
    sales_change_1d DECIMAL(10,2),          -- 销售数量1日环比
    volume_change_1d DECIMAL(10,2),         -- 交易额1日环比
    price_change_1d DECIMAL(10,2),          -- 均价1日环比
    is_in_working_set BOOLEAN,              -- 是否属于工作集
    rank_by_volume INT,                     -- 按交易额排名
    rank_by_sales INT,                      -- 按销售量排名
    is_top30_volume BOOLEAN,                -- 是否交易额Top30
    is_top30_sales BOOLEAN,                 -- 是否销售量Top30
    data_source VARCHAR(100),               -- 数据来源
    etl_time TIMESTAMP,                     -- ETL处理时间
    PRIMARY KEY (collection_date, contract_address) NOT ENFORCED
) WITH (
    'bucket' = '10',
    'bucket-key' = 'contract_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'lookup',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 计算收藏集每日统计数据
INSERT INTO dws_collection_daily_stats
WITH floor_prices AS (
    -- 获取地板价子查询（当日最后一笔交易的价格作为地板价）
    SELECT 
        tx_date,
        contract_address,
        -- 对于每个收藏集，选择交易时间最晚的那条记录的价格作为地板价
        MAX(trade_price_eth) AS floor_price_eth
    FROM (
        SELECT 
            tx_date,
            contract_address,
            trade_price_eth,
            ROW_NUMBER() OVER (PARTITION BY tx_date, contract_address ORDER BY tx_timestamp DESC) AS rn
        FROM 
            dwd.dwd_transaction_clean
    ) ranked
    WHERE rn = 1
    GROUP BY 
        tx_date,
        contract_address
),
daily_stats AS (
    -- 基础交易统计
    SELECT 
        tx_date AS collection_date,
        contract_address,
        MAX(collection_name) AS collection_name,
        CAST(COUNT(*) AS INT) AS sales_count,
        SUM(trade_price_eth) AS volume_eth,
        SUM(trade_price_usd) AS volume_usd,
        AVG(trade_price_eth) AS avg_price_eth,
        MIN(trade_price_eth) AS min_price_eth,
        MAX(trade_price_eth) AS max_price_eth,
        CAST(COUNT(DISTINCT to_address) AS INT) AS unique_buyers,
        CAST(COUNT(DISTINCT from_address) AS INT) AS unique_sellers,
        MAX(is_in_working_set) AS is_in_working_set
    FROM 
        dwd.dwd_transaction_clean
    GROUP BY 
        tx_date,
        contract_address
),
whale_stats AS (
    -- 鲸鱼相关统计
    SELECT 
        tx_date AS collection_date,
        contract_address,
        CAST(COUNT(DISTINCT CASE WHEN to_is_whale THEN to_address END) AS INT) AS whale_buyers,
        CAST(COUNT(DISTINCT CASE WHEN from_is_whale THEN from_address END) AS INT) AS whale_sellers,
        SUM(CASE WHEN to_is_whale OR from_is_whale THEN trade_price_eth ELSE 0 END) AS whale_volume_eth
    FROM 
        dwd.dwd_whale_transaction_detail
    GROUP BY 
        tx_date,
        contract_address
),
prev_day_stats AS (
    -- 获取前一天的统计数据，用于计算环比
    SELECT 
        collection_date,
        contract_address,
        sales_count,
        volume_eth,
        avg_price_eth
    FROM 
        dws_collection_daily_stats
),
rankings AS (
    -- 计算排名
    SELECT 
        collection_date,
        contract_address,
        CAST(ROW_NUMBER() OVER (PARTITION BY collection_date ORDER BY volume_eth DESC) AS INT) AS rank_by_volume,
        CAST(ROW_NUMBER() OVER (PARTITION BY collection_date ORDER BY sales_count DESC) AS INT) AS rank_by_sales
    FROM 
        daily_stats
)
SELECT 
    d.collection_date,
    d.contract_address,
    d.collection_name,
    d.sales_count,
    d.volume_eth,
    d.volume_usd,
    d.avg_price_eth,
    d.min_price_eth,
    d.max_price_eth,
    COALESCE(f.floor_price_eth, d.min_price_eth) AS floor_price_eth,
    d.unique_buyers,
    d.unique_sellers,
    COALESCE(w.whale_buyers, 0) AS whale_buyers,
    COALESCE(w.whale_sellers, 0) AS whale_sellers,
    COALESCE(w.whale_volume_eth, 0) AS whale_volume_eth,
    CASE 
        WHEN d.volume_eth > 0 
        THEN (COALESCE(w.whale_volume_eth, 0) / d.volume_eth) * 100 
        ELSE 0 
    END AS whale_percentage,
    -- 环比计算
    CASE 
        WHEN p.sales_count > 0 
        THEN ((d.sales_count - p.sales_count) / p.sales_count) * 100 
        ELSE 0 
    END AS sales_change_1d,
    CASE 
        WHEN p.volume_eth > 0 
        THEN ((d.volume_eth - p.volume_eth) / p.volume_eth) * 100 
        ELSE 0 
    END AS volume_change_1d,
    CASE 
        WHEN p.avg_price_eth > 0 
        THEN ((d.avg_price_eth - p.avg_price_eth) / p.avg_price_eth) * 100 
        ELSE 0 
    END AS price_change_1d,
    d.is_in_working_set,
    r.rank_by_volume,
    r.rank_by_sales,
    CASE WHEN r.rank_by_volume <= 30 THEN TRUE ELSE FALSE END AS is_top30_volume,
    CASE WHEN r.rank_by_sales <= 30 THEN TRUE ELSE FALSE END AS is_top30_sales,
    'dwd_transaction_clean,dwd_whale_transaction_detail' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    daily_stats d
LEFT JOIN 
    floor_prices f ON d.collection_date = f.tx_date AND d.contract_address = f.contract_address
LEFT JOIN 
    whale_stats w ON d.collection_date = w.collection_date AND d.contract_address = w.contract_address
LEFT JOIN 
    prev_day_stats p ON TIMESTAMPADD(DAY, 1, p.collection_date) = d.collection_date AND p.contract_address = d.contract_address
LEFT JOIN 
    rankings r ON d.collection_date = r.collection_date AND d.contract_address = r.contract_address
WHERE 
    d.collection_date = CURRENT_DATE; 