-- 聪明鲸鱼净流入/流出Top10表

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

-- 创建聪明鲸鱼净流入/流出Top10表
CREATE TABLE IF NOT EXISTS ads_smart_whale_collection_flow (
    snapshot_date DATE,
    collection_address VARCHAR(255),
    collection_name VARCHAR(255),
    flow_direction VARCHAR(20),
    rank_num INT,
    smart_whale_net_flow_eth DECIMAL(30,10),
    smart_whale_net_flow_usd DECIMAL(30,10),
    smart_whale_net_flow_7d_eth DECIMAL(30,10),
    smart_whale_net_flow_30d_eth DECIMAL(30,10),
    smart_whale_buyers INT,
    smart_whale_sellers INT,
    smart_whale_buy_volume_eth DECIMAL(30,10),
    smart_whale_sell_volume_eth DECIMAL(30,10),
    smart_whale_trading_percentage DECIMAL(10,2),
    floor_price_eth DECIMAL(30,10),
    floor_price_change_1d DECIMAL(10,2),
    trend_indicator VARCHAR(50),
    data_source VARCHAR(100),
    etl_time TIMESTAMP,
    PRIMARY KEY (snapshot_date, collection_address, flow_direction) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'bucket-key' = 'collection_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '3',
    'compaction.max.file-num' = '30',
    'compaction.target-file-size' = '128MB'
);

