# NFT鲸鱼追踪器 - DIM层

## 概述

DIM层（维度层）是NFT鲸鱼追踪器数据湖架构中的重要层级，负责存储相对稳定的维度信息，提供统一口径。根据重构指南，DIM层专注于维度属性，不包含度量值和汇总计算。

## 目录结构

```
dim/
├── docs/                  # 文档目录
│   ├── dim_data_dictionary.md      # 数据字典（老版本）
│   ├── dim_data_flow.md            # 数据流转文档（老版本）
│   └── dim_restructuring_note.md   # 重构说明文档（新增）
├── logs/                  # 日志目录
├── scripts/               # 辅助脚本目录
├── sql/                   # SQL脚本目录
│   ├── dim_collection_info.sql      # 收藏集维度表SQL
│   └── dim_whale_address.sql        # 鲸鱼钱包维度表SQL
└── run_all_sql.sh         # SQL执行脚本
```

## 重构说明

本层级已根据《NFT鲸鱼追踪器数据湖重构指南》进行了重构，主要变化包括：

1. **表结构调整**：
   - 保留并精简`dim_collection_info`表
   - 保留并精简`dim_whale_address`表
   - 移除所有统计性和计算性字段

2. **明确数据处理流程**：
   - 从ODS层和DWD层获取基础维度信息
   - 维护维度数据的稳定性和一致性
   - 为上层应用提供标准维度引用

3. **字段优化**：
   - 移除计算字段和汇总统计字段
   - 保留基础维度属性字段
   - 统一字段命名和注释

## 数据表说明

### 1. dim_collection_info

**表说明**：存储NFT收藏集的维度信息

**主键**：collection_address

**关键字段**：
- collection_address - 收藏集地址
- collection_name - 收藏集名称
- first_tracked_date - 首次追踪日期
- last_active_date - 最后活跃日期
- is_in_working_set - 是否在工作集
- status - 状态

### 2. dim_whale_address

**表说明**：存储鲸鱼钱包的维度信息

**主键**：wallet_address

**关键字段**：
- wallet_address - 钱包地址
- first_track_date - 首次追踪日期
- last_active_date - 最后活跃日期
- is_whale - 是否为鲸鱼
- whale_type - 鲸鱼类型
- status - 状态

## 使用说明

1. **执行SQL**：
   ```bash
   # 执行所有SQL文件
   ./run_all_sql.sh
   ```

2. **数据查询示例**：
   ```sql
   -- 查询特定收藏集的维度信息
   SELECT * FROM dim.dim_collection_info WHERE collection_address = '0x495f947276749ce646f68ac8c248420045cb7b5e';
   
   -- 查询特定类型的鲸鱼钱包
   SELECT * FROM dim.dim_whale_address WHERE whale_type = 'SMART';
   ```

## 注意事项

1. **数据来源**：
   - `dim_collection_info`主要来源于ODS层的`ods_collection_working_set`和DWD层数据
   - `dim_whale_address`主要来源于ODS层的鲸鱼相关表和DWD层数据

2. **数据更新频率**：
   - 建议每日更新一次
   - 维度数据相对稳定，不需要频繁更新

3. **与DWS层的关系**：
   - 所有统计指标已迁移至DWS层
   - DIM层只提供维度属性，不提供计算指标

## 参考文档

- [DIM层数据字典](./docs/dim_data_dictionary.md)（老版本，仅供参考）
- [DIM层数据流转文档](./docs/dim_data_flow.md)（老版本，仅供参考）
- [DIM层重构说明文档](./docs/dim_restructuring_note.md)（新版本） 