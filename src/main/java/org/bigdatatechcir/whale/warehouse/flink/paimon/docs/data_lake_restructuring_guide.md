# NFT鲸鱼追踪器数据湖重构指南

## 1. 引言

本文档基于对现有NFT鲸鱼追踪器数据湖架构的全面分析，提出一套系统化的重构方案，旨在解决当前数据湖中DWD、DIM和DWS层之间职责边界模糊、功能重叠、数据冗余等问题。重构后的数据湖将更加符合标准数据仓库分层设计理念，提高数据处理效率，简化系统维护，并为后续应用层开发提供清晰稳定的数据基础。

## 2. 现状问题分析总结

### 2.1 层级职责混乱

1. **DWD层越权**：执行了应属于DWS层的汇总计算
2. **DIM层功能扩张**：包含了大量汇总统计字段，超出了维度表定义范围
3. **DWS层功能弱化**：核心聚合功能被DWD和DIM层分散实现
4. **循环依赖**：DWD和DIM层之间存在循环引用，数据血缘难以追踪

### 2.2 字段利用率低

1. **未被充分利用的字段**：各层均存在未被上层引用的冗余字段
2. **重复计算**：相同指标在不同层级重复计算，可能导致口径不一致
3. **数据冗余**：同类信息在多个表中重复存储

## 3. 标准分层架构定义

在重构之前，首先明确各层的标准定义和职责范围：

### 3.1 ODS层（操作数据层）
- **职责**：原始数据的存储，保持数据原貌
- **特点**：不做业务处理，只负责数据集成和存储
- **表命名**：`ods_*`

### 3.2 DWD层（明细数据层）
- **职责**：对ODS层数据进行清洗和规范化，构建业务明细数据
- **特点**：保持明细粒度，不做聚合计算
- **表命名**：`dwd_*`

### 3.3 DIM层（维度层）
- **职责**：存储相对稳定的维度信息，提供统一口径
- **特点**：只包含维度属性，不包含度量值和汇总计算
- **表命名**：`dim_*`

### 3.4 DWS层（汇总层）
- **职责**：基于DWD层和DIM层进行多维度汇总计算
- **特点**：包含各类汇总指标，支持多维分析
- **表命名**：`dws_*`

## 4. 重构方案

### 4.1 DWD层重构

#### 4.1.1 表结构调整

**保留表**：
- `dwd_whale_transaction_detail` - 鲸鱼交易明细表

**新增表**：
- `dwd_transaction_clean` - 清洗后的所有交易明细表，不限于鲸鱼

**移除表**（移至DWS层）：
- `dwd_collection_daily_stats` → `dws_collection_daily_stats`
- `dwd_wallet_daily_stats` → `dws_wallet_daily_stats`

#### 4.1.2 字段优化

**`dwd_whale_transaction_detail`表调整**：
- 保留：交易ID、日期、哈希、地址、金额、币种等基本字段
- 移除：`profit_potential`等计算字段（移至DWS）
- 移除：`is_deleted`等管理字段（使用视图过滤）

**`dwd_transaction_clean`表设计**：
```sql
CREATE TABLE dwd_transaction_clean (
    tx_date DATE,                           -- 交易日期
    tx_id VARCHAR(255),                     -- 交易ID
    tx_hash VARCHAR(255),                   -- 交易哈希
    tx_timestamp TIMESTAMP,                 -- 交易时间戳
    from_address VARCHAR(255),              -- 卖方地址
    to_address VARCHAR(255),                -- 买方地址
    contract_address VARCHAR(255),          -- NFT合约地址
    collection_name VARCHAR(255),           -- 收藏集名称
    token_id VARCHAR(255),                  -- NFT代币ID
    trade_price_eth DECIMAL(30,10),         -- 交易价格(ETH)
    trade_price_usd DECIMAL(30,10),         -- 交易价格(USD)
    trade_symbol VARCHAR(50),               -- 交易代币符号
    event_type VARCHAR(50),                 -- 事件类型
    platform VARCHAR(100),                  -- 交易平台
    is_in_working_set BOOLEAN,              -- 是否属于工作集
    etl_time TIMESTAMP,                     -- ETL处理时间
    PRIMARY KEY (tx_date, tx_id) NOT ENFORCED
) WITH (
    'bucket' = '10',
    'file.format' = 'parquet'
);
```

### 4.2 DIM层重构

#### 4.2.1 表结构调整

**保留并精简表**：
- `dim_whale_address` - 鲸鱼钱包维度表（精简）
- `dim_collection_info` - 收藏集维度表（精简）

