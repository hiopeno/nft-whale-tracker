-- 收藏集每日统计数据

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
CREATE DATABASE IF NOT EXISTS dwd;
USE dwd;

-- 收藏集每日统计表
CREATE TABLE IF NOT EXISTS dwd_collection_daily_stats (
    collection_date DATE,
    contract_address VARCHAR(255),
    collection_name VARCHAR(255),
    sales_count INT,
    volume_eth DECIMAL(30,10),
    volume_usd DECIMAL(30,10),
    avg_price_eth DECIMAL(30,10),
    min_price_eth DECIMAL(30,10),
    max_price_eth DECIMAL(30,10),
    floor_price_eth DECIMAL(30,10),
    unique_buyers INT,
    unique_sellers INT,
    whale_buyers INT,
    whale_sellers INT,
    whale_volume_eth DECIMAL(30,10),
    whale_percentage DECIMAL(10,2),
    sales_change_1d DECIMAL(10,2),
    volume_change_1d DECIMAL(10,2),
    price_change_1d DECIMAL(10,2),
    is_in_working_set BOOLEAN,
    rank_by_volume INT,
    rank_by_sales INT,
    is_top30_volume BOOLEAN,
    is_top30_sales BOOLEAN,
    data_source VARCHAR(100),
    etl_time TIMESTAMP,
    PRIMARY KEY (collection_date, contract_address) NOT ENFORCED
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
INSERT INTO dwd_collection_daily_stats
WITH base_stats AS (
    SELECT 
        TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))) AS collection_date,
        contract_address,
        contract_name,
        COUNT(*) AS sales_count,
        SUM(trade_price) AS volume_eth,
        SUM(trade_price * 2500.00) AS volume_usd,
        AVG(trade_price) AS avg_price_eth,
        MIN(trade_price) AS min_price_eth,
        MAX(trade_price) AS max_price_eth,
        COUNT(DISTINCT to_address) AS unique_buyers,
        COUNT(DISTINCT from_address) AS unique_sellers
    FROM 
        ods.ods_collection_transaction_inc
    WHERE 
        trade_price > 0
        AND tx_timestamp > 0 -- 确保时间戳为正数
        AND tx_timestamp < 253402271999000 -- 排除过大的时间戳（2023年之后的8000年左右）
        AND event_type = 'Sale' -- 只统计Sale类型的交易
    GROUP BY 
        TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))),
        contract_address,
        contract_name
),
whale_stats AS (
    SELECT 
        tx_date AS collection_date,
        contract_address,
        COUNT(DISTINCT CASE WHEN to_is_whale THEN to_address END) AS whale_buyers,
        COUNT(DISTINCT CASE WHEN from_is_whale THEN from_address END) AS whale_sellers,
        SUM(CASE WHEN to_is_whale OR from_is_whale THEN trade_price_eth ELSE 0 END) AS whale_volume_eth
    FROM 
        dwd_whale_transaction_detail
    WHERE
        event_type = 'Sale' -- 只统计Sale类型的交易
    GROUP BY 
        tx_date,
        contract_address
),
previous_day AS (
    SELECT 
        TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))) AS prev_date,
        TO_DATE(DATE_FORMAT(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT) + 86400), 'yyyy-MM-dd')) AS collection_date,
        contract_address,
        COUNT(*) AS prev_sales_count,
        SUM(trade_price) AS prev_volume_eth,
        AVG(trade_price) AS prev_avg_price_eth
    FROM 
        ods.ods_collection_transaction_inc
    WHERE 
        trade_price > 0
        AND event_type = 'Sale' -- 只统计Sale类型的交易
    GROUP BY 
        TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))),
        TO_DATE(DATE_FORMAT(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT) + 86400), 'yyyy-MM-dd')),
        contract_address
),
-- 使用窗口函数高效计算排名
rank_data AS (
    SELECT 
        collection_date,
        contract_address,
        RANK() OVER (PARTITION BY collection_date ORDER BY volume_eth DESC) AS rank_by_volume,
        RANK() OVER (PARTITION BY collection_date ORDER BY sales_count DESC) AS rank_by_sales
    FROM 
        base_stats
)
SELECT 
    bs.collection_date,
    bs.contract_address,
    bs.contract_name AS collection_name,
    CAST(bs.sales_count AS INT) AS sales_count,
    CAST(bs.volume_eth AS DECIMAL(30,10)) AS volume_eth,
    CAST(bs.volume_usd AS DECIMAL(30,10)) AS volume_usd,
    CAST(bs.avg_price_eth AS DECIMAL(30,10)) AS avg_price_eth,
    bs.min_price_eth,
    bs.max_price_eth,
    COALESCE(c.floor_price, 0) AS floor_price_eth,
    CAST(bs.unique_buyers AS INT) AS unique_buyers,
    CAST(bs.unique_sellers AS INT) AS unique_sellers,
    CAST(COALESCE(ws.whale_buyers, 0) AS INT) AS whale_buyers,
    CAST(COALESCE(ws.whale_sellers, 0) AS INT) AS whale_sellers,
    CAST(COALESCE(ws.whale_volume_eth, 0) AS DECIMAL(30,10)) AS whale_volume_eth,
    CAST(CASE 
        WHEN (bs.unique_buyers + bs.unique_sellers) > 0 
        THEN ((COALESCE(ws.whale_buyers, 0) + COALESCE(ws.whale_sellers, 0)) * 100.0) / (bs.unique_buyers + bs.unique_sellers)
        ELSE 0 
    END AS DECIMAL(10,2)) AS whale_percentage,
    CAST(CASE 
        WHEN pd.prev_sales_count > 0 THEN ((bs.sales_count - pd.prev_sales_count) / pd.prev_sales_count) * 100
        ELSE 0
    END AS DECIMAL(10,2)) AS sales_change_1d,
    CAST(CASE 
        WHEN pd.prev_volume_eth > 0 THEN ((bs.volume_eth - pd.prev_volume_eth) / pd.prev_volume_eth) * 100
        ELSE 0
    END AS DECIMAL(10,2)) AS volume_change_1d,
    CAST(CASE 
        WHEN pd.prev_avg_price_eth > 0 THEN ((bs.avg_price_eth - pd.prev_avg_price_eth) / pd.prev_avg_price_eth) * 100
        ELSE 0
    END AS DECIMAL(10,2)) AS price_change_1d,
    CASE WHEN cws.collection_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_in_working_set,
    CAST(rd.rank_by_volume AS INT) AS rank_by_volume,
    CAST(rd.rank_by_sales AS INT) AS rank_by_sales,
    CASE WHEN rd.rank_by_volume <= 30 THEN TRUE ELSE FALSE END AS is_top30_volume,
    CASE WHEN rd.rank_by_sales <= 30 THEN TRUE ELSE FALSE END AS is_top30_sales,
    CAST('ods_collection_transaction_inc,ods_daily_top30_volume_collections' AS VARCHAR(100)) AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    base_stats bs
LEFT JOIN 
    whale_stats ws ON bs.collection_date = ws.collection_date AND bs.contract_address = ws.contract_address
LEFT JOIN 
    previous_day pd ON bs.collection_date = pd.collection_date AND bs.contract_address = pd.contract_address
LEFT JOIN 
    rank_data rd ON bs.collection_date = rd.collection_date AND bs.contract_address = rd.contract_address
LEFT JOIN 
    ods.ods_collection_working_set cws ON bs.contract_address = cws.collection_address
LEFT JOIN 
    (
        SELECT contract_address, floor_price, TO_DATE(DATE_FORMAT(record_time, 'yyyy-MM-dd')) AS record_date
        FROM ods.ods_daily_top30_volume_collections
        UNION
        SELECT contract_address, floor_price, TO_DATE(DATE_FORMAT(record_time, 'yyyy-MM-dd')) AS record_date
        FROM ods.ods_daily_top30_transaction_collections
    ) c ON bs.collection_date = c.record_date AND bs.contract_address = c.contract_address
WHERE 
    bs.collection_date IS NOT NULL
    AND bs.contract_address IS NOT NULL; 