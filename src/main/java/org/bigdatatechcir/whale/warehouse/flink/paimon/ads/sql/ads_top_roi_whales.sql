-- 收益率Top10鲸鱼钱包表

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

-- 创建收益率Top10鲸鱼钱包表
CREATE TABLE IF NOT EXISTS ads_top_roi_whales (
    snapshot_date DATE,
    wallet_address VARCHAR(255),
    rank_num INT,
    wallet_tag VARCHAR(255),
    roi_percentage DECIMAL(10,2),
    total_buy_volume_eth DECIMAL(30,10),
    total_sell_volume_eth DECIMAL(30,10),
    total_profit_eth DECIMAL(30,10),
    roi_7d_percentage DECIMAL(10,2),
    roi_30d_percentage DECIMAL(10,2),
    best_collection_roi VARCHAR(255),
    best_collection_roi_percentage DECIMAL(10,2),
    avg_hold_days DECIMAL(10,2),
    first_track_date DATE,
    influence_score DECIMAL(10,2),
    data_source VARCHAR(100),
    etl_time TIMESTAMP,
    PRIMARY KEY (snapshot_date, wallet_address) NOT ENFORCED
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

-- 计算并更新收益率Top10鲸鱼钱包
INSERT INTO ads_top_roi_whales
WITH whale_data AS (
    -- 从DWS获取鲸鱼信息和精确计算的ROI
    SELECT 
        wallet_address,
        MAX(daily_roi_percentage) AS roi_percentage,  -- 使用精确计算的ROI
        SUM(daily_buy_volume_eth) AS total_buy_volume_eth,
        SUM(daily_sell_volume_eth) AS total_sell_volume_eth,
        SUM(daily_profit_eth) AS total_profit_eth,
        -- 修复DECIMAL类型的AVG问题：先转换为DOUBLE计算平均值，再转回DECIMAL
        CAST(AVG(CAST(avg_holding_days AS DOUBLE)) AS DECIMAL(10,2)) AS avg_hold_days,
        MAX(influence_score) AS influence_score
    FROM 
        dws.dws_whale_daily_stats
    GROUP BY 
        wallet_address
),
roi_ranks AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        wd.wallet_address,
        dwa.whale_type,
        wd.roi_percentage,
        wd.total_buy_volume_eth,
        wd.total_sell_volume_eth,
        wd.total_profit_eth,
        dwa.first_track_date,
        wd.influence_score,
        wd.avg_hold_days,
        ROW_NUMBER() OVER (ORDER BY wd.roi_percentage DESC) AS rank_num
    FROM 
        whale_data wd
    JOIN 
        dim.dim_whale_address dwa ON wd.wallet_address = dwa.wallet_address
    WHERE 
        dwa.is_whale = TRUE
        AND dwa.status = 'ACTIVE'
        AND wd.total_buy_volume_eth > 0  -- 确保有有效的ROI计算
),
recent_roi AS (
    -- 计算近期ROI - 使用精确的NFT买卖配对计算
    SELECT 
        wds.wallet_address,
        -- 7天ROI
        CASE 
            WHEN SUM(CASE WHEN wds.stat_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN wds.daily_profit_eth ELSE 0 END) > 0 
            THEN AVG(CASE WHEN wds.stat_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN wds.daily_roi_percentage ELSE NULL END)
            ELSE 0
        END AS roi_7d_percentage,
        -- 30天ROI
        CASE 
            WHEN SUM(CASE WHEN wds.stat_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN wds.daily_profit_eth ELSE 0 END) > 0 
            THEN AVG(CASE WHEN wds.stat_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN wds.daily_roi_percentage ELSE NULL END)
            ELSE 0
        END AS roi_30d_percentage
    FROM 
        dws.dws_whale_daily_stats wds
    GROUP BY 
        wds.wallet_address
),
-- 通过NFT精确配对计算每个收藏集的ROI
nft_profits_by_collection AS (
    -- 通过配对买卖交易计算每个收藏集的收益和投资额
    SELECT 
        sell.from_address AS wallet_address,
        sell.contract_address,
        SUM(buy.trade_price_eth) AS invested_eth,
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
        sell.contract_address
),
collection_roi AS (
    -- 计算每个收藏集的ROI
    SELECT
        wallet_address,
        contract_address,
        CASE 
            WHEN invested_eth > 0 
            THEN (profit_eth / invested_eth) * 100 
            ELSE 0 
        END AS roi_percentage
    FROM 
        nft_profits_by_collection
    WHERE 
        invested_eth > 0
),
collection_roi_ranked AS (
    -- 为每个钱包的收藏集ROI排序
    SELECT
        wallet_address,
        contract_address,
        roi_percentage,
        ROW_NUMBER() OVER (PARTITION BY wallet_address ORDER BY roi_percentage DESC) AS roi_rank
    FROM 
        collection_roi
),
best_collection_roi AS (
    -- 选择每个钱包的最佳ROI收藏集
    SELECT 
        cr.wallet_address,
        c.collection_name AS best_collection_roi,
        cr.roi_percentage AS best_collection_roi_percentage
    FROM 
        collection_roi_ranked cr
    LEFT JOIN 
        dim.dim_collection_info c ON cr.contract_address = c.collection_address
    WHERE 
        cr.roi_rank = 1
)
SELECT 
    r.snapshot_date,
    r.wallet_address,
    CAST(r.rank_num AS INT) AS rank_num,
    CASE 
        WHEN r.whale_type = 'SMART' THEN 'Smart Whale'
        WHEN r.whale_type = 'DUMB' THEN 'Dumb Whale'
        ELSE 'Tracking Whale'
    END AS wallet_tag,
    r.roi_percentage,
    r.total_buy_volume_eth,
    r.total_sell_volume_eth,
    r.total_profit_eth,
    CAST(COALESCE(rr.roi_7d_percentage, 0) AS DECIMAL(10,2)) AS roi_7d_percentage,
    CAST(COALESCE(rr.roi_30d_percentage, 0) AS DECIMAL(10,2)) AS roi_30d_percentage,
    COALESCE(bc.best_collection_roi, 'Unknown') AS best_collection_roi,
    CAST(COALESCE(bc.best_collection_roi_percentage, 0) AS DECIMAL(10,2)) AS best_collection_roi_percentage,
    CAST(r.avg_hold_days AS DECIMAL(10,2)) AS avg_hold_days,
    r.first_track_date,
    CAST(r.influence_score AS DECIMAL(10,2)) AS influence_score,
    'dws_whale_daily_stats,dwd_whale_transaction_detail' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    roi_ranks r
LEFT JOIN 
    recent_roi rr ON r.wallet_address = rr.wallet_address
LEFT JOIN 
    best_collection_roi bc ON r.wallet_address = bc.wallet_address
WHERE 
    r.rank_num <= 10; 