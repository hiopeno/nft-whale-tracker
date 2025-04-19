-- 收藏集交易数据 批次 11 (记录 5000-5003)

-- 设置任务名称，确保每个批次有唯一的任务标识
SET 'pipeline.name' = 'NFT_Transaction_Batch_11_Records_5000_5004';

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


-- 字段映射说明:
-- record_time: 当前时间戳
-- hash: 对应JSON的hash字段
-- buyer_address: 对应JSON的from字段 
-- marketplace_address: 对应JSON的to字段
-- block_number: 对应JSON的block_number字段
-- block_hash: 对应JSON的block_hash字段
-- gas_price: 对应JSON的gas_price字段
-- gas_used: 对应JSON的gas_used字段
-- gas_fee: 对应JSON的gas_fee字段
-- tx_timestamp: 对应JSON的timestamp字段
-- contract_address: 对应JSON的contract_address字段
-- contract_name: 对应JSON的contract_name字段
-- contract_token_id: 对应JSON的contract_token_id字段
-- token_id: 对应JSON的token_id字段
-- erc_type: 对应JSON的erc_type字段
-- from_address: 对应JSON的send字段
-- to_address: 对应JSON的receive字段
-- amount: 对应JSON的amount字段
-- trade_value: 对应JSON的trade_value字段
-- trade_price: 对应JSON的trade_price字段
-- trade_symbol: 对应JSON的trade_symbol字段
-- trade_symbol_address: 对应JSON的trade_symbol_address字段
-- event_type: 对应JSON的event_type字段
-- exchange_name: 对应JSON的exchange_name字段
-- aggregate_exchange_name: 对应JSON的aggregate_exchange_name字段
-- nftscan_tx_id: 对应JSON的nftscan_tx_id字段

-- 收藏集交易数据
CREATE TABLE IF NOT EXISTS ods_collection_transaction_inc (
    record_time TIMESTAMP,
    hash VARCHAR(255),
    buyer_address VARCHAR(255),
    marketplace_address VARCHAR(255),
    block_number VARCHAR(50),
    block_hash VARCHAR(255),
    gas_price VARCHAR(255),
    gas_used VARCHAR(255),
    gas_fee DECIMAL(30,10),
    tx_timestamp DECIMAL(30,10),
    contract_address VARCHAR(255),
    contract_name VARCHAR(255),
    contract_token_id VARCHAR(255),
    token_id VARCHAR(255),
    erc_type VARCHAR(50),
    from_address VARCHAR(255),
    to_address VARCHAR(255),
    amount VARCHAR(255),
    trade_value VARCHAR(255),
    trade_price DECIMAL(30,10),
    trade_symbol VARCHAR(255),
    trade_symbol_address VARCHAR(255),
    event_type VARCHAR(50),
    exchange_name VARCHAR(255),
    aggregate_exchange_name VARCHAR(255),
    nftscan_tx_id VARCHAR(255),
    PRIMARY KEY (record_time, hash, contract_address, token_id) NOT ENFORCED
) WITH (
    'bucket' = '8',
    'bucket-key' = 'contract_address',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '5',
    'compaction.max.file-num' = '50',
    'compaction.target-file-size' = '256MB'
);

