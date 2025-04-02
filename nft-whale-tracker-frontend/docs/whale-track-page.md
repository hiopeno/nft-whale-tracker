# 巨鲸追踪页面开发指南

## 页面概述

巨鲸追踪页面是NFT鲸鱼追踪系统的核心功能页面，用于实时监控和分析NFT市场中的鲸鱼行为。该页面包含多个关键组件，展示了鲸鱼交易的实时数据、统计分析和详细信息。本文档旨在为后端和数据库开发者提供详细的实现指南。

## 主要功能模块

### 1. 鲸鱼统计卡片
- **重点追踪鲸鱼**：显示当前被系统重点追踪的鲸鱼数量
- **聪明鲸鱼**：展示系统判定为"聪明"的鲸鱼数量（基于收益率和交易成功率）
- **愚蠢鲸鱼**：展示系统判定为"愚蠢"的鲸鱼数量（基于亏损率和不当交易行为）
- **追踪成功率**：显示系统预测的准确率

#### 后端需求
```json
{
  "activeWhales": "number",
  "smartWhales": "number",
  "dumbWhales": "number",
  "successRate": "number (percentage)"
}
```

#### 鲸鱼分类算法建议
- **聪明鲸鱼判定**：
  - 过去90天总体收益率 > 20%
  - 交易成功率 > 65%
  - 至少5次成功的高价出售记录
  
- **愚蠢鲸鱼判定**：
  - 过去90天总体收益率 < -15%
  - 连续3次以上在市场高点买入记录
  - FOMO行为模式（在价格上涨后集中买入）

### 2. 实时交易流
实时展示鲸鱼的NFT交易活动，包含以下信息：
- NFT名称和收藏集信息
- 交易价格和价格变化
- 买卖双方地址
- 交易类型标签
- 稀有度排名（如有）
- 鲸鱼标识

#### 后端需求
```json
{
  "transactions": [{
    "id": "string",                      // 交易唯一标识符
    "time": "timestamp",                 // 交易时间，ISO 8601格式
    "nftName": "string",                 // NFT名称，例如"BAYC #1234"
    "collection": "string",              // 收藏集名称
    "seller": "string (address)",        // 卖家钱包地址
    "buyer": "string (address)",         // 买家钱包地址
    "price": "number",                   // 成交价格(ETH)
    "priceChange": "number (percentage)", // 相对上次成交价格的变化百分比
    "rarityRank": "number",              // NFT在收藏集中的稀有度排名
    "whaleInfluence": "number (0-100)",  // 鲸鱼影响力评分
    "actionType": "enum ('accumulate'|'dump'|'flip'|'explore'|'profit'|'fomo'|'bargain')", // 交易行为类型
    "isWhale": "boolean",                // 是否涉及鲸鱼账户
    "whaleIsBuyer": "boolean",           // 鲸鱼是否为买家
    "whaleSeller": "boolean",            // 鲸鱼是否为卖家
    "whaleAddress": "string"             // 鲸鱼钱包地址
  }]
}
```

#### 交易类型判定算法
- **accumulate**: 鲸鱼持续在同一收藏集中购买，表现为积累行为
- **dump**: 鲸鱼短期内集中卖出同一收藏集，表现为抛售行为
- **flip**: 买入后短期内（<7天）卖出，表现为快速翻转获利
- **explore**: 首次购买新收藏集或小众收藏集
- **profit**: 以显著高于买入价的价格卖出（>30%）
- **fomo**: 在价格快速上涨期间买入热门收藏集
- **bargain**: 以低于市场均价15%以上的价格买入

### 3. 收藏集流向分析
展示鲸鱼资金在不同NFT收藏集间的流动情况：
- 支持净流入/净流出切换
- 按鲸鱼类型筛选（所有/聪明/愚蠢）
- 时间范围选择（当天/近一周/近一月）

