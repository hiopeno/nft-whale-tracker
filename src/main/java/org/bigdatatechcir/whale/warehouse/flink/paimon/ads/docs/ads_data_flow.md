# NFT Whale Tracker ADS层数据流转文档

## 1. 概述

本文档详细描述了NFT Whale Tracker项目中ADS层（Application Data Service，应用数据服务层）的数据流转过程。ADS层是数据仓库的最上层，直接面向应用和业务分析，提供结构化的数据服务。在完成DWD、DIM和DWS层重构后，ADS层的数据来源发生了调整，现在主要从DWS层获取汇总数据，而不是直接从DWD层获取明细数据。

## 2. 数据流转架构

整个ADS层的数据流转过程可以分为以下几个环节：

```
     ┌───────────┐           ┌───────────┐           ┌───────────┐
     │  DWD层    │           │  DIM层    │           │  DWS层    │
     │(明细数据) │           │(维度数据) │           │(汇总数据) │
     └─────┬─────┘           └─────┬─────┘           └─────┬─────┘
           │                       │                       │
           └───────────────────────┼───────────────────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │     ADS层       │
                          │ (应用数据服务)  │
                          └────────┬────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │    应用层       │
                          │  (报表/API等)   │
                          └─────────────────┘
```

ADS层的主要数据来源是DWS层的汇总数据表，而DWS层则基于DWD层的明细数据和DIM层的维度数据构建。这种分层架构确保了数据处理的高效性和数据服务的灵活性。

## 3. 数据源与依赖关系

### 3.1 数据源说明

根据重构后的分层架构，ADS层主要依赖以下数据源：

1. **DWS层数据**：
   - `dws_whale_daily_stats` - 鲸鱼每日统计表
   - `dws_collection_daily_stats` - 收藏集每日统计表
   - `dws_collection_whale_flow` - 收藏集鲸鱼资金流向表
   - `dws_whale_portfolio_trend` - 鲸鱼投资组合趋势表
   - `dws_collection_whale_ownership` - 收藏集鲸鱼持有统计表
   - `dws_wallet_daily_stats` - 钱包每日统计表

2. **DIM层数据**：
   - `dim_whale_address` - 鲸鱼钱包维度表
   - `dim_collection_info` - 收藏集维度表

3. **DWD层数据**（仅在特定场景下直接使用）：
   - `dwd_whale_transaction_detail` - 鲸鱼交易明细表

### 3.2 依赖关系

ADS层的各个表与DWS、DIM层表之间的主要依赖关系如下：

| ADS层表 | 主要依赖数据源 |
|---------|---------------|
| ads_top_profit_whales | dws_whale_daily_stats, dim_whale_address |
| ads_top_roi_whales | dws_whale_daily_stats, dim_whale_address |
| ads_whale_tracking_list | dim_whale_address, dws_whale_daily_stats |
| ads_tracking_whale_collection_flow | dws_collection_whale_flow, dim_collection_info |
| ads_smart_whale_collection_flow | dws_collection_whale_flow, dim_whale_address |
| ads_dumb_whale_collection_flow | dws_collection_whale_flow, dim_whale_address |
| ads_whale_transactions | dwd_whale_transaction_detail, dim_whale_address, dws_whale_daily_stats, dws_collection_daily_stats |

## 4. 数据处理流程

### 4.1 鲸鱼排行榜相关表

#### 4.1.1 ads_top_profit_whales（收益额Top鲸鱼）

该表存储收益额排名靠前的鲸鱼钱包信息，主要用于展示哪些鲸鱼钱包在NFT交易中获得的利润最高。

**处理流程**：
1. 从DWS层`dws_whale_daily_stats`表聚合鲸鱼钱包的交易与收益数据
   - 计算总利润（daily_profit_eth的累计和）
   - 计算总交易次数（统计记录数）
   - 获取影响力评分（influence_score）
2. 关联DIM层`dim_whale_address`表获取鲸鱼类型、首次追踪日期和状态信息
3. 计算追踪天数和利润相关指标
4. 识别每个鲸鱼的最佳收藏集（产生最高利润的收藏集）
5. 根据总收益排序，提取Top10
6. 通过临时计算视图获取近期（7天、30天）的利润数据

#### 4.1.2 ads_top_roi_whales（收益率Top鲸鱼）

该表存储收益率排名靠前的鲸鱼钱包信息，主要用于展示哪些鲸鱼钱包在NFT交易中的投资回报率最高。

**处理流程**：
1. 从DWS层`dws_whale_daily_stats`表获取鲸鱼钱包的交易和收益数据
2. 关联DIM层`dim_whale_address`表获取鲸鱼类型和标签
3. 计算各鲸鱼钱包的ROI（投资回报率）
4. 根据ROI排序，提取Top10
5. 计算相关指标（成功交易比例、交易次数等）

### 4.2 收藏集流向相关表

