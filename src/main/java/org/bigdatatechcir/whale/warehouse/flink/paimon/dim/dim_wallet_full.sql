-- 钱包维度表
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';

-- 创建Paimon Catalog
CREATE CATALOG paimon_hive WITH (
    'type' = 'paimon',
    'metastore' = 'hive',
    'uri' = 'thrift://192.168.254.133:9083',
    'hive-conf-dir' = '/opt/software/apache-hive-3.1.3-bin/conf',
    'hadoop-conf-dir' = '/opt/software/hadoop-3.1.3/etc/hadoop',
    'warehouse' = 'hdfs:////user/hive/warehouse'
);

-- 使用Paimon Catalog
USE CATALOG paimon_hive;

-- 创建DIM数据库
CREATE DATABASE IF NOT EXISTS dim;

-- 创建钱包维度表
CREATE TABLE IF NOT EXISTS dim.dim_wallet_full (
    `address` STRING, -- 钱包地址
    `wallet_type` STRING, -- 钱包类型：whale(巨鲸)/institutional(机构)/retail(零售)
    `wallet_label` STRING, -- 钱包标签(如知名投资者等)
    `total_asset_value_usd` DOUBLE, -- 资产总值(USD)
    `total_asset_value_eth` DOUBLE, -- 资产总值(ETH)
    `total_transaction_count` BIGINT, -- 总交易次数
    `total_buy_count` BIGINT, -- 总买入次数
    `total_sell_count` BIGINT, -- 总卖出次数
    `total_volume_usd` DOUBLE, -- 总交易额(USD)
    `total_volume_eth` DOUBLE, -- 总交易额(ETH)
    `first_transaction_time` TIMESTAMP(3), -- 首次交易时间
    `last_transaction_time` TIMESTAMP(3), -- 最后交易时间
    `active_days` INT, -- 活跃天数
    `activity_score` DOUBLE, -- 活跃度评分
    `preferred_marketplace` STRING, -- 偏好交易平台
    `preferred_collections` STRING, -- 偏好NFT系列(JSON数组)
    `holding_collections` STRING, -- 当前持有系列(JSON数组)
    `holding_nfts` STRING, -- 当前持有NFT(JSON数组)
    `profit_loss_usd` DOUBLE, -- 盈亏(USD)
    `profit_loss_percent` DOUBLE, -- 盈亏百分比
    `trading_strategy` STRING, -- 交易策略(长期持有/短期交易等)
    `is_active` BOOLEAN, -- 是否活跃
    `risk_score` DOUBLE, -- 风险评分
    `influence_score` DOUBLE, -- 影响力评分
    `associated_addresses` STRING, -- 关联地址(JSON数组)
    `updated_at` TIMESTAMP(3), -- 更新时间
    PRIMARY KEY (`address`) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'bucket-key' = 'address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'lookup',
    'changelog-producer.lookup.db' = 'dim',
    'changelog-producer.lookup.table' = 'dim_wallet_full'
);

-- 创建临时视图：市场使用统计
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_marketplaces AS
SELECT
    wallet_address,
    LISTAGG(marketplace, ',') AS used_marketplaces
FROM (
    SELECT DISTINCT
        buyer AS wallet_address,
        marketplace
    FROM dwd.dwd_nft_transaction_inc
    WHERE buyer IS NOT NULL AND marketplace IS NOT NULL
    
    UNION
    
    SELECT DISTINCT
        seller AS wallet_address,
        marketplace
    FROM dwd.dwd_nft_transaction_inc
    WHERE seller IS NOT NULL AND marketplace IS NOT NULL
) t
GROUP BY wallet_address;

-- 创建临时视图：钱包汇总统计
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_stats AS
SELECT
    wallet_address,
    SUM(CAST(1 AS INT)) AS transaction_count,
    COUNT(DISTINCT CASE WHEN buyer = wallet_address THEN transactionHash END) AS buy_count,
    COUNT(DISTINCT CASE WHEN seller = wallet_address THEN transactionHash END) AS sell_count,
    SUM(CASE WHEN buyer = wallet_address THEN price ELSE 0 END) AS total_buy_value,
    SUM(CASE WHEN seller = wallet_address THEN price ELSE 0 END) AS total_sell_value,
    COUNT(DISTINCT collectionId) AS collections_interacted,
    COUNT(DISTINCT nftId) AS nfts_interacted,
    COUNT(DISTINCT DATE_FORMAT(ts, 'yyyy-MM-dd')) AS active_days,
    MAX(ts) AS last_transaction,
    MIN(ts) AS first_transaction,
    -- 计算钱包交易的平均价格
    AVG(price) AS avg_price,
    -- 最常交易的NFT集合ID (使用多步骤计算)
    '' AS favorite_collection,  -- 稍后在外部获取
    -- 简化风险评分计算
    0.5 + ABS(HASH_CODE(wallet_address) % 100) / 200.0 AS risk_score,  -- 范围0.5~1.0的确定性随机数
    -- 简化影响力评分计算
    0.3 + ABS(HASH_CODE(wallet_address) % 100) / 166.7 AS influence_score  -- 范围0.3~0.9的确定性随机数
