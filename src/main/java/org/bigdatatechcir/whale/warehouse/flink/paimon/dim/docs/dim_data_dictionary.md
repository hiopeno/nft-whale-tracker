# NFT Whale Tracker DIM层数据字典

## 概述

DIM层（Dimension，维度层）是NFT Whale Tracker项目中存储标准化维度数据的层，主要提供鲸鱼钱包地址和NFT收藏集的标准化视图，为数据分析提供统一的维度口径。本文档详细说明DIM层各表的字段定义、数据类型、取值范围和业务含义。

## 表清单

DIM层目前包含以下维度表：

1. `dim_whale_address` - 鲸鱼钱包地址维度表
2. `dim_collection_info` - NFT收藏集维度表

## 表结构详细说明

### dim_whale_address

该表存储鲸鱼钱包地址的维度信息，用于标准化鲸鱼钱包的属性和状态。

#### 表设计

| 字段名 | 数据类型 | 是否为空 | 主键 | 描述 | 示例值 |
|-------|---------|--------|------|------|-------|
| wallet_address | STRING | 否 | 是 | 钱包地址 | 0x123abc... |
| first_track_date | DATE | 否 | 否 | 首次追踪日期 | 2023-06-01 |
| last_active_date | DATE | 否 | 否 | 最后活跃日期 | 2023-06-25 |
| is_whale | BOOLEAN | 否 | 否 | 是否为鲸鱼 | TRUE |
| whale_type | STRING | 否 | 否 | 鲸鱼类型 | SMART |
| labels | STRING | 是 | 否 | 标签（JSON数组） | ["nft-flipper", "early-adopter"] |
| status | STRING | 否 | 否 | 状态 | ACTIVE |
| etl_time | TIMESTAMP | 否 | 否 | ETL处理时间 | 2023-06-26 00:01:25 |

#### 字段详细说明

1. **wallet_address**
   - 数据类型：STRING
   - 描述：钱包地址，作为主键唯一标识一个钱包
   - 来源：从交易数据和鲸鱼名单中提取
   - 格式：以"0x"开头的以太坊地址

2. **first_track_date**
   - 数据类型：DATE
   - 描述：该钱包首次被系统识别为鲸鱼并开始追踪的日期
   - 取值范围：有效的日期
   - 业务含义：标记鲸鱼进入追踪系统的时间点

3. **last_active_date**
   - 数据类型：DATE
   - 描述：该钱包最后一次在系统中有交易活动的日期
   - 取值范围：有效的日期
   - 业务含义：用于判断鲸鱼活跃状态

4. **is_whale**
   - 数据类型：BOOLEAN
   - 描述：标识该地址是否被确认为鲸鱼
   - 取值范围：TRUE/FALSE
   - 业务含义：TRUE表示确认为鲸鱼，FALSE表示暂未确认

5. **whale_type**
   - 数据类型：STRING
   - 描述：鲸鱼类型分类
   - 取值范围：TRACKING（追踪中）、SMART（聪明）、DUMB（愚蠢）
   - 业务含义：
     - TRACKING：观察期内的新鲸鱼
     - SMART：观察期结束后，被判定为"聪明"的鲸鱼（成功交易多）
     - DUMB：观察期结束后，被判定为"愚蠢"的鲸鱼（亏损交易多）

6. **labels**
   - 数据类型：STRING (JSON数组)
   - 描述：该钱包的标签集合，以JSON数组形式存储
   - 取值范围：预定义的标签值
   - 业务含义：用于标记钱包的特征和行为模式

7. **status**
   - 数据类型：STRING
   - 描述：钱包的活跃状态
   - 取值范围：ACTIVE（活跃）、INACTIVE（不活跃）
   - 业务含义：
     - ACTIVE：表示近期（30天内）有交易活动
     - INACTIVE：表示长时间（超过30天）无交易活动

8. **etl_time**
   - 数据类型：TIMESTAMP
   - 描述：数据ETL处理时间
   - 业务含义：用于数据追踪和处理监控

#### 表属性

- **主键**：wallet_address
- **更新策略**：每日更新
- **记录追踪期**：30天（如果钱包30天内无交易，会被标记为不活跃）

### dim_collection_info

该表存储NFT收藏集的维度信息，用于标准化收藏集的属性和状态。

#### 表设计

| 字段名 | 数据类型 | 是否为空 | 主键 | 描述 | 示例值 |
|-------|---------|--------|------|------|-------|
| collection_address | STRING | 否 | 是 | 收藏集合约地址 | 0xbc4ca0... |
| collection_name | STRING | 否 | 否 | 收藏集名称 | Bored Ape Yacht Club |
| symbol | STRING | 是 | 否 | 代币符号 | BAYC |
| logo_url | STRING | 是 | 否 | Logo图片URL | https://example.com/logo.png |
| banner_url | STRING | 是 | 否 | Banner图片URL | https://example.com/banner.png |
| first_tracked_date | DATE | 否 | 否 | 首次追踪日期 | 2023-05-15 |
| last_active_date | DATE | 否 | 否 | 最后活跃日期 | 2023-06-25 |
| items_total | INT | 是 | 否 | NFT总数量 | 10000 |
| owners_total | INT | 是 | 否 | 持有者总数 | 6745 |
| is_verified | BOOLEAN | 否 | 否 | 是否已验证 | TRUE |
| is_in_working_set | BOOLEAN | 否 | 否 | 是否在工作集 | TRUE |
| working_set_join_date | DATE | 是 | 否 | 加入工作集日期 | 2023-05-15 |
| category | STRING | 是 | 否 | 收藏集类别 | ART |
| status | STRING | 否 | 否 | 状态 | ACTIVE |
| etl_time | TIMESTAMP | 否 | 否 | ETL处理时间 | 2023-06-26 00:02:15 |

