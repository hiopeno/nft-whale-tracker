# NFT Whale Tracker ADS层数据流转文档

## 1. 概述

本文档详细描述了NFT Whale Tracker项目中ADS层（Application Data Service，应用数据服务层）的数据流转过程。ADS层是数据仓库的最上层，直接面向应用和业务分析需求，主要整合DWS层和DIM层的数据，生成符合特定业务场景的数据产品。

## 2. 数据流转架构

整个ADS层的数据流转过程可以分为以下几个关键步骤：

```
DWS/DIM层数据 -> 主题聚焦 -> 指标筛选 -> 排序与分组 -> ADS层表
```

## 3. 数据处理流程

### 3.1 ads_top_profit_whales 处理流程

该表存储收益额Top10鲸鱼钱包，主要来源于DWS层的`dws_whale_daily_stats`表和DIM层的`dim_whale_address`表。

处理流程：
1. 从`dws_whale_daily_stats`和`dim_whale_address`汇总鲸鱼收益数据
2. 按总收益额进行排序
3. 识别每个鲸鱼的最佳收藏集
4. 提取Top10收益鲸鱼列表

SQL处理逻辑示例：
```sql
INSERT INTO ads_top_profit_whales
WITH profit_ranks AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        dwa.wallet_address,
        dwa.whale_type,
        dwa.total_profit_eth,
        dwa.total_profit_usd,
        dwa.total_tx_count,
        dwa.first_track_date,
        DATEDIFF(CURRENT_DATE, dwa.first_track_date) AS tracking_days,
        dwa.whale_score AS influence_score,
        ROW_NUMBER() OVER (ORDER BY dwa.total_profit_eth DESC) AS rank_num
    FROM 
        dim_whale_address dwa
    WHERE 
        dwa.is_whale = TRUE
        AND dwa.status = 'ACTIVE'
),
whale_profit_stats AS (
    -- 计算近期利润
    SELECT 
        wallet_address,
        SUM(CASE WHEN stat_date >= DATE_SUB(CURRENT_DATE, 7) THEN daily_profit_eth ELSE 0 END) AS profit_7d_eth,
        SUM(CASE WHEN stat_date >= DATE_SUB(CURRENT_DATE, 30) THEN daily_profit_eth ELSE 0 END) AS profit_30d_eth
    FROM 
        dws_whale_daily_stats
    GROUP BY 
        wallet_address
),
best_collections AS (
    -- 识别最佳收藏集
    SELECT 
        w.wallet_address,
        c.collection_name AS best_collection,
        MAX(cp.profit_eth) AS best_collection_profit_eth
    FROM (
        SELECT 
            wallet_address,
            contract_address,
            SUM(CASE WHEN from_address = wallet_address THEN trade_price_eth ELSE 0 END) - 
            SUM(CASE WHEN to_address = wallet_address THEN trade_price_eth ELSE 0 END) AS profit_eth
        FROM 
            dwd_whale_transaction_detail
        WHERE 
            (from_is_whale = TRUE OR to_is_whale = TRUE)
        GROUP BY 
            wallet_address, 
            contract_address
    ) cp
    JOIN 
        profit_ranks w ON cp.wallet_address = w.wallet_address
    JOIN 
        dim_collection_info c ON cp.contract_address = c.collection_address
    GROUP BY 
        w.wallet_address,
        c.collection_name
)
SELECT 
    r.snapshot_date,
    r.wallet_address,
    r.rank_num,
    CASE 
        WHEN r.whale_type = 'SMART' THEN 'Smart Whale'
        WHEN r.whale_type = 'DUMB' THEN 'Dumb Whale'
        ELSE 'Tracking Whale'
    END AS wallet_tag,
    r.total_profit_eth,
    r.total_profit_usd,
    COALESCE(ps.profit_7d_eth, 0) AS profit_7d_eth,
    COALESCE(ps.profit_30d_eth, 0) AS profit_30d_eth,
    COALESCE(bc.best_collection, 'Unknown') AS best_collection,
    COALESCE(bc.best_collection_profit_eth, 0) AS best_collection_profit_eth,
    r.total_tx_count,
    r.first_track_date,
    r.tracking_days,
    r.influence_score,
    'dws_whale_daily_stats,dim_whale_address' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    profit_ranks r
LEFT JOIN 
    whale_profit_stats ps ON r.wallet_address = ps.wallet_address
LEFT JOIN 
    best_collections bc ON r.wallet_address = bc.wallet_address
WHERE 
    r.rank_num <= 10;
```

