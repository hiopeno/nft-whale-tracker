# NFT Whale Tracker DWD层数据流转文档

## 1. 概述

本文档详细描述了NFT Whale Tracker项目中DWD层（Detail Warehouse Data，明细数据层）的数据流转过程。DWD层是在ODS层基础上进行数据清洗、转换和规范化处理后形成的明细数据层，为后续的维度构建、数据汇总和应用层分析提供基础。根据数据湖重构指南，DWD层不再进行聚合计算，专注于其核心职责：数据清洗和规范化处理。

## 2. 数据流转架构

整个DWD层的数据流转过程经过重构后，遵循以下清晰路径：

```
ODS层数据 -> dwd_transaction_clean(基础清洗) -> dwd_whale_transaction_detail(鲸鱼识别)
```

这种处理链路确保了DWD层专注于数据清洗和明细数据构建，而将聚合统计功能移至DWS层。

## 3. 数据处理流程

### 3.1 dwd_transaction_clean 处理流程

该表是DWD层的基础交易清洗表，存储所有清洗后的NFT交易数据，不限于鲸鱼交易。

处理流程：
1. 从`ods_collection_transaction_inc`表提取交易数据
2. 清洗和规范化时间戳（处理毫秒级时间戳、异常时间戳等）
3. 关联`ods_collection_working_set`表标识工作集收藏集
4. 规范化价格（ETH和USD）、符号和事件类型
5. 过滤无效交易（价格为0、异常时间戳等）

SQL处理逻辑示例：
```sql
INSERT INTO dwd_transaction_clean
SELECT
    TO_DATE(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT))) AS tx_date,
    t.nftscan_tx_id AS tx_id,
    t.hash AS tx_hash,
    CAST(FROM_UNIXTIME(CAST(t.tx_timestamp/1000 AS BIGINT)) AS TIMESTAMP(6)) AS tx_timestamp,
    t.from_address,
    t.to_address,
    t.contract_address,
    t.contract_name AS collection_name,
    t.token_id,
    CAST(t.trade_price AS DECIMAL(30,10)) AS trade_price_eth,
    CAST(t.trade_price * 2500.00 AS DECIMAL(30,10)) AS trade_price_usd, -- 使用固定汇率做示例，实际应从外部获取
    CAST(t.trade_symbol AS VARCHAR(50)) AS trade_symbol,
    CAST(t.event_type AS VARCHAR(50)) AS event_type,
    CAST(t.exchange_name AS VARCHAR(100)) AS platform,
    CASE WHEN cws.collection_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_in_working_set,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP(6)) AS etl_time
FROM 
    ods.ods_collection_transaction_inc t
LEFT JOIN 
    ods.ods_collection_working_set cws ON t.contract_address = cws.collection_address
WHERE 
    t.trade_price > 0 -- 过滤无效交易
    AND t.tx_timestamp > 0 -- 确保时间戳为正数
    AND t.tx_timestamp < 253402271999000 -- 排除过大的时间戳（2023年之后的8000年左右）
```

### 3.2 dwd_whale_transaction_detail 处理流程

该表存储与潜在鲸鱼相关的NFT交易明细数据，主要来源于`dwd_transaction_clean`表，并添加鲸鱼标识。

处理流程：
1. 从`dwd_transaction_clean`表获取基础交易数据
2. 关联`ods_daily_top30_volume_wallets`和`ods_top100_balance_wallets`表识别鲸鱼地址
3. 添加卖方和买方的鲸鱼标识
4. 保留至少有一方是鲸鱼的交易记录

SQL处理逻辑示例：
```sql
INSERT INTO dwd_whale_transaction_detail
SELECT
    t.tx_date,
    t.tx_id,
    t.tx_hash,
    t.tx_timestamp,
    t.from_address,
    t.to_address,
    CASE WHEN vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS from_is_whale,
    CASE WHEN vw2.account_address IS NOT NULL OR bw2.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS to_is_whale,
    t.contract_address,
    t.collection_name,
    t.token_id,
    t.trade_price_eth,
    t.trade_price_usd,
    t.trade_symbol,
    t.event_type,
    t.platform,
    t.is_in_working_set,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dwd_transaction_clean t
LEFT JOIN 
    ods.ods_daily_top30_volume_wallets vw ON t.from_address = vw.account_address 
LEFT JOIN 
    ods.ods_top100_balance_wallets bw ON t.from_address = bw.account_address 
LEFT JOIN 
    ods.ods_daily_top30_volume_wallets vw2 ON t.to_address = vw2.account_address 
LEFT JOIN 
    ods.ods_top100_balance_wallets bw2 ON t.to_address = bw2.account_address 
WHERE 
    -- 至少有一方是鲸鱼
    (vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL OR 
     vw2.account_address IS NOT NULL OR bw2.account_address IS NOT NULL)
```

