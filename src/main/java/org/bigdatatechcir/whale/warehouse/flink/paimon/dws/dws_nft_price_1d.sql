-- NFT价格日汇总表
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'table.exec.resource.default-parallelism' = '2';
SET 'pipeline.name' = 'NFT-Price-DWS-Processing';

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

-- 创建DWS数据库(如果不存在)
CREATE DATABASE IF NOT EXISTS dws;

-- 创建NFT价格日汇总表
CREATE TABLE IF NOT EXISTS dws.dws_nft_price_1d (
  `collection_id` STRING,
  `dt` STRING,
  `daily_transaction_count` BIGINT,
  `daily_volume_usd` DOUBLE,
  `floor_price` DOUBLE,
  `avg_price` DOUBLE,
  `max_price` DOUBLE,
  `min_price` DOUBLE,
  `price_volatility` DOUBLE, -- 价格波动率
  `price_momentum` DOUBLE, -- 价格动量
  `whale_attention_ratio` DOUBLE, -- 鲸鱼关注度
  `liquidity_score` DOUBLE, -- 流动性评分
  `price_trend_prediction` STRING, -- 'UP'/'DOWN'/'STABLE'
  `updated_at` TIMESTAMP(3),
  PRIMARY KEY (`collection_id`, `dt`) NOT ENFORCED
) WITH (
  'bucket' = '8',
  'bucket-key' = 'collection_id',
  'file.format' = 'parquet',
  'merge-engine' = 'deduplicate',
  'changelog-producer' = 'input',
  'compaction.min.file-num' = '5',
  'compaction.max.file-num' = '50',
  'compaction.target-file-size' = '256MB'
);

-- 创建临时视图：每日NFT系列交易基本统计
CREATE TEMPORARY VIEW IF NOT EXISTS daily_collection_stats AS
SELECT
  dt,
  collectionId AS collection_id,
  COUNT(DISTINCT id) AS transaction_count,
  SUM(price_usd) AS volume_usd,
  MIN(CASE WHEN price > 0 THEN price ELSE NULL END) AS min_price,
  MAX(price) AS max_price,
  AVG(price) AS avg_price
FROM dwd.dwd_nft_transaction_inc
WHERE collectionId IS NOT NULL
GROUP BY dt, collectionId;

-- 创建临时视图：每日地板价计算(每日系列最低成交价)
CREATE TEMPORARY VIEW IF NOT EXISTS daily_floor_price AS
SELECT
  dt,
  collectionId AS collection_id,
  MIN(CASE WHEN price > 0 THEN price ELSE NULL END) AS floor_price
FROM dwd.dwd_nft_transaction_inc
WHERE collectionId IS NOT NULL
GROUP BY dt, collectionId;

