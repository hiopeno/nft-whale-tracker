# NFT鲸鱼追踪器 - DWS层

## 概述

DWS层（Data Warehouse Service，数据服务层）是NFT鲸鱼追踪器数据湖架构中的关键层级，负责基于DWD层和DIM层进行多维度汇总计算，提供标准分析数据。根据重构指南，DWS层承担了从DWD和DIM层迁移的所有聚合计算功能，为上层应用提供统一的数据服务。

## 目录结构

```
dws/
├── docs/                  # 文档目录
│   ├── dws_data_dictionary.md      # 数据字典（老版本）
│   ├── dws_data_flow.md            # 数据流转文档（老版本）
│   └── dws_restructuring_note.md   # 重构说明文档（新增）
├── logs/                  # 日志目录
├── scripts/               # 辅助脚本目录
├── sql/                   # SQL脚本目录
│   ├── dws_collection_daily_stats.sql   # 收藏集每日统计表SQL
│   ├── dws_wallet_daily_stats.sql       # 钱包每日统计表SQL
│   ├── dws_whale_daily_stats.sql        # 鲸鱼每日统计表SQL
│   ├── dws_collection_whale_flow.sql    # 收藏集鲸鱼资金流向表SQL
│   └── dws_collection_whale_ownership.sql # 收藏集鲸鱼持有统计表SQL
└── run_all_sql.sh         # SQL执行脚本
```

## 重构说明

本层级已根据《NFT鲸鱼追踪器数据湖重构指南》进行了重构，主要变化包括：

1. **表结构调整**：
   - 保留并优化了`dws_whale_daily_stats`和`dws_collection_whale_flow`表
   - 从DWD层迁移并增强了`dws_collection_daily_stats`和`dws_wallet_daily_stats`表
   - 新增了`dws_collection_whale_ownership`表

2. **明确数据处理流程**：
   - DWS层直接从DWD层获取明细数据进行聚合
   - 通过DIM层获取维度信息进行丰富
   - 建立清晰的数据依赖关系

3. **指标计算统一**：
   - 将所有聚合计算统一到DWS层实现
   - 提供标准的指标计算口径
   - 支持多维度的数据分析

## 数据表说明

### 1. dws_collection_daily_stats

**表说明**：存储收藏集每日汇总统计数据（从DWD层迁移）

**主键**：collection_date, contract_address

**数据来源**：dwd.dwd_transaction_clean, dwd.dwd_whale_transaction_detail

### 2. dws_wallet_daily_stats

**表说明**：存储钱包每日汇总统计数据（从DWD层迁移）

**主键**：wallet_date, wallet_address

**数据来源**：dwd.dwd_transaction_clean, dwd.dwd_whale_transaction_detail

### 3. dws_whale_daily_stats

**表说明**：存储鲸鱼钱包每日交易汇总数据

**主键**：stat_date, wallet_address

**数据来源**：dim.dim_whale_address, dwd.dwd_whale_transaction_detail

### 4. dws_collection_whale_flow

**表说明**：存储收藏集鲸鱼资金流向数据

**主键**：stat_date, collection_address, whale_type

**数据来源**：dim.dim_whale_address, dwd.dwd_whale_transaction_detail

### 5. dws_collection_whale_ownership

**表说明**：存储收藏集鲸鱼持有统计数据（新增）

**主键**：stat_date, collection_address

**数据来源**：dim.dim_collection_info, dwd.dwd_whale_transaction_detail

## 使用说明

1. **执行SQL**：
   ```bash
   # 执行所有SQL文件
   ./run_all_sql.sh
   ```

2. **数据查询示例**：
   ```sql
   -- 查询特定收藏集的每日统计数据
   SELECT * FROM dws.dws_collection_daily_stats 
   WHERE collection_date = '2023-04-01' AND contract_address = '0x495f947276749ce646f68ac8c248420045cb7b5e';
   
   -- 查询鲸鱼钱包的每日统计数据
   SELECT * FROM dws.dws_whale_daily_stats 
   WHERE stat_date >= '2023-04-01' ORDER BY daily_profit_eth DESC LIMIT 10;
   
   -- 查询特定收藏集的鲸鱼持有情况
   SELECT * FROM dws.dws_collection_whale_ownership 
   WHERE collection_address = '0x495f947276749ce646f68ac8c248420045cb7b5e' 
   ORDER BY stat_date DESC;
   ```

## 注意事项

1. **数据依赖**：
   - DWS层表之间可能存在依赖关系
   - 确保按正确顺序执行SQL文件
   - 基础层（DWD和DIM）数据必须准备完毕

2. **性能考虑**：
   - 所有表均采用分区和分桶优化
   - 大型汇总查询可能需要更多资源
   - 推荐为大型查询配置专用资源组

3. **数据更新频率**：
   - 建议每日全量刷新
   - 可以考虑按需增量更新高频表

## 参考文档

- [DWS层数据字典](./docs/dws_data_dictionary.md)（老版本，仅供参考）
- [DWS层数据流转文档](./docs/dws_data_flow.md)（老版本，仅供参考）
- [DWS层重构说明文档](./docs/dws_restructuring_note.md)（新版本） 