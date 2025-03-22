-- 市场活跃度日汇总表
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'table.exec.resource.default-parallelism' = '2';
SET 'pipeline.name' = 'Market-Activity-DWS-Processing';

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

-- 创建市场活跃度日汇总表
CREATE TABLE IF NOT EXISTS dws.dws_market_activity_1d (
  `marketplace_id` STRING,
  `dt` STRING,
  `daily_transaction_count` BIGINT,
  `daily_volume_usd` DOUBLE,
  `unique_users` BIGINT,
  `unique_nfts` BIGINT,
  `top_collections` STRING, -- JSON数组，热门系列排名
  `buy_sell_ratio` DOUBLE, -- 买入/卖出比例
  `average_gas_fee` DOUBLE,
  `whale_transaction_ratio` DOUBLE, -- 鲸鱼交易占比
  `market_sentiment` STRING, -- 'BULLISH'/'BEARISH'/'NEUTRAL'
  `updated_at` TIMESTAMP(3),
  PRIMARY KEY (`marketplace_id`, `dt`) NOT ENFORCED
) WITH (
  'bucket' = '4',
  'bucket-key' = 'marketplace_id',
  'file.format' = 'parquet',
  'merge-engine' = 'deduplicate',
  'changelog-producer' = 'input',
  'compaction.min.file-num' = '5',
  'compaction.max.file-num' = '50',
  'compaction.target-file-size' = '256MB'
);

-- 创建临时视图：每日市场交易基础统计
CREATE TEMPORARY VIEW IF NOT EXISTS daily_marketplace_stats AS
SELECT
  dt,
  marketplace AS marketplace_id,
  COUNT(DISTINCT id) AS transaction_count,
  SUM(price_usd) AS volume_usd,
  COUNT(DISTINCT buyer) + COUNT(DISTINCT seller) AS total_users,
  COUNT(DISTINCT buyer) AS buyers_count,
  COUNT(DISTINCT seller) AS sellers_count,
  COUNT(DISTINCT nftId) AS unique_nfts,
  AVG(gasFee) AS average_gas_fee
FROM dwd.dwd_nft_transaction_inc
WHERE marketplace IS NOT NULL
GROUP BY dt, marketplace;

-- 创建临时视图：鲸鱼参与度统计
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_whale_stats AS
SELECT
  dt,
  marketplace AS marketplace_id,
  -- 鲸鱼交易数量占比
  COUNT(DISTINCT CASE WHEN isWhaleTransaction = true THEN id END) / NULLIF(COUNT(DISTINCT id), 0) AS whale_transaction_ratio,
  -- 鲸鱼交易金额占比
  SUM(CASE WHEN isWhaleTransaction = true THEN price_usd ELSE 0 END) / NULLIF(SUM(price_usd), 0) AS whale_volume_ratio
FROM dwd.dwd_nft_transaction_inc
WHERE marketplace IS NOT NULL
GROUP BY dt, marketplace;

-- 创建临时视图：热门系列排名
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_top_collections AS
SELECT
  dt,
  marketplace AS marketplace_id,
  LISTAGG(collection_json, ',') AS top_collections_json
FROM (
  SELECT
    dt,
    marketplace,
    CONCAT('{"id":"', collectionId, '","name":"', collectionName, '","volume":', CAST(collection_volume AS STRING), '}') AS collection_json,
    ROW_NUMBER() OVER (PARTITION BY dt, marketplace ORDER BY collection_volume DESC) AS rn
  FROM (
    SELECT
      dt,
      marketplace,
      collectionId,
      collectionName,
      SUM(price_usd) AS collection_volume
    FROM dwd.dwd_nft_transaction_inc
    WHERE marketplace IS NOT NULL AND collectionId IS NOT NULL
    GROUP BY dt, marketplace, collectionId, collectionName
  ) t
) ranked
WHERE rn <= 5 -- 只保留前5个热门系列
GROUP BY dt, marketplace;

-- 创建临时视图：市场情绪指标
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_sentiment AS
SELECT
  dt,
  marketplace AS marketplace_id,
  -- 买卖比率(买单数/卖单数)
  COUNT(DISTINCT CASE WHEN buyer IS NOT NULL THEN id END) / 
    NULLIF(COUNT(DISTINCT CASE WHEN seller IS NOT NULL THEN id END), 0) AS buy_sell_ratio,
  -- 市场情绪判断
  CASE
    WHEN COUNT(DISTINCT CASE WHEN buyer IS NOT NULL THEN id END) / 
         NULLIF(COUNT(DISTINCT CASE WHEN seller IS NOT NULL THEN id END), 0) > 1.2 THEN 'BULLISH'
    WHEN COUNT(DISTINCT CASE WHEN buyer IS NOT NULL THEN id END) / 
         NULLIF(COUNT(DISTINCT CASE WHEN seller IS NOT NULL THEN id END), 0) < 0.8 THEN 'BEARISH'
    ELSE 'NEUTRAL'
  END AS market_sentiment
FROM dwd.dwd_nft_transaction_inc
WHERE marketplace IS NOT NULL
GROUP BY dt, marketplace;

-- 将数据插入市场活跃度日汇总表
INSERT INTO dws.dws_market_activity_1d
SELECT
  ms.marketplace_id,
  ms.dt,
  ms.transaction_count AS daily_transaction_count,
  ms.volume_usd AS daily_volume_usd,
  ms.total_users AS unique_users,
  ms.unique_nfts,
  CONCAT('[', COALESCE(tc.top_collections_json, ''), ']') AS top_collections,
  COALESCE(sent.buy_sell_ratio, 1.0) AS buy_sell_ratio, -- 默认为1.0表示平衡
  COALESCE(ms.average_gas_fee, 0.0) AS average_gas_fee,
  COALESCE(ws.whale_transaction_ratio, 0.0) AS whale_transaction_ratio,
  COALESCE(sent.market_sentiment, 'NEUTRAL') AS market_sentiment,
  CURRENT_TIMESTAMP AS updated_at
FROM daily_marketplace_stats ms
LEFT JOIN marketplace_whale_stats ws ON ms.marketplace_id = ws.marketplace_id AND ms.dt = ws.dt
LEFT JOIN marketplace_top_collections tc ON ms.marketplace_id = tc.marketplace_id AND ms.dt = tc.dt
LEFT JOIN marketplace_sentiment sent ON ms.marketplace_id = sent.marketplace_id AND ms.dt = sent.dt; 