### 3.2 ads_top_roi_whales 处理流程

该表存储收益率Top10鲸鱼钱包，主要来源于DWS层的`dws_whale_daily_stats`表和DIM层的`dim_whale_address`表。

处理流程：
1. 从`dws_whale_daily_stats`和`dim_whale_address`汇总鲸鱼ROI数据
2. 按投资回报率进行排序
3. 计算每个钱包的最佳收藏集ROI和持有时间
4. 提取Top10 ROI鲸鱼列表

SQL处理逻辑示例：
```sql
INSERT INTO ads_top_roi_whales
WITH roi_ranks AS (
    SELECT 
        CURRENT_DATE AS snapshot_date,
        dwa.wallet_address,
        dwa.whale_type,
        dwa.roi_percentage,
        dwa.total_buy_volume_eth,
        dwa.total_sell_volume_eth,
        dwa.total_profit_eth,
        dwa.first_track_date,
        dwa.whale_score AS influence_score,
        dwa.avg_hold_days,
        ROW_NUMBER() OVER (ORDER BY dwa.roi_percentage DESC) AS rank_num
    FROM 
        dim_whale_address dwa
    WHERE 
        dwa.is_whale = TRUE
        AND dwa.status = 'ACTIVE'
        AND dwa.total_buy_volume_eth > 0 -- 确保有有效的ROI计算
        AND dwa.total_tx_count >= 10 -- 确保有足够的交易记录
),
recent_roi AS (
    -- 计算近期ROI
    SELECT 
        wallet_address,
        CASE 
            WHEN SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN daily_buy_volume_eth ELSE 0 END) > 0 
            THEN SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN daily_profit_eth ELSE 0 END) * 100 / 
                 SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -7, CURRENT_DATE) THEN daily_buy_volume_eth ELSE 0 END)
            ELSE 0
        END AS roi_7d_percentage,
        CASE 
            WHEN SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN daily_buy_volume_eth ELSE 0 END) > 0 
            THEN SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN daily_profit_eth ELSE 0 END) * 100 / 
                 SUM(CASE WHEN stat_date >= TIMESTAMPADD(DAY, -30, CURRENT_DATE) THEN daily_buy_volume_eth ELSE 0 END)
            ELSE 0
        END AS roi_30d_percentage
    FROM 
        dws_whale_daily_stats
    GROUP BY 
        wallet_address
),
wallet_collection_roi AS (
    -- 计算每个钱包的每个收藏集ROI
    SELECT
        t.contract_address,
        SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) AS buy_value,
        SUM(CASE WHEN t.from_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) AS sell_value,
        CASE 
            WHEN SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) > 0
            THEN (SUM(CASE WHEN t.from_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) - 
                 SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END)) * 100 /
                 SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END)
            ELSE 0
        END AS roi_percentage,
        w.wallet_address
    FROM 
        dwd_whale_transaction_detail t
    JOIN 
        roi_ranks w 
    ON 
        t.from_address = w.wallet_address OR t.to_address = w.wallet_address
    WHERE 
        (t.from_is_whale = TRUE OR t.to_is_whale = TRUE)
    GROUP BY 
        t.contract_address,
        w.wallet_address
    HAVING 
        SUM(CASE WHEN t.to_address = w.wallet_address THEN t.trade_price_eth ELSE 0 END) > 0
),
collection_roi_ranked AS (
    -- 为每个钱包的收藏集ROI排序
    SELECT
        wallet_address,
        contract_address,
        roi_percentage,
        ROW_NUMBER() OVER (PARTITION BY wallet_address ORDER BY roi_percentage DESC) AS roi_rank
    FROM 
        wallet_collection_roi
),
best_collection_roi AS (
    -- 选择每个钱包的最佳ROI收藏集
    SELECT 
        cr.wallet_address,
        c.collection_name AS best_collection_roi,
        cr.roi_percentage AS best_collection_roi_percentage
    FROM 
        collection_roi_ranked cr
    JOIN 
        dim_collection_info c ON cr.contract_address = c.collection_address
    WHERE 
        cr.roi_rank = 1
)
SELECT 
    r.snapshot_date,
    r.wallet_address,
    CAST(r.rank_num AS INT) AS rank_num,
    CASE 
        WHEN r.whale_type = 'SMART' THEN 'Smart Whale'
        WHEN r.whale_type = 'DUMB' THEN 'Dumb Whale'
        ELSE 'Tracking Whale'
    END AS wallet_tag,
    r.roi_percentage,
    r.total_buy_volume_eth,
    r.total_sell_volume_eth,
    r.total_profit_eth,
    COALESCE(rr.roi_7d_percentage, 0) AS roi_7d_percentage,
    COALESCE(rr.roi_30d_percentage, 0) AS roi_30d_percentage,
    COALESCE(bc.best_collection_roi, 'Unknown') AS best_collection_roi,
    COALESCE(bc.best_collection_roi_percentage, 0) AS best_collection_roi_percentage,
    r.avg_hold_days,
    r.first_track_date,
    r.influence_score,
    'dws_whale_daily_stats,dim_whale_address' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    roi_ranks r
LEFT JOIN 
    recent_roi rr ON r.wallet_address = rr.wallet_address
LEFT JOIN 
    best_collection_roi bc ON r.wallet_address = bc.wallet_address
WHERE 
    r.rank_num <= 10;
```

