# NFT Whale Tracker DWS层数据字典

## 概述

本文档详细描述了NFT Whale Tracker项目DWS层（Data Warehouse Service，数据服务层）中各个表的字段定义、数据类型和业务含义，作为项目开发、数据分析和运维的参考文档。DWS层是在DWD层和DIM层的基础上进行多维度的汇总和分析，形成面向特定业务主题的聚合结果。

## 表目录

1. [dws_whale_daily_stats](#1-dws_whale_daily_stats)
2. [dws_collection_whale_flow](#2-dws_collection_whale_flow)

## 1. dws_whale_daily_stats

**表说明**: 存储鲸鱼钱包的每日交易汇总数据

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
| data_source | VARCHAR(100) | 数据来源 | dim_whale_address,dwd_wallet_daily_stats |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 03:00:00 |

## 2. dws_collection_whale_flow

**表说明**: 存储收藏集的鲸鱼资金流向数据

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
| data_source | VARCHAR(100) | 数据来源 | dim_collection_info,dwd_whale_transaction_detail |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 03:30:00 |

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
    'changelog-producer' = 'input',      -- 变更日志生产模式
    'compaction.min.file-num' = 'n',     -- 最小文件数量进行压缩
    'compaction.max.file-num' = 'n',     -- 最大文件数量进行压缩
    'compaction.target-file-size' = 'nMB' -- 目标文件大小
)
``` 