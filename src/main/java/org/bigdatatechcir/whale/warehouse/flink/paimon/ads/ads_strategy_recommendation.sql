-- 策略推荐表
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'table.exec.resource.default-parallelism' = '2';
SET 'pipeline.name' = 'Strategy-Recommendation-ADS-Processing';

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

-- 创建策略推荐表
CREATE TABLE IF NOT EXISTS ads.ads_strategy_recommendation (
  `strategy_id` STRING,
  `strategy_type` STRING,              -- BUY/SELL/HOLD
  `generation_time` TIMESTAMP(3),
  `expiry_time` TIMESTAMP(3),
  `target_entity` STRING,              -- NFT/Collection
  `entity_id` STRING,
  `recommended_action` STRING,
  `price_range` STRING,                -- JSON格式价格区间
  `expected_return_rate` DOUBLE,
  `success_probability` DOUBLE,
  `rationale` STRING,                  -- 推荐理由
  `market_context` STRING,             -- 市场背景(JSON)
  PRIMARY KEY (`strategy_id`) NOT ENFORCED
) WITH (
  'bucket' = '8',
  'bucket-key' = 'strategy_id',
  'file.format' = 'parquet',
  'merge-engine' = 'deduplicate',
  'changelog-producer' = 'input',
  'compaction.min.file-num' = '5',
  'compaction.max.file-num' = '50',
  'compaction.target-file-size' = '256MB'
);

-- 创建临时视图：市场情绪
CREATE TEMPORARY VIEW IF NOT EXISTS market_sentiment_view AS
SELECT
  marketplace_id,
  market_sentiment
FROM dws.dws_market_activity_1d
WHERE dt = DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd');

-- 创建临时视图：鲸鱼活跃度
CREATE TEMPORARY VIEW IF NOT EXISTS whale_activity_view AS
SELECT
  CASE 
    WHEN COUNT(1) > 5 THEN 'HIGH'
    WHEN COUNT(1) > 2 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS whale_activity
FROM dws.dws_whale_behavior_1d
WHERE dt = DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd')
  AND influence_score > 0.7;

