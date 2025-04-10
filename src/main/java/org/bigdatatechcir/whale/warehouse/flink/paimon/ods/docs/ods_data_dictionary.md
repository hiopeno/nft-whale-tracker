# NFT Whale Tracker ODS层数据字典

## 概述

本文档详细描述了NFT Whale Tracker项目ODS层中各个表的字段定义、数据类型和业务含义，作为项目开发、数据分析和运维的参考文档。

## 表目录

1. [ods_daily_top30_transaction_collections](#1-ods_daily_top30_transaction_collections)
2. [ods_daily_top30_volume_collections](#2-ods_daily_top30_volume_collections)
3. [ods_daily_top30_volume_wallets](#3-ods_daily_top30_volume_wallets)
4. [ods_top100_balance_wallets](#4-ods_top100_balance_wallets)
5. [ods_collection_transaction_inc](#5-ods_collection_transaction_inc)
6. [ods_collection_working_set](#6-ods_collection_working_set)

## 1. ods_daily_top30_transaction_collections

**表说明**: 存储每日交易数量排名前30的NFT收藏集信息

**主键**: record_time, contract_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| record_time | TIMESTAMP | 记录时间，数据录入的时间戳 | 2025-04-10 15:25:11 |
| contract_address | VARCHAR(255) | NFT合约地址，区块链上的智能合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| contract_name | VARCHAR(255) | NFT合约名称 | The Bears |
| symbol | VARCHAR(255) | NFT代币符号 | BRS |
| logo_url | VARCHAR(1000) | NFT收藏集logo的URL | https://i.seadn.io/gcs/files/cc9dff22af78221f1eda1931618387bb.gif |
| banner_url | VARCHAR(1000) | NFT收藏集banner图片的URL | https://i.seadn.io/gcs/files/a9d86572578d16967e7fedf... |
| items_total | INT | NFT收藏集中的NFT总数量 | 10000 |
| owners_total | INT | 持有该NFT收藏集的唯一钱包数量 | 1170 |
| verified | BOOLEAN | 是否已验证（通常由NFT平台验证） | false |
| opensea_verified | BOOLEAN | 是否被OpenSea平台验证 | true |
| sales_1d | DECIMAL(30,10) | 过去24小时的销售数量 | 216 |
| sales_7d | DECIMAL(30,10) | 过去7天的销售数量 | 524 |
| sales_30d | DECIMAL(30,10) | 过去30天的销售数量 | 3327 |
| sales_total | DECIMAL(30,10) | 总销售数量 | 4405 |
| sales_change_1d | VARCHAR(50) | 24小时销售数量变化百分比 | 50% |
| sales_change_7d | VARCHAR(50) | 7天销售数量变化百分比 | -54.98% |
| sales_change_30d | VARCHAR(50) | 30天销售数量变化百分比 | 210.64% |
| volume_1d | DECIMAL(30,10) | 过去24小时的交易额（以ETH计算） | 0.0409 |
| volume_7d | DECIMAL(30,10) | 过去7天的交易额（以ETH计算） | 0.0557 |
| volume_30d | DECIMAL(30,10) | 过去30天的交易额（以ETH计算） | 0.507 |
| volume_total | DECIMAL(30,10) | 总交易额（以ETH计算） | 0.614 |
| floor_price | DECIMAL(30,10) | 最低挂单价格（以ETH计算） | 0.1 |
| average_price_1d | DECIMAL(30,10) | 过去24小时的平均交易价格 | 0.0002 |
| average_price_7d | DECIMAL(30,10) | 过去7天的平均交易价格 | 0.0001 |
| average_price_30d | DECIMAL(30,10) | 过去30天的平均交易价格 | 0 |
| average_price_total | DECIMAL(30,10) | 总体平均交易价格 | 0.0001 |
| average_price_change_1d | VARCHAR(50) | 24小时平均价格变化百分比 | 100% |
| average_price_change_7d | VARCHAR(50) | 7天平均价格变化百分比 | 0% |
| average_price_change_30d | VARCHAR(50) | 30天平均价格变化百分比 | 100% |
| volume_change_1d | VARCHAR(50) | 24小时交易额变化百分比 | 2,456.25% |
| volume_change_7d | VARCHAR(50) | 7天交易额变化百分比 | -19.04% |
| volume_change_30d | VARCHAR(50) | 30天交易额变化百分比 | 376.06% |
| market_cap | DECIMAL(30,10) | 市值（以ETH计算） | 1000 |

## 2. ods_daily_top30_volume_collections

**表说明**: 存储每日交易额排名前30的NFT收藏集信息

**主键**: record_time, contract_address

字段定义与`ods_daily_top30_transaction_collections`表相同，但数据内容为按交易额排序的前30个收藏集。

## 3. ods_daily_top30_volume_wallets

**表说明**: 存储每日交易额排名前30的钱包地址信息

**主键**: rank_date, account_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| rank_date | STRING | 排名日期，格式为YYYY-MM-DD | 2025-04-10 |
| account_address | STRING | 钱包地址，以太坊钱包地址 | 0x29469395eaf6f95920e59f858042f0e28d98a20b |
| rank_num | INT | 排名，从1开始递增 | 1 |
| trade_volume | DOUBLE | 交易量（以ETH计算） | 1248183.18 |
| trade_volume_usdc | DOUBLE | 交易量（以USDC计算） | 3000000 |
| trade_count | BIGINT | 交易次数 | 705582 |
| is_whale | BOOLEAN | 是否为巨鲸钱包（通常持有大量资产） | TRUE |
| created_at | TIMESTAMP(3) | 记录创建时间 | 2025-04-10 15:07:27.000 |

## 4. ods_top100_balance_wallets

**表说明**: 存储持有NFT资产价值排名前100的钱包地址信息

**主键**: rank_date, account_address

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| rank_date | STRING | 排名日期，格式为YYYY-MM-DD | 2025-04-10 |
| account_address | STRING | 钱包地址，以太坊钱包地址 | 0xab14624691d0d1b62f9797368104ef1f8c20df83 |
| rank_num | INT | 排名，从1开始递增 | 1 |
| holding_volume | DOUBLE | 持有资产价值（以ETH计算） | 64785.003 |
| buy_volume | DOUBLE | 购买总量（以ETH计算） | 0 |
| sell_volume | DOUBLE | 出售总量（以ETH计算） | 0 |
| realized_gains_volume | DOUBLE | 已实现收益（以ETH计算） | 0 |
| holding_collections | BIGINT | 持有的收藏集数量 | 3 |
| holding_nfts | BIGINT | 持有的NFT总数量 | 4815 |
| trade_count | BIGINT | 交易次数 | 7459 |

## 5. ods_collection_transaction_inc

**表说明**: 存储NFT收藏集的详细交易记录

**主键**: record_time, hash, contract_address, token_id

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| record_time | TIMESTAMP | 记录时间，数据录入的时间戳 | 2025-04-10 15:25:11 |
| hash | VARCHAR(255) | 交易哈希，区块链上的唯一交易标识 | 0xabc123... |
| from_address | VARCHAR(255) | 发送方地址 | 0x123... |
| to_address | VARCHAR(255) | 接收方地址 | 0x456... |
| block_number | VARCHAR(50) | 区块号 | 17234567 |
| block_hash | VARCHAR(255) | 区块哈希 | 0xdef456... |
| gas_price | VARCHAR(255) | Gas价格 | 0x5b8d7f5800 |
| gas_used | VARCHAR(255) | 使用的Gas量 | 0x5208 |
| gas_fee | DECIMAL(30,10) | Gas费用（以ETH计算） | 0.0008 |
| tx_timestamp | DECIMAL(30,10) | 交易时间戳，UNIX时间戳 | 1712745600 |
| contract_address | VARCHAR(255) | NFT合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| contract_name | VARCHAR(255) | NFT合约名称 | The Bears |
| contract_token_id | VARCHAR(255) | 合约中的代币ID | 1 |
| token_id | VARCHAR(255) | 代币ID，可能是合约代币ID的变体 | 1 |
| erc_type | VARCHAR(50) | ERC标准类型 | erc721 |
| send | VARCHAR(255) | 发送数量 | 1 |
| receive | VARCHAR(255) | 接收数量 | 1 |
| amount | VARCHAR(255) | 交易金额 | 1 |
| trade_value | VARCHAR(255) | 交易价值（以交易代币计算） | 0.1 |
| trade_price | DECIMAL(30,10) | 交易价格（以ETH计算） | 0.1 |
| trade_symbol | VARCHAR(255) | 交易代币符号 | ETH |
| trade_symbol_address | VARCHAR(255) | 交易代币合约地址 | 0x0000000000000000000000000000000000000000 |
| event_type | VARCHAR(50) | 事件类型 | Transfer |
| exchange_name | VARCHAR(255) | 交易所名称 | OpenSea |
| aggregate_exchange_name | VARCHAR(255) | 聚合交易所名称 | OpenSea |
| nftscan_tx_id | VARCHAR(255) | NFTScan交易ID | tx_123456 |

## 6. ods_collection_working_set

**表说明**: 存储活跃NFT收藏集的工作集数据

**主键**: collection_id

| 字段名 | 数据类型 | 说明 | 示例值 |
|-------|---------|------|-------|
| collection_id | STRING | 收藏集ID，系统内部唯一标识 | col_12345 |
| collection_address | STRING | 收藏集合约地址 | 0x495f947276749ce646f68ac8c248420045cb7b5e |
| collection_name | STRING | 收藏集名称 | The Bears |
| logo_url | STRING | 收藏集Logo URL | https://i.seadn.io/gcs/files/cc9dff22af78221f1eda1931618387bb.gif |
| first_added_date | STRING | 首次添加日期，格式为YYYY-MM-DD | 2023-01-15 |
| last_updated_date | STRING | 最后更新日期，格式为YYYY-MM-DD | 2025-04-10 |
| last_active_date | STRING | 最后活跃日期，格式为YYYY-MM-DD | 2025-04-10 |
| source | STRING | 数据来源 | api |
| status | STRING | 收藏集状态 | active |
| floor_price | DECIMAL(30,10) | 地板价（以ETH计算） | 0.1 |
| volume_1d | DECIMAL(30,10) | 24小时交易额 | 0.0409 |
| volume_7d | DECIMAL(30,10) | 7天交易额 | 0.0557 |
| sales_1d | BIGINT | 24小时销售量 | 216 |
| sales_7d | BIGINT | 7天销售量 | 524 |
| update_count | INT | 更新计数，记录更新次数 | 10 |

## 数据类型说明

- **STRING**: 字符串类型
- **VARCHAR(n)**: 可变长度字符串，最大长度为n
- **INT**: 整数类型
- **BIGINT**: 大整数类型
- **DOUBLE**: 双精度浮点数
- **DECIMAL(p,s)**: 定点数，p是总位数，s是小数位数
- **BOOLEAN**: 布尔值，true或false
- **TIMESTAMP**: 时间戳
- **TIMESTAMP(3)**: 带3位毫秒精度的时间戳

## 主键约束

所有表都有主键约束，但Paimon表的主键是非强制的（NOT ENFORCED），这意味着系统不会强制主键唯一性，但会用主键来优化存储和查询。

```sql
PRIMARY KEY (field1, field2) NOT ENFORCED
```

## 表参数说明

所有ODS层表都使用以下通用参数：

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

### 参数含义：

- **bucket**: 表数据分桶数量，影响并行度
- **bucket-key**: 分桶的字段，通常用于主键的一部分
- **file.format**: 存储文件格式，默认使用parquet
- **merge-engine**: 合并策略，deduplicate表示通过主键去重
- **changelog-producer**: 变更日志生产方式
- **compaction.min.file-num**: 触发压缩的最小文件数
- **compaction.max.file-num**: 压缩考虑的最大文件数
- **compaction.target-file-size**: 压缩后的目标文件大小 