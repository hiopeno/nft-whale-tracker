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
        CAST(SUM(tx.trade_price_eth) AS DECIMAL(30,10)) AS holding_value_eth,
        CAST(COUNT(DISTINCT tx.contract_address) AS INT) AS holding_collections,
        CAST(COUNT(*) AS INT) AS holding_nfts
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
avg_prices AS (
    -- 获取每个收藏集的平均价格，用于判断成功交易
    -- 使用CAST转换为DOUBLE类型以避免DECIMAL AVG的问题
    SELECT
        tx_date,
        contract_address,
        CAST(AVG(CAST(trade_price_eth AS DOUBLE)) AS DECIMAL(30,10)) AS avg_price_eth
    FROM
        dwd.dwd_whale_transaction_detail
    GROUP BY
        tx_date,
        contract_address
),
success_rates AS (
    -- 计算成功率 - 使用卖出价格与买入价格比较来判断成功交易
    SELECT 
        sell.tx_date,
        sell.from_address AS wallet_address,
        -- 7天成功率 - 卖出价格高于买入价格视为成功交易
        CAST(
            (COUNT(CASE WHEN sell.tx_date >= (CURRENT_DATE - INTERVAL '7' DAY) AND sell.trade_price_eth > buy.trade_price_eth THEN 1 END) * 100.0 / 
             NULLIF(COUNT(CASE WHEN sell.tx_date >= (CURRENT_DATE - INTERVAL '7' DAY) THEN 1 END), 0))
        AS DECIMAL(10,2)) AS success_rate_7d,
        -- 30天成功率
        CAST(
            (COUNT(CASE WHEN sell.tx_date >= (CURRENT_DATE - INTERVAL '30' DAY) AND sell.trade_price_eth > buy.trade_price_eth THEN 1 END) * 100.0 / 
             NULLIF(COUNT(CASE WHEN sell.tx_date >= (CURRENT_DATE - INTERVAL '30' DAY) THEN 1 END), 0))
        AS DECIMAL(10,2)) AS success_rate_30d
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
holding_days AS (
    -- 计算平均持有天数
    SELECT 
        sell.tx_date,
        sell.from_address AS wallet_address,
        -- 使用CAST转换为DOUBLE类型以避免DECIMAL平均值计算的问题
        CAST(
            CASE 
                WHEN COUNT(*) > 0 
                THEN AVG(CAST(TIMESTAMPDIFF(DAY, buy.tx_date, sell.tx_date) AS DOUBLE))
                ELSE 0 
            END
        AS DECIMAL(10,2)) AS avg_holding_days
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
-- 获取持有量排名(top100_balance_wallets)的信息
balance_rankings AS (
    SELECT 
        rank_date,
        account_address,
        CAST(ROW_NUMBER() OVER (PARTITION BY rank_date ORDER BY holding_volume DESC) AS INT) AS balance_rank
    FROM 
        ods.ods_top100_balance_wallets
),
-- 获取交易量排名(daily_top30_volume_wallets)的信息
volume_rankings AS (
    SELECT 
        rank_date,
        account_address,
        CAST(ROW_NUMBER() OVER (PARTITION BY rank_date ORDER BY trade_volume DESC) AS INT) AS volume_rank
    FROM 
        ods.ods_daily_top30_volume_wallets
),
-- 计算影响力评分
influence_scores AS (
    SELECT 
        wd.wallet_date AS stat_date,
        wd.wallet_address,
        -- 影响力评分计算：
        -- top100_balance_wallets排名占40分（每前进1名得0.4分）
        -- daily_top30_volume_wallets排名占60分（每前进1名得2分）
        CAST(
            (CASE 
                WHEN br.balance_rank IS NOT NULL THEN (100 - br.balance_rank) * 0.4
                ELSE 0
            END) +
            (CASE 
                WHEN vr.volume_rank IS NOT NULL THEN (30 - vr.volume_rank) * 2
                ELSE 0
            END)
        AS DECIMAL(10,2)) AS influence_score,
        (CASE WHEN vr.volume_rank <= 30 THEN TRUE ELSE FALSE END) AS is_top30_volume,
        (CASE WHEN br.balance_rank <= 100 THEN TRUE ELSE FALSE END) AS is_top100_balance
    FROM 
        dws.dws_wallet_daily_stats wd
    LEFT JOIN 
        balance_rankings br ON wd.wallet_date = CAST(br.rank_date AS DATE) AND wd.wallet_address = br.account_address
    LEFT JOIN 
        volume_rankings vr ON wd.wallet_date = CAST(vr.rank_date AS DATE) AND wd.wallet_address = vr.account_address
),
-- 获取所有鲸鱼钱包的交易数据，不限制日期
whale_wallet_data AS (
    SELECT 
        wd.wallet_date AS stat_date,
        wd.wallet_address,
        wd.buy_volume_eth,
        wd.sell_volume_eth,
        wd.profit_eth,
        wd.roi_percentage
    FROM 
        dws.dws_wallet_daily_stats wd
    JOIN 
        dim.dim_whale_address dwa ON wd.wallet_address = dwa.wallet_address
    WHERE 
        dwa.is_whale = TRUE
        -- 移除日期限制，处理所有历史数据
),
whale_rankings AS (
    -- 使用鲸鱼钱包数据集计算排名，按每个日期分别排名
    SELECT 
        stat_date,
        wallet_address,
        CAST(ROW_NUMBER() OVER (PARTITION BY stat_date ORDER BY (buy_volume_eth + sell_volume_eth) DESC) AS INT) AS rank_by_volume,
        CAST(ROW_NUMBER() OVER (PARTITION BY stat_date ORDER BY profit_eth DESC) AS INT) AS rank_by_profit,
        CAST(ROW_NUMBER() OVER (PARTITION BY stat_date ORDER BY roi_percentage DESC) AS INT) AS rank_by_roi
    FROM 
        whale_wallet_data
),
-- 重写累积收益计算逻辑以匹配新的钱包统计表的计算方式
accu_stats AS (
    -- 获取钱包最近30天的交易数据和投资金额，计算累计收益
    SELECT 
        s.wallet_address,
        SUM(s.profit_eth) AS total_profit_eth,
        SUM(b.invested_eth) AS total_invested_eth
    FROM (
        SELECT 
            wallet_date,
            wallet_address,
            profit_eth
        FROM 
            dws.dws_wallet_daily_stats
        WHERE 
            wallet_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE)
    ) s
    LEFT JOIN (
        -- 从单独的表或CTE中获取投资信息
        -- 这里我们假设有一个named_result_column叫invested_eth
        SELECT 
            wallet_date,
            wallet_address,
            -- 这里理想情况下应该有一个字段记录实际投资金额
            -- 如果没有，可以从nft_profits表中直接计算
            0 AS invested_eth -- 这是一个占位符，实际实现中应该使用真实数据
        FROM 
            dws.dws_wallet_daily_stats
        WHERE 
            wallet_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE)
    ) b ON s.wallet_date = b.wallet_date AND s.wallet_address = b.wallet_address
    GROUP BY 
        s.wallet_address
),
accumulative_profits AS (
    -- 计算累计利润和ROI
    SELECT 
        wallet_address,
        CAST(COALESCE(total_profit_eth, 0) AS DECIMAL(30, 10)) AS accu_profit_eth,
        CAST(
            CASE 
                WHEN COALESCE(total_invested_eth, 0) > 0 
                THEN (COALESCE(total_profit_eth, 0) / COALESCE(total_invested_eth, 0)) * 100
                -- 如果没有投资数据，则使用已有的dws_wallet_daily_stats表的计算逻辑作为备选
                ELSE (
                    SELECT 
                        CASE 
                            WHEN SUM(buy_volume_eth) > 0 
                            THEN (SUM(profit_eth) / SUM(buy_volume_eth)) * 100
                            ELSE 0
                        END
                    FROM 
                        dws.dws_wallet_daily_stats
                    WHERE 
                        wallet_address = a.wallet_address
                        AND wallet_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE)
                )
            END
        AS DECIMAL(10, 2)) AS accu_roi_percentage
    FROM 
        accu_stats a
)
SELECT 
    wd.wallet_date AS stat_date,
    wd.wallet_address,
    dwa.whale_type,
    dwa.status AS wallet_status,
    CAST(wd.total_tx_count AS INT) AS daily_trade_count,
    CAST(wd.buy_count AS INT) AS daily_buy_count,
    CAST(wd.sell_count AS INT) AS daily_sell_count,
    CAST(wd.buy_volume_eth AS DECIMAL(30,10)) AS daily_buy_volume_eth,
    CAST(wd.sell_volume_eth AS DECIMAL(30,10)) AS daily_sell_volume_eth,
    CAST(wd.profit_eth AS DECIMAL(30,10)) AS daily_profit_eth,
    -- 使用钱包统计表中计算好的ROI
    CAST(wd.roi_percentage AS DECIMAL(10,2)) AS daily_roi_percentage,
    CAST(wd.collections_traded AS INT) AS daily_collections_traded,
    CAST(COALESCE(ap.accu_profit_eth, 0) AS DECIMAL(30,10)) AS accu_profit_eth,
    CAST(COALESCE(ap.accu_roi_percentage, 0) AS DECIMAL(10,2)) AS accu_roi_percentage,
    CAST(COALESCE(h.holding_value_eth, 0) AS DECIMAL(30,10)) AS holding_value_eth,
    CAST(
        CASE 
            WHEN p.holding_value_eth > 0 
            THEN ((COALESCE(h.holding_value_eth, 0) - p.holding_value_eth) / p.holding_value_eth) * 100 
            ELSE 0 
        END
    AS DECIMAL(10,2)) AS holding_value_change_1d,
    CAST(COALESCE(h.holding_collections, 0) AS INT) AS holding_collections,
    CAST(COALESCE(h.holding_nfts, 0) AS INT) AS holding_nfts,
    -- 使用新的影响力评分计算方法
    CAST(COALESCE(inf_score.influence_score, 0) AS DECIMAL(10,2)) AS influence_score,
    CAST(COALESCE(sr.success_rate_7d, 0) AS DECIMAL(10,2)) AS success_rate_7d,
    CAST(COALESCE(sr.success_rate_30d, 0) AS DECIMAL(10,2)) AS success_rate_30d,
    CAST(COALESCE(hd.avg_holding_days, 0) AS DECIMAL(10,2)) AS avg_holding_days,
    -- 使用新的top30和top100标记
    COALESCE(inf_score.is_top30_volume, FALSE) AS is_top30_volume,
    COALESCE(inf_score.is_top100_balance, FALSE) AS is_top100_balance,
    CAST(COALESCE(r.rank_by_volume, 0) AS INT) AS rank_by_volume,
    CAST(COALESCE(r.rank_by_profit, 0) AS INT) AS rank_by_profit,
    CAST(COALESCE(r.rank_by_roi, 0) AS INT) AS rank_by_roi,
    CAST('dim_whale_address,dws_wallet_daily_stats,ods_top100_balance_wallets,ods_daily_top30_volume_wallets' AS VARCHAR(100)) AS data_source,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS etl_time
FROM 
    dws.dws_wallet_daily_stats wd
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
    whale_rankings r ON wd.wallet_date = r.stat_date AND wd.wallet_address = r.wallet_address
LEFT JOIN
    accumulative_profits ap ON wd.wallet_address = ap.wallet_address
LEFT JOIN
    influence_scores inf_score ON wd.wallet_date = inf_score.stat_date AND wd.wallet_address = inf_score.wallet_address
WHERE 
    dwa.is_whale = TRUE; 