#### 4.2.1 ads_tracking_whale_collection_flow（收藏集鲸鱼流向Top）

该表存储鲸鱼资金净流入/流出排名靠前的收藏集信息，用于分析哪些收藏集受到鲸鱼青睐或抛弃。

**处理流程**：
1. 从DWS层`dws_collection_whale_flow`表获取收藏集的鲸鱼资金流向数据
2. 计算各收藏集的鲸鱼净流入/流出金额
3. 分别按照净流入和净流出排序，分别提取Top10
4. 计算7天和30天的累计净流量
5. 关联DIM层收藏集信息，添加相关属性

#### 4.2.2 ads_smart_whale_collection_flow（聪明鲸鱼收藏集流向）

该表存储聪明鲸鱼（赚钱能力强的鲸鱼）资金流向的收藏集信息，用于分析有盈利能力的鲸鱼的投资偏好。

**处理流程**：
1. 从DWS层`dws_collection_whale_flow`和`dws_whale_daily_stats`表获取数据
2. 筛选出聪明鲸鱼（whale_type为'SMART'）的交易记录
3. 计算各收藏集的聪明鲸鱼净流入/流出金额
4. 分别按照净流入和净流出排序，提取Top收藏集
5. 计算聪明鲸鱼交易占该收藏集总交易的比例

#### 4.2.3 ads_dumb_whale_collection_flow（愚蠢鲸鱼收藏集流向）

该表存储愚蠢鲸鱼（亏损较多的鲸鱼）资金流向的收藏集信息，用于分析哪些收藏集可能存在价值高估。

**处理流程**：
1. 从DWS层`dws_collection_whale_flow`和`dws_whale_daily_stats`表获取数据
2. 筛选出愚蠢鲸鱼（whale_type为'DUMB'）的交易记录
3. 计算各收藏集的愚蠢鲸鱼净流入/流出金额
4. 分别按照净流入和净流出排序，提取Top收藏集
5. 计算愚蠢鲸鱼交易占该收藏集总交易的比例

### 4.3 鲸鱼追踪相关表

#### 4.3.1 ads_whale_tracking_list（鲸鱼追踪名单）

该表存储值得追踪的鲸鱼钱包信息，用于持续监控有影响力鲸鱼的交易行为。

**处理流程**：
1. 从DWS层`dws_whale_daily_stats`表聚合鲸鱼钱包数据
   - 计算总利润和利润转化率
   - 获取影响力评分（influence_score）
   - 获取交易成功率（success_rate_30d）
   - 获取交易过的收藏集数量
2. 关联DIM层`dim_whale_address`表获取鲸鱼基础信息
   - 钱包地址和类型
   - 首次追踪日期和最后活跃日期
   - 状态信息
3. 通过现有数据计算其他指标
   - 根据最后活跃日期计算不活跃天数
   - 根据首次追踪日期计算追踪天数
   - 生成追踪ID（根据影响力评分排序）
4. 关联当天的DWS层数据获取排名信息
5. 筛选活跃或短期不活跃（7天内）的鲸鱼钱包

### 4.4 交易明细相关表

#### 4.4.1 ads_whale_transactions（鲸鱼交易数据）

该表存储鲸鱼相关的交易记录，用于详细分析鲸鱼的交易行为。

**处理流程**：
1. 从DWD层`dwd_whale_transaction_detail`表获取鲸鱼交易明细
2. 创建临时视图关联鲸鱼信息
   - 关联DIM层`dim_whale_address`表获取鲸鱼类型信息
   - 关联DWS层`dws_whale_daily_stats`表获取影响力评分（influence_score）
3. 创建临时视图关联收藏集信息
   - 关联DWS层`dws_collection_daily_stats`表获取收藏集地板价信息
4. 整合交易明细与鲸鱼、收藏集信息
5. 计算价格相对于地板价的比率
6. 筛选最近两周的数据
7. 格式化结果，补充空值，生成最终数据

## 5. 执行流程与调度

### 5.1 完整执行流程

ADS层数据处理通常按以下顺序执行：

1. **鲸鱼排行榜作业**：
   - 生成`ads_top_profit_whales`和`ads_top_roi_whales`表
   - 脚本：`run_ads_whale_top_lists.sh`

2. **鲸鱼追踪名单作业**：
   - 生成`ads_whale_tracking_list`表
   - 脚本：`run_ads_whale_tracking.sh`

3. **收藏集流向作业**：
   - 生成`ads_tracking_whale_collection_flow`、`ads_smart_whale_collection_flow`和`ads_dumb_whale_collection_flow`表
   - 脚本：`run_ads_collection_flows.sh`

4. **鲸鱼交易数据作业**：
   - 生成`ads_whale_transactions`表
   - 脚本：`run_ads_whale_transactions.sh`

### 5.2 调度策略

ADS层数据处理通常在DWD、DIM和DWS层数据处理完成后执行：

