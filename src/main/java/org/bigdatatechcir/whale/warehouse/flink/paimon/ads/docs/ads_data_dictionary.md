# NFT Whale Tracker ADS层数据字典

## 概述

本文档详细描述了NFT Whale Tracker项目ADS层（Application Data Service，应用数据服务层）中各个表的字段定义、数据类型和业务含义，作为应用层开发和数据分析的参考标准。ADS层是数据仓库的最上层，主要基于DWS层和DIM层数据，提供直接面向业务分析和应用的数据产品。

## 表目录

1. [ads_top_profit_whales](#1-ads_top_profit_whales)
2. [ads_top_roi_whales](#2-ads_top_roi_whales)
3. [ads_whale_tracking_list](#3-ads_whale_tracking_list)
4. [ads_tracking_whale_collection_flow](#4-ads_tracking_whale_collection_flow)
5. [ads_smart_whale_collection_flow](#5-ads_smart_whale_collection_flow)
6. [ads_dumb_whale_collection_flow](#6-ads_dumb_whale_collection_flow)
7. [ads_whale_transactions](#7-ads_whale_transactions)

## 1. ads_top_profit_whales

**表说明**: 存储收益额排名靠前的鲸鱼钱包信息，用于分析鲸鱼的盈利能力。利润数据从dws_whale_daily_stats表聚合获取，不再从dim_whale_address表直接获取。

**主键**: snapshot_date, wallet_address

**主要数据来源**: dws_whale_daily_stats, dim_whale_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2023-04-20 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0x123... |
| rank_num | INT | 利润排名 | 1 |
| wallet_tag | VARCHAR(50) | 钱包标签 | Smart Whale |
| total_profit_eth | DECIMAL(30,10) | 总利润(ETH) | 150.5 |
| total_profit_usd | DECIMAL(30,10) | 总利润(USD) | 375125.00 |
| profit_7d_eth | DECIMAL(30,10) | 近7天利润(ETH) | 15.2 |
| profit_30d_eth | DECIMAL(30,10) | 近30天利润(ETH) | 45.7 |
| best_collection | VARCHAR(255) | 最佳收藏集(最盈利) | CryptoPunks |
| best_collection_profit_eth | DECIMAL(30,10) | 最佳收藏集利润(ETH) | 75.5 |
| total_tx_count | INT | 总交易次数 | 428 |
| first_track_date | DATE | 首次追踪日期 | 2023-01-15 |
| tracking_days | INT | 已追踪天数 | 95 |
| influence_score | DECIMAL(10,2) | 影响力评分 | 85.5 |
| data_source | VARCHAR(100) | 数据来源 | dws_whale_daily_stats,dim_whale_address |
| etl_time | TIMESTAMP | ETL处理时间 | 2023-04-20 03:15:00 |

## 2. ads_top_roi_whales

**表说明**: 存储投资回报率排名靠前的鲸鱼钱包信息，用于分析鲸鱼的投资效率

**主键**: snapshot_date, wallet_address

**主要数据来源**: dws_whale_daily_stats, dim_whale_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2023-04-20 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0x456... |
| rank_num | INT | ROI排名 | 1 |
| wallet_tag | VARCHAR(50) | 钱包标签 | Smart Whale |
| roi_percentage | DECIMAL(10,2) | 投资回报率(%) | 230.45 |
| total_buy_volume_eth | DECIMAL(30,10) | 总买入金额(ETH) | 85.4 |
| total_sell_volume_eth | DECIMAL(30,10) | 总卖出金额(ETH) | 282.5 |
| total_profit_eth | DECIMAL(30,10) | 总利润(ETH) | 197.1 |
| roi_7d_percentage | DECIMAL(10,2) | 近7天ROI(%) | 32.5 |
| roi_30d_percentage | DECIMAL(10,2) | 近30天ROI(%) | 125.4 |
| best_collection_roi | VARCHAR(255) | 最佳ROI收藏集 | Azuki |
| best_collection_roi_percentage | DECIMAL(10,2) | 最佳收藏集ROI(%) | 350.75 |
| avg_hold_days | INT | 平均持有天数 | 12 |
| first_track_date | DATE | 首次追踪日期 | 2023-02-10 |
| influence_score | DECIMAL(10,2) | 影响力评分 | 72.5 |
| data_source | VARCHAR(100) | 数据来源 | dws_whale_daily_stats,dim_whale_address |
| etl_time | TIMESTAMP | ETL处理时间 | 2023-04-20 03:20:00 |

## 3. ads_whale_tracking_list

**表说明**: 存储值得追踪的鲸鱼钱包信息，用于持续监控有影响力的鲸鱼。鲸鱼利润和影响力评分数据从dws_whale_daily_stats表获取，不再从dim_whale_address表直接获取。

**主键**: snapshot_date, wallet_address

**主要数据来源**: dim_whale_address, dws_whale_daily_stats

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2023-04-20 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0x789... |
| wallet_type | VARCHAR(50) | 鲸鱼类型 | SMART |
| tracking_id | VARCHAR(100) | 追踪ID | WHL_20230420_1 |
| first_track_date | DATE | 首次追踪日期 | 2023-01-05 |
| tracking_days | INT | 已追踪天数 | 105 |
| last_active_date | DATE | 最后活跃日期 | 2023-04-18 |
| status | VARCHAR(20) | 状态 | ACTIVE |
| total_profit_eth | DECIMAL(30,10) | 总利润(ETH) | 125.5 |
| total_profit_usd | DECIMAL(30,10) | 总利润(USD) | 313750.00 |
| roi_percentage | DECIMAL(10,2) | 投资回报率(%) | 175.25 |
| influence_score | DECIMAL(10,2) | 影响力评分 | 92.5 |
| total_tx_count | INT | 总交易次数 | 356 |
| success_rate | DECIMAL(10,2) | 成功率(%) | 82.5 |
| favorite_collections | VARCHAR(1000) | 偏好收藏集描述 | Top 5 collections |
| inactive_days | INT | 不活跃天数 | 2 |
| is_top30_volume | BOOLEAN | 是否交易量前30 | TRUE |
| is_top100_balance | BOOLEAN | 是否余额前100 | TRUE |
| rank_by_volume | INT | 交易量排名 | 15 |
| rank_by_profit | INT | 利润排名 | 8 |
| data_source | VARCHAR(100) | 数据来源 | dim_whale_address,dws_whale_daily_stats |
| etl_time | TIMESTAMP | ETL处理时间 | 2023-04-20 03:25:00 |

## 4. ads_tracking_whale_collection_flow

**表说明**: 存储鲸鱼资金净流入/流出排名靠前的收藏集信息，用于分析鲸鱼对收藏集的偏好变化

**主键**: snapshot_date, collection_address, flow_direction

**主要数据来源**: dws_collection_whale_flow, dim_collection_info

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2023-04-20 |
| collection_address | VARCHAR(255) | 收藏集地址 | 0xabc... |
| collection_name | VARCHAR(255) | 收藏集名称 | Bored Ape Yacht Club |
| flow_direction | VARCHAR(20) | 流向类型(INFLOW/OUTFLOW) | INFLOW |
| rank_num | INT | 排名 | 1 |
| net_flow_eth | DECIMAL(30,10) | 净流入/流出金额(ETH) | 25.5 |
| net_flow_usd | DECIMAL(30,10) | 净流入/流出金额(USD) | 63750.00 |
| net_flow_7d_eth | DECIMAL(30,10) | 7天累计净流入/流出(ETH) | 40.2 |
| net_flow_30d_eth | DECIMAL(30,10) | 30天累计净流入/流出(ETH) | 125.7 |
| floor_price_eth | DECIMAL(30,10) | 地板价(ETH) | 80.5 |
| floor_price_change_1d | DECIMAL(10,2) | 地板价1日变化率(%) | 2.5 |
| unique_whale_buyers | INT | 唯一鲸鱼买家数 | 8 |
| unique_whale_sellers | INT | 唯一鲸鱼卖家数 | 3 |
| whale_trading_percentage | DECIMAL(10,2) | 鲸鱼交易占比(%) | 75.4 |
| smart_whale_percentage | DECIMAL(10,2) | 聪明鲸鱼交易占比(%) | 60.5 |
| dumb_whale_percentage | DECIMAL(10,2) | 愚蠢鲸鱼交易占比(%) | 15.2 |
| trend_indicator | VARCHAR(50) | 趋势指标 | STRONG_INFLOW |
| data_source | VARCHAR(100) | 数据来源 | dws_collection_whale_flow,dim_whale_address |
| etl_time | TIMESTAMP | ETL处理时间 | 2023-04-20 03:30:00 |

## 5. ads_smart_whale_collection_flow

**表说明**: 存储聪明鲸鱼资金净流入/流出排名靠前的收藏集信息，用于发现有投资价值的收藏集

**主键**: snapshot_date, collection_address, flow_direction

**主要数据来源**: dws_collection_whale_flow, dim_whale_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2023-04-20 |
| collection_address | VARCHAR(255) | 收藏集地址 | 0xdef... |
| collection_name | VARCHAR(255) | 收藏集名称 | Azuki |
| flow_direction | VARCHAR(20) | 流向类型(INFLOW/OUTFLOW) | INFLOW |
| rank_num | INT | 排名 | 1 |
| smart_whale_net_flow_eth | DECIMAL(30,10) | 聪明鲸鱼净流入/流出(ETH) | 15.5 |
| smart_whale_net_flow_usd | DECIMAL(30,10) | 聪明鲸鱼净流入/流出(USD) | 38750.00 |
| smart_whale_net_flow_7d_eth | DECIMAL(30,10) | 7天累计净流入/流出(ETH) | 22.3 |
| smart_whale_net_flow_30d_eth | DECIMAL(30,10) | 30天累计净流入/流出(ETH) | 78.5 |
| smart_whale_buyers | INT | 聪明鲸鱼买家数 | 5 |
| smart_whale_sellers | INT | 聪明鲸鱼卖家数 | 2 |
| smart_whale_buy_volume_eth | DECIMAL(30,10) | 聪明鲸鱼买入金额(ETH) | 18.2 |
| smart_whale_sell_volume_eth | DECIMAL(30,10) | 聪明鲸鱼卖出金额(ETH) | 2.7 |
| smart_whale_trading_percentage | DECIMAL(10,2) | 聪明鲸鱼交易占比(%) | 65.2 |
| floor_price_eth | DECIMAL(30,10) | 地板价(ETH) | 12.5 |
| floor_price_change_1d | DECIMAL(10,2) | 地板价1日变化率(%) | 3.8 |
| trend_indicator | VARCHAR(50) | 趋势指标 | MODERATE_INFLOW |
| data_source | VARCHAR(100) | 数据来源 | dws_collection_whale_flow,dim_whale_address |
| etl_time | TIMESTAMP | ETL处理时间 | 2023-04-20 03:35:00 |

## 6. ads_dumb_whale_collection_flow

**表说明**: 存储愚蠢鲸鱼资金净流入/流出排名靠前的收藏集信息，用于识别潜在的风险收藏集

**主键**: snapshot_date, collection_address, flow_direction

**主要数据来源**: dws_collection_whale_flow, dim_whale_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2023-04-20 |
| collection_address | VARCHAR(255) | 收藏集地址 | 0xghi... |
| collection_name | VARCHAR(255) | 收藏集名称 | MoonBirds |
| flow_direction | VARCHAR(20) | 流向类型(INFLOW/OUTFLOW) | INFLOW |
| rank_num | INT | 排名 | 1 |
| dumb_whale_net_flow_eth | DECIMAL(30,10) | 愚蠢鲸鱼净流入/流出(ETH) | 8.5 |
| dumb_whale_net_flow_usd | DECIMAL(30,10) | 愚蠢鲸鱼净流入/流出(USD) | 21250.00 |
| dumb_whale_net_flow_7d_eth | DECIMAL(30,10) | 7天累计净流入/流出(ETH) | 12.3 |
| dumb_whale_net_flow_30d_eth | DECIMAL(30,10) | 30天累计净流入/流出(ETH) | 25.5 |
| dumb_whale_buyers | INT | 愚蠢鲸鱼买家数 | 3 |
| dumb_whale_sellers | INT | 愚蠢鲸鱼卖家数 | 1 |
| dumb_whale_buy_volume_eth | DECIMAL(30,10) | 愚蠢鲸鱼买入金额(ETH) | 10.2 |
| dumb_whale_sell_volume_eth | DECIMAL(30,10) | 愚蠢鲸鱼卖出金额(ETH) | 1.7 |
| dumb_whale_trading_percentage | DECIMAL(10,2) | 愚蠢鲸鱼交易占比(%) | 32.8 |
| floor_price_eth | DECIMAL(30,10) | 地板价(ETH) | 5.2 |
| floor_price_change_1d | DECIMAL(10,2) | 地板价1日变化率(%) | -2.5 |
| trend_indicator | VARCHAR(50) | 趋势指标 | SLIGHT_INFLOW |
| data_source | VARCHAR(100) | 数据来源 | dws_collection_whale_flow,dim_whale_address |
| etl_time | TIMESTAMP | ETL处理时间 | 2023-04-20 03:40:00 |

## 7. ads_whale_transactions

**表说明**: 存储鲸鱼相关的交易记录，用于详细分析鲸鱼的交易行为。鲸鱼影响力评分(influence_score)从dws_whale_daily_stats表获取，不再从dim_whale_address表直接获取。

**主键**: snapshot_date, tx_hash, contract_address, token_id

**主要数据来源**: dwd_whale_transaction_detail, dim_whale_address, dws_whale_daily_stats, dws_collection_daily_stats

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2023-04-20 |
| tx_hash | VARCHAR(255) | 交易哈希 | 0xtx123... |
| contract_address | VARCHAR(255) | NFT合约地址 | 0xcon123... |
| token_id | VARCHAR(255) | NFT代币ID | 1234 |
| tx_timestamp | TIMESTAMP | 交易发生时间戳 | 2023-04-19 14:25:10 |
| from_address | VARCHAR(255) | 卖方钱包地址 | 0xseller... |
| to_address | VARCHAR(255) | 买方钱包地址 | 0xbuyer... |
| from_whale_type | VARCHAR(50) | 卖方鲸鱼类型 | SMART |
| to_whale_type | VARCHAR(50) | 买方鲸鱼类型 | TRACKING |
| from_influence_score | DECIMAL(10,2) | 卖方影响力评分 | 85.2 |
| to_influence_score | DECIMAL(10,2) | 买方影响力评分 | 62.8 |
| collection_name | VARCHAR(255) | 收藏集名称 | CloneX |
| trade_price_eth | DECIMAL(30,10) | 交易价格(ETH) | 5.2 |
| trade_price_usd | DECIMAL(30,10) | 交易价格(USD) | 13000.00 |
| floor_price_eth | DECIMAL(30,10) | 交易时地板价(ETH) | 4.8 |
| price_to_floor_ratio | DECIMAL(10,2) | 价格/地板价比率 | 1.08 |
| marketplace | VARCHAR(100) | 交易平台 | OpenSea |
| data_source | VARCHAR(255) | 数据来源 | dwd_whale_transaction_detail,dim_whale_address,dws_whale_daily_stats,dws_collection_daily_stats |
| etl_time | TIMESTAMP | ETL处理时间 | 2023-04-20 03:45:00 |

## 数据类型说明

- **VARCHAR(n)**: 可变长度字符串，最大长度为n
- **DATE**: 日期类型，格式为YYYY-MM-DD
- **TIMESTAMP**: 时间戳类型，包含日期和时间
- **INT**: 整数类型
- **DECIMAL(p,s)**: 定点数，p是总位数，s是小数位数
- **BOOLEAN**: 布尔值，TRUE或FALSE

## 主键约束

所有表都有主键约束，但Paimon表的主键是非强制的（NOT ENFORCED），这意味着系统不会强制主键唯一性，但会用主键来优化存储和查询。

```sql
PRIMARY KEY (field1, field2) NOT ENFORCED
```

## 表参数说明

所有ADS层表都使用以下通用参数：

```sql
WITH (
    'bucket' = 'n',                      -- 分桶数
    'bucket-key' = 'field',              -- 分桶键，通常是集合地址或钱包地址
    'file.format' = 'parquet',           -- 文件格式
    'merge-engine' = 'deduplicate',      -- 合并引擎
    'changelog-producer' = 'input',      -- 变更日志生产模式
    'compaction.min.file-num' = 'n',     -- 最小文件数量进行压缩
    'compaction.max.file-num' = 'n',     -- 最大文件数量进行压缩
    'compaction.target-file-size' = 'nMB' -- 目标文件大小
)
```

## 数据流转关系

底层重构后，ADS层的数据流转遵循以下路径：

1. DWS层汇总数据 + DIM层维度数据 -> ADS层应用数据
2. DWD层明细数据（仅特定场景直接使用，如鲸鱼交易明细）

这种结构确保ADS层的数据既有足够的汇总性，也保留了必要的细节信息，以满足各种应用场景的需求。 