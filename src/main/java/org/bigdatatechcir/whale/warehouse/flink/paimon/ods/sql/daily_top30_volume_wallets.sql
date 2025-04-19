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
('2025-04-19', '0xaecf4dca61c9a9f769ebfb63f5f44bd6c403d251', 1, 155.099, 246509.1415, 51, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x29469395eaf6f95920e59f858042f0e28d98a20b', 2, 70.4277, 112125.5972, 41, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x807ea4c5d7945dfea05d358473fee6042e92cf37', 3, 40, 63444, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x7c76cf8894d42ed11b53236da54f05add1d44073', 4, 40, 63444, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x1ea27bce786a81022dfc156059771e8d3279a9a6', 5, 33.6899, 53492.3831, 14, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x511432a0ca35ea7a3874290872333b8b719280fc', 6, 25.9489, 41258.6838, 18, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x2eaea150e3c1e16ed2f5afd3fb96ce7cc1443f33', 7, 25.5, 40626.6, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x77384e62fddb42dea73b2a0a628f5ed7bd4d42d7', 8, 25.5, 40626.6, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x0b36792f715b99a773a938ae9c733b59522d2bbe', 9, 24.69, 39232.7804, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x2290f81330c51d712416ec074af282ba3a10ce3f', 10, 24.69, 39232.7804, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x6d5ebfbe5c33394a7d1f6c37f74173bab3e0e9f6', 11, 22.46, 35679.0576, 2, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0xfdc7ee2c43d3e4ae903ecfb68d731d44b813c620', 12, 21.2009, 33916.3396, 15, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x5b468edb7688e9ae6c1fa5a6d2debbef06e92907', 13, 20.6573, 32920.0186, 5, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x18beceb3674f20ee3f75c03ef06542c8c882d088', 14, 19, 30325.805, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x6b26eda810e5de599121e56e22667b19a2a64b9b', 15, 19, 30325.805, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x11f77377277be17ddfed9af34d29721bfa4030da', 16, 18.06, 28825.476, 10, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0xd7adf74d4ce376fbf90ceb980f0b070625e0f388', 17, 17.942, 28501.6023, 8, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0xef0b56692f78a44cf4034b07f80204757c31bcc9', 18, 16.5242, 26419.0597, 44, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x9e657264573770e33df0602764444632af4f2054', 19, 15.259, 24171.7961, 2, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x7c240dafebd8fce5146078d295ee2e58a5a022e0', 20, 15.199, 24076.3559, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x518ce3f0b6e33db825b36db1b5ad8151ce871c50', 21, 14.95, 23740.1615, 2, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x2777df13d272c9433858f5e1947b51e6a4720d60', 22, 14.6188, 23200.6616, 15, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0xcf0a85e5acf3f9627024361f3373011647d192a6', 23, 14.5, 23017.88, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x7e1de534d18fe49b23053c99f2ce2b4619a3f5f4', 24, 14.1825, 22635.7684, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x2a578a939bdc5486fa8c4f0ef865b71cca03ab7a', 25, 14, 22345.33, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0xd76e34c56cc3a9ee687854cc746959e90dd7dfe7', 26, 14, 22345.33, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0x8bab603fde4824950fa81268a84ef9cbb89cad69', 27, 12, 19062.72, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0xccd23c17daca17c99c3aca44be996e5611094f1c', 28, 11.75, 18720.1, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0xa900fbcb01245c9fafdc9f8d06c0c4e50620d610', 29, 11.75, 18720.1, 1, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP)),('2025-04-19', '0xe609549239157ff1341015308b1bff447ba7efe8', 30, 11.1939, 17819.8382, 23, TRUE, CAST('2025-04-19 19:03:32' AS TIMESTAMP))
;
