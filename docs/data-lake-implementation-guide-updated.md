# NFT巨鲸追踪系统 - 数据湖搭建指南（更新版）

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
| `ods_daily_top30_transaction_collections` | 当天交易数Top30收藏集 | 日更新 | record_time, contract_address, contract_name, symbol, logo_url, banner_url, items_total, owners_total, verified, opensea_verified, sales_1d/7d/30d, volume_1d/7d/30d, floor_price, market_cap, ... |
| `ods_daily_top30_volume_collections` | 当天交易额Top30收藏集 | 日更新 | record_time, contract_address, contract_name, symbol, logo_url, banner_url, items_total, owners_total, verified, opensea_verified, sales_1d/7d/30d, volume_1d/7d/30d, floor_price, market_cap, ... |
| `ods_daily_top30_volume_wallets` | 当天交易额Top30钱包 | 日更新 | rank_date, account_address, rank_num, trade_volume, trade_volume_usdc, trade_count, is_whale, created_at |
| `ods_top100_balance_wallets` | 持有金额Top100钱包 | 日更新 | rank_date, account_address, rank_num, holding_volume, buy_volume, sell_volume, realized_gains_volume, holding_collections, holding_nfts, trade_count |
| `ods_collection_transaction_inc` | 收藏集交易数据 | 实时/小时 | record_time, hash, from_address, to_address, block_number, block_hash, gas_price, gas_used, gas_fee, tx_timestamp, contract_address, contract_name, contract_token_id, token_id, erc_type, trade_price, trade_symbol, event_type, exchange_name, ... |
| `ods_collection_working_set` | 收藏集工作集数据 | 日更新 | collection_id, collection_address, collection_name, logo_url, first_added_date, last_updated_date, last_active_date, source, status, floor_price, volume_1d, volume_7d, sales_1d, sales_7d, update_count |

#### ODS层表结构详情

**1. ods_daily_top30_transaction_collections**
- **主键**: record_time, contract_address
- **说明**: 存储每日交易数量排名前30的NFT收藏集信息
- **详细字段**:
  - record_time (TIMESTAMP): 记录时间
  - contract_address (VARCHAR): NFT合约地址
  - contract_name (VARCHAR): NFT合约名称
  - symbol (VARCHAR): NFT代币符号
  - logo_url, banner_url (VARCHAR): 图片URL
  - items_total, owners_total (INT): 总项目数、总持有者数
  - verified, opensea_verified (BOOLEAN): 验证状态
  - sales_1d/7d/30d/total (DECIMAL): 销售量指标
  - volume_1d/7d/30d/total (DECIMAL): 交易额指标
  - floor_price (DECIMAL): 地板价
  - market_cap (DECIMAL): 市值

**2. ods_daily_top30_volume_collections**
- 与`ods_daily_top30_transaction_collections`结构相同，数据按交易额排序

**3. ods_daily_top30_volume_wallets**
- **主键**: rank_date, account_address
- **说明**: 存储每日交易额排名前30的钱包地址信息
- **详细字段**:
  - rank_date (STRING): 排名日期
  - account_address (STRING): 钱包地址
  - rank_num (INT): 排名
  - trade_volume (DOUBLE): 交易量
  - trade_volume_usdc (DOUBLE): USDC交易量
  - trade_count (BIGINT): 交易次数
  - is_whale (BOOLEAN): 是否为巨鲸
  - created_at (TIMESTAMP): 记录创建时间

**4. ods_top100_balance_wallets**
- **主键**: rank_date, account_address
- **说明**: 存储持有NFT资产价值排名前100的钱包地址信息
- **详细字段**:
  - rank_date (STRING): 排名日期
  - account_address (STRING): 钱包地址
  - rank_num (INT): 排名
  - holding_volume (DOUBLE): 持有量
  - buy_volume, sell_volume (DOUBLE): 购买/出售总量
  - realized_gains_volume (DOUBLE): 已实现收益
  - holding_collections (BIGINT): 持有收藏集数量
  - holding_nfts (BIGINT): 持有NFT数量
  - trade_count (BIGINT): 交易次数