### 3.3 ads_whale_tracking_list 处理流程

该表存储鲸鱼追踪名单，包括追踪中、聪明、愚蠢类型的鲸鱼，主要来源于DIM层的`dim_whale_address`表和DWS层的`dws_whale_daily_stats`表。

处理流程：
1. 从`dim_whale_address`获取所有活跃鲸鱼
2. 关联`dws_whale_daily_stats`获取最新统计数据
3. 生成追踪ID和统计数据
4. 合并所有类型的鲸鱼名单

SQL处理逻辑示例：
```sql
INSERT INTO ads_whale_tracking_list
SELECT 
    CURRENT_DATE AS snapshot_date,
    dwa.wallet_address,
    dwa.whale_type AS wallet_type,
    CONCAT('WHL_', DATE_FORMAT(CURRENT_DATE, 'yyyyMMdd'), 
           LPAD(CAST(ROW_NUMBER() OVER (ORDER BY dwa.whale_score DESC) AS STRING), 2, '0')) AS tracking_id,
    dwa.first_track_date,
    DATEDIFF(CURRENT_DATE, dwa.first_track_date) AS tracking_days,
    dwa.last_active_date,
    dwa.status,
    dwa.total_profit_eth,
    dwa.total_profit_usd,
    dwa.roi_percentage,
    dwa.whale_score AS influence_score,
    dwa.total_tx_count,
    dwa.success_rate,
    dwa.favorite_collections,
    dwa.inactive_days,
    COALESCE(dws.is_top30_volume, FALSE) AS is_top30_volume,
    COALESCE(dws.is_top100_balance, FALSE) AS is_top100_balance,
    COALESCE(dws.rank_by_volume, 0) AS rank_by_volume,
    COALESCE(dws.rank_by_profit, 0) AS rank_by_profit,
    'dws_whale_daily_stats,dim_whale_address' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dim_whale_address dwa
LEFT JOIN 
    dws_whale_daily_stats dws ON dwa.wallet_address = dws.wallet_address AND dws.stat_date = CURRENT_DATE
WHERE 
    dwa.is_whale = TRUE
    AND (dwa.status = 'ACTIVE' OR dwa.inactive_days <= 7); -- 包括最近7天变为不活跃的鲸鱼
```

### 3.4 ads_tracking_whale_collection_flow 处理流程

该表存储工作集收藏集中追踪鲸鱼净流入/流出Top10，主要来源于DWS层的`dws_collection_whale_flow`表。

处理流程：
1. 从`dws_collection_whale_flow`获取收藏集的鲸鱼流向数据
2. 按净流入和净流出分别计算排名
3. 关联收藏集维度获取更多信息
4. 提取净流入和净流出Top10列表

