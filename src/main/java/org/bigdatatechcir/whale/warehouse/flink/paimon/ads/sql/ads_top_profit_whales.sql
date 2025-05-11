-- 收益额Top10鲸鱼钱包表

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

-- 创建收益额Top10鲸鱼钱包表
CREATE TABLE IF NOT EXISTS ads_top_profit_whales (
    snapshot_date DATE,
    wallet_address VARCHAR(255),
    rank_timerange VARCHAR(10),    -- 新增字段，表示排名周期：DAY, 7DAYS, 30DAYS
    rank_num INT,
    wallet_tag VARCHAR(255),
    total_profit_eth DECIMAL(30,10),
    total_profit_usd DECIMAL(30,10),
    profit_7d_eth DECIMAL(30,10),
    profit_30d_eth DECIMAL(30,10),
    best_collection VARCHAR(255),
    best_collection_profit_eth DECIMAL(30,10),
    total_tx_count INT,
    first_track_date DATE,
    tracking_days INT,
    influence_score DECIMAL(10,2),
    data_source VARCHAR(100),
    etl_time TIMESTAMP,
    PRIMARY KEY (snapshot_date, wallet_address, rank_timerange) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'bucket-key' = 'wallet_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '3',
    'compaction.max.file-num' = '30',
    'compaction.target-file-size' = '128MB'
);

