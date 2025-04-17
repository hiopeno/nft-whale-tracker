-- 钱包每日统计数据

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
CREATE DATABASE IF NOT EXISTS dwd;
USE dwd;

-- 钱包每日统计表
CREATE TABLE IF NOT EXISTS dwd_wallet_daily_stats (
    wallet_date DATE,
    wallet_address VARCHAR(255),
    buy_count INT,
    sell_count INT,
    total_tx_count INT,
    buy_volume_eth DECIMAL(30,10),
    sell_volume_eth DECIMAL(30,10),
    net_flow_eth DECIMAL(30,10),
    buy_volume_usd DECIMAL(30,10),
    sell_volume_usd DECIMAL(30,10),
    net_flow_usd DECIMAL(30,10),
    profit_eth DECIMAL(30,10),
    profit_usd DECIMAL(30,10),
    collections_traded INT,
    working_set_collections_traded INT,
    is_top30_volume BOOLEAN,
    is_top100_balance BOOLEAN,
    rank_by_volume INT,
    rank_by_balance INT,
    is_whale_candidate BOOLEAN,
    data_source VARCHAR(100),
    etl_time TIMESTAMP,
    PRIMARY KEY (wallet_date, wallet_address) NOT ENFORCED
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

-- 插入数据
INSERT INTO dwd_wallet_daily_stats
WITH
-- 创建统一的钱包地址和日期映射表，包含所有参与交易的钱包
wallet_dates AS (
    SELECT DISTINCT 
        TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))) AS wallet_date,
        wallet_address
    FROM (
        -- 所有作为买家的钱包地址
        SELECT 
            tx_timestamp,
            to_address AS wallet_address
        FROM 
            ods.ods_collection_transaction_inc
        WHERE 
            trade_price > 0
            AND tx_timestamp > 0
            AND tx_timestamp < 253402271999000
            AND to_address IS NOT NULL
            
        UNION
        
        -- 所有作为卖家的钱包地址
        SELECT 
            tx_timestamp,
            from_address AS wallet_address
        FROM 
            ods.ods_collection_transaction_inc
        WHERE 
            trade_price > 0
            AND tx_timestamp > 0
            AND tx_timestamp < 253402271999000
            AND from_address IS NOT NULL
    )
),

-- 买入交易统计，基于统一的钱包-日期映射表
buy_transactions AS (
    SELECT 
        wd.wallet_date,
        wd.wallet_address,
        COUNT(CASE WHEN tx.to_address = wd.wallet_address THEN 1 END) AS buy_count,
        SUM(CASE WHEN tx.to_address = wd.wallet_address THEN tx.trade_price ELSE 0 END) AS buy_volume_eth,
        SUM(CASE WHEN tx.to_address = wd.wallet_address THEN tx.trade_price * 2500.00 ELSE 0 END) AS buy_volume_usd,
        COUNT(DISTINCT CASE WHEN tx.to_address = wd.wallet_address THEN tx.contract_address END) AS buy_collections
    FROM 
        wallet_dates wd
    LEFT JOIN
        ods.ods_collection_transaction_inc tx 
        ON wd.wallet_address = tx.to_address 
        AND wd.wallet_date = TO_DATE(FROM_UNIXTIME(CAST(tx.tx_timestamp/1000 AS BIGINT)))
        AND tx.trade_price > 0
    GROUP BY 
        wd.wallet_date,
        wd.wallet_address
),

-- 卖出交易统计，基于统一的钱包-日期映射表
sell_transactions AS (
    SELECT 
        wd.wallet_date,
        wd.wallet_address,
        COUNT(CASE WHEN tx.from_address = wd.wallet_address THEN 1 END) AS sell_count,
        SUM(CASE WHEN tx.from_address = wd.wallet_address THEN tx.trade_price ELSE 0 END) AS sell_volume_eth,
        SUM(CASE WHEN tx.from_address = wd.wallet_address THEN tx.trade_price * 2500.00 ELSE 0 END) AS sell_volume_usd,
        COUNT(DISTINCT CASE WHEN tx.from_address = wd.wallet_address THEN tx.contract_address END) AS sell_collections
    FROM 
        wallet_dates wd
    LEFT JOIN
        ods.ods_collection_transaction_inc tx 
        ON wd.wallet_address = tx.from_address 
        AND wd.wallet_date = TO_DATE(FROM_UNIXTIME(CAST(tx.tx_timestamp/1000 AS BIGINT)))
        AND tx.trade_price > 0
    GROUP BY 
        wd.wallet_date,
        wd.wallet_address
),

-- 合并处理收藏集 - 使用单独的CTE直接计算
collections_stats AS (
    SELECT
        wallet_date,
        wallet_address,
        COUNT(DISTINCT contract_address) AS unique_collections_traded
    FROM (
        -- 买入的收藏集
        SELECT
            TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))) AS wallet_date,
            to_address AS wallet_address,
            contract_address
        FROM 
            ods.ods_collection_transaction_inc
        WHERE 
            trade_price > 0
            AND tx_timestamp > 0
            AND tx_timestamp < 253402271999000
            AND to_address IS NOT NULL
        
        UNION
        
        -- 卖出的收藏集
        SELECT
            TO_DATE(FROM_UNIXTIME(CAST(tx_timestamp/1000 AS BIGINT))) AS wallet_date,
            from_address AS wallet_address,
            contract_address
        FROM 
            ods.ods_collection_transaction_inc
        WHERE 
            trade_price > 0
            AND tx_timestamp > 0
            AND tx_timestamp < 253402271999000
            AND from_address IS NOT NULL
    ) combined
    GROUP BY
        wallet_date,
        wallet_address
),

