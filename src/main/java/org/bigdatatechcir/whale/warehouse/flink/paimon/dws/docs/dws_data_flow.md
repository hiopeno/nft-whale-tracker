# NFT Whale Tracker DWS层数据流转文档

## 1. 概述

本文档详细描述了NFT Whale Tracker项目中DWS层（Data Warehouse Service，数据服务层）的数据流转过程。DWS层是在DWD层和DIM层基础上进行面向主题的汇总分析，将多维度数据整合为特定业务场景需要的分析结果，为ADS层提供数据支持。

## 2. 数据流转架构

整个DWS层的数据流转过程可以分为以下几个关键步骤：

```
DWD/DIM层数据 -> 多维度关联 -> 聚合计算 -> 统计分析 -> DWS层表
```

## 3. 数据处理流程

### 3.1 dws_whale_daily_stats 处理流程

该表存储鲸鱼钱包的每日交易汇总数据，主要来源于DWD层的`dwd_wallet_daily_stats`表和DIM层的`dim_whale_address`表。

处理流程：
1. 从`dwd_wallet_daily_stats`获取钱包的每日交易数据
2. 关联`dim_whale_address`获取鲸鱼的维度信息
3. 计算当日交易相关指标（如交易次数、交易金额、利润等）
4. 计算持仓价值和持仓变化
5. 计算累计指标（累计利润、累计ROI等）
6. 计算影响力评分
7. 计算排名指标