#### 后端需求
```json
{
  "collections": [{
    "name": "string",                    // 收藏集名称
    "value": "number",                   // 流入/流出金额(ETH)
    "icon": "string (url)",              // 收藏集图标URL
    "timeRange": "enum ('day'|'week'|'month')", // 时间范围
    "whaleType": "enum ('all'|'smart'|'dumb')", // 鲸鱼类型
    "flowType": "enum ('inflow'|'outflow')",    // 流向类型
    "transactionCount": "number",        // 交易次数
    "percentageOfTotal": "number"        // 占总流量的百分比
  }]
}
```

#### 计算方法建议
- **净流入**: 所有鲸鱼买入该收藏集的ETH总额 - 所有鲸鱼卖出该收藏集的ETH总额
- **净流出**: 所有鲸鱼卖出该收藏集的ETH总额 - 所有鲸鱼买入该收藏集的ETH总额
- 应通过定时任务预计算不同时间周期的数据，存储在专门的统计表中

### 4. 鲸鱼交易额分析
展示交易额排名前十的鲸鱼：
- 支持不同时间范围查询
- 展示交易额占比
- 展示具体交易金额

#### 后端需求
```json
{
  "whales": [{
    "whaleId": "string",                 // 鲸鱼ID
    "tradingVolume": "number",           // 交易总额(ETH)
    "timeRange": "enum ('day'|'week'|'month')", // 时间范围
    "percentageOfTotal": "number",       // 占市场总交易量百分比
    "transactionCount": "number",        // 交易次数
    "averageTransactionValue": "number", // 平均每笔交易金额
    "dominantAction": "string"           // 主要交易行为(买入/卖出)
  }]
}
```

### 5. 鲸鱼收益率分析
展示收益率排名前十的鲸鱼：
- 支持不同时间范围查询
- 展示收益率和具体收益金额
- 展示占总收益的比例

#### 后端需求
```json
{
  "whales": [{
    "whaleId": "string",                 // 鲸鱼ID
    "profitRate": "number (percentage)", // 收益率(%)
    "profit": "number",                  // 收益金额(ETH)
    "timeRange": "enum ('day'|'week'|'month')", // 时间范围
    "investmentAmount": "number",        // 投资总额(ETH)
    "successfulTrades": "number",        // 盈利交易次数
    "failedTrades": "number"             // 亏损交易次数
  }]
}
```

#### 收益率计算方法
```
收益率 = (卖出总额 - 买入总额) / 买入总额 * 100%
```

### 6. 钱包分析功能
点击钱包地址时显示详细信息：
- 总交易次数和交易额
- 当前持有价值
- 交易趋势分析
- NFT持有分布
- 近期交易记录

#### 后端需求
```json
{
  "walletInfo": {
    "address": "string",                 // 钱包地址
    "label": "string",                   // 标签(如"鲸鱼钱包"/"普通用户")
    "totalTransactions": "number",       // 总交易次数
    "totalVolume": "number",             // 总交易额(ETH)
    "holdingValue": "number",            // 当前持有价值(ETH)
    "profitLoss": "number",              // 总盈亏(ETH)
    "profitRate": "number",              // 收益率(%)
    "firstActivity": "timestamp",        // 首次活动时间
    "tradingTrends": [{                  // 交易趋势数据
      "date": "string",                  // 日期(YYYY-MM-DD)
      "value": "number"                  // 交易金额(ETH)
    }],
    "nftHoldings": [{                    // NFT持有分布
      "name": "string",                  // 收藏集名称
      "value": "number",                 // 估值(ETH)
      "count": "number",                 // 持有数量
      "acquisitionValue": "number",      // 总获取成本
      "unrealizedProfit": "number"       // 未实现收益
    }],
    "recentTransactions": [{             // 近期交易记录
      "id": "number",                    // 交易ID
      "time": "timestamp",               // 交易时间
      "type": "enum ('买入'|'卖出')",    // 交易类型
      "collection": "string",            // 收藏集
      "tokenId": "string",               // 代币ID
      "price": "number",                 // 价格(ETH)
      "withWhale": "boolean",            // 是否与其他鲸鱼交易
      "profitLoss": "number"             // 交易盈亏(如适用)
    }],
    "frequentlyTradedWith": [{          // 常交易对手
      "address": "string",              // 地址
      "count": "number",                // 交易次数
      "isWhale": "boolean"              // 是否为鲸鱼
    }]
  }
}
```