-- 创建临时视图：市场成交量趋势
CREATE TEMPORARY VIEW IF NOT EXISTS volume_trend_view AS
SELECT
  CASE 
    WHEN (SELECT SUM(daily_volume_usd) FROM dws.dws_market_activity_1d 
          WHERE dt = DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd')) > 
         (SELECT SUM(daily_volume_usd) FROM dws.dws_market_activity_1d 
          WHERE dt = DATE_FORMAT(TIMESTAMPADD(DAY, -1, CURRENT_TIMESTAMP), 'yyyy-MM-dd'))
    THEN 'INCREASING'
    ELSE 'STABLE'
  END AS volume_trend;

-- 创建临时视图：低价狙击策略
CREATE TEMPORARY VIEW IF NOT EXISTS buy_strategies AS
SELECT
  'BUY' AS strategy_type,
  'NFT' AS target_entity,
  b.nft_id AS entity_id,
  'BUY_NOW' AS action,
  CONCAT('{"min":', CAST(b.current_price AS STRING), ',"max":', CAST(b.current_price * 1.05 AS STRING), '}') AS price_range,
  b.discount_percentage / 100 AS expected_return,
  (1 - b.risk_score) AS success_prob,
  CONCAT('折扣率', CAST(ROUND(b.discount_percentage, 2) AS STRING), '%，投资价值评分:', CAST(ROUND(b.investment_value_score * 10, 1) AS STRING), '/10') AS rationale,
  b.collection_id,
  b.opportunity_id,
  b.marketplace
FROM ads.ads_bargain_opportunity b
WHERE b.investment_value_score > 0.5 AND b.discount_percentage > 20 AND b.status = 'ACTIVE';

-- 创建临时视图：市场情绪与买入策略关联
CREATE TEMPORARY VIEW IF NOT EXISTS buy_market_context AS
SELECT
  bs.entity_id,
  bs.strategy_type,
  bs.target_entity,
  bs.action,
  bs.price_range,
  bs.expected_return,
  bs.success_prob,
  bs.rationale,
  COALESCE(msv.market_sentiment, 'NEUTRAL') AS market_sentiment,
  (SELECT whale_activity FROM whale_activity_view) AS whale_activity,
  (SELECT volume_trend FROM volume_trend_view) AS volume_trend
FROM buy_strategies bs
LEFT JOIN market_sentiment_view msv ON bs.marketplace = msv.marketplace_id;

-- 创建临时视图：鲸鱼抛售信号
CREATE TEMPORARY VIEW IF NOT EXISTS whale_selling_signals AS
SELECT
  np.collection_id,
  np.dt,
  np.avg_price,
  np.price_momentum,
  COUNT(DISTINCT wb.wallet_address) AS selling_whales_count,
  -- 计算鲸鱼活跃度加权
  SUM(wb.influence_score) AS total_whale_influence
FROM dws.dws_nft_price_1d np
JOIN dws.dws_whale_behavior_1d wb 
  ON np.dt = wb.dt 
  AND wb.transaction_pattern IN ('DISTRIBUTING', 'SELLING_ONLY')
  AND TIMESTAMPDIFF(DAY, CAST(wb.dt AS DATE), CAST(CURRENT_TIMESTAMP AS DATE)) <= 3
GROUP BY np.collection_id, np.dt, np.avg_price, np.price_momentum
HAVING COUNT(DISTINCT wb.wallet_address) >= 2;

-- 创建临时视图：卖出策略的市场上下文
CREATE TEMPORARY VIEW IF NOT EXISTS sell_market_context AS
SELECT
  'SELL' AS strategy_type,
  'COLLECTION' AS target_entity,
  wss.collection_id AS entity_id,
  'SELL_SOON' AS action,
  CONCAT('{"min":', CAST(wss.avg_price * 0.95 AS STRING), ',"max":', CAST(wss.avg_price * 1.05 AS STRING), '}') AS price_range,
  0.1 AS expected_return,
  CASE
    WHEN wss.price_momentum < -0.1 AND wss.selling_whales_count > 3 THEN 0.85
    WHEN wss.price_momentum < 0 AND wss.selling_whales_count > 2 THEN 0.7
    ELSE 0.6
  END AS success_prob,
  CONCAT('鲸鱼抛售信号增强，', CAST(wss.selling_whales_count AS STRING), '个鲸鱼钱包近期有抛售行为，总影响力评分:', CAST(ROUND(wss.total_whale_influence, 2) AS STRING)) AS rationale,
  COALESCE(m.market_sentiment, 'NEUTRAL') AS market_sentiment
FROM whale_selling_signals wss
JOIN dws.dws_market_activity_1d m 
  ON wss.dt = m.dt 
  AND TIMESTAMPDIFF(DAY, CAST(m.dt AS DATE), CAST(CURRENT_TIMESTAMP AS DATE)) <= 1;

-- 创建临时视图：持有策略的市场上下文
CREATE TEMPORARY VIEW IF NOT EXISTS hold_market_context AS
SELECT
  'HOLD' AS strategy_type,
  'COLLECTION' AS target_entity,
  np.collection_id AS entity_id,
  'HOLD_WATCH' AS action,
  CONCAT('{"min":', CAST(np.floor_price AS STRING), ',"max":', CAST(np.avg_price * 1.2 AS STRING), '}') AS price_range,
  0.05 + (np.whale_attention_ratio * 0.2) AS expected_return,
  0.6 AS success_prob,
  CONCAT('价格稳定且有鲸鱼关注，关注度评分:', CAST(ROUND(np.whale_attention_ratio * 10, 1) AS STRING), '/10，流动性评分:', CAST(ROUND(np.liquidity_score * 10, 1) AS STRING), '/10') AS rationale,
  COALESCE(m.market_sentiment, 'NEUTRAL') AS market_sentiment
FROM dws.dws_nft_price_1d np
JOIN dws.dws_market_activity_1d m ON np.dt = m.dt
WHERE 
  ABS(np.price_momentum) < 0.05 -- 价格稳定
  AND np.whale_attention_ratio > 0.3 -- 有鲸鱼关注
  AND np.liquidity_score > 0.5 -- 流动性好
  AND TIMESTAMPDIFF(DAY, CAST(np.dt AS DATE), CAST(CURRENT_TIMESTAMP AS DATE)) <= 1;

-- 将数据插入策略推荐表 - 买入策略
INSERT INTO ads.ads_strategy_recommendation
SELECT
  -- 买入策略
  MD5(CONCAT('BUY', entity_id, CAST(CURRENT_TIMESTAMP AS STRING))) AS strategy_id,
  strategy_type,
  CURRENT_TIMESTAMP AS generation_time,
  TIMESTAMPADD(HOUR, 24, CURRENT_TIMESTAMP) AS expiry_time,
  target_entity,
  entity_id,
  action AS recommended_action,
  price_range,
  expected_return AS expected_return_rate,
  success_prob AS success_probability,
  rationale,
  -- 市场背景JSON
  CONCAT('{"market_sentiment":"', market_sentiment, 
         '","whale_activity":"', whale_activity,
         '","volume_trend":"', volume_trend,
         '"}') AS market_context
FROM buy_market_context;

-- 将数据插入策略推荐表 - 卖出策略
INSERT INTO ads.ads_strategy_recommendation
SELECT
  MD5(CONCAT('SELL', entity_id, CAST(CURRENT_TIMESTAMP AS STRING))) AS strategy_id,
  strategy_type,
  CURRENT_TIMESTAMP AS generation_time,
  TIMESTAMPADD(HOUR, 24, CURRENT_TIMESTAMP) AS expiry_time,
  target_entity,
  entity_id,
  action AS recommended_action,
  price_range,
  expected_return AS expected_return_rate,
  success_prob AS success_probability,
  rationale,
  -- 市场背景JSON
  CONCAT('{"market_sentiment":"', market_sentiment, 
         '","whale_signal":"BEARISH","price_trend":"DOWNWARD"}') AS market_context
FROM sell_market_context;

-- 将数据插入策略推荐表 - 持有策略
INSERT INTO ads.ads_strategy_recommendation
SELECT
  MD5(CONCAT('HOLD', entity_id, CAST(CURRENT_TIMESTAMP AS STRING))) AS strategy_id,
  strategy_type,
  CURRENT_TIMESTAMP AS generation_time,
  TIMESTAMPADD(HOUR, 48, CURRENT_TIMESTAMP) AS expiry_time,
  target_entity,
  entity_id,
  action AS recommended_action,
  price_range,
  expected_return AS expected_return_rate,
  success_prob AS success_probability,
  rationale,
  -- 市场背景JSON
  CONCAT('{"market_sentiment":"', market_sentiment, 
         '","whale_signal":"NEUTRAL","price_trend":"STABLE"}') AS market_context
FROM hold_market_context; 