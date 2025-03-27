-- 低价狙击机会表
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'table.exec.resource.default-parallelism' = '2';
SET 'pipeline.name' = 'Bargain-Opportunity-ADS-Processing';

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

-- 创建ADS数据库(如果不存在)
CREATE DATABASE IF NOT EXISTS ads;

-- 创建低价狙击机会表
CREATE TABLE IF NOT EXISTS ads.ads_bargain_opportunity (
  `opportunity_id` STRING,
  `nft_id` STRING,
  `collection_id` STRING,
  `discovery_time` TIMESTAMP(3),
  `current_price` DOUBLE,
  `market_reference_price` DOUBLE,
  `discount_percentage` DOUBLE,
  `urgency_score` DOUBLE,              -- 紧急度评分
  `investment_value_score` DOUBLE,     -- 投资价值评分
  `risk_score` DOUBLE,                 -- 风险评分
  `opportunity_window` STRING,         -- 机会窗口期
  `marketplace` STRING,                -- 交易平台
  `status` STRING,                     -- 状态(ACTIVE/EXPIRED)
  PRIMARY KEY (`opportunity_id`) NOT ENFORCED
) WITH (
  'bucket' = '8',
  'bucket-key' = 'opportunity_id',
  'file.format' = 'parquet',
  'merge-engine' = 'deduplicate',
  'changelog-producer' = 'input',
  'compaction.min.file-num' = '5',
  'compaction.max.file-num' = '50',
  'compaction.target-file-size' = '256MB'
);

-- 创建临时视图：最新交易记录
CREATE TEMPORARY VIEW IF NOT EXISTS latest_nft_transactions AS
SELECT
  t1.nftId,
  t1.id
FROM dwd.dwd_nft_transaction_inc t1
JOIN (
  SELECT
    nftId,
    MAX(ts) AS max_ts
  FROM dwd.dwd_nft_transaction_inc
  WHERE nftId IS NOT NULL
  GROUP BY nftId
) t2 ON t1.nftId = t2.nftId AND t1.ts = t2.max_ts;

-- 创建临时视图：最新NFT价格
CREATE TEMPORARY VIEW IF NOT EXISTS latest_nft_prices AS
SELECT
  np.collection_id,
  t.nftId AS nft_id,
  t.price AS current_price,
  t.marketplace,
  np.avg_price,
  np.floor_price,
  np.price_volatility,
  np.price_momentum,
  np.whale_attention_ratio,
  np.liquidity_score,
  np.daily_transaction_count
FROM dws.dws_nft_price_1d np
JOIN dwd.dwd_nft_transaction_inc t 
  ON np.collection_id = t.collectionId
JOIN latest_nft_transactions lnt
  ON t.nftId = lnt.nftId AND t.id = lnt.id
WHERE np.dt = DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd');

-- 创建临时视图：潜在低价机会
CREATE TEMPORARY VIEW IF NOT EXISTS potential_bargains AS
SELECT
  nft_id,
  collection_id,
  current_price,
  avg_price AS market_reference_price,
  marketplace,
  -- 计算折扣百分比
  CASE 
    WHEN avg_price > 0 THEN (1 - (current_price / avg_price)) * 100
    ELSE 0
  END AS discount_percentage,
  -- 价格波动率
  price_volatility,
  -- 价格动量
  price_momentum,
  -- 鲸鱼关注度
  whale_attention_ratio,
  -- 流动性评分
  liquidity_score,
  -- 交易数量
  daily_transaction_count,
  -- 预先计算投资价值评分，避免嵌套
  0.5 * (CASE
    WHEN price_momentum > 0.1 THEN 0.9
    WHEN price_momentum > 0 THEN 0.7
    WHEN price_momentum > -0.1 THEN 0.5
    ELSE 0.3
  END) + 0.5 * whale_attention_ratio AS investment_value_score
FROM latest_nft_prices
WHERE 
  -- 降低折扣要求到15%
  current_price < avg_price * 0.85
  -- 放宽异常低价判断
  AND current_price > floor_price * 0.3
  -- 降低交易量要求
  AND daily_transaction_count >= 2;

-- 创建临时视图：紧急度评分
CREATE TEMPORARY VIEW IF NOT EXISTS urgency_scores AS
SELECT
  nft_id,
  collection_id,
  current_price,
  market_reference_price,
  discount_percentage,
  price_volatility,
  liquidity_score,
  investment_value_score,
  marketplace,
  daily_transaction_count,
  -- 紧急度评分(基于价差和市场热度)
  0.7 * (discount_percentage / 100) + 
  0.3 * (CASE 
    WHEN daily_transaction_count > 20 THEN 1.0
    WHEN daily_transaction_count > 10 THEN 0.8
    WHEN daily_transaction_count > 5 THEN 0.6
    ELSE 0.4
  END) AS urgency_score,
  -- 风险评分(基于价格波动率和流动性)
  0.6 * price_volatility + 
  0.4 * (1 - liquidity_score) AS risk_score,
  -- 机会窗口期
  CASE
    WHEN price_volatility > 0.3 THEN '短期(1-2小时)'
    WHEN price_volatility > 0.1 THEN '中期(12小时内)'
    ELSE '长期(24-48小时)'
  END AS opportunity_window
FROM potential_bargains
-- 保证低价有足够的投资价值
WHERE investment_value_score > 0.5;

-- 将数据插入低价狙击机会表(新记录)
INSERT INTO ads.ads_bargain_opportunity
SELECT
  -- 生成机会ID
  MD5(CONCAT(collection_id, nft_id, CAST(CURRENT_TIMESTAMP AS STRING))) AS opportunity_id,
  nft_id,
  collection_id,
  CURRENT_TIMESTAMP AS discovery_time,
  current_price,
  market_reference_price,
  discount_percentage,
  urgency_score,
  investment_value_score,
  risk_score,
  opportunity_window,
  marketplace,
  'ACTIVE' AS status
FROM urgency_scores;

-- 将过期机会重新插入以更新状态(Flink流模式不支持UPDATE)
INSERT INTO ads.ads_bargain_opportunity
SELECT
  opportunity_id,
  nft_id,
  collection_id,
  discovery_time,
  current_price,
  market_reference_price,
  discount_percentage,
  urgency_score,
  investment_value_score,
  risk_score,
  opportunity_window,
  marketplace,
  'EXPIRED' AS status
FROM ads.ads_bargain_opportunity
WHERE status = 'ACTIVE' 
  AND TIMESTAMPDIFF(HOUR, CAST(discovery_time AS TIMESTAMP(3)), CAST(CURRENT_TIMESTAMP AS TIMESTAMP(3))) > 
    CASE 
      WHEN opportunity_window = '短期(1-2小时)' THEN 2
      WHEN opportunity_window = '中期(12小时内)' THEN 12
      ELSE 48
    END;