## 数据库设计建议

### 1. Whales表 (鲸鱼表)
```sql
CREATE TABLE whales (
    whale_id VARCHAR(50) PRIMARY KEY,    -- 鲸鱼唯一标识
    type ENUM('tracked', 'smart', 'dumb'),  -- 鲸鱼类型
    influence_score INT,                 -- 影响力评分(0-100)
    total_profit DECIMAL(20,8),          -- 总收益(ETH)
    total_volume DECIMAL(20,8),          -- 总交易量(ETH)
    profit_rate DECIMAL(10,2),           -- 收益率(%)
    successful_trades INT,               -- 成功交易次数
    total_trades INT,                    -- 总交易次数
    first_seen TIMESTAMP,                -- 首次观察时间
    last_active TIMESTAMP,               -- 最后活动时间
    avg_hold_time INT,                   -- 平均持有时间(天)
    created_at TIMESTAMP,                -- 记录创建时间
    updated_at TIMESTAMP,                -- 记录更新时间
    INDEX idx_whale_type (type),         -- 鲸鱼类型索引
    INDEX idx_influence (influence_score), -- 影响力索引
    INDEX idx_profit_rate (profit_rate),   -- 收益率索引
    INDEX idx_volume (total_volume)        -- 交易量索引
);
```

### 2. WalletAddresses表 (钱包地址表)
```sql
CREATE TABLE wallet_addresses (
    address VARCHAR(42) PRIMARY KEY,     -- 钱包地址
    whale_id VARCHAR(50),                -- 关联鲸鱼ID
    label VARCHAR(100),                  -- 地址标签
    influence_score INT,                 -- 影响力评分
    holding_value DECIMAL(20,8),         -- 当前持有价值
    total_transactions INT,              -- 总交易次数
    total_volume DECIMAL(20,8),          -- 总交易量
    profit_loss DECIMAL(20,8),           -- 总盈亏
    profit_rate DECIMAL(10,2),           -- 收益率
    first_transaction TIMESTAMP,         -- 首次交易时间
    last_transaction TIMESTAMP,          -- 最后交易时间
    created_at TIMESTAMP,                -- 记录创建时间
    updated_at TIMESTAMP,                -- 记录更新时间
    FOREIGN KEY (whale_id) REFERENCES whales(whale_id), -- 外键约束
    INDEX idx_whale_address (whale_id),  -- 鲸鱼ID索引
    INDEX idx_holding_value (holding_value) -- 持有价值索引
);
```

### 3. Transactions表 (交易表)
```sql
CREATE TABLE transactions (
    tx_hash VARCHAR(66) PRIMARY KEY,     -- 交易哈希
    blockchain VARCHAR(20),              -- 区块链网络
    block_number BIGINT,                 -- 区块号
    collection_address VARCHAR(42),      -- 收藏集合约地址
    token_id VARCHAR(50),                -- 代币ID
    seller_address VARCHAR(42),          -- 卖家地址
    buyer_address VARCHAR(42),           -- 买家地址
    price DECIMAL(20,8),                 -- 价格(ETH)
    usd_price DECIMAL(20,2),             -- 美元价格
    timestamp TIMESTAMP,                 -- 交易时间
    action_type VARCHAR(20),             -- 行为类型
    marketplace VARCHAR(30),             -- 交易市场
    gas_fee DECIMAL(20,8),               -- 燃料费
    is_whale_transaction BOOLEAN,        -- 是否鲸鱼交易
    whale_address VARCHAR(42),           -- 鲸鱼地址
    whale_is_buyer BOOLEAN,              -- 鲸鱼是否买家
    rarity_rank INT,                     -- 稀有度排名
    profit_loss DECIMAL(20,8),           -- 交易盈亏
    FOREIGN KEY (seller_address) REFERENCES wallet_addresses(address), -- 外键约束
    FOREIGN KEY (buyer_address) REFERENCES wallet_addresses(address),  -- 外键约束
    INDEX idx_collection (collection_address), -- 收藏集索引
    INDEX idx_timestamp (timestamp),     -- 时间索引
    INDEX idx_whale_tx (is_whale_transaction), -- 鲸鱼交易索引
    INDEX idx_price (price),             -- 价格索引
    INDEX idx_token (collection_address, token_id) -- 组合索引
);
```

