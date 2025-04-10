# NFT Whale Tracker ODS层

## 简介

ODS层（Operational Data Store，操作型数据存储）是NFT Whale Tracker项目的数据入口层，负责从各种NFT API接口获取原始数据，并将其转换、加载到Paimon表中。ODS层保留了原始数据的完整性，不进行复杂的数据加工和计算，为后续的DWD、DWS和ADS层提供基础数据。

## 目录结构

```
ods/
├── data/              # 存放从API获取的JSON数据
├── docs/              # 文档目录
│   ├── README.md      # 本文件
│   ├── ods_data_flow.md       # 数据流转文档
│   └── ods_data_dictionary.md # 数据字典文档
├── logs/              # 存放脚本执行日志
├── sql/               # 存放生成的SQL文件
├── fetch_api_data.sh  # 从API获取数据的脚本
├── load_api_data.sh   # 将数据转换为SQL的脚本
├── run_all_sql.sh     # 执行SQL文件的脚本
└── clean_ods.sh       # 清理ODS层数据的脚本
```

## 数据表

ODS层包含以下主要数据表：

1. **ods_daily_top30_transaction_collections**: 当天交易数Top30收藏集
2. **ods_daily_top30_volume_collections**: 当天交易额Top30收藏集
3. **ods_daily_top30_volume_wallets**: 当天交易额Top30钱包
4. **ods_top100_balance_wallets**: 持有金额Top100钱包
5. **ods_collection_transaction_inc**: 收藏集交易数据
6. **ods_collection_working_set**: 收藏集工作集

## 数据流转流程

```
API数据源 → 获取数据(fetch_api_data.sh) → JSON文件 → 转换处理(load_api_data.sh) → SQL脚本 → 执行导入(run_all_sql.sh) → Paimon表
```

## 使用方法

### 1. 获取API数据

```bash
cd /root/nft-whale-tracker/src/main/java/org/bigdatatechcir/whale/warehouse/flink/paimon/ods
./fetch_api_data.sh
```

该脚本将从NFT API获取数据，并保存为JSON文件到`data/`目录。

### 2. 转换数据为SQL

```bash
./load_api_data.sh
```

该脚本将读取`data/`目录中的JSON文件，转换为SQL语句，并保存到`sql/`目录。

### 3. 执行SQL导入数据

```bash
./run_all_sql.sh
```

该脚本将执行`sql/`目录中的SQL文件，将数据导入到Paimon表中。

### 4. 一步执行所有流程

```bash
./fetch_api_data.sh && ./load_api_data.sh && ./run_all_sql.sh
```

### 5. 清理ODS层数据（慎用）

```bash
./clean_ods.sh
```

该脚本将清理ODS层的数据，包括SQL文件和Paimon表。

## 文档说明

- **ods_data_flow.md**: 详细描述了ODS层的数据流转过程，包括数据获取、转换和加载的详细步骤。
- **ods_data_dictionary.md**: 详细描述了ODS层中各个表的字段定义、数据类型和业务含义。

## 依赖环境

- Apache Flink 1.18.1
- Paimon (flink-1.18版本)
- JQ (用于JSON处理)
- Bash (4.2+)

## 注意事项

1. 执行脚本前，确保Hadoop、Hive Metastore和Flink服务已启动。
2. 数据导入操作可能会覆盖现有数据，请谨慎使用。
3. 如需自定义API数据源，请修改`fetch_api_data.sh`脚本中的相关配置。
4. 所有脚本执行过程均会记录到`logs/`目录中。

## 故障排查

1. **API数据获取失败**
   - 检查网络连接是否正常
   - 检查API接口是否可用
   - 查看`logs/fetch_api_data.log`日志文件

2. **数据转换失败**
   - 检查JSON文件格式是否正确
   - 检查`load_api_data.sh`脚本是否有错误
   - 查看`logs/load_api_data.log`日志文件

3. **SQL执行失败**
   - 检查Flink环境是否正常
   - 检查SQL语法是否正确
   - 查看`logs/`目录下对应的SQL执行日志文件

## 后续开发

ODS层的数据将被用于以下后续处理：
- DWD层(Data Warehouse Detail): 细粒度的明细数据层
- DWS层(Data Warehouse Service): 服务数据层，包含聚合计算
- ADS层(Application Data Service): 应用数据服务层，为前端应用提供数据支持 