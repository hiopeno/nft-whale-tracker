-- 收藏集维度表 - DIM层重构

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

-- 删除现有表以便重建
DROP TABLE IF EXISTS dim_collection_info;

-- 创建收藏集维度表（精简版）
CREATE TABLE IF NOT EXISTS dim_collection_info (
    collection_address VARCHAR(255),        -- 收藏集地址
    collection_name VARCHAR(255),           -- 收藏集名称
    symbol VARCHAR(50),                     -- 代币符号
    logo_url VARCHAR(1000),                 -- Logo URL
    banner_url VARCHAR(1000),               -- Banner URL
    first_tracked_date DATE,                -- 首次追踪日期
    last_active_date DATE,                  -- 最后活跃日期
    items_total INT,                        -- NFT总数量
    owners_total INT,                       -- 持有者总数
    is_verified BOOLEAN,                    -- 是否已验证
    is_in_working_set BOOLEAN,              -- 是否在工作集
    working_set_join_date DATE,             -- 加入工作集日期
    category VARCHAR(100),                  -- 类别
    status VARCHAR(20),                     -- 状态
    etl_time TIMESTAMP,                     -- ETL处理时间
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
        MIN(cd.tx_date) AS first_tracked_date,
        MAX(cd.tx_date) AS last_active_date,
        0 AS items_total, -- 默认值，实际项目中应从外部源获取
        0 AS owners_total, -- 默认值，实际项目中应从外部源获取
        FALSE AS is_verified, -- 默认值，实际项目中应从外部源获取
        TRUE AS is_in_working_set,
        MIN(cd.tx_date) AS working_set_join_date,
        'NFT' AS category, -- 默认类别
        CASE 
            WHEN MAX(cd.tx_date) >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN 'ACTIVE'
            ELSE 'INACTIVE'
        END AS status,
        CURRENT_TIMESTAMP AS etl_time
    FROM 
        ods.ods_collection_working_set cws
    LEFT JOIN 
        dwd.dwd_transaction_clean cd ON cws.collection_address = cd.contract_address
    LEFT JOIN (
        SELECT DISTINCT contract_address, collection_name FROM dwd.dwd_transaction_clean
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
  JOIN dwd.dwd_transaction_clean cd ON dci.collection_address = cd.contract_address
  WHERE cd.tx_date > dci.last_active_date
);

-- 然后重新插入更新后的数据
INSERT INTO dim_collection_info
SELECT 
  dci.collection_address,
  dci.collection_name,
  dci.symbol,
  COALESCE(cws.logo_url, dci.logo_url) AS logo_url, -- 优先使用最新的logo_url
  dci.banner_url,
  dci.first_tracked_date,
  MAX(cd.tx_date) AS last_active_date,
  dci.items_total,
  dci.owners_total,
  dci.is_verified,
  dci.is_in_working_set,
  dci.working_set_join_date,
  dci.category,
  CASE WHEN MAX(cd.tx_date) >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN 'ACTIVE'
       ELSE 'INACTIVE' END AS status,
  CURRENT_TIMESTAMP AS etl_time
FROM 
  dim_collection_info dci
JOIN 
  dwd.dwd_transaction_clean cd 
  ON dci.collection_address = cd.contract_address
LEFT JOIN
  ods.ods_collection_working_set cws
  ON dci.collection_address = cws.collection_address
WHERE 
  cd.tx_date > dci.last_active_date
GROUP BY
  dci.collection_address,
  dci.collection_name,
  dci.symbol,
  cws.logo_url,
  dci.logo_url,
  dci.banner_url,
  dci.first_tracked_date,
  dci.items_total,
  dci.owners_total,
  dci.is_verified,
  dci.is_in_working_set,
  dci.working_set_join_date,
  dci.category; 