### 4. Collections表 (收藏集表)
```sql
CREATE TABLE collections (
    address VARCHAR(42) PRIMARY KEY,     -- 收藏集合约地址
    name VARCHAR(100),                   -- 收藏集名称
    symbol VARCHAR(20),                  -- 代币符号
    creator VARCHAR(42),                 -- 创建者地址
    total_supply INT,                    -- 总供应量
    icon_url TEXT,                       -- 图标URL
    floor_price_history JSON,            -- 地板价历史
    average_price_history JSON,          -- 平均价格历史
    whale_interest_score INT,            -- 鲸鱼兴趣评分
    volume_24h DECIMAL(20,8),            -- 24小时交易量
    volume_7d DECIMAL(20,8),             -- 7天交易量
    volume_30d DECIMAL(20,8),            -- 30天交易量
    whale_ownership_percentage DECIMAL(5,2), -- 鲸鱼持有比例
    created_at TIMESTAMP,                -- 记录创建时间
    updated_at TIMESTAMP,                -- 记录更新时间
    INDEX idx_name (name),               -- 名称索引
    INDEX idx_volume_24h (volume_24h),   -- 24h交易量索引
    INDEX idx_whale_interest (whale_interest_score) -- 鲸鱼兴趣索引
);
```

### 5. CollectionFlows表 (收藏集资金流向表)
```sql
CREATE TABLE collection_flows (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, -- 主键
    collection_address VARCHAR(42),      -- 收藏集地址
    date DATE,                           -- 日期
    inflow DECIMAL(20,8),                -- 流入金额
    outflow DECIMAL(20,8),               -- 流出金额
    net_flow DECIMAL(20,8),              -- 净流量
    whale_type ENUM('all', 'smart', 'dumb'), -- 鲸鱼类型
    transaction_count INT,               -- 交易次数
    unique_wallet_count INT,             -- 独立钱包数
    time_range ENUM('day', 'week', 'month'), -- 时间范围
    FOREIGN KEY (collection_address) REFERENCES collections(address), -- 外键约束
    INDEX idx_collection_date (collection_address, date), -- 组合索引
    INDEX idx_flow_date (date, net_flow),   -- 流量日期索引
    UNIQUE KEY unique_collection_date_range_type (
        collection_address, date, time_range, whale_type
    ) -- 唯一约束
);
```

### 6. WhaleStats表 (鲸鱼统计表)
```sql
CREATE TABLE whale_stats (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, -- 主键
    date DATE,                           -- 统计日期
    active_whales INT,                   -- 活跃鲸鱼数
    smart_whales INT,                    -- 聪明鲸鱼数
    dumb_whales INT,                     -- 愚蠢鲸鱼数
    success_rate DECIMAL(5,2),           -- 成功率
    total_volume DECIMAL(20,8),          -- 总交易量
    total_profit DECIMAL(20,8),          -- 总收益
    time_range ENUM('day', 'week', 'month'), -- 时间范围
    INDEX idx_date_range (date, time_range), -- 日期范围索引
    UNIQUE KEY unique_date_range (date, time_range) -- 唯一约束
);
```

### 7. WalletHoldings表 (钱包持有表)
```sql
CREATE TABLE wallet_holdings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, -- 主键
    wallet_address VARCHAR(42),          -- 钱包地址
    collection_address VARCHAR(42),      -- 收藏集地址
    token_id VARCHAR(50),                -- 代币ID
    acquisition_price DECIMAL(20,8),     -- 获取价格
    acquisition_time TIMESTAMP,          -- 获取时间
    current_value DECIMAL(20,8),         -- 当前估值
    last_valuation_time TIMESTAMP,       -- 最后估值时间
    FOREIGN KEY (wallet_address) REFERENCES wallet_addresses(address), -- 外键约束
    FOREIGN KEY (collection_address) REFERENCES collections(address),  -- 外键约束
    INDEX idx_wallet (wallet_address),   -- 钱包索引
    INDEX idx_collection_token (collection_address, token_id), -- 收藏集代币索引
    UNIQUE KEY unique_wallet_token (wallet_address, collection_address, token_id) -- 唯一约束
);
```

