# NFT Whale Tracker DWD层数据流转文档

## 1. 概述

本文档详细描述了NFT Whale Tracker项目中DWD层（Detail Warehouse Data，明细数据层）的数据流转过程。DWD层是在ODS层基础上进行数据清洗、转换和规范化处理后形成的明细数据层，为后续的维度构建、数据汇总和应用层分析提供基础。

## 2. 数据流转架构

整个DWD层的数据流转过程可以分为以下几个关键步骤：

```
ODS层数据 -> 数据清洗与转换 -> 数据标准化与规范化 -> 数据质量检查 -> DWD层表
```

## 3. 数据处理流程

### 3.1 dwd_whale_transaction_detail 处理流程

该表存储与潜在鲸鱼相关的NFT交易明细数据，主要来源于ODS层的`ods_collection_transaction_inc`表。

处理流程：
1. 从`ods_collection_transaction_inc`表提取交易数据
2. 关联`ods_daily_top30_volume_wallets`和`ods_top100_balance_wallets`表识别鲸鱼地址
3. 关联`ods_collection_working_set`表标识工作集收藏集
4. 增加时间维度（日期、周、月）
5. 计算交易相关指标（如潜在利润）
6. 将USD和ETH价格统一化
7. 标准化平台名称和事件类型

SQL处理逻辑示例：
```sql
INSERT INTO dwd_whale_transaction_detail
SELECT
    TO_DATE(FROM_UNIXTIME(tx_timestamp)) AS tx_date,
    nftscan_tx_id AS tx_id,
    hash AS tx_hash,
    FROM_UNIXTIME(tx_timestamp) AS tx_timestamp,
    DATE_FORMAT(FROM_UNIXTIME(tx_timestamp), 'YYYY-ww') AS tx_week,
    DATE_FORMAT(FROM_UNIXTIME(tx_timestamp), 'YYYY-MM') AS tx_month,
    from_address,
    to_address,
    CASE WHEN vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS from_is_whale,
    CASE WHEN vw2.account_address IS NOT NULL OR bw2.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS to_is_whale,
    t.contract_address,
    t.contract_name AS collection_name,
    t.token_id,
    t.trade_price AS trade_price_eth,
    t.trade_price * eth_usd_rate AS trade_price_usd,
    t.trade_symbol,
    c.floor_price AS floor_price_eth,
    (t.trade_price - c.floor_price) AS profit_potential,
    t.event_type,
    t.exchange_name AS platform,
    CASE WHEN cws.collection_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_in_working_set,
    'ods_collection_transaction_inc' AS data_source,
    FALSE AS is_deleted,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    ods_collection_transaction_inc t
LEFT JOIN 
    ods_daily_top30_volume_wallets vw ON t.from_address = vw.account_address AND TO_DATE(FROM_UNIXTIME(tx_timestamp)) = vw.rank_date
LEFT JOIN 
    ods_top100_balance_wallets bw ON t.from_address = bw.account_address AND TO_DATE(FROM_UNIXTIME(tx_timestamp)) = bw.rank_date
LEFT JOIN 
    ods_daily_top30_volume_wallets vw2 ON t.to_address = vw2.account_address AND TO_DATE(FROM_UNIXTIME(tx_timestamp)) = vw2.rank_date
LEFT JOIN 
    ods_top100_balance_wallets bw2 ON t.to_address = bw2.account_address AND TO_DATE(FROM_UNIXTIME(tx_timestamp)) = bw2.rank_date
LEFT JOIN 
    ods_collection_working_set cws ON t.contract_address = cws.collection_address
LEFT JOIN 
    (SELECT contract_address, floor_price, record_time FROM ods_daily_top30_volume_collections
     UNION 
     SELECT contract_address, floor_price, record_time FROM ods_daily_top30_transaction_collections) c 
    ON t.contract_address = c.contract_address 
    AND DATE(FROM_UNIXTIME(t.tx_timestamp)) = DATE(c.record_time)
CROSS JOIN 
    (SELECT 2500.00 AS eth_usd_rate) r -- 示例USD汇率，实际应该从外部源获取
WHERE 
    t.trade_price > 0 -- 过滤无效交易
    AND (vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL OR vw2.account_address IS NOT NULL OR bw2.account_address IS NOT NULL) -- 至少一方是鲸鱼
```

### 3.2 dwd_collection_daily_stats 处理流程

该表存储NFT收藏集的每日统计数据，主要来源于ODS层的交易数据和收藏集数据。

处理流程：
1. 从`ods_collection_transaction_inc`表按收藏集和日期汇总交易数据
2. 关联`ods_daily_top30_volume_collections`和`ods_daily_top30_transaction_collections`表获取收藏集信息
3. 关联`ods_collection_working_set`表标识工作集收藏集
4. 根据`dwd_whale_transaction_detail`表计算鲸鱼相关指标
5. 计算日环比变化率
6. 计算排名和Top30标识