FROM (
    SELECT 
        transactionHash,
        nftId,
        collectionId,
        buyer,
        seller,
        price,
        ts,
        marketplace,
        buyer AS wallet_address
    FROM dwd.dwd_nft_transaction_inc 
    WHERE buyer IS NOT NULL

    UNION ALL

    SELECT 
        transactionHash,
        nftId,
        collectionId,
        buyer,
        seller,
        price,
        ts,
        marketplace,
        seller AS wallet_address
    FROM dwd.dwd_nft_transaction_inc 
    WHERE seller IS NOT NULL
) t
GROUP BY wallet_address;

-- 创建临时视图：钱包偏好的NFT集合
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_favorites AS
SELECT
    wallet_address,
    favorite_collection
FROM (
    SELECT
        wallet_address,
        collectionId AS favorite_collection,
        SUM(CAST(1 AS INT)) AS txn_times,
        ROW_NUMBER() OVER (PARTITION BY wallet_address ORDER BY SUM(CAST(1 AS INT)) DESC) AS rn
    FROM (
        SELECT buyer AS wallet_address, collectionId FROM dwd.dwd_nft_transaction_inc WHERE buyer IS NOT NULL
        UNION ALL
        SELECT seller AS wallet_address, collectionId FROM dwd.dwd_nft_transaction_inc WHERE seller IS NOT NULL
    ) t
    WHERE collectionId IS NOT NULL
    GROUP BY wallet_address, collectionId
) ranked
WHERE rn = 1;

-- 创建临时视图：活跃状态判断
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_active_status AS
SELECT
    wallet_address,
    last_transaction,
    -- 如果最后交易时间在30天内，则认为活跃
    CASE 
        WHEN last_transaction IS NOT NULL AND 
             CAST(TIMESTAMPDIFF(DAY, CAST(last_transaction AS TIMESTAMP), CAST(CURRENT_TIMESTAMP AS TIMESTAMP)) AS INT) <= 30
        THEN TRUE
        ELSE FALSE
    END AS is_active
FROM wallet_stats;

-- 插入钱包维度表
INSERT INTO dim.dim_wallet_full
SELECT
    ws.wallet_address AS address,
    CASE
        WHEN ws.transaction_count > 100 AND 
             (ws.avg_price > 10.0 OR ws.total_buy_value > 1000.0) THEN 'whale'
        WHEN ws.transaction_count > 50 THEN 'frequent_trader'
        WHEN ws.avg_price > 20.0 THEN 'high_value'
        ELSE 'retail'
    END AS wallet_type,
    -- 钱包标签
    'Retail User' AS wallet_label,
    -- 总值估计
    ws.total_buy_value * 1.2 AS total_asset_value_eth,
    ws.total_buy_value * 1.2 * 2200 AS total_asset_value_usd,
    CAST(ws.transaction_count AS BIGINT) AS total_transaction_count,
    CAST(ws.buy_count AS BIGINT) AS total_buy_count,
    CAST(ws.sell_count AS BIGINT) AS total_sell_count,
    ws.total_buy_value * 2200 AS total_volume_usd,
    ws.total_buy_value AS total_volume_eth,
    ws.first_transaction AS first_transaction_time,
    ws.last_transaction AS last_transaction_time,
    CAST(ws.active_days AS INT) AS active_days,
    -- 活跃度评分
    CASE
        WHEN ws.transaction_count > 0 THEN LOG10(ws.transaction_count) / 3
        ELSE 0
    END AS activity_score,
    -- 偏好市场
    COALESCE(wm.used_marketplaces, '') AS preferred_marketplace,
    -- 偏好NFT系列
    CONCAT('["', COALESCE(wf.favorite_collection, ''), '"]') AS preferred_collections,
    -- 持仓假设
    '[]' AS holding_collections,
    '[]' AS holding_nfts,
    -- 盈亏估算
    ws.total_sell_value - ws.total_buy_value AS profit_loss_usd,
    CASE
        WHEN ws.total_buy_value > 0 THEN (ws.total_sell_value - ws.total_buy_value) / ws.total_buy_value
        ELSE 0.0
    END AS profit_loss_percent,
    -- 交易策略
    CASE
        WHEN ws.buy_count > ws.sell_count * 2 THEN 'collector'
        WHEN ws.sell_count > ws.buy_count * 2 THEN 'seller'
        ELSE 'trader'
    END AS trading_strategy,
    -- 活跃状态判断
    COALESCE(was.is_active, FALSE) AS is_active,
    -- 风险和影响力评分
    CAST(COALESCE(ws.risk_score, 0.5) AS DOUBLE) AS risk_score,
    CAST(COALESCE(ws.influence_score, 0.3) AS DOUBLE) AS influence_score,
    -- 关联地址
    '[]' AS associated_addresses,
    CURRENT_TIMESTAMP AS updated_at
FROM wallet_stats ws
LEFT JOIN wallet_marketplaces wm ON ws.wallet_address = wm.wallet_address
LEFT JOIN wallet_favorites wf ON ws.wallet_address = wf.wallet_address
LEFT JOIN wallet_active_status was ON ws.wallet_address = was.wallet_address; 