SQL处理逻辑示例：
```sql
INSERT INTO ads_tracking_whale_collection_flow
WITH inflow_collections AS (
    -- 计算净流入Top10
    SELECT 
        CURRENT_DATE AS snapshot_date,
        cf.collection_address,
        MAX(cf.collection_name) AS collection_name,
        'INFLOW' AS flow_direction,
        ROW_NUMBER() OVER (ORDER BY SUM(cf.net_flow_eth) DESC) AS rank_num,
        SUM(cf.net_flow_eth) AS net_flow_eth,
        SUM(cf.net_flow_eth) * 2500.00 AS net_flow_usd, -- 示例USD汇率
        SUM(cf.accu_net_flow_7d) AS net_flow_7d_eth,
        SUM(cf.accu_net_flow_30d) AS net_flow_30d_eth,
        AVG(cf.floor_price_eth) AS floor_price_eth,
        NULL AS floor_price_change_1d, -- 需要其他数据源
        SUM(cf.unique_whale_buyers) AS unique_whale_buyers,
        SUM(cf.unique_whale_sellers) AS unique_whale_sellers,
        AVG(cf.whale_trading_percentage) AS whale_trading_percentage,
        SUM(CASE WHEN cf.whale_type = 'SMART' THEN cf.net_flow_eth ELSE 0 END) / 
        NULLIF(SUM(cf.net_flow_eth), 0) * 100 AS smart_whale_percentage,
        SUM(CASE WHEN cf.whale_type = 'DUMB' THEN cf.net_flow_eth ELSE 0 END) / 
        NULLIF(SUM(cf.net_flow_eth), 0) * 100 AS dumb_whale_percentage,
        CASE 
            WHEN SUM(cf.net_flow_eth) > 10 THEN 'STRONG_INFLOW'
            WHEN SUM(cf.net_flow_eth) > 5 THEN 'MODERATE_INFLOW'
            ELSE 'SLIGHT_INFLOW'
        END AS trend_indicator
    FROM 
        dws_collection_whale_flow cf
    WHERE 
        cf.stat_date = CURRENT_DATE
        AND cf.is_in_working_set = TRUE
    GROUP BY 
        cf.collection_address
    HAVING 
        SUM(cf.net_flow_eth) > 0
),
outflow_collections AS (
    -- 计算净流出Top10
    SELECT 
        CURRENT_DATE AS snapshot_date,
        cf.collection_address,
        MAX(cf.collection_name) AS collection_name,
        'OUTFLOW' AS flow_direction,
        ROW_NUMBER() OVER (ORDER BY SUM(cf.net_flow_eth) ASC) AS rank_num,
        SUM(cf.net_flow_eth) AS net_flow_eth,
        SUM(cf.net_flow_eth) * 2500.00 AS net_flow_usd, -- 示例USD汇率
        SUM(cf.accu_net_flow_7d) AS net_flow_7d_eth,
        SUM(cf.accu_net_flow_30d) AS net_flow_30d_eth,
        AVG(cf.floor_price_eth) AS floor_price_eth,
        NULL AS floor_price_change_1d, -- 需要其他数据源
        SUM(cf.unique_whale_buyers) AS unique_whale_buyers,
        SUM(cf.unique_whale_sellers) AS unique_whale_sellers,
        AVG(cf.whale_trading_percentage) AS whale_trading_percentage,
        SUM(CASE WHEN cf.whale_type = 'SMART' THEN cf.net_flow_eth ELSE 0 END) / 
        NULLIF(SUM(cf.net_flow_eth), 0) * 100 AS smart_whale_percentage,
        SUM(CASE WHEN cf.whale_type = 'DUMB' THEN cf.net_flow_eth ELSE 0 END) / 
        NULLIF(SUM(cf.net_flow_eth), 0) * 100 AS dumb_whale_percentage,
        CASE 
            WHEN SUM(cf.net_flow_eth) < -10 THEN 'STRONG_OUTFLOW'
            WHEN SUM(cf.net_flow_eth) < -5 THEN 'MODERATE_OUTFLOW'
            ELSE 'SLIGHT_OUTFLOW'
        END AS trend_indicator
    FROM 
        dws_collection_whale_flow cf
    WHERE 
        cf.stat_date = CURRENT_DATE
        AND cf.is_in_working_set = TRUE
    GROUP BY 
        cf.collection_address
    HAVING 
        SUM(cf.net_flow_eth) < 0
)
SELECT 
    snapshot_date,
    collection_address,
    collection_name,
    flow_direction,
    rank_num,
    net_flow_eth,
    net_flow_usd,
    net_flow_7d_eth,
    net_flow_30d_eth,
    floor_price_eth,
    floor_price_change_1d,
    unique_whale_buyers,
    unique_whale_sellers,
    whale_trading_percentage,
    smart_whale_percentage,
    dumb_whale_percentage,
    trend_indicator,
    'dws_collection_whale_flow' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    inflow_collections
WHERE 
    rank_num <= 10

UNION ALL

SELECT 
    snapshot_date,
    collection_address,
    collection_name,
    flow_direction,
    rank_num,
    net_flow_eth,
    net_flow_usd,
    net_flow_7d_eth,
    net_flow_30d_eth,
    floor_price_eth,
    floor_price_change_1d,
    unique_whale_buyers,
    unique_whale_sellers,
    whale_trading_percentage,
    smart_whale_percentage,
    dumb_whale_percentage,
    trend_indicator,
    'dws_collection_whale_flow' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    outflow_collections
WHERE 
    rank_num <= 10;
```

