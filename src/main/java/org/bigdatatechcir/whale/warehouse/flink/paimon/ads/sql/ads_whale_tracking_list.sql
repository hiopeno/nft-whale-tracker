-- 鲸鱼追踪名单表

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

-- 创建鲸鱼追踪名单表
CREATE TABLE IF NOT EXISTS ads_whale_tracking_list (
    snapshot_date DATE,
    wallet_address VARCHAR(255),
    wallet_type VARCHAR(50),
    tracking_id VARCHAR(100),
    first_track_date DATE,
    tracking_days INT,
    last_active_date DATE,
    status VARCHAR(20),
    total_profit_eth DECIMAL(30,10),
    total_profit_usd DECIMAL(30,10),
    roi_percentage DECIMAL(10,2),
    influence_score DECIMAL(10,2),
    total_tx_count INT,
    success_rate DECIMAL(10,2),
    favorite_collections VARCHAR(1000),
    inactive_days INT,
    is_top30_volume BOOLEAN,
    is_top100_balance BOOLEAN,
    rank_by_volume INT,
    rank_by_profit INT,
    data_source VARCHAR(100),
    etl_time TIMESTAMP,
    PRIMARY KEY (snapshot_date, wallet_address) NOT ENFORCED
) WITH (
    'bucket' = '8',
    'bucket-key' = 'wallet_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '3',
    'compaction.max.file-num' = '30',
    'compaction.target-file-size' = '128MB'
);

-- 计算并更新鲸鱼追踪名单
INSERT INTO ads_whale_tracking_list
WITH whale_stats AS (
    SELECT 
        wallet_address,
        whale_type,
        SUM(daily_profit_eth) AS total_profit_eth,
        SUM(daily_profit_eth) * 2500.00 AS total_profit_usd,  -- 示例ETH->USD汇率
        CASE 
            WHEN SUM(daily_buy_volume_eth) > 0 
            THEN CAST((SUM(daily_profit_eth) / SUM(daily_buy_volume_eth)) * 100 AS DECIMAL(10,2))
            ELSE CAST(0 AS DECIMAL(10,2))
        END AS roi_percentage,
        MAX(influence_score) AS influence_score,
        COUNT(*) AS total_tx_count,
        MAX(success_rate_30d) AS success_rate,
        MAX(daily_collections_traded) AS favorite_collections_count
    FROM 
        dws.dws_whale_daily_stats
    GROUP BY 
        wallet_address,
        whale_type
)
SELECT 
    CURRENT_DATE AS snapshot_date,
    dwa.wallet_address,
    dwa.whale_type AS wallet_type,
    CONCAT(
        'WHL_', 
        CAST(DATE_FORMAT(CAST(CURRENT_DATE AS TIMESTAMP), 'yyyyMMdd') AS VARCHAR), 
        '_',
        CAST(ROW_NUMBER() OVER (ORDER BY ws.influence_score DESC) AS VARCHAR)
    ) AS tracking_id,
    dwa.first_track_date,
    TIMESTAMPDIFF(DAY, dwa.first_track_date, CURRENT_DATE) AS tracking_days,
    dwa.last_active_date,
    dwa.status,
    CAST(ws.total_profit_eth AS DECIMAL(30,10)),
    CAST(ws.total_profit_usd AS DECIMAL(30,10)),
    ws.roi_percentage,
    CAST(ws.influence_score AS DECIMAL(10,2)) AS influence_score,
    CAST(ws.total_tx_count AS INT) AS total_tx_count,
    CAST(ws.success_rate AS DECIMAL(10,2)) AS success_rate,
    CAST(CONCAT('Top ', CAST(ws.favorite_collections_count AS VARCHAR), ' collections') AS VARCHAR(1000)) AS favorite_collections,
    CAST(TIMESTAMPDIFF(DAY, dwa.last_active_date, CURRENT_DATE) AS INT) AS inactive_days,
    COALESCE(dws.is_top30_volume, FALSE) AS is_top30_volume,
    COALESCE(dws.is_top100_balance, FALSE) AS is_top100_balance,
    CAST(COALESCE(dws.rank_by_volume, 0) AS INT) AS rank_by_volume,
    CAST(COALESCE(dws.rank_by_profit, 0) AS INT) AS rank_by_profit,
    'dws_whale_daily_stats,dim_whale_address' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dim.dim_whale_address dwa
JOIN
    whale_stats ws ON dwa.wallet_address = ws.wallet_address
LEFT JOIN 
    dws.dws_whale_daily_stats dws ON dwa.wallet_address = dws.wallet_address AND dws.stat_date = CURRENT_DATE
WHERE 
    dwa.is_whale = TRUE
    AND (dwa.status = 'ACTIVE' OR TIMESTAMPDIFF(DAY, dwa.last_active_date, CURRENT_DATE) <= 7);