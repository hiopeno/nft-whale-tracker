-- 市场维度表
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.exec.mini-batch.enabled' = 'true';
SET 'table.exec.mini-batch.allow-latency' = '5s';
SET 'table.exec.mini-batch.size' = '5000';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'table.exec.sink.not-null-enforcer'='DROP';
SET 'table.exec.sink.upsert-materialize' = 'NONE';

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

-- 创建DIM数据库
CREATE DATABASE IF NOT EXISTS dim;

-- 创建市场维度表
CREATE TABLE IF NOT EXISTS dim.dim_marketplace_full (
    `id` STRING, -- 市场标识符
    `name` STRING, -- 市场名称
    `website_url` STRING, -- 网站URL
    `logo_url` STRING, -- Logo URL
    `description` STRING, -- 描述
    `blockchain` STRING, -- 支持的区块链网络
    `marketplace_fee_ratio` DOUBLE, -- 市场手续费率
    `royalty_fee_ratio` DOUBLE, -- 版税费率
    `avg_gas_fee` DOUBLE, -- 平均gas费用
    `supported_currencies` STRING, -- 支持的货币(JSON数组)
    `supported_transaction_types` STRING, -- 支持的交易类型(JSON数组)
    `supported_standards` STRING, -- 支持的代币标准(JSON数组)
    `market_focus` STRING, -- 市场专注领域(艺术/游戏/音乐等)
    `founding_date` DATE, -- 成立日期
    `trading_volume_usd` DOUBLE, -- 交易量(USD)
    `trading_volume_eth` DOUBLE, -- 交易量(ETH)
    `transaction_count` BIGINT, -- 交易次数
    `unique_users` BIGINT, -- 独立用户数
    `unique_nfts` BIGINT, -- 独立NFT数
    `unique_collections` BIGINT, -- 独立系列数
    `avg_transaction_price` DOUBLE, -- 平均交易价格
    `avg_transaction_time` DOUBLE, -- 平均交易完成时间(秒)
    `security_features` STRING, -- 安全特性
    `has_launchpad` BOOLEAN, -- 是否有发布平台
    `has_staking` BOOLEAN, -- 是否有质押功能
    `has_fractional` BOOLEAN, -- 是否支持碎片化
    `has_lending` BOOLEAN, -- 是否支持借贷
    `market_rank` INT, -- 市场排名
    `active_listings` BIGINT, -- 活跃挂单数
    `market_share` DOUBLE, -- 市场份额百分比
    `user_growth_30d` DOUBLE, -- 30天用户增长率
    `volume_growth_30d` DOUBLE, -- 30天交易量增长率
    `updated_at` TIMESTAMP(3), -- 更新时间
    PRIMARY KEY (`id`) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'bucket-key' = 'id',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'lookup',
    'changelog-producer.lookup.db' = 'dim',
    'changelog-producer.lookup.table' = 'dim_marketplace_full'
);

-- 创建临时视图：交易市场统计
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_stats AS
SELECT
    marketplace AS id,
    SUM(CAST(1 AS INT)) AS transaction_times,
    COUNT(DISTINCT buyer) AS unique_users_buying,
    COUNT(DISTINCT seller) AS unique_users_selling,
    COUNT(DISTINCT nftId) AS unique_nfts,
    COUNT(DISTINCT collectionId) AS unique_collections,
    SUM(price) AS total_volume_eth,
    AVG(price) AS avg_transaction_price
FROM dwd.dwd_nft_transaction_inc
WHERE marketplace IS NOT NULL
GROUP BY marketplace;

-- 创建临时视图：市场信息表(简化版，实际应用可能来自专门的市场信息源)
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_info AS
SELECT
    id,
    name,
    website_url,
    logo_url,
    description,
    blockchain,
    marketplace_fee_ratio,
    royalty_fee_ratio,
    avg_gas_fee,
    supported_currencies,
    supported_transaction_types,
    supported_standards,
    market_focus,
    founding_date