**5. ods_collection_transaction_inc**
- **主键**: record_time, hash, contract_address, token_id
- **说明**: 存储NFT收藏集的详细交易记录
- **详细字段**:
  - record_time (TIMESTAMP): 记录时间
  - hash (VARCHAR): 交易哈希
  - from_address, to_address (VARCHAR): 发送/接收地址
  - block_number, block_hash (VARCHAR): 区块信息
  - gas_price, gas_used (VARCHAR): Gas信息
  - gas_fee (DECIMAL): Gas费用
  - tx_timestamp (DECIMAL): 交易时间戳
  - contract_address, contract_name (VARCHAR): 合约信息
  - contract_token_id, token_id (VARCHAR): 代币ID
  - erc_type (VARCHAR): ERC标准类型
  - trade_price (DECIMAL): 交易价格
  - trade_symbol (VARCHAR): 交易代币符号
  - event_type (VARCHAR): 事件类型
  - exchange_name (VARCHAR): 交易所名称

**6. ods_collection_working_set**
- **主键**: collection_id
- **说明**: 存储活跃NFT收藏集的工作集数据
- **详细字段**:
  - collection_id (STRING): 收藏集ID
  - collection_address (STRING): 收藏集合约地址
  - collection_name (STRING): 收藏集名称
  - logo_url (STRING): 收藏集Logo URL
  - first_added_date (STRING): 首次添加日期
  - last_updated_date (STRING): 最后更新日期
  - last_active_date (STRING): 最后活跃日期
  - source (STRING): 数据来源
  - status (STRING): 收藏集状态
  - floor_price (DECIMAL): 地板价
  - volume_1d, volume_7d (DECIMAL): 交易额指标
  - sales_1d, sales_7d (BIGINT): 销售量指标
  - update_count (INT): 更新计数

### 3.2 DWD层（数据明细层）

| 表名 | 说明 | 数据来源 | 主要处理逻辑 |
|-----|-----|---------|------------|
| `dwd_collection_transaction_detail` | 收藏集交易明细 | ods_collection_transaction_inc | 数据清洗、价格标准化、关联买卖双方 |
| `dwd_whale_transaction_flow` | 巨鲸交易数据流 | ods_collection_transaction_inc, ods_daily_top30_volume_wallets | 筛选出巨鲸相关交易，标记交易类型 |
| `dwd_nft_transaction_inc` | NFT交易增量数据 | ods_collection_transaction_inc | 进一步标准化交易数据，增加业务相关标记 |
| `dwd_price_behavior_inc` | 价格行为增量数据 | ods_collection_transaction_inc | 提取价格变化行为数据，识别价格模式 |

### 3.3 DIM层（维度表层）

| 表名 | 说明 | 更新策略 | 主要字段 |
|-----|-----|---------|--------|
| `dim_wallet_full` | 钱包全量维度表 | 缓慢变化维 | wallet_address, first_seen_date, last_seen_date, wallet_type, ... |
| `dim_nft_full` | NFT全量维度表 | 缓慢变化维 | token_id, collection_id, creator, creation_date, attributes, ... |
| `dim_collection_full` | 收藏集全量维度表 | 缓慢变化维 | collection_id, collection_name, creator, creation_date, category, ... |
| `dim_whale_wallet` | 巨鲸钱包维度表 | 日更新 | wallet_address, tracking_start_date, whale_type, influence_score, ... |
| `dim_time` | 时间维度表 | 预生成 | date_id, year, month, day, week, is_weekend, ... |

### 3.4 DWS层（汇总层）