-- 计算并更新收益额Top10鲸鱼钱包 - 基本数据CTE
-- 插入所有时间范围的排名数据
INSERT INTO ads_top_profit_whales
WITH whale_profit_data AS (
    -- 从DWS层获取已精确计算的利润数据
    SELECT 
        wallet_address,
        SUM(daily_profit_eth) AS total_profit_eth,
        SUM(daily_profit_eth) * 2500.00 AS total_profit_usd,  -- 示例ETH->USD汇率
        COUNT(*) AS total_tx_count,
        MAX(influence_score) AS influence_score
    FROM 
        dws.dws_whale_daily_stats
    GROUP BY 
        wallet_address
),
recent_profit_stats AS (
    -- 计算近期利润 - 使用精确计算的利润
    SELECT 
        wallet_address,
        SUM(CASE WHEN stat_date >= DATE_FORMAT(CAST(TIMESTAMPADD(DAY, -7, CURRENT_DATE) AS TIMESTAMP), 'yyyy-MM-dd') 
                 THEN daily_profit_eth ELSE 0 END) AS profit_7d_eth,
        SUM(CASE WHEN stat_date >= DATE_FORMAT(CAST(TIMESTAMPADD(DAY, -30, CURRENT_DATE) AS TIMESTAMP), 'yyyy-MM-dd') 
                 THEN daily_profit_eth ELSE 0 END) AS profit_30d_eth
    FROM 
        dws.dws_whale_daily_stats
    GROUP BY 
        wallet_address
),
-- 计算每个收藏集的利润 - 使用NFT买卖配对计算
nft_profits_by_collection AS (
    -- 通过配对买卖交易计算每个收藏集的利润
    SELECT 
        sell.from_address AS wallet_address,
        sell.contract_address,
        sell.collection_name,
        SUM(sell.trade_price_eth - buy.trade_price_eth) AS profit_eth
    FROM 
        dwd.dwd_whale_transaction_detail sell
    JOIN (
        -- 找到每个NFT的最后一次买入记录
        SELECT 
            t.to_address,
            t.contract_address,
            t.token_id,
            t.trade_price_eth,
            ROW_NUMBER() OVER (
                PARTITION BY t.to_address, t.contract_address, t.token_id 
                ORDER BY t.tx_date DESC
            ) AS rn
        FROM 
            dwd.dwd_whale_transaction_detail t
    ) buy ON sell.from_address = buy.to_address
        AND sell.contract_address = buy.contract_address
        AND sell.token_id = buy.token_id
        AND buy.rn = 1  -- 确保只取最后一次买入
    WHERE 
        sell.from_is_whale = TRUE
    GROUP BY 
        sell.from_address,
        sell.contract_address,
        sell.collection_name
),
best_collections AS (
    -- 识别最佳收藏集（利润最高的）
    SELECT 
        wallet_address,
        collection_name AS best_collection,
        profit_eth AS best_collection_profit_eth,
        ROW_NUMBER() OVER (PARTITION BY wallet_address ORDER BY profit_eth DESC) AS rank_num
    FROM 
        nft_profits_by_collection
),
top_collection_profits AS (
    -- 每个钱包利润最高的收藏集
    SELECT 
        wallet_address,
        best_collection,
        best_collection_profit_eth
    FROM 
        best_collections
    WHERE 
        rank_num = 1
),
-- 每日排名
daily_profit_ranks AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        wp.wallet_address,
        'DAY' AS rank_timerange,
        dwa.whale_type,
        wp.total_profit_eth,
        wp.total_profit_usd,
        CAST(wp.total_tx_count AS INT) AS total_tx_count,
        dwa.first_track_date,
        TIMESTAMPDIFF(DAY, dwa.first_track_date, CURRENT_DATE) AS tracking_days,
        wp.influence_score,
        CAST(ROW_NUMBER() OVER (ORDER BY wp.total_profit_eth DESC) AS INT) AS rank_num
    FROM 
        whale_profit_data wp
    JOIN 
        dim.dim_whale_address dwa ON wp.wallet_address = dwa.wallet_address
    WHERE 
        dwa.is_whale = TRUE
      --  AND dwa.status = 'ACTIVE'
),
-- 7天排名
weekly_profit_ranks AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        wp.wallet_address,
        CAST('7DAYS' AS VARCHAR(10)) AS rank_timerange,
        dwa.whale_type,
        wp.total_profit_eth,
        wp.total_profit_usd,
        CAST(wp.total_tx_count AS INT) AS total_tx_count,
        dwa.first_track_date,
        TIMESTAMPDIFF(DAY, dwa.first_track_date, CURRENT_DATE) AS tracking_days,
        wp.influence_score,
        CAST(ROW_NUMBER() OVER (ORDER BY ps.profit_7d_eth DESC) AS INT) AS rank_num
    FROM 
        whale_profit_data wp
    JOIN 
        dim.dim_whale_address dwa ON wp.wallet_address = dwa.wallet_address
    JOIN
        recent_profit_stats ps ON wp.wallet_address = ps.wallet_address
    WHERE 
        dwa.is_whale = TRUE
   --     AND dwa.status = 'ACTIVE'
),
-- 30天排名
monthly_profit_ranks AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        wp.wallet_address,
        CAST('30DAYS' AS VARCHAR(10)) AS rank_timerange,
        dwa.whale_type,
        wp.total_profit_eth,
        wp.total_profit_usd,
        CAST(wp.total_tx_count AS INT) AS total_tx_count,
        dwa.first_track_date,
        TIMESTAMPDIFF(DAY, dwa.first_track_date, CURRENT_DATE) AS tracking_days,
        wp.influence_score,
        CAST(ROW_NUMBER() OVER (ORDER BY ps.profit_30d_eth DESC) AS INT) AS rank_num
    FROM 
        whale_profit_data wp
    JOIN 
        dim.dim_whale_address dwa ON wp.wallet_address = dwa.wallet_address
    JOIN
        recent_profit_stats ps ON wp.wallet_address = ps.wallet_address
    WHERE 
        dwa.is_whale = TRUE
  --      AND dwa.status = 'ACTIVE'
),
-- 合并所有排名
all_ranks AS (
    SELECT * FROM daily_profit_ranks
    UNION ALL
    SELECT * FROM weekly_profit_ranks
    UNION ALL
    SELECT * FROM monthly_profit_ranks
)
SELECT 
    r.snapshot_date,
    r.wallet_address,
    CAST(r.rank_timerange AS VARCHAR(10)) AS rank_timerange,
    CAST(r.rank_num AS INT) AS rank_num,
    CASE 
        WHEN r.whale_type = 'SMART' THEN 'Smart Whale'
        WHEN r.whale_type = 'DUMB' THEN 'Dumb Whale'
        ELSE 'Tracking Whale'
    END AS wallet_tag,
    r.total_profit_eth,
    r.total_profit_usd,
    CAST(COALESCE(ps.profit_7d_eth, 0) AS DECIMAL(30,10)) AS profit_7d_eth,
    CAST(COALESCE(ps.profit_30d_eth, 0) AS DECIMAL(30,10)) AS profit_30d_eth,
    COALESCE(bc.best_collection, 'Unknown') AS best_collection,
    CAST(COALESCE(bc.best_collection_profit_eth, 0) AS DECIMAL(30,10)) AS best_collection_profit_eth,
    r.total_tx_count,
    r.first_track_date,
    CAST(r.tracking_days AS INT) AS tracking_days,
    CAST(r.influence_score AS DECIMAL(10,2)) AS influence_score,
    CAST('dws_whale_daily_stats' AS VARCHAR(100)) AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    all_ranks r
LEFT JOIN 
    recent_profit_stats ps ON r.wallet_address = ps.wallet_address
LEFT JOIN
    top_collection_profits bc ON r.wallet_address = bc.wallet_address
WHERE 
    r.rank_num <= 10; 