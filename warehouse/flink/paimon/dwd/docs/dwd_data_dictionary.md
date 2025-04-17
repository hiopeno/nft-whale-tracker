# NFT Whale Tracker DWD层数据字典

## 概述

本文档详细描述了NFT Whale Tracker项目DWD层（Detail Warehouse Data，明细数据层）中各个表的字段定义、数据类型和业务含义，作为项目开发、数据分析和运维的参考文档。DWD层是在ODS层基础上，经过数据清洗和规范化处理后形成的明细数据层。

## 表目录

1. [dwd_whale_transaction_detail](#1-dwd_whale_transaction_detail)
2. [dwd_collection_daily_stats](#2-dwd_collection_daily_stats)
3. [dwd_wallet_daily_stats](#3-dwd_wallet_daily_stats)

## 1. dwd_whale_transaction_detail

**表说明**: 存储与潜在鲸鱼相关的NFT交易明细数据，经过清洗和规范化处理

**主键**: tx_date, tx_id, contract_address, token_id

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| tx_date | DATE | 交易日期 | 2025-04-10 |
| tx_id | VARCHAR(255) | 交易ID，唯一标识一笔交易 | tx_12345 |
| tx_hash | VARCHAR(255) | 交易哈希，区块链上的唯一交易标识 | 0xabc123... |
| tx_timestamp | TIMESTAMP | 交易时间戳 | 2025-04-10 15:25:11 |
| tx_week | VARCHAR(20) | 交易所在周，格式为YYYY-WW | 2025-15 |
| tx_month | VARCHAR(10) | 交易所在月，格式为YYYY-MM | 2025-04 |
| from_address | VARCHAR(255) | 卖方钱包地址 | 0x123... |
| to_address | VARCHAR(255) | 买方钱包地址 | 0x456... |
| from_is_whale | BOOLEAN | 卖方是否为鲸鱼钱包 | TRUE |
| to_is_whale | BOOLEAN | 买方是否为鲸鱼钱包 | FALSE |
| contract_address | VARCHAR(255) | NFT合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| token_id | VARCHAR(255) | NFT代币ID | 1234 |
| trade_price_eth | DECIMAL(30,10) | 交易价格（以ETH计算） | 0.5 |
| trade_price_usd | DECIMAL(30,10) | 交易价格（以USD计算） | 1250.00 |
| trade_symbol | VARCHAR(50) | 交易代币符号 | ETH |
| floor_price_eth | DECIMAL(30,10) | 交易时收藏集地板价（以ETH计算） | 0.3 |
| profit_potential | DECIMAL(30,10) | 潜在利润（trade_price与floor_price的差值） | 0.2 |
| event_type | VARCHAR(50) | 事件类型 | Transfer |
| platform | VARCHAR(100) | 交易平台 | OpenSea |
| is_in_working_set | BOOLEAN | 是否属于工作集收藏集 | TRUE |
| data_source | VARCHAR(50) | 数据来源 | ods_collection_transaction_inc |
| is_deleted | BOOLEAN | 是否被删除（用于逻辑删除） | FALSE |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-10 16:30:00 |

## 2. dwd_collection_daily_stats

**表说明**: 存储NFT收藏集的每日统计数据

**主键**: collection_date, contract_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| collection_date | DATE | 统计日期 | 2025-04-10 |
| contract_address | VARCHAR(255) | NFT合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| sales_count | INT | 当日销售数量 | 150 |
| volume_eth | DECIMAL(30,10) | 当日交易额（以ETH计算） | 45.75 |
| volume_usd | DECIMAL(30,10) | 当日交易额（以USD计算） | 114375.00 |
| avg_price_eth | DECIMAL(30,10) | 当日平均价格（以ETH计算） | 0.305 |
| min_price_eth | DECIMAL(30,10) | 当日最低价格（以ETH计算） | 0.25 |
| max_price_eth | DECIMAL(30,10) | 当日最高价格（以ETH计算） | 0.45 |
| floor_price_eth | DECIMAL(30,10) | 当日收盘地板价（以ETH计算） | 0.28 |
| unique_buyers | INT | 唯一买家数量 | 87 |
| unique_sellers | INT | 唯一卖家数量 | 92 |
| whale_buyers | INT | 鲸鱼买家数量 | 12 |
| whale_sellers | INT | 鲸鱼卖家数量 | 15 |
| whale_volume_eth | DECIMAL(30,10) | 鲸鱼交易额（以ETH计算） | 30.5 |
| whale_percentage | DECIMAL(10,2) | 鲸鱼交易额占比 | 66.67 |
| sales_change_1d | DECIMAL(10,2) | 销售数量1日环比变化率 | 10.5 |
| volume_change_1d | DECIMAL(10,2) | 交易额1日环比变化率 | 12.7 |
| price_change_1d | DECIMAL(10,2) | 均价1日环比变化率 | 2.0 |
| is_in_working_set | BOOLEAN | 是否属于工作集 | TRUE |
| rank_by_volume | INT | 按交易额排名 | 5 |
| rank_by_sales | INT | 按销售量排名 | 8 |
| is_top30_volume | BOOLEAN | 是否交易额Top30 | TRUE |
| is_top30_sales | BOOLEAN | 是否销售量Top30 | TRUE |
| data_source | VARCHAR(100) | 数据来源 | ods_collection_transaction_inc,ods_daily_top30_volume_collections |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 01:00:00 |

## 3. dwd_wallet_daily_stats

**表说明**: 存储钱包地址的每日交易统计数据

**主键**: wallet_date, wallet_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| wallet_date | DATE | 统计日期 | 2025-04-10 |
| wallet_address | VARCHAR(255) | 钱包地址 | 0x29469395eaf6f95920e59f858042f0e28d98a20b |
| buy_count | INT | 购买交易数量 | 23 |
| sell_count | INT | 出售交易数量 | 17 |
| total_tx_count | INT | 总交易数量 | 40 |
| buy_volume_eth | DECIMAL(30,10) | 购买总额（以ETH计算） | 15.3 |
| sell_volume_eth | DECIMAL(30,10) | 出售总额（以ETH计算） | 10.7 |
| net_flow_eth | DECIMAL(30,10) | 净流入（以ETH计算） | 4.6 |
| buy_volume_usd | DECIMAL(30,10) | 购买总额（以USD计算） | 38250.00 |
| sell_volume_usd | DECIMAL(30,10) | 出售总额（以USD计算） | 26750.00 |
| net_flow_usd | DECIMAL(30,10) | 净流入（以USD计算） | 11500.00 |
| profit_eth | DECIMAL(30,10) | 当日估算利润（以ETH计算） | 3.5 |
| profit_usd | DECIMAL(30,10) | 当日估算利润（以USD计算） | 8750.00 |
| collections_traded | INT | 交易的收藏集数量 | 7 |
| working_set_collections_traded | INT | 交易的工作集收藏集数量 | 5 |
| is_top30_volume | BOOLEAN | 是否交易额Top30钱包 | TRUE |
| is_top100_balance | BOOLEAN | 是否持有金额Top100钱包 | FALSE |
| rank_by_volume | INT | 按交易额排名 | 12 |
| rank_by_balance | INT | 按持有金额排名 | 0 |
| is_whale_candidate | BOOLEAN | 是否为潜在鲸鱼 | TRUE |
| data_source | VARCHAR(100) | 数据来源 | ods_collection_transaction_inc,ods_daily_top30_volume_wallets |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 01:30:00 |

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
PRIMARY KEY (field1, field2) NOT ENFORCED
```

## 表参数说明

所有DWD层表都使用以下通用参数：

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