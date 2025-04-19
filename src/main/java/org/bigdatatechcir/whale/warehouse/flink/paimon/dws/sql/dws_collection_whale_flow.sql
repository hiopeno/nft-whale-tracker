-- 收藏集鲸鱼资金流向表

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
CREATE DATABASE IF NOT EXISTS dws;
USE dws;

-- 创建收藏集鲸鱼资金流向表
CREATE TABLE IF NOT EXISTS dws_collection_whale_flow (
    stat_date DATE,
    collection_address VARCHAR(255),
    collection_name VARCHAR(255),
    whale_type VARCHAR(50),
    whale_buy_count INT,
    whale_sell_count INT,
    whale_buy_volume_eth DECIMAL(30,10),
    whale_sell_volume_eth DECIMAL(30,10),
    net_flow_eth DECIMAL(30,10),
    is_net_inflow BOOLEAN,
    unique_whale_buyers INT,
    unique_whale_sellers INT,
    whale_trading_percentage DECIMAL(10,2),
    whale_buy_avg_price_eth DECIMAL(30,10),
    whale_sell_avg_price_eth DECIMAL(30,10),
    avg_price_eth DECIMAL(30,10),
    floor_price_eth DECIMAL(30,10),
    total_volume_eth DECIMAL(30,10),
    whale_ownership_percentage DECIMAL(10,2),
    accu_net_flow_7d DECIMAL(30,10),
    accu_net_flow_30d DECIMAL(30,10),
    rank_by_whale_volume INT,
    rank_by_net_flow INT,
    is_in_working_set BOOLEAN,
    data_source VARCHAR(100),
    etl_time TIMESTAMP,
    PRIMARY KEY (stat_date, collection_address, whale_type) NOT ENFORCED
) WITH (
    'bucket' = '8',
    'bucket-key' = 'collection_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 计算并更新收藏集鲸鱼资金流向数据
INSERT INTO dws_collection_whale_flow
WITH daily_whale_txs AS (
    -- 按收藏集和鲸鱼类型分组的当日交易数据
    SELECT 
        tx.tx_date,
        tx.contract_address,
        tx.collection_name,
        w.whale_type,
        CAST(COUNT(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN 1 END) AS INT) AS whale_buy_count,
        CAST(COUNT(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN 1 END) AS INT) AS whale_sell_count,
        CAST(SUM(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.trade_price_eth ELSE 0 END) AS DECIMAL(30,10)) AS whale_buy_volume_eth,
        CAST(SUM(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.trade_price_eth ELSE 0 END) AS DECIMAL(30,10)) AS whale_sell_volume_eth,
        CAST(COUNT(DISTINCT CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.to_address END) AS INT) AS unique_whale_buyers,
        CAST(COUNT(DISTINCT CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.from_address END) AS INT) AS unique_whale_sellers,
        CAST(
            CASE 
                WHEN COUNT(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN 1 END) > 0 
                THEN SUM(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.trade_price_eth ELSE 0 END) / 
                     COUNT(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN 1 END)
                ELSE 0 
            END
        AS DECIMAL(30,10)) AS whale_buy_avg_price_eth,
        CAST(
            CASE 
                WHEN COUNT(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN 1 END) > 0 
                THEN SUM(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.trade_price_eth ELSE 0 END) / 
                     COUNT(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN 1 END)
                ELSE 0 
            END
        AS DECIMAL(30,10)) AS whale_sell_avg_price_eth
    FROM 
        dwd.dwd_whale_transaction_detail tx
    JOIN 
        dim.dim_whale_address w ON (tx.to_is_whale AND tx.to_address = w.wallet_address) OR (tx.from_is_whale AND tx.from_address = w.wallet_address)
    GROUP BY 
        tx.tx_date,
        tx.contract_address,
        tx.collection_name,
        w.whale_type
),
collection_stats AS (
    -- 收藏集当日总体统计
    SELECT 
        tx_date,
        contract_address,
        collection_name,
        CAST(COUNT(*) AS INT) AS total_txs,
        CAST(SUM(trade_price_eth) AS DECIMAL(30,10)) AS total_volume_eth,
        CAST(
            CASE 
                WHEN COUNT(*) > 0 
                THEN SUM(trade_price_eth) / COUNT(*) 
                ELSE 0 
            END
        AS DECIMAL(30,10)) AS avg_price_eth,
        CAST(0 AS DECIMAL(30,10)) AS floor_price_eth,
        MAX(is_in_working_set) AS is_in_working_set
    FROM 
        dwd.dwd_whale_transaction_detail
    GROUP BY 
        tx_date,
        contract_address,
        collection_name
),
whale_ownership AS (
    -- 计算鲸鱼持有比例（从DWS层的whale_ownership表中获取）
    SELECT 
        collection_address,
        whale_ownership_percentage
    FROM 
        dws_collection_whale_ownership
    WHERE 
        stat_date = CURRENT_DATE
),
historical_flows AS (
    -- 计算历史净流入
    SELECT 
        collection_address,
        whale_type,
        CAST(SUM(CASE WHEN stat_date >= (CURRENT_DATE - INTERVAL '7' DAY) THEN net_flow_eth ELSE 0 END) AS DECIMAL(30,10)) AS accu_net_flow_7d,
        CAST(SUM(CASE WHEN stat_date >= (CURRENT_DATE - INTERVAL '30' DAY) THEN net_flow_eth ELSE 0 END) AS DECIMAL(30,10)) AS accu_net_flow_30d
    FROM 
        dws_collection_whale_flow
    GROUP BY 
        collection_address,
        whale_type
),
rankings AS (
    -- 计算排名
    SELECT 
        w.tx_date,
        w.contract_address,
        w.whale_type,
        CAST(ROW_NUMBER() OVER (PARTITION BY w.tx_date, w.whale_type ORDER BY (w.whale_buy_volume_eth + w.whale_sell_volume_eth) DESC) AS INT) AS rank_by_whale_volume,
        CAST(ROW_NUMBER() OVER (PARTITION BY w.tx_date, w.whale_type ORDER BY (w.whale_buy_volume_eth - w.whale_sell_volume_eth) DESC) AS INT) AS rank_by_net_flow
    FROM 
        daily_whale_txs w
)
SELECT 
    dwt.tx_date AS stat_date,
    dwt.contract_address AS collection_address,
    dwt.collection_name,
    dwt.whale_type,
    dwt.whale_buy_count,
    dwt.whale_sell_count,
    dwt.whale_buy_volume_eth,
    dwt.whale_sell_volume_eth,
    CAST((dwt.whale_buy_volume_eth - dwt.whale_sell_volume_eth) AS DECIMAL(30,10)) AS net_flow_eth,
    CASE WHEN (dwt.whale_buy_volume_eth - dwt.whale_sell_volume_eth) > 0 THEN TRUE ELSE FALSE END AS is_net_inflow,
    dwt.unique_whale_buyers,
    dwt.unique_whale_sellers,
    CAST(
        CASE 
            WHEN cs.total_volume_eth > 0 
            THEN ((dwt.whale_buy_volume_eth + dwt.whale_sell_volume_eth) / cs.total_volume_eth) * 100 
            ELSE 0 
        END
    AS DECIMAL(10,2)) AS whale_trading_percentage,
    dwt.whale_buy_avg_price_eth,
    dwt.whale_sell_avg_price_eth,
    cs.avg_price_eth,
    cs.floor_price_eth,
    cs.total_volume_eth,
    CAST(COALESCE(wo.whale_ownership_percentage, 0) AS DECIMAL(10,2)) AS whale_ownership_percentage,
    CAST(COALESCE(hf.accu_net_flow_7d, 0) + (dwt.whale_buy_volume_eth - dwt.whale_sell_volume_eth) AS DECIMAL(30,10)) AS accu_net_flow_7d,
    CAST(COALESCE(hf.accu_net_flow_30d, 0) + (dwt.whale_buy_volume_eth - dwt.whale_sell_volume_eth) AS DECIMAL(30,10)) AS accu_net_flow_30d,
    r.rank_by_whale_volume,
    r.rank_by_net_flow,
    cs.is_in_working_set,
    CAST('dim_collection_info,dim_whale_address,dwd_whale_transaction_detail' AS VARCHAR(100)) AS data_source,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS etl_time
FROM 
    daily_whale_txs dwt
JOIN 
    collection_stats cs ON dwt.tx_date = cs.tx_date AND dwt.contract_address = cs.contract_address
LEFT JOIN 
    whale_ownership wo ON dwt.contract_address = wo.collection_address
LEFT JOIN 
    historical_flows hf ON dwt.contract_address = hf.collection_address AND dwt.whale_type = hf.whale_type
LEFT JOIN 
    rankings r ON dwt.tx_date = r.tx_date AND dwt.contract_address = r.contract_address AND dwt.whale_type = r.whale_type; 