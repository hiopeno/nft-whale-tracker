# NFT巨鲸钱包追踪系统 - ADS层开发计划

## 1. 项目背景与目标

### 1.1 背景概述
数据仓库ODS、DWD/DIM、DWS层已经完成开发，现在需要开发ADS应用数据服务层，直接为业务决策提供支持。ADS层将整合和优化下层数据，构建面向特定业务场景的数据产品。

### 1.2 开发目标
- 实现三个核心ADS应用表：巨鲸追踪看板、低价狙击机会表、策略推荐表
- 开发与业务系统集成的API接口
- 设计告警和通知机制
- 构建交易决策支持系统

### 1.3 业务价值
- 显著降低交易决策时间，实现准实时响应
- 提高投资收益率，预计可提升15-30%
- 降低交易风险，通过多维度分析避免有害投资
- 为后续智能交易系统奠定数据基础

## 2. ADS层设计方案

### 2.1 数据表设计

#### 2.1.1 巨鲸追踪看板表 (ads_whale_tracking_dashboard)
```sql
CREATE TABLE IF NOT EXISTS ads.ads_whale_tracking_dashboard (
  `wallet_address` STRING,
  `update_time` TIMESTAMP(3),
  `wallet_label` STRING,                 -- 钱包标签
  `recent_activity_summary` STRING,      -- 近期活动摘要(JSON)
  `holdings_change_30d` DOUBLE,          -- 30天持仓变化
  `influence_score` DOUBLE,              -- 影响力评分
  `activity_alert_level` STRING,         -- 活动预警等级
  `preferred_collections` STRING,        -- 偏好收藏品(JSON)
  `prediction_signals` STRING,           -- 预测信号(JSON)
  `tracking_priority` INT,               -- 追踪优先级
  PRIMARY KEY (`wallet_address`) NOT ENFORCED
) WITH (
  'bucket' = '4',
  'bucket-key' = 'wallet_address',
  'file.format' = 'parquet',
  'merge-engine' = 'deduplicate',
  'changelog-producer' = 'input'
);
```

#### 2.1.2 低价狙击机会表 (ads_bargain_opportunity)
```sql
CREATE TABLE IF NOT EXISTS ads.ads_bargain_opportunity (
  `opportunity_id` STRING,
  `nft_id` STRING,
  `collection_id` STRING,
  `discovery_time` TIMESTAMP(3),
  `current_price` DOUBLE,
  `market_reference_price` DOUBLE,
  `discount_percentage` DOUBLE,
  `urgency_score` DOUBLE,              -- 紧急度评分
  `investment_value_score` DOUBLE,     -- 投资价值评分
  `risk_score` DOUBLE,                 -- 风险评分
  `opportunity_window` STRING,         -- 机会窗口期
  `marketplace` STRING,                -- 交易平台
  `status` STRING,                     -- 状态(ACTIVE/EXPIRED)
  PRIMARY KEY (`opportunity_id`) NOT ENFORCED
) WITH (
  'bucket' = '8',
  'bucket-key' = 'opportunity_id',
  'file.format' = 'parquet',
  'merge-engine' = 'deduplicate',
  'changelog-producer' = 'input'
);
```

#### 2.1.3 策略推荐表 (ads_strategy_recommendation)
```sql
CREATE TABLE IF NOT EXISTS ads.ads_strategy_recommendation (
  `strategy_id` STRING,
  `strategy_type` STRING,              -- BUY/SELL/HOLD
  `generation_time` TIMESTAMP(3),
  `expiry_time` TIMESTAMP(3),
  `target_entity` STRING,              -- NFT/Collection
  `entity_id` STRING,
  `recommended_action` STRING,
  `price_range` STRING,                -- JSON格式价格区间
  `expected_return_rate` DOUBLE,
  `success_probability` DOUBLE,
  `rationale` STRING,                  -- 推荐理由
  `market_context` STRING,             -- 市场背景(JSON)
  PRIMARY KEY (`strategy_id`) NOT ENFORCED
) WITH (
  'bucket' = '8',
  'bucket-key' = 'strategy_id',
  'file.format' = 'parquet',
  'merge-engine' = 'deduplicate',
  'changelog-producer' = 'input'
);
```

### 2.2 数据处理逻辑设计

#### 2.2.1 巨鲸追踪看板
- 数据来源：dws_whale_behavior_1d、dim_wallet_full
- 更新频率：1小时
- 关键计算：
  - 近期活动摘要：7天内交易统计
  - 30天持仓变化：对net_position_change累计
  - 影响力评分：取最近7天最高分
  - 活动预警：基于abnormal_activity_score阈值判断
  - 追踪优先级：影响力与异常活动加权排序