FROM (
    VALUES
    ('opensea', 'OpenSea', 'https://opensea.io', '/images/marketplaces/opensea.png', 'Largest NFT marketplace supporting various blockchains', 'Ethereum,Polygon,Solana', 0.025, 0.05, 0.2, '["ETH","WETH","USDC"]', '["BUY","SELL","AUCTION"]', '["ERC721","ERC1155"]', 'General Market', DATE '2017-12-20'),
    ('blur', 'Blur', 'https://blur.io', '/images/marketplaces/blur.png', 'Zero-fee NFT marketplace focusing on professional traders', 'Ethereum', 0.0, 0.05, 0.15, '["ETH","BLUR"]', '["BUY","SELL"]', '["ERC721"]', 'Pro Traders', DATE '2022-03-28'),
    ('x2y2', 'X2Y2', 'https://x2y2.io', '/images/marketplaces/x2y2.png', 'Community-first NFT marketplace with token incentives', 'Ethereum', 0.02, 0.05, 0.18, '["ETH","X2Y2"]', '["BUY","SELL","DUTCH"]', '["ERC721","ERC1155"]', 'Collectors', DATE '2022-02-01'),
    ('looksrare', 'LooksRare', 'https://looksrare.org', '/images/marketplaces/looksrare.png', 'Rewarding NFT platform with LOOKS token rewards', 'Ethereum', 0.02, 0.05, 0.17, '["ETH","LOOKS"]', '["BUY","SELL","AUCTION"]', '["ERC721","ERC1155"]', 'Stakers', DATE '2022-01-10')
) AS t(id, name, website_url, logo_url, description, blockchain, marketplace_fee_ratio, royalty_fee_ratio, avg_gas_fee, supported_currencies, supported_transaction_types, supported_standards, market_focus, founding_date);

-- 创建临时视图：交易增长率（不使用窗口函数）
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_growth AS
SELECT
    a.marketplace AS id,
    a.current_volume,
    a.current_users,
    -- 模拟30天前数据，避免窗口函数
    CAST(a.current_volume * 0.8 AS DOUBLE) AS volume_30d_ago,
    CAST(a.current_users * 0.85 AS DOUBLE) AS users_30d_ago
FROM (
    SELECT 
        marketplace,
        SUM(CAST(1 AS INT)) AS current_volume,
        COUNT(DISTINCT buyer) + COUNT(DISTINCT seller) AS current_users
    FROM dwd.dwd_nft_transaction_inc
    WHERE marketplace IS NOT NULL
    GROUP BY marketplace
) a;

-- 创建临时视图：市场交易平均时间(简化计算)
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_tx_time AS
SELECT
    marketplace AS id,
    -- 交易平均时间(模拟计算)
    5.0 + marketplace_id_hash * 5.0 AS avg_transaction_time
FROM (
    SELECT 
        marketplace, 
        ABS(HASH_CODE(marketplace) % 100) / 100.0 AS marketplace_id_hash
    FROM (
        SELECT DISTINCT marketplace 
        FROM dwd.dwd_nft_transaction_inc 
        WHERE marketplace IS NOT NULL
    )
) t;

-- 创建临时视图：活跃上架数量(简化计算)
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_listings AS
SELECT
    marketplace AS id,
    -- 模拟活跃上架数量，使用交易数量的3倍
    CAST(tx_count * 3 AS BIGINT) AS active_listings
FROM (
    SELECT 
        marketplace, 
        SUM(CAST(1 AS INT)) AS tx_count
    FROM dwd.dwd_nft_transaction_inc 
    WHERE marketplace IS NOT NULL
    GROUP BY marketplace
) t;

-- 创建临时视图：市场排名（不使用DENSE_RANK窗口函数）
CREATE TEMPORARY VIEW IF NOT EXISTS marketplace_ranking AS
SELECT
    ranked.id,
    ranked.rank_pos AS market_rank
FROM (
    SELECT
        t1.id,
        1 + CAST(SUM(
            CASE WHEN t2.transaction_times > t1.transaction_times THEN 1 ELSE 0 END
        ) AS INT) AS rank_pos
    FROM marketplace_stats t1
    CROSS JOIN marketplace_stats t2
    GROUP BY t1.id, t1.transaction_times
) ranked;

