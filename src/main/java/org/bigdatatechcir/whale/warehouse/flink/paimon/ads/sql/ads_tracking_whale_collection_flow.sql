-- 工作集收藏集中鲸鱼净流入/流出Top10表

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

-- 创建工作集收藏集中鲸鱼净流入/流出Top10表
CREATE TABLE IF NOT EXISTS ads_tracking_whale_collection_flow (
    snapshot_date DATE,
    collection_address VARCHAR(255),
    collection_name VARCHAR(255),
    logo_url VARCHAR(500),                           -- 收藏集logo URL
    flow_direction VARCHAR(20),
    rank_timerange VARCHAR(10),    -- 新增字段，表示排名周期：DAY, 7DAYS, 30DAYS
    rank_num INT,
    net_flow_eth DECIMAL(30,10),
    net_flow_usd DECIMAL(30,10),
    net_flow_7d_eth DECIMAL(30,10),
    net_flow_30d_eth DECIMAL(30,10),
    floor_price_eth DECIMAL(30,10),
    floor_price_change_1d DECIMAL(10,2),
    unique_whale_buyers INT,
    unique_whale_sellers INT,
    whale_trading_percentage DECIMAL(10,2),
    smart_whale_percentage DECIMAL(10,2),
    dumb_whale_percentage DECIMAL(10,2),
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

-- 插入所有时间范围的排名数据
INSERT INTO ads_tracking_whale_collection_flow
WITH collection_logo_info AS (
    -- 获取收藏集Logo信息
    SELECT 
        collection_address,
        logo_url
    FROM 
        dim.dim_collection_info
),
historical_flows AS (
    -- 计算各收藏集历史累计流量(7日和30日)
    SELECT 
        cf.collection_address,
        SUM(CASE WHEN cf.stat_date BETWEEN CURRENT_DATE - INTERVAL '7' DAY AND CURRENT_DATE 
                THEN cf.net_flow_eth ELSE 0 END) AS net_flow_7d_eth,
        SUM(CASE WHEN cf.stat_date BETWEEN CURRENT_DATE - INTERVAL '30' DAY AND CURRENT_DATE 
                THEN cf.net_flow_eth ELSE 0 END) AS net_flow_30d_eth
    FROM 
        dws.dws_collection_whale_flow cf
    GROUP BY 
        cf.collection_address
),
whale_type_stats AS (
    -- 计算各收藏集中不同类型鲸鱼的交易占比
    SELECT 
        cf.collection_address,
        SUM(CASE WHEN w1.whale_type = 'SMART' THEN cf.whale_buy_volume_eth ELSE 0 END) + 
        SUM(CASE WHEN w2.whale_type = 'SMART' THEN cf.whale_sell_volume_eth ELSE 0 END) AS smart_whale_volume,
        SUM(CASE WHEN w1.whale_type = 'DUMB' THEN cf.whale_buy_volume_eth ELSE 0 END) + 
        SUM(CASE WHEN w2.whale_type = 'DUMB' THEN cf.whale_sell_volume_eth ELSE 0 END) AS dumb_whale_volume,
        SUM(cf.whale_buy_volume_eth) + SUM(cf.whale_sell_volume_eth) AS total_whale_volume
    FROM 
        dws.dws_collection_whale_flow cf
    LEFT JOIN
        dim.dim_whale_address w1 ON cf.unique_whale_buyers > 0 
    LEFT JOIN
        dim.dim_whale_address w2 ON cf.unique_whale_sellers > 0
    WHERE 
        cf.stat_date = CURRENT_DATE
    GROUP BY 
        cf.collection_address
),
current_day_stats AS (
    -- 获取当日汇总数据
    SELECT 
        cf.collection_address,
        MAX(cf.collection_name) AS collection_name,
        SUM(cf.net_flow_eth) AS net_flow_eth,
        AVG(cf.floor_price_eth) AS floor_price_eth,
        CAST(0 AS DECIMAL(10,2)) AS floor_price_change_1d, -- 此字段需要外部数据源
        SUM(cf.unique_whale_buyers) AS unique_whale_buyers,
        SUM(cf.unique_whale_sellers) AS unique_whale_sellers,
        CAST(AVG(cf.whale_trading_percentage) AS DECIMAL(10,2)) AS whale_trading_percentage,
        CASE 
            WHEN SUM(cf.net_flow_eth) > 10 THEN 'STRONG_INFLOW'
            WHEN SUM(cf.net_flow_eth) > 5 THEN 'MODERATE_INFLOW'
            WHEN SUM(cf.net_flow_eth) > 0 THEN 'SLIGHT_INFLOW'
            WHEN SUM(cf.net_flow_eth) < -10 THEN 'STRONG_OUTFLOW'
            WHEN SUM(cf.net_flow_eth) < -5 THEN 'MODERATE_OUTFLOW'
            WHEN SUM(cf.net_flow_eth) < 0 THEN 'SLIGHT_OUTFLOW'
            ELSE 'NEUTRAL'
        END AS trend_indicator
    FROM 
        dws.dws_collection_whale_flow cf
    WHERE 
        cf.stat_date = CURRENT_DATE
    GROUP BY 
        cf.collection_address
),
-- 当日净流入排名
daily_inflow_collections AS (
    -- 计算净流入Top10
    SELECT 
        cds.collection_address,
        cds.collection_name,
        'INFLOW' AS flow_direction,
        'DAY' AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY cds.net_flow_eth DESC) AS INT) AS rank_num,
        cds.net_flow_eth,
        cds.net_flow_eth * 2500.00 AS net_flow_usd, -- 示例USD汇率
        cds.floor_price_eth,
        cds.floor_price_change_1d,
        CAST(cds.unique_whale_buyers AS INT) AS unique_whale_buyers,
        CAST(cds.unique_whale_sellers AS INT) AS unique_whale_sellers,
        cds.whale_trading_percentage,
        cds.trend_indicator
    FROM 
        current_day_stats cds
    WHERE 
        cds.net_flow_eth > 0
),
-- 当日净流出排名
daily_outflow_collections AS (
    -- 计算净流出Top10
    SELECT 
        cds.collection_address,
        cds.collection_name,
        'OUTFLOW' AS flow_direction,
        'DAY' AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY cds.net_flow_eth ASC) AS INT) AS rank_num,
        cds.net_flow_eth,
        cds.net_flow_eth * 2500.00 AS net_flow_usd, -- 示例USD汇率
        cds.floor_price_eth,
        cds.floor_price_change_1d,
        CAST(cds.unique_whale_buyers AS INT) AS unique_whale_buyers,
        CAST(cds.unique_whale_sellers AS INT) AS unique_whale_sellers,
        cds.whale_trading_percentage,
        cds.trend_indicator
    FROM 
        current_day_stats cds
    WHERE 
        cds.net_flow_eth < 0
),
-- 7天净流入排名
weekly_inflow_collections AS (
    SELECT 
        hf.collection_address,
        cds.collection_name,
        CAST('INFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('7DAYS' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY hf.net_flow_7d_eth DESC) AS INT) AS rank_num,
        hf.net_flow_7d_eth AS net_flow_eth,
        hf.net_flow_7d_eth * 2500.00 AS net_flow_usd,
        cds.floor_price_eth,
        cds.floor_price_change_1d,
        CAST(cds.unique_whale_buyers AS INT) AS unique_whale_buyers,
        CAST(cds.unique_whale_sellers AS INT) AS unique_whale_sellers,
        cds.whale_trading_percentage,
        CASE 
            WHEN hf.net_flow_7d_eth > 30 THEN 'STRONG_INFLOW'
            WHEN hf.net_flow_7d_eth > 15 THEN 'MODERATE_INFLOW'
            ELSE 'SLIGHT_INFLOW'
        END AS trend_indicator
    FROM 
        historical_flows hf
    JOIN 
        current_day_stats cds ON hf.collection_address = cds.collection_address
    WHERE 
        -- 修改筛选条件，取前10名流入
        hf.net_flow_7d_eth > 0
    ORDER BY hf.net_flow_7d_eth DESC
    LIMIT 10
),
-- 7天净流出排名
weekly_outflow_collections AS (
    SELECT 
        hf.collection_address,
        cds.collection_name,
        CAST('OUTFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('7DAYS' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY hf.net_flow_7d_eth ASC) AS INT) AS rank_num,
        hf.net_flow_7d_eth AS net_flow_eth,
        hf.net_flow_7d_eth * 2500.00 AS net_flow_usd,
        cds.floor_price_eth,
        cds.floor_price_change_1d,
        CAST(cds.unique_whale_buyers AS INT) AS unique_whale_buyers,
        CAST(cds.unique_whale_sellers AS INT) AS unique_whale_sellers,
        cds.whale_trading_percentage,
        CASE 
            WHEN hf.net_flow_7d_eth < -30 THEN 'STRONG_OUTFLOW'
            WHEN hf.net_flow_7d_eth < -15 THEN 'MODERATE_OUTFLOW'
            ELSE 'SLIGHT_OUTFLOW'
        END AS trend_indicator
    FROM 
        historical_flows hf
    JOIN 
        current_day_stats cds ON hf.collection_address = cds.collection_address
    WHERE 
        -- 修改筛选条件，取前10名流出
        hf.net_flow_7d_eth < 0
    ORDER BY hf.net_flow_7d_eth ASC
    LIMIT 10
),
-- 30天净流入排名
monthly_inflow_collections AS (
    SELECT 
        hf.collection_address,
        cds.collection_name,
        CAST('INFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('30DAYS' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY hf.net_flow_30d_eth DESC) AS INT) AS rank_num,
        hf.net_flow_30d_eth AS net_flow_eth,
        hf.net_flow_30d_eth * 2500.00 AS net_flow_usd,
        cds.floor_price_eth,
        cds.floor_price_change_1d,
        CAST(cds.unique_whale_buyers AS INT) AS unique_whale_buyers,
        CAST(cds.unique_whale_sellers AS INT) AS unique_whale_sellers,
        cds.whale_trading_percentage,
        CASE 
            WHEN hf.net_flow_30d_eth > 50 THEN 'STRONG_INFLOW'
            WHEN hf.net_flow_30d_eth > 25 THEN 'MODERATE_INFLOW'
            ELSE 'SLIGHT_INFLOW'
        END AS trend_indicator
    FROM 
        historical_flows hf
    JOIN 
        current_day_stats cds ON hf.collection_address = cds.collection_address
    WHERE 
        -- 修改筛选条件，取前10名流入
        hf.net_flow_30d_eth > 0
    ORDER BY hf.net_flow_30d_eth DESC
    LIMIT 10
),
-- 30天净流出排名
monthly_outflow_collections AS (
    SELECT 
        hf.collection_address,
        cds.collection_name,
        CAST('OUTFLOW' AS VARCHAR(10)) AS flow_direction,
        CAST('30DAYS' AS VARCHAR(10)) AS rank_timerange,
        CAST(ROW_NUMBER() OVER (ORDER BY hf.net_flow_30d_eth ASC) AS INT) AS rank_num,
        hf.net_flow_30d_eth AS net_flow_eth,
        hf.net_flow_30d_eth * 2500.00 AS net_flow_usd,
        cds.floor_price_eth,
        cds.floor_price_change_1d,
        CAST(cds.unique_whale_buyers AS INT) AS unique_whale_buyers,
        CAST(cds.unique_whale_sellers AS INT) AS unique_whale_sellers,
        cds.whale_trading_percentage,
        CASE 
            WHEN hf.net_flow_30d_eth < -50 THEN 'STRONG_OUTFLOW'
            WHEN hf.net_flow_30d_eth < -25 THEN 'MODERATE_OUTFLOW'
            ELSE 'SLIGHT_OUTFLOW'
        END AS trend_indicator
    FROM 
        historical_flows hf
    JOIN 
        current_day_stats cds ON hf.collection_address = cds.collection_address
    WHERE 
        -- 修改筛选条件，取前10名流出
        hf.net_flow_30d_eth < 0
    ORDER BY hf.net_flow_30d_eth ASC
    LIMIT 10
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
    CURRENT_DATE AS snapshot_date,
    c.collection_address,
    c.collection_name,
    cli.logo_url,
    CAST(c.flow_direction AS VARCHAR(10)) AS flow_direction,
    CAST(c.rank_timerange AS VARCHAR(10)) AS rank_timerange,
    c.rank_num,
    c.net_flow_eth,
    c.net_flow_usd,
    COALESCE(hf.net_flow_7d_eth, CAST(0 AS DECIMAL(30,10))) AS net_flow_7d_eth,
    COALESCE(hf.net_flow_30d_eth, CAST(0 AS DECIMAL(30,10))) AS net_flow_30d_eth,
    c.floor_price_eth,
    c.floor_price_change_1d,
    c.unique_whale_buyers,
    c.unique_whale_sellers,
    c.whale_trading_percentage,
    CASE 
        WHEN wts.total_whale_volume > 0 
        THEN CAST((COALESCE(wts.smart_whale_volume, 0) / wts.total_whale_volume) * 100 AS DECIMAL(10,2))
        ELSE CAST(0 AS DECIMAL(10,2))
    END AS smart_whale_percentage,
    CASE 
        WHEN wts.total_whale_volume > 0 
        THEN CAST((COALESCE(wts.dumb_whale_volume, 0) / wts.total_whale_volume) * 100 AS DECIMAL(10,2))
        ELSE CAST(0 AS DECIMAL(10,2))
    END AS dumb_whale_percentage,
    c.trend_indicator,
    CAST('dws_collection_whale_flow,dim_whale_address,dim_collection_info' AS VARCHAR(100)) AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    all_collections c
LEFT JOIN 
    historical_flows hf ON c.collection_address = hf.collection_address
LEFT JOIN 
    whale_type_stats wts ON c.collection_address = wts.collection_address
LEFT JOIN
    collection_logo_info cli ON c.collection_address = cli.collection_address
WHERE 
    c.rank_num <= 10; 