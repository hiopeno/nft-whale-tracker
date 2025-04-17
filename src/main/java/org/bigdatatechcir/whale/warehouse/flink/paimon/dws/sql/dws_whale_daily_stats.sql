-- 鲸鱼钱包每日交易汇总表

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

-- 创建鲸鱼钱包每日交易汇总表
CREATE TABLE IF NOT EXISTS dws_whale_daily_stats (
    stat_date DATE,
    wallet_address VARCHAR(255),
    whale_type VARCHAR(50),
    wallet_status VARCHAR(20),
    daily_trade_count INT,
    daily_buy_count INT,
    daily_sell_count INT,
    daily_buy_volume_eth DECIMAL(30,10),
    daily_sell_volume_eth DECIMAL(30,10),
    daily_profit_eth DECIMAL(30,10),
    daily_roi_percentage DECIMAL(10,2),
    daily_collections_traded INT,
    accu_profit_eth DECIMAL(30,10),
    accu_roi_percentage DECIMAL(10,2),
    holding_value_eth DECIMAL(30,10),
    holding_value_change_1d DECIMAL(10,2),
    holding_collections INT,
    holding_nfts INT,
    influence_score DECIMAL(10,2),
    success_rate_7d DECIMAL(10,2),
    success_rate_30d DECIMAL(10,2),
    avg_holding_days DECIMAL(10,2),
    is_top30_volume BOOLEAN,
    is_top100_balance BOOLEAN,
    rank_by_volume INT,
    rank_by_profit INT,
    rank_by_roi INT,
    data_source VARCHAR(100),
    etl_time TIMESTAMP,
    PRIMARY KEY (stat_date, wallet_address) NOT ENFORCED
) WITH (
    'bucket' = '8',
    'bucket-key' = 'wallet_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 计算并更新鲸鱼钱包每日交易汇总数据
INSERT INTO dws_whale_daily_stats
WITH prev_day_stats AS (
    -- 获取前一天的统计数据，用于计算变化
    SELECT 
        wallet_address,
        holding_value_eth
    FROM 
        dws_whale_daily_stats
),
daily_holdings AS (
    -- 估算当日持仓价值
    SELECT 
        tx.tx_date,
        tx.to_address AS wallet_address,
        SUM(tx.trade_price_eth) AS holding_value_eth,
        COUNT(DISTINCT tx.contract_address) AS holding_collections,
        COUNT(*) AS holding_nfts
    FROM 
        dwd.dwd_whale_transaction_detail tx
    LEFT JOIN 
        dwd.dwd_whale_transaction_detail sell ON tx.to_address = sell.from_address 
        AND tx.contract_address = sell.contract_address
        AND tx.token_id = sell.token_id
        AND sell.tx_date > tx.tx_date
    WHERE 
        tx.to_is_whale = TRUE
        AND sell.tx_hash IS NULL -- 未被卖出的NFT
    GROUP BY 
        tx.tx_date,
        tx.to_address
),
success_rates AS (
    -- 计算成功率
    SELECT 
        tx.tx_date,
        tx.from_address AS wallet_address,
        -- 7天成功率
        (COUNT(CASE WHEN tx.tx_date >= (CURRENT_DATE - INTERVAL '7' DAY) AND tx.trade_price_eth > tx.floor_price_eth THEN 1 END) * 100.0 / 
         NULLIF(COUNT(CASE WHEN tx.tx_date >= (CURRENT_DATE - INTERVAL '7' DAY) THEN 1 END), 0)) AS success_rate_7d,
        -- 30天成功率
        (COUNT(CASE WHEN tx.tx_date >= (CURRENT_DATE - INTERVAL '30' DAY) AND tx.trade_price_eth > tx.floor_price_eth THEN 1 END) * 100.0 / 
         NULLIF(COUNT(CASE WHEN tx.tx_date >= (CURRENT_DATE - INTERVAL '30' DAY) THEN 1 END), 0)) AS success_rate_30d
    FROM 
        dwd.dwd_whale_transaction_detail tx
    WHERE 
        tx.from_is_whale = TRUE
    GROUP BY 
        tx.tx_date,
        tx.from_address
),
holding_days AS (
    -- 计算平均持有天数
    SELECT 
        sell.tx_date,
        sell.from_address AS wallet_address,
        CASE 
            WHEN COUNT(*) > 0 
            THEN SUM(TIMESTAMPDIFF(DAY, buy.tx_date, sell.tx_date)) / COUNT(*) 
            ELSE 0 
        END AS avg_holding_days
    FROM 
        dwd.dwd_whale_transaction_detail sell
    JOIN 
        dwd.dwd_whale_transaction_detail buy ON sell.from_address = buy.to_address
        AND sell.contract_address = buy.contract_address
        AND sell.token_id = buy.token_id
        AND sell.tx_date > buy.tx_date
    WHERE 
        sell.from_is_whale = TRUE
    GROUP BY 
        sell.tx_date,
        sell.from_address
),
whale_rankings AS (
    -- 计算排名
    SELECT 
        wallet_date,
        wallet_address,
        ROW_NUMBER() OVER (PARTITION BY wallet_date ORDER BY buy_volume_eth + sell_volume_eth DESC) AS rank_by_volume,
        ROW_NUMBER() OVER (PARTITION BY wallet_date ORDER BY profit_eth DESC) AS rank_by_profit,
        ROW_NUMBER() OVER (PARTITION BY wallet_date ORDER BY 
            CASE WHEN buy_volume_eth > 0 THEN (profit_eth / buy_volume_eth) * 100 ELSE 0 END DESC) AS rank_by_roi
    FROM 
        dwd.dwd_wallet_daily_stats
)
SELECT 
    wd.wallet_date AS stat_date,
    wd.wallet_address,
    dwa.whale_type,
    dwa.status AS wallet_status,
    CAST(wd.total_tx_count AS INT) AS daily_trade_count,
    CAST(wd.buy_count AS INT) AS daily_buy_count,
    CAST(wd.sell_count AS INT) AS daily_sell_count,
    wd.buy_volume_eth AS daily_buy_volume_eth,
    wd.sell_volume_eth AS daily_sell_volume_eth,
    wd.profit_eth AS daily_profit_eth,
    CASE WHEN wd.buy_volume_eth > 0 THEN (wd.profit_eth / wd.buy_volume_eth) * 100 ELSE 0 END AS daily_roi_percentage,
    CAST(wd.collections_traded AS INT) AS daily_collections_traded,
    dwa.total_profit_eth AS accu_profit_eth,
    dwa.roi_percentage AS accu_roi_percentage,
    COALESCE(h.holding_value_eth, 0) AS holding_value_eth,
    CASE 
        WHEN p.holding_value_eth > 0 
        THEN ((COALESCE(h.holding_value_eth, 0) - p.holding_value_eth) / p.holding_value_eth) * 100 
        ELSE 0 
    END AS holding_value_change_1d,
    CAST(COALESCE(h.holding_collections, 0) AS INT) AS holding_collections,
    CAST(COALESCE(h.holding_nfts, 0) AS INT) AS holding_nfts,
    dwa.whale_score AS influence_score,
    COALESCE(sr.success_rate_7d, 0) AS success_rate_7d,
    COALESCE(sr.success_rate_30d, 0) AS success_rate_30d,
    COALESCE(hd.avg_holding_days, dwa.avg_hold_days) AS avg_holding_days,
    wd.is_top30_volume,
    wd.is_top100_balance,
    CAST(COALESCE(r.rank_by_volume, 0) AS INT) AS rank_by_volume,
    CAST(COALESCE(r.rank_by_profit, 0) AS INT) AS rank_by_profit,
    CAST(COALESCE(r.rank_by_roi, 0) AS INT) AS rank_by_roi,
    'dim_whale_address,dwd_wallet_daily_stats' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dwd.dwd_wallet_daily_stats wd
JOIN 
    dim.dim_whale_address dwa ON wd.wallet_address = dwa.wallet_address
LEFT JOIN 
    daily_holdings h ON wd.wallet_date = h.tx_date AND wd.wallet_address = h.wallet_address
LEFT JOIN 
    prev_day_stats p ON wd.wallet_address = p.wallet_address
LEFT JOIN 
    success_rates sr ON wd.wallet_date = sr.tx_date AND wd.wallet_address = sr.wallet_address
LEFT JOIN 
    holding_days hd ON wd.wallet_date = hd.tx_date AND wd.wallet_address = hd.wallet_address
LEFT JOIN 
    whale_rankings r ON wd.wallet_date = r.wallet_date AND wd.wallet_address = r.wallet_address
WHERE 
    dwa.is_whale = TRUE; 