## API端点设计

### 1. 统计数据
```
GET /api/v1/whale-stats
```

**请求参数**: 无

**响应格式**:
```json
{
  "activeWhales": 327,
  "smartWhales": 156,
  "dumbWhales": 83,
  "successRate": 78.6,
  "lastUpdated": "2023-06-15T08:30:22Z"
}
```

**状态码**:
- 200: 成功
- 500: 服务器错误

```
GET /api/v1/whale-stats/history?timeRange=day|week|month
```

**请求参数**:
- `timeRange`: 时间范围(day|week|month)，默认为day

**响应格式**:
```json
{
  "timeRange": "week",
  "data": [
    {
      "date": "2023-06-09",
      "activeWhales": 312,
      "smartWhales": 149,
      "dumbWhales": 79,
      "successRate": 77.2
    },
    // 更多日期数据...
  ]
}
```

**状态码**:
- 200: 成功
- 400: 参数错误
- 500: 服务器错误

### 2. 实时交易流
```
GET /api/v1/transactions/stream
```

**请求参数**:
- `limit`: 返回记录数量，默认为20，最大为50
- `whaleOnly`: 是否只返回鲸鱼交易，默认为false

**响应格式**:
```json
{
  "transactions": [
    {
      "id": "tx123456",
      "time": "2023-06-15T14:23:12Z",
      "nftName": "BAYC #8765",
      "collection": "Bored Ape Yacht Club",
      "seller": "0x7823...45fa",
      "buyer": "0x9abc...78de",
      "price": 68.5,
      "priceChange": -5.2,
      "rarityRank": 234,
      "whaleInfluence": 85,
      "actionType": "accumulate",
      "isWhale": true,
      "whaleIsBuyer": true,
      "whaleSeller": false,
      "whaleAddress": "0x9abc...78de"
    },
    // 更多交易...
  ]
}
```

**状态码**:
- 200: 成功
- 400: 参数错误
- 500: 服务器错误

```
GET /api/v1/transactions?type=whale_buy|whale_sell&timeRange=10min|1hour|4hours|12hours
```

**请求参数**:
- `type`: 交易类型(whale_buy|whale_sell)，默认返回所有类型
- `timeRange`: 时间范围，默认为1hour
- `page`: 页码，默认为1
- `pageSize`: 每页记录数，默认为20，最大为100
- `collection`: 收藏集地址，可选
- `minPrice`: 最低价格，可选
- `maxPrice`: 最高价格，可选

**响应格式**:
```json
{
  "total": 157,
  "page": 1,
  "pageSize": 20,
  "transactions": [
    // 交易数据，格式同上
  ]
}
```

**状态码**:
- 200: 成功
- 400: 参数错误
- 500: 服务器错误

### 3. 收藏集流向
```
GET /api/v1/collections/flow?type=inflow|outflow&whaleType=all|smart|dumb&timeRange=day|week|month
```

**请求参数**:
- `type`: 流向类型(inflow|outflow)，默认为inflow
- `whaleType`: 鲸鱼类型(all|smart|dumb)，默认为all
- `timeRange`: 时间范围，默认为day
- `limit`: 返回记录数量，默认为10，最大为50

**响应格式**:
```json
{
  "type": "inflow",
  "whaleType": "smart",
  "timeRange": "week",
  "collections": [
    {
      "name": "Bored Ape Yacht Club",
      "value": 523.7,
      "icon": "https://example.com/bayc.png",
      "transactionCount": 12,
      "percentageOfTotal": 23.5
    },
    // 更多收藏集...
  ]
}
```

**状态码**:
- 200: 成功
- 400: 参数错误
- 500: 服务器错误

