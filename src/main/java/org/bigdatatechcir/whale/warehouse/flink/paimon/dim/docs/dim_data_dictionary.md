# NFT Whale Tracker DIM层数据字典

## 概述

本文档详细描述了NFT Whale Tracker项目DIM层（Dimension，维度层）中各个表的字段定义、数据类型和业务含义，作为项目开发、数据分析和运维的参考文档。DIM层是对各种业务对象的维度信息进行汇总和管理的层次，存储相对稳定的维度数据。

## 表目录

1. [dim_whale_address](#1-dim_whale_address)
2. [dim_collection_info](#2-dim_collection_info)

## 1. dim_whale_address

**表说明**: 存储鲸鱼钱包地址的维度信息

**主键**: wallet_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| wallet_address | VARCHAR(255) | 钱包地址 | 0x29469395eaf6f95920e59f858042f0e28d98a20b |
| first_track_date | DATE | 首次追踪日期 | 2025-03-15 |
| last_active_date | DATE | 最后活跃日期 | 2025-04-10 |
| is_whale | BOOLEAN | 是否为活跃鲸鱼 | TRUE |
| whale_type | VARCHAR(50) | 鲸鱼类型（追踪中/聪明/愚蠢） | SMART |
| whale_score | DECIMAL(10,2) | 鲸鱼影响力评分(0-100) | 85.75 |
| total_profit_eth | DECIMAL(30,10) | 追踪以来总收益(ETH) | 125.35 |
| total_profit_usd | DECIMAL(30,10) | 追踪以来总收益(USD) | 313375.00 |
| roi_percentage | DECIMAL(10,2) | 投资回报率 | 37.50 |
| total_buy_volume_eth | DECIMAL(30,10) | 总购买量(ETH) | 334.25 |
| total_sell_volume_eth | DECIMAL(30,10) | 总出售量(ETH) | 459.60 |
| total_tx_count | BIGINT | 总交易次数 | 857 |
| avg_hold_days | DECIMAL(10,2) | 平均持有天数 | 12.7 |
| favorite_collections | VARCHAR(1000) | 偏好收藏集(JSON格式) | ["0x123...", "0x456..."] |
| labels | VARCHAR(500) | 标签(JSON格式) | ["early_buyer", "high_volume"] |
| success_rate | DECIMAL(10,2) | 成功交易比率 | 78.4 |
| is_top30_volume_days | INT | 交易额Top30榜单天数 | 15 |
| is_top100_balance_days | INT | 持有额Top100榜单天数 | 30 |
| inactive_days | INT | 不活跃天数计数 | 0 |
| status | VARCHAR(20) | 状态 | ACTIVE |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 02:00:00 |

## 2. dim_collection_info

**表说明**: 存储NFT收藏集的维度信息

**主键**: collection_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| collection_address | VARCHAR(255) | 收藏集合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| symbol | VARCHAR(50) | 代币符号 | BRS |
| logo_url | VARCHAR(1000) | Logo URL | https://i.seadn.io/gcs/files/cc9dff22af78221f1eda1931618387bb.gif |
| banner_url | VARCHAR(1000) | Banner URL | https://i.seadn.io/gcs/files/a9d86572578d16967e7fedf... |
| first_tracked_date | DATE | 首次追踪日期 | 2023-12-01 |
| last_active_date | DATE | 最后活跃日期 | 2025-04-10 |
| items_total | INT | NFT总数量 | 10000 |
| owners_total | INT | 持有者总数 | 3782 |
| is_verified | BOOLEAN | 是否已验证 | TRUE |
| current_floor_price_eth | DECIMAL(30,10) | 当前地板价(ETH) | 0.25 |
| all_time_volume_eth | DECIMAL(30,10) | 历史总交易额(ETH) | 12500.75 |
| all_time_sales | INT | 历史总销售量 | 25478 |
| avg_price_7d | DECIMAL(30,10) | 7日平均价格 | 0.3 |
| avg_price_30d | DECIMAL(30,10) | 30日平均价格 | 0.28 |
| volume_7d | DECIMAL(30,10) | 7日交易额 | 125.5 |
| volume_30d | DECIMAL(30,10) | 30日交易额 | 475.3 |
| sales_7d | INT | 7日销售量 | 418 |
| sales_30d | INT | 30日销售量 | 1697 |
| whale_ownership_percentage | DECIMAL(10,2) | 鲸鱼持有比例 | 35.7 |
| whale_volume_percentage | DECIMAL(10,2) | 鲸鱼交易额比例 | 65.3 |
| smart_whale_interest_score | DECIMAL(10,2) | 聪明鲸鱼兴趣评分 | 78.4 |
| is_in_working_set | BOOLEAN | 是否在工作集 | TRUE |
| working_set_join_date | DATE | 加入工作集日期 | 2024-01-15 |
| working_set_days | INT | 在工作集天数 | 87 |
| inactive_days | INT | 不活跃天数计数 | 0 |
| status | VARCHAR(20) | 状态 | ACTIVE |
| category | VARCHAR(100) | 类别 | ART |
| total_whale_buys | INT | 鲸鱼总购买次数 | 375 |
| total_whale_sells | INT | 鲸鱼总出售次数 | 295 |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-11 02:30:00 |

## 数据类型说明

- **VARCHAR(n)**: 可变长度字符串，最大长度为n
- **DATE**: 日期类型，格式为YYYY-MM-DD
- **TIMESTAMP**: 时间戳类型
- **INT**: 整数类型
- **BIGINT**: 大整数类型
- **DECIMAL(p,s)**: 定点数，p是总位数，s是小数位数
- **BOOLEAN**: 布尔值，true或false

## 主键约束

所有表都有主键约束，但Paimon表的主键是非强制的（NOT ENFORCED），这意味着系统不会强制主键唯一性，但会用主键来优化存储和查询。

```sql
PRIMARY KEY (field) NOT ENFORCED
```

## 表参数说明

所有DIM层表都使用以下通用参数：

```sql
WITH (
    'bucket' = 'n',                      -- 分桶数
    'bucket-key' = 'field',              -- 分桶键（可选）
    'file.format' = 'parquet',           -- 文件格式
    'merge-engine' = 'deduplicate',      -- 合并引擎
    'changelog-producer' = 'lookup',     -- 变更日志生产模式
    'compaction.min.file-num' = 'n',     -- 最小文件数量进行压缩
    'compaction.max.file-num' = 'n',     -- 最大文件数量进行压缩
    'compaction.target-file-size' = 'nMB' -- 目标文件大小
)
``` 