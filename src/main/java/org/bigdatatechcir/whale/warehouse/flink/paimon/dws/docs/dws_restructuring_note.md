# DWS层重构说明文档

## 重构概述

根据《NFT鲸鱼追踪器数据湖重构指南》的要求，我们对DWS层（Data Warehouse Service，数据服务层）进行了重构，以解决层级职责混乱、字段利用率低等问题。本次重构主要目标是使DWS层承担起其应有的汇总计算职责，承接从DWD和DIM层迁移过来的聚合统计功能，为上层应用提供标准的多维分析数据。

## 重构内容

### 1. 表结构调整

**现有表优化**：
- `dws_whale_daily_stats` - 鲸鱼每日统计表（优化字段和逻辑）
- `dws_collection_whale_flow` - 收藏集鲸鱼资金流向表（优化字段和逻辑）

**新增表**（从DWD层迁移）：
- `dws_collection_daily_stats` - 收藏集每日统计表（从原DWD层迁移并增强）
- `dws_wallet_daily_stats` - 钱包每日统计表（从原DWD层迁移并增强）

**新增聚合表**：
- `dws_collection_whale_ownership` - 收藏集鲸鱼持有统计表（新增，聚合DIM层的统计功能）

### 2. 字段优化

#### `dws_collection_daily_stats`表
该表从DWD层迁移而来，包含以下核心字段：
- 时间维度：collection_date
- 收藏集维度：contract_address, collection_name
- 交易指标：sales_count, volume_eth, volume_usd, avg_price_eth, min_price_eth, max_price_eth, floor_price_eth
- 买卖方指标：unique_buyers, unique_sellers, whale_buyers, whale_sellers
- 鲸鱼相关指标：whale_volume_eth, whale_percentage
- 变化指标：sales_change_1d, volume_change_1d, price_change_1d
- 排名指标：rank_by_volume, rank_by_sales, is_top30_volume, is_top30_sales
- 其他标记：is_in_working_set, etl_time

#### `dws_wallet_daily_stats`表
该表从DWD层迁移而来，进一步增强了钱包统计功能：
- 时间维度：wallet_date
- 钱包维度：wallet_address
- 交易指标：total_tx_count, buy_count, sell_count, buy_volume_eth, sell_volume_eth
- 财务指标：profit_eth, profit_usd, roi_percentage
- 活跃指标：collections_traded, is_active
- 鲸鱼相关：is_whale_candidate, is_top30_volume, is_top100_balance
- 资产指标：balance_eth, balance_usd
- 管理字段：etl_time

#### `dws_collection_whale_ownership`表
这是新增的收藏集鲸鱼持有统计表，从DIM层迁移统计功能，包含以下核心字段：
- 时间维度：stat_date
- 收藏集维度：collection_address, collection_name
- 持有指标：total_nfts, total_owners, whale_owners, whale_owned_nfts
- 持有比例：whale_ownership_percentage, smart_whale_ownership_percentage, dumb_whale_ownership_percentage
- 价值指标：total_value_eth, whale_owned_value_eth
- 趋势指标：ownership_change_1d, ownership_change_7d
- 排名指标：rank_by_whale_ownership
- 其他标记：is_in_working_set, etl_time

### 3. 数据流转优化

- DWS层直接从DWD层获取明细数据进行聚合
- 通过DIM层获取维度信息进行丰富
- 建立明确的数据依赖关系：
  - DWD层明细数据 → DWS层汇总数据
  - DIM层维度数据 → DWS层汇总数据
- 避免层级间的循环依赖

## 执行脚本调整

更新了`run_all_sql.sh`脚本，调整了SQL执行顺序：
1. 首先执行`dws_collection_daily_stats.sql`创建并填充收藏集每日统计表
2. 然后执行`dws_wallet_daily_stats.sql`创建并填充钱包每日统计表
3. 接着执行`dws_whale_daily_stats.sql`创建并填充鲸鱼每日统计表
4. 然后执行`dws_collection_whale_flow.sql`创建并填充收藏集鲸鱼资金流向表
5. 最后执行`dws_collection_whale_ownership.sql`创建并填充收藏集鲸鱼持有统计表

## 后续建议

1. **数据一致性验证**：
   - 验证原DWD层和新DWS层计算结果的一致性
   - 确保所有迁移的指标计算逻辑正确

2. **性能优化**：
   - 对汇总查询进行性能优化
   - 考虑为高频查询创建物化视图

3. **指标口径统一**：
   - 建立统一的指标计算规范
   - 在DWS层实现标准指标计算逻辑

4. **自动化监控**：
   - 为DWS层表设置数据质量监控
   - 监测关键指标的异常变化

## 重构效果

本次重构使DWS层回归到其标准定义，具有以下优势：
1. **层级职责明确**：DWS层专注于汇总分析数据
2. **数据流转清晰**：从DWD和DIM层获取数据，提供标准聚合口径
3. **消除冗余计算**：统一在DWS层实现聚合计算，避免在多层重复计算
4. **支持多维分析**：提供不同维度的汇总数据，满足各类分析需求
5. **提高开发效率**：明确的层级划分，使功能开发和维护更加高效

## 实施注意事项

1. **历史数据处理**：
   - 需要对从DWD层迁移的表进行历史数据回填
   - 确保历史数据的连续性和一致性

2. **依赖关系管理**：
   - DWS层表之间可能存在依赖关系
   - 确保按正确顺序执行SQL文件

3. **指标计算准确性**：
   - 验证所有聚合计算的准确性
   - 特别是涉及时间窗口的计算逻辑

---

版本：1.0
日期：2023-04-XX
作者：数据工程团队 