-- 处理工作集收藏集统计
working_collections_stats AS (
    SELECT
        combined.wallet_date,
        combined.wallet_address,
        COUNT(DISTINCT combined.contract_address) AS unique_working_collections_traded
    FROM (
        -- 买入的工作集收藏集
        SELECT
            TO_DATE(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT))) AS wallet_date,
            t.to_address AS wallet_address,
            t.contract_address
        FROM 
            ods.ods_collection_transaction_inc t
        JOIN
            ods.ods_collection_working_set w ON t.contract_address = w.collection_address
        WHERE 
            t.trade_price > 0
            AND t.tx_timestamp > 0
            AND t.tx_timestamp < 253402271999000
            AND t.to_address IS NOT NULL
        
        UNION
        
        -- 卖出的工作集收藏集
        SELECT
            TO_DATE(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT))) AS wallet_date,
            t.from_address AS wallet_address,
            t.contract_address
        FROM 
            ods.ods_collection_transaction_inc t
        JOIN
            ods.ods_collection_working_set w ON t.contract_address = w.collection_address
        WHERE 
            t.trade_price > 0
            AND t.tx_timestamp > 0
            AND t.tx_timestamp < 253402271999000
            AND t.from_address IS NOT NULL
    ) combined
    GROUP BY
        combined.wallet_date,
        combined.wallet_address
)

-- 最终数据聚合，从统一的钱包-日期映射表出发
SELECT 
    wd.wallet_date,
    wd.wallet_address,
    
    -- 买入卖出计数
    CAST(COALESCE(b.buy_count, 0) AS INT) AS buy_count,
    CAST(COALESCE(s.sell_count, 0) AS INT) AS sell_count,
    CAST(COALESCE(b.buy_count, 0) + COALESCE(s.sell_count, 0) AS INT) AS total_tx_count,
    
    -- 交易量计算
    CAST(COALESCE(b.buy_volume_eth, 0) AS DECIMAL(30,10)) AS buy_volume_eth,
    CAST(COALESCE(s.sell_volume_eth, 0) AS DECIMAL(30,10)) AS sell_volume_eth,
    CAST(COALESCE(b.buy_volume_eth, 0) - COALESCE(s.sell_volume_eth, 0) AS DECIMAL(30,10)) AS net_flow_eth,
    
    -- USD计算
    CAST(COALESCE(b.buy_volume_usd, 0) AS DECIMAL(30,10)) AS buy_volume_usd,
    CAST(COALESCE(s.sell_volume_usd, 0) AS DECIMAL(30,10)) AS sell_volume_usd,
    CAST(COALESCE(b.buy_volume_usd, 0) - COALESCE(s.sell_volume_usd, 0) AS DECIMAL(30,10)) AS net_flow_usd,
    
    -- 利润计算
    CAST(COALESCE(s.sell_volume_eth, 0) - COALESCE(b.buy_volume_eth, 0) AS DECIMAL(30,10)) AS profit_eth,
    CAST(COALESCE(s.sell_volume_usd, 0) - COALESCE(b.buy_volume_usd, 0) AS DECIMAL(30,10)) AS profit_usd,
    
    -- 收藏集统计
    CAST(COALESCE(cs.unique_collections_traded, 0) AS INT) AS collections_traded,
    CAST(COALESCE(wcs.unique_working_collections_traded, 0) AS INT) AS working_set_collections_traded,
    
    -- 鲸鱼相关字段
    CASE WHEN vw.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_top30_volume,
    CASE WHEN bw.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_top100_balance,
    COALESCE(vw.rank_num, 0) AS rank_by_volume,
    COALESCE(bw.rank_num, 0) AS rank_by_balance,
    CASE 
        WHEN vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL 
        OR (COALESCE(b.buy_volume_eth, 0) + COALESCE(s.sell_volume_eth, 0)) > 10 
        THEN TRUE ELSE FALSE 
    END AS is_whale_candidate,
    
    -- 元数据
    CAST('ods_collection_transaction_inc,ods_daily_top30_volume_wallets,ods_top100_balance_wallets' AS VARCHAR(100)) AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    wallet_dates wd
LEFT JOIN 
    buy_transactions b ON wd.wallet_date = b.wallet_date AND wd.wallet_address = b.wallet_address
LEFT JOIN 
    sell_transactions s ON wd.wallet_date = s.wallet_date AND wd.wallet_address = s.wallet_address
LEFT JOIN 
    collections_stats cs ON wd.wallet_date = cs.wallet_date AND wd.wallet_address = cs.wallet_address
LEFT JOIN 
    working_collections_stats wcs ON wd.wallet_date = wcs.wallet_date AND wd.wallet_address = wcs.wallet_address
LEFT JOIN 
    ods.ods_daily_top30_volume_wallets vw ON wd.wallet_address = vw.account_address
LEFT JOIN 
    ods.ods_top100_balance_wallets bw ON wd.wallet_address = bw.account_address
WHERE 
    wd.wallet_date IS NOT NULL
    AND wd.wallet_address IS NOT NULL; 