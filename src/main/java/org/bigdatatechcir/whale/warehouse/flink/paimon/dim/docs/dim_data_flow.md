# NFT Whale Tracker DIM层数据流转文档

## 1. 概述

本文档详细描述了NFT Whale Tracker项目中DIM层（Dimension，维度层）的数据流转过程。DIM层作为数据仓库中的维度层，主要用于存储相对稳定的维度信息，为数据分析提供统一的口径和视角，是后续DWS层和ADS层分析的基础。

## 2. 数据流转架构

整个DIM层的数据流转过程可以分为以下几个关键步骤：

```
ODS/DWD层数据 -> 维度抽取 -> 维度合并与更新 -> 维度标准化 -> DIM层表
```

## 3. 数据处理流程

### 3.1 dim_whale_address 处理流程

该表存储鲸鱼钱包地址的维度信息，主要来源于DWD层的`dwd_wallet_daily_stats`表和ODS层的钱包相关数据。

处理流程：
1. 从`dwd_wallet_daily_stats`和ODS钱包表中识别鲸鱼钱包地址
2. 计算鲸鱼钱包的各项指标（如交易收益、交易成功率等）
3. 基于历史交易表现为鲸鱼分类（追踪中/聪明/愚蠢）
4. 管理鲸鱼钱包的生命周期（新增、更新、失活）
5. 计算并更新鲸鱼影响力评分

> 🔴 **重要更新**: 由于Paimon表的特殊性，维度表的更新采用"先删除后插入"的方式进行，确保数据能够正确更新而不是累积重复。这种方式虽然不是最高效的，但在当前环境下能够确保数据的准确性。

