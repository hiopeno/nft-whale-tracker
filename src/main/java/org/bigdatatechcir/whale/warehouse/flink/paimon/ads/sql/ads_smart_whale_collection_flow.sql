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
    logo_url VARCHAR(500),                           -- 收藏集logo URL
    flow_direction VARCHAR(20),
    rank_timerange VARCHAR(10),    -- 新增字段，表示排名周期：DAY, 7DAYS, 30DAYS
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
    PRIMARY KEY (snapshot_date, collection_address, flow_direction, rank_timerange) NOT ENFORCED
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
WITH collection_logo_info AS (
    -- 获取收藏集Logo信息
    SELECT 
        collection_address,
        logo_url
    FROM 
        dim.dim_collection_info
),
base_collection_stats AS (
    -- 基础统计数据
    SELECT 
        cf.collection_address,
        MAX(cf.collection_name) AS collection_name,
        SUM(cf.net_flow_eth) AS daily_net_flow_eth,
        COALESCE(SUM(cf.accu_net_flow_7d), CAST(0 AS DECIMAL(30,10))) AS net_flow_7d_eth,
        COALESCE(SUM(cf.accu_net_flow_30d), CAST(0 AS DECIMAL(30,10))) AS net_flow_30d_eth,
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
        END AS smart_whale_trading_percentage
    FROM 
        dws.dws_collection_whale_flow cf
    WHERE 
        cf.whale_type = 'SMART'
    GROUP BY 
        cf.collection_address
),
-- 每日流入排名
daily_inflow_collections AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        bcs.collection_address,
        bcs.collection_name,
        CAST('INFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('DAY' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY bcs.daily_net_flow_eth DESC) AS INT) AS rank_num,
        bcs.daily_net_flow_eth AS smart_whale_net_flow_eth,
        bcs.daily_net_flow_eth * 2500.00 AS smart_whale_net_flow_usd,
        bcs.net_flow_7d_eth AS smart_whale_net_flow_7d_eth,
        bcs.net_flow_30d_eth AS smart_whale_net_flow_30d_eth,
        bcs.floor_price_eth,
        bcs.floor_price_change_1d,
        bcs.smart_whale_buyers,
        bcs.smart_whale_sellers,
        bcs.smart_whale_buy_volume_eth,
        bcs.smart_whale_sell_volume_eth,
        bcs.smart_whale_trading_percentage,
        CASE 
            WHEN bcs.daily_net_flow_eth > 10 THEN 'STRONG_INFLOW'
            WHEN bcs.daily_net_flow_eth > 5 THEN 'MODERATE_INFLOW'
            ELSE 'SLIGHT_INFLOW'
        END AS trend_indicator
    FROM 
        base_collection_stats bcs
    WHERE 
        bcs.daily_net_flow_eth >= 0
),
-- 每日流出排名
daily_outflow_collections AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        bcs.collection_address,
        bcs.collection_name,
        CAST('OUTFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('DAY' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY bcs.daily_net_flow_eth ASC) AS INT) AS rank_num,
        bcs.daily_net_flow_eth AS smart_whale_net_flow_eth,
        bcs.daily_net_flow_eth * 2500.00 AS smart_whale_net_flow_usd,
        bcs.net_flow_7d_eth AS smart_whale_net_flow_7d_eth,
        bcs.net_flow_30d_eth AS smart_whale_net_flow_30d_eth,
        bcs.floor_price_eth,
        bcs.floor_price_change_1d,
        bcs.smart_whale_buyers,
        bcs.smart_whale_sellers,
        bcs.smart_whale_buy_volume_eth,
        bcs.smart_whale_sell_volume_eth,
        bcs.smart_whale_trading_percentage,
        CASE 
            WHEN bcs.daily_net_flow_eth < -10 THEN 'STRONG_OUTFLOW'
            WHEN bcs.daily_net_flow_eth < -5 THEN 'MODERATE_OUTFLOW'
            ELSE 'SLIGHT_OUTFLOW'
        END AS trend_indicator
    FROM 
        base_collection_stats bcs
    WHERE 
        bcs.daily_net_flow_eth <= 0
),
-- 7天流入排名
weekly_inflow_collections AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        bcs.collection_address,
        bcs.collection_name,
        CAST('INFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('7DAYS' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY bcs.net_flow_7d_eth DESC) AS INT) AS rank_num,
        bcs.net_flow_7d_eth AS smart_whale_net_flow_eth,
        bcs.net_flow_7d_eth * 2500.00 AS smart_whale_net_flow_usd,
        bcs.net_flow_7d_eth AS smart_whale_net_flow_7d_eth,
        bcs.net_flow_30d_eth AS smart_whale_net_flow_30d_eth,
        bcs.floor_price_eth,
        bcs.floor_price_change_1d,
        bcs.smart_whale_buyers,
        bcs.smart_whale_sellers,
        bcs.smart_whale_buy_volume_eth,
        bcs.smart_whale_sell_volume_eth,
        bcs.smart_whale_trading_percentage,
        CASE 
            WHEN bcs.net_flow_7d_eth > 30 THEN 'STRONG_INFLOW'
            WHEN bcs.net_flow_7d_eth > 15 THEN 'MODERATE_INFLOW'
            ELSE 'SLIGHT_INFLOW'
        END AS trend_indicator
    FROM 
        base_collection_stats bcs
    WHERE 
        bcs.net_flow_7d_eth >= 0
),
-- 7天流出排名
weekly_outflow_collections AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        bcs.collection_address,
        bcs.collection_name,
        CAST('OUTFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('7DAYS' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY bcs.net_flow_7d_eth ASC) AS INT) AS rank_num,
        bcs.net_flow_7d_eth AS smart_whale_net_flow_eth,
        bcs.net_flow_7d_eth * 2500.00 AS smart_whale_net_flow_usd,
        bcs.net_flow_7d_eth AS smart_whale_net_flow_7d_eth,
        bcs.net_flow_30d_eth AS smart_whale_net_flow_30d_eth,
        bcs.floor_price_eth,
        bcs.floor_price_change_1d,
        bcs.smart_whale_buyers,
        bcs.smart_whale_sellers,
        bcs.smart_whale_buy_volume_eth,
        bcs.smart_whale_sell_volume_eth,
        bcs.smart_whale_trading_percentage,
        CASE 
            WHEN bcs.net_flow_7d_eth < -30 THEN 'STRONG_OUTFLOW'
            WHEN bcs.net_flow_7d_eth < -15 THEN 'MODERATE_OUTFLOW'
            ELSE 'SLIGHT_OUTFLOW'
        END AS trend_indicator
    FROM 
        base_collection_stats bcs
    WHERE 
        bcs.net_flow_7d_eth <= 0
),
-- 30天流入排名
monthly_inflow_collections AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        bcs.collection_address,
        bcs.collection_name,
        CAST('INFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('30DAYS' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY bcs.net_flow_30d_eth DESC) AS INT) AS rank_num,
        bcs.net_flow_30d_eth AS smart_whale_net_flow_eth,
        bcs.net_flow_30d_eth * 2500.00 AS smart_whale_net_flow_usd,
        bcs.net_flow_7d_eth AS smart_whale_net_flow_7d_eth,
        bcs.net_flow_30d_eth AS smart_whale_net_flow_30d_eth,
        bcs.floor_price_eth,
        bcs.floor_price_change_1d,
        bcs.smart_whale_buyers,
        bcs.smart_whale_sellers,
        bcs.smart_whale_buy_volume_eth,
        bcs.smart_whale_sell_volume_eth,
        bcs.smart_whale_trading_percentage,
        CASE 
            WHEN bcs.net_flow_30d_eth > 50 THEN 'STRONG_INFLOW'
            WHEN bcs.net_flow_30d_eth > 25 THEN 'MODERATE_INFLOW'
            ELSE 'SLIGHT_INFLOW'
        END AS trend_indicator
    FROM 
        base_collection_stats bcs
    WHERE 
        bcs.net_flow_30d_eth >= 0
),
-- 30天流出排名
monthly_outflow_collections AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        bcs.collection_address,
        bcs.collection_name,
        CAST('OUTFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('30DAYS' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY bcs.net_flow_30d_eth ASC) AS INT) AS rank_num,
        bcs.net_flow_30d_eth AS smart_whale_net_flow_eth,
        bcs.net_flow_30d_eth * 2500.00 AS smart_whale_net_flow_usd,
        bcs.net_flow_7d_eth AS smart_whale_net_flow_7d_eth,
        bcs.net_flow_30d_eth AS smart_whale_net_flow_30d_eth,
        bcs.floor_price_eth,
        bcs.floor_price_change_1d,
        bcs.smart_whale_buyers,
        bcs.smart_whale_sellers,
        bcs.smart_whale_buy_volume_eth,
        bcs.smart_whale_sell_volume_eth,
        bcs.smart_whale_trading_percentage,
        CASE 
            WHEN bcs.net_flow_30d_eth < -50 THEN 'STRONG_OUTFLOW'
            WHEN bcs.net_flow_30d_eth < -25 THEN 'MODERATE_OUTFLOW'
            ELSE 'SLIGHT_OUTFLOW'
        END AS trend_indicator
    FROM 
        base_collection_stats bcs
    WHERE 
        bcs.net_flow_30d_eth <= 0
),
-- 合并所有排名
all_collections AS (
    SELECT * FROM daily_inflow_collections
    UNION ALL
    SELECT * FROM daily_outflow_collections
    UNION ALL
    SELECT * FROM weekly_inflow_collections
    UNION ALL
    SELECT * FROM weekly_outflow_collections
    UNION ALL
    SELECT * FROM monthly_inflow_collections
    UNION ALL
    SELECT * FROM monthly_outflow_collections
)
SELECT 
    ac.snapshot_date,
    ac.collection_address,
    ac.collection_name,
    cli.logo_url,
    CAST(ac.flow_direction AS VARCHAR(10)) AS flow_direction,
    CAST(ac.rank_timerange AS VARCHAR(10)) AS rank_timerange,
    CAST(ac.rank_num AS INT) AS rank_num,
    ac.smart_whale_net_flow_eth,
    ac.smart_whale_net_flow_usd,
    ac.smart_whale_net_flow_7d_eth,
    ac.smart_whale_net_flow_30d_eth,
    CAST(ac.smart_whale_buyers AS INT) AS smart_whale_buyers,
    CAST(ac.smart_whale_sellers AS INT) AS smart_whale_sellers,
    ac.smart_whale_buy_volume_eth,
    ac.smart_whale_sell_volume_eth,
    ac.smart_whale_trading_percentage,
    ac.floor_price_eth,
    ac.floor_price_change_1d,
    ac.trend_indicator,
    CAST('dws_collection_whale_flow,dim_collection_info' AS VARCHAR(100)) AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    all_collections ac
LEFT JOIN
    collection_logo_info cli ON ac.collection_address = cli.collection_address
WHERE 
    ac.rank_num <= 10; 