### 4. 鲸鱼排行
```
GET /api/v1/whales/top?by=volume|profit&timeRange=day|week|month
```

**请求参数**:
- `by`: 排序依据(volume|profit)，默认为volume
- `timeRange`: 时间范围，默认为day
- `limit`: 返回记录数量，默认为10，最大为100
- `whaleType`: 鲸鱼类型(all|smart|dumb)，默认为all

**响应格式**:
```json
{
  "by": "volume",
  "timeRange": "day",
  "whales": [
    {
      "whaleId": "whale123",
      "tradingVolume": 876.3,
      "percentageOfTotal": 12.4,
      "transactionCount": 15,
      "averageTransactionValue": 58.42,
      "dominantAction": "买入"
    },
    // 更多鲸鱼数据...
  ]
}
```

**状态码**:
- 200: 成功
- 400: 参数错误
- 500: 服务器错误

```
GET /api/v1/whales/{whaleId}/wallets
```

**请求参数**:
- `whaleId`: 鲸鱼ID

**响应格式**:
```json
{
  "whaleId": "whale123",
  "wallets": [
    {
      "address": "0x1234...5678",
      "label": "主钱包",
      "transactionCount": 56,
      "volume": 734.2
    },
    // 更多钱包...
  ]
}
```

**状态码**:
- 200: 成功
- 404: 未找到指定鲸鱼
- 500: 服务器错误

### 5. 钱包分析
```
GET /api/v1/wallets/{address}/stats
```

**请求参数**:
- `address`: 钱包地址

**响应格式**:
```json
{
  "address": "0x1234...5678",
  "label": "鲸鱼钱包",
  "totalTransactions": 87,
  "totalVolume": 1435.8,
  "holdingValue": 982.3,
  "profitLoss": 356.2,
  "profitRate": 24.8,
  "firstActivity": "2022-04-12T15:23:18Z"
}
```

**状态码**:
- 200: 成功
- 404: 钱包未找到
- 500: 服务器错误

```
GET /api/v1/wallets/{address}/holdings
```

**请求参数**:
- `address`: 钱包地址
- `page`: 页码，默认为1
- `pageSize`: 每页记录数，默认为20，最大为100

**响应格式**:
```json
{
  "address": "0x1234...5678",
  "total": 25,
  "page": 1,
  "pageSize": 20,
  "holdings": [
    {
      "name": "Bored Ape Yacht Club",
      "value": 321.5,
      "count": 2,
      "acquisitionValue": 278.3,
      "unrealizedProfit": 43.2
    },
    // 更多持有...
  ]
}
```

**状态码**:
- 200: 成功
- 404: 钱包未找到
- 500: 服务器错误

```
GET /api/v1/wallets/{address}/transactions
```

**请求参数**:
- `address`: 钱包地址
- `page`: 页码，默认为1
- `pageSize`: 每页记录数，默认为20，最大为100
- `type`: 交易类型(买入|卖出)，可选
- `timeRange`: 时间范围(1d|7d|30d|all)，默认为all

**响应格式**:
```json
{
  "address": "0x1234...5678",
  "total": 87,
  "page": 1,
  "pageSize": 20,
  "transactions": [
    {
      "id": 12345,
      "time": "2023-06-14T12:34:56Z",
      "type": "买入",
      "collection": "Bored Ape Yacht Club",
      "tokenId": "8765",
      "price": 68.5,
      "withWhale": true,
      "profitLoss": null
    },
    // 更多交易...
  ]
}
```

**状态码**:
- 200: 成功
- 404: 钱包未找到
- 400: 参数错误
- 500: 服务器错误

## 实现技术建议

### 1. 鲸鱼识别算法
应实现一个多因素评分系统来识别鲸鱼账户，考虑以下因素：
- 历史交易量（ETH总额）
- 当前持有NFT总价值
- 交易频率和模式
- 与已知鲸鱼的交易关系
- 账户活跃时间
- 成功投资的历史记录

建议使用加权评分算法，并设置动态阈值以适应市场变化。