-- 计算并更新聪明鲸鱼净流入/流出Top10
INSERT INTO ads_smart_whale_collection_flow
WITH inflow_collections AS (
    -- 计算净流入Top10
    SELECT 
        CURRENT_DATE AS snapshot_date,
        cf.collection_address,
        MAX(cf.collection_name) AS collection_name,
        'INFLOW' AS flow_direction,
        ROW_NUMBER() OVER (ORDER BY SUM(cf.net_flow_eth) DESC) AS rank_num,
        SUM(cf.net_flow_eth) AS smart_whale_net_flow_eth,
        SUM(cf.net_flow_eth) * 2500.00 AS smart_whale_net_flow_usd, -- 示例USD汇率
        COALESCE(SUM(cf.accu_net_flow_7d), CAST(0 AS DECIMAL(30,10))) AS smart_whale_net_flow_7d_eth,
        COALESCE(SUM(cf.accu_net_flow_30d), CAST(0 AS DECIMAL(30,10))) AS smart_whale_net_flow_30d_eth,
        CASE 
            WHEN COUNT(cf.floor_price_eth) > 0 
            THEN CAST(SUM(cf.floor_price_eth) / COUNT(cf.floor_price_eth) AS DECIMAL(30,10)) 
            ELSE CAST(0 AS DECIMAL(30,10)) 
        END AS floor_price_eth,
        CAST(0 AS DECIMAL(10,2)) AS floor_price_change_1d, -- 需要其他数据源
        SUM(cf.unique_whale_buyers) AS smart_whale_buyers,
        SUM(cf.unique_whale_sellers) AS smart_whale_sellers,
        SUM(cf.whale_buy_volume_eth) AS smart_whale_buy_volume_eth,
        SUM(cf.whale_sell_volume_eth) AS smart_whale_sell_volume_eth,
        CASE 
            WHEN COUNT(cf.whale_trading_percentage) > 0 
            THEN CAST(SUM(cf.whale_trading_percentage) / COUNT(cf.whale_trading_percentage) AS DECIMAL(10,2)) 
            ELSE CAST(0 AS DECIMAL(10,2)) 
        END AS smart_whale_trading_percentage,
        CASE 
            WHEN SUM(cf.net_flow_eth) > 10 THEN 'STRONG_INFLOW'
            WHEN SUM(cf.net_flow_eth) > 5 THEN 'MODERATE_INFLOW'
            ELSE 'SLIGHT_INFLOW'
        END AS trend_indicator
    FROM 
        dws.dws_collection_whale_flow cf
    WHERE 
        -- 暂时去除日期限制
        -- cf.stat_date = CURRENT_DATE
        cf.whale_type = 'SMART'
    GROUP BY 
        cf.collection_address
    HAVING 
        SUM(cf.net_flow_eth) > 0
),
outflow_collections AS (
    -- 计算净流出Top10
    SELECT 
        CURRENT_DATE AS snapshot_date,
        cf.collection_address,
        MAX(cf.collection_name) AS collection_name,
        'OUTFLOW' AS flow_direction,
        ROW_NUMBER() OVER (ORDER BY SUM(cf.net_flow_eth) ASC) AS rank_num,
        SUM(cf.net_flow_eth) AS smart_whale_net_flow_eth,
        SUM(cf.net_flow_eth) * 2500.00 AS smart_whale_net_flow_usd, -- 示例USD汇率
        COALESCE(SUM(cf.accu_net_flow_7d), CAST(0 AS DECIMAL(30,10))) AS smart_whale_net_flow_7d_eth,
        COALESCE(SUM(cf.accu_net_flow_30d), CAST(0 AS DECIMAL(30,10))) AS smart_whale_net_flow_30d_eth,
        CASE 
            WHEN COUNT(cf.floor_price_eth) > 0 
            THEN CAST(SUM(cf.floor_price_eth) / COUNT(cf.floor_price_eth) AS DECIMAL(30,10)) 
            ELSE CAST(0 AS DECIMAL(30,10)) 
        END AS floor_price_eth,
        CAST(0 AS DECIMAL(10,2)) AS floor_price_change_1d, -- 需要其他数据源
        SUM(cf.unique_whale_buyers) AS smart_whale_buyers,
        SUM(cf.unique_whale_sellers) AS smart_whale_sellers,
        SUM(cf.whale_buy_volume_eth) AS smart_whale_buy_volume_eth,
        SUM(cf.whale_sell_volume_eth) AS smart_whale_sell_volume_eth,
        CASE 
            WHEN COUNT(cf.whale_trading_percentage) > 0 
            THEN CAST(SUM(cf.whale_trading_percentage) / COUNT(cf.whale_trading_percentage) AS DECIMAL(10,2)) 
            ELSE CAST(0 AS DECIMAL(10,2)) 
        END AS smart_whale_trading_percentage,
        CASE 
            WHEN SUM(cf.net_flow_eth) < -10 THEN 'STRONG_OUTFLOW'
            WHEN SUM(cf.net_flow_eth) < -5 THEN 'MODERATE_OUTFLOW'
            ELSE 'SLIGHT_OUTFLOW'
        END AS trend_indicator
    FROM 
        dws.dws_collection_whale_flow cf
    WHERE 
        -- 暂时去除日期限制
        -- cf.stat_date = CURRENT_DATE
        cf.whale_type = 'SMART'
    GROUP BY 
        cf.collection_address
    HAVING 
        SUM(cf.net_flow_eth) < 0
)
SELECT 
    snapshot_date,
    collection_address,
    collection_name,
    flow_direction,
    CAST(rank_num AS INT) AS rank_num,
    smart_whale_net_flow_eth,
    smart_whale_net_flow_usd,
    smart_whale_net_flow_7d_eth,
    smart_whale_net_flow_30d_eth,
    CAST(smart_whale_buyers AS INT) AS smart_whale_buyers,
    CAST(smart_whale_sellers AS INT) AS smart_whale_sellers,
    smart_whale_buy_volume_eth,
    smart_whale_sell_volume_eth,
    smart_whale_trading_percentage,
    floor_price_eth,
    floor_price_change_1d,
    trend_indicator,
    'dws_collection_whale_flow' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    inflow_collections
WHERE 
    rank_num <= 10

UNION ALL

SELECT 
    snapshot_date,
    collection_address,
    collection_name,
    flow_direction,
    CAST(rank_num AS INT) AS rank_num,
    smart_whale_net_flow_eth,
    smart_whale_net_flow_usd,
    smart_whale_net_flow_7d_eth,
    smart_whale_net_flow_30d_eth,
    CAST(smart_whale_buyers AS INT) AS smart_whale_buyers,
    CAST(smart_whale_sellers AS INT) AS smart_whale_sellers,
    smart_whale_buy_volume_eth,
    smart_whale_sell_volume_eth,
    smart_whale_trading_percentage,
    floor_price_eth,
    floor_price_change_1d,
    trend_indicator,
    'dws_collection_whale_flow' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    outflow_collections
WHERE 
    rank_num <= 10; 