#### 4.2.2 字段优化

**`dim_whale_address`表调整**：
```sql
CREATE TABLE dim_whale_address (
    wallet_address VARCHAR(255),            -- 钱包地址
    first_track_date DATE,                  -- 首次追踪日期
    last_active_date DATE,                  -- 最后活跃日期
    is_whale BOOLEAN,                       -- 是否为鲸鱼
    whale_type VARCHAR(50),                 -- 鲸鱼类型(追踪中/聪明/愚蠢)
    labels VARCHAR(500),                    -- 标签(JSON格式)
    status VARCHAR(20),                     -- 状态(活跃/不活跃)
    etl_time TIMESTAMP,                     -- ETL处理时间
    PRIMARY KEY (wallet_address) NOT ENFORCED
) WITH (
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate'
);
```

**`dim_collection_info`表调整**：
```sql
CREATE TABLE dim_collection_info (
    collection_address VARCHAR(255),        -- 收藏集地址
    collection_name VARCHAR(255),           -- 收藏集名称
    symbol VARCHAR(50),                     -- 代币符号
    logo_url VARCHAR(1000),                 -- Logo URL
    banner_url VARCHAR(1000),               -- Banner URL
    first_tracked_date DATE,                -- 首次追踪日期
    last_active_date DATE,                  -- 最后活跃日期
    items_total INT,                        -- NFT总数量
    owners_total INT,                       -- 持有者总数
    is_verified BOOLEAN,                    -- 是否已验证
    is_in_working_set BOOLEAN,              -- 是否在工作集
    working_set_join_date DATE,             -- 加入工作集日期
    category VARCHAR(100),                  -- 类别
    status VARCHAR(20),                     -- 状态
    etl_time TIMESTAMP,                     -- ETL处理时间
    PRIMARY KEY (collection_address) NOT ENFORCED
) WITH (
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate'
);
```

### 4.3 DWS层重构

#### 4.3.1 表结构调整

**现有表优化**：
- `dws_whale_daily_stats` - 鲸鱼每日统计表（增强）
- `dws_collection_whale_flow` - 收藏集鲸鱼资金流向表（增强）

**新增表**（从DWD层迁移）：
- `dws_collection_daily_stats` - 收藏集每日统计表
- `dws_wallet_daily_stats` - 钱包每日统计表

**新增聚合表**：
- `dws_collection_whale_ownership` - 收藏集鲸鱼持有统计表

#### 4.3.2 表设计示例

**`dws_collection_daily_stats`表设计**：
```sql
CREATE TABLE dws_collection_daily_stats (
    collection_date DATE,                   -- 统计日期
    contract_address VARCHAR(255),          -- NFT合约地址
    collection_name VARCHAR(255),           -- 收藏集名称
    sales_count INT,                        -- 当日销售数量
    volume_eth DECIMAL(30,10),              -- 当日交易额(ETH)
    volume_usd DECIMAL(30,10),              -- 当日交易额(USD)
    avg_price_eth DECIMAL(30,10),           -- 当日平均价格(ETH)
    min_price_eth DECIMAL(30,10),           -- 当日最低价格(ETH)
    max_price_eth DECIMAL(30,10),           -- 当日最高价格(ETH)
    floor_price_eth DECIMAL(30,10),         -- 当日地板价(ETH)
    unique_buyers INT,                      -- 唯一买家数量
    unique_sellers INT,                     -- 唯一卖家数量
    whale_buyers INT,                       -- 鲸鱼买家数量
    whale_sellers INT,                      -- 鲸鱼卖家数量
    whale_volume_eth DECIMAL(30,10),        -- 鲸鱼交易额(ETH)
    whale_percentage DECIMAL(10,2),         -- 鲸鱼交易额占比
    sales_change_1d DECIMAL(10,2),          -- 销售数量1日环比
    volume_change_1d DECIMAL(10,2),         -- 交易额1日环比
    price_change_1d DECIMAL(10,2),          -- 均价1日环比
    is_in_working_set BOOLEAN,              -- 是否属于工作集
    rank_by_volume INT,                     -- 按交易额排名
    rank_by_sales INT,                      -- 按销售量排名
    is_top30_volume BOOLEAN,                -- 是否交易额Top30
    is_top30_sales BOOLEAN,                 -- 是否销售量Top30
    etl_time TIMESTAMP,                     -- ETL处理时间
    PRIMARY KEY (collection_date, contract_address) NOT ENFORCED
) WITH (
    'bucket' = '10',
    'file.format' = 'parquet'
);
```

