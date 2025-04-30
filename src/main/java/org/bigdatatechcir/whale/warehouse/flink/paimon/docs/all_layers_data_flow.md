# NFT鲸鱼追踪器数据湖整体数据流转文档

## 1. 整体架构概述

NFT鲸鱼追踪器是一个采用湖仓一体架构的数据系统，通过Apache Flink和Apache Paimon技术实现，旨在追踪和分析NFT市场中的"鲸鱼"（大额持有者）行为。整个系统遵循经典的数据仓库分层设计，从数据采集到数据应用形成完整的数据处理链路。

### 1.1 系统分层架构

```
+---------------------+
|     应用层/前端     |  --> 数据可视化、API服务、交互界面
+----------^----------+
           |
+----------v----------+
|      ADS层         |  --> 应用数据服务层，直接面向应用和分析
+----------^----------+
           |
+----------v----------+
|      DWS层         |  --> 数据汇总层，多维度统计分析
+----------^----------+
           |
+-----+----v----+-----+
|     |          |     |
| DWD层 <----> DIM层  |  --> 明细数据层和维度数据层
|     |          |     |
+-----+----^-----+-----+
           |
+----------v----------+
|      ODS层         |  --> 原始数据层，数据采集和存储
+----------^----------+
           |
+----------v----------+
|    外部数据源      |  --> NFT交易API、市场数据等
+---------------------+
```

### 1.2 技术架构

- **存储引擎**：Apache Paimon (湖仓一体存储系统)
- **计算引擎**：Apache Flink (流批一体处理引擎)
- **元数据管理**：Apache Hive Metastore
- **底层存储**：HDFS
- **数据交互**：SQL、Shell脚本、REST API

## 2. 数据流转全景

### 2.1 整体数据流转路径

NFT鲸鱼追踪器的完整数据流转路径如下：

1. **数据采集阶段**：
   - 通过API调用获取NFT交易数据、钱包数据、收藏集信息
   - 将采集的JSON数据保存到ODS层

2. **数据清洗阶段**：
   - ODS层数据经过清洗后进入DWD层
   - 标准化字段、处理异常值、规范数据格式

3. **维度构建阶段**：
   - 从ODS和DWD层提取维度信息构建DIM层
   - 维护鲸鱼钱包和收藏集两大核心维度

4. **数据聚合阶段**：
   - 基于DWD明细数据和DIM维度数据进行多维度聚合计算
   - 生成面向分析的DWS汇总数据

5. **应用数据服务阶段**：
   - 根据应用需求从DWS层构建特定的ADS层数据
   - 为前端展示、API服务和分析报告提供数据支持

## 3. 各层数据流转详解

### 3.1 ODS层数据流转

ODS层（Operational Data Store，操作型数据存储）作为数据湖的入口，负责原始数据的接入和存储。

#### 3.1.1 数据来源

- NFT交易API
- 钱包排行榜API
- 收藏集信息API

#### 3.1.2 处理流程

```
API数据源 --> 数据获取(fetch_api_data.sh) --> JSON文件 --> 转换处理(load_api_data.sh) --> SQL脚本 --> 执行导入(run_all_sql.sh) --> Paimon表
```

#### 3.1.3 主要数据表

| 表名 | 说明 | 主键 | 更新策略 |
|-----|------|-----|---------|
| ods_daily_top30_transaction_collections | 当天交易数Top30收藏集 | record_time, contract_address | 每日全量 |
| ods_daily_top30_volume_collections | 当天交易额Top30收藏集 | record_time, contract_address | 每日全量 |
| ods_daily_top30_volume_wallets | 当天交易额Top30钱包 | rank_date, account_address | 每日全量 |
| ods_top100_balance_wallets | 持有金额Top100钱包 | rank_date, account_address | 每日全量 |
| ods_collection_transaction_inc | 收藏集交易数据 | record_time, hash, contract_address, token_id | 增量 |
| ods_collection_working_set | 收藏集工作集 | collection_id | 全量覆盖 |

### 3.2 DWD层数据流转

DWD层（Detail Warehouse Data，明细数据层）负责对ODS层数据进行清洗和规范化处理，构建业务明细数据。

#### 3.2.1 数据来源

- ODS层原始数据

#### 3.2.2 处理流程

```
ODS层数据 -> dwd_transaction_clean(基础清洗) -> dwd_whale_transaction_detail(鲸鱼识别)
```

