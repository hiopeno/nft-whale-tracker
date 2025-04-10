-- 创建NFT交易数据视图，适配前后端需求
CREATE VIEW IF NOT EXISTS api_nft_transactions AS
SELECT 
    -- 基本交易信息
    id,
    transaction_hash AS transactionHash,
    token_id AS tokenId,
    collection_id AS collectionId,
    collection_name AS collectionName,
    seller_address AS seller,
    buyer_address AS buyer,
    price,
    currency,
    transaction_type AS transactionType,
    marketplace,
    CAST(unix_timestamp(transaction_time) * 1000 AS BIGINT) AS timestamp,
    
    -- 额外交易信息
    marketplace_fee AS marketplaceFee,
    royalty_fee AS royaltyFee,
    gas_fee AS gasFee,
    status,
    block_number AS blockNumber,
    
    -- 价格相关信息
    price_usd AS priceUSD,
    previous_price AS previousPrice,
    (price - previous_price) AS priceChange,
    CASE 
        WHEN previous_price > 0 THEN ((price - previous_price) / previous_price) * 100
        ELSE 0
    END AS priceChangePercent,
    
    -- 鲸鱼交易标记
    CASE 
        WHEN seller_is_whale = TRUE OR buyer_is_whale = TRUE THEN TRUE
        ELSE FALSE
    END AS isWhaleTransaction,
    
    -- 额外前端展示字段
    CASE 
        WHEN price > floor_price * 1.5 THEN TRUE
        ELSE FALSE
    END AS isOutlier,
    (price - floor_price) AS floorDifference,
    
    -- 交易行为类型 (用于前端过滤/标记)
    CASE 
        WHEN buyer_is_whale = TRUE AND seller_is_whale = FALSE THEN 'whale_buy'
        WHEN buyer_is_whale = FALSE AND seller_is_whale = TRUE THEN 'whale_sell'
        WHEN price < floor_price * 0.8 THEN 'bargain'
        WHEN price > floor_price * 1.5 THEN 'fomo'
        WHEN previous_price > 0 AND price > previous_price * 1.2 THEN 'profit'
        WHEN hold_time < 86400 THEN 'flip'  -- 持有时间小于1天
        WHEN buyer_transaction_count < 5 THEN 'explore'  -- 买家交易次数少
        WHEN price_change_percent > 20 THEN 'accumulate'
        WHEN price_change_percent < -10 THEN 'dump'
        ELSE 'normal'
    END AS actionType
FROM ods.ods_nft_transaction_inc;

-- 创建鲸鱼钱包数据视图
CREATE VIEW IF NOT EXISTS api_whale_wallets AS
SELECT
    -- 基本钱包信息
    id,
    wallet_address AS walletAddress,
    nickname,
    total_value AS totalValue,
    nft_count AS nftCount,
    collections_count AS collectionsCount,
    
    -- 交易量相关
    volume_24h AS volume24h,
    volume_7d AS volume7d,
    volume_30d AS volume30d,
    volume_total AS volumeTotal,
    
    -- 交易历史
    CAST(unix_timestamp(first_transaction_date) * 1000 AS BIGINT) AS firstTransactionDate,
    CAST(unix_timestamp(last_transaction_date) * 1000 AS BIGINT) AS lastTransactionDate,
    transaction_count AS transactionCount,
    
    -- 收藏集合
    top_collections AS topCollections,
    
    -- 收益和行为特征
    profit_loss AS profitLoss,
    wallet_type AS walletType,
    average_hold_time AS averageHoldTime,
    
    -- 社交信息
    verified,
    profile_image_url AS profileImageUrl,
    twitter,
    website,
    
    -- 鲸鱼评分
    whale_score AS whaleScore
FROM dws.dws_whale_wallet;

-- 创建NFT集合数据视图
CREATE VIEW IF NOT EXISTS api_nft_collections AS
SELECT
    -- 基本集合信息
    id,
    name,
    description,
    symbol,
    image_url AS imageUrl,
    banner_image_url AS bannerImageUrl,
    creator,
    blockchain,
    contract_address AS contractAddress,
    
    -- 集合统计信息
    total_supply AS totalSupply,
    floor_price AS floorPrice,
    volume_24h AS volume24h,
    volume_total AS volumeTotal,
    market_cap AS marketCap,
    owners_count AS ownersCount,
    
    -- 分类和验证信息
    category,
    verified,
    
    -- 时间戳
    CAST(unix_timestamp(created_at) * 1000 AS BIGINT) AS createdAt,
    CAST(unix_timestamp(updated_at) * 1000 AS BIGINT) AS updatedAt,
    
    -- 社交链接
    website,
    twitter,
    discord,
    
    -- 额外前端需要的数据
    whale_interest_score AS whaleInterestScore,
    whale_ownership_percent AS whaleOwnershipPercent,
    price_trend_7d AS priceTrend7d
FROM dws.dws_nft_collection;

-- 创建热门NFT集合统计视图
CREATE VIEW IF NOT EXISTS api_hot_collections AS
SELECT
    collection_id AS collectionId,
    collection_name AS collectionName,
    image_url AS imageUrl,
    floor_price AS floorPrice,
    volume_24h AS volume24h,
    transaction_count AS transactionCount,
    whale_transaction_count AS whaleTransactionCount,
    whale_volume_percent AS whaleVolumePercent,
    whale_ownership_percent AS whaleOwnershipPercent,
    avg_price AS averagePrice,
    price_change_24h AS priceChange24h,
    price_change_7d AS priceChange7d,
    whale_interest_score AS whaleInterestScore,
    market_cap AS marketCap
FROM dws.dws_nft_collection_stats;

-- 创建鲸鱼活动统计视图
CREATE VIEW IF NOT EXISTS api_whale_activity AS
SELECT
    dt AS date,
    hour,
    whale_address AS whaleAddress,
    nickname,
    action_type AS actionType,
    collection_name AS collectionName,
    transaction_count AS transactionCount,
    volume,
    profit_loss AS profitLoss,
    avg_hold_time AS averageHoldTime,
    total_value AS portfolioValue,
    whale_score AS whaleScore,
    price_trend_prediction AS priceTrendPrediction
FROM ads.ads_whale_tracking_dashboard
WHERE dt >= date_sub(current_date(), 7); -- 只保留最近7天的数据 