# NFT Whale Tracker DWS层数据字典

## 概述

本文档详细描述了NFT Whale Tracker项目DWS层（Data Warehouse Service，数据服务层）中各个表的字段定义、数据类型和业务含义，作为项目开发、数据分析和运维的参考文档。DWS层是在DWD层和DIM层的基础上进行多维度的汇总和分析，形成面向特定业务主题的聚合结果。

## 表目录

1. [dws_collection_daily_stats](#1-dws_collection_daily_stats)
2. [dws_wallet_daily_stats](#2-dws_wallet_daily_stats)
3. [dws_whale_daily_stats](#3-dws_whale_daily_stats)
4. [dws_collection_whale_flow](#4-dws_collection_whale_flow)
5. [dws_collection_whale_ownership](#5-dws_collection_whale_ownership)

## 1. dws_collection_daily_stats

**表说明**: 存储收藏集的每日交易统计数据（从DWD层迁移并增强）

**主键**: collection_date, contract_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| collection_date | DATE | 统计日期 | 2025-04-10 |
| contract_address | VARCHAR(255) | NFT合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| sales_count | INT | 当日销售数量 | 150 |
| volume_eth | DECIMAL(30,10) | 当日交易额(ETH) | 25.75 |
| volume_usd | DECIMAL(30,10) | 当日交易额(USD) | 64375.0 |
| avg_price_eth | DECIMAL(30,10) | 当日平均价格(ETH) | 0.172 |
| min_price_eth | DECIMAL(30,10) | 当日最低价格(ETH) | 0.1 |
| max_price_eth | DECIMAL(30,10) | 当日最高价格(ETH) | 0.5 |
| floor_price_eth | DECIMAL(30,10) | 当日地板价(ETH) | 0.15 |
| unique_buyers | INT | 唯一买家数量 | 75 |
| unique_sellers | INT | 唯一卖家数量 | 60 |
| whale_buyers | INT | 鲸鱼买家数量 | 12 |
| whale_sellers | INT | 鲸鱼卖家数量 | 8 |
| whale_volume_eth | DECIMAL(30,10) | 鲸鱼交易额(ETH) | 15.3 |
| whale_percentage | DECIMAL(10,2) | 鲸鱼交易额占比 | 59.4 |
| sales_change_1d | DECIMAL(10,2) | 销售数量1日环比 | 12.5 |
| volume_change_1d | DECIMAL(10,2) | 交易额1日环比 | 8.3 |
| price_change_1d | DECIMAL(10,2) | 均价1日环比 | -2.8 |
| is_in_working_set | BOOLEAN | 是否属于工作集 | TRUE |
| rank_by_volume | INT | 按交易额排名 | 5 |
| rank_by_sales | INT | 按销售量排名 | 7 |
| is_top30_volume | BOOLEAN | 是否交易额Top30 | TRUE |
| is_top30_sales | BOOLEAN | 是否销售量Top30 | FALSE |
| data_source | VARCHAR(100) | 数据来源 | dwd_transaction_clean,dwd_whale_transaction_detail |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 03:00:00 |

## 2. dws_wallet_daily_stats

**表说明**: 存储所有钱包的每日交易统计数据（从DWD层迁移并增强）

**主键**: wallet_date, wallet_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| wallet_date | DATE | 统计日期 | 2025-04-10 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0x29469395eaf6f95920e59f858042f0e28d98a20b |
| total_tx_count | INT | 交易总数 | 23 |
| buy_count | INT | 买入次数 | 15 |
| sell_count | INT | 卖出次数 | 8 |
| buy_volume_eth | DECIMAL(30,10) | 买入量(ETH) | 5.75 |
| sell_volume_eth | DECIMAL(30,10) | 卖出量(ETH) | 4.25 |
| profit_eth | DECIMAL(30,10) | 利润(ETH) | 1.5 |
| profit_usd | DECIMAL(30,10) | 利润(USD) | 3750.0 |
| roi_percentage | DECIMAL(10,2) | 投资回报率 | 26.1 |
| collections_traded | INT | 交易的收藏集数量 | 4 |
| is_active | BOOLEAN | 是否活跃 | TRUE |
| is_whale_candidate | BOOLEAN | 是否鲸鱼候选 | TRUE |
| is_top30_volume | BOOLEAN | 是否交易额Top30 | TRUE |
| is_top100_balance | BOOLEAN | 是否余额Top100 | FALSE |
| balance_eth | DECIMAL(30,10) | 持仓余额(ETH) | 125.5 |
| balance_usd | DECIMAL(30,10) | 持仓余额(USD) | 313750.0 |
| data_source | VARCHAR(100) | 数据来源 | dwd_transaction_clean |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 03:15:00 |

## 3. dws_whale_daily_stats

**表说明**: 存储鲸鱼钱包的每日交易汇总数据（优化字段和逻辑）

**主键**: stat_date, wallet_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| stat_date | DATE | 统计日期 | 2025-04-10 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0x29469395eaf6f95920e59f858042f0e28d98a20b |
| whale_type | VARCHAR(50) | 鲸鱼类型（追踪中/聪明/愚蠢） | SMART |
| wallet_status | VARCHAR(20) | 钱包状态 | ACTIVE |
| daily_trade_count | INT | 当日交易次数 | 23 |
| daily_buy_count | INT | 当日购买次数 | 15 |
| daily_sell_count | INT | 当日出售次数 | 8 |
| daily_buy_volume_eth | DECIMAL(30,10) | 当日购买金额(ETH) | 5.75 |
| daily_sell_volume_eth | DECIMAL(30,10) | 当日出售金额(ETH) | 4.25 |
| daily_profit_eth | DECIMAL(30,10) | 当日估算利润(ETH) | 1.5 |
| daily_roi_percentage | DECIMAL(10,2) | 当日投资回报率 | 35.3 |
| daily_collections_traded | INT | 当日交易收藏集数量 | 4 |
| accu_profit_eth | DECIMAL(30,10) | 累计利润(ETH) | 45.8 |
| accu_roi_percentage | DECIMAL(10,2) | 累计投资回报率 | 42.6 |
| holding_value_eth | DECIMAL(30,10) | 持仓价值(ETH) | 125.5 |
| holding_value_change_1d | DECIMAL(10,2) | 持仓价值1日变化百分比 | 3.7 |
| holding_collections | INT | 持有收藏集数量 | 15 |
| holding_nfts | INT | 持有NFT数量 | 47 |
| influence_score | DECIMAL(10,2) | 影响力评分(0-100) | 78.5 |
| success_rate_7d | DECIMAL(10,2) | 7天交易成功率 | 80.5 |
| success_rate_30d | DECIMAL(10,2) | 30天交易成功率 | 75.2 |
| avg_holding_days | DECIMAL(10,2) | 平均持有天数 | 12.5 |
| is_top30_volume | BOOLEAN | 是否交易额Top30钱包 | TRUE |
| is_top100_balance | BOOLEAN | 是否持有金额Top100钱包 | FALSE |
| rank_by_volume | INT | 按交易额排名 | 8 |
| rank_by_profit | INT | 按利润排名 | 15 |
| rank_by_roi | INT | 按ROI排名 | 6 |
| data_source | VARCHAR(100) | 数据来源 | dim_whale_address,dws_wallet_daily_stats |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 03:30:00 |

## 4. dws_collection_whale_flow

**表说明**: 存储收藏集的鲸鱼资金流向数据（优化字段和逻辑）

**主键**: stat_date, collection_address, whale_type

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| stat_date | DATE | 统计日期 | 2025-04-10 |
| collection_address | VARCHAR(255) | 收藏集地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| whale_type | VARCHAR(50) | 鲸鱼类型（追踪中/聪明/愚蠢） | SMART |
| whale_buy_count | INT | 鲸鱼购买交易数 | 15 |
| whale_sell_count | INT | 鲸鱼出售交易数 | 8 |
| whale_buy_volume_eth | DECIMAL(30,10) | 鲸鱼购买金额(ETH) | 5.75 |
| whale_sell_volume_eth | DECIMAL(30,10) | 鲸鱼出售金额(ETH) | 4.25 |
| net_flow_eth | DECIMAL(30,10) | 净流入量(ETH) | 1.5 |
| is_net_inflow | BOOLEAN | 是否净流入 | TRUE |
| unique_whale_buyers | INT | 唯一鲸鱼买家数 | 10 |
| unique_whale_sellers | INT | 唯一鲸鱼卖家数 | 5 |
| whale_trading_percentage | DECIMAL(10,2) | 鲸鱼交易占比 | 65.8 |
| whale_buy_avg_price_eth | DECIMAL(30,10) | 鲸鱼平均购买价格(ETH) | 0.38 |
| whale_sell_avg_price_eth | DECIMAL(30,10) | 鲸鱼平均出售价格(ETH) | 0.53 |
| avg_price_eth | DECIMAL(30,10) | 总体平均价格(ETH) | 0.42 |
| floor_price_eth | DECIMAL(30,10) | 当日地板价(ETH) | 0.35 |
| total_volume_eth | DECIMAL(30,10) | 当日总交易额(ETH) | 12.5 |
| whale_ownership_percentage | DECIMAL(10,2) | 鲸鱼持有比例 | 35.7 |
| accu_net_flow_7d | DECIMAL(30,10) | 7日累计净流入(ETH) | 10.8 |
| accu_net_flow_30d | DECIMAL(30,10) | 30日累计净流入(ETH) | 25.3 |
| rank_by_whale_volume | INT | 按鲸鱼交易额排名 | 4 |
| rank_by_net_flow | INT | 按净流入排名 | 2 |
| is_in_working_set | BOOLEAN | 是否在工作集中 | TRUE |
| data_source | VARCHAR(100) | 数据来源 | dim_whale_address,dwd_whale_transaction_detail,dws_collection_whale_ownership |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 03:45:00 |

## 5. dws_collection_whale_ownership

**表说明**: 存储收藏集的鲸鱼持有统计数据（新增，聚合DIM层统计功能）

**主键**: stat_date, collection_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| stat_date | DATE | 统计日期 | 2025-04-10 |
| collection_address | VARCHAR(255) | 收藏集地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| total_nfts | INT | NFT总数量 | 10000 |
| total_owners | INT | 持有者总数 | 5000 |
| whale_owners | INT | 鲸鱼持有者数 | 150 |
| whale_owned_nfts | INT | 鲸鱼持有的NFT数量 | 3500 |
| whale_ownership_percentage | DECIMAL(10,2) | 鲸鱼持有比例 | 35.0 |
| smart_whale_ownership_percentage | DECIMAL(10,2) | 聪明鲸鱼持有比例 | 20.5 |
| dumb_whale_ownership_percentage | DECIMAL(10,2) | 愚蠢鲸鱼持有比例 | 14.5 |
| total_value_eth | DECIMAL(30,10) | 持有总价值(ETH) | 1500.0 |
| whale_owned_value_eth | DECIMAL(30,10) | 鲸鱼持有价值(ETH) | 525.0 |
| ownership_change_1d | DECIMAL(10,2) | 持有比例1日变化 | 1.5 |
| ownership_change_7d | DECIMAL(10,2) | 持有比例7日变化 | 5.3 |
| rank_by_whale_ownership | INT | 按鲸鱼持有比例排名 | 3 |
| is_in_working_set | BOOLEAN | 是否属于工作集 | TRUE |
| data_source | VARCHAR(100) | 数据来源 | dwd_transaction_clean,dim_whale_address |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 03:40:00 |

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

所有DWS层表都使用以下通用参数：

```sql
WITH (
    'bucket' = 'n',                      -- 分桶数
    'bucket-key' = 'field',              -- 分桶键（可选）
    'file.format' = 'parquet',           -- 文件格式
    'merge-engine' = 'deduplicate',      -- 合并引擎
    'changelog-producer' = 'input/lookup', -- 变更日志生产模式
    'compaction.min.file-num' = 'n',     -- 最小文件数量进行压缩
    'compaction.max.file-num' = 'n',     -- 最大文件数量进行压缩
    'compaction.target-file-size' = 'nMB' -- 目标文件大小
)
```

## 字段命名规范

1. **时间维度**: 通常以表的主题命名，例如`collection_date`、`wallet_date`、`stat_date`
2. **实体标识符**: 通常使用`{entity}_address`格式，例如`wallet_address`、`collection_address`
3. **计数指标**: 使用`{entity}_count`或`{metric}_count`格式，例如`sales_count`、`buy_count`
4. **货币指标**: 使用`{metric}_{currency}`格式，例如`volume_eth`、`profit_usd`
5. **比例指标**: 使用`{metric}_percentage`或`{metric}_rate`格式，例如`roi_percentage`、`success_rate_7d`
6. **累计指标**: 使用`accu_{metric}`格式，例如`accu_profit_eth`、`accu_net_flow_7d`
7. **排名指标**: 使用`rank_by_{metric}`格式，例如`rank_by_volume`、`rank_by_profit`
8. **变化指标**: 使用`{metric}_change_{period}`格式，例如`price_change_1d`、`ownership_change_7d`

## 数据依赖关系

1. **dws_collection_daily_stats**: 依赖`dwd_transaction_clean`和`dwd_whale_transaction_detail`
2. **dws_wallet_daily_stats**: 依赖`dwd_transaction_clean`
3. **dws_whale_daily_stats**: 依赖`dws_wallet_daily_stats`和`dim_whale_address`
4. **dws_collection_whale_ownership**: 依赖`dwd_transaction_clean`和`dim_whale_address`
5. **dws_collection_whale_flow**: 依赖`dwd_whale_transaction_detail`、`dim_whale_address`和`dws_collection_whale_ownership`