## 4. 执行流程与调度

### 4.1 完整执行流程

DWD层数据处理按以下顺序执行：

1. 执行`dwd_transaction_clean.sql`创建并填充基础交易清洗表：
   ```bash
   ./run_all_sql.sh
   ```

2. 执行`dwd_whale_transaction_detail.sql`创建并填充鲸鱼交易明细表（依赖于`dwd_transaction_clean`表）

### 4.2 调度策略

DWD层数据处理通常在ODS层数据完成加载后执行，建议采用以下调度策略：

- **调度频率**：每日一次，在ODS层数据加载完成后
- **依赖关系**：
  - `dwd_transaction_clean`依赖于ODS层数据
  - `dwd_whale_transaction_detail`依赖于`dwd_transaction_clean`和ODS层鲸鱼相关表
- **超时设置**：60分钟
- **失败处理**：失败时自动重试2次，然后告警

### 4.3 数据质量监控

DWD层应设置以下数据质量监控规则：

1. **完整性检查**：
   - 确保关键字段（如tx_id、wallet_address、contract_address）无空值
   - 检查是否有丢失的日期

2. **准确性检查**：
   - 验证金额字段不为负
   - 验证交易时间戳在合理范围内

3. **一致性检查**：
   - 验证DWD层的总记录数与ODS层相关数据的一致性
   - 检查鲸鱼标识的一致性

## 5. 数据整合与关联

DWD层数据主要来源于ODS层，并通过以下方式进行整合和关联：

1. **清洗关联**：ODS层交易数据 -> dwd_transaction_clean（基础数据清洗）
2. **鲸鱼识别关联**：dwd_transaction_clean + 鲸鱼名单 -> dwd_whale_transaction_detail

这种分层处理方式既保证了数据的清晰度，又提高了处理效率：
- 基础交易数据只清洗一次，存储在`dwd_transaction_clean`表中
- 鲸鱼相关查询只针对已清洗的数据进行，避免重复清洗

## 6. 主键与分桶键设计

在Paimon表中，必须确保主键包含所有分桶键，这是实施过程中发现的重要技术要求：

1. **dwd_transaction_clean**：
   - 主键：(tx_date, tx_id, contract_address)
   - 分桶键：contract_address
   - 分桶数：10

2. **dwd_whale_transaction_detail**：
   - 主键：(tx_date, tx_id, contract_address, token_id)
   - 分桶键：contract_address
   - 分桶数：8

## 7. 常见问题与解决方案

1. **主键与分桶键问题**：
   - 症状：SQL执行报错，提示主键必须包含所有分桶键
   - 解决方案：确保表定义中的主键包含分桶键字段

2. **数据类型不匹配问题**：
   - 症状：JOIN条件失败，DATE和VARCHAR类型的日期字段无法自动转换
   - 解决方案：使用显式类型转换，如`CAST(t.tx_date AS VARCHAR) = vw.rank_date`

3. **性能问题**：
   - 症状：DWD层数据处理耗时过长
   - 解决方案：优化SQL语句，增加分区策略，调整Flink并行度

## 8. 重构效果

本次DWD层重构达到了以下效果：

1. **层级职责明确**：DWD层专注于数据清洗和明细数据构建
2. **数据流转清晰**：建立了ODS -> dwd_transaction_clean -> dwd_whale_transaction_detail的清晰路径
3. **消除冗余计算**：移除了DWD层不必要的聚合计算，迁移至DWS层
4. **提高系统效率**：减少了重复计算，提高了系统整体效率

## 9. 运维建议

1. 定期检查日志，及时发现和解决问题
2. 监控DWD层表的数据量增长，及时调整资源配置
3. 定期验证关键指标的准确性
4. 建立数据血缘关系，便于问题追踪和影响分析
5. 为关键的DWD层表设置数据质量监控告警 