-- 创建临时视图：鲸鱼交易占比计算
CREATE TEMPORARY VIEW IF NOT EXISTS daily_whale_attention AS
SELECT
  dt,
  collectionId AS collection_id,
  -- 鲸鱼交易数量占总交易数量的比例
  SUM(CASE WHEN isWhaleTransaction = true THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS whale_transaction_ratio,
  -- 鲸鱼交易金额占总交易金额的比例
  SUM(CASE WHEN isWhaleTransaction = true THEN price_usd ELSE 0 END) / NULLIF(SUM(price_usd), 0) AS whale_volume_ratio,
  -- 整合两个指标为鲸鱼关注度
  0.4 * SUM(CASE WHEN isWhaleTransaction = true THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) +
  0.6 * SUM(CASE WHEN isWhaleTransaction = true THEN price_usd ELSE 0 END) / NULLIF(SUM(price_usd), 0) AS whale_attention_ratio
FROM dwd.dwd_nft_transaction_inc
WHERE collectionId IS NOT NULL
GROUP BY dt, collectionId;

-- 创建临时视图：计算价格波动率
CREATE TEMPORARY VIEW IF NOT EXISTS price_volatility AS
SELECT
  dt,
  collectionId AS collection_id,
  -- 单日内价格波动率计算
  CASE
    WHEN COUNT(*) <= 1 THEN 0.0 -- 单笔交易无波动率
    WHEN AVG(price) = 0 THEN 0.0 -- 避免除零
    ELSE STDDEV_POP(price) / NULLIF(AVG(price), 0) -- 价格标准差/平均价格
  END AS price_volatility
FROM dwd.dwd_nft_transaction_inc
WHERE collectionId IS NOT NULL
GROUP BY dt, collectionId;

-- 创建临时视图：计算价格动量(与前一日比较)
CREATE TEMPORARY VIEW IF NOT EXISTS price_momentum AS
SELECT
  current_day.dt,
  current_day.collection_id,
  -- 价格动量计算(当日均价相对前一日变化百分比)
  CASE
    WHEN prev_day.avg_price IS NULL OR prev_day.avg_price = 0 THEN 0.0
    ELSE (current_day.avg_price - prev_day.avg_price) / prev_day.avg_price
  END AS price_momentum,
  -- 价格趋势预测
  CASE
    WHEN prev_day.avg_price IS NULL THEN 'STABLE'
    WHEN (current_day.avg_price - prev_day.avg_price) / NULLIF(prev_day.avg_price, 0) > 0.1 THEN 'UP'
    WHEN (current_day.avg_price - prev_day.avg_price) / NULLIF(prev_day.avg_price, 0) < -0.1 THEN 'DOWN'
    ELSE 'STABLE'
  END AS price_trend_prediction
FROM daily_collection_stats current_day
LEFT JOIN (
  -- 获取前一日数据
  SELECT 
    dt,
    collection_id,
    avg_price
  FROM daily_collection_stats
) prev_day 
ON current_day.collection_id = prev_day.collection_id 
AND TO_DATE(current_day.dt, 'yyyy-MM-dd') = TO_DATE(prev_day.dt, 'yyyy-MM-dd') + INTERVAL '1' DAY;

-- 创建临时视图：计算流动性评分
CREATE TEMPORARY VIEW IF NOT EXISTS liquidity_score AS
SELECT
  dt,
  collectionId AS collection_id,
  -- 流动性评分计算(基于交易频率、交易量和价格连续性)
  CASE
    -- 交易频率权重40%
    WHEN COUNT(*) > 50 THEN 0.4
    WHEN COUNT(*) > 20 THEN 0.3
    WHEN COUNT(*) > 10 THEN 0.2
    WHEN COUNT(*) > 5 THEN 0.1
    ELSE 0.05
  END +
  -- 交易量权重30%
  CASE
    WHEN SUM(price_usd) > 100000 THEN 0.3
    WHEN SUM(price_usd) > 50000 THEN 0.25
    WHEN SUM(price_usd) > 10000 THEN 0.2
    WHEN SUM(price_usd) > 5000 THEN 0.15
    WHEN SUM(price_usd) > 1000 THEN 0.1
    ELSE 0.05
  END +
  -- 价格连续性权重30%(使用最大最小价差与平均价的比例)
  CASE
    WHEN MAX(price) = MIN(price) OR AVG(price) = 0 THEN 0.05 -- 无价格差异
    WHEN (MAX(price) - MIN(price)) / NULLIF(AVG(price), 0) < 0.1 THEN 0.3 -- 价格非常稳定
    WHEN (MAX(price) - MIN(price)) / NULLIF(AVG(price), 0) < 0.25 THEN 0.25
    WHEN (MAX(price) - MIN(price)) / NULLIF(AVG(price), 0) < 0.5 THEN 0.2
    WHEN (MAX(price) - MIN(price)) / NULLIF(AVG(price), 0) < 1.0 THEN 0.15
    ELSE 0.1 -- 价格差异大
  END AS liquidity_score
FROM dwd.dwd_nft_transaction_inc
WHERE collectionId IS NOT NULL
GROUP BY dt, collectionId;

-- 将数据插入NFT价格日汇总表
INSERT INTO dws.dws_nft_price_1d
SELECT
  cs.collection_id,
  cs.dt,
  cs.transaction_count AS daily_transaction_count,
  cs.volume_usd AS daily_volume_usd,
  COALESCE(fp.floor_price, cs.min_price) AS floor_price, -- 地板价可能来自其他源
  cs.avg_price,
  cs.max_price,
  cs.min_price,
  COALESCE(pv.price_volatility, 0.0) AS price_volatility,
  COALESCE(pm.price_momentum, 0.0) AS price_momentum,
  COALESCE(wa.whale_attention_ratio, 0.0) AS whale_attention_ratio,
  COALESCE(ls.liquidity_score, 0.1) AS liquidity_score,
  COALESCE(pm.price_trend_prediction, 'STABLE') AS price_trend_prediction,
  CURRENT_TIMESTAMP AS updated_at
FROM daily_collection_stats cs
LEFT JOIN daily_floor_price fp ON cs.collection_id = fp.collection_id AND cs.dt = fp.dt
LEFT JOIN daily_whale_attention wa ON cs.collection_id = wa.collection_id AND cs.dt = wa.dt
LEFT JOIN price_volatility pv ON cs.collection_id = pv.collection_id AND cs.dt = pv.dt
LEFT JOIN price_momentum pm ON cs.collection_id = pm.collection_id AND cs.dt = pm.dt
LEFT JOIN liquidity_score ls ON cs.collection_id = ls.collection_id AND cs.dt = ls.dt; 