-- 鲸鱼行为日汇总表
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'table.exec.resource.default-parallelism' = '2';
SET 'pipeline.name' = 'NFT-Whale-Behavior-DWS-Processing';

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

-- 创建DWS数据库
CREATE DATABASE IF NOT EXISTS dws;

-- 创建鲸鱼行为日汇总表
CREATE TABLE IF NOT EXISTS dws.dws_whale_behavior_1d (
  `wallet_address` STRING,
  `dt` STRING,
  `buy_count` BIGINT,
  `buy_value_usd` DOUBLE,
  `sell_count` BIGINT,
  `sell_value_usd` DOUBLE,
  `net_position_change` DOUBLE,
  `favorite_collections` STRING, -- JSON数组，记录最活跃的系列
  `transaction_pattern` STRING, -- 'ACCUMULATING'/'DISTRIBUTING'/'SWAPPING'
  `influence_score` DOUBLE, -- 市场影响力评分
  `abnormal_activity_score` DOUBLE, -- 异常活动评分
  `prediction_signal` STRING, -- 'BULLISH'/'BEARISH'/'NEUTRAL'
  `updated_at` TIMESTAMP(3),
  PRIMARY KEY (`wallet_address`, `dt`) NOT ENFORCED
) WITH (
  'bucket' = '4',
  'bucket-key' = 'wallet_address',
  'file.format' = 'parquet',
  'merge-engine' = 'deduplicate',
  'changelog-producer' = 'input',
  'compaction.min.file-num' = '5',
  'compaction.max.file-num' = '50',
  'compaction.target-file-size' = '256MB'
);

-- 创建临时视图：钱包日交易统计
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_daily_transaction AS
SELECT
  dt,
  -- 计算买入情况
  CASE WHEN buyer IS NOT NULL THEN buyer ELSE seller END AS wallet_address,
  COUNT(DISTINCT CASE WHEN buyer IS NOT NULL THEN id END) AS buy_count,
  SUM(CASE WHEN buyer IS NOT NULL THEN price_usd ELSE 0 END) AS buy_value_usd,
  -- 计算卖出情况
  COUNT(DISTINCT CASE WHEN seller IS NOT NULL THEN id END) AS sell_count,
  SUM(CASE WHEN seller IS NOT NULL THEN price_usd ELSE 0 END) AS sell_value_usd
FROM dwd.dwd_nft_transaction_inc
GROUP BY dt, CASE WHEN buyer IS NOT NULL THEN buyer ELSE seller END;

-- 创建临时视图：识别鲸鱼钱包
CREATE TEMPORARY VIEW IF NOT EXISTS whale_wallets AS
SELECT
  address AS wallet_address
FROM dim.dim_wallet_full
WHERE wallet_type = 'whale' OR total_transaction_count > 50 OR total_volume_usd > 50000;

-- 创建临时视图：钱包偏好NFT系列
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_favorite_collections AS
SELECT
  wallet_address,
  LISTAGG(collection_info, ',') AS favorite_collections_list
FROM (
  SELECT
    t.wallet_address,
    t.collectionId,
    t.collection_count,
    CONCAT('{"id":"', t.collectionId, '","name":"', t.collectionName, '","count":', CAST(t.collection_count AS STRING), '}') AS collection_info,
    ROW_NUMBER() OVER (PARTITION BY t.wallet_address ORDER BY t.collection_count DESC) AS rn
  FROM (
    -- 买入集合统计
    SELECT
      buyer AS wallet_address,
      collectionId,
      collectionName,
      COUNT(DISTINCT id) AS collection_count
    FROM dwd.dwd_nft_transaction_inc
    WHERE buyer IS NOT NULL AND collectionId IS NOT NULL
    GROUP BY buyer, collectionId, collectionName
    
    UNION ALL
    
    -- 卖出集合统计
    SELECT
      seller AS wallet_address,
      collectionId,
      collectionName,
      COUNT(DISTINCT id) AS collection_count
    FROM dwd.dwd_nft_transaction_inc
    WHERE seller IS NOT NULL AND collectionId IS NOT NULL
    GROUP BY seller, collectionId, collectionName
  ) t
) ranked
WHERE rn <= 5 -- 只取前5个最活跃的系列
GROUP BY wallet_address;

-- 创建临时视图：计算异常活动评分
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_abnormal_activity AS
SELECT
  wallet_address,
  dt,
  -- 异常活动评分计算 (基于交易量、交易频率和价格异常)
  0.4 * price_abnormal_ratio + 0.3 * volume_abnormal_ratio + 0.3 * frequency_abnormal_ratio AS abnormal_activity_score
