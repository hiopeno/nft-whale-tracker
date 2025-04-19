-- 收藏集鲸鱼持有统计表 - 新增表

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

-- 创建收藏集鲸鱼持有统计表
CREATE TABLE IF NOT EXISTS dws_collection_whale_ownership (
    stat_date DATE,                          -- 统计日期
    collection_address VARCHAR(255),         -- 收藏集地址
    collection_name VARCHAR(255),            -- 收藏集名称
    total_nfts INT,                          -- NFT总数量
    total_owners INT,                        -- 持有者总数
    whale_owners INT,                        -- 鲸鱼持有者数
    whale_owned_nfts INT,                    -- 鲸鱼持有的NFT数量
    whale_ownership_percentage DECIMAL(10,2), -- 鲸鱼持有比例
    smart_whale_ownership_percentage DECIMAL(10,2), -- 聪明鲸鱼持有比例
    dumb_whale_ownership_percentage DECIMAL(10,2), -- 愚蠢鲸鱼持有比例
    total_value_eth DECIMAL(30,10),          -- 持有总价值(ETH)
    whale_owned_value_eth DECIMAL(30,10),    -- 鲸鱼持有价值(ETH)
    ownership_change_1d DECIMAL(10,2),       -- 持有比例1日变化
    ownership_change_7d DECIMAL(10,2),       -- 持有比例7日变化
    rank_by_whale_ownership INT,             -- 按鲸鱼持有比例排名
    is_in_working_set BOOLEAN,               -- 是否属于工作集
    data_source VARCHAR(100),                -- 数据来源
    etl_time TIMESTAMP,                      -- ETL处理时间
    PRIMARY KEY (stat_date, collection_address) NOT ENFORCED
) WITH (
    'bucket' = '8',
    'bucket-key' = 'collection_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'lookup',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 计算收藏集鲸鱼持有统计数据
INSERT INTO dws_collection_whale_ownership
WITH current_holdings AS (
    -- 计算当前持有情况
    SELECT 
        CURRENT_DATE AS stat_date,
        t.contract_address AS collection_address,
        MAX(t.collection_name) AS collection_name,
        CAST(COUNT(*) AS INT) AS total_nfts,
        CAST(COUNT(DISTINCT t.to_address) AS INT) AS total_owners,
        CAST(COUNT(DISTINCT CASE WHEN w.is_whale THEN t.to_address END) AS INT) AS whale_owners,
        CAST(COUNT(CASE WHEN w.is_whale THEN 1 END) AS INT) AS whale_owned_nfts,
        CAST(SUM(t.trade_price_eth) AS DECIMAL(30,10)) AS total_value_eth,
        CAST(SUM(CASE WHEN w.is_whale THEN t.trade_price_eth ELSE 0 END) AS DECIMAL(30,10)) AS whale_owned_value_eth,
        CAST(COUNT(CASE WHEN w.whale_type = 'SMART' THEN 1 END) AS INT) AS smart_whale_owned_nfts,
        CAST(COUNT(CASE WHEN w.whale_type = 'DUMB' THEN 1 END) AS INT) AS dumb_whale_owned_nfts,
        MAX(t.is_in_working_set) AS is_in_working_set
    FROM 
        dwd.dwd_transaction_clean t
    LEFT JOIN 
        dim.dim_whale_address w ON t.to_address = w.wallet_address
    WHERE 
        NOT EXISTS (
            -- 排除已卖出的NFT
            SELECT 1 FROM dwd.dwd_transaction_clean s
            WHERE s.from_address = t.to_address
            AND s.contract_address = t.contract_address
            AND s.token_id = t.token_id
            AND s.tx_date > t.tx_date
        )
    GROUP BY 
        t.contract_address
),
previous_day AS (
    -- 获取前一天的数据，用于计算1天变化
    SELECT 
        collection_address,
        whale_ownership_percentage
    FROM 
        dws_collection_whale_ownership
    WHERE 
        stat_date = TIMESTAMPADD(DAY, -1, CURRENT_DATE)
),
previous_week AS (
    -- 获取7天前的数据，用于计算7天变化
    SELECT 
        collection_address,
        whale_ownership_percentage
    FROM 
        dws_collection_whale_ownership
    WHERE 
        stat_date = TIMESTAMPADD(DAY, -7, CURRENT_DATE)
),
rankings AS (
    -- 计算排名
    SELECT 
        collection_address,
        CAST(ROW_NUMBER() OVER (ORDER BY 
            CASE WHEN total_nfts > 0 
                 THEN (whale_owned_nfts * 100.0 / total_nfts) 
                 ELSE 0 
            END DESC
        ) AS INT) AS rank_by_whale_ownership
    FROM 
        current_holdings
)
SELECT 
    ch.stat_date,
    ch.collection_address,
    ch.collection_name,
    ch.total_nfts,
    ch.total_owners,
    ch.whale_owners,
    ch.whale_owned_nfts,
    CAST(
        CASE 
            WHEN ch.total_nfts > 0 
            THEN (ch.whale_owned_nfts * 100.0 / ch.total_nfts) 
            ELSE 0 
        END 
    AS DECIMAL(10,2)) AS whale_ownership_percentage,
    CAST(
        CASE 
            WHEN ch.total_nfts > 0 
            THEN (ch.smart_whale_owned_nfts * 100.0 / ch.total_nfts) 
            ELSE 0 
        END 
    AS DECIMAL(10,2)) AS smart_whale_ownership_percentage,
    CAST(
        CASE 
            WHEN ch.total_nfts > 0 
            THEN (ch.dumb_whale_owned_nfts * 100.0 / ch.total_nfts) 
            ELSE 0 
        END 
    AS DECIMAL(10,2)) AS dumb_whale_ownership_percentage,
    ch.total_value_eth,
    ch.whale_owned_value_eth,
    -- 计算1天变化
    CAST(
        CASE 
            WHEN pd.whale_ownership_percentage > 0 
            THEN (
                (CASE WHEN ch.total_nfts > 0 THEN (ch.whale_owned_nfts * 100.0 / ch.total_nfts) ELSE 0 END) - pd.whale_ownership_percentage
            ) / pd.whale_ownership_percentage * 100
            ELSE 0 
        END
    AS DECIMAL(10,2)) AS ownership_change_1d,
    -- 计算7天变化
    CAST(
        CASE 
            WHEN pw.whale_ownership_percentage > 0 
            THEN (
                (CASE WHEN ch.total_nfts > 0 THEN (ch.whale_owned_nfts * 100.0 / ch.total_nfts) ELSE 0 END) - pw.whale_ownership_percentage
            ) / pw.whale_ownership_percentage * 100
            ELSE 0 
        END
    AS DECIMAL(10,2)) AS ownership_change_7d,
    r.rank_by_whale_ownership,
    ch.is_in_working_set,
    CAST('dwd_transaction_clean,dim_whale_address' AS VARCHAR(100)) AS data_source,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS etl_time
FROM 
    current_holdings ch
LEFT JOIN 
    previous_day pd ON ch.collection_address = pd.collection_address
LEFT JOIN 
    previous_week pw ON ch.collection_address = pw.collection_address
LEFT JOIN 
    rankings r ON ch.collection_address = r.collection_address; 