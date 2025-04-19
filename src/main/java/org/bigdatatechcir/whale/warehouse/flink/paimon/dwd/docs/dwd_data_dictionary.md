# NFT Whale Tracker DWD层数据字典

## 概述

本文档详细描述了NFT Whale Tracker项目DWD层（Detail Warehouse Data，明细数据层）中各个表的字段定义、数据类型和业务含义，作为项目开发、数据分析和运维的参考文档。DWD层是在ODS层基础上，经过数据清洗和规范化处理后形成的明细数据层，专注于数据清洗和规范化，不进行聚合计算。

## 表目录

1. [dwd_transaction_clean](#1-dwd_transaction_clean)
2. [dwd_whale_transaction_detail](#2-dwd_whale_transaction_detail)

## 1. dwd_transaction_clean

**表说明**: 存储所有NFT交易的清洗后数据，不限于鲸鱼交易，是DWD层最基础的交易明细表

**主键**: tx_date, tx_id, contract_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| tx_date | DATE | 交易日期 | 2025-04-10 |
| tx_id | VARCHAR(255) | 交易ID，唯一标识一笔交易 | tx_12345 |
| tx_hash | VARCHAR(255) | 交易哈希，区块链上的唯一交易标识 | 0xabc123... |
| tx_timestamp | TIMESTAMP | 交易时间戳 | 2025-04-10 15:25:11 |
| from_address | VARCHAR(255) | 卖方钱包地址 | 0x123... |
| to_address | VARCHAR(255) | 买方钱包地址 | 0x456... |
| contract_address | VARCHAR(255) | NFT合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | VARCHAR(255) | 收藏集名称 | The Bears |
| token_id | VARCHAR(255) | NFT代币ID | 1234 |
| trade_price_eth | DECIMAL(30,10) | 交易价格（以ETH计算） | 0.5 |
| trade_price_usd | DECIMAL(30,10) | 交易价格（以USD计算） | 1250.00 |
| trade_symbol | VARCHAR(50) | 交易代币符号 | ETH |
| event_type | VARCHAR(50) | 事件类型 | Transfer |
| platform | VARCHAR(100) | 交易平台 | OpenSea |
| is_in_working_set | BOOLEAN | 是否属于工作集收藏集 | TRUE |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-10 16:30:00 |

## 2. dwd_whale_transaction_detail

**表说明**: 存储与潜在鲸鱼相关的NFT交易明细数据，由dwd_transaction_clean表筛选添加鲸鱼标识得到

**主键**: tx_date, tx_id, contract_address, token_id

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| tx_date | DATE | 交易日期 | 2025-04-10 |
| tx_id | VARCHAR(255) | 交易ID，唯一标识一笔交易 | tx_12345 |
| tx_hash | VARCHAR(255) | 交易哈希，区块链上的唯一交易标识 | 0xabc123... |
| tx_timestamp | TIMESTAMP | 交易时间戳 | 2025-04-10 15:25:11 |
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
| event_type | VARCHAR(50) | 事件类型 | Transfer |
| platform | VARCHAR(100) | 交易平台 | OpenSea |
| is_in_working_set | BOOLEAN | 是否属于工作集收藏集 | TRUE |
| etl_time | TIMESTAMP | ETL处理时间 | 2025-04-10 16:30:00 |

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

## 分桶键设计

在Paimon表中，必须确保主键包含所有分桶键。这是Paimon表的技术要求，否则会导致SQL执行错误。

- **dwd_transaction_clean**: 主键为(tx_date, tx_id, contract_address)，分桶键为contract_address
- **dwd_whale_transaction_detail**: 主键为(tx_date, tx_id, contract_address, token_id)，分桶键为contract_address

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

## 数据流转关系

DWD层的数据流转遵循以下路径：

1. ODS层原始数据 -> dwd_transaction_clean (基础清洗)
2. dwd_transaction_clean -> dwd_whale_transaction_detail (添加鲸鱼标识)

所有汇总统计功能都已迁移至DWS层，确保DWD层专注于数据清洗和规范化处理。 