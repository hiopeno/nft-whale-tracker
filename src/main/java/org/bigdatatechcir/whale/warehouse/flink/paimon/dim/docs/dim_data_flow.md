# DIM层数据流转文档

## 概述

DIM层（Dimension，维度层）是NFT Whale Tracker项目中负责管理和标准化维度数据的层级。DIM层主要处理鲸鱼钱包地址和NFT收藏集这两类关键维度数据，为上层的数据分析提供统一的维度口径和标准化视图。

本文档详细描述DIM层的数据流转流程、处理逻辑和更新策略。

## 数据流转架构

DIM层的数据流转架构如下：

1. **数据获取**
   - 从ODS层获取原始维度数据（如鲸鱼名单、收藏集基本信息）
   - 从DWD层获取清洗后的交易数据，用于更新维度的活跃状态

2. **数据处理**
   - 对维度数据进行标准化处理
   - 应用业务规则进行分类和标记
   - 更新维度状态和属性

3. **数据存储**
   - 将处理后的维度数据写入Paimon表
   - 保持维度表结构稳定，确保上层分析一致性

4. **数据更新**
   - 采用增量更新策略，每日定时更新
   - 维护状态变更历史，支持时间点查询

## dim_whale_address处理流程

### 数据来源

`dim_whale_address`表的数据来源包括：

1. ODS层的鲸鱼名单数据：
   - `ods_daily_top30_volume_wallets` - 每日交易量前30的钱包
   - `ods_top100_balance_wallets` - 资产价值前100的钱包

2. DWD层的交易数据：
   - `dwd_transaction_clean` - 清洗后的NFT交易数据
   - `dwd_whale_transaction_detail` - 鲸鱼交易明细数据

### 处理步骤

1. **新增鲸鱼识别与录入**
   - 从ODS层获取最新的鲸鱼名单
   - 与已有维度数据比对，识别新增钱包
   - 为新增钱包创建维度记录，设置初始属性

```sql
   -- 插入新增鲸鱼地址
INSERT INTO dim_whale_address
SELECT 
     wallet_address,
     CURRENT_DATE as first_track_date,
     CURRENT_DATE as last_active_date,
     TRUE as is_whale,
     'TRACKING' as whale_type,
     '[]' as labels,
     'ACTIVE' as status,
     CURRENT_TIMESTAMP as etl_time
        FROM (
     -- 从多个数据源获取潜在鲸鱼地址
     SELECT wallet_address FROM ods_daily_top30_volume_wallets
     UNION
     SELECT wallet_address FROM ods_top100_balance_wallets
   ) potential_whales
   WHERE wallet_address NOT IN (SELECT wallet_address FROM dim_whale_address);
   ```

2. **活跃状态更新**
   - 基于DWD层的交易数据，更新鲸鱼的最后活跃日期
   - 根据活跃日期判断活跃状态（30天内有交易为活跃）

   ```sql
   -- 更新鲸鱼活跃状态
   UPDATE dim_whale_address w
   SET 
     last_active_date = t.latest_tx_date,
     status = CASE 
               WHEN DATEDIFF(CURRENT_DATE, t.latest_tx_date) <= 30 THEN 'ACTIVE' 
               ELSE 'INACTIVE' 
             END,
     etl_time = CURRENT_TIMESTAMP
FROM (
    SELECT 
       COALESCE(from_address, to_address) as wallet_address,
       MAX(tx_date) as latest_tx_date
     FROM dwd_whale_transaction_detail
     GROUP BY COALESCE(from_address, to_address)
   ) t
   WHERE w.wallet_address = t.wallet_address;
   ```

3. **鲸鱼类型判定**
   - 对追踪期超过30天的鲸鱼，基于交易表现判定类型
   - 根据收益率、成功交易比例等指标分为SMART或DUMB

   ```sql
   -- 更新鲸鱼类型
   UPDATE dim_whale_address w
   SET 
     whale_type = CASE 
                   WHEN profit_rate > 0 THEN 'SMART'
                   ELSE 'DUMB'
                 END,
     etl_time = CURRENT_TIMESTAMP
            FROM (
     -- 复杂的鲸鱼交易表现计算逻辑
                SELECT 
       wallet_address,
       SUM(profit_amount) / SUM(investment_amount) as profit_rate
     FROM dwd_whale_transaction_detail
     GROUP BY wallet_address
   ) t
   WHERE w.wallet_address = t.wallet_address
     AND w.whale_type = 'TRACKING'
     AND DATEDIFF(CURRENT_DATE, w.first_track_date) > 30;
   ```

## dim_collection_info处理流程

### 数据来源

`dim_collection_info`表的数据来源包括：

1. ODS层的收藏集数据：
   - `ods_collection_working_set` - 当前工作集中的收藏集信息

2. DWD层的交易数据：
   - `dwd_transaction_clean` - 清洗后的NFT交易数据，用于更新活跃状态

### 处理步骤

1. **收藏集基本信息获取与更新**
   - 从ODS层获取最新的收藏集信息
   - 更新或插入收藏集基本属性