## 5. 实施步骤

### 5.1 准备阶段

1. **数据备份**：
   - 全量备份现有数据表
   - 记录现有表的DDL语句

2. **设计确认**：
   - 确认新表结构设计
   - 验证字段映射关系
   - 核实主键设计

### 5.2 DWD层调整

1. **创建新表**：
   ```bash
   # 创建dwd_transaction_clean表
   flink-sql-client.sh -f create_dwd_transaction_clean.sql
   ```

2. **数据迁移**：
   ```bash
   # 从ODS层填充dwd_transaction_clean
   flink-sql-client.sh -f populate_dwd_transaction_clean.sql
   ```

3. **更新dwd_whale_transaction_detail**：
   ```bash
   # 调整表结构并更新数据
   flink-sql-client.sh -f update_dwd_whale_transaction_detail.sql
   ```

### 5.3 DIM层调整

1. **创建新表**：
   ```bash
   # 创建精简版dim表
   flink-sql-client.sh -f create_dim_tables_new.sql
   ```

2. **数据迁移**：
   ```bash
   # 从现有表迁移基础维度数据
   flink-sql-client.sh -f migrate_dim_data.sql
   ```

### 5.4 DWS层增强

1. **创建新表**：
   ```bash
   # 创建新的DWS层表
   flink-sql-client.sh -f create_dws_tables_new.sql
   ```

2. **数据聚合填充**：
   ```bash
   # 从DWD层和DIM层填充DWS层数据
   flink-sql-client.sh -f populate_dws_tables.sql
   ```

### 5.5 验证与切换

1. **数据验证**：
   - 核对新旧表数据一致性
   - 验证关键指标计算准确性

2. **应用层切换**：
   - 更新应用程序配置，指向新表

3. **旧表归档**：
   - 备份后删除冗余表

## 6. SQL示例

### 6.1 DWS层聚合计算示例

**收藏集每日统计**：
```sql
INSERT INTO dws_collection_daily_stats
SELECT 
    tx_date AS collection_date,
    contract_address,
    MAX(collection_name) AS collection_name,
    COUNT(*) AS sales_count,
    SUM(trade_price_eth) AS volume_eth,
    SUM(trade_price_usd) AS volume_usd,
    AVG(trade_price_eth) AS avg_price_eth,
    MIN(trade_price_eth) AS min_price_eth,
    MAX(trade_price_eth) AS max_price_eth,
    -- 当日最后一笔交易的地板价
    LAST_VALUE(floor_price_eth) OVER (
        PARTITION BY tx_date, contract_address 
        ORDER BY tx_timestamp
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS floor_price_eth,
    COUNT(DISTINCT to_address) AS unique_buyers,
    COUNT(DISTINCT from_address) AS unique_sellers,
    -- 鲸鱼统计需关联维度表
    COUNT(DISTINCT CASE WHEN w1.is_whale THEN to_address END) AS whale_buyers,
    COUNT(DISTINCT CASE WHEN w2.is_whale THEN from_address END) AS whale_sellers,
    SUM(CASE WHEN (w1.is_whale OR w2.is_whale) THEN trade_price_eth ELSE 0 END) AS whale_volume_eth,
    CASE 
        WHEN SUM(trade_price_eth) > 0 
        THEN (SUM(CASE WHEN (w1.is_whale OR w2.is_whale) THEN trade_price_eth ELSE 0 END) / SUM(trade_price_eth)) * 100 
        ELSE 0 
    END AS whale_percentage,
    -- 环比需要窗口函数
    0 AS sales_change_1d, -- 在后续处理中更新
    0 AS volume_change_1d, -- 在后续处理中更新
    0 AS price_change_1d, -- 在后续处理中更新
    MAX(is_in_working_set) AS is_in_working_set,
    0 AS rank_by_volume, -- 在后续处理中更新
    0 AS rank_by_sales, -- 在后续处理中更新
    FALSE AS is_top30_volume, -- 在后续处理中更新
    FALSE AS is_top30_sales, -- 在后续处理中更新
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dwd_transaction_clean t
LEFT JOIN 
    dim_whale_address w1 ON t.to_address = w1.wallet_address
LEFT JOIN 
    dim_whale_address w2 ON t.from_address = w2.wallet_address
WHERE 
    tx_date = CURRENT_DATE
GROUP BY 
    tx_date,
    contract_address;

-- 更新排名和环比信息
-- 这里仅为示例，实际实现可能需要多个SQL语句或存储过程
```

