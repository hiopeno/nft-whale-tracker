# DIM层重构说明文档

## 重构概述

根据《NFT鲸鱼追踪器数据湖重构指南》的要求，我们对DIM层（维度层）进行了重构，以解决层级职责混乱、字段利用率低等问题。本次重构主要目标是使DIM层专注于存储相对稳定的维度信息，提供统一口径，而不包含度量值和汇总计算字段。

## 重构内容

### 1. 表结构调整

**保留并精简表**：
- `dim_whale_address` - 鲸鱼钱包维度表（已精简）
- `dim_collection_info` - 收藏集维度表（已精简）

### 2. 字段优化

#### `dim_whale_address`表

该表是鲸鱼钱包的维度表，已精简为以下核心字段：
- 钱包基本信息：wallet_address, first_track_date, last_active_date
- 鲸鱼属性：is_whale, whale_type
- 标签信息：labels
- 状态信息：status
- 管理字段：etl_time

**主要变更**：
- 移除所有计算性统计字段，如：
  - total_profit_eth, total_profit_usd, roi_percentage
  - total_buy_volume_eth, total_sell_volume_eth
  - total_tx_count, avg_hold_days
  - success_rate, whale_score
- 这些字段将移至DWS层进行计算和存储

#### `dim_collection_info`表

该表是NFT收藏集的维度表，已精简为以下核心字段：
- 收藏集基本信息：collection_address, collection_name, symbol
- 展示信息：logo_url, banner_url
- 时间信息：first_tracked_date, last_active_date
- 基础属性：items_total, owners_total, is_verified
- 工作集信息：is_in_working_set, working_set_join_date
- 分类信息：category, status
- 管理字段：etl_time

**主要变更**：
- 移除所有统计性字段，如：
  - current_floor_price_eth, all_time_volume_eth, all_time_sales
  - avg_price_7d, avg_price_30d, volume_7d, volume_30d
  - sales_7d, sales_30d, whale_ownership_percentage
  - whale_volume_percentage, smart_whale_interest_score
  - total_whale_buys, total_whale_sells
- 这些字段将移至DWS层进行计算和存储

### 3. 数据流转优化

- DIM层将从ODS层和DWD层获取基础维度信息
- 不再存储和计算汇总指标
- 保持维度数据的相对稳定性
- 为DWS层提供标准维度引用

## 执行脚本调整

更新了`run_all_sql.sh`脚本，调整了SQL文件执行顺序和依赖关系：
1. 首先执行`dim_collection_info.sql`创建并填充收藏集维度表
2. 然后执行`dim_whale_address.sql`创建并填充鲸鱼钱包维度表

## 后续建议

1. **DWS层增强**：
   - 将原DIM层的汇总统计指标迁移至DWS层
   - 创建专门的汇总表存储这些指标

2. **数据回填与验证**：
   - 对新表结构进行历史数据回填
   - 进行数据一致性验证，确保重构前后结果一致

3. **应用程序适配**：
   - 更新应用程序查询，适配新的表结构
   - 统计类查询应从DWS层获取数据，维度属性查询从DIM层获取

## 重构效果

本次重构使DIM层回归到其标准定义，具有以下优势：
1. **层级职责明确**：DIM层专注于维度信息存储
2. **消除冗余计算**：移除了DIM层不必要的计算字段
3. **数据更新效率提高**：维度表更新逻辑简化
4. **数据一致性增强**：统计指标集中在DWS层管理，避免不同层级计算口径不一致

---

版本：1.0
日期：2023-04-XX
作者：数据工程团队 