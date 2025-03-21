SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';

-- 创建Kafka数据源表
CREATE TABLE kafka_nft_transactions (
    kafka_partition INT METADATA FROM 'partition',
    kafka_offset BIGINT METADATA FROM 'offset',
    kafka_timestamp TIMESTAMP(3) METADATA FROM 'timestamp',
    `id` STRING,
    `transactionHash` STRING,
    `tokenId` STRING,
    `nftId` STRING,
    `collectionId` STRING,
    `collectionName` STRING,
    `seller` STRING,
    `buyer` STRING,
    `price` DOUBLE,
    `currency` STRING,
    `transactionType` STRING,
    `marketplace` STRING,
    `marketplaceFee` DOUBLE,
    `royaltyFee` DOUBLE,
    `gasFee` DOUBLE,
    `status` STRING, 
    `timestamp` BIGINT,
    `blockNumber` STRING,
    `isWhaleTransaction` BOOLEAN,
    `priceUSD` DOUBLE,
    `previousPrice` DOUBLE,
    `priceChange` DOUBLE,
    `priceChangePercent` DOUBLE,
    `isOutlier` BOOLEAN,
    `floorDifference` DOUBLE
) WITH (
    'connector' = 'kafka',
    'topic' = 'NFT_TRANSACTIONS',
    'properties.bootstrap.servers' = '192.168.254.133:9092',
    'properties.group.id' = 'nft-transaction-consumer-group',
    'scan.startup.mode' = 'latest-offset',
    'value.format' = 'json',
    'value.json.ignore-parse-errors' = 'true',
    'value.json.fail-on-missing-field' = 'false'
);

/* 每次运行时，都要创建Paimon Catalog */
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

-- 创建ODS数据库
CREATE DATABASE IF NOT EXISTS ods;

-- 创建NFT交易表 (增量表)
CREATE TABLE IF NOT EXISTS ods.ods_nft_transaction_inc (
    `id` STRING,
    `dt` STRING,
    `transactionHash` STRING,
    `tokenId` STRING,
    `nftId` STRING,
    `collectionId` STRING,
    `collectionName` STRING,
    `seller` STRING,
    `buyer` STRING,
    `price` DOUBLE,
    `currency` STRING,
    `transactionType` STRING,
    `marketplace` STRING,
    `marketplaceFee` DOUBLE,
    `royaltyFee` DOUBLE,
    `gasFee` DOUBLE,
    `status` STRING, 
    `timestamp` BIGINT,
    `blockNumber` STRING,
    `isWhaleTransaction` BOOLEAN,
    `priceUSD` DOUBLE,
    `previousPrice` DOUBLE,
    `priceChange` DOUBLE,
    `priceChangePercent` DOUBLE,
    `isOutlier` BOOLEAN,
    `floorDifference` DOUBLE,
    PRIMARY KEY (`id`) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'bucket-key' = 'id',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 将Kafka数据写入Paimon
INSERT INTO ods.ods_nft_transaction_inc
SELECT
    id,
    FROM_UNIXTIME(CAST(`timestamp` / 1000 AS BIGINT), 'yyyy-MM-dd') AS dt,
    transactionHash,
    tokenId,
    nftId,
    collectionId,
    collectionName,
    seller,
    buyer,
    price,
    currency,
    transactionType,
    marketplace,
    marketplaceFee,
    royaltyFee,
    gasFee,
    status,
    `timestamp`,
    blockNumber,
    isWhaleTransaction,
    priceUSD,
    previousPrice,
    priceChange,
    priceChangePercent,
    isOutlier,
    floorDifference
FROM default_catalog.default_database.kafka_nft_transactions; 