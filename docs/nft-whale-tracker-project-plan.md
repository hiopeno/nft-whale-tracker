# NFT巨鲸钱包追踪和低价狙击系统 - 项目开发规划

## 1. 项目概述

### 1.1 项目背景
NFT市场受巨鲸钱包（大额持有者）行为的显著影响，同时存在大量低价狙击机会。本系统旨在实时监控巨鲸活动并识别潜在的低价NFT投资机会，为交易决策提供数据支持。

### 1.2 项目目标
- 构建符合数据仓库标准的四层架构实时数据处理系统
- 实现巨鲸钱包活动的实时监控和分析
- 开发低价NFT自动识别和评估功能
- 提供可操作的交易决策支持

### 1.3 业务价值
- 通过跟踪巨鲸行为洞察市场趋势
- 识别并快速响应低价NFT交易机会
- 降低投资风险，提高投资收益率
- 构建可扩展的数据分析平台

## 2. 系统架构

### 2.1 整体架构
```
                      +---------------+
                      |    数据源     |
                      | (Kafka/APIs)  |
                      +-------+-------+
                              |
                              v
+-------------------------------------------------------------+
|                         数据仓库                            |
|                                                             |
| +-------------+  +----------------+  +------------+  +-----+|
| |    ODS层    |->| DWD/DIM层     |->|   DWS层    |->| ADS ||
| | (原始数据)  |  | (明细/维度数据)|  | (汇总数据) |  |(应用||
| +-------------+  +----------------+  +------------+  |数据)||
|                                                      +-----+|
+-------------------------------------------------------------+
                              |
                              v
                      +---------------+
                      |  应用层/API   |
                      |               |
                      +-------+-------+
                              |
                              v
                     +----------------+
                     |  前端展示/告警  |
                     +----------------+
```

### 2.2 技术栈选型
- **存储层**：Paimon + HDFS + Hive Metastore
- **计算引擎**：Apache Flink (实时处理)
- **消息队列**：Apache Kafka
- **调度系统**：Apache Airflow
- **API层**：Spring Boot
- **前端**：React + Ant Design
- **监控**：Prometheus + Grafana

## 3. 数据分层设计

### 3.1 ODS层 (操作数据存储) [已完成]
存储原始交易数据，保留数据完整性，无业务处理。

**表结构**：
- `ods_nft_transaction_inc`：NFT交易原始数据表

### 3.2 DWD层 (数据仓库明细层) [已完成]
存储经过清洗、转换的明细数据，构建业务过程数据。

**表结构**：
- `dwd_nft_transaction_inc`：交易明细表
  - 交易ID、NFT ID、买方地址、卖方地址、交易时间、交易平台
  - 价格（原始值、USD换算值）、交易费用、交易类型
  - 交易状态、地板价差异、异常标记等

- `dwd_price_behavior_inc`：价格行为表
  - 交易ID、NFT ID、当前价格、历史价格
  - 价格变动率、市场平均价格差异
  - 价格异常评分、相对地板价比例

### 3.3 DIM层 (维度数据层) [已完成]
存储各类主题的维度信息，提供上下文和分析视角。

**表结构**：
- `dim_wallet_full`：钱包维度表
  - 钱包地址、标签类型（巨鲸/机构/零售）
  - 资产总值、历史交易总额
  - 首次/最后交易时间、活跃度评分
  - 偏好NFT类型、关联钱包地址

- `dim_nft_full`：NFT维度表
  - NFT ID、系列ID、代币ID
  - 创建时间、创建者信息
  - 稀有度、属性详情
  - 首发价格、历史最高/最低价格

- `dim_marketplace_full`：市场维度表
  - 市场ID、市场名称
  - 手续费率、版税率
  - 支持的交易类型
  - 市场特性和优势

### 3.4 DWS层 (数据服务层) [下一阶段开发]
存储基于主题的汇总和计算结果，面向业务分析需求。

**表结构**：
- `dws_whale_behavior_1d`：巨鲸行为日汇总表
  - 巨鲸钱包地址
  - 日期、汇总周期
  - 买入/卖出数量和金额
  - 关注系列分布
  - 持仓变化情况
  - 异常交易标记
  - 市场影响力评分
  - 预测信号指标