### 3.5 ads_smart_whale_collection_flow 与 ads_dumb_whale_collection_flow 处理流程

这两个表分别存储工作集收藏集中聪明鲸鱼和愚蠢鲸鱼的净流入/流出Top10，主要来源于DWS层的`dws_collection_whale_flow`表，处理逻辑类似，这里以聪明鲸鱼为例。

处理流程：
1. 从`dws_collection_whale_flow`筛选对应鲸鱼类型的交易数据
2. 按净流入和净流出分别计算排名
3. 提取净流入和净流出Top10列表

SQL处理逻辑示例（以聪明鲸鱼为例）：
```sql
INSERT INTO ads_smart_whale_collection_flow
WITH smart_inflow_collections AS (
    -- 计算聪明鲸鱼净流入Top10
    SELECT 
        CURRENT_DATE AS snapshot_date,
        cf.collection_address,
        cf.collection_name,
        'INFLOW' AS flow_direction,
        ROW_NUMBER() OVER (ORDER BY cf.net_flow_eth DESC) AS rank_num,
        cf.net_flow_eth AS smart_whale_net_flow_eth,
        cf.net_flow_eth * 2500.00 AS smart_whale_net_flow_usd, -- 示例USD汇率
        cf.accu_net_flow_7d AS smart_whale_net_flow_7d_eth,
        cf.accu_net_flow_30d AS smart_whale_net_flow_30d_eth,
        cf.unique_whale_buyers AS smart_whale_buyers,
        cf.unique_whale_sellers AS smart_whale_sellers,
        cf.whale_buy_volume_eth AS smart_whale_buy_volume_eth,
        cf.whale_sell_volume_eth AS smart_whale_sell_volume_eth,
        cf.whale_trading_percentage AS smart_whale_trading_percentage,
        cf.floor_price_eth,
        NULL AS floor_price_change_1d, -- 需要其他数据源
        CASE 
            WHEN cf.net_flow_eth > 10 THEN 'STRONG_INFLOW'
            WHEN cf.net_flow_eth > 5 THEN 'MODERATE_INFLOW'
            ELSE 'SLIGHT_INFLOW'
        END AS trend_indicator
    FROM 
        dws_collection_whale_flow cf
    WHERE 
        cf.stat_date = CURRENT_DATE
        AND cf.is_in_working_set = TRUE
        AND cf.whale_type = 'SMART'
        AND cf.net_flow_eth > 0
),
smart_outflow_collections AS (
    -- 计算聪明鲸鱼净流出Top10
    SELECT 
        CURRENT_DATE AS snapshot_date,
        cf.collection_address,
        cf.collection_name,
        'OUTFLOW' AS flow_direction,
        ROW_NUMBER() OVER (ORDER BY cf.net_flow_eth ASC) AS rank_num,
        cf.net_flow_eth AS smart_whale_net_flow_eth,
        cf.net_flow_eth * 2500.00 AS smart_whale_net_flow_usd, -- 示例USD汇率
        cf.accu_net_flow_7d AS smart_whale_net_flow_7d_eth,
        cf.accu_net_flow_30d AS smart_whale_net_flow_30d_eth,
        cf.unique_whale_buyers AS smart_whale_buyers,
        cf.unique_whale_sellers AS smart_whale_sellers,
        cf.whale_buy_volume_eth AS smart_whale_buy_volume_eth,
        cf.whale_sell_volume_eth AS smart_whale_sell_volume_eth,
        cf.whale_trading_percentage AS smart_whale_trading_percentage,
        cf.floor_price_eth,
        NULL AS floor_price_change_1d, -- 需要其他数据源
        CASE 
            WHEN cf.net_flow_eth < -10 THEN 'STRONG_OUTFLOW'
            WHEN cf.net_flow_eth < -5 THEN 'MODERATE_OUTFLOW'
            ELSE 'SLIGHT_OUTFLOW'
        END AS trend_indicator
    FROM 
        dws_collection_whale_flow cf
    WHERE 
        cf.stat_date = CURRENT_DATE
        AND cf.is_in_working_set = TRUE
        AND cf.whale_type = 'SMART'
        AND cf.net_flow_eth < 0
)
SELECT 
    snapshot_date,
    collection_address,
    collection_name,
    flow_direction,
    rank_num,
    smart_whale_net_flow_eth,
    smart_whale_net_flow_usd,
    smart_whale_net_flow_7d_eth,
    smart_whale_net_flow_30d_eth,
    smart_whale_buyers,
    smart_whale_sellers,
    smart_whale_buy_volume_eth,
    smart_whale_sell_volume_eth,
    smart_whale_trading_percentage,
    floor_price_eth,
    floor_price_change_1d,
    trend_indicator,
    'dws_collection_whale_flow' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    smart_inflow_collections
WHERE 
    rank_num <= 10

UNION ALL

SELECT 
    snapshot_date,
    collection_address,
    collection_name,
    flow_direction,
    rank_num,
    smart_whale_net_flow_eth,
    smart_whale_net_flow_usd,
    smart_whale_net_flow_7d_eth,
    smart_whale_net_flow_30d_eth,
    smart_whale_buyers,
    smart_whale_sellers,
    smart_whale_buy_volume_eth,
    smart_whale_sell_volume_eth,
    smart_whale_trading_percentage,
    floor_price_eth,
    floor_price_change_1d,
    trend_indicator,
    'dws_collection_whale_flow' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    smart_outflow_collections
WHERE 
    rank_num <= 10;
```

