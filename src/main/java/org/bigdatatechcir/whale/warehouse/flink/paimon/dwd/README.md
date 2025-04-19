# NFT鲸鱼追踪器 - DWD层

## 概述

DWD层（Detail Warehouse Data，明细数据层）是NFT鲸鱼追踪器数据湖架构中的关键层级，负责对ODS层数据进行清洗和规范化处理，构建业务明细数据。根据重构指南，DWD层专注于明细数据处理，不做聚合计算。

## 目录结构

```
dwd/
├── data/                  # 临时数据文件目录
├── docs/                  # 文档目录
│   ├── dwd_data_dictionary.md      # 数据字典（老版本）
│   ├── dwd_data_flow.md            # 数据流转文档（老版本）
│   └── dwd_restructuring_note.md   # 重构说明文档（新增）
├── logs/                  # 日志目录
├── scripts/               # 辅助脚本目录
├── sql/                   # SQL脚本目录
│   ├── README.md                      # SQL说明文档
│   ├── dwd_transaction_clean.sql      # 交易清洗明细表SQL
│   └── dwd_whale_transaction_detail.sql # 鲸鱼交易明细表SQL
└── run_all_sql.sh         # SQL执行脚本
```

## 重构说明

本层级已根据《NFT鲸鱼追踪器数据湖重构指南》进行了重构，主要变化包括：

1. **表结构调整**：
   - 新增基础交易清洗表：`dwd_transaction_clean`
   - 优化鲸鱼交易明细表：`dwd_whale_transaction_detail`
   - 移除聚合统计表（迁移至DWS层）

2. **明确数据处理流程**：
   - 从ODS层获取原始数据进行清洗
   - 建立`dwd_transaction_clean` -> `dwd_whale_transaction_detail`的处理链路
   - 确保数据处理的一致性和逻辑清晰度

3. **字段优化**：
   - 移除计算字段和管理字段
   - 保留基础明细数据字段
   - 统一字段命名和注释

4. **执行脚本更新**：
   - 调整SQL执行顺序
   - 移除聚合表的执行

## 数据表说明

### 1. dwd_transaction_clean

**表说明**：存储清洗后的所有交易明细数据，不限于鲸鱼交易

**主键**：tx_date, tx_id, contract_address

**数据来源**：ods.ods_collection_transaction_inc

### 2. dwd_whale_transaction_detail

**表说明**：存储与鲸鱼相关的交易明细数据（买方或卖方至少有一方是鲸鱼）

**主键**：tx_date, tx_id, contract_address, token_id

**数据来源**：dwd.dwd_transaction_clean + 鲸鱼识别

## 使用说明

1. **执行SQL**：
   ```bash
   # 执行所有SQL文件
   ./run_all_sql.sh
   ```

2. **数据查询示例**：
   ```sql
   -- 查询特定日期的交易清洗数据
   SELECT * FROM dwd.dwd_transaction_clean WHERE tx_date = '2023-04-01';
   
   -- 查询特定收藏集的鲸鱼交易明细
   SELECT * FROM dwd.dwd_whale_transaction_detail 
   WHERE contract_address = '0x495f947276749ce646f68ac8c248420045cb7b5e'
   AND tx_date >= '2023-04-01';
   ```

## 注意事项

1. **数据依赖**：
   - `dwd_transaction_clean`依赖于ODS层数据
   - `dwd_whale_transaction_detail`依赖于`dwd_transaction_clean`和ODS层鲸鱼相关表

2. **性能考虑**：
   - 所有表均使用分桶和分区优化
   - 关联查询时注意使用正确的关联条件

3. **数据更新频率**：
   - 建议每日更新一次
   - 保证ODS层数据更新完成后再执行DWD层处理

## 参考文档

- [DWD层数据字典](./docs/dwd_data_dictionary.md)（老版本，仅供参考）
- [DWD层数据流转文档](./docs/dwd_data_flow.md)（老版本，仅供参考）
- [DWD层重构说明文档](./docs/dwd_restructuring_note.md)（新版本）
- [SQL说明文档](./sql/README.md) 