SQL处理逻辑示例：
```sql
INSERT INTO dwd_collection_daily_stats
WITH daily_tx AS (
    SELECT 
        TO_DATE(FROM_UNIXTIME(tx_timestamp)) AS collection_date,
        contract_address,
        contract_name,
        COUNT(*) AS sales_count,
        SUM(trade_price) AS volume_eth,
        SUM(trade_price * 2500.00) AS volume_usd,
        AVG(trade_price) AS avg_price_eth,
        MIN(trade_price) AS min_price_eth,
        MAX(trade_price) AS max_price_eth,
        COUNT(DISTINCT to_address) AS unique_buyers,
        COUNT(DISTINCT from_address) AS unique_sellers
    FROM 
        ods_collection_transaction_inc
    WHERE 
        trade_price > 0
    GROUP BY 
        TO_DATE(FROM_UNIXTIME(tx_timestamp)),
        contract_address,
        contract_name
),
whale_stats AS (
    SELECT 
        tx_date AS collection_date,
        contract_address,
        COUNT(DISTINCT CASE WHEN to_is_whale THEN to_address END) AS whale_buyers,
        COUNT(DISTINCT CASE WHEN from_is_whale THEN from_address END) AS whale_sellers,
        SUM(trade_price_eth) AS whale_volume_eth
    FROM 
        dwd_whale_transaction_detail
    GROUP BY 
        tx_date,
        contract_address
),
previous_day AS (
    SELECT 
        TO_DATE(FROM_UNIXTIME(tx_timestamp)) AS collection_date,
        contract_address,
        COUNT(*) AS prev_sales_count,
        SUM(trade_price) AS prev_volume_eth,
        AVG(trade_price) AS prev_avg_price_eth
    FROM 
        ods_collection_transaction_inc
    WHERE 
        trade_price > 0
    GROUP BY 
        TO_DATE(FROM_UNIXTIME(tx_timestamp)),
        contract_address
),
collection_ranks AS (
    SELECT
        collection_date,
        contract_address,
        ROW_NUMBER() OVER (PARTITION BY collection_date ORDER BY volume_eth DESC) AS rank_by_volume,
        ROW_NUMBER() OVER (PARTITION BY collection_date ORDER BY sales_count DESC) AS rank_by_sales
    FROM 
        daily_tx
)
SELECT 
    d.collection_date,
    d.contract_address,
    d.contract_name AS collection_name,
    d.sales_count,
    d.volume_eth,
    d.volume_usd,
    d.avg_price_eth,
    d.min_price_eth,
    d.max_price_eth,
    COALESCE(c.floor_price, 0) AS floor_price_eth,
    d.unique_buyers,
    d.unique_sellers,
    COALESCE(w.whale_buyers, 0) AS whale_buyers,
    COALESCE(w.whale_sellers, 0) AS whale_sellers,
    COALESCE(w.whale_volume_eth, 0) AS whale_volume_eth,
    CASE WHEN d.volume_eth > 0 THEN (COALESCE(w.whale_volume_eth, 0) / d.volume_eth) * 100 ELSE 0 END AS whale_percentage,
    CASE 
        WHEN p.prev_sales_count > 0 THEN ((d.sales_count - p.prev_sales_count) / p.prev_sales_count) * 100
        ELSE 0
    END AS sales_change_1d,
    CASE 
        WHEN p.prev_volume_eth > 0 THEN ((d.volume_eth - p.prev_volume_eth) / p.prev_volume_eth) * 100
        ELSE 0
    END AS volume_change_1d,
    CASE 
        WHEN p.prev_avg_price_eth > 0 THEN ((d.avg_price_eth - p.prev_avg_price_eth) / p.prev_avg_price_eth) * 100
        ELSE 0
    END AS price_change_1d,
    CASE WHEN cws.collection_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_in_working_set,
    r.rank_by_volume,
    r.rank_by_sales,
    CASE WHEN r.rank_by_volume <= 30 THEN TRUE ELSE FALSE END AS is_top30_volume,
    CASE WHEN r.rank_by_sales <= 30 THEN TRUE ELSE FALSE END AS is_top30_sales,
    'ods_collection_transaction_inc,ods_daily_top30_volume_collections' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    daily_tx d
LEFT JOIN 
    whale_stats w ON d.collection_date = w.collection_date AND d.contract_address = w.contract_address
LEFT JOIN 
    previous_day p ON d.collection_date = DATE_ADD(p.collection_date, 1) AND d.contract_address = p.contract_address
LEFT JOIN 
    ods_collection_working_set cws ON d.contract_address = cws.collection_address
LEFT JOIN 
    (
        SELECT contract_address, floor_price, DATE(record_time) AS record_date
        FROM ods_daily_top30_volume_collections
        UNION
        SELECT contract_address, floor_price, DATE(record_time) AS record_date
        FROM ods_daily_top30_transaction_collections
    ) c ON d.contract_address = c.contract_address AND d.collection_date = c.record_date
LEFT JOIN 
    collection_ranks r ON d.collection_date = r.collection_date AND d.contract_address = r.contract_address
```

