-- 价格行为分析表
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

-- 创建DWD数据库
CREATE DATABASE IF NOT EXISTS dwd;

-- 创建价格行为表(聚焦价格分析)
CREATE TABLE IF NOT EXISTS dwd.dwd_price_behavior_inc (
    `id` STRING,
    `dt` STRING,
    `nftId` STRING,
    `collectionId` STRING,
    `collectionName` STRING,
    `transactionHash` STRING,
    `current_price` DOUBLE, -- 当前价格
    `previous_price` DOUBLE, -- 上一次价格
    `price_usd` DOUBLE, -- 美元计价
    `price_change` DOUBLE, -- 价格变动绝对值
    `price_change_percent` DOUBLE, -- 价格变动百分比
    `market_avg_price` DOUBLE, -- 市场平均价格
    `market_median_price` DOUBLE, -- 市场中位数价格
    `price_deviation` DOUBLE, -- 价格偏离度
    `floor_price` DOUBLE, -- 地板价
    `floor_price_ratio` DOUBLE, -- 相对地板价比例
    `is_floor_price` BOOLEAN, -- 是否是当日地板价
    `is_ceiling_price` BOOLEAN, -- 是否是当日天花板价
    `price_volatility` DOUBLE, -- 价格波动率
    `price_trend` STRING, -- 价格趋势(上涨/下跌/稳定)
    `abnormal_score` DOUBLE, -- 异常评分
    `is_outlier` BOOLEAN, -- 是否异常值
    `ts` TIMESTAMP(3), -- 交易时间
    `created_at` TIMESTAMP(3), -- 处理时间
    PRIMARY KEY (`id`) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'bucket-key' = 'id',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 创建临时视图：获取各NFT系列的地板价
CREATE TEMPORARY VIEW IF NOT EXISTS nft_collection_floor_price AS
SELECT 
    collectionId,
    dt,
    MIN(price) AS floor_price
FROM ods.ods_nft_transaction_inc
WHERE price > 0
GROUP BY collectionId, dt;

-- 创建临时视图：获取各NFT系列的天花板价
CREATE TEMPORARY VIEW IF NOT EXISTS nft_collection_ceiling_price AS
SELECT 
    collectionId,
    dt,
    MAX(price) AS ceiling_price
FROM ods.ods_nft_transaction_inc
WHERE price > 0
GROUP BY collectionId, dt;

-- 创建临时视图：获取各NFT系列的中位数价格
CREATE TEMPORARY VIEW IF NOT EXISTS nft_collection_median_price AS
SELECT 
    collectionId,
    dt,
    -- 简化的中位数计算，实际项目中可能需要更复杂的逻辑
    AVG(price) AS median_price
FROM ods.ods_nft_transaction_inc
WHERE price > 0
GROUP BY collectionId, dt;

-- 创建临时视图：计算波动率
CREATE TEMPORARY VIEW IF NOT EXISTS nft_price_volatility AS
SELECT
    nftId,
    dt,
    -- 简化的波动率计算，实际项目中可能需要标准差等统计方法
    (MAX(price) - MIN(price)) / NULLIF(AVG(price), 0) AS volatility
FROM ods.ods_nft_transaction_inc
WHERE price > 0
GROUP BY nftId, dt;

-- 将数据插入价格行为表
INSERT INTO dwd.dwd_price_behavior_inc
SELECT
    t.id,
    t.dt,
    t.nftId,
    t.collectionId,
    t.collectionName,
    t.transactionHash,
    t.price AS current_price,
    t.previousPrice AS previous_price,
    -- 计算美元价格(不依赖DWD层)
    CASE 
        WHEN t.currency = 'ETH' THEN t.price * 1800.0 -- 使用默认汇率
        ELSE t.priceUSD
    END AS price_usd,
    t.priceChange AS price_change,
    t.priceChangePercent AS price_change_percent,
    COALESCE(dwd.market_avg_price, mp.median_price) AS market_avg_price, -- 使用备选值
    mp.median_price AS market_median_price,
    -- 计算价格偏离度(使用计算的平均价格)
    CASE 
        WHEN mp.median_price IS NOT NULL AND mp.median_price > 0 THEN (t.price - mp.median_price) / mp.median_price
        ELSE 0
    END AS price_deviation,
    fp.floor_price,
    -- 相对于地板价的比例
    CASE 
        WHEN fp.floor_price > 0 THEN t.price / fp.floor_price
        ELSE NULL
    END AS floor_price_ratio,
    -- 判断是否是地板价
    CASE 
        WHEN t.price = fp.floor_price THEN true
        ELSE false
    END AS is_floor_price,
    -- 判断是否是天花板价
    CASE 
        WHEN t.price = cp.ceiling_price THEN true
        ELSE false
    END AS is_ceiling_price,
    v.volatility AS price_volatility,
    -- 确定价格趋势
    CASE
        WHEN t.priceChangePercent > 0.05 THEN 'UP'
        WHEN t.priceChangePercent < -0.05 THEN 'DOWN'
        ELSE 'STABLE'
    END AS price_trend,
    -- 独立计算异常评分
    CASE 
        WHEN t.isOutlier = true THEN 0.9
        WHEN ABS(COALESCE(t.priceChangePercent, 0)) > 0.5 THEN 0.7
        WHEN mp.median_price IS NOT NULL AND mp.median_price <> 0 AND 
             ABS((t.price - mp.median_price) / mp.median_price) > 0.3 THEN 0.5
        ELSE 0.1
    END AS abnormal_score,
    t.isOutlier AS is_outlier,
    -- 时间戳处理
    TO_TIMESTAMP(FROM_UNIXTIME(CAST(t.`timestamp` / 1000 AS BIGINT))) AS ts,
    CURRENT_TIMESTAMP AS created_at
FROM ods.ods_nft_transaction_inc t
LEFT JOIN dwd.dwd_nft_transaction_inc dwd ON t.id = dwd.id
LEFT JOIN nft_collection_floor_price fp ON t.collectionId = fp.collectionId AND t.dt = fp.dt
LEFT JOIN nft_collection_ceiling_price cp ON t.collectionId = cp.collectionId AND t.dt = cp.dt
LEFT JOIN nft_collection_median_price mp ON t.collectionId = mp.collectionId AND t.dt = mp.dt
LEFT JOIN nft_price_volatility v ON t.nftId = v.nftId AND t.dt = v.dt; 