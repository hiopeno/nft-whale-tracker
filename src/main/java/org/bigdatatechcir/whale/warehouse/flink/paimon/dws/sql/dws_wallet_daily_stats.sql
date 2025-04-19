-- 钱包每日统计表 - 从DWD层迁移到DWS层

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

-- 创建钱包每日统计表
CREATE TABLE IF NOT EXISTS dws_wallet_daily_stats (
    wallet_date DATE,                      -- 统计日期
    wallet_address VARCHAR(255),           -- 钱包地址
    total_tx_count INT,                    -- 交易总数
    buy_count INT,                         -- 买入次数
    sell_count INT,                        -- 卖出次数
    buy_volume_eth DECIMAL(30,10),         -- 买入量(ETH)
    sell_volume_eth DECIMAL(30,10),        -- 卖出量(ETH)
    profit_eth DECIMAL(30,10),             -- 利润(ETH)
    profit_usd DECIMAL(30,10),             -- 利润(USD)
    roi_percentage DECIMAL(10,2),          -- 投资回报率
    collections_traded INT,                -- 交易的收藏集数量
    is_active BOOLEAN,                     -- 是否活跃
    is_whale_candidate BOOLEAN,            -- 是否鲸鱼候选
    is_top30_volume BOOLEAN,               -- 是否交易额Top30
    is_top100_balance BOOLEAN,             -- 是否余额Top100
    balance_eth DECIMAL(30,10),            -- 持仓余额(ETH)
    balance_usd DECIMAL(30,10),            -- 持仓余额(USD)
    data_source VARCHAR(100),              -- 数据来源
    etl_time TIMESTAMP,                    -- ETL处理时间
    PRIMARY KEY (wallet_date, wallet_address) NOT ENFORCED
) WITH (
    'bucket' = '10',
    'bucket-key' = 'wallet_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'lookup',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 计算钱包每日统计数据
INSERT INTO dws_wallet_daily_stats
WITH daily_buys AS (
    -- 每日买入统计
    SELECT 
        tx_date AS wallet_date,
        to_address AS wallet_address,
        CAST(COUNT(*) AS INT) AS buy_count,
        CAST(SUM(trade_price_eth) AS DECIMAL(30,10)) AS buy_volume_eth,
        CAST(COUNT(DISTINCT contract_address) AS INT) AS buy_collections
    FROM 
        dwd.dwd_transaction_clean
    GROUP BY 
        tx_date,
        to_address
),
daily_sells AS (
    -- 每日卖出统计
    SELECT 
        tx_date AS wallet_date,
        from_address AS wallet_address,
        CAST(COUNT(*) AS INT) AS sell_count,
        CAST(SUM(trade_price_eth) AS DECIMAL(30,10)) AS sell_volume_eth,
        CAST(COUNT(DISTINCT contract_address) AS INT) AS sell_collections
    FROM 
        dwd.dwd_transaction_clean
    GROUP BY 
        tx_date,
        from_address
),
daily_profits AS (
    -- 每日利润计算（简化逻辑，实际项目中可能需要更复杂的计算）
    SELECT 
        s.wallet_date,
        s.wallet_address,
        CAST((s.sell_volume_eth - COALESCE(b_prev.total_buy, 0)) AS DECIMAL(30,10)) AS profit_eth,
        CAST((s.sell_volume_eth - COALESCE(b_prev.total_buy, 0)) * 2500.00 AS DECIMAL(30,10)) AS profit_usd -- 使用简化汇率
    FROM 
        daily_sells s
    LEFT JOIN (
        -- 计算截至前一天的总买入
        SELECT 
            wallet_address,
            SUM(buy_volume_eth) AS total_buy
        FROM 
            daily_buys
        WHERE 
            wallet_date < CURRENT_DATE
        GROUP BY 
            wallet_address
    ) b_prev ON s.wallet_address = b_prev.wallet_address
    WHERE 
        s.wallet_date = CURRENT_DATE
),
wallet_balance AS (
    -- 计算钱包持仓余额
    SELECT 
        tx_date AS wallet_date,
        to_address AS wallet_address,
        CAST(SUM(trade_price_eth) AS DECIMAL(30,10)) AS balance_eth
    FROM 
        dwd.dwd_transaction_clean c
    WHERE 
        NOT EXISTS (
            -- 排除已卖出的NFT
            SELECT 1 FROM dwd.dwd_transaction_clean s
            WHERE s.from_address = c.to_address
            AND s.contract_address = c.contract_address
            AND s.token_id = c.token_id
            AND s.tx_date > c.tx_date
        )
    GROUP BY 
        tx_date,
        to_address
),
volume_rankings AS (
    -- 交易额排名
    SELECT 
        wallet_date,
        wallet_address,
        CASE WHEN ROW_NUMBER() OVER (PARTITION BY wallet_date ORDER BY (buy_volume_eth + COALESCE(sell_volume_eth, 0)) DESC) <= 30 
             THEN TRUE ELSE FALSE END AS is_top30_volume
    FROM (
        SELECT 
            COALESCE(b.wallet_date, s.wallet_date) AS wallet_date,
            COALESCE(b.wallet_address, s.wallet_address) AS wallet_address,
            COALESCE(b.buy_volume_eth, 0) AS buy_volume_eth,
            COALESCE(s.sell_volume_eth, 0) AS sell_volume_eth
        FROM 
            daily_buys b
        FULL OUTER JOIN 
            daily_sells s ON b.wallet_date = s.wallet_date AND b.wallet_address = s.wallet_address
    ) t
),
balance_rankings AS (
    -- 余额排名
    SELECT 
        wallet_date,
        wallet_address,
        CASE WHEN ROW_NUMBER() OVER (PARTITION BY wallet_date ORDER BY balance_eth DESC) <= 100 
             THEN TRUE ELSE FALSE END AS is_top100_balance
    FROM 
        wallet_balance
)
SELECT 
    COALESCE(b.wallet_date, s.wallet_date) AS wallet_date,
    COALESCE(b.wallet_address, s.wallet_address) AS wallet_address,
    CAST(COALESCE(b.buy_count, 0) + COALESCE(s.sell_count, 0) AS INT) AS total_tx_count,
    CAST(COALESCE(b.buy_count, 0) AS INT) AS buy_count,
    CAST(COALESCE(s.sell_count, 0) AS INT) AS sell_count,
    CAST(COALESCE(b.buy_volume_eth, 0) AS DECIMAL(30,10)) AS buy_volume_eth,
    CAST(COALESCE(s.sell_volume_eth, 0) AS DECIMAL(30,10)) AS sell_volume_eth,
    CAST(COALESCE(p.profit_eth, 0) AS DECIMAL(30,10)) AS profit_eth,
    CAST(COALESCE(p.profit_usd, 0) AS DECIMAL(30,10)) AS profit_usd,
    CAST(
        CASE WHEN COALESCE(b.buy_volume_eth, 0) > 0 
             THEN (COALESCE(p.profit_eth, 0) / COALESCE(b.buy_volume_eth, 0)) * 100 
             ELSE 0 
        END 
    AS DECIMAL(10,2)) AS roi_percentage,
    CAST(
        COALESCE(b.buy_collections, 0) + COALESCE(s.sell_collections, 0) - 
        COALESCE((SELECT COUNT(DISTINCT c1.contract_address) 
                 FROM dwd.dwd_transaction_clean c1 
                 WHERE c1.to_address = COALESCE(b.wallet_address, s.wallet_address) 
                 AND c1.tx_date = COALESCE(b.wallet_date, s.wallet_date)
                 AND EXISTS (
                     SELECT 1 FROM dwd.dwd_transaction_clean c2
                     WHERE c2.from_address = c1.to_address
                     AND c2.contract_address = c1.contract_address
                     AND c2.tx_date = c1.tx_date
                 )), 0)
    AS INT) AS collections_traded,
    CASE WHEN COALESCE(b.buy_count, 0) + COALESCE(s.sell_count, 0) > 0 
         THEN TRUE ELSE FALSE END AS is_active,
    CASE WHEN COALESCE(b.buy_volume_eth, 0) + COALESCE(s.sell_volume_eth, 0) > 10 -- 鲸鱼识别阈值
         THEN TRUE ELSE FALSE END AS is_whale_candidate,
    COALESCE(vr.is_top30_volume, FALSE) AS is_top30_volume,
    COALESCE(br.is_top100_balance, FALSE) AS is_top100_balance,
    CAST(COALESCE(wb.balance_eth, 0) AS DECIMAL(30,10)) AS balance_eth,
    CAST(COALESCE(wb.balance_eth, 0) * 2500.00 AS DECIMAL(30,10)) AS balance_usd, -- 使用简化汇率
    CAST('dwd_transaction_clean' AS VARCHAR(100)) AS data_source,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS etl_time
FROM 
    daily_buys b
FULL OUTER JOIN 
    daily_sells s ON b.wallet_date = s.wallet_date AND b.wallet_address = s.wallet_address
LEFT JOIN 
    daily_profits p ON COALESCE(b.wallet_date, s.wallet_date) = p.wallet_date 
    AND COALESCE(b.wallet_address, s.wallet_address) = p.wallet_address
LEFT JOIN 
    wallet_balance wb ON COALESCE(b.wallet_date, s.wallet_date) = wb.wallet_date 
    AND COALESCE(b.wallet_address, s.wallet_address) = wb.wallet_address
LEFT JOIN 
    volume_rankings vr ON COALESCE(b.wallet_date, s.wallet_date) = vr.wallet_date 
    AND COALESCE(b.wallet_address, s.wallet_address) = vr.wallet_address
LEFT JOIN 
    balance_rankings br ON COALESCE(b.wallet_date, s.wallet_date) = br.wallet_date 
    AND COALESCE(b.wallet_address, s.wallet_address) = br.wallet_address
WHERE 
    COALESCE(b.wallet_date, s.wallet_date) = CURRENT_DATE; 