## 4. 执行流程与调度

### 4.1 完整执行流程

ADS层数据处理通常按以下顺序执行：

1. 执行`ads_top_profit_whales`和`ads_top_roi_whales`表的数据处理：
   ```bash
   ./run_ads_whale_top_lists.sh
   ```

2. 执行`ads_whale_tracking_list`表的数据处理：
   ```bash
   ./run_ads_whale_tracking.sh
   ```

3. 执行`ads_tracking_whale_collection_flow`、`ads_smart_whale_collection_flow`和`ads_dumb_whale_collection_flow`表的数据处理：
   ```bash
   ./run_ads_collection_flows.sh
   ```

### 4.2 调度策略

ADS层数据处理通常在DWS层数据完成处理后执行，建议采用以下调度策略：

- **调度频率**：每日一次，在DWS层处理完成后

- **依赖关系**：
  - 依赖DWS层和DIM层相关表的处理完成
  - 所有ADS层表可并行处理

- **超时设置**：30分钟

- **失败处理**：失败时自动重试2次，然后告警

### 4.3 数据质量监控

ADS层应设置以下数据质量监控规则：

1. **完整性检查**：
   - 确保Top榜单有足够的记录数
   - 检查关键字段不为空

2. **准确性检查**：
   - 验证排名序列是否连续
   - 检查金额和占比计算是否准确

3. **一致性检查**：
   - 确保相同指标在不同报表中的一致性
   - 检查排名逻辑的一致性

## 5. 数据应用场景

ADS层的数据主要支持以下应用场景：

1. **鲸鱼绩效排行榜**：
   - 展示最赚钱的鲸鱼钱包
   - 展示投资回报率最高的鲸鱼钱包

2. **鲸鱼追踪名单**：
   - 提供完整的鲸鱼追踪名单
   - 标记鲸鱼的类型和活跃状态

3. **收藏集鲸鱼流向分析**：
   - 监控工作集收藏集的鲸鱼资金流向
   - 对比聪明鲸鱼和愚蠢鲸鱼的行为差异

4. **市场趋势预测**：
   - 根据鲸鱼流向预测市场趋势
   - 发现潜在的投资机会

## 6. 常见问题与解决方案

1. **排名计算问题**：
   - 症状：排名不连续或有重复
   - 解决方案：确保使用正确的ROW_NUMBER()函数和排序条件

2. **Top榜单记录不足**：
   - 症状：某些Top榜单记录数不足10条
   - 解决方案：放宽筛选条件或减少榜单规模

3. **数据更新延迟**：
   - 症状：ADS层数据未及时反映最新状态
   - 解决方案：优化调度策略，确保依赖的数据层及时完成

## 7. ads_whale_transactions 数据流转处理流程

该表存储鲸鱼相关的NFT交易详细数据，主要来源于DWD层的`dwd_whale_transaction_detail`表和DIM层的`dim_whale_address`表。

