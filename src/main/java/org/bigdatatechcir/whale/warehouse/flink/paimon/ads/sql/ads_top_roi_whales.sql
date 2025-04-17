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
WITH roi_ranks AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        dwa.wallet_address,
        dwa.whale_type,
        dwa.roi_percentage,
        dwa.total_buy_volume_eth,
        dwa.total_sell_volume_eth,
        dwa.total_profit_eth,
        dwa.first_track_date,
        dwa.whale_score AS influence_score,
        dwa.avg_hold_days,
        ROW_NUMBER() OVER (ORDER BY dwa.roi_percentage DESC) AS rank_num
    FROM 
        dim.dim_whale_address dwa
    WHERE 
        dwa.is_whale = TRUE
        AND dwa.status = 'ACTIVE'
        AND dwa.total_buy_volume_eth > 0 -- 确保有有效的ROI计算
        AND dwa.total_tx_count >= 10 -- 确保有足够的交易记录
),
recent_roi AS (
    -- 计算近期ROI
    SELECT 
        wallet_address,
        CASE 
            WHEN SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN daily_buy_volume_eth ELSE 0 END) > 0 
            THEN SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN daily_profit_eth ELSE 0 END) * 100 / 
                 SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN daily_buy_volume_eth ELSE 0 END)
            ELSE 0
        END AS roi_7d_percentage,
        CASE 
            WHEN SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN daily_buy_volume_eth ELSE 0 END) > 0 
            THEN SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN daily_profit_eth ELSE 0 END) * 100 / 
                 SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN daily_buy_volume_eth ELSE 0 END)
            ELSE 0
        END AS roi_30d_percentage
    FROM 
        dws.dws_whale_daily_stats
    GROUP BY 
        wallet_address
),
wallet_collection_roi AS (
    -- 计算每个钱包的每个收藏集ROI
    SELECT
        t.contract_address,
        SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) AS buy_value,
        SUM(CASE WHEN t.from_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) AS sell_value,
        CASE 
            WHEN SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) > 0
            THEN (SUM(CASE WHEN t.from_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) - 
                 SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END)) * 100 /
                 SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END)
            ELSE 0
        END AS roi_percentage,
        w.wallet_address
    FROM 
        dwd.dwd_whale_transaction_detail t
    JOIN 
        roi_ranks w 
    ON 
        t.from_address = w.wallet_address OR t.to_address = w.wallet_address
    WHERE 
        (t.from_is_whale = TRUE OR t.to_is_whale = TRUE)
    GROUP BY 
        t.contract_address,
        w.wallet_address
    HAVING 
        SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) > 0
),
collection_roi_ranked AS (
    -- 为每个钱包的收藏集ROI排序
    SELECT
        wallet_address,
        contract_address,
        roi_percentage,
        ROW_NUMBER() OVER (PARTITION BY wallet_address ORDER BY roi_percentage DESC) AS roi_rank
    FROM 
        wallet_collection_roi
),
best_collection_roi AS (
    -- 选择每个钱包的最佳ROI收藏集
    SELECT 
        cr.wallet_address,
        c.collection_name AS best_collection_roi,
        cr.roi_percentage AS best_collection_roi_percentage
    FROM 
        collection_roi_ranked cr
    JOIN 
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
    COALESCE(rr.roi_7d_percentage, 0) AS roi_7d_percentage,
    COALESCE(rr.roi_30d_percentage, 0) AS roi_30d_percentage,
    COALESCE(bc.best_collection_roi, 'Unknown') AS best_collection_roi,
    COALESCE(bc.best_collection_roi_percentage, 0) AS best_collection_roi_percentage,
    r.avg_hold_days,
    r.first_track_date,
    r.influence_score,
    'dws_whale_daily_stats,dim_whale_address' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    roi_ranks r
LEFT JOIN 
    recent_roi rr ON r.wallet_address = rr.wallet_address
LEFT JOIN 
    best_collection_roi bc ON r.wallet_address = bc.wallet_address
WHERE 
    r.rank_num <= 10; 