```sql
   -- 插入/更新收藏集信息
   MERGE INTO dim_collection_info t
   USING ods_collection_working_set s
   ON t.collection_address = s.collection_address
   WHEN MATCHED THEN
     UPDATE SET
       collection_name = s.collection_name,
       symbol = s.symbol,
       logo_url = s.logo_url,
       banner_url = s.banner_url,
       items_total = s.items_total,
       owners_total = s.owners_total,
       is_verified = s.is_verified,
       is_in_working_set = TRUE,
       working_set_join_date = COALESCE(t.working_set_join_date, CURRENT_DATE),
       category = s.category,
       etl_time = CURRENT_TIMESTAMP
   WHEN NOT MATCHED THEN
     INSERT (collection_address, collection_name, symbol, logo_url, banner_url, 
             first_tracked_date, last_active_date, items_total, owners_total, 
             is_verified, is_in_working_set, working_set_join_date, category, status, etl_time)
     VALUES (s.collection_address, s.collection_name, s.symbol, s.logo_url, s.banner_url,
             CURRENT_DATE, CURRENT_DATE, s.items_total, s.owners_total,
             s.is_verified, TRUE, CURRENT_DATE, s.category, 'ACTIVE', CURRENT_TIMESTAMP);
   ```

2. **收藏集活跃状态更新**
   - 基于DWD层的交易数据，更新收藏集的最后活跃日期
   - 根据活跃日期判断活跃状态（7天内有交易为活跃）

   ```sql
   -- 更新收藏集活跃状态
   UPDATE dim_collection_info c
   SET 
     last_active_date = t.latest_tx_date,
     status = CASE 
               WHEN DATEDIFF(CURRENT_DATE, t.latest_tx_date) <= 7 THEN 'ACTIVE' 
               ELSE 'INACTIVE' 
             END,
     etl_time = CURRENT_TIMESTAMP
   FROM (
     SELECT 
       contract_address,
       MAX(tx_date) as latest_tx_date
     FROM dwd_transaction_clean
     GROUP BY contract_address
   ) t
   WHERE c.collection_address = t.contract_address;
   ```

3. **工作集状态更新**
   - 更新不再属于工作集的收藏集状态
   - 保留历史数据，但标记为非工作集

   ```sql
   -- 更新非工作集状态
   UPDATE dim_collection_info
   SET 
     is_in_working_set = FALSE,
     etl_time = CURRENT_TIMESTAMP
   WHERE collection_address NOT IN (SELECT collection_address FROM ods_collection_working_set)
     AND is_in_working_set = TRUE;
   ```

## 执行策略

DIM层表的执行策略如下：

1. **执行顺序**
   - 先执行`dim_collection_info`的更新，因为它依赖较少的前置条件
   - 再执行`dim_whale_address`的更新，因为它需要用到最新的交易数据

2. **更新策略**
   - 采用每日定时调度策略，在ODS层和DWD层数据准备完成后执行
   - 每次更新时，先处理插入和更新操作，再处理状态变更

3. **历史数据保留**
   - 维度表保留所有历史记录，不会物理删除数据
   - 通过状态字段和活跃时间标记实体的当前状态

## DIM层职责说明

明确DIM层的职责边界对于维护数据仓库的层次清晰至关重要：

### DIM层应该做的

1. **维度数据标准化**
   - 对维度实体（鲸鱼钱包、收藏集）进行唯一标识
   - 标准化维度属性和状态的表示方式

2. **维度状态管理**
   - 跟踪维度实体的状态变化（如活跃/不活跃）
   - 维护状态变更的时间点和历史

3. **基本分类和标记**
   - 对维度实体进行基本分类（如鲸鱼类型）
   - 添加业务标签和属性（如收藏集类别）

4. **维度关系管理**
   - 维护维度实体之间的基本关系
   - 确保维度数据的一致性和完整性

### DIM层不应该做的

1. **复杂计算和统计**
   - 不进行复杂的统计计算（如平均持有时间、收益率等）
   - 不存储复杂的计算指标或聚合统计

2. **跨维度关联分析**
   - 不进行跨多个维度的复杂关联分析
   - 不存储维度之间的交叉分析结果

3. **时序数据存储**
   - 不存储详细的时序变化数据（如每日地板价、每日交易量）
   - 不进行时序趋势分析

4. **预测性分析**
   - 不进行预测性分析或模型评分
   - 不存储预测结果或模型输出

## 数据质量监控

为确保DIM层数据质量，实施以下监控措施：

1. **完整性检查**
   - 监控主键的唯一性和完整性
   - 检查必填字段的非空比例

2. **一致性检查**
   - 验证维度数据与源系统数据的一致性
   - 检查关联维度之间的数据一致性

3. **及时性检查**
   - 监控维度数据的更新及时性
   - 跟踪更新延迟和处理时间

4. **准确性检查**
   - 验证维度属性的准确性
   - 抽样核对维度状态和分类的正确性

## 性能优化策略

针对DIM层表的性能优化策略包括：

1. **分区策略**
   - 不对维度表进行物理分区，保持表的完整性
   - 通过状态字段进行逻辑分区

2. **索引策略**
   - 对主键（wallet_address, collection_address）建立主键索引
   - 对频繁查询的状态字段建立二级索引

3. **更新优化**
   - 批量处理更新操作，减少单条更新
   - 使用MERGE语句实现高效的更新和插入

4. **查询优化**
   - 预计算常用的维度属性
   - 维护统计信息，优化查询计划 