处理流程：
1. 从`dwd_whale_transaction_detail`获取鲸鱼相关交易数据
2. 关联`dim_whale_address`获取鲸鱼类型和影响力评分
3. 计算价格与地板价比率
4. 筛选最近14天的交易数据

SQL处理逻辑示例：
```sql
INSERT INTO ads_whale_transactions
-- 创建临时视图，关联鲸鱼钱包数据
WITH tmp_whale_info AS (
  SELECT 
    w.wallet_address,
    w.whale_type,
    w.whale_score
  FROM 
    dim.dim_whale_address w
  WHERE 
    w.status = 'ACTIVE'
)
SELECT 
  CURRENT_DATE AS snapshot_date,
  t.tx_hash,
  t.contract_address,
  t.token_id,
  CAST(t.tx_timestamp AS TIMESTAMP) AS tx_timestamp,
  t.from_address,
  t.to_address,
  COALESCE(from_whale.whale_type, 'NO_WHALE') AS from_whale_type,
  COALESCE(to_whale.whale_type, 'NO_WHALE') AS to_whale_type,
  CAST(COALESCE(from_whale.whale_score, 0) AS DECIMAL(10,2)) AS from_influence_score,
  CAST(COALESCE(to_whale.whale_score, 0) AS DECIMAL(10,2)) AS to_influence_score,
  t.collection_name,
  CAST(t.trade_price_eth AS DECIMAL(30,10)) AS trade_price_eth,
  CAST(t.trade_price_usd AS DECIMAL(30,10)) AS trade_price_usd,
  CAST(t.floor_price_eth AS DECIMAL(30,10)) AS floor_price_eth,
  CASE 
    WHEN t.floor_price_eth > 0 THEN CAST(t.trade_price_eth / t.floor_price_eth AS DECIMAL(10,2))
    ELSE CAST(NULL AS DECIMAL(10,2))
  END AS price_to_floor_ratio,
  t.platform AS marketplace,
  'dwd_whale_transaction_detail,dim_whale_address' AS data_source,
  CURRENT_TIMESTAMP AS etl_time
FROM 
  dwd.dwd_whale_transaction_detail t
  LEFT JOIN tmp_whale_info from_whale ON t.from_address = from_whale.wallet_address
  LEFT JOIN tmp_whale_info to_whale ON t.to_address = to_whale.wallet_address
WHERE 
  (t.from_is_whale = TRUE OR t.to_is_whale = TRUE OR 
   from_whale.wallet_address IS NOT NULL OR to_whale.wallet_address IS NOT NULL)
  AND t.tx_date BETWEEN CURRENT_DATE - INTERVAL '14' DAY AND CURRENT_DATE;
```

### 数据流转图

```
                            +------------------+
                            |                  |
                    +------>+ dim_whale_address+------+
                    |       |                  |      |
                    |       +------------------+      |
                    |                                 |
+------------------------+                      +------------------------+
|                        |                      |                        |
| dwd_whale_transaction_ |                      |                        |
| detail                 +--------------------->+ ads_whale_transactions |
|                        |                      |                        |
+------------------------+                      +------------------------+
```

### 执行周期

- **更新频率**: 每日一次
- **处理窗口**: 每次处理最近14天的交易数据
- **依赖关系**: 依赖DWD层dwd_whale_transaction_detail表和DIM层dim_whale_address表的更新

### 数据应用场景

1. **鲸鱼交易模式分析**:
   - 分析不同类型鲸鱼的交易平台选择
   - 研究鲸鱼交易与地板价的关系
   - 比较聪明鲸鱼和愚蠢鲸鱼的交易价格差异

2. **鲸鱼关系网络构建**:
   - 分析鲸鱼之间的交易关系
   - 识别高影响力鲸鱼的交易网络

3. **市场指标监控**:
   - 监控鲸鱼交易对地板价的影响
   - 分析不同交易平台的鲸鱼活跃度

4. **交易异常检测**:
   - 识别显著高于或低于地板价的异常交易
   - 监控钱包地址之间的非常规交易模式

## 8. 运维建议

1. 设置关键指标的阈值监控，及时发现异常数据
2. 对历史榜单数据进行归档管理，保留一定时间范围的历史快照
3. 建立数据质量报告机制，定期验证关键指标的准确性
4. 定期与业务方沟通，确保ADS层的输出符合业务需求
5. 为关键应用场景创建优化的视图或具体化视图，提高查询性能 