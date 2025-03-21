-- 交易域NFT交易明细表
SET 'execution.checkpointing.interval' = '5s';
SET 'execution.checkpointing.timeout' = '60s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '2s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'table.exec.resource.default-parallelism' = '2';
SET 'pipeline.name' = 'NFT-Transaction-DWD-Processing';

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

-- 创建交易明细表(标准化和丰富ODS层数据)
CREATE TABLE IF NOT EXISTS dwd.dwd_nft_transaction_inc (
    `id` STRING,
    `dt` STRING,
    `transactionHash` STRING,
    `tokenId` STRING,
    `nftId` STRING,
    `collectionId` STRING,
    `collectionName` STRING,
    `seller` STRING,
    `buyer` STRING,
    `price` DOUBLE,
    `price_usd` DOUBLE, -- 美元统一计价
    `price_eth` DOUBLE, -- ETH计价(如果原始不是ETH则转换)
    `currency` STRING,
    `transactionType` STRING,
    `marketplace` STRING,
    `marketplaceFee` DOUBLE,
    `royaltyFee` DOUBLE,
    `gasFee` DOUBLE,
    `totalFee` DOUBLE, -- 总费用
    `feeRatio` DOUBLE, -- 费用占比
    `status` STRING,
    `ts` TIMESTAMP(3), -- 交易时间戳(标准化)
    `date_id` STRING, -- 日期ID
    `hour_id` STRING, -- 小时ID
    `blockNumber` STRING,
    `isWhaleTransaction` BOOLEAN,
    `whaleType` STRING, -- 巨鲸类型(卖方/买方/双方)
    `priceUSD` DOUBLE,
    `previousPrice` DOUBLE,
    `priceChange` DOUBLE,
    `priceChangePercent` DOUBLE,
    `market_avg_price` DOUBLE, -- 市场平均价格
    `floor_price_ratio` DOUBLE, -- 相对地板价比例
    `isOutlier` BOOLEAN,
    `floorDifference` DOUBLE,
    `abnormal_score` DOUBLE, -- 异常评分
    `transaction_speed` STRING, -- 交易速度(快/中/慢)
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

-- 创建临时市场平均价格视图(按照收藏集分组计算)
CREATE TEMPORARY VIEW IF NOT EXISTS avg_price_by_collection AS
SELECT 
    collectionId,
    AVG(price) AS avg_price
FROM ods.ods_nft_transaction_inc
GROUP BY collectionId;

-- 创建临时ETH-USD转换率视图(简化示例,实际项目中可能需要外部数据源)
CREATE TEMPORARY VIEW IF NOT EXISTS eth_usd_rates AS
SELECT 1800.0 AS eth_usd_rate;

-- 将ODS数据转换并插入DWD层
INSERT INTO dwd.dwd_nft_transaction_inc
SELECT
    t.id,
    t.dt,
    t.transactionHash,
    t.tokenId,
    t.nftId,
    t.collectionId,
    t.collectionName,
    t.seller,
    t.buyer,
    t.price,
    -- 价格转换逻辑
    CASE 
        WHEN t.currency = 'ETH' THEN t.price * COALESCE(r.eth_usd_rate, 1800.0)
        ELSE t.priceUSD
    END AS price_usd,
    CASE 
        WHEN t.currency = 'ETH' THEN t.price
        ELSE COALESCE(t.priceUSD / r.eth_usd_rate, t.price / 1800.0)
    END AS price_eth,
    t.currency,
    t.transactionType,
    t.marketplace,
    t.marketplaceFee,
    t.royaltyFee,
    t.gasFee,
    -- 计算总费用和费用比例
    COALESCE(t.marketplaceFee, 0) + COALESCE(t.royaltyFee, 0) + COALESCE(t.gasFee, 0) AS totalFee,
    CASE 
        WHEN t.price > 0 THEN (COALESCE(t.marketplaceFee, 0) + COALESCE(t.royaltyFee, 0) + COALESCE(t.gasFee, 0)) / t.price
        ELSE 0
    END AS feeRatio,
    t.status,
    -- 时间戳处理
    TO_TIMESTAMP(FROM_UNIXTIME(CAST(`timestamp` / 1000 AS BIGINT))) AS ts,
    t.dt AS date_id,
    FROM_UNIXTIME(CAST(`timestamp` / 1000 AS BIGINT), 'yyyy-MM-dd HH') AS hour_id,
    t.blockNumber,
    t.isWhaleTransaction,
    -- 确定巨鲸类型(基于交易标记和价格)
    CASE
        WHEN t.isWhaleTransaction = true AND t.seller IS NOT NULL AND t.buyer IS NOT NULL THEN 'BOTH'
        WHEN t.isWhaleTransaction = true AND t.seller IS NOT NULL THEN 'SELLER'
        WHEN t.isWhaleTransaction = true AND t.buyer IS NOT NULL THEN 'BUYER'
        WHEN t.price > 10.0 THEN 'POTENTIAL' -- 高价值交易可能是巨鲸
        ELSE 'NONE'
    END AS whaleType,
    t.priceUSD,
    t.previousPrice,
    t.priceChange,
    t.priceChangePercent,
    -- 市场相关分析
    a.avg_price AS market_avg_price,
    CASE 
        WHEN t.floorDifference IS NOT NULL THEN t.price / (t.price - t.floorDifference) 
        ELSE NULL
    END AS floor_price_ratio,
    t.isOutlier,
    t.floorDifference,
    -- 异常评分计算
    CASE 
        WHEN t.isOutlier = true THEN 0.9
        WHEN ABS(COALESCE(t.priceChangePercent, 0)) > 0.5 THEN 0.7
        WHEN a.avg_price IS NOT NULL AND a.avg_price <> 0 AND ABS((t.price - a.avg_price) / a.avg_price) > 0.3 THEN 0.5
        ELSE 0.1
    END AS abnormal_score,
    -- 交易速度分类
    CASE
        WHEN t.gasFee > 0.01 THEN 'FAST'
        WHEN t.gasFee > 0.005 THEN 'MEDIUM'
        ELSE 'SLOW'
    END AS transaction_speed,
    CURRENT_TIMESTAMP AS created_at
FROM ods.ods_nft_transaction_inc t
LEFT JOIN avg_price_by_collection a ON t.collectionId = a.collectionId
CROSS JOIN eth_usd_rates r
WHERE t.dt IS NOT NULL; 