SQL处理逻辑示例：
```sql
INSERT INTO dws_whale_daily_stats
WITH prev_day_stats AS (
    -- 获取前一天的统计数据，用于计算变化
    SELECT 
        wallet_address,
        holding_value_eth
    FROM 
        dws_whale_daily_stats
    WHERE 
        stat_date = DATE_SUB(CURRENT_DATE, 1)
),
daily_holdings AS (
    -- 估算当日持仓价值
    SELECT 
        tx.tx_date,
        tx.to_address AS wallet_address,
        SUM(tx.trade_price_eth) AS holding_value_eth,
        COUNT(DISTINCT tx.contract_address) AS holding_collections,
        COUNT(*) AS holding_nfts
    FROM 
        dwd_whale_transaction_detail tx
    LEFT JOIN 
        dwd_whale_transaction_detail sell ON tx.to_address = sell.from_address 
        AND tx.contract_address = sell.contract_address 
        AND tx.token_id = sell.token_id
        AND sell.tx_date > tx.tx_date
    WHERE 
        tx.to_is_whale = TRUE
        AND sell.tx_hash IS NULL -- 未被卖出的NFT
    GROUP BY 
        tx.tx_date,
        tx.to_address
),
success_rates AS (
    -- 计算成功率
    SELECT 
        tx.tx_date,
        tx.from_address AS wallet_address,
        -- 7天成功率
        (COUNT(CASE WHEN tx.tx_date >= DATE_SUB(CURRENT_DATE, 7) AND tx.trade_price_eth > tx.floor_price_eth THEN 1 END) * 100.0 / 
         NULLIF(COUNT(CASE WHEN tx.tx_date >= DATE_SUB(CURRENT_DATE, 7) THEN 1 END), 0)) AS success_rate_7d,
        -- 30天成功率
        (COUNT(CASE WHEN tx.tx_date >= DATE_SUB(CURRENT_DATE, 30) AND tx.trade_price_eth > tx.floor_price_eth THEN 1 END) * 100.0 / 
         NULLIF(COUNT(CASE WHEN tx.tx_date >= DATE_SUB(CURRENT_DATE, 30) THEN 1 END), 0)) AS success_rate_30d
    FROM 
        dwd_whale_transaction_detail tx
    WHERE 
        tx.from_is_whale = TRUE
    GROUP BY 
        tx.tx_date,
        tx.from_address
),
holding_days AS (
    -- 计算平均持有天数
    SELECT 
        sell.tx_date,
        sell.from_address AS wallet_address,
        AVG(DATEDIFF(sell.tx_date, buy.tx_date)) AS avg_holding_days
    FROM 
        dwd_whale_transaction_detail sell
    JOIN 
        dwd_whale_transaction_detail buy ON sell.from_address = buy.to_address
        AND sell.contract_address = buy.contract_address
        AND sell.token_id = buy.token_id
        AND sell.tx_date > buy.tx_date
    WHERE 
        sell.from_is_whale = TRUE
        AND sell.tx_date = CURRENT_DATE
    GROUP BY 
        sell.tx_date,
        sell.from_address
),
whale_rankings AS (
    -- 计算排名
    SELECT 
        wallet_date,
        wallet_address,
        ROW_NUMBER() OVER (PARTITION BY wallet_date ORDER BY buy_volume_eth + sell_volume_eth DESC) AS rank_by_volume,
        ROW_NUMBER() OVER (PARTITION BY wallet_date ORDER BY profit_eth DESC) AS rank_by_profit,
        ROW_NUMBER() OVER (PARTITION BY wallet_date ORDER BY 
            CASE WHEN buy_volume_eth > 0 THEN (profit_eth / buy_volume_eth) * 100 ELSE 0 END DESC) AS rank_by_roi
    FROM 
        dwd_wallet_daily_stats
    WHERE 
        wallet_date = CURRENT_DATE
)
SELECT 
    wd.wallet_date AS stat_date,
    wd.wallet_address,
    dwa.whale_type,
    dwa.status AS wallet_status,
    wd.total_tx_count AS daily_trade_count,
    wd.buy_count AS daily_buy_count,
    wd.sell_count AS daily_sell_count,
    wd.buy_volume_eth AS daily_buy_volume_eth,
    wd.sell_volume_eth AS daily_sell_volume_eth,
    wd.profit_eth AS daily_profit_eth,
    CASE WHEN wd.buy_volume_eth > 0 THEN (wd.profit_eth / wd.buy_volume_eth) * 100 ELSE 0 END AS daily_roi_percentage,
    wd.collections_traded AS daily_collections_traded,
    dwa.total_profit_eth AS accu_profit_eth,
    dwa.roi_percentage AS accu_roi_percentage,
    COALESCE(h.holding_value_eth, 0) AS holding_value_eth,
    CASE 
        WHEN p.holding_value_eth > 0 
        THEN ((COALESCE(h.holding_value_eth, 0) - p.holding_value_eth) / p.holding_value_eth) * 100 
        ELSE 0 
    END AS holding_value_change_1d,
    COALESCE(h.holding_collections, 0) AS holding_collections,
    COALESCE(h.holding_nfts, 0) AS holding_nfts,
    dwa.whale_score AS influence_score,
    COALESCE(sr.success_rate_7d, 0) AS success_rate_7d,
    COALESCE(sr.success_rate_30d, 0) AS success_rate_30d,
    COALESCE(hd.avg_holding_days, dwa.avg_hold_days) AS avg_holding_days,
    wd.is_top30_volume,
    wd.is_top100_balance,
    COALESCE(r.rank_by_volume, 0) AS rank_by_volume,
    COALESCE(r.rank_by_profit, 0) AS rank_by_profit,
    COALESCE(r.rank_by_roi, 0) AS rank_by_roi,
    'dim_whale_address,dwd_wallet_daily_stats' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    dwd_wallet_daily_stats wd
JOIN 
    dim_whale_address dwa ON wd.wallet_address = dwa.wallet_address
LEFT JOIN 
    daily_holdings h ON wd.wallet_date = h.tx_date AND wd.wallet_address = h.wallet_address
LEFT JOIN 
    prev_day_stats p ON wd.wallet_address = p.wallet_address
LEFT JOIN 
    success_rates sr ON wd.wallet_date = sr.tx_date AND wd.wallet_address = sr.wallet_address
LEFT JOIN 
    holding_days hd ON wd.wallet_date = hd.tx_date AND wd.wallet_address = hd.wallet_address
LEFT JOIN 
    whale_rankings r ON wd.wallet_date = r.wallet_date AND wd.wallet_address = r.wallet_address
WHERE 
    wd.wallet_date = CURRENT_DATE
    AND dwa.is_whale = TRUE; 
```

### 3.2 dws_collection_whale_flow 处理流程

该表存储收藏集的鲸鱼资金流向数据，主要来源于DWD层的`dwd_whale_transaction_detail`表和DIM层的`dim_collection_info`与`dim_whale_address`表。

处理流程：
1. 从`dwd_whale_transaction_detail`获取鲸鱼相关的交易数据
2. 关联`dim_collection_info`获取收藏集信息
3. 关联`dim_whale_address`获取鲸鱼类型信息
4. 按收藏集和鲸鱼类型维度聚合计算流入流出指标
5. 计算净流入量和鲸鱼交易占比
6. 计算7天和30天累计净流入
7. 计算排名指标

