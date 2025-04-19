# NFT Whale Tracker 数据湖架构

## 1. 项目概述

NFT Whale Tracker是一个基于Flink和Paimon的NFT交易数据分析系统，用于实时跟踪NFT市场中的"鲸鱼"（大额持有者）活动。系统从NFT API接口获取交易数据，经过多层处理形成完整的数据湖，为NFT市场提供分析洞察、鲸鱼跟踪和市场趋势预测等功能。

### 1.1 核心功能

- NFT鲸鱼地址识别与跟踪
- NFT收藏集热度分析与预警
- 鲸鱼资金流向监控
- NFT市场趋势分析
- 收藏集价格波动预测

### 1.2 技术栈

- **数据处理框架**：Apache Flink (1.18.1+)
- **数据存储**：Apache Paimon
- **批处理支持**：Flink SQL
- **元数据管理**：Hive Metastore
- **资源管理**：YARN/Kubernetes
- **数据获取**：Shell脚本 + REST API
- **数据导出**：Flink CDC

## 2. 数据湖分层架构

NFT Whale Tracker项目采用经典的数据湖分层架构，包括：

### 2.1 ODS层（Operational Data Store）

**职责**：原始数据存储层，保留从API获取的原始数据，不进行复杂处理，确保数据的完整性和可溯源性。

**主要表**：
- `ods_daily_top30_transaction_collections`: 当天交易数Top30收藏集
- `ods_daily_top30_volume_collections`: 当天交易额Top30收藏集
- `ods_daily_top30_volume_wallets`: 当天交易额Top30钱包
- `ods_top100_balance_wallets`: 持有金额Top100钱包
- `ods_collection_transaction_inc`: 收藏集交易数据
- `ods_collection_working_set`: 收藏集工作集

**数据流转**：`API数据源 → 获取数据(fetch_api_data.sh) → JSON文件 → 转换处理(load_api_data.sh) → SQL脚本 → 执行导入(run_all_sql.sh) → Paimon表`

### 2.2 DWD层（Data Warehouse Detail）

**职责**：数据明细层，对ODS层数据进行清洗、转换和规范化处理，形成业务明细数据。

**主要表**：
- `dwd_whale_transaction_detail`: 鲸鱼交易明细表
- `dwd_collection_daily_stats`: 收藏集每日统计表
- `dwd_wallet_daily_stats`: 钱包每日统计表
- `dwd_market_daily_summary`: 市场每日汇总表

**数据流转**：`ODS层数据 → 数据清洗与转换 → 数据标准化与规范化 → 数据质量检查 → DWD层表`

### 2.3 DIM层（Dimension）

**职责**：维度层，存储各类业务维度信息，为事实表提供分析视角。

**主要表**：
- `dim_collection_info`: 收藏集信息维度表
- `dim_whale_address`: 鲸鱼地址维度表
- `dim_exchange_platform`: 交易平台维度表
- `dim_collection_category`: 收藏集分类维度表

**数据流转**：`ODS/DWD层数据 → 维度抽取 → 维度建模 → 缓慢变化维处理 → DIM层表`

### 2.4 DWS层（Data Warehouse Service）

**职责**：服务层，基于DWD和DIM层数据进行多维度聚合分析，形成面向特定主题的汇总数据。

**主要表**：
- `dws_whale_daily_stats`: 鲸鱼每日统计汇总表
- `dws_collection_whale_flow`: 收藏集鲸鱼资金流向表
- `dws_market_trend_analysis`: 市场趋势分析表
- `dws_collection_performance`: 收藏集表现汇总表

**数据流转**：`DWD/DIM层数据 → 多维度关联 → 聚合计算 → 统计分析 → DWS层表`

### 2.5 ADS层（Application Data Service）

**职责**：应用层，面向具体业务场景的统计指标，直接为前端应用提供数据支持。

**主要表**：
- `ads_whale_movement_alerts`: 鲸鱼异动预警表
- `ads_hot_collections_prediction`: 热门收藏集预测表
- `ads_whale_influence_rankings`: 鲸鱼影响力排行表
- `ads_market_insight_dashboard`: 市场洞察仪表盘数据表
- `ads_potential_profit_opportunities`: 潜在利润机会表

**数据流转**：`DWS层数据 → 指标计算 → 模型预测 → 指标加工 → ADS层表`

## 3. 数据流程

### 3.1 数据获取流程

1. **API数据获取**：通过`fetch_api_data.sh`脚本从NFT API获取各类数据
2. **数据转换**：通过`load_api_data.sh`脚本将JSON数据转换为SQL语句
3. **数据导入**：通过`run_all_sql.sh`脚本执行SQL语句，将数据导入Paimon表

### 3.2 数据处理流程

1. **ODS到DWD**：清洗、转换原始数据，生成明细数据
2. **明细到维度**：从原始和明细数据中抽取维度信息
3. **数据服务化**：基于明细和维度数据进行多维聚合分析
4. **应用数据**：基于服务层数据生成面向应用的指标

### 3.3 实时与离线处理

- **实时处理**：通过Flink实时流式处理关键指标
- **批量处理**：通过Flink SQL处理历史数据或高复杂度计算

## 4. 目录结构

