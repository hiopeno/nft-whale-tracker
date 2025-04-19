# NFT Whale Tracker DWS层数据流转文档

## 1. 概述

本文档详细描述了NFT Whale Tracker项目中DWS层（Data Warehouse Service，数据服务层）的数据流转过程。DWS层是在DWD层和DIM层基础上进行面向主题的汇总分析，将多维度数据整合为特定业务场景需要的分析结果，为ADS层提供数据支持。根据重构要求，DWS层承担起其应有的汇总计算职责，消除了原有的层级职责混乱问题。

## 2. 数据流转架构

整个DWS层的数据流转过程可以分为以下几个关键步骤：

```
DWD层明细数据 ---> 多维度关联 ---> 聚合计算 ---> 统计分析 ---> DWS层表
       |                                              ^
       |                                              |
       |           DIM层维度数据 -------------------- |
```

## 3. 数据处理流程

### 3.1 dws_collection_daily_stats 处理流程

该表存储收藏集的每日统计数据，从原DWD层迁移并增强。主要来源于DWD层的`dwd_transaction_clean`和`dwd_whale_transaction_detail`表。

处理流程：
1. 从`dwd_transaction_clean`获取收藏集的基础交易信息
2. 计算当日交易相关指标（如交易次数、交易金额、平均价格等）
3. 计算地板价（使用当日最后一笔交易价格）
4. 从`dwd_whale_transaction_detail`获取鲸鱼相关交易数据
5. 计算环比指标（如销售量环比、交易额环比、价格环比）
6. 计算排名指标

SQL处理逻辑示例：
```sql
INSERT INTO dws_collection_daily_stats
WITH floor_prices AS (
    -- 获取地板价子查询
    SELECT 
        tx_date,
        contract_address,
        MAX(trade_price_eth) AS floor_price_eth
    FROM (
        SELECT 
            tx_date,
            contract_address,
            trade_price_eth,
            ROW_NUMBER() OVER (PARTITION BY tx_date, contract_address ORDER BY tx_timestamp DESC) AS rn
        FROM 
            dwd.dwd_transaction_clean
    ) ranked
    WHERE rn = 1
    GROUP BY 
        tx_date,
        contract_address
),
daily_stats AS (
    -- 基础交易统计
    SELECT 
        tx_date AS collection_date,
        contract_address,
        MAX(collection_name) AS collection_name,
        CAST(COUNT(*) AS INT) AS sales_count,
        SUM(trade_price_eth) AS volume_eth,
        SUM(trade_price_usd) AS volume_usd,
        AVG(trade_price_eth) AS avg_price_eth,
        MIN(trade_price_eth) AS min_price_eth,
        MAX(trade_price_eth) AS max_price_eth,
        CAST(COUNT(DISTINCT to_address) AS INT) AS unique_buyers,
        CAST(COUNT(DISTINCT from_address) AS INT) AS unique_sellers,
        MAX(is_in_working_set) AS is_in_working_set
    FROM 
        dwd.dwd_transaction_clean
    GROUP BY 
        tx_date,
        contract_address
),
-- 其他CTE操作...
```

### 3.2 dws_wallet_daily_stats 处理流程

该表存储钱包的每日统计数据，从原DWD层迁移并增强。主要来源于DWD层的`dwd_transaction_clean`表。

处理流程：
1. 从`dwd_transaction_clean`获取钱包的交易数据
2. 分别计算买入和卖出相关指标
3. 计算利润和投资回报率
4. 计算钱包持仓余额
5. 计算排名指标和鲸鱼候选标记

SQL处理逻辑示例：
```sql
INSERT INTO dws_wallet_daily_stats
WITH daily_buys AS (
    -- 每日买入统计
    SELECT 
        tx_date AS wallet_date,
        to_address AS wallet_address,
        CAST(COUNT(*) AS INT) AS buy_count,
        CAST(SUM(trade_price_eth) AS DECIMAL(30,10)) AS buy_volume_eth,
        CAST(COUNT(DISTINCT contract_address) AS INT) AS buy_collections
    FROM 
        dwd.dwd_transaction_clean
    GROUP BY 
        tx_date,
        to_address
),
-- 其他CTE操作...
```

### 3.3 dws_whale_daily_stats 处理流程

该表存储鲸鱼钱包的每日交易汇总数据，优化了字段和计算逻辑。主要来源于DWS层的`dws_wallet_daily_stats`表和DIM层的`dim_whale_address`表。