SQL处理逻辑示例：
```sql
INSERT INTO dws_collection_whale_flow
WITH daily_whale_txs AS (
    -- 按收藏集和鲸鱼类型分组的当日交易数据
    SELECT 
        tx.tx_date,
        tx.contract_address,
        tx.collection_name,
        w.whale_type,
        COUNT(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN 1 END) AS whale_buy_count,
        COUNT(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN 1 END) AS whale_sell_count,
        SUM(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.trade_price_eth ELSE 0 END) AS whale_buy_volume_eth,
        SUM(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.trade_price_eth ELSE 0 END) AS whale_sell_volume_eth,
        COUNT(DISTINCT CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.to_address END) AS unique_whale_buyers,
        COUNT(DISTINCT CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.from_address END) AS unique_whale_sellers,
        AVG(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.trade_price_eth END) AS whale_buy_avg_price_eth,
        AVG(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.trade_price_eth END) AS whale_sell_avg_price_eth
    FROM 
        dwd_whale_transaction_detail tx
    JOIN 
        dim_whale_address w ON (tx.to_is_whale AND tx.to_address = w.wallet_address) OR (tx.from_is_whale AND tx.from_address = w.wallet_address)
    WHERE 
        tx.tx_date = CURRENT_DATE
    GROUP BY 
        tx.tx_date,
        tx.contract_address,
        tx.collection_name,
        w.whale_type
),
collection_stats AS (
    -- 收藏集当日总体统计
    SELECT 
        tx_date,
        contract_address,
        collection_name,
        COUNT(*) AS total_txs,
        SUM(trade_price_eth) AS total_volume_eth,
        AVG(trade_price_eth) AS avg_price_eth,
        MAX(floor_price_eth) AS floor_price_eth,
        BOOL_OR(is_in_working_set) AS is_in_working_set
    FROM 
        dwd_whale_transaction_detail
    WHERE 
        tx_date = CURRENT_DATE
    GROUP BY 
        tx_date,
        contract_address,
        collection_name
),
whale_ownership AS (
    -- 计算鲸鱼持有比例
    SELECT 
        ci.collection_address,
        ci.whale_ownership_percentage
    FROM 
        dim_collection_info ci
),
historical_flows AS (
    -- 计算历史净流入
    SELECT 
        contract_address,
        whale_type,
        SUM(CASE WHEN tx_date >= DATE_SUB(CURRENT_DATE, 7) THEN net_flow_eth ELSE 0 END) AS accu_net_flow_7d,
        SUM(CASE WHEN tx_date >= DATE_SUB(CURRENT_DATE, 30) THEN net_flow_eth ELSE 0 END) AS accu_net_flow_30d
    FROM 
        dws_collection_whale_flow
    WHERE 
        tx_date < CURRENT_DATE
    GROUP BY 
        contract_address,
        whale_type
),
rankings AS (
    -- 计算排名
    SELECT 
        w.tx_date,
        w.contract_address,
        w.whale_type,
        ROW_NUMBER() OVER (PARTITION BY w.tx_date, w.whale_type ORDER BY (w.whale_buy_volume_eth + w.whale_sell_volume_eth) DESC) AS rank_by_whale_volume,
        ROW_NUMBER() OVER (PARTITION BY w.tx_date, w.whale_type ORDER BY (w.whale_buy_volume_eth - w.whale_sell_volume_eth) DESC) AS rank_by_net_flow
    FROM 
        daily_whale_txs w
)
SELECT 
    dwt.tx_date AS stat_date,
    dwt.contract_address AS collection_address,
    dwt.collection_name,
    dwt.whale_type,
    dwt.whale_buy_count,
    dwt.whale_sell_count,
    dwt.whale_buy_volume_eth,
    dwt.whale_sell_volume_eth,
    (dwt.whale_buy_volume_eth - dwt.whale_sell_volume_eth) AS net_flow_eth,
    CASE WHEN (dwt.whale_buy_volume_eth - dwt.whale_sell_volume_eth) > 0 THEN TRUE ELSE FALSE END AS is_net_inflow,
    dwt.unique_whale_buyers,
    dwt.unique_whale_sellers,
    CASE 
        WHEN cs.total_volume_eth > 0 
        THEN ((dwt.whale_buy_volume_eth + dwt.whale_sell_volume_eth) / cs.total_volume_eth) * 100 
        ELSE 0 
    END AS whale_trading_percentage,
    dwt.whale_buy_avg_price_eth,
    dwt.whale_sell_avg_price_eth,
    cs.avg_price_eth,
    cs.floor_price_eth,
    cs.total_volume_eth,
    COALESCE(wo.whale_ownership_percentage, 0) AS whale_ownership_percentage,
    COALESCE(hf.accu_net_flow_7d, 0) + (dwt.whale_buy_volume_eth - dwt.whale_sell_volume_eth) AS accu_net_flow_7d,
    COALESCE(hf.accu_net_flow_30d, 0) + (dwt.whale_buy_volume_eth - dwt.whale_sell_volume_eth) AS accu_net_flow_30d,
    COALESCE(r.rank_by_whale_volume, 0) AS rank_by_whale_volume,
    COALESCE(r.rank_by_net_flow, 0) AS rank_by_net_flow,
    cs.is_in_working_set,
    'dim_collection_info,dim_whale_address,dwd_whale_transaction_detail' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    daily_whale_txs dwt
JOIN 
    collection_stats cs ON dwt.tx_date = cs.tx_date AND dwt.contract_address = cs.contract_address
LEFT JOIN 
    whale_ownership wo ON dwt.contract_address = wo.collection_address
LEFT JOIN 
    historical_flows hf ON dwt.contract_address = hf.contract_address AND dwt.whale_type = hf.whale_type
LEFT JOIN 
    rankings r ON dwt.tx_date = r.tx_date AND dwt.contract_address = r.contract_address AND dwt.whale_type = r.whale_type;
```


