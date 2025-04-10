# NFT巨鲸追踪系统 - 数据湖搭建指南

## 1. 项目概述

NFT巨鲸追踪系统旨在监控和分析NFT市场中的"巨鲸"（大额持有者和交易者）行为，帮助用户识别市场趋势并提供交易信号。本系统通过构建多层数据湖架构，实现对原始数据的采集、清洗、加工和分析，最终生成可用于决策的数据产品。

## 2. 数据湖架构概览

本系统采用经典的五层数据湖架构：

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   ODS   │ => │   DWD   │ => │   DIM   │ => │   DWS   │ => │   ADS   │
│  原始层 │    │ 明细层  │    │ 维度层  │    │ 汇总层  │    │ 应用层  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
```

- **ODS层**：存储原始数据，保留数据完整性
- **DWD层**：清洗和标准化数据，构建明细层
- **DIM层**：构建维度表，支持多维分析
- **DWS层**：汇总统计数据，生成中间指标
- **ADS层**：生成面向应用的数据产品和指标

## 3. 各层设计详情

### 3.1 ODS层（原始数据层）

| 表名 | 说明 | 更新频率 | 主要字段 |
|-----|-----|--------|--------|
| `ods_wallet_transaction` | 钱包交易原始数据 | 实时/小时 | transaction_id, wallet_address, timestamp, amount, transaction_type, ... |
| `ods_collection_transaction` | 收藏集交易原始数据 | 实时/小时 | transaction_id, collection_id, nft_id, buyer, seller, price, timestamp, ... |
| `ods_daily_top30_transaction_collections` | 当天交易数Top30收藏集 | 日更新 | collection_id, collection_name, transaction_count, rank_date, ... |
| `ods_daily_top30_volume_collections` | 当天交易额Top30收藏集 | 日更新 | collection_id, collection_name, volume, rank_date, ... |
| `ods_daily_top30_volume_wallets` | 当天交易额Top30钱包 | 日更新 | wallet_address, volume, rank, rank_date, ... |
| `ods_top100_balance_wallets` | 持有金额Top100钱包 | 日更新 | wallet_address, balance, rank, rank_date, ... |

### 3.2 DWD层（数据明细层）

| 表名 | 说明 | 数据来源 | 主要处理逻辑 |
|-----|-----|---------|------------|
| `dwd_wallet_transaction_detail` | 钱包交易明细 | ods_wallet_transaction | 数据清洗、字段标准化、异常值处理 |
| `dwd_collection_transaction_detail` | 收藏集交易明细 | ods_collection_transaction | 数据清洗、价格标准化、关联买卖双方 |
| `dwd_whale_transaction_flow` | 巨鲸交易数据流 | ods_collection_transaction, ods_daily_top30_volume_wallets | 筛选出巨鲸相关交易，标记交易类型 |
| `dwd_collection_working_set` | 收藏集工作集数据 | 多个ODS表 | 构建活跃收藏集工作集，计算加入/移除状态 |

### 3.3 DIM层（维度表层）

| 表名 | 说明 | 更新策略 | 主要字段 |
|-----|-----|---------|--------|
| `dim_wallet` | 钱包维度表 | 缓慢变化维 | wallet_address, first_seen_date, last_seen_date, wallet_type, ... |
| `dim_collection` | 收藏集维度表 | 缓慢变化维 | collection_id, collection_name, creator, creation_date, category, ... |
| `dim_whale_wallet` | 巨鲸钱包维度表 | 日更新 | wallet_address, tracking_start_date, whale_type, influence_score, ... |
| `dim_time` | 时间维度表 | 预生成 | date_id, year, month, day, week, is_weekend, ... |

### 3.4 DWS层（汇总层）

| 表名 | 说明 | 汇总粒度 | 主要指标 |
|-----|-----|---------|--------|
| `dws_whale_tracking_summary` | 巨鲸追踪汇总数据 | 钱包+日期 | tracking_days, total_profit_amount, profit_rate, ... |
| `dws_whale_profit_summary` | 巨鲸收益汇总数据 | 钱包+日期 | daily_profit, weekly_profit, monthly_profit, ... |
| `dws_collection_flow_summary` | 收藏集资金流向汇总 | 收藏集+日期 | inflow_amount, outflow_amount, net_flow, whale_transaction_count, ... |
| `dws_smart_whale_stats` | 聪明鲸鱼统计数据 | 钱包+日期 | smart_type, profit_rank_percentile, successful_trades_rate, ... |
| `dws_dumb_whale_stats` | 愚蠢鲸鱼统计数据 | 钱包+日期 | dumb_type, profit_rank_percentile, failed_trades_rate, ... |
| `dws_whale_influence_score` | 巨鲸影响力评分数据 | 钱包+日期 | influence_score, influence_rank, balance_rank, star_rating, ... |

### 3.5 ADS层（应用层）

| 表名 | 说明 | 更新频率 | 主要字段 |
|-----|-----|---------|--------|
| `ads_top10_profit_amount_whales` | 收益额Top10巨鲸 | 日更新 | wallet_address, profit_amount, profit_rank, tracking_days, ... |
| `ads_top10_profit_rate_whales` | 收益率Top10巨鲸 | 日更新 | wallet_address, profit_rate, profit_rate_rank, tracking_days, ... |
| `ads_tracked_whale_list` | 追踪鲸鱼名单 | 日更新 | wallet_address, tracking_start_date, total_profit, influence_score, ... |
| `ads_smart_whale_list` | 聪明鲸鱼名单 | 日更新 | wallet_address, smart_type, profit_rate, successful_trades_count, ... |
| `ads_dumb_whale_list` | 愚蠢鲸鱼名单 | 日更新 | wallet_address, dumb_type, profit_rate, failed_trades_count, ... |
| `ads_tracked_whale_collection_flow` | 追踪鲸鱼收藏集净流出入Top10 | 日更新 | collection_id, net_inflow, net_outflow, time_window, ... |
| `ads_smart_whale_collection_flow` | 聪明鲸鱼收藏集净流出入Top10 | 日更新 | collection_id, smart_whale_net_inflow, smart_whale_net_outflow, time_window, ... |
| `ads_dumb_whale_collection_flow` | 愚蠢鲸鱼收藏集净流出入Top10 | 日更新 | collection_id, dumb_whale_net_inflow, dumb_whale_net_outflow, time_window, ... |
| `ads_trading_signals` | 推荐交易信号 | 实时/小时 | collection_id, signal_type, signal_strength, smart_whale_activity, ... |

## 4. 数据流转流程

### 4.1 数据采集到ODS层
- 从交易平台API获取原始交易数据、钱包数据
- 定时任务调度采集Top30/Top100相关排名数据
- 存储为原始格式，保留数据完整性

### 4.2 ODS到DWD层处理
- `ods_wallet_transaction` → `dwd_wallet_transaction_detail`：清洗交易数据，标准化格式
- `ods_collection_transaction` → `dwd_collection_transaction_detail`：清洗NFT收藏集交易数据
- `ods_daily_top30_volume_wallets` + `ods_collection_transaction` → `dwd_whale_transaction_flow`：筛选巨鲸交易
- 各类Top30数据 → `dwd_collection_working_set`：构建收藏集工作集

### 4.3 DWD+DIM到DWS层聚合
- `dwd_whale_transaction_flow` + `dim_wallet` → `dws_whale_tracking_summary`：计算巨鲸追踪汇总数据
- `dwd_whale_transaction_flow` + `dim_time` → `dws_whale_profit_summary`：汇总巨鲸收益数据
- `dwd_collection_transaction_detail` + `dim_collection` → `dws_collection_flow_summary`：汇总收藏集资金流向
- `dws_whale_profit_summary` → `dws_smart_whale_stats` + `dws_dumb_whale_stats`：划分聪明/愚蠢鲸鱼
- `ods_top100_balance_wallets` → `dws_whale_influence_score`：计算影响力评分

### 4.4 DWS到ADS层加工
- `dws_whale_profit_summary` → `ads_top10_profit_amount_whales` + `ads_top10_profit_rate_whales`
- `dws_whale_tracking_summary` → `ads_tracked_whale_list`
- `dws_smart_whale_stats` → `ads_smart_whale_list`
- `dws_dumb_whale_stats` → `ads_dumb_whale_list`
- `dws_collection_flow_summary` → 各类净流出入Top10表
- 综合多个DWS层数据 → `ads_trading_signals`：生成交易信号