#### 3.2.3 主要数据表

| 表名 | 说明 | 主键 | 数据来源 |
|-----|------|-----|---------|
| dwd_transaction_clean | 交易清洗明细表 | tx_date, tx_id, contract_address | ods_collection_transaction_inc |
| dwd_whale_transaction_detail | 鲸鱼交易明细表 | tx_date, tx_id, contract_address, token_id | dwd_transaction_clean + 鲸鱼识别 |

### 3.3 DIM层数据流转

DIM层（Dimension，维度层）负责管理和标准化维度数据，为上层的数据分析提供统一的维度口径。

#### 3.3.1 数据来源

- ODS层鲸鱼名单数据
- ODS层收藏集基本信息
- DWD层交易数据（用于更新维度状态）

#### 3.3.2 处理流程

1. **dim_whale_address处理流程**：
   - 从ODS层获取鲸鱼名单
   - 识别新增鲸鱼并创建记录
   - 基于DWD层交易数据更新活跃状态
   - 根据交易表现判定鲸鱼类型

2. **dim_collection_info处理流程**：
   - 从ODS层获取收藏集信息
   - 更新收藏集基本属性
   - 基于DWD层交易数据更新活跃状态
   - 更新工作集状态

#### 3.3.3 主要数据表

| 表名 | 说明 | 主键 | 更新策略 |
|-----|------|-----|---------|
| dim_whale_address | 鲸鱼钱包维度表 | wallet_address | 增量+状态更新 |
| dim_collection_info | 收藏集维度表 | collection_address | 增量+状态更新 |

### 3.4 DWS层数据流转

DWS层（Data Warehouse Service，数据服务层）负责基于DWD层和DIM层进行多维度汇总计算，为上层应用提供标准分析数据。

#### 3.4.1 数据来源

- DWD层明细数据
- DIM层维度数据

#### 3.4.2 处理流程

```
DWD层明细数据 ---> 多维度关联 ---> 聚合计算 ---> 统计分析 ---> DWS层表
       |                                              ^
       |                                              |
       |           DIM层维度数据 -------------------- |
```

#### 3.4.3 主要数据表

| 表名 | 说明 | 主键 | 数据来源 |
|-----|------|-----|---------|
| dws_collection_daily_stats | 收藏集每日统计表 | collection_date, contract_address | dwd_transaction_clean, dwd_whale_transaction_detail |
| dws_wallet_daily_stats | 钱包每日统计表 | wallet_date, wallet_address | dwd_transaction_clean |
| dws_whale_daily_stats | 鲸鱼每日统计表 | stat_date, wallet_address | dim_whale_address, dws_wallet_daily_stats |
| dws_collection_whale_flow | 收藏集鲸鱼资金流向表 | stat_date, collection_address, whale_type | dim_whale_address, dwd_whale_transaction_detail |
| dws_collection_whale_ownership | 收藏集鲸鱼持有统计表 | stat_date, collection_address | dim_collection_info, dwd_whale_transaction_detail |

### 3.5 ADS层数据流转

ADS层（Application Data Service，应用数据服务层）是数据仓库的最上层，直接面向应用和业务分析，提供结构化的数据服务。

#### 3.5.1 数据来源

- DWS层汇总数据
- DIM层维度数据
- DWD层明细数据（特定场景下直接使用）

#### 3.5.2 处理流程

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

#### 3.5.3 主要数据表

| ADS层表 | 说明 | 主要依赖数据源 |
|---------|-----|---------------|
| ads_top_profit_whales | 收益额Top鲸鱼 | dws_whale_daily_stats, dim_whale_address |
| ads_top_roi_whales | 收益率Top鲸鱼 | dws_whale_daily_stats, dim_whale_address |
| ads_whale_tracking_list | 鲸鱼追踪名单 | dim_whale_address, dws_whale_daily_stats |
| ads_tracking_whale_collection_flow | 收藏集鲸鱼流向Top | dws_collection_whale_flow, dim_collection_info |
| ads_smart_whale_collection_flow | 聪明鲸鱼收藏集流向 | dws_collection_whale_flow, dim_whale_address |
| ads_dumb_whale_collection_flow | 愚蠢鲸鱼收藏集流向 | dws_collection_whale_flow, dim_whale_address |
| ads_whale_transactions | 鲸鱼交易数据 | dwd_whale_transaction_detail, dim_whale_address, dws_whale_daily_stats, dws_collection_daily_stats |