#### 2.2.2 低价狙击机会
- 数据来源：dws_nft_price_1d、dwd_nft_transaction_inc
- 更新频率：15分钟
- 关键计算：
  - 折扣百分比：基于当前价格与参考价格
  - 紧急度评分：价格折扣和市场热度加权
  - 投资价值评分：价格动量和鲸鱼关注度加权
  - 风险评分：价格波动率和流动性加权
  - 机会窗口：基于价格波动率分级

#### 2.2.3 策略推荐
- 数据来源：ads_bargain_opportunity、dws_whale_behavior_1d、dws_nft_price_1d
- 更新频率：1小时
- 关键计算：
  - 买入策略：基于折扣率和投资价值评分
  - 卖出策略：基于鲸鱼抛售信号和价格动量
  - 持有策略：基于市场情绪和价格稳定性
  - 成功概率：多因素综合评估
  - 市场背景：整合市场情绪、鲸鱼活动和交易量趋势

## 3. 开发计划与时间表

### 3.1 第一阶段：基础架构与ADS表创建 (3天)
| 任务 | 时间 | 负责人 |
|------|------|--------|
| ADS数据库创建 | 0.5天 | 数据工程师 |
| 巨鲸追踪看板表结构开发 | 0.5天 | 数据工程师 |
| 低价狙击机会表结构开发 | 0.5天 | 数据工程师 |
| 策略推荐表结构开发 | 0.5天 | 数据工程师 |
| 数据流设计与测试 | 1天 | 数据工程师 |

### 3.2 第二阶段：ADS表实现与优化 (5天)
| 任务 | 时间 | 负责人 |
|------|------|--------|
| 巨鲸追踪看板SQL实现 | 1天 | 数据工程师 |
| 低价狙击机会SQL实现 | 1天 | 数据工程师 |
| 策略推荐SQL实现 | 1.5天 | 数据工程师 |
| 性能测试与优化 | 1天 | 数据工程师 |
| 增量更新逻辑实现 | 0.5天 | 数据工程师 |

### 3.3 第三阶段：API接口开发 (3天)
| 任务 | 时间 | 负责人 |
|------|------|--------|
| API架构设计 | 0.5天 | 全栈开发工程师 |
| 巨鲸追踪API实现 | 0.5天 | 全栈开发工程师 |
| 低价狙击API实现 | 0.5天 | 全栈开发工程师 |
| 策略推荐API实现 | 0.5天 | 全栈开发工程师 |
| 安全与性能优化 | 1天 | 全栈开发工程师 |

### 3.4 第四阶段：告警系统开发 (3天)
| 任务 | 时间 | 负责人 |
|------|------|--------|
| 告警规则设计 | 0.5天 | 数据分析师 |
| 告警触发机制实现 | 1天 | 全栈开发工程师 |
| 通知渠道集成 | 1天 | 全栈开发工程师 |
| 告警优先级机制 | 0.5天 | 数据分析师 |

### 3.5 第五阶段：集成测试与部署 (2天)
| 任务 | 时间 | 负责人 |
|------|------|--------|
| 调度脚本开发 | 0.5天 | 数据工程师 |
| 集成测试 | 1天 | 测试工程师 |
| 生产环境部署 | 0.5天 | 运维工程师 |

## 4. 技术实现细节

### 4.1 数据更新流程
```
                   +---------------+
                   |  Flink SQL    |
                   | 定时任务(ADS层)|
                   +-------+-------+
                           |
                           v
                   +---------------+
                   |   Paimon      |
                   | (ADS层数据表)  |
                   +-------+-------+
                           |
         +----------------+----------------+
         |                |                |
+----------------+ +----------------+ +----------------+
|  巨鲸追踪API    | |   低价狙击API   | |  策略推荐API    |
+-------+--------+ +--------+-------+ +--------+-------+
         |                |                |
         +----------------+----------------+
                           |
                           v
                   +---------------+
                   |  告警系统     |
                   | (基于规则引擎) |
                   +-------+-------+
                           |
                           v
                   +---------------+
                   |  消息推送     |
                   | (邮件/短信/APP)|
                   +---------------+
```

### 4.2 巨鲸追踪看板SQL实现
```sql
-- 完整SQL实现将在开发阶段提供
INSERT INTO ads.ads_whale_tracking_dashboard
SELECT
  w.wallet_address,
  CURRENT_TIMESTAMP AS update_time,
  d.wallet_label,
  -- 构建近期活动摘要JSON
  CONCAT('{"buy_count_7d":', CAST(SUM(CASE WHEN TO_DAYS(CURRENT_TIMESTAMP) - TO_DAYS(wb.dt) <= 7 THEN wb.buy_count ELSE 0 END) AS STRING),
         ',"sell_count_7d":', CAST(SUM(CASE WHEN TO_DAYS(CURRENT_TIMESTAMP) - TO_DAYS(wb.dt) <= 7 THEN wb.sell_count ELSE 0 END) AS STRING),
         ',"volume_7d":', CAST(SUM(CASE WHEN TO_DAYS(CURRENT_TIMESTAMP) - TO_DAYS(wb.dt) <= 7 THEN (wb.buy_value_usd + wb.sell_value_usd) ELSE 0 END) AS STRING),
         ',"pattern":"', MAX(CASE WHEN TO_DAYS(CURRENT_TIMESTAMP) - TO_DAYS(wb.dt) <= 3 THEN wb.transaction_pattern ELSE '' END), '"}') AS recent_activity_summary,
  -- 其他字段计算逻辑...
FROM 
  (SELECT DISTINCT wallet_address FROM dws.dws_whale_behavior_1d) w
JOIN dws.dws_whale_behavior_1d wb ON w.wallet_address = wb.wallet_address
JOIN dim.dim_wallet_full d ON w.wallet_address = d.address
GROUP BY w.wallet_address, d.wallet_label, d.preferred_collections;
```