-- 插入数据 批次 11 (任务名称: NFT_Transaction_Batch_11_Records_5000_5004)
INSERT INTO ods_collection_transaction_inc (
    record_time,
    hash,
    buyer_address,
    marketplace_address,
    block_number,
    block_hash,
    gas_price,
    gas_used,
    gas_fee,
    tx_timestamp,
    contract_address,
    contract_name,
    contract_token_id,
    token_id,
    erc_type,
    from_address,
    to_address,
    amount,
    trade_value,
    trade_price,
    trade_symbol,
    trade_symbol_address,
    event_type,
    exchange_name,
    aggregate_exchange_name,
    nftscan_tx_id
) VALUES
(CAST('2025-04-15 14:16:35' AS TIMESTAMP), '0xffa60920872c08dfd762e3b94d8d810efc7e6e56f54ee76f045061a08156f02b', '0x367d9fe21c6e66b9a2f169c229e0203b5619e4de', '0x0000000000c2d145a2526bd8c716263bfebe1a72', '22261519', '0xc4a96e02f3f09e24d2831882e137c4b11bc6389337fb70d3e33cc69b7416d151', '0x37e7d6cd', '0x11a59', 6.7795290652485e-05, 1744564967000, '0xb5af0c7f3885c1007e6699c357566610291585cb', 'Infinex Patrons', '0x0000000000000000000000000000000000000000000000000000000000002ac3', '10947', 'erc721', '0x367d9fe21c6e66b9a2f169c229e0203b5619e4de', '0xda8ac7f40274f6efb57ddc09efd691cab79137ce', '1', '0x0', 0, 'ETH', '', 'Transfer', '', '', '2226151901510001'),
(CAST('2025-04-15 14:16:35' AS TIMESTAMP), '0xffd09b48f9aebd596230a1342ca36eb708614dd8c9481db6a1419d7d5cb32d8e', '0xa83b468e5d645e01a88951ca43ec9665b61bf546', '0xbb5b742156df1fd58b87d15701a7096a008e8cb9', '22259937', '0x0d42c1be6e9e6653301759540955f92516e7f10bbef164d45fe5a5f247babfae', '0x718dd25e', '0x3e9c8', 0.000488579413174128, 1744545923000, '0x1a3c1bf0bd66eb15cd4a61b76a20fb68609f97ef', 'Morph Black', '0x000000000000000000000000000000000000000000000000000000000000076a', '1898', 'erc721', '0xa83b468e5d645e01a88951ca43ec9665b61bf546', '0xbb5b742156df1fd58b87d15701a7096a008e8cb9', '1', '0x0', 0, 'ETH', '', 'Transfer', '', '', '2225993700360001'),
(CAST('2025-04-15 14:16:35' AS TIMESTAMP), '0xffdc6fed99865e084eda09f3ac9c66a50abb0b1e26cd5e415ba44ef1ea898744', '0xc800f85d6662ca09ee053348b72ea9c0cdc6cc5b', '0x0000000000c2d145a2526bd8c716263bfebe1a72', '22177426', '0x80126c887b4bc69dcda6d0a72ce8772a3f394d02ebb7e4e6eac7f2ef313a648c', '0x24473fa0', '0x18b50', 6.1595290944e-05, 1743551123000, '0xc143bbfcdbdbed6d454803804752a064a622c1f3', 'Async Blueprints', '0x0000000000000000000000000000000000000000000000000000000000003b4f', '15183', 'erc721', '0xc800f85d6662ca09ee053348b72ea9c0cdc6cc5b', '0x99deb4f9975972beee9d80fe0ff2be981bdfa4e6', '1', '0x0', 0, 'ETH', '', 'Transfer', '', '', '2217742600890002'),
(CAST('2025-04-15 14:16:35' AS TIMESTAMP), '0xfffb0945a3ba154e45e41a988ff362bd801ac0614f3eb7602216aa00fbf508f4', '0xdcaf023ee67a220207afcaa8fc08e5823074e013', '0xc5d5b9f30aa674aa210a0ec24941bad7d8b42069', '22262536', '0x7b9dbcaea74210b945a5edc37d58e8444ada401aba2e63fed84f6ec04aae348f', '0x5bbbc819', '0x11a6b5', 0.001780336575754157, 1744577207000, '0xd32cb5f76989a27782e44c5297aaba728ad61669', 'HyPC License', '0x0000000000000000000000000000000000000000000000000002000800000e6b', '562984313163371', 'erc721', '0xc5d5b9f30aa674aa210a0ec24941bad7d8b42069', '0x4bfba79cf232361a53eddd17c67c6c77a6f00379', '1', '0x0', 0, 'ETH', '', 'Transfer', '', '', '2226253600490003');

-- 批次 11 执行完成