| 表名 | 说明 | 汇总粒度 | 主要指标 |
|-----|-----|---------|--------|
| `dws_whale_tracking_summary` | 巨鲸追踪汇总数据 | 钱包+日期 | tracking_days, total_profit_amount, profit_rate, ... |
| `dws_whale_profit_summary` | 巨鲸收益汇总数据 | 钱包+日期 | daily_profit, weekly_profit, monthly_profit, ... |
| `dws_collection_flow_summary` | 收藏集资金流向汇总 | 收藏集+日期 | inflow_amount, outflow_amount, net_flow, whale_transaction_count, ... |
| `dws_whale_behavior_1d` | 巨鲸行为日度汇总 | 钱包+日期 | behavior_type, activity_score, profit_score, influence_score, ... |
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
| `ads_whale_tracking_dashboard` | 巨鲸追踪仪表板数据 | 日更新 | wallet_address, tracking_priority, activity_level, profit_level, ... |
| `ads_tracked_whale_collection_flow` | 追踪鲸鱼收藏集净流出入Top10 | 日更新 | collection_id, net_inflow, net_outflow, time_window, ... |
| `ads_strategy_recommendation` | 投资策略推荐 | 日更新 | strategy_id, collection_id, recommendation_level, whale_activity, ... |
| `ads_trading_signals` | 推荐交易信号 | 实时/小时 | collection_id, signal_type, signal_strength, smart_whale_activity, ... |

## 4. 数据流转流程

### 4.1 数据采集到ODS层
- 从交易平台API获取原始交易数据
- 定时任务调度采集Top30/Top100相关排名数据
- 采集收藏集工作集数据，包括活跃收藏集信息
- 存储为原始格式，保留数据完整性

### 4.2 ODS到DWD层处理
- `ods_collection_transaction_inc` → `dwd_collection_transaction_detail`：清洗收藏集交易数据
- `ods_collection_transaction_inc` → `dwd_nft_transaction_inc`：标准化NFT交易数据
- `ods_collection_transaction_inc` → `dwd_price_behavior_inc`：提取价格行为数据
- `ods_daily_top30_volume_wallets` + `ods_collection_transaction_inc` → `dwd_whale_transaction_flow`：筛选巨鲸交易

### 4.3 DWD+DIM到DWS层聚合
- `dwd_whale_transaction_flow` + `dim_wallet_full` → `dws_whale_tracking_summary`：计算巨鲸追踪汇总数据
- `dwd_whale_transaction_flow` + `dim_time` → `dws_whale_profit_summary`：汇总巨鲸收益数据
- `dwd_collection_transaction_detail` + `dim_collection_full` → `dws_collection_flow_summary`：汇总收藏集资金流向
- `dwd_nft_transaction_inc` + `dwd_price_behavior_inc` → `dws_whale_behavior_1d`：汇总巨鲸行为
- `dws_whale_profit_summary` → `dws_smart_whale_stats` + `dws_dumb_whale_stats`：划分聪明/愚蠢鲸鱼
- `ods_top100_balance_wallets` → `dws_whale_influence_score`：计算影响力评分

### 4.4 DWS到ADS层加工
- `dws_whale_profit_summary` → `ads_top10_profit_amount_whales` + `ads_top10_profit_rate_whales`
- `dws_whale_tracking_summary` → `ads_tracked_whale_list`
- `dws_smart_whale_stats` → `ads_smart_whale_list`
- `dws_dumb_whale_stats` → `ads_dumb_whale_list`
- `dws_whale_behavior_1d` → `ads_whale_tracking_dashboard`
- `dws_collection_flow_summary` → `ads_tracked_whale_collection_flow`
- 综合多个DWS层数据 → `ads_strategy_recommendation` + `ads_trading_signals`：生成策略推荐和交易信号

## 5. 表存储参数说明

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

## 6. 技术选型

- **存储系统**: Paimon (基于Apache Flink的流批一体存储系统)
- **计算引擎**: Apache Flink 1.18
- **元数据管理**: Hive Metastore
- **底层存储**: HDFS
- **API数据采集**: RESTful API 客户端
- **任务调度**: 自定义脚本 + cron

## 7. 部署流程

1. 准备Hadoop、Hive Metastore和Flink集群环境
2. 部署Paimon相关依赖
3. 创建目录结构和数据流水线
4. 配置API数据采集任务
5. 部署ODS层数据加载脚本
6. 开发并部署DWD、DWS、ADS层的Flink SQL作业
7. 配置监控和告警机制 