SQL处理逻辑示例：
```sql
-- 1. 识别新加入的鲸鱼钱包
INSERT INTO dim_whale_address
WITH potential_whales AS (
    SELECT DISTINCT
        wallet_address,
        MIN(wallet_date) AS first_track_date,
        MAX(wallet_date) AS last_active_date,
        TRUE AS is_whale,
        'TRACKING' AS whale_type, -- 初始状态为追踪中
        0 AS whale_score, -- 初始影响力评分为0
        SUM(CASE WHEN net_flow_eth > 0 THEN net_flow_eth ELSE 0 END) AS total_profit_eth,
        SUM(CASE WHEN net_flow_usd > 0 THEN net_flow_usd ELSE 0 END) AS total_profit_usd,
        0 AS roi_percentage, -- 初始ROI为0
        SUM(buy_volume_eth) AS total_buy_volume_eth,
        SUM(sell_volume_eth) AS total_sell_volume_eth,
        SUM(total_tx_count) AS total_tx_count,
        0 AS avg_hold_days, -- 初始平均持有天数为0
        '[]' AS favorite_collections, -- 初始无偏好收藏集
        '[]' AS labels, -- 初始无标签
        0 AS success_rate, -- 初始成功率为0
        COUNT(CASE WHEN is_top30_volume = TRUE THEN 1 END) AS is_top30_volume_days,
        COUNT(CASE WHEN is_top100_balance = TRUE THEN 1 END) AS is_top100_balance_days,
        0 AS inactive_days, -- 初始不活跃天数为0
        'ACTIVE' AS status,
        CURRENT_TIMESTAMP AS etl_time
    FROM 
        dwd_wallet_daily_stats
    WHERE 
        is_whale_candidate = TRUE
        AND wallet_date >= DATE_SUB(CURRENT_DATE(), 30) -- 最近30天内
    GROUP BY 
        wallet_address
    HAVING 
        COUNT(CASE WHEN is_top30_volume = TRUE THEN 1 END) >= 1 -- 至少1天在交易额Top30
        OR COUNT(CASE WHEN is_top100_balance = TRUE THEN 1 END) >= 1 -- 或至少1天在持有额Top100
)
SELECT * FROM potential_whales pw
WHERE NOT EXISTS (
    SELECT 1 FROM dim_whale_address dw
    WHERE dw.wallet_address = pw.wallet_address
);

-- 2. 更新现有鲸鱼钱包信息
-- 先删除要更新的记录
DELETE FROM dim_whale_address
WHERE wallet_address IN (
    SELECT DISTINCT dw.wallet_address
    FROM dim_whale_address dw
    JOIN dwd.dwd_wallet_daily_stats wd ON dw.wallet_address = wd.wallet_address
    WHERE wd.wallet_date > dw.last_active_date
);

-- 然后重新插入更新后的数据
INSERT INTO dim_whale_address
SELECT 
    wd.wallet_address,
    MAX(wd.wallet_date) AS max_date,
    SUM(wd.profit_eth) AS profit_eth,
    SUM(wd.profit_usd) AS profit_usd,
    SUM(wd.buy_volume_eth) AS buy_volume_eth,
    SUM(wd.sell_volume_eth) AS sell_volume_eth,
    SUM(wd.total_tx_count) AS tx_count,
    COUNT(CASE WHEN wd.is_top30_volume = TRUE THEN 1 END) AS top30_days,
    COUNT(CASE WHEN wd.is_top100_balance = TRUE THEN 1 END) AS top100_days,
    (COUNT(CASE WHEN wd.profit_eth > 0 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)) AS success_rate,
    (
        SELECT CONCAT('["', STRING_AGG(DISTINCT contract_address, '","'), '"]')
        FROM (
            SELECT 
                contract_address,
                COUNT(*) AS trade_count
            FROM 
                dwd_whale_transaction_detail
            WHERE 
                tx_date >= DATE_SUB(CURRENT_DATE, 30)
                AND (from_address = wd.wallet_address OR to_address = wd.wallet_address)
            GROUP BY 
                contract_address
            ORDER BY 
                trade_count DESC
            LIMIT 5
        ) fc
    ) AS favorite_collections,
    CASE 
        WHEN (wd.total_buy_volume_eth + COALESCE(stats.buy_volume_eth, 0)) > 0 
        THEN ((wd.total_profit_eth + COALESCE(stats.profit_eth, 0)) / (wd.total_buy_volume_eth + COALESCE(stats.buy_volume_eth, 0))) * 100 
        ELSE 0 
    END AS roi_percentage,
    CASE 
        WHEN stats.max_date >= DATE_SUB(CURRENT_DATE, 7) THEN 'ACTIVE'
        WHEN DATEDIFF(CURRENT_DATE, GREATEST(wd.last_active_date, stats.max_date)) > 7 THEN 'INACTIVE'
        ELSE wd.status
    END AS status,
    CASE
        WHEN wd.whale_type = 'TRACKING' AND DATEDIFF(CURRENT_DATE, wd.first_track_date) >= 30 THEN
            CASE
                WHEN COALESCE(stats.success_rate, wd.success_rate) >= 65 THEN 'SMART'
                WHEN COALESCE(stats.success_rate, wd.success_rate) < 40 THEN 'DUMB'
                ELSE 'TRACKING'
            END
        ELSE wd.whale_type
    END AS whale_type,
    CASE
        WHEN COALESCE(stats.roi_percentage, 0) >= 50 THEN CONCAT_WS(',', wd.labels, '["high_profit"]')
        WHEN COALESCE(stats.total_tx_count, 0) >= 500 THEN CONCAT_WS(',', wd.labels, '["high_activity"]')
        WHEN COALESCE(stats.top30_days, 0) >= 10 THEN CONCAT_WS(',', wd.labels, '["top_trader"]')
        ELSE wd.labels
    END AS labels,
    CASE
        WHEN stats.max_date >= DATE_SUB(CURRENT_DATE, 7) THEN CURRENT_TIMESTAMP
        ELSE wd.etl_time
    END AS etl_time
FROM (
    SELECT 
        wd.wallet_address,
        MAX(wd.wallet_date) AS max_date,
        SUM(wd.profit_eth) AS profit_eth,
        SUM(wd.profit_usd) AS profit_usd,
        SUM(wd.buy_volume_eth) AS buy_volume_eth,
        SUM(wd.sell_volume_eth) AS sell_volume_eth,
        SUM(wd.total_tx_count) AS tx_count,
        COUNT(CASE WHEN wd.is_top30_volume = TRUE THEN 1 END) AS top30_days,
        COUNT(CASE WHEN wd.is_top100_balance = TRUE THEN 1 END) AS top100_days,
        (COUNT(CASE WHEN wd.profit_eth > 0 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)) AS success_rate,
        (
            SELECT CONCAT('["', STRING_AGG(DISTINCT contract_address, '","'), '"]')
            FROM (
                SELECT 
                    contract_address,
                    COUNT(*) AS trade_count
                FROM 
                    dwd_whale_transaction_detail
                WHERE 
                    tx_date >= DATE_SUB(CURRENT_DATE, 30)
                    AND (from_address = wd.wallet_address OR to_address = wd.wallet_address)
                GROUP BY 
                    contract_address
                ORDER BY 
                    trade_count DESC
                LIMIT 5
            ) fc
        ) AS favorite_collections
    FROM 
        dwd_wallet_daily_stats wd
    WHERE 
        wd.wallet_date > COALESCE(
            (SELECT MAX(last_active_date) FROM dim_whale_address WHERE wallet_address = wd.wallet_address),
            '1970-01-01'
        )
    GROUP BY 
        wd.wallet_address
) stats
WHERE wd.wallet_address = stats.wallet_address;
```