FROM (
  SELECT
    CASE WHEN buyer IS NOT NULL THEN buyer ELSE seller END AS wallet_address,
    dt,
    -- 价格异常比例 (交易价格异常比例)
    SUM(CASE WHEN isOutlier = true THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS price_abnormal_ratio,
    -- 交易量异常 (相对该钱包历史平均值)
    CASE
      WHEN AVG(price_usd) > 0 AND MAX(price_usd) / AVG(price_usd) > 3 THEN 0.8
      WHEN AVG(price_usd) > 0 AND MAX(price_usd) / AVG(price_usd) > 2 THEN 0.5
      ELSE 0.2
    END AS volume_abnormal_ratio,
    -- 交易频率异常 (相对市场平均值)
    CASE
      WHEN COUNT(*) > 20 THEN 0.9
      WHEN COUNT(*) > 10 THEN 0.6
      WHEN COUNT(*) > 5 THEN 0.3
      ELSE 0.1
    END AS frequency_abnormal_ratio
  FROM dwd.dwd_nft_transaction_inc
  GROUP BY dt, CASE WHEN buyer IS NOT NULL THEN buyer ELSE seller END
) t;

-- 创建临时视图：交易模式分析
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_transaction_pattern AS
SELECT
  t.wallet_address,
  t.dt,
  -- 交易模式判断
  CASE
    WHEN t.buy_count > t.sell_count * 2 THEN 'ACCUMULATING' -- 大量买入积累
    WHEN t.sell_count > t.buy_count * 2 THEN 'DISTRIBUTING' -- 大量卖出分发
    WHEN t.buy_count > 0 AND t.sell_count > 0 THEN 'SWAPPING' -- 买卖均衡交换
    WHEN t.buy_count > 0 THEN 'BUYING_ONLY' -- 仅买入
    WHEN t.sell_count > 0 THEN 'SELLING_ONLY' -- 仅卖出
    ELSE 'INACTIVE' -- 无交易活动
  END AS transaction_pattern,
  -- 市场信号预测
  CASE
    WHEN t.buy_count > t.sell_count * 3 THEN 'BULLISH' -- 强烈看涨
    WHEN t.buy_count > t.sell_count * 1.5 THEN 'MODERATELY_BULLISH' -- 温和看涨
    WHEN t.sell_count > t.buy_count * 3 THEN 'BEARISH' -- 强烈看跌
    WHEN t.sell_count > t.buy_count * 1.5 THEN 'MODERATELY_BEARISH' -- 温和看跌
    ELSE 'NEUTRAL' -- 中性
  END AS prediction_signal
FROM wallet_daily_transaction t;

-- 创建临时视图：影响力评分计算
CREATE TEMPORARY VIEW IF NOT EXISTS wallet_influence_score AS
SELECT
  w.wallet_address,
  dt,
  -- 影响力评分计算 (交易金额权重50%，交易频率权重20%，历史影响力15%，收藏品多样性15%)
  0.5 * volume_score + 0.2 * frequency_score + 0.15 * history_score + 0.15 * diversity_score AS influence_score
FROM (
  SELECT
    wallet_address,
    dt,
    -- 交易金额得分 (取值0.1-1.0)
    CASE
      WHEN (buy_value_usd + sell_value_usd) > 100000 THEN 1.0
      WHEN (buy_value_usd + sell_value_usd) > 50000 THEN 0.8
      WHEN (buy_value_usd + sell_value_usd) > 10000 THEN 0.6
      WHEN (buy_value_usd + sell_value_usd) > 5000 THEN 0.4
      WHEN (buy_value_usd + sell_value_usd) > 1000 THEN 0.2
      ELSE 0.1
    END AS volume_score,
    -- 交易频率得分 (取值0.1-1.0)
    CASE
      WHEN (buy_count + sell_count) > 50 THEN 1.0
      WHEN (buy_count + sell_count) > 30 THEN 0.8
      WHEN (buy_count + sell_count) > 20 THEN 0.6
      WHEN (buy_count + sell_count) > 10 THEN 0.4
      WHEN (buy_count + sell_count) > 5 THEN 0.2
      ELSE 0.1
    END AS frequency_score
  FROM wallet_daily_transaction
) t
JOIN whale_wallets w ON t.wallet_address = w.wallet_address
LEFT JOIN (
  -- 历史影响力评分 (基于dim层)
  SELECT
    address AS wallet_address,
    COALESCE(influence_score, 0.5) AS history_score,
    -- 多样性评分 (基于持有收藏品多样性)
    CASE
      WHEN CHAR_LENGTH(preferred_collections) - CHAR_LENGTH(REPLACE(preferred_collections, ',', '')) > 8 THEN 1.0
      WHEN CHAR_LENGTH(preferred_collections) - CHAR_LENGTH(REPLACE(preferred_collections, ',', '')) > 5 THEN 0.7
      WHEN CHAR_LENGTH(preferred_collections) - CHAR_LENGTH(REPLACE(preferred_collections, ',', '')) > 3 THEN 0.5
      WHEN CHAR_LENGTH(preferred_collections) - CHAR_LENGTH(REPLACE(preferred_collections, ',', '')) > 1 THEN 0.3
      ELSE 0.1
    END AS diversity_score
  FROM dim.dim_wallet_full
) d ON w.wallet_address = d.wallet_address;

-- 将数据插入鲸鱼行为日汇总表
INSERT INTO dws.dws_whale_behavior_1d
SELECT
  t.wallet_address,
  t.dt,
  t.buy_count,
  t.buy_value_usd,
  t.sell_count,
  t.sell_value_usd,
  -- 净持仓变化 (买入 - 卖出)
  t.buy_value_usd - t.sell_value_usd AS net_position_change,
  -- 偏好NFT系列
  CONCAT('[', COALESCE(wfc.favorite_collections_list, ''), ']') AS favorite_collections,
  -- 交易模式
  wtp.transaction_pattern,
  -- 影响力评分
  COALESCE(wis.influence_score, 0.5) AS influence_score,
  -- 异常活动评分
  COALESCE(waa.abnormal_activity_score, 0.1) AS abnormal_activity_score,
  -- 预测信号
  wtp.prediction_signal,
  -- 更新时间
  CURRENT_TIMESTAMP AS updated_at
FROM wallet_daily_transaction t
JOIN whale_wallets ww ON t.wallet_address = ww.wallet_address
LEFT JOIN wallet_favorite_collections wfc ON t.wallet_address = wfc.wallet_address
LEFT JOIN wallet_transaction_pattern wtp ON t.wallet_address = wtp.wallet_address AND t.dt = wtp.dt
LEFT JOIN wallet_influence_score wis ON t.wallet_address = wis.wallet_address AND t.dt = wis.dt
LEFT JOIN wallet_abnormal_activity waa ON t.wallet_address = waa.wallet_address AND t.dt = waa.dt; 