### 3.3 dwd_wallet_daily_stats 处理流程

该表存储钱包地址的每日交易统计数据，主要来源于ODS层的交易数据和钱包排名数据。

处理流程：
1. 从`ods_collection_transaction_inc`表按钱包地址和日期汇总交易数据
2. 区分买卖双方角色计算交易量
3. 关联`ods_daily_top30_volume_wallets`和`ods_top100_balance_wallets`表获取排名信息
4. 标识潜在鲸鱼钱包
5. 计算交易的收藏集数量和工作集收藏集数量
6. 估算当日利润

SQL处理逻辑示例：
```sql
INSERT INTO dwd_wallet_daily_stats
WITH buy_stats AS (
    SELECT 
        TO_DATE(FROM_UNIXTIME(tx_timestamp)) AS wallet_date,
        to_address AS wallet_address,
        COUNT(*) AS buy_count,
        SUM(trade_price) AS buy_volume_eth,
        SUM(trade_price * 2500.00) AS buy_volume_usd,
        COUNT(DISTINCT contract_address) AS buy_collections
    FROM 
        ods_collection_transaction_inc
    WHERE 
        trade_price > 0
    GROUP BY 
        TO_DATE(FROM_UNIXTIME(tx_timestamp)),
        to_address
),
sell_stats AS (
    SELECT 
        TO_DATE(FROM_UNIXTIME(tx_timestamp)) AS wallet_date,
        from_address AS wallet_address,
        COUNT(*) AS sell_count,
        SUM(trade_price) AS sell_volume_eth,
        SUM(trade_price * 2500.00) AS sell_volume_usd,
        COUNT(DISTINCT contract_address) AS sell_collections
    FROM 
        ods_collection_transaction_inc
    WHERE 
        trade_price > 0
    GROUP BY 
        TO_DATE(FROM_UNIXTIME(tx_timestamp)),
        from_address
),
working_set_stats AS (
    SELECT 
        TO_DATE(FROM_UNIXTIME(t.tx_timestamp)) AS wallet_date,
        t.to_address AS wallet_address,
        COUNT(DISTINCT CASE WHEN cws.collection_address IS NOT NULL THEN t.contract_address END) AS buy_working_collections
    FROM 
        ods_collection_transaction_inc t
    LEFT JOIN 
        ods_collection_working_set cws ON t.contract_address = cws.collection_address
    GROUP BY 
        TO_DATE(FROM_UNIXTIME(t.tx_timestamp)),
        t.to_address
    
    UNION ALL
    
    SELECT 
        TO_DATE(FROM_UNIXTIME(t.tx_timestamp)) AS wallet_date,
        t.from_address AS wallet_address,
        COUNT(DISTINCT CASE WHEN cws.collection_address IS NOT NULL THEN t.contract_address END) AS sell_working_collections
    FROM 
        ods_collection_transaction_inc t
    LEFT JOIN 
        ods_collection_working_set cws ON t.contract_address = cws.collection_address
    GROUP BY 
        TO_DATE(FROM_UNIXTIME(t.tx_timestamp)),
        t.from_address
)
SELECT 
    COALESCE(b.wallet_date, s.wallet_date) AS wallet_date,
    COALESCE(b.wallet_address, s.wallet_address) AS wallet_address,
    COALESCE(b.buy_count, 0) AS buy_count,
    COALESCE(s.sell_count, 0) AS sell_count,
    COALESCE(b.buy_count, 0) + COALESCE(s.sell_count, 0) AS total_tx_count,
    COALESCE(b.buy_volume_eth, 0) AS buy_volume_eth,
    COALESCE(s.sell_volume_eth, 0) AS sell_volume_eth,
    COALESCE(b.buy_volume_eth, 0) - COALESCE(s.sell_volume_eth, 0) AS net_flow_eth,
    COALESCE(b.buy_volume_usd, 0) AS buy_volume_usd,
    COALESCE(s.sell_volume_usd, 0) AS sell_volume_usd,
    COALESCE(b.buy_volume_usd, 0) - COALESCE(s.sell_volume_usd, 0) AS net_flow_usd,
    COALESCE(s.sell_volume_eth, 0) - COALESCE(b.buy_volume_eth, 0) AS profit_eth, -- 简单估算，实际应考虑持仓成本
    COALESCE(s.sell_volume_usd, 0) - COALESCE(b.buy_volume_usd, 0) AS profit_usd,
    COALESCE(b.buy_collections, 0) + COALESCE(s.sell_collections, 0) AS collections_traded,
    COALESCE(ws.buy_working_collections, 0) + COALESCE(ws2.sell_working_collections, 0) AS working_set_collections_traded,
    CASE WHEN vw.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_top30_volume,
    CASE WHEN bw.account_address IS NOT NULL THEN TRUE ELSE FALSE END AS is_top100_balance,
    COALESCE(vw.rank_num, 0) AS rank_by_volume,
    COALESCE(bw.rank_num, 0) AS rank_by_balance,
    CASE WHEN vw.account_address IS NOT NULL OR bw.account_address IS NOT NULL OR COALESCE(b.buy_volume_eth, 0) + COALESCE(s.sell_volume_eth, 0) > 10 THEN TRUE ELSE FALSE END AS is_whale_candidate,
    'ods_collection_transaction_inc,ods_daily_top30_volume_wallets,ods_top100_balance_wallets' AS data_source,
    CURRENT_TIMESTAMP AS etl_time
FROM 
    buy_stats b
FULL OUTER JOIN 
    sell_stats s ON b.wallet_date = s.wallet_date AND b.wallet_address = s.wallet_address
LEFT JOIN 
    working_set_stats ws ON COALESCE(b.wallet_date, s.wallet_date) = ws.wallet_date AND COALESCE(b.wallet_address, s.wallet_address) = ws.wallet_address
LEFT JOIN 
    working_set_stats ws2 ON COALESCE(b.wallet_date, s.wallet_date) = ws2.wallet_date AND COALESCE(b.wallet_address, s.wallet_address) = ws2.wallet_address
LEFT JOIN 
    ods_daily_top30_volume_wallets vw ON COALESCE(b.wallet_date, s.wallet_date) = vw.rank_date AND COALESCE(b.wallet_address, s.wallet_address) = vw.account_address
LEFT JOIN 
    ods_top100_balance_wallets bw ON COALESCE(b.wallet_date, s.wallet_date) = bw.rank_date AND COALESCE(b.wallet_address, s.wallet_address) = bw.account_address
```