处理流程：
1. 从`dws_wallet_daily_stats`获取钱包的每日交易数据
2. 关联`dim_whale_address`获取鲸鱼的维度信息
3. 计算当日交易相关指标
4. 从交易明细计算持仓价值和持仓变化
5. 计算累计指标（累计利润、累计ROI等）
6. 计算成功率和平均持有天数
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
),
daily_holdings AS (
    -- 估算当日持仓价值
    SELECT 
        tx.tx_date,
        tx.to_address AS wallet_address,
        CAST(SUM(tx.trade_price_eth) AS DECIMAL(30,10)) AS holding_value_eth,
        CAST(COUNT(DISTINCT tx.contract_address) AS INT) AS holding_collections,
        CAST(COUNT(*) AS INT) AS holding_nfts
    FROM 
        dwd.dwd_whale_transaction_detail tx
    LEFT JOIN 
        dwd.dwd_whale_transaction_detail sell ON tx.to_address = sell.from_address 
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
        dwd.dwd_whale_transaction_detail tx
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
        dwd.dwd_whale_transaction_detail sell
    JOIN 
        dwd.dwd_whale_transaction_detail buy ON sell.from_address = buy.to_address
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
        dwd.dwd_wallet_daily_stats
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
    dwd.dwd_wallet_daily_stats wd
JOIN 
    dim.dim_whale_address dwa ON wd.wallet_address = dwa.wallet_address
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

### 3.4 dws_collection_whale_flow 处理流程

该表存储收藏集的鲸鱼资金流向数据，优化了字段和计算逻辑。主要来源于DWD层的`dwd_whale_transaction_detail`表、DIM层的`dim_whale_address`表和DWS层的`dws_collection_whale_ownership`表。

处理流程：
1. 从`dwd_whale_transaction_detail`获取鲸鱼相关的交易数据
2. 关联`dim_whale_address`获取鲸鱼类型信息
3. 按收藏集和鲸鱼类型维度聚合计算流入流出指标
4. 计算净流入量和鲸鱼交易占比
5. 从`dws_collection_whale_ownership`获取鲸鱼持有比例信息
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
        CAST(COUNT(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN 1 END) AS INT) AS whale_buy_count,
        CAST(COUNT(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN 1 END) AS INT) AS whale_sell_count,
        CAST(SUM(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.trade_price_eth ELSE 0 END) AS DECIMAL(30,10)) AS whale_buy_volume_eth,
        CAST(SUM(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.trade_price_eth ELSE 0 END) AS DECIMAL(30,10)) AS whale_sell_volume_eth,
        CAST(COUNT(DISTINCT CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.to_address END) AS INT) AS unique_whale_buyers,
        CAST(COUNT(DISTINCT CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.from_address END) AS INT) AS unique_whale_sellers,
        CAST(AVG(CASE WHEN tx.to_is_whale AND tx.to_address = w.wallet_address THEN tx.trade_price_eth END) AS DECIMAL(30,10)) AS whale_buy_avg_price_eth,
        CAST(AVG(CASE WHEN tx.from_is_whale AND tx.from_address = w.wallet_address THEN tx.trade_price_eth END) AS DECIMAL(30,10)) AS whale_sell_avg_price_eth
    FROM 
        dwd.dwd_whale_transaction_detail tx
    JOIN 
        dim.dim_whale_address w ON (tx.to_is_whale AND tx.to_address = w.wallet_address) OR (tx.from_is_whale AND tx.from_address = w.wallet_address)
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
        dwd.dwd_whale_transaction_detail
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
        dim.dim_collection_info ci
),
historical_flows AS (
    -- 计算历史净流入
    SELECT 
        contract_address,
        whale_type,
        SUM(CASE WHEN tx_date >= DATE_SUB(CURRENT_DATE, 7) THEN net_flow_eth ELSE 0 END) AS accu_net_flow_7d,
        SUM(CASE WHEN tx_date >= DATE_SUB(CURRENT_DATE, 30) THEN net_flow_eth ELSE 0 END) AS accu_net_flow_30d
    FROM 
        dws.dws_collection_whale_flow
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

### 3.5 dws_collection_whale_ownership 处理流程

这是新增的收藏集鲸鱼持有统计表，从DIM层迁移统计功能。主要来源于DWD层的`dwd_transaction_clean`表和DIM层的`dim_whale_address`表。

处理流程：
1. 从`dwd_transaction_clean`获取NFT持有相关的交易数据
2. 关联`dim_whale_address`获取鲸鱼识别信息
3. 计算持有总数、持有者总数和鲸鱼持有相关指标
4. 计算持有比例和持有价值
5. 计算1天和7天的持有比例变化
6. 计算排名指标

SQL处理逻辑示例：
```sql
INSERT INTO dws_collection_whale_ownership
WITH current_holdings AS (
    -- 计算当前持有情况
    SELECT 
        CURRENT_DATE AS stat_date,
        t.contract_address AS collection_address,
        MAX(t.collection_name) AS collection_name,
        CAST(COUNT(*) AS INT) AS total_nfts,
        CAST(COUNT(DISTINCT t.to_address) AS INT) AS total_owners,
        CAST(COUNT(DISTINCT CASE WHEN w.is_whale THEN t.to_address END) AS INT) AS whale_owners,
        CAST(COUNT(CASE WHEN w.is_whale THEN 1 END) AS INT) AS whale_owned_nfts,
        -- 其他计算逻辑...
    FROM 
        dwd.dwd_transaction_clean t
    LEFT JOIN 
        dim.dim_whale_address w ON t.to_address = w.wallet_address
    WHERE 
        NOT EXISTS (
            -- 排除已卖出的NFT
            SELECT 1 FROM dwd.dwd_transaction_clean s
            WHERE s.from_address = t.to_address
            AND s.contract_address = t.contract_address
            AND s.token_id = t.token_id
            AND s.tx_date > t.tx_date
        )
    GROUP BY 
        t.contract_address
),
-- 其他CTE操作...
```

## 4. 执行流程与调度

### 4.1 完整执行流程

DWS层数据处理按以下顺序执行，确保了依赖关系的正确处理：

1. 执行`dws_collection_daily_stats.sql`创建并填充收藏集每日统计表：
   ```bash
   ./scripts/run_dws_collection_daily_stats.sh
   ```

2. 执行`dws_wallet_daily_stats.sql`创建并填充钱包每日统计表：
   ```bash
   ./scripts/run_dws_wallet_daily_stats.sh
   ```

3. 执行`dws_whale_daily_stats.sql`创建并填充鲸鱼每日统计表：
   ```bash
   ./scripts/run_dws_whale_daily_stats.sh
   ```

4. 执行`dws_collection_whale_ownership.sql`创建并填充收藏集鲸鱼持有统计表：
   ```bash
   ./scripts/run_dws_collection_whale_ownership.sh
   ```

5. 执行`dws_collection_whale_flow.sql`创建并填充收藏集鲸鱼资金流向表：
   ```bash
   ./scripts/run_dws_collection_whale_flow.sh
   ```

或者使用统一的执行脚本：
```bash
./run_all_sql.sh
```

### 4.2 调度策略

DWS层数据处理通常在DWD层数据完成处理后执行，建议采用以下调度策略：

- **调度频率**：每日一次，在DWD层处理完成后

- **依赖关系**：
  - 依赖DWD层相关表的处理完成
  - `dws_whale_daily_stats`依赖`dws_wallet_daily_stats`的完成
  - `dws_collection_whale_flow`依赖`dws_collection_whale_ownership`的完成

- **超时设置**：120分钟

- **失败处理**：失败时自动重试2次，然后告警

### 4.3 数据质量监控

DWS层应设置以下数据质量监控规则：

1. **完整性检查**：
   - 确保每日数据完整性，不缺少关键鲸鱼或收藏集的数据
   - 检查主键的唯一性
   - 验证关键记录数量在合理范围内

2. **准确性检查**：
   - 验证计算指标是否在合理范围内
   - 检查关键聚合指标的准确性
   - 检测异常值和极端值

3. **一致性检查**：
   - 跨表指标一致性检查（如鲸鱼数量和流向统计）
   - 时间序列一致性检查（与前一天数据的合理变化）
   - 子表与主表之间的一致性

## 5. 数据应用场景

DWS层的数据主要支持以下应用场景：

1. **鲸鱼行为分析**：
   - 追踪鲸鱼的交易策略和表现
   - 对比不同类型鲸鱼的行为特征
   - 鉴别成功鲸鱼的投资模式

2. **收藏集鲸鱼流向监控**：
   - 监控重要收藏集的鲸鱼资金流向
   - 预测潜在的市场趋势变化
   - 识别鲸鱼集中交易的收藏集

3. **收藏集持有分析**：
   - 分析鲸鱼对不同收藏集的持有比例
   - 跟踪鲸鱼持有比例的变化趋势
   - 评估收藏集的鲸鱼影响力指数

4. **钱包交易分析**：
   - 分析所有钱包的交易行为
   - 识别潜在的鲸鱼钱包
   - 计算钱包的投资回报和表现

5. **投资组合分析**：
   - 分析成功鲸鱼的投资组合特点
   - 提供投资组合优化建议
   - 跟踪投资组合价值变化

## 6. 常见问题与解决方案

1. **数据计算性能问题**：
   - 症状：DWS层SQL执行时间过长
   - 解决方案：优化SQL，明确的类型转换，避免AVG等函数类型问题，引入中间表，或调整并行度

2. **历史数据累积问题**：
   - 症状：累积指标（如7/30天）计算不准确
   - 解决方案：建立滑动窗口计算机制，或定期校准累积值

3. **数据不一致问题**：
   - 症状：不同表之间的统计结果不一致
   - 解决方案：统一口径，确保数据依赖正确性，遵循表执行顺序

4. **数据类型问题**：
   - 症状：SQL执行报错，如DECIMAL类型的AVG函数问题
   - 解决方案：使用明确的类型转换，先转换为DOUBLE再聚合，后转回DECIMAL

## 7. 运维建议

1. 定期监控DWS层表的数据增长和性能
2. 设置关键指标的阈值告警，及时发现异常数据
3. 对历史数据进行归档和分区管理，提高查询效率
4. 建立数据质量报告机制，定期检查数据的准确性和完整性
5. 针对关键查询场景优化SQL和表结构
6. 定期验证各表之间的依赖关系是否正确
7. 监控执行顺序是否满足数据依赖要求