## 4. 执行流程与调度

### 4.1 完整执行流程

DWS层数据处理通常按以下顺序执行：

1. 执行`dws_whale_daily_stats`表的数据处理：
   ```bash
   ./run_dws_whale_daily_stats.sh
   ```

2. 执行`dws_collection_whale_flow`表的数据处理：
   ```bash
   ./run_dws_collection_whale_flow.sh
   ```

### 4.2 调度策略

DWS层数据处理通常在DIM层数据完成处理后执行，建议采用以下调度策略：

- **调度频率**：每日一次，在DIM层处理完成后

- **依赖关系**：
  - 依赖DIM层相关表的处理完成
  - `dws_whale_portfolio_trend`依赖`dws_whale_daily_stats`的完成

- **超时设置**：90分钟

- **失败处理**：失败时自动重试2次，然后告警

### 4.3 数据质量监控

DWS层应设置以下数据质量监控规则：

1. **完整性检查**：
   - 确保每日数据完整性，不缺少关键鲸鱼或收藏集的数据
   - 检查主键的唯一性

2. **准确性检查**：
   - 验证计算指标是否在合理范围内
   - 检查关键聚合指标的准确性

3. **一致性检查**：
   - 跨表指标一致性检查（如鲸鱼数量和流向统计）
   - 时间序列一致性检查（与前一天数据的合理变化）

## 5. 数据应用场景

DWS层的数据主要支持以下应用场景：

1. **鲸鱼行为分析**：
   - 追踪鲸鱼的交易策略和表现
   - 对比不同类型鲸鱼的行为特征

2. **收藏集鲸鱼流向监控**：
   - 监控重要收藏集的鲸鱼资金流向
   - 预测潜在的市场趋势变化

3. **投资组合分析**：
   - 分析成功鲸鱼的投资组合特点
   - 提供投资组合优化建议

4. **鲸鱼社交网络分析**：
   - 识别相关联的鲸鱼群体
   - 分析鲸鱼之间的交易影响关系

## 6. 常见问题与解决方案

1. **数据计算性能问题**：
   - 症状：DWS层SQL执行时间过长
   - 解决方案：优化SQL，引入中间表，或调整并行度

2. **历史数据累积问题**：
   - 症状：累积指标（如7/30天）计算不准确
   - 解决方案：建立滑动窗口计算机制，或定期校准累积值

3. **数据不一致问题**：
   - 症状：不同表之间的统计结果不一致
   - 解决方案：统一口径，建立主表和从表的关系

## 7. 运维建议

1. 定期监控DWS层表的数据增长和性能
2. 设置关键指标的阈值告警，及时发现异常数据
3. 对历史数据进行归档和分区管理，提高查询效率
4. 建立数据质量报告机制，定期检查数据的准确性和完整性
5. 针对关键查询场景优化SQL和表结构