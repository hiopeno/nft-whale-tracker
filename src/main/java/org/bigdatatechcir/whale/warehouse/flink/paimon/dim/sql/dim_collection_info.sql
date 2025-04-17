-- 收藏集维度表

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
CREATE DATABASE IF NOT EXISTS dim;
USE dim;

-- 创建收藏集维度表
CREATE TABLE IF NOT EXISTS dim_collection_info (
    collection_address VARCHAR(255),
    collection_name VARCHAR(255),
    symbol VARCHAR(50),
    logo_url VARCHAR(1000),
    banner_url VARCHAR(1000),
    first_tracked_date DATE,
    last_active_date DATE,
    items_total INT,
    owners_total INT,
    is_verified BOOLEAN,
    current_floor_price_eth DECIMAL(30,10),
    all_time_volume_eth DECIMAL(30,10),
    all_time_sales INT,
    avg_price_7d DECIMAL(30,10),
    avg_price_30d DECIMAL(30,10),
    volume_7d DECIMAL(30,10),
    volume_30d DECIMAL(30,10),
    sales_7d INT,
    sales_30d INT,
    whale_ownership_percentage DECIMAL(10,2),
    whale_volume_percentage DECIMAL(10,2),
    smart_whale_interest_score DECIMAL(10,2),
    is_in_working_set BOOLEAN,
    working_set_join_date DATE,
    working_set_days INT,
    inactive_days INT,
    status VARCHAR(20),
    category VARCHAR(100),
    total_whale_buys INT,
    total_whale_sells INT,
    etl_time TIMESTAMP,
    PRIMARY KEY (collection_address) NOT ENFORCED
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

-- 1. 新增收藏集
INSERT INTO dim_collection_info
WITH new_collections AS (
    SELECT DISTINCT
        cws.collection_address,
        COALESCE(cd.collection_name, c.collection_name) AS collection_name,
        'NFT' AS symbol, -- 默认符号，实际项目中应从外部源获取
        COALESCE(cws.logo_url, '') AS logo_url, -- 从ods_collection_working_set获取logo_url
        'https://placeholder.com/banner.png' AS banner_url, -- 设置为默认banner URL
        MIN(cd.collection_date) AS first_tracked_date,
        MAX(cd.collection_date) AS last_active_date,
        0 AS items_total, -- 默认值，实际项目中应从外部源获取
        0 AS owners_total, -- 默认值，实际项目中应从外部源获取
        FALSE AS is_verified, -- 默认值，实际项目中应从外部源获取
        AVG(cd.floor_price_eth) AS current_floor_price_eth,
        SUM(cd.volume_eth) AS all_time_volume_eth,
        SUM(cd.sales_count) AS all_time_sales,
        AVG(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN cd.avg_price_eth ELSE NULL END) AS avg_price_7d,
        AVG(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN cd.avg_price_eth ELSE NULL END) AS avg_price_30d,
        SUM(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN cd.volume_eth ELSE 0 END) AS volume_7d,
        SUM(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN cd.volume_eth ELSE 0 END) AS volume_30d,
        SUM(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN cd.sales_count ELSE 0 END) AS sales_7d,
        SUM(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN cd.sales_count ELSE 0 END) AS sales_30d,
        AVG(cd.whale_percentage) AS whale_ownership_percentage,
        (SUM(cd.whale_volume_eth) * 100.0) / NULLIF(SUM(cd.volume_eth), 0) AS whale_volume_percentage,
        0 AS smart_whale_interest_score, -- 初始化为0，后续计算
        TRUE AS is_in_working_set,
        MIN(cd.collection_date) AS working_set_join_date,
        TIMESTAMPDIFF(DAY, MIN(cd.collection_date), CURRENT_DATE) AS working_set_days,
        CASE 
            WHEN MAX(cd.collection_date) >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN 0
            ELSE TIMESTAMPDIFF(DAY, MAX(cd.collection_date), CURRENT_DATE)
        END AS inactive_days,
        CASE 
            WHEN MAX(cd.collection_date) >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN 'ACTIVE'
            ELSE 'INACTIVE'
        END AS status,
        'NFT' AS category, -- 默认类别
        SUM(cd.whale_buyers) AS total_whale_buys,
        SUM(cd.whale_sellers) AS total_whale_sells,
        CURRENT_TIMESTAMP AS etl_time
    FROM 
        ods.ods_collection_working_set cws
    LEFT JOIN 
        dwd.dwd_collection_daily_stats cd ON cws.collection_address = cd.contract_address
    LEFT JOIN (
        SELECT DISTINCT contract_address, collection_name FROM dwd.dwd_whale_transaction_detail
    ) c ON cws.collection_address = c.contract_address
    WHERE 
        cws.status = 'active'
    GROUP BY 
        cws.collection_address, 
        COALESCE(cd.collection_name, c.collection_name),
        cws.logo_url
)
SELECT * FROM new_collections nc
WHERE NOT EXISTS (
    SELECT 1 FROM dim_collection_info dci
    WHERE dci.collection_address = nc.collection_address
);

-- 2. 更新已有收藏集
-- 先删除要更新的记录
DELETE FROM dim_collection_info
WHERE collection_address IN (
  SELECT DISTINCT dci.collection_address
  FROM dim_collection_info dci
  JOIN dwd.dwd_collection_daily_stats cd ON dci.collection_address = cd.contract_address
  WHERE cd.collection_date > dci.last_active_date
);

-- 然后重新插入更新后的数据
INSERT INTO dim_collection_info
SELECT 
  dci.collection_address,
  dci.collection_name,
  dci.symbol,
  COALESCE(cws.logo_url, dci.logo_url) AS logo_url, -- 优先使用最新的logo_url
  'https://placeholder.com/banner.png' AS banner_url, -- 设置为默认banner URL
  dci.first_tracked_date,
  MAX(cd.collection_date) AS last_active_date,
  dci.items_total,
  dci.owners_total,
  dci.is_verified,
  AVG(cd.floor_price_eth) AS current_floor_price_eth,
  dci.all_time_volume_eth + SUM(cd.volume_eth) AS all_time_volume_eth,
  dci.all_time_sales + SUM(cd.sales_count) AS all_time_sales,
  AVG(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN cd.avg_price_eth ELSE NULL END) AS avg_price_7d,
  AVG(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN cd.avg_price_eth ELSE NULL END) AS avg_price_30d,
  SUM(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN cd.volume_eth ELSE 0 END) AS volume_7d,
  SUM(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN cd.volume_eth ELSE 0 END) AS volume_30d,
  SUM(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN cd.sales_count ELSE 0 END) AS sales_7d,
  SUM(CASE WHEN cd.collection_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN cd.sales_count ELSE 0 END) AS sales_30d,
  
  -- 简化鲸鱼持有百分比计算
  AVG(cd.whale_percentage) AS whale_ownership_percentage,
  (SUM(cd.whale_volume_eth) * 100.0) / NULLIF(SUM(cd.volume_eth), 0) AS whale_volume_percentage,
  
  -- 对于复杂的鲸鱼兴趣评分，使用默认值
  dci.smart_whale_interest_score,
  
  MAX(cd.is_in_working_set) AS is_in_working_set,
  CASE WHEN MAX(cd.is_in_working_set) = TRUE AND dci.is_in_working_set = FALSE 
       THEN CURRENT_DATE ELSE dci.working_set_join_date END AS working_set_join_date,
  CASE WHEN MAX(cd.is_in_working_set) = TRUE 
       THEN TIMESTAMPDIFF(DAY, dci.working_set_join_date, CURRENT_DATE) 
       ELSE dci.working_set_days END AS working_set_days,
  
  CASE WHEN MAX(cd.collection_date) >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN 0
       ELSE TIMESTAMPDIFF(DAY, MAX(cd.collection_date), CURRENT_DATE) END AS inactive_days,
  
  CASE WHEN MAX(cd.collection_date) >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN 'ACTIVE'
       WHEN TIMESTAMPDIFF(DAY, MAX(cd.collection_date), CURRENT_DATE) > 7 THEN 'INACTIVE'
       ELSE dci.status END AS status,
  
  dci.category,
  dci.total_whale_buys + SUM(cd.whale_buyers) AS total_whale_buys,
  dci.total_whale_sells + SUM(cd.whale_sellers) AS total_whale_sells,
  CURRENT_TIMESTAMP AS etl_time
FROM 
  dim_collection_info dci
JOIN 
  dwd.dwd_collection_daily_stats cd 
  ON dci.collection_address = cd.contract_address
LEFT JOIN
  ods.ods_collection_working_set cws
  ON dci.collection_address = cws.collection_address
WHERE 
  cd.collection_date > dci.last_active_date
GROUP BY
  dci.collection_address,
  dci.collection_name,
  dci.symbol,
  cws.logo_url,
  dci.logo_url,
  dci.first_tracked_date,
  dci.items_total,
  dci.owners_total,
  dci.is_verified,
  dci.all_time_volume_eth,
  dci.all_time_sales,
  dci.smart_whale_interest_score,
  dci.is_in_working_set,
  dci.working_set_join_date,
  dci.working_set_days,
  dci.status,
  dci.category,
  dci.total_whale_buys,
  dci.total_whale_sells; 