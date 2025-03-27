-- 巨鲸追踪看板
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';
SET 'table.exec.resource.default-parallelism' = '2';
SET 'pipeline.name' = 'Whale-Tracking-Dashboard-ADS-Processing';

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

-- 创建ADS数据库
CREATE DATABASE IF NOT EXISTS ads;

-- 创建巨鲸追踪看板表
CREATE TABLE IF NOT EXISTS ads.ads_whale_tracking_dashboard (
  `wallet_address` STRING,
  `update_time` TIMESTAMP(3),
  `wallet_label` STRING,                 -- 钱包标签
  `recent_activity_summary` STRING,      -- 近期活动摘要(JSON)
  `holdings_change_30d` DOUBLE,          -- 30天持仓变化
  `influence_score` DOUBLE,              -- 影响力评分
  `activity_alert_level` STRING,         -- 活动预警等级
  `preferred_collections` STRING,        -- 偏好收藏品(JSON)
  `prediction_signals` STRING,           -- 预测信号(JSON)
  `tracking_priority` INT,               -- 追踪优先级
  PRIMARY KEY (`wallet_address`) NOT ENFORCED
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

-- 创建临时视图：提取鲸鱼钱包在最近30天内的交易数据
CREATE TEMPORARY VIEW IF NOT EXISTS whale_recent_activity AS
SELECT
  wb.wallet_address,
  wb.dt,
  wb.buy_count,
  wb.sell_count,
  wb.buy_value_usd,
  wb.sell_value_usd,
  wb.transaction_pattern,
  wb.influence_score,
  wb.abnormal_activity_score,
  wb.prediction_signal,
  wb.net_position_change
FROM dws.dws_whale_behavior_1d wb
WHERE wb.dt >= DATE_FORMAT(TIMESTAMPADD(DAY, -30, CURRENT_TIMESTAMP), 'yyyy-MM-dd');

-- 创建临时视图：计算30天持仓变化
CREATE TEMPORARY VIEW IF NOT EXISTS whale_holdings_change AS
SELECT
  wallet_address,
  SUM(net_position_change) AS holdings_change_30d
FROM whale_recent_activity
GROUP BY wallet_address;

-- 创建临时视图：计算最近预测信号
CREATE TEMPORARY VIEW IF NOT EXISTS whale_prediction_signals AS
SELECT
  wallet_address,
  LISTAGG(signal_json, ',') AS prediction_signals_json
FROM (
  SELECT
    wallet_address,
    CONCAT('{"dt":"', dt, '","signal":"', prediction_signal, '"}') AS signal_json,
    ROW_NUMBER() OVER (PARTITION BY wallet_address ORDER BY dt DESC) AS rn
  FROM whale_recent_activity
) t
WHERE rn <= 7 -- 最近7天的信号
GROUP BY wallet_address;

-- 创建临时视图：计算近期活动摘要
CREATE TEMPORARY VIEW IF NOT EXISTS whale_activity_summary AS
SELECT
  wallet_address,
  SUM(CASE WHEN TIMESTAMPDIFF(DAY, CAST(dt AS DATE), CAST(CURRENT_TIMESTAMP AS DATE)) <= 7 THEN buy_count ELSE 0 END) AS buy_count_7d,
  SUM(CASE WHEN TIMESTAMPDIFF(DAY, CAST(dt AS DATE), CAST(CURRENT_TIMESTAMP AS DATE)) <= 7 THEN sell_count ELSE 0 END) AS sell_count_7d,
  SUM(CASE WHEN TIMESTAMPDIFF(DAY, CAST(dt AS DATE), CAST(CURRENT_TIMESTAMP AS DATE)) <= 7 THEN buy_value_usd + sell_value_usd ELSE 0 END) AS volume_7d,
  MAX(CASE WHEN TIMESTAMPDIFF(DAY, CAST(dt AS DATE), CAST(CURRENT_TIMESTAMP AS DATE)) <= 3 THEN transaction_pattern ELSE '' END) AS recent_pattern
FROM whale_recent_activity
GROUP BY wallet_address;

-- 创建临时视图：计算活动预警等级
CREATE TEMPORARY VIEW IF NOT EXISTS whale_alert_level AS
SELECT
  wallet_address,
  CASE
    WHEN MAX(abnormal_activity_score) > 0.7 THEN 'HIGH_ALERT'
    WHEN MAX(abnormal_activity_score) > 0.4 THEN 'MEDIUM_ALERT'
    ELSE 'LOW_ALERT'
  END AS activity_alert_level,
  MAX(influence_score) AS recent_influence_score,
  MAX(abnormal_activity_score) AS max_abnormal_score
FROM whale_recent_activity
GROUP BY wallet_address;

-- 将数据插入巨鲸追踪看板表
INSERT INTO ads.ads_whale_tracking_dashboard
SELECT
  w.wallet_address,
  CURRENT_TIMESTAMP AS update_time,
  COALESCE(d.wallet_label, '普通用户') AS wallet_label,
  -- 构建近期活动摘要JSON
  CONCAT('{"buy_count_7d":', CAST(COALESCE(s.buy_count_7d, 0) AS STRING),
         ',"sell_count_7d":', CAST(COALESCE(s.sell_count_7d, 0) AS STRING),
         ',"volume_7d":', CAST(COALESCE(s.volume_7d, 0) AS STRING),
         ',"pattern":"', COALESCE(s.recent_pattern, 'INACTIVE'), '"}') AS recent_activity_summary,
  -- 30天持仓变化
  COALESCE(hc.holdings_change_30d, 0) AS holdings_change_30d,
  -- 影响力评分
  COALESCE(al.recent_influence_score, 0.5) AS influence_score,
  -- 活动预警等级
  COALESCE(al.activity_alert_level, 'LOW_ALERT') AS activity_alert_level,
  -- 从DIM层获取偏好收藏品
  COALESCE(d.preferred_collections, '[]') AS preferred_collections,
  -- 汇总最近的预测信号
  CONCAT('[', COALESCE(ps.prediction_signals_json, ''), ']') AS prediction_signals,
  -- 追踪优先级(影响力+异常活动)
  CAST(((COALESCE(al.recent_influence_score, 0.5) * 0.7 + COALESCE(al.max_abnormal_score, 0.1) * 0.3) * 10) AS INT) AS tracking_priority
FROM 
  (SELECT DISTINCT wallet_address FROM dws.dws_whale_behavior_1d) w
LEFT JOIN dim.dim_wallet_full d ON w.wallet_address = d.address
LEFT JOIN whale_activity_summary s ON w.wallet_address = s.wallet_address
LEFT JOIN whale_holdings_change hc ON w.wallet_address = hc.wallet_address
LEFT JOIN whale_alert_level al ON w.wallet_address = al.wallet_address
LEFT JOIN whale_prediction_signals ps ON w.wallet_address = ps.wallet_address
WHERE d.wallet_type = 'whale' OR COALESCE(al.recent_influence_score, 0.5) > 0.6; 