### 3.2 dim_collection_info 处理流程

该表存储NFT收藏集的维度信息，主要来源于ODS层的收藏集信息和DWD层的收藏集统计数据。

处理流程：
1. 从ODS层收藏集数据提取基本信息
2. 关联DWD层收藏集统计数据计算各项指标
3. 更新收藏集的工作集状态
4. 更新收藏集与鲸鱼相关的统计指标
5. 管理收藏集的生命周期（活跃、不活跃）

> 🔴 **重要更新**: 与`dim_whale_address`相同，此表的更新也采用"先删除后插入"的方式进行，确保数据能够正确更新而不累积重复记录。

SQL处理逻辑示例：
```sql
-- 1. 新增收藏集
INSERT INTO dim_collection_info
WITH new_collections AS (
    SELECT DISTINCT
        cws.collection_address,
        COALESCE(cws.collection_name, c.collection_name) AS collection_name,
        c.symbol,
        cws.logo_url,
        c.banner_url,
        CAST(cws.first_added_date AS DATE) AS first_tracked_date,
        CAST(cws.last_active_date AS DATE) AS last_active_date,
        c.items_total,
        c.owners_total,
        c.verified AS is_verified,
        c.floor_price AS current_floor_price_eth,
        c.volume_total AS all_time_volume_eth,
        c.sales_total AS all_time_sales,
        c.average_price_7d AS avg_price_7d,
        c.average_price_30d AS avg_price_30d,
        c.volume_7d,
        c.volume_30d,
        c.sales_7d,
        c.sales_30d,
        0 AS whale_ownership_percentage, -- 初始化为0
        0 AS whale_volume_percentage, -- 初始化为0
        0 AS smart_whale_interest_score, -- 初始化为0
        TRUE AS is_in_working_set,
        CAST(cws.first_added_date AS DATE) AS working_set_join_date,
        DATEDIFF(CURRENT_DATE, CAST(cws.first_added_date AS DATE)) AS working_set_days,
        0 AS inactive_days,
        'ACTIVE' AS status,
        'NFT' AS category, -- 默认类别
        0 AS total_whale_buys,
        0 AS total_whale_sells,
        CURRENT_TIMESTAMP AS etl_time
    FROM 
        ods_collection_working_set cws
    LEFT JOIN (
        SELECT * FROM ods_daily_top30_volume_collections
        UNION
        SELECT * FROM ods_daily_top30_transaction_collections
    ) c ON cws.collection_address = c.contract_address
    WHERE 
        cws.status = 'active'
)
SELECT * FROM new_collections nc
WHERE NOT EXISTS (
    SELECT 1 FROM dim_collection_info dci
    WHERE dci.collection_address = nc.collection_address
);

-- 2. 更新已有收藏集
-- 先删除要更新的记录
DELETE FROM dim_collection_info
WHERE collection_address IN (
  SELECT DISTINCT dci.collection_address
  FROM dim_collection_info dci
  JOIN dwd.dwd_collection_daily_stats cd ON dci.collection_address = cd.contract_address
  WHERE cd.collection_date > dci.last_active_date
);

-- 然后重新插入更新后的数据
INSERT INTO dim_collection_info
SELECT 
    cd.contract_address,
    MAX(cd.collection_name) AS collection_name,
    MAX(cd.collection_date) AS max_date,
    AVG(cd.floor_price_eth) AS floor_price_eth,
    AVG(cd.avg_price_eth) AS avg_price_7d,
    NULL AS avg_price_30d, -- 需要其他数据源
    SUM(cd.volume_eth) AS volume_7d,
    NULL AS volume_30d, -- 需要其他数据源
    SUM(cd.sales_count) AS sales_7d,
    NULL AS sales_30d, -- 需要其他数据源
    AVG(cd.whale_percentage) AS whale_volume_pct,
    SUM(cd.whale_buyers) AS whale_buys,
    SUM(cd.whale_sellers) AS whale_sells,
    BOOL_OR(cd.is_in_working_set) AS is_in_working_set,
    (
        SELECT (COUNT(DISTINCT CASE WHEN tx.to_is_whale AND tx.from_is_whale = FALSE THEN tx.to_address END) * 100.0 / NULLIF(COUNT(DISTINCT tx.to_address), 0))
        FROM dwd_whale_transaction_detail tx
        WHERE tx.contract_address = cd.contract_address
        AND tx.tx_date >= DATE_SUB(CURRENT_DATE, 30)
    ) AS whale_ownership,
    (
        SELECT AVG(
            CASE
                WHEN w.whale_type = 'SMART' THEN 1
                ELSE 0
            END
        ) * 100
        FROM dwd_whale_transaction_detail tx
        JOIN dim_whale_address w ON tx.to_address = w.wallet_address
        WHERE tx.contract_address = cd.contract_address
        AND tx.tx_date >= DATE_SUB(CURRENT_DATE, 30)
        AND tx.to_is_whale = TRUE
    ) AS smart_whale_score
FROM 
    dwd_collection_daily_stats cd
WHERE 
    cd.collection_date > COALESCE(
        (SELECT MAX(last_active_date) FROM dim_collection_info WHERE collection_address = cd.contract_address),
        '1970-01-01'
    )
    AND cd.collection_date >= DATE_SUB(CURRENT_DATE, 7) -- 获取最近7天数据
GROUP BY 
    cd.contract_address;


## 4. 执行流程与调度

### 4.1 完整执行流程

DIM层数据处理通常按以下顺序执行：

1. 执行`dim_date_info`表的数据处理（通常只需一次或定期扩展）：
   ```bash
   ./run_dim_date_info.sh
   ```

2. 执行`dim_collection_info`表的数据处理：
   ```bash
   ./run_dim_collection_info.sh
   ```

3. 执行`dim_whale_address`表的数据处理：
   ```bash
   ./run_dim_whale_address.sh
   ```

### 4.2 调度策略

DIM层数据处理通常在DWD层数据完成处理后执行，建议采用以下调度策略：

- **调度频率**：
  - `dim_collection_info`和`dim_whale_address`：每日一次，在DWD层处理完成后

- **依赖关系**：
  - 依赖DWD层相关表的处理完成
  - `dim_whale_address`部分依赖于`dim_collection_info`的更新

- **超时设置**：30分钟

- **失败处理**：失败时自动重试2次，然后告警

### 4.3 数据质量监控

DIM层应设置以下数据质量监控规则：

1. **完整性检查**：
   - 确保主键字段（如wallet_address、collection_address、date_id）无空值
   - 检查是否有缺失的关键维度

2. **准确性检查**：
   - 验证计算字段（如收益率、影响力评分）在合理范围内
   - 验证日期相关字段的逻辑一致性

3. **一致性检查**：
   - 检查维度数据与源系统数据的一致性
   - 验证状态字段（如active/inactive）的准确性

## 5. 维度管理与更新策略

DIM层采用以下策略管理和更新维度数据：

### 5.1 鲸鱼钱包维度管理

1. **新增策略**：
   - 满足特定条件的钱包（如出现在交易额Top30或持有额Top100）被识别为潜在鲸鱼
   - 初始状态设置为"追踪中"（TRACKING）

2. **状态变更**：
   - 追踪30天后，根据交易表现将鲸鱼分类为"聪明"或"愚蠢"
   - 连续7天不活跃的鲸鱼标记为"不活跃"状态

3. **指标更新**：
   - 定期更新累计收益、交易量、影响力评分等指标
   - 基于最新交易记录更新偏好收藏集和标签

### 5.2 收藏集维度管理

1. **新增策略**：
   - 来自工作集的收藏集会被添加到维度表
   - 初始状态设置为"活跃"

2. **状态变更**：
   - 连续7天无交易的收藏集标记为"不活跃"
   - 重新出现交易的收藏集恢复为"活跃"状态

3. **指标更新**：
   - 定期更新价格、交易量、销售量等基本指标
   - 更新与鲸鱼相关的统计指标

### 5.3 日期维度管理

1. **初始化**：
   - 一次性生成多年的日期数据
   - 包括所有必要的时间相关属性

2. **扩展**：
   - 定期检查是否需要扩展日期范围
   - 按需添加新的日期记录

## 6. 常见问题与解决方案

1. **维度数据不一致问题**：
   - 症状：同一维度在不同表中有不同的值
   - 解决方案：建立主数据管理机制，确保单一数据源

2. **维度更新延迟问题**：
   - 症状：维度数据未及时反映最新状态
   - 解决方案：调整调度策略，确保关键维度优先更新

3. **历史维度变更问题**：
   - 症状：需要追溯维度的历史变化
   - 解决方案：实现缓慢变化维度（SCD）机制，记录变更历史

## 7. 运维建议

1. 定期检查维度表的增长情况，特别是随时间累积的维度表
2. 监控维度数据的质量，确保关键指标的准确性
3. 维护维度表的数据字典和血缘关系，方便理解和问题排查
4. 对于频繁访问的维度表，考虑增加适当的索引或优化存储结构
5. 定期清理不再使用的维度值，保持维度表的精简 