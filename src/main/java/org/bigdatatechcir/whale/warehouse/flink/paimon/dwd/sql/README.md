# DWD层SQL说明文档

## 概述

本目录包含NFT鲸鱼追踪器数据湖DWD层（Detail Warehouse Data，明细数据层）的SQL脚本文件。根据重构指南，DWD层专注于对ODS层数据进行清洗和规范化，不做聚合计算。

## SQL文件列表

### 1. dwd_transaction_clean.sql

**用途**：创建并填充交易清洗明细表，包含所有清洗后的交易数据（不限于鲸鱼交易）。

**主要功能**：
- 从ODS层的`ods_collection_transaction_inc`表获取原始交易数据
- 进行字段清洗和标准化处理
- 过滤无效数据
- 结果保存到`dwd_transaction_clean`表

**数据源**：
- `ods.ods_collection_transaction_inc`
- `ods.ods_collection_working_set`

### 2. dwd_whale_transaction_detail.sql

**用途**：创建并填充鲸鱼交易明细表，仅包含与鲸鱼相关的交易数据。

**主要功能**：
- 从`dwd_transaction_clean`表获取基础交易数据
- 关联ODS层的鲸鱼相关表，识别鲸鱼钱包
- 筛选至少有一方为鲸鱼的交易
- 结果保存到`dwd_whale_transaction_detail`表

**数据源**：
- `dwd.dwd_transaction_clean`
- `ods.ods_daily_top30_volume_wallets`
- `ods.ods_top100_balance_wallets`

### 3. 已迁移的SQL文件（不再使用）

以下SQL文件已根据重构指南迁移至DWS层，不再在DWD层使用：

- `dwd_collection_daily_stats.sql` - 迁移至`dws_collection_daily_stats.sql`
- `dwd_wallet_daily_stats.sql` - 迁移至`dws_wallet_daily_stats.sql`

## 执行顺序

为确保数据依赖关系正确，请按以下顺序执行SQL文件：

1. `dwd_transaction_clean.sql`
2. `dwd_whale_transaction_detail.sql`

您可以使用项目根目录下的`run_all_sql.sh`脚本自动按正确顺序执行这些SQL文件。

## 重要说明

1. **环境变量**：所有SQL文件开头都设置了必要的执行参数，如果需要修改这些参数，请在所有SQL文件中保持一致。

2. **表主键**：
   - `dwd_transaction_clean`表：主键为(tx_date, tx_id, contract_address)
   - `dwd_whale_transaction_detail`表：主键为(tx_date, tx_id, contract_address, token_id)

3. **分区与分桶**：为优化性能，所有表都按照交易日期（tx_date）和合约地址（contract_address）进行分区和分桶。

4. **数据清洗规则**：
   - 交易价格大于0的有效交易
   - 时间戳在有效范围内
   - 对于`dwd_whale_transaction_detail`表，至少有一方是鲸鱼 