# NFT Whale Tracker ADS层数据字典

## 概述

本文档详细描述了NFT Whale Tracker项目ADS层（Application Data Service，应用数据服务层）中各个表的字段定义、数据类型和业务含义，作为项目开发、数据分析和运维的参考文档。ADS层是数据仓库的顶层，主要面向业务应用和分析需求，提供各类主题的聚合分析结果。

## 表目录

1. [ads_top_profit_whales](#1-ads_top_profit_whales)
2. [ads_top_roi_whales](#2-ads_top_roi_whales)
3. [ads_whale_tracking_list](#3-ads_whale_tracking_list)
4. [ads_tracking_whale_collection_flow](#4-ads_tracking_whale_collection_flow)
5. [ads_smart_whale_collection_flow](#5-ads_smart_whale_collection_flow)
6. [ads_dumb_whale_collection_flow](#6-ads_dumb_whale_collection_flow)
7. [ads_whale_transactions](#7-ads_whale_transactions)

## 1. ads_top_profit_whales

**表说明**: 存储收益额Top10鲸鱼钱包

**主键**: snapshot_date, wallet_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2025-04-10 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0x29469395eaf6f95920e59f858042f0e28d98a20b |
| rank_num | INT | 排名 | 1 |
| wallet_tag | VARCHAR(255) | 钱包标签 | Smart Whale |
| total_profit_eth | DECIMAL(30,10) | 总收益额(ETH) | 158.75 |
| total_profit_usd | DECIMAL(30,10) | 总收益额(USD) | 396875.00 |
| profit_7d_eth | DECIMAL(30,10) | 7日收益额(ETH) | 15.25 |
| profit_30d_eth | DECIMAL(30,10) | 30日收益额(ETH) | 42.80 |
| best_collection | VARCHAR(255) | 最佳收藏集 | The Bears |
| best_collection_profit_eth | DECIMAL(30,10) | 最佳收藏集收益额(ETH) | 35.50 |
| total_tx_count | INT | 总交易次数 | 287 |
| first_track_date | DATE | 首次追踪日期 | 2025-01-15 |
| tracking_days | INT | 追踪天数 | 85 |
| influence_score | DECIMAL(10,2) | 影响力评分(0-100) | 85.5 |
| data_source | VARCHAR(100) | 数据来源 | dws_whale_daily_stats |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 05:00:00 |

## 2. ads_top_roi_whales

**表说明**: 存储收益率Top10鲸鱼钱包

**主键**: snapshot_date, wallet_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2025-04-10 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0xab14624691d0d1b62f9797368104ef1f8c20df83 |
| rank_num | INT | 排名 | 1 |
| wallet_tag | VARCHAR(255) | 钱包标签 | Smart Whale |
| roi_percentage | DECIMAL(10,2) | 投资回报率(%) | 75.8 |
| total_buy_volume_eth | DECIMAL(30,10) | 总购买额(ETH) | 258.30 |
| total_sell_volume_eth | DECIMAL(30,10) | 总出售额(ETH) | 454.10 |
| total_profit_eth | DECIMAL(30,10) | 总利润(ETH) | 195.80 |
| roi_7d_percentage | DECIMAL(10,2) | 7日ROI(%) | 12.5 |
| roi_30d_percentage | DECIMAL(10,2) | 30日ROI(%) | 28.3 |
| best_collection_roi | VARCHAR(255) | 最佳ROI收藏集 | Doodles |
| best_collection_roi_percentage | DECIMAL(10,2) | 最佳收藏集ROI(%) | 125.5 |
| avg_hold_days | DECIMAL(10,2) | 平均持有天数 | 15.3 |
| first_track_date | DATE | 首次追踪日期 | 2025-01-20 |
| influence_score | DECIMAL(10,2) | 影响力评分(0-100) | 78.5 |
| data_source | VARCHAR(100) | 数据来源 | dws_whale_daily_stats |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 05:10:00 |

## 3. ads_whale_tracking_list

**表说明**: 存储鲸鱼追踪名单，包括追踪中、聪明、愚蠢类型的鲸鱼

**主键**: snapshot_date, wallet_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2025-04-10 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0x29469395eaf6f95920e59f858042f0e28d98a20b |
| wallet_type | VARCHAR(50) | 鲸鱼类型 | SMART |
| tracking_id | VARCHAR(100) | 追踪ID | WHL_2025041001 |
| first_track_date | DATE | 首次追踪日期 | 2025-01-15 |
| tracking_days | INT | 追踪天数 | 85 |
| last_active_date | DATE | 最后活跃日期 | 2025-04-09 |
| status | VARCHAR(20) | 状态 | ACTIVE |
| total_profit_eth | DECIMAL(30,10) | 追踪以来总收益(ETH) | 158.75 |
| total_profit_usd | DECIMAL(30,10) | 追踪以来总收益(USD) | 396875.00 |
| roi_percentage | DECIMAL(10,2) | 投资回报率(%) | 75.8 |
| influence_score | DECIMAL(10,2) | 影响力评分(0-100) | 85.5 |
| total_tx_count | INT | 总交易次数 | 287 |
| success_rate | DECIMAL(10,2) | 成功交易比率(%) | 78.5 |
| favorite_collections | VARCHAR(1000) | 偏好收藏集(JSON) | ["0x123...", "0x456..."] |
| inactive_days | INT | 不活跃天数 | 1 |
| is_top30_volume | BOOLEAN | 是否当前交易额Top30 | TRUE |
| is_top100_balance | BOOLEAN | 是否当前持有额Top100 | TRUE |
| rank_by_volume | INT | 按交易额排名 | 5 |
| rank_by_profit | INT | 按利润排名 | 1 |
| data_source | VARCHAR(100) | 数据来源 | dws_whale_daily_stats,dim_whale_address |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 05:20:00 |

## 4. ads_tracking_whale_collection_flow

**表说明**: 存储工作集收藏集中追踪鲸鱼净流入/流出Top10

**主键**: snapshot_date, collection_address, flow_direction

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2025-04-10 |
| collection_address | VARCHAR(255) | 收藏集地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| flow_direction | VARCHAR(20) | 流向(INFLOW/OUTFLOW) | INFLOW |
| rank_num | INT | 排名 | 1 |
| net_flow_eth | DECIMAL(30,10) | 净流入/流出量(ETH) | 25.75 |
| net_flow_usd | DECIMAL(30,10) | 净流入/流出量(USD) | 64375.00 |
| net_flow_7d_eth | DECIMAL(30,10) | 7日累计净流入/流出(ETH) | 43.25 |
| net_flow_30d_eth | DECIMAL(30,10) | 30日累计净流入/流出(ETH) | 125.50 |
| floor_price_eth | DECIMAL(30,10) | 地板价(ETH) | 0.85 |
| floor_price_change_1d | DECIMAL(10,2) | 地板价1日变化(%) | 5.25 |
| unique_whale_buyers | INT | 唯一鲸鱼买家数 | 12 |
| unique_whale_sellers | INT | 唯一鲸鱼卖家数 | 5 |
| whale_trading_percentage | DECIMAL(10,2) | 鲸鱼交易占比(%) | 65.8 |
| smart_whale_percentage | DECIMAL(10,2) | 聪明鲸鱼占比(%) | 75.5 |
| dumb_whale_percentage | DECIMAL(10,2) | 愚蠢鲸鱼占比(%) | 15.3 |
| trend_indicator | VARCHAR(50) | 趋势指标 | STRONG_INFLOW |
| data_source | VARCHAR(100) | 数据来源 | dws_collection_whale_flow |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 05:30:00 |

## 5. ads_smart_whale_collection_flow

**表说明**: 存储工作集收藏集中聪明鲸鱼净流入/流出Top10

**主键**: snapshot_date, collection_address, flow_direction

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2025-04-10 |
| collection_address | VARCHAR(255) | 收藏集地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| flow_direction | VARCHAR(20) | 流向(INFLOW/OUTFLOW) | INFLOW |
| rank_num | INT | 排名 | 1 |
| smart_whale_net_flow_eth | DECIMAL(30,10) | 聪明鲸鱼净流入/流出(ETH) | 18.50 |
| smart_whale_net_flow_usd | DECIMAL(30,10) | 聪明鲸鱼净流入/流出(USD) | 46250.00 |
| smart_whale_net_flow_7d_eth | DECIMAL(30,10) | 7日累计净流入/流出(ETH) | 28.75 |
| smart_whale_net_flow_30d_eth | DECIMAL(30,10) | 30日累计净流入/流出(ETH) | 95.25 |
| smart_whale_buyers | INT | 聪明鲸鱼买家数 | 8 |
| smart_whale_sellers | INT | 聪明鲸鱼卖家数 | 3 |
| smart_whale_buy_volume_eth | DECIMAL(30,10) | 聪明鲸鱼买入量(ETH) | 22.50 |
| smart_whale_sell_volume_eth | DECIMAL(30,10) | 聪明鲸鱼卖出量(ETH) | 4.00 |
| smart_whale_trading_percentage | DECIMAL(10,2) | 聪明鲸鱼交易占比(%) | 45.8 |
| floor_price_eth | DECIMAL(30,10) | 地板价(ETH) | 0.85 |
| floor_price_change_1d | DECIMAL(10,2) | 地板价1日变化(%) | 5.25 |
| trend_indicator | VARCHAR(50) | 趋势指标 | STRONG_INFLOW |
| data_source | VARCHAR(100) | 数据来源 | dws_collection_whale_flow |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 05:40:00 |

## 6. ads_dumb_whale_collection_flow

**表说明**: 存储工作集收藏集中愚蠢鲸鱼净流入/流出Top10

**主键**: snapshot_date, collection_address, flow_direction

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2025-04-10 |
| collection_address | VARCHAR(255) | 收藏集地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| flow_direction | VARCHAR(20) | 流向(INFLOW/OUTFLOW) | OUTFLOW |
| rank_num | INT | 排名 | 1 |
| dumb_whale_net_flow_eth | DECIMAL(30,10) | 愚蠢鲸鱼净流入/流出(ETH) | -12.25 |
| dumb_whale_net_flow_usd | DECIMAL(30,10) | 愚蠢鲸鱼净流入/流出(USD) | -30625.00 |
| dumb_whale_net_flow_7d_eth | DECIMAL(30,10) | 7日累计净流入/流出(ETH) | -18.75 |
| dumb_whale_net_flow_30d_eth | DECIMAL(30,10) | 30日累计净流入/流出(ETH) | -45.50 |
| dumb_whale_buyers | INT | 愚蠢鲸鱼买家数 | 2 |
| dumb_whale_sellers | INT | 愚蠢鲸鱼卖家数 | 5 |
| dumb_whale_buy_volume_eth | DECIMAL(30,10) | 愚蠢鲸鱼买入量(ETH) | 3.25 |
| dumb_whale_sell_volume_eth | DECIMAL(30,10) | 愚蠢鲸鱼卖出量(ETH) | 15.50 |
| dumb_whale_trading_percentage | DECIMAL(10,2) | 愚蠢鲸鱼交易占比(%) | 25.5 |
| floor_price_eth | DECIMAL(30,10) | 地板价(ETH) | 0.85 |
| floor_price_change_1d | DECIMAL(10,2) | 地板价1日变化(%) | 5.25 |
| trend_indicator | VARCHAR(50) | 趋势指标 | MODERATE_OUTFLOW |
| data_source | VARCHAR(100) | 数据来源 | dws_collection_whale_flow |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 05:50:00 |

## 7. ads_whale_transactions

**表说明**: 存储鲸鱼相关的NFT交易详细数据，包含交易双方属性和收藏集状态

**主键**: snapshot_date, tx_hash, contract_address, token_id

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| snapshot_date | DATE | 快照日期 | 2025-04-10 |
| tx_hash | VARCHAR(255) | 交易哈希 | 0xabc123... |
| contract_address | VARCHAR(255) | NFT合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| token_id | VARCHAR(255) | NFT代币ID | 1234 |
| tx_timestamp | TIMESTAMP | 交易发生时间戳 | 2025-04-10 15:25:11 |
| from_address | VARCHAR(255) | 卖方钱包地址 | 0x123... |
| to_address | VARCHAR(255) | 买方钱包地址 | 0x456... |
| from_whale_type | VARCHAR(50) | 卖方鲸鱼类型(SMART/DUMB/TRACKING/NO_WHALE) | SMART |
| to_whale_type | VARCHAR(50) | 买方鲸鱼类型(SMART/DUMB/TRACKING/NO_WHALE) | NO_WHALE |
| from_influence_score | DECIMAL(10,2) | 卖方影响力评分 | 85.5 |
| to_influence_score | DECIMAL(10,2) | 买方影响力评分 | 0 |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| trade_price_eth | DECIMAL(30,10) | 交易价格(ETH) | 0.5 |
| trade_price_usd | DECIMAL(30,10) | 交易价格(USD) | 1250.00 |
| floor_price_eth | DECIMAL(30,10) | 交易时地板价(ETH) | 0.3 |
| price_to_floor_ratio | DECIMAL(10,2) | 价格/地板价比率 | 1.67 |
| marketplace | VARCHAR(100) | 交易平台 | OpenSea |
| data_source | VARCHAR(255) | 数据来源 | dwd_whale_transaction_detail,dim_whale_address |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-15 12:30:00 |

## 数据类型说明

- **VARCHAR(n)**: 可变长度字符串，最大长度为n
- **DATE**: 日期类型，格式为YYYY-MM-DD
- **TIMESTAMP**: 时间戳类型
- **INT**: 整数类型
- **DECIMAL(p,s)**: 定点数，p是总位数，s是小数位数
- **BOOLEAN**: 布尔值，true或false

## 主键约束

所有表都有主键约束，但Paimon表的主键是非强制的（NOT ENFORCED），这意味着系统不会强制主键唯一性，但会用主键来优化存储和查询。

```sql
PRIMARY KEY (field1, field2, ...) NOT ENFORCED
```

## 表参数说明

所有ADS层表都使用以下通用参数：

```sql
WITH (
    'bucket' = 'n',                      -- 分桶数
    'bucket-key' = 'field',              -- 分桶键（可选）
    'file.format' = 'parquet',           -- 文件格式
    'merge-engine' = 'deduplicate',      -- 合并引擎
    'changelog-producer' = 'input',      -- 变更日志生产模式
    'compaction.min.file-num' = 'n',     -- 最小文件数量进行压缩
    'compaction.max.file-num' = 'n',     -- 最大文件数量进行压缩
    'compaction.target-file-size' = 'nMB' -- 目标文件大小
)
``` 