-- 计算总交易量用于市场份额计算
CREATE TEMPORARY VIEW IF NOT EXISTS total_volume AS
SELECT SUM(total_volume_eth) AS total_eth
FROM marketplace_stats;

-- 将数据插入市场维度表
INSERT INTO dim.dim_marketplace_full
SELECT
    ms.id,
    COALESCE(mi.name, ms.id) AS name,
    COALESCE(mi.website_url, CONCAT('https://', ms.id, '.io')) AS website_url,
    COALESCE(mi.logo_url, '/images/marketplaces/default.png') AS logo_url,
    COALESCE(mi.description, '') AS description,
    COALESCE(mi.blockchain, 'Ethereum') AS blockchain,
    COALESCE(mi.marketplace_fee_ratio, 0.025) AS marketplace_fee_ratio,
    COALESCE(mi.royalty_fee_ratio, 0.05) AS royalty_fee_ratio,
    COALESCE(mi.avg_gas_fee, 0.2) AS avg_gas_fee,
    COALESCE(mi.supported_currencies, '["ETH"]') AS supported_currencies,
    COALESCE(mi.supported_transaction_types, '["BUY","SELL"]') AS supported_transaction_types,
    COALESCE(mi.supported_standards, '["ERC721"]') AS supported_standards,
    COALESCE(mi.market_focus, 'General') AS market_focus,
    COALESCE(mi.founding_date, DATE '2020-01-01') AS founding_date,
    -- 交易量 ETH
    COALESCE(ms.total_volume_eth, 0.0) AS trading_volume_eth,
    -- 交易量 USD (简单估算)
    COALESCE(ms.total_volume_eth * 2200, 0.0) AS trading_volume_usd, -- 假设1 ETH = 2200 USD
    COALESCE(ms.transaction_times, 0) AS transaction_count,
    COALESCE(ms.unique_users_buying + ms.unique_users_selling, 0) AS unique_users,
    COALESCE(ms.unique_nfts, 0) AS unique_nfts,
    COALESCE(ms.unique_collections, 0) AS unique_collections,
    COALESCE(ms.avg_transaction_price, 0.0) AS avg_transaction_price,
    COALESCE(mt.avg_transaction_time, 5.0) AS avg_transaction_time,
    -- 安全特性(虚构值)
    'Two-factor authentication, Escrow' AS security_features,
    -- 是否有特殊功能(虚构值)
    CASE WHEN ms.id IN ('opensea', 'rarible') THEN true ELSE false END AS has_launchpad,
    CASE WHEN ms.id IN ('nftx') THEN true ELSE false END AS has_staking,
    CASE WHEN ms.id IN ('fractional') THEN true ELSE false END AS has_fractional,
    CASE WHEN ms.id IN ('nftfi') THEN true ELSE false END AS has_lending,
    COALESCE(mr.market_rank, 999) AS market_rank,
    COALESCE(ml.active_listings, 0) AS active_listings,
    -- 市场份额计算
    COALESCE(ms.total_volume_eth / NULLIF((SELECT total_eth FROM total_volume), 0), 0.0) AS market_share,
    -- 用户增长率
    CASE 
        WHEN mg.users_30d_ago > 0 THEN
            CAST((mg.current_users - mg.users_30d_ago) / mg.users_30d_ago AS DOUBLE)
        ELSE 0.0
    END AS user_growth_30d,
    -- 交易量增长率
    CASE 
        WHEN mg.volume_30d_ago > 0 THEN
            CAST((mg.current_volume - mg.volume_30d_ago) / mg.volume_30d_ago AS DOUBLE)
        ELSE 0.0
    END AS volume_growth_30d,
    CURRENT_TIMESTAMP AS updated_at
FROM marketplace_stats ms
LEFT JOIN marketplace_info mi ON ms.id = mi.id
LEFT JOIN marketplace_growth mg ON ms.id = mg.id
LEFT JOIN marketplace_tx_time mt ON ms.id = mt.id
LEFT JOIN marketplace_listings ml ON ms.id = ml.id
LEFT JOIN marketplace_ranking mr ON ms.id = mr.id; 