### 4.3 告警规则设计
1. **紧急低价机会告警**
   - 触发条件：`urgency_score > 0.8 AND discount_percentage > 30`
   - 优先级：高
   - 渠道：APP推送、短信

2. **鲸鱼异常活动告警**
   - 触发条件：`activity_alert_level = 'HIGH_ALERT' AND influence_score > 0.7`
   - 优先级：高
   - 渠道：APP推送

3. **高成功率策略告警**
   - 触发条件：`success_probability > 0.8 AND expected_return_rate > 0.2`
   - 优先级：中
   - 渠道：APP推送、邮件

4. **市场趋势变化告警**
   - 触发条件：多个鲸鱼预测信号一致且与前期相反
   - 优先级：中
   - 渠道：邮件

## 5. API设计

### 5.1 API架构
- RESTful API设计
- JWT认证
- 缓存机制
- 速率限制

### 5.2 主要接口
1. **巨鲸追踪接口**
   - `GET /api/v1/whales` - 获取鲸鱼列表
   - `GET /api/v1/whales/{address}` - 获取特定鲸鱼详情
   - `GET /api/v1/whales/alerts` - 获取鲸鱼活动告警

2. **低价机会接口**
   - `GET /api/v1/opportunities` - 获取所有机会
   - `GET /api/v1/opportunities/{id}` - 获取特定机会详情
   - `GET /api/v1/opportunities/urgent` - 获取紧急机会

3. **策略推荐接口**
   - `GET /api/v1/strategies` - 获取所有策略
   - `GET /api/v1/strategies/{id}` - 获取特定策略详情
   - `GET /api/v1/strategies/types/{type}` - 获取特定类型策略

## 6. 风险与挑战

### 6.1 技术风险
- **数据延迟风险**：ADS层需要实时响应，数据延迟将影响决策
  - 缓解措施：实现数据处理监控，设置SLA警报

- **计算性能风险**：复杂计算可能导致处理延迟
  - 缓解措施：优化SQL，考虑分区策略，增加计算资源

- **数据质量风险**：下游依赖ADS数据质量
  - 缓解措施：实现数据质量检查，定期验证计算准确性

### 6.2 业务风险
- **告警噪音风险**：过多的告警会导致决策疲劳
  - 缓解措施：动态调整告警阈值，实现优先级排序

- **策略准确性风险**：投资策略受多因素影响，准确性有限
  - 缓解措施：持续回测与优化，增加置信度指标

## 7. 后续扩展规划

### 7.1 功能扩展
- **个性化推荐引擎**：基于用户偏好定制投资策略
- **趋势预测模型**：整合机器学习模型提升预测准确性
- **社交信号整合**：监控社交媒体信号，关联鲸鱼活动
- **多链数据支持**：扩展至其他区块链的NFT数据

### 7.2 技术扩展
- **实时流处理增强**：优化告警触发速度
- **图数据分析**：实现鲸鱼关系网络分析
- **高级可视化**：开发专业交易视图
- **智能交易执行**：与交易所API集成，实现自动交易

## 8. 交付验收标准

1. **功能验收**
   - 所有ADS表数据更新正常
   - API接口按规范实现并通过测试
   - 告警系统能及时触发并推送消息

2. **性能验收**
   - ADS表更新延迟不超过规定SLA
   - API响应时间<200ms (95%请求)
   - 告警触发延迟<1分钟

3. **业务验收**
   - 低价机会识别准确率>80%
   - 策略推荐回测收益率高于基准指标
   - 巨鲸追踪信号提前量符合预期

## 9. 资源需求

- 1名高级数据工程师 (全职，2周)
- 1名全栈开发工程师 (全职，2周)
- 1名数据分析师 (兼职，1周)
- 1名测试工程师 (兼职，3天)
- 1名运维工程师 (兼职，1天)

---

**版本控制信息：**
- 文档版本：1.0
- 创建日期：2023-05-16
- 编制人：数据工程团队
- 审批状态：待审批 