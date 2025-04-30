-- 当天交易额Top30钱包数据

-- NFT API数据表结构定义和数据导入

-- 设置执行参数
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.local-time-zone' = 'Asia/Shanghai';

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
CREATE DATABASE IF NOT EXISTS ods;
USE ods;


-- 当天交易额Top30钱包
CREATE TABLE IF NOT EXISTS ods_daily_top30_volume_wallets (
    rank_date STRING,
    account_address STRING,
    rank_num INT,
    trade_volume DOUBLE,
    trade_volume_usdc DOUBLE,
    trade_count BIGINT,
    is_whale BOOLEAN, 
    created_at TIMESTAMP(3),
    PRIMARY KEY (rank_date, account_address) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'bucket-key' = 'account_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '128MB'
);

-- 插入数据
INSERT INTO ods_daily_top30_volume_wallets (
    rank_date,
    account_address,
    rank_num,
    trade_volume,
    trade_volume_usdc,
    trade_count,
    is_whale,
    created_at
) VALUES
('2025-04-20', '0xaecf4dca61c9a9f769ebfb63f5f44bd6c403d251', 1, 131.352, 211349.0753, 49, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x29469395eaf6f95920e59f858042f0e28d98a20b', 2, 90.0266, 144585.2819, 44, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xf005093464e14cbacf0f9b9a371269fc118776dd', 3, 52, 84165.12, 1, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xeeb51149987e90cc815f0bca98f609933072d4c3', 4, 52, 84165.12, 1, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x1ea27bce786a81022dfc156059771e8d3279a9a6', 5, 41.2904, 66445.4265, 21, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xfc4672341c78f1ebc0c23fdbcbb03b61c6f2d50f', 6, 38.13, 60976.1801, 4, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xa2de7065ae0c9a87b867cc91fb3418cc6f5f1a2b', 7, 28.6436, 46193.9508, 11, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x585da029caedd7dfb702f71960fc9b0af931243a', 8, 28.14, 45193.4028, 3, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x1c3becc3000ec36300b260cdb19a67e02d35059a', 9, 26.013, 41967.0948, 19, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x511432a0ca35ea7a3874290872333b8b719280fc', 10, 23.7659, 38114.6317, 25, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x532ee831bb3c2bbe6f60f4fd523f912699152905', 11, 23.55, 37826.6159, 8, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x8da03feb7174b4b2a6b323f3dc40d97f3421cd07', 12, 21.69, 35046.9189, 1, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xb3e12a0ac4fb13fe091b448f45b81b1da0246994', 13, 21.69, 35046.9189, 1, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x2742cf55ddfdadb5e8449fd4b4a7fbded34408a0', 14, 19.31, 31067.7337, 2, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xa71a705c620ff8ddff7f5144800613469d5838bb', 15, 19.119, 30430.9475, 2, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xf84a4eeca2953bf5c16f5fdad2ab85738be66244', 16, 17.507, 28134.0619, 15, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xfdc7ee2c43d3e4ae903ecfb68d731d44b813c620', 17, 15.3038, 24580.8665, 10, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x08476da7fa9f54c8e931a4ab185d18f2caa76b4b', 18, 14.346, 23131.7505, 9, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x568f888e808621bde2f8f6511bfcf952732ae70c', 19, 12.2673, 19749.9639, 79, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x4b6760682191de7e476b801b7ab42d8e8a5b041a', 20, 11.7473, 18791.111, 39, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x8a7d2a5fa5912e6feef47c8184d4e4ff56681f0c', 21, 11.32, 18048.0274, 6, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xfc5ce134b32366bb58d920b700513b3cdd756576', 22, 11.168, 17958.4009, 11, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xe609549239157ff1341015308b1bff447ba7efe8', 23, 10.1747, 16359.569, 20, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x4c95915aa398c0e4aef6d7dd1ff5c0f9adbf9729', 24, 10.0617, 15843.2229, 2, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xd7adf74d4ce376fbf90ceb980f0b070625e0f388', 25, 10.0427, 16187.0315, 5, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xbf5b2954d58b6726d610046e97acaa41bd7d2e83', 26, 9.584, 15470.9241, 1, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xd43dfa9024096b0224adf6859e22fbc35ea2b21f', 27, 9.584, 15470.9241, 1, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0x88b835e481cabef3c7c35e4007b2f413aab7755f', 28, 9.49, 15197.4749, 5, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xa8a50450f7ddb46154c4e3c415b90e40a374e818', 29, 8.88, 14333.4197, 3, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP)),('2025-04-20', '0xdfe9def041c0a05d3de86d24adaa8f9a31cd0118', 30, 8.4327, 13642.3377, 4, TRUE, CAST('2025-04-20 20:52:17' AS TIMESTAMP))
;
