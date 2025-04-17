-- 鲸鱼钱包地址维度表

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
CREATE DATABASE IF NOT EXISTS dim;
USE dim;

-- 创建鲸鱼钱包地址维度表
CREATE TABLE IF NOT EXISTS dim_whale_address (
    wallet_address VARCHAR(255),
    first_track_date DATE,
    last_active_date DATE,
    is_whale BOOLEAN,
    whale_type VARCHAR(50),
    whale_score DECIMAL(10,2),
    total_profit_eth DECIMAL(30,10),
    total_profit_usd DECIMAL(30,10),
    roi_percentage DECIMAL(10,2),
    total_buy_volume_eth DECIMAL(30,10),
    total_sell_volume_eth DECIMAL(30,10),
    total_tx_count BIGINT,
    avg_hold_days DECIMAL(10,2),
    favorite_collections VARCHAR(1000),
    labels VARCHAR(500),
    success_rate DECIMAL(10,2),
    is_top30_volume_days INT,
    is_top100_balance_days INT,
    inactive_days INT,
    status VARCHAR(20),
    etl_time TIMESTAMP,
    PRIMARY KEY (wallet_address) NOT ENFORCED
) WITH (
    'bucket' = '8',
    'bucket-key' = 'wallet_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'lookup',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 1. 识别新加入的鲸鱼钱包并插入
INSERT INTO dim_whale_address
WITH potential_whales AS (
    SELECT DISTINCT
        wallet_address,
        MIN(wallet_date) AS first_track_date,
        MAX(wallet_date) AS last_active_date,
        TRUE AS is_whale,
        'TRACKING' AS whale_type, -- 初始状态为追踪中
        0 AS whale_score, -- 初始影响力评分为0
        SUM(CASE WHEN profit_eth > 0 THEN profit_eth ELSE 0 END) AS total_profit_eth,
        SUM(CASE WHEN profit_usd > 0 THEN profit_usd ELSE 0 END) AS total_profit_usd,
        CASE 
            WHEN SUM(buy_volume_eth) > 0 
            THEN (SUM(CASE WHEN profit_eth > 0 THEN profit_eth ELSE 0 END) / SUM(buy_volume_eth)) * 100 
            ELSE 0 
        END AS roi_percentage,
        SUM(buy_volume_eth) AS total_buy_volume_eth,
        SUM(sell_volume_eth) AS total_sell_volume_eth,
        SUM(total_tx_count) AS total_tx_count,
        0 AS avg_hold_days, -- 初始平均持有天数为0
        '[]' AS favorite_collections, -- 初始无偏好收藏集
        '[]' AS labels, -- 初始无标签
        SUM(CASE WHEN profit_eth > 0 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS success_rate,
        CAST(COUNT(CASE WHEN is_top30_volume = TRUE THEN 1 END) AS INT) AS is_top30_volume_days,
        CAST(COUNT(CASE WHEN is_top100_balance = TRUE THEN 1 END) AS INT) AS is_top100_balance_days,
        0 AS inactive_days, -- 初始不活跃天数为0
        'ACTIVE' AS status,
        CURRENT_TIMESTAMP AS etl_time
    FROM 
        dwd.dwd_wallet_daily_stats
    WHERE 
        is_whale_candidate = TRUE
        AND wallet_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) -- 最近30天内
    GROUP BY 
        wallet_address
    HAVING 
        COUNT(CASE WHEN is_top30_volume = TRUE THEN 1 END) >= 1 -- 至少1天在交易额Top30
        OR COUNT(CASE WHEN is_top100_balance = TRUE THEN 1 END) >= 1 -- 或至少1天在持有额Top100
)
SELECT * FROM potential_whales pw
WHERE NOT EXISTS (
    SELECT 1 FROM dim_whale_address dw
    WHERE dw.wallet_address = pw.wallet_address
);

-- 2. 更新现有鲸鱼钱包信息
-- 先删除要更新的记录
DELETE FROM dim_whale_address
WHERE wallet_address IN (
    SELECT DISTINCT dw.wallet_address
    FROM dim_whale_address dw
    JOIN dwd.dwd_wallet_daily_stats wd ON dw.wallet_address = wd.wallet_address
    WHERE wd.wallet_date > dw.last_active_date
);

-- 然后重新插入更新后的数据
INSERT INTO dim_whale_address
SELECT 
    dw.wallet_address,
    dw.first_track_date,
    CASE WHEN stats.max_date > dw.last_active_date THEN stats.max_date ELSE dw.last_active_date END,
    dw.is_whale,
    CASE WHEN dw.whale_type = 'TRACKING' AND TIMESTAMPDIFF(DAY, dw.first_track_date, CURRENT_DATE) >= 30 THEN
        CASE WHEN COALESCE(stats.success_rate, dw.success_rate) >= 65 THEN 'SMART'
             WHEN COALESCE(stats.success_rate, dw.success_rate) < 40 THEN 'DUMB'
             ELSE 'TRACKING' END
    ELSE dw.whale_type END AS whale_type,
    LEAST(100, GREATEST(0, ((dw.is_top30_volume_days * 0.2) + 
        (dw.is_top100_balance_days * 0.1) + 
        (CASE WHEN dw.total_tx_count > 1000 THEN 20 ELSE dw.total_tx_count * 0.02 END) +
        (CASE WHEN dw.total_buy_volume_eth > 1000 THEN 30 ELSE dw.total_buy_volume_eth * 0.03 END) +
        (CASE WHEN dw.roi_percentage > 100 THEN 30 ELSE dw.roi_percentage * 0.3 END)))) AS whale_score,
    dw.total_profit_eth + COALESCE(stats.profit_eth, 0) AS total_profit_eth,
    dw.total_profit_usd + COALESCE(stats.profit_usd, 0) AS total_profit_usd,
    CASE WHEN (dw.total_buy_volume_eth + COALESCE(stats.buy_volume_eth, 0)) > 0 
        THEN ((dw.total_profit_eth + COALESCE(stats.profit_eth, 0)) / (dw.total_buy_volume_eth + COALESCE(stats.buy_volume_eth, 0))) * 100 
        ELSE 0 END AS roi_percentage,
    dw.total_buy_volume_eth + COALESCE(stats.buy_volume_eth, 0) AS total_buy_volume_eth,
    dw.total_sell_volume_eth + COALESCE(stats.sell_volume_eth, 0) AS total_sell_volume_eth,
    dw.total_tx_count + COALESCE(stats.tx_count, 0) AS total_tx_count,
    dw.avg_hold_days,
    '[]' AS favorite_collections,
    '["default_label"]' AS labels,
    stats.success_rate,
    dw.is_top30_volume_days + COALESCE(stats.top30_days, 0) AS is_top30_volume_days,
    dw.is_top100_balance_days + COALESCE(stats.top100_days, 0) AS is_top100_balance_days,
    CASE WHEN stats.max_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN 0
        ELSE TIMESTAMPDIFF(DAY, GREATEST(dw.last_active_date, stats.max_date), CURRENT_DATE) END AS inactive_days,
    CASE WHEN stats.max_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN 'ACTIVE'
        WHEN TIMESTAMPDIFF(DAY, GREATEST(dw.last_active_date, stats.max_date), CURRENT_DATE) > 7 THEN 'INACTIVE'
        ELSE dw.status END AS status,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dim_whale_address dw
JOIN (
    -- 内联统计数据子查询，替代临时视图
    SELECT 
        wd.wallet_address,
        MAX(wd.wallet_date) AS max_date,
        SUM(wd.profit_eth) AS profit_eth,
        SUM(wd.profit_usd) AS profit_usd,
        SUM(wd.buy_volume_eth) AS buy_volume_eth,
        SUM(wd.sell_volume_eth) AS sell_volume_eth,
        SUM(wd.total_tx_count) AS tx_count,
        CAST(COUNT(CASE WHEN wd.is_top30_volume = TRUE THEN 1 END) AS INT) AS top30_days,
        CAST(COUNT(CASE WHEN wd.is_top100_balance = TRUE THEN 1 END) AS INT) AS top100_days,
        (SUM(CASE WHEN wd.profit_eth > 0 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0)) AS success_rate
    FROM 
        dwd.dwd_wallet_daily_stats wd
    WHERE 
        wd.wallet_date > COALESCE(
            (SELECT MAX(last_active_date) FROM dim_whale_address WHERE wallet_address = wd.wallet_address),
            '1970-01-01'
        )
    GROUP BY 
        wd.wallet_address
) stats
ON 
    dw.wallet_address = stats.wallet_address; 