### 6.2 维度表更新示例

**鲸鱼维度表更新**：
```sql
-- 1. 识别并添加新鲸鱼
INSERT INTO dim_whale_address
WITH potential_whales AS (
    SELECT DISTINCT
        wallet_address,
        MIN(tx_date) AS first_track_date,
        MAX(tx_date) AS last_active_date,
        TRUE AS is_whale,
        'TRACKING' AS whale_type,
        '[]' AS labels,
        'ACTIVE' AS status,
        CURRENT_TIMESTAMP AS etl_time
    FROM (
        -- 统计买方和卖方的交易总额
        SELECT 
            tx_date,
            to_address AS wallet_address,
            SUM(trade_price_eth) AS volume
        FROM 
            dwd_transaction_clean
        WHERE 
            tx_date >= DATE_SUB(CURRENT_DATE, 30)
        GROUP BY 
            tx_date, to_address
        
        UNION ALL
        
        SELECT 
            tx_date,
            from_address AS wallet_address,
            SUM(trade_price_eth) AS volume
        FROM 
            dwd_transaction_clean
        WHERE 
            tx_date >= DATE_SUB(CURRENT_DATE, 30)
        GROUP BY 
            tx_date, from_address
    ) t
    -- 根据交易额识别鲸鱼
    WHERE volume > 10 -- 设置鲸鱼识别阈值
    GROUP BY wallet_address
)
SELECT * FROM potential_whales pw
WHERE NOT EXISTS (
    SELECT 1 FROM dim_whale_address dw
    WHERE dw.wallet_address = pw.wallet_address
);

-- 2. 更新现有鲸鱼
MERGE INTO dim_whale_address t
USING (
    SELECT 
        wallet_address,
        MAX(tx_date) AS last_active_date,
        CASE
            WHEN wallet_address IN (SELECT wallet_address FROM dws_whale_daily_stats WHERE success_rate_30d >= 65) THEN 'SMART'
            WHEN wallet_address IN (SELECT wallet_address FROM dws_whale_daily_stats WHERE success_rate_30d < 40) THEN 'DUMB'
            ELSE 'TRACKING'
        END AS whale_type,
        'ACTIVE' AS status
    FROM 
        dwd_transaction_clean
    WHERE 
        tx_date >= DATE_SUB(CURRENT_DATE, 7)
    GROUP BY 
        wallet_address
) s
ON t.wallet_address = s.wallet_address
WHEN MATCHED THEN
    UPDATE SET 
        t.last_active_date = s.last_active_date,
        t.whale_type = 
            CASE 
                WHEN t.whale_type = 'TRACKING' AND DATEDIFF(CURRENT_DATE, t.first_track_date) >= 30 
                THEN s.whale_type 
                ELSE t.whale_type 
            END,
        t.status = s.status,
        t.etl_time = CURRENT_TIMESTAMP;
```

## 7. 注意事项与风险

1. **数据一致性**：
   - 确保在重构过程中保持数据一致性
   - 实施增量迁移策略，减少停机时间

2. **业务中断风险**：
   - 可能需要短暂停止数据更新
   - 建议在低峰期执行重构工作

3. **回滚计划**：
   - 制定详细的回滚计划
   - 保留足够长的旧架构过渡期

4. **性能影响**：
   - 监控重构后SQL执行性能
   - 可能需要重新优化查询和索引

## 8. 后续优化建议

1. **血缘关系管理**：
   - 实现血缘关系追踪工具
   - 记录字段级数据流转路径

2. **指标管理体系**：
   - 建立统一的指标管理平台
   - 标准化指标定义和计算口径

3. **数据质量监控**：
   - 增强数据质量检查流程
   - 实现异常数据自动告警

4. **存储优化**：
   - 实施数据分区和压缩策略
   - 针对热点数据设置缓存

5. **文档更新**：
   - 更新各层数据字典
   - 维护表关系图和查询示例

## 9. 结论

通过本重构方案，NFT鲸鱼追踪器数据湖将实现层级职责清晰、数据流转合理、减少冗余计算的目标。重构后的架构不仅提高了系统性能和可维护性，也为未来的功能扩展和分析需求提供了更加灵活和可扩展的基础。

---

**附录：数据流转示意图**

ODS层 → DWD层(清洗) → DIM层(维度) + DWS层(汇总) → ADS层(应用)

---

**版本记录**
- v1.0 初始版本 (2023-04-XX) 