- `dws_nft_price_1d`：NFT价格日汇总表
  - NFT系列ID、日期
  - 日交易量、地板价
  - 最高/最低/平均价格
  - 价格变动率
  - 价格波动率与动量
  - 鲸鱼关注度
  - 流动性评分
  

- `dws_market_activity_1d`：市场活跃度日汇总表
  - 市场ID、日期
  - 交易总量和总额
  - 热门系列排名
  - 买入/卖出比例
  - 流动性指标
  - 鲸鱼交易占比
  - 市场情绪指标

### 3.5 ADS层 (应用数据存储)
存储直接面向应用的数据产品，提供决策支持。

**表结构**：
- `ads_whale_tracking_dashboard`：巨鲸追踪看板
  - 巨鲸钱包ID、更新时间
  - 近期活动摘要
  - 持仓变化
  - 影响力评分
  - 活动预警等级

- `ads_bargain_opportunity`：低价狙击机会表
  - NFT ID、发现时间
  - 当前价格、市场参考价
  - 折扣百分比
  - 紧急度评分
  - 投资价值评分
  - 风险评分

- `ads_strategy_recommendation`：策略推荐表
  - 策略ID、策略类型
  - 生成时间、有效期
  - 目标NFT/系列
  - 建议操作
  - 预期收益率
  - 成功概率评分

## 4. 开发里程碑

### 4.1 第一阶段：基础架构设计与ODS层实现 [已完成]
- [x] 系统架构设计
- [x] 技术栈选型
- [x] 数据模型设计
- [x] ODS层实现
- [x] Kafka -> Paimon数据通道搭建

### 4.2 第二阶段：DWD/DIM层开发 [已完成]
- [x] 交易明细表(dwd_nft_transaction_inc)设计与实现
- [x] 价格行为表(dwd_price_behavior_inc)设计与实现
- [x] 钱包维度表(dim_wallet_full)设计与实现
- [x] NFT维度表(dim_nft_full)设计与实现
- [x] 市场维度表(dim_marketplace_full)设计与实现
- [x] 数据质量验证与测试

### 4.3 第三阶段：DWS层开发 [计划中 - 预计3周]
- [ ] 巨鲸行为汇总表实现
- [ ] NFT价格汇总表实现
- [ ] 市场活跃度汇总表实现
- [ ] 数据聚合逻辑优化
- [ ] 增量计算框架开发
- [ ] 性能测试与优化

### 4.4 第四阶段：ADS层与应用接口开发 [2周]
- [ ] 巨鲸追踪看板实现
- [ ] 低价狙击机会表实现
- [ ] 策略推荐表实现
- [ ] REST API接口设计与开发
- [ ] 告警系统开发

### 4.5 第五阶段：前端开发与系统集成 [2周]
- [ ] 前端数据展示页面开发
- [ ] 实时数据更新集成
- [ ] 用户交互优化
- [ ] 系统整体测试
- [ ] 部署与上线

## 5. 技术实现细节

### 5.1 DWD/DIM层实现 [已完成]
已成功实现Flink SQL进行实时ETL，主要成果包括：

- **交易明细表(dwd_nft_transaction_inc)**：
  - 实现价格换算逻辑，统一USD和ETH计价
  - 开发鲸鱼交易识别算法
  - 构建交易异常评分模型
  - 使用微批处理优化实时性能

- **价格行为表(dwd_price_behavior_inc)**：
  - 实现价格变动分析
  - 开发价格偏离度计算模型
  - 实现价格趋势识别算法
  - 建立价格异常评分体系

- **维度表体系**：
  - 构建NFT全面画像，实现稀有度评估
  - 开发钱包用户画像，识别交易行为模式
  - 实现市场平台分析，计算市场份额和增长趋势

### 5.2 DWS层实现计划

