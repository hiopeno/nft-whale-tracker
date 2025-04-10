# NFT Whale Tracker ODS层数据流转文档

## 1. 概述

本文档详细描述了NFT Whale Tracker项目中ODS层（Operational Data Store，操作型数据存储）的数据流转过程。ODS层作为项目的数据入口，负责从外部NFT API获取原始数据，并将其转换为结构化的SQL数据，最终导入到Paimon表存储系统中，为后续的数据处理和分析提供基础数据支持。

## 2. 数据流转架构

整个ODS层的数据流转过程可以分为以下几个关键步骤：

```
API数据源 -> 数据获取(fetch_api_data.sh) -> JSON文件 -> 转换处理(load_api_data.sh) -> SQL脚本 -> 执行导入(run_all_sql.sh) -> Paimon表
```

## 3. 数据表概览

ODS层包含以下主要数据表：

| 表名 | 说明 | 主键 | 数据来源 |
|-----|------|-----|---------|
| ods_daily_top30_transaction_collections | 当天交易数Top30收藏集 | record_time, contract_address | daily_top30_transaction_collections.json |
| ods_daily_top30_volume_collections | 当天交易额Top30收藏集 | record_time, contract_address | daily_top30_volume_collections.json |
| ods_daily_top30_volume_wallets | 当天交易额Top30钱包 | rank_date, account_address | daily_top30_volume_wallets.json |
| ods_top100_balance_wallets | 持有金额Top100钱包 | rank_date, account_address | top100_balance_wallets.json |
| ods_collection_transaction_inc | 收藏集交易数据 | record_time, hash, contract_address, token_id | collection_transaction_inc.json |
| ods_collection_working_set | 收藏集工作集 | collection_id | collection_working_set.json |

## 4. 详细流程

### 4.1 数据获取阶段

数据获取阶段通过`fetch_api_data.sh`脚本实现，该脚本负责从各API端点获取JSON格式的NFT相关数据。

主要功能：
- 从不同的API端点获取NFT数据
- 处理API响应，提取有用的数据部分
- 将获取的数据保存为JSON文件到`data`目录
- 记录数据获取过程的日志

获取的主要数据包括：
- 每日交易数Top30的NFT收藏集
- 每日交易额Top30的NFT收藏集
- 每日交易额Top30的钱包地址
- 持有NFT资产价值Top100的钱包地址
- NFT收藏集的交易记录
- 活跃NFT收藏集的工作集

### 4.2 数据转换阶段

数据转换阶段由`load_api_data.sh`脚本实现，该脚本将获取的JSON数据转换为SQL语句。

主要功能：
- 读取`data`目录中的各个JSON文件
- 解析JSON数据并提取相关字段
- 根据表结构定义生成创建表的SQL语句
- 将JSON数据转换为INSERT语句
- 将SQL语句保存到`sql`目录中的对应文件

主要处理流程：
1. 设置环境变量和目录路径
2. 检查所需的JSON文件是否存在
3. 定义SQL头部和各表的创建语句
4. 处理各类数据，生成对应的SQL文件：
   - `process_daily_top30_transaction_collections`：处理交易数Top30收藏集
   - `process_daily_top30_volume_collections`：处理交易额Top30收藏集
   - `process_daily_top30_volume_wallets`：处理交易额Top30钱包
   - `process_top100_balance_wallets`：处理持有金额Top100钱包
   - `process_collection_transaction_inc`：处理收藏集交易数据
   - `process_collection_working_set`：处理收藏集工作集数据
5. 生成汇总报告

每个数据处理函数的基本流程：
- 读取对应的JSON文件
- 创建SQL文件头部，包含建表语句
- 遍历JSON数据，提取字段并生成INSERT语句
- 如数据为空，添加样本数据
- 保存完整SQL文件

### 4.3 数据导入阶段

数据导入阶段由`run_all_sql.sh`脚本实现，该脚本负责执行生成的SQL文件，将数据导入到Paimon表中。

主要功能：
- 设置Flink环境和依赖JAR包
- 遍历`sql`目录中的所有SQL文件
- 使用Flink SQL Client执行每个SQL文件
- 记录执行过程和结果

主要流程：
1. 设置Flink相关环境变量和依赖JAR包
2. 创建日志目录
3. 遍历并执行SQL目录下的所有SQL文件（排除备份文件）
4. 记录每个SQL文件的执行结果
5. 输出整体执行情况汇总

## 5. 数据表结构详解

### 5.1 ods_daily_top30_transaction_collections（当天交易数Top30收藏集）

该表存储每日交易数量排名前30的NFT收藏集信息。