### 2. 数据聚合服务
建议使用批处理架构：
- 每小时更新收藏集流向分析
- 每天更新鲸鱼分类（聪明/愚蠢）
- 实时更新交易流数据
- 每周重新计算鲸鱼影响力评分

### 3. 市场异常检测
实现异常检测算法以识别：
- 可疑的价格异常（洗交易）
- 协同活动模式（多个钱包协同操作）
- 市场操纵尝试（如价格拉升后抛售）

## 性能考虑

### 1. 实时数据处理
- **WebSocket实现**：建议使用Node.js+Socket.IO或SignalR实现WebSocket服务
- **消息队列**：使用RabbitMQ或Kafka处理高并发交易数据
- **数据分片**：
  ```
  # 交易表分片示例
  交易表按月分片：transactions_202306, transactions_202307...
  # 查询时动态路由
  SELECT * FROM transactions_current WHERE ...
  UNION ALL
  SELECT * FROM transactions_202305 WHERE ...
  ```

### 2. 缓存策略
- **多级缓存**：
  ```
  Memory Cache (Redis) -> 存储热点数据，10分钟过期
  API Cache -> 存储API响应，5分钟过期
  DB Cache -> 存储查询结果，1小时过期
  ```
- **预热缓存**：系统启动时预加载热门收藏集和鲸鱼数据
- **缓存失效策略**：
  ```
  定时刷新：每10分钟刷新统计数据
  按需刷新：交易发生时仅更新相关鲸鱼和收藏集缓存
  ```

## 监控指标

### 1. 业务指标
- **鲸鱼预测准确率计算**：
  ```
  准确率 = 正确预测次数 / 总预测次数 * 100%
  ```
- **交易捕获率计算**：
  ```
  捕获率 = 系统记录的鲸鱼交易 / 区块链上实际鲸鱼交易 * 100%
  ```
- **异常交易识别准确率**：
  ```
  准确率 = 正确标记的异常交易 / 总标记的异常交易 * 100%
  ```

### 2. 性能指标
- **API响应时间监控**：
  ```
  时间阈值：
  P99: < 300ms
  P95: < 200ms
  P50: < 100ms
  ```
- **WebSocket连接状态监控**：
  ```
  健康度 = 活跃连接数 / 预期连接数 * 100%
  重连率 = 重连次数 / 总连接次数 * 100%
  ```
- **数据同步延迟监控**：
  ```
  区块链同步延迟: 最新同步区块时间 - 当前时间
  报警阈值: > 10分钟
  ```

## 安全考虑

### 1. 数据安全
- **钱包地址脱敏算法**：
  ```
  // 前6位 + ... + 后4位
  function maskAddress(address) {
    return address.substring(0, 6) + "..." + address.substring(address.length - 4);
  }
  ```
- **API访问限流配置**：
  ```
  // 使用Redis实现令牌桶算法
  每IP限制: 60次/分钟
  每用户限制: 120次/分钟
  WebSocket消息限制: 100条/分钟
  ```
- **数据访问权限控制**：
  ```
  实现基于角色的访问控制(RBAC)
  不同用户角色可查看不同级别的统计和交易数据
  ```

### 2. 接口安全
- **API签名验证**：
  ```
  // HMAC签名机制
  signature = HMAC-SHA256(secret_key, timestamp + method + endpoint + body)
  ```
- **防重放攻击机制**：
  ```
  // 请求需包含timestamp和nonce
  有效期: 5分钟内
  nonce: 一次性随机字符串，使用后失效
  ```

## 后端架构建议

建议采用微服务架构，将功能拆分为以下几个服务：

1. **数据采集服务**：
   - 负责从区块链获取NFT交易数据
   - 使用Go或Rust实现高性能数据抓取

2. **鲸鱼分析服务**：
   - 负责鲸鱼识别和分类
   - 使用Python+机器学习实现行为分析

3. **交易流服务**：
   - 负责实时交易推送
   - 使用Node.js实现WebSocket服务

4. **统计分析服务**：
   - 负责各类统计数据计算
   - 使用Java或Python实现批处理任务

5. **API网关**：
   - 统一接口管理和安全控制
   - 使用Nginx+API网关实现 