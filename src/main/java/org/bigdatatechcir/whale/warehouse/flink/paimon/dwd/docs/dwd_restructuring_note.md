# DWD层重构说明文档

## 重构概述

根据《NFT鲸鱼追踪器数据湖重构指南》的要求，我们对DWD层（Detail Warehouse Data，明细数据层）进行了重构，以解决层级职责混乱、字段利用率低等问题。本次重构主要目标是使DWD层回归其本职工作：对ODS层数据进行清洗和规范化，构建业务明细数据，而不做聚合计算。

## 重构内容

### 1. 表结构调整

**保留表**：
- `dwd_whale_transaction_detail` - 鲸鱼交易明细表（已优化）

**新增表**：
- `dwd_transaction_clean` - 清洗后的所有交易明细表，不限于鲸鱼

**移除表**（迁移至DWS层）：
- `dwd_collection_daily_stats` -> `dws_collection_daily_stats`
- `dwd_wallet_daily_stats` -> `dws_wallet_daily_stats`

### 2. 字段优化

#### `dwd_transaction_clean`表

该表是新增的基础交易清洗表，包含以下字段：
- 交易基本信息：tx_date, tx_id, tx_hash, tx_timestamp
- 地址信息：from_address, to_address
- 合约信息：contract_address, collection_name, token_id
- 交易信息：trade_price_eth, trade_price_usd, trade_symbol, event_type, platform
- 其他标记：is_in_working_set
- 管理字段：etl_time

**主键设计**：
- 主键为(tx_date, tx_id, contract_address)
- 分桶键为contract_address
- 确保主键包含分桶键，以满足Paimon表的技术要求

#### `dwd_whale_transaction_detail`表

对该表进行了精简，移除了计算字段和部分管理字段：
- 移除的计算字段：
  - profit_potential（潜在利润）
  - floor_price_eth（地板价）
  - tx_week, tx_month（时间维度划分）
- 移除的管理字段：
  - data_source（数据来源）
  - is_deleted（逻辑删除标记）

此表现在仅保留基础字段和鲸鱼标识，更符合DWD层的定位。

### 3. 数据流转优化

- 建立了`dwd_transaction_clean` -> `dwd_whale_transaction_detail`的处理链路
- `dwd_whale_transaction_detail`表从`dwd_transaction_clean`获取数据，并添加鲸鱼标识
- 保证数据处理的一致性和逻辑清晰度

## 执行脚本调整

更新了`run_all_sql.sh`脚本，调整了SQL执行顺序：
1. 首先执行`dwd_transaction_clean.sql`创建并填充基础交易清洗表
2. 然后执行`dwd_whale_transaction_detail.sql`创建并填充鲸鱼交易明细表
3. 不再执行原汇总统计相关SQL文件

## 后续建议

1. **创建DWS层汇总表**：
   - 根据重构指南，将原DWD层的汇总功能迁移至DWS层
   - 创建`dws_collection_daily_stats`和`dws_wallet_daily_stats`表

2. **数据回填与验证**：
   - 对新表结构进行历史数据回填
   - 进行数据一致性验证，确保重构前后结果一致

3. **应用程序适配**：
   - 更新应用程序查询，适配新的表结构
   - 确保应用程序从正确的层级获取数据

## 重构效果

本次重构使DWD层回归到其标准定义，具有以下优势：
1. **层级职责明确**：DWD层专注于数据清洗和明细数据构建
2. **数据流转清晰**：建立了从ODS到DWD的清晰数据流转路径
3. **消除冗余计算**：移除了DWD层不必要的聚合计算
4. **提高系统效率**：减少了重复计算，提高了系统整体效率

## 实施过程中的关键问题与解决方案

### 1. 主键与分桶键问题

在实施`dwd_transaction_clean`表时，发现Paimon要求主键必须包含所有分桶键。最初的设计中，主键为`(tx_date, tx_id)`而分桶键为`contract_address`，导致SQL执行报错。

**解决方案**：
- 修改主键定义为`(tx_date, tx_id, contract_address)`，确保包含分桶键
- 更新相关文档，说明主键设计的技术要求

### 2. 字段类型不匹配问题

在`dwd_whale_transaction_detail`表关联时，发现DATE和VARCHAR类型的日期字段无法自动转换，导致JOIN条件失败。

**解决方案**：
- 使用显式类型转换：`CAST(t.tx_date AS VARCHAR) = vw.rank_date`
- 确保所有关联条件使用兼容的数据类型

---

版本：1.0
日期：2023-04-XX
作者：数据工程团队 