- **调度频率**：每日一次
- **调度时间**：凌晨3:00（在DWS层作业完成后）
- **依赖关系**：
  - 依赖DWS层数据处理完成
  - 依赖DIM层数据更新完成
- **超时设置**：45分钟
- **失败处理**：失败时自动重试1次，然后告警

### 5.3 数据更新策略

ADS层表的数据更新策略如下：

1. **全量更新**：
   - `ads_top_profit_whales`
   - `ads_top_roi_whales`
   - `ads_tracking_whale_collection_flow`
   - `ads_smart_whale_collection_flow`
   - `ads_dumb_whale_collection_flow`
   - `ads_whale_tracking_list`

2. **增量更新**：
   - `ads_whale_transactions`（每日仅处理最近14天的数据）

## 6. 数据质量控制

### 6.1 数据质量规则

ADS层实施以下数据质量控制规则：

1. **完整性检查**：
   - 确保排行榜类表记录数符合预期（如Top10表应该有10条记录）
   - 验证关键字段无空值

2. **准确性检查**：
   - 验证汇总数值与DWS层一致
   - 验证排名计算正确

3. **时效性检查**：
   - 确保每日有当天的快照数据
   - 监控作业执行时间

### 6.2 异常处理机制

对于发现的数据质量问题，采取以下处理机制：

1. **告警通知**：
   - 数据异常时通过邮件/消息通知运维团队
   - 记录详细的错误日志

2. **数据修复**：
   - 对于数据缺失，通过手动触发脚本重新生成
   - 对于数据错误，先修复上游数据源，再重新执行ADS层作业

## 7. 典型应用场景

### 7.1 鲸鱼投资行为分析

该场景主要关注鲸鱼的投资偏好和绩效：

- **相关表**：`ads_top_profit_whales`, `ads_top_roi_whales`, `ads_whale_tracking_list`
- **关键指标**：鲸鱼收益额、收益率、成功交易比例
- **应用方式**：
  - 分析最赚钱的Top10鲸鱼的投资策略
  - 监控高ROI鲸鱼的最新交易动向
  - 追踪有影响力鲸鱼的投资组合变化

### 7.2 收藏集热度预测

该场景主要关注收藏集的鲸鱼资金流向，预测热度变化：

- **相关表**：`ads_tracking_whale_collection_flow`, `ads_smart_whale_collection_flow`
- **关键指标**：鲸鱼净流入/流出金额、聪明鲸鱼占比、地板价变化
- **应用方式**：
  - 发现鲸鱼大量买入的新兴收藏集
  - 分析聪明鲸鱼近期关注的收藏集
  - 预警鲸鱼大量卖出的收藏集

### 7.3 交易异常监测

该场景主要关注异常交易模式的检测：

- **相关表**：`ads_whale_transactions`, `ads_dumb_whale_collection_flow`
- **关键指标**：价格/地板价比率、大额交易、愚蠢鲸鱼交易占比
- **应用方式**：
  - 识别明显高于地板价的可疑交易
  - 监测愚蠢鲸鱼集中买入的收藏集
  - 分析大额交易的时间分布模式

## 8. 常见问题与解决方案

### 8.1 数据延迟问题

**问题**：ADS层数据未能及时更新。

**解决方案**：
1. 检查上游依赖的DWS层作业是否已完成
2. 检查Flink作业执行日志，查看是否有卡顿或失败
3. 适当调整资源配置，提高并行度
4. 优化SQL查询，减少复杂计算

### 8.2 数据不一致问题

**问题**：ADS层数据与上游数据源不一致。

**解决方案**：
1. 验证DWS到ADS的数据流转逻辑是否正确
2. 查看中间计算过程，检查汇总逻辑
3. 确认使用的时间范围筛选条件一致
4. 修正类型转换和NULL值处理逻辑

### 8.3 新增表集成问题

**问题**：新增ADS表集成到现有架构困难。

**解决方案**：
1. 遵循现有命名和设计规范
2. 先在测试环境验证数据处理逻辑
3. 更新相关文档和元数据信息
4. 调整执行脚本，确保新表纳入现有调度流程

## 9. 运维建议

1. 定期清理历史快照数据，避免存储占用过大
2. 监控ADS层作业执行时间，及时发现性能下降问题
3. 建立数据质量监控体系，对关键指标设置合理阈值
4. 优化查询频繁的表，考虑添加适当索引
5. 定期与业务方沟通，确保ADS层输出满足业务需求

## 10. 未来优化方向

1. **实时数据服务**：构建基于Kafka的实时数据流，减少数据延迟
2. **个性化推荐**：基于鲸鱼历史交易行为，构建推荐模型
3. **智能告警**：实现基于机器学习的异常检测，提高预警准确率
4. **指标统一管理**：建立指标元数据管理平台，统一口径与计算规则
5. **交互式分析**：提供更灵活的即席查询能力，支持多维分析 