#### 字段详细说明

1. **collection_address**
   - 数据类型：STRING
   - 描述：收藏集合约地址，作为主键唯一标识一个收藏集
   - 来源：从交易数据和收藏集信息中提取
   - 格式：以"0x"开头的以太坊合约地址

2. **collection_name**
   - 数据类型：STRING
   - 描述：收藏集名称
   - 业务含义：用于展示和搜索

3. **symbol**
   - 数据类型：STRING
   - 描述：收藏集代币符号
   - 业务含义：代表收藏集的简称

4. **logo_url**
   - 数据类型：STRING
   - 描述：收藏集Logo图片的URL
   - 业务含义：用于UI展示

5. **banner_url**
   - 数据类型：STRING
   - 描述：收藏集Banner图片的URL
   - 业务含义：用于UI展示

6. **first_tracked_date**
   - 数据类型：DATE
   - 描述：该收藏集首次被系统追踪的日期
   - 业务含义：标记收藏集进入追踪系统的时间点

7. **last_active_date**
   - 数据类型：DATE
   - 描述：该收藏集最后一次在系统中有交易活动的日期
   - 业务含义：用于判断收藏集活跃状态

8. **items_total**
   - 数据类型：INT
   - 描述：收藏集中NFT的总数量
   - 业务含义：反映收藏集规模

9. **owners_total**
   - 数据类型：INT
   - 描述：收藏集持有者的总数量
   - 业务含义：反映收藏集分散度

10. **is_verified**
    - 数据类型：BOOLEAN
    - 描述：收藏集是否经过验证
    - 取值范围：TRUE/FALSE
    - 业务含义：TRUE表示已验证，FALSE表示未验证

11. **is_in_working_set**
    - 数据类型：BOOLEAN
    - 描述：收藏集是否在当前工作集中
    - 取值范围：TRUE/FALSE
    - 业务含义：TRUE表示在工作集中，FALSE表示不在

12. **working_set_join_date**
    - 数据类型：DATE
    - 描述：收藏集加入工作集的日期
    - 业务含义：用于追踪收藏集进入工作集的时间

13. **category**
    - 数据类型：STRING
    - 描述：收藏集类别
    - 取值范围：ART、COLLECTIBLE、GAME、METAVERSE等
    - 业务含义：对收藏集进行分类

14. **status**
    - 数据类型：STRING
    - 描述：收藏集的活跃状态
    - 取值范围：ACTIVE（活跃）、INACTIVE（不活跃）
    - 业务含义：
      - ACTIVE：表示近期（7天内）有交易活动
      - INACTIVE：表示长时间（超过7天）无交易活动

15. **etl_time**
    - 数据类型：TIMESTAMP
    - 描述：数据ETL处理时间
    - 业务含义：用于数据追踪和处理监控

#### 表属性

- **主键**：collection_address
- **更新策略**：每日更新
- **记录追踪期**：7天（如果收藏集7天内无交易，会被标记为不活跃）

## 数据质量规则

为确保DIM层数据的质量，设定了以下数据质量规则：

1. **完整性规则**
   - 主键字段不允许为NULL
   - 核心业务字段不允许为NULL（如状态、类型等）

2. **有效性规则**
   - 日期字段必须为有效的日期格式
   - 枚举值字段（如status、whale_type）必须符合预定义的取值范围

3. **一致性规则**
   - first_track_date 不应晚于 last_active_date
   - 鲸鱼类型和状态应与活跃时间一致

## 数据管理责任

DIM层数据的维护和管理责任如下：

1. **数据所有者**：数据仓库团队
2. **数据维护者**：ETL开发团队
3. **数据使用者**：数据分析团队、产品团队

## 表间关系

DIM层表之间存在以下关联关系：

1. **dim_whale_address** 与 **dim_collection_info** 之间的关系是通过交易数据间接关联的，无直接外键关系。

## 维度层职责边界

DIM层专注于维度数据的管理和标准化，不进行复杂的计算和分析。以下是DIM层的职责边界：

1. **DIM层应该做的**：
   - 管理和标准化维度数据
   - 提供实体（如鲸鱼钱包、收藏集）的基本属性和状态
   - 为分析层（DWS/ADS）提供稳定的维度视图

2. **DIM层不应该做的**：
   - 不存储复杂的计算指标（如ROI、收益率等）
   - 不执行复杂的聚合计算
   - 不进行跨维度的复杂关联分析

```sql
PRIMARY KEY (field) NOT ENFORCED
```

## 表参数说明

所有DIM层表都使用以下通用参数：

```sql
WITH (
    'bucket' = 'n',                      -- 分桶数
    'bucket-key' = 'field',              -- 分桶键（可选）
    'file.format' = 'parquet',           -- 文件格式
    'merge-engine' = 'deduplicate',      -- 合并引擎
    'changelog-producer' = 'lookup',     -- 变更日志生产模式
    'compaction.min.file-num' = 'n',     -- 最小文件数量进行压缩
    'compaction.max.file-num' = 'n',     -- 最大文件数量进行压缩
    'compaction.target-file-size' = 'nMB' -- 目标文件大小
)
``` 