## 4. 执行流程与调度

### 4.1 完整执行流程

DWD层数据处理通常按以下顺序执行：

1. 执行`dwd_whale_transaction_detail`表的数据处理：
   ```bash
   ./run_dwd_whale_transaction.sh
   ```

2. 执行`dwd_collection_daily_stats`表的数据处理：
   ```bash
   ./run_dwd_collection_stats.sh
   ```

3. 执行`dwd_wallet_daily_stats`表的数据处理：
   ```bash
   ./run_dwd_wallet_stats.sh
   ```

### 4.2 调度策略

DWD层数据处理通常在ODS层数据完成加载后执行，建议采用以下调度策略：

- **调度频率**：每日一次，在ODS层数据加载完成后
- **依赖关系**：依赖ODS层所有表的加载完成
- **超时设置**：60分钟
- **失败处理**：失败时自动重试2次，然后告警

### 4.3 数据质量监控

DWD层应设置以下数据质量监控规则：

1. **完整性检查**：
   - 确保关键字段（如tx_id、wallet_address、contract_address）无空值
   - 检查是否有丢失的日期

2. **准确性检查**：
   - 验证金额字段不为负
   - 验证统计汇总的准确性（如总交易额 = 买入总额 + 卖出总额）

3. **一致性检查**：
   - 验证DWD层的总记录数与ODS层相关数据的一致性
   - 检查鲸鱼标识的一致性

## 5. 数据整合与关联

DWD层数据主要来源于ODS层，并通过以下方式进行整合和关联：

1. **时间关联**：通过日期字段关联不同数据源的数据
2. **地址关联**：通过钱包地址关联交易与钱包信息
3. **收藏集关联**：通过合约地址关联交易与收藏集信息
4. **工作集关联**：通过合约地址与工作集表关联，标识重点关注的收藏集

## 6. 常见问题与解决方案

1. **数据延迟问题**：
   - 症状：某些日期的数据不完整
   - 解决方案：设置数据延迟阈值，对于不完整的数据重新处理

2. **数据不一致问题**：
   - 症状：不同表之间的鲸鱼识别结果不一致
   - 解决方案：统一鲸鱼识别规则，优先使用维度表中的标识

3. **性能问题**：
   - 症状：DWD层数据处理耗时过长
   - 解决方案：优化SQL语句，增加分区策略，调整Flink并行度

## 7. 运维建议

1. 定期检查日志，及时发现和解决问题
2. 监控DWD层表的数据量增长，及时调整资源配置
3. 定期验证关键指标的准确性
4. 建立数据血缘关系，便于问题追踪和影响分析
5. 为关键的DWD层表设置数据质量监控告警 