#### 5.2.1 巨鲸行为汇总表(dws_whale_behavior_1d)
```sql
CREATE TABLE IF NOT EXISTS dws.dws_whale_behavior_1d (
  `wallet_address` STRING,
  `dt` STRING,
  `buy_count` BIGINT,
  `buy_value_usd` DOUBLE,
  `sell_count` BIGINT,
  `sell_value_usd` DOUBLE,
  `net_position_change` DOUBLE,
  `favorite_collections` STRING, -- JSON数组，记录最活跃的系列
  `transaction_pattern` STRING, -- 'ACCUMULATING'/'DISTRIBUTING'/'SWAPPING'
  `influence_score` DOUBLE, -- 市场影响力评分
  `abnormal_activity_score` DOUBLE, -- 异常活动评分
  `prediction_signal` STRING, -- 'BULLISH'/'BEARISH'/'NEUTRAL'
  `updated_at` TIMESTAMP(3),
  PRIMARY KEY (`wallet_address`, `dt`) NOT ENFORCED
) WITH (
  'bucket' = '4',
  'bucket-key' = 'wallet_address',
  'file.format' = 'parquet'
);
```

实现流程：
1. 识别鲸鱼钱包
2. 日级别交易聚合
3. 交易模式分析
4. 影响力评分算法实现
5. 市场信号生成模型开发

#### 5.2.2 NFT价格汇总表(dws_nft_price_1d)
```sql
CREATE TABLE IF NOT EXISTS dws.dws_nft_price_1d (
  `collection_id` STRING,
  `dt` STRING,
  `daily_transaction_count` BIGINT,
  `daily_volume_usd` DOUBLE,
  `floor_price` DOUBLE,
  `avg_price` DOUBLE,
  `max_price` DOUBLE,
  `min_price` DOUBLE,
  `price_volatility` DOUBLE, -- 价格波动率
  `price_momentum` DOUBLE, -- 价格动量
  `whale_attention_ratio` DOUBLE, -- 鲸鱼关注度
  `liquidity_score` DOUBLE, -- 流动性评分
  `price_trend_prediction` STRING, -- 'UP'/'DOWN'/'STABLE'
  `updated_at` TIMESTAMP(3),
  PRIMARY KEY (`collection_id`, `dt`) NOT ENFORCED
) WITH (
  'bucket' = '8',
  'bucket-key' = 'collection_id',
  'file.format' = 'parquet'
);
```

实现流程：
1. 系列级别价格聚合计算
2. 价格波动率与动量模型
3. 鲸鱼关注度算法开发
4. 流动性评分体系实现
5. 趋势预测模型构建

#### 5.2.3 市场活跃度汇总表(dws_market_activity_1d)
```sql
CREATE TABLE IF NOT EXISTS dws.dws_market_activity_1d (
  `marketplace_id` STRING,
  `dt` STRING,
  `daily_transaction_count` BIGINT,
  `daily_volume_usd` DOUBLE,
  `unique_users` BIGINT,
  `unique_nfts` BIGINT,
  `top_collections` STRING, -- JSON数组，热门系列排名
  `buy_sell_ratio` DOUBLE, -- 买入/卖出比例
  `average_gas_fee` DOUBLE,
  `whale_transaction_ratio` DOUBLE, -- 鲸鱼交易占比
  `market_sentiment` STRING, -- 'BULLISH'/'BEARISH'/'NEUTRAL'
  `updated_at` TIMESTAMP(3),
  PRIMARY KEY (`marketplace_id`, `dt`) NOT ENFORCED
) WITH (
  'bucket' = '4',
  'bucket-key' = 'marketplace_id',
  'file.format' = 'parquet'
);
```

实现流程：
1. 市场日交易聚合分析
2. 用户活跃度计算
3. 热门系列排名算法
4. 市场情绪指标构建
5. 鲸鱼交易影响分析

### 5.3 实时计算框架
- 使用Flink的时间窗口进行实时聚合
- 结合Paimon的变更数据捕获(CDC)功能实现增量计算
- 通过状态后端保障数据一致性

### 5.4 数据质量保障
- 输入验证：检查字段完整性和有效性
- 业务规则验证：确保业务逻辑一致性
- 参考完整性：确保维度关联的有效性
- 数据时效性监控：跟踪处理延迟

## 6. 运维与监控

### 6.1 系统监控
- 实时作业状态监控
- 数据流延迟监控
- 系统资源使用监控
- 异常检测与告警

### 6.2 数据质量监控
- 数据完整性检查
- 重复数据检测
- 异常值监控
- 业务规则合规性检查