## 4. 数据流转特性与优化

### 4.1 增量处理策略

1. **ODS层**：
   - 收藏集交易数据采用增量方式处理
   - 其他维度类数据每日全量刷新

2. **DWD层**：
   - 基于变更日期进行增量处理
   - 支持历史数据全量重新处理

3. **DIM层**：
   - 采用缓慢变化维度(SCD)处理方式
   - 状态字段实时更新，历史属性保留

4. **DWS层**：
   - 每日全量计算最近统计周期的聚合数据
   - 支持历史数据回溯计算

5. **ADS层**：
   - 每日全量更新排行榜类表
   - 交易明细数据采用滚动窗口机制

### 4.2 性能优化策略

1. **分区与分桶设计**：
   - 所有表均按日期分区
   - 按高频查询字段设置分桶键（如contract_address、wallet_address）
   - 主键必须包含分桶键

2. **文件合并与压缩**：
   - 设置文件合并策略（min-file-num、max-file-num、target-file-size）
   - 使用Parquet文件格式提高查询性能和存储效率

3. **SQL优化**：
   - 广泛使用CTE（WITH子句）提高SQL可读性和优化性能
   - 合理设置JOIN顺序减少中间结果集大小
   - 尽可能下推过滤条件

### 4.3 数据质量控制

1. **数据完整性检查**：
   - 关键字段空值检查
   - 主键唯一性校验
   - 日期连续性验证

2. **数据一致性检查**：
   - 上下游层级数据量核对
   - 关键指标计算一致性校验
   - 维度关联完整性检查

3. **异常处理机制**：
   - 详细的错误日志记录
   - 失败重试机制
   - 数据修复流程

## 5. 调度与监控

### 5.1 调度策略

整个数据流水线的调度策略如下：

```
ODS层数据加载 --> DWD层处理 --> DIM层更新 --> DWS层计算 --> ADS层生成
```

各层调度时间与频率：

| 层级 | 调度频率 | 调度时间 | 依赖关系 | 超时设置 |
|-----|---------|---------|---------|---------|
| ODS | 每日一次 | 凌晨00:30 | 外部API可用 | 60分钟 |
| DWD | 每日一次 | 凌晨01:30 | ODS层完成 | 60分钟 |
| DIM | 每日一次 | 凌晨02:00 | ODS层完成 | 30分钟 |
| DWS | 每日一次 | 凌晨02:30 | DWD、DIM层完成 | 90分钟 |
| ADS | 每日一次 | 凌晨04:00 | DWS层完成 | 45分钟 |

### 5.2 监控体系

1. **作业监控**：
   - Flink作业状态监控
   - 作业执行时长监控
   - 资源使用率监控

2. **数据监控**：
   - 数据量监控
   - 数据质量监控
   - 延迟监控

3. **系统监控**：
   - 集群状态监控
   - 存储容量监控
   - 系统负载监控

## 6. 总结与最佳实践

### 6.1 分层设计的优势

1. **职责清晰**：每一层都有明确定义的职责和边界
2. **数据血缘清晰**：可以轻松追踪数据的来源和流向
3. **降低耦合**：不同层次之间通过接口交互，减少相互依赖
4. **提高复用性**：中间层数据可被多个上层应用复用
5. **便于维护**：问题定位和修复更加容易

### 6.2 最佳实践

1. **保持层次边界**：
   - DWD层专注于数据清洗，不做聚合
   - DIM层专注于维度管理，不含复杂计算
   - DWS层负责汇总计算，为上层提供统一口径

2. **统一命名规范**：
   - 表名前缀反映所属层级（ods_/dwd_/dim_/dws_/ads_）
   - 字段命名保持一致性，便于理解和使用

3. **文档与注释**：
   - 保持详细的数据字典
   - SQL中添加充分注释
   - 定期更新数据流转文档

### 6.3 未来优化方向

1. **实时化处理**：
   - 逐步将批处理模式转向流式处理
   - 缩短数据更新周期

2. **自动化运维**：
   - 自动化数据质量检测与修复
   - 智能调度与资源分配

3. **深度分析能力**：
   - 接入机器学习模型
   - 开发预测性分析功能
   - 构建知识图谱增强关联分析能力 