```
warehouse/
├── flink/
│   └── paimon/
│       ├── ods/            # 原始数据层
│       │   ├── data/       # 存放JSON数据
│       │   ├── docs/       # ODS层文档
│       │   ├── logs/       # 日志文件
│       │   ├── sql/        # SQL脚本
│       │   └── scripts/    # 数据处理脚本
│       ├── dwd/            # 数据明细层
│       │   ├── docs/       # DWD层文档
│       │   ├── sql/        # SQL脚本
│       │   └── scripts/    # 处理脚本
│       ├── dim/            # 维度层
│       │   ├── docs/       # DIM层文档
│       │   ├── sql/        # SQL脚本
│       │   └── scripts/    # 维度处理脚本
│       ├── dws/            # 数据服务层
│       │   ├── docs/       # DWS层文档
│       │   ├── sql/        # SQL脚本
│       │   └── scripts/    # 服务计算脚本
│       └── ads/            # 应用数据层
│           ├── docs/       # ADS层文档
│           ├── sql/        # SQL脚本
│           └── scripts/    # 应用计算脚本
└── docs/                   # 数据湖整体文档
```

## 5. 主要数据表说明

### 5.1 ODS层表

- **ods_daily_top30_transaction_collections**：每日交易数Top30的NFT收藏集数据
- **ods_daily_top30_volume_collections**：每日交易额Top30的NFT收藏集数据
- **ods_daily_top30_volume_wallets**：每日交易额Top30的钱包地址数据
- **ods_top100_balance_wallets**：持有NFT资产价值Top100的钱包地址数据
- **ods_collection_transaction_inc**：NFT收藏集的交易记录数据
- **ods_collection_working_set**：活跃NFT收藏集的工作集数据

### 5.2 DWD层表

- **dwd_whale_transaction_detail**：与潜在鲸鱼相关的NFT交易明细数据
- **dwd_collection_daily_stats**：NFT收藏集的每日统计数据
- **dwd_wallet_daily_stats**：钱包的每日交易统计数据
- **dwd_market_daily_summary**：NFT市场的每日汇总数据

### 5.3 DIM层表

- **dim_collection_info**：NFT收藏集的维度信息
- **dim_whale_address**：鲸鱼钱包地址的维度信息
- **dim_exchange_platform**：交易平台的维度信息
- **dim_collection_category**：收藏集分类的维度信息

### 5.4 DWS层表

- **dws_whale_daily_stats**：鲸鱼钱包的每日交易汇总数据
- **dws_collection_whale_flow**：收藏集的鲸鱼资金流向数据
- **dws_market_trend_analysis**：NFT市场趋势分析数据
- **dws_collection_performance**：收藏集表现汇总数据

### 5.5 ADS层表

- **ads_whale_movement_alerts**：鲸鱼异动预警数据
- **ads_hot_collections_prediction**：热门收藏集预测数据
- **ads_whale_influence_rankings**：鲸鱼影响力排行数据
- **ads_market_insight_dashboard**：市场洞察仪表盘数据
- **ads_potential_profit_opportunities**：潜在利润机会数据

## 6. 系统部署与运行

### 6.1 环境要求

- Apache Flink 1.18.1+
- Apache Hadoop 3.3.4+
- Apache Hive Metastore
- Paimon (Flink-1.18版本)
- JDK 11+
- Python 3.8+
- JQ (用于JSON处理)
- Bash 4.2+

### 6.2 部署流程

1. 环境准备：确保Hadoop、Hive Metastore和Flink环境已正确配置
2. 部署代码：将项目代码部署到集群主节点
3. 配置权限：确保脚本有执行权限
4. 启动服务：启动Hadoop和Flink服务
5. 初始化库表：执行初始化脚本创建所需的表结构

### 6.3 运行流程

1. 数据获取：`cd /path/to/ods && ./fetch_api_data.sh`
2. 数据转换：`./load_api_data.sh`
3. 数据导入：`./run_all_sql.sh`
4. 数据处理：分别在各层执行`run_all_sql.sh`处理数据
5. 数据应用：执行ADS层的`run_ads_flink_jobs.sh`生成应用数据

## 7. 监控与维护

### 7.1 日志管理

- 各层的操作日志存放在对应的`logs`目录中
- 可以通过日志监控脚本执行情况和错误

### 7.2 数据质量管理

- 数据一致性检查：通过比对不同层的记录数
- 数据完整性检查：通过计算空值比例和数据覆盖度
- 数据准确性检查：通过业务规则验证数据

### 7.3 故障处理

1. API数据获取失败：检查网络和API接口状态
2. 数据转换失败：检查JSON格式和转换脚本
3. SQL执行失败：检查SQL语法和Flink环境
4. 数据处理失败：检查依赖数据和处理逻辑

## 8. 开发指南

### 8.1 添加新数据源

1. 在`fetch_api_data.sh`中添加新的API调用
2. 在`load_api_data.sh`中添加新的数据处理逻辑
3. 更新相应的SQL创建脚本
4. 更新文档和数据字典

### 8.2 添加新分析指标

1. 根据需求确定数据应在哪一层处理
2. 编写相应的SQL脚本（创建表和数据处理）
3. 更新数据流转文档和数据字典
4. 测试新指标的计算准确性

## 9. 参考文档

- [Flink SQL文档](https://nightlies.apache.org/flink/flink-docs-master/docs/dev/table/sql/overview/)
- [Paimon文档](https://paimon.apache.org/docs/master/filesystem/paimon-overview/)
- [NFT API文档](https://docs.nftscan.com/reference/overview)

每个层级还有详细的文档：
- ODS层：详见 `flink/paimon/ods/docs/`
- DWD层：详见 `flink/paimon/dwd/docs/`
- DIM层：详见 `flink/paimon/dim/docs/`
- DWS层：详见 `flink/paimon/dws/docs/`
- ADS层：详见 `flink/paimon/ads/docs/` 