### 6.3 容量规划
- 初期每日数据量：约5GB
- 三个月增长预计：到达15GB/日
- 存储扩展计划：初始50TB，每季度评估扩容需求

## 7. 风险管理

### 7.1 技术风险
- **数据延迟风险**：通过冗余设计和降级策略减轻
- **系统可用性风险**：实现高可用部署，关键组件冗余
- **数据质量风险**：建立完善的数据质量框架

### 7.2 业务风险
- **模型准确性风险**：定期验证预测模型效果
- **市场变化风险**：设计适应性策略，快速响应市场变化
- **合规风险**：确保数据使用符合相关法规

## 8. 团队与资源需求

### 8.1 团队组成
- 1x 项目经理
- 2x 数据工程师
- 1x 数据科学家
- 1x 前端开发工程师
- 1x 测试工程师

### 8.2 资源需求
- 计算资源：8-16核心服务器集群
- 存储资源：初始50TB，可扩展
- 网络资源：稳定的内外网连接
- 软件许可：相关组件的商业支持

## 9. 项目时间规划

| 阶段 | 起始日期 | 结束日期 | 负责人 |
|------|---------|---------|--------|
| 阶段一：基础架构设计与ODS层 | 已完成 | 已完成 | 数据工程团队 |
| 阶段二：DWD/DIM层开发 | 已完成 | 已完成 | 数据工程团队 |
| 阶段三：DWS层开发 | T+1天 | T+21天 | 数据工程团队 |
| 阶段四：ADS层与API开发 | T+22天 | T+35天 | 全栈开发团队 |
| 阶段五：前端开发与系统集成 | T+36天 | T+49天 | 前端团队 |
| 用户验收测试 | T+50天 | T+56天 | 测试团队 |
| 系统上线 | T+57天 | | 运维团队 |

## 10. 后续扩展规划

### 10.1 功能扩展
- NFT稀有度自动评估模型
- 巨鲸社交网络分析功能
- 跨链NFT数据整合
- 高级投资策略引擎

### 10.2 技术扩展
- 图数据库集成（用于关系分析）
- AI模型优化与自学习
- 实时推荐引擎升级
- 移动端应用开发

## 11. DWS层详细开发计划

### 11.1 时间规划

| 任务 | 时间 | 资源 |
|-----|------|-----|
| 环境准备与数据库创建 | 第1周第1-2天 | 1名数据工程师 |
| dws_whale_behavior_1d开发 | 第1周第3-7天 | 2名数据工程师 |
| dws_nft_price_1d开发 | 第2周第1-5天 | 2名数据工程师 |
| dws_market_activity_1d开发 | 第2周第6-7天 + 第3周第1-3天 | 2名数据工程师 |
| 集成测试与性能优化 | 第3周第4-7天 | 1名数据工程师 + 1名测试工程师 |

### 11.2 技术要点

1. **增量计算框架**：
   - 设计Flink SQL任务，实现高效增量聚合
   - 配置滚动窗口处理，支持日级别数据更新
   - 实现延迟数据处理逻辑，保证数据完整性

2. **性能优化**：
   - 使用高效聚合函数，避免复杂窗口操作
   - 应用分桶策略提升查询性能
   - 实现数据预热机制，加速冷启动

3. **数据质量保障**：
   - 开发数据一致性检查机制
   - 构建异常值检测逻辑
   - 配置数据质量监控告警

### 11.3 关键指标实现

1. **巨鲸影响力评分算法**：
   - 交易金额权重：50%
   - 交易频率权重：20%
   - 持仓多样性权重：15%
   - 历史准确性权重：15%

2. **价格趋势预测模型**：
   - 基于近期价格变动率
   - 结合鲸鱼活动因素
   - 考虑市场整体情绪
   - 应用简单时间序列预测

3. **市场情绪指标**：
   - 买卖比例权重：40%
   - 价格动量权重：30%
   - 鲸鱼活动权重：20%
   - 交易量变化权重：10%

---

**版本控制信息：**
- 文档版本：2.0
- 创建日期：2023-03-20
- 最后更新：2023-03-21
- 审批状态：已更新 