主要字段：
- `record_time`: 记录时间
- `contract_address`: 合约地址
- `contract_name`: 合约名称
- `symbol`: 代币符号
- `logo_url`: Logo URL
- `banner_url`: Banner URL
- `items_total`: 总项目数
- `owners_total`: 总持有者数
- `verified`: 是否验证
- `opensea_verified`: 是否OpenSea验证
- `sales_1d/7d/30d/total`: 1日/7日/30日/总销售量
- `volume_1d/7d/30d/total`: 1日/7日/30日/总交易额
- `floor_price`: 地板价
- `market_cap`: 市值

### 5.2 ods_daily_top30_volume_collections（当天交易额Top30收藏集）

该表存储每日交易额排名前30的NFT收藏集信息，字段结构与`ods_daily_top30_transaction_collections`相同。

### 5.3 ods_daily_top30_volume_wallets（当天交易额Top30钱包）

该表存储每日交易额排名前30的钱包地址信息。

主要字段：
- `rank_date`: 排名日期
- `account_address`: 钱包地址
- `rank_num`: 排名
- `trade_volume`: 交易量
- `trade_volume_usdc`: USDC交易量
- `trade_count`: 交易次数
- `is_whale`: 是否为巨鲸
- `created_at`: 创建时间

### 5.4 ods_top100_balance_wallets（持有金额Top100钱包）

该表存储持有NFT资产价值排名前100的钱包地址信息。

主要字段：
- `rank_date`: 排名日期
- `account_address`: 钱包地址
- `rank_num`: 排名
- `holding_volume`: 持有量
- `buy_volume`: 购买量
- `sell_volume`: 出售量
- `realized_gains_volume`: 已实现收益
- `holding_collections`: 持有收藏集数量
- `holding_nfts`: 持有NFT数量
- `trade_count`: 交易次数

### 5.5 ods_collection_transaction_inc（收藏集交易数据）

该表存储NFT收藏集的详细交易记录。

主要字段：
- `record_time`: 记录时间
- `hash`: 交易哈希
- `from_address`: 发送方地址
- `to_address`: 接收方地址
- `block_number`: 区块号
- `block_hash`: 区块哈希
- `contract_address`: 合约地址
- `contract_name`: 合约名称
- `token_id`: 代币ID
- `trade_price`: 交易价格
- `trade_symbol`: 交易代币符号
- `event_type`: 事件类型
- `exchange_name`: 交易所名称

### 5.6 ods_collection_working_set（收藏集工作集）

该表存储活跃NFT收藏集的工作集数据。

主要字段：
- `collection_id`: 收藏集ID
- `collection_address`: 收藏集地址
- `collection_name`: 收藏集名称
- `logo_url`: Logo URL
- `first_added_date`: 首次添加日期
- `last_updated_date`: 最后更新日期
- `last_active_date`: 最后活跃日期
- `source`: 来源
- `status`: 状态
- `floor_price`: 地板价
- `volume_1d/7d`: 1日/7日交易额
- `sales_1d/7d`: 1日/7日销售量
- `update_count`: 更新计数

## 6. 执行流程与监控

### 6.1 完整执行流程

1. 获取API数据：
   ```bash
   ./fetch_api_data.sh
   ```

2. 转换数据为SQL：
   ```bash
   ./load_api_data.sh
   ```

3. 执行SQL导入数据：
   ```bash
   ./run_all_sql.sh
   ```

### 6.2 监控与维护

- 执行日志：所有脚本执行的日志保存在`logs`目录下
- SQL文件：生成的SQL文件保存在`sql`目录下
- 数据文件：获取的JSON数据保存在`data`目录下
- 清理数据：使用`clean_ods.sh`可以清理ODS层数据（慎用）

### 6.3 错误处理

- 数据获取失败：检查API接口是否可用，网络连接是否正常
- 数据转换失败：检查JSON数据格式是否正确，`load_api_data.sh`脚本是否有错误
- 数据导入失败：检查Flink环境是否正常，SQL语法是否正确，Paimon表是否已存在

## 7. 运维建议

1. 定期执行数据同步，保持数据的时效性
2. 监控日志文件，及时发现并解决问题
3. 定期备份重要的JSON数据和SQL文件
4. 使用Flink Dashboard监控Flink作业状态
5. 如数据出现问题，可以使用备份的JSON数据重新生成SQL并导入

## 8. 参考资料

- [Flink SQL文档](https://nightlies.apache.org/flink/flink-docs-master/docs/dev/table/sql/overview/)
- [Paimon文档](https://paimon.apache.org/docs/master/filesystem/paimon-overview/)
- [NFT API文档](https://docs.nftscan.com/reference/overview) 