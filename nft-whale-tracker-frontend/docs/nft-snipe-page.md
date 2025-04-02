# NFT藏品狙击页面开发文档

## 页面概述

藏品狙击(NFT Snipe)页面是NFT鲸鱼追踪平台的核心功能之一，旨在帮助用户发现和利用市场上出现的低价NFT机会。该页面通过实时监控各大NFT交易平台上的价格异常，快速识别出明显低于市场价的NFT，为用户提供套利和收藏机会。

## 页面功能模块

### 1. 市场概览统计卡片

页面顶部展示四个关键指标统计卡片：

- **最低狙击成本**：当前可进入的最低价格NFT成本（ETH）
- **最高折扣率**：目前市场上可获得的最大折扣百分比
- **可获收益**：基于当前机会的潜在最大收益（ETH）
- **收益率**：预期投资回报率百分比

**后端数据需求**：
```json
{
  "lowestCost": 5.2,           // 最低成本(ETH)
  "highestDiscountRate": 33.5,  // 最高折扣率(%)
  "potentialProfit": 58.2,      // 理论最大收益(ETH)
  "profitRate": 24.8            // 平均收益率(%)
}
```

### 2. 实时低价藏品流

左侧展示实时更新的低价NFT列表，包含以下信息：

- NFT名称和图片
- 收藏集信息
- 折扣率（相对于市场平均价的百分比）
- 当前价格和折扣幅度
- 卖家钱包地址
- 交易平台标签（OpenSea/Blur等）
- 发布时间
- 抢购按钮（链接到原平台购买页）

支持按折扣范围（高/中/低）和时间范围（1小时/24小时/全部）筛选。

**后端数据需求**：
```json
{
  "discountItems": [
    {
      "id": "1",                                // 唯一ID
      "time": "刚刚",                           // 上架时间
      "nftName": "BoredApe #8765",              // NFT名称
      "collectionName": "Bored Ape Yacht Club", // 收藏集名称
      "collectionIcon": "url_to_icon",          // 收藏集图标URL
      "currentPrice": 68.5,                     // 当前价格(ETH)
      "marketPrice": 95.2,                      // 市场均价(ETH)
      "discount": 28.0,                         // 折扣率(%)
      "listingUrl": "https://...",              // 购买链接
      "marketPlace": "OpenSea",                 // 市场平台
      "seller": "0x7823...45fa"                 // 卖家地址
    },
    // 更多藏品...
  ]
}
```

### 3. 藏品统计日历

右侧展示过去三个月内每天的低价藏品数据，支持两种视图切换：

- **低价藏品数量**：当日找到的低价NFT数量
- **理论可获收益**：当日低价NFT的理论总收益（ETH）

日历采用热力图形式，数据量越大，颜色越深。

**后端数据需求**：
```json
{
  "calendarData": {
    "2023-04-01": {
      "count": 7,       // 低价藏品数量
      "profit": 15.3    // 理论收益(ETH)
    },
    "2023-04-02": {
      "count": 5,
      "profit": 10.8
    },
    // 更多日期数据...
  }
}
```

## API接口详细规范

### 1. 获取统计卡片数据

```
GET /api/nft-snipe/stats
```

**请求参数**: 无

**响应示例**：
```json
{
  "lowestCost": 5.2,
  "highestDiscountRate": 33.5,
  "potentialProfit": 58.2,
  "profitRate": 24.8,
  "lastUpdated": "2023-06-15T08:30:22Z"
}
```

**状态码**:
- 200: 成功
- 500: 服务器错误

**缓存策略**:
- 建议缓存时间: 5分钟
- 实现方式: Redis缓存或API网关缓存

**计算建议**:
- 最低狙击成本: 当前所有低价NFT中最低价格
- 最高折扣率: 当前所有低价NFT中最高折扣比例
- 可获收益: 所有低价NFT理论收益(市场价-当前价)的总和
- 收益率: 总可获收益/总成本*100%

### 2. 获取实时低价藏品

```
GET /api/nft-snipe/discount-items
```

**请求参数**：
- `discountLevel`: 折扣等级筛选 (all/high/medium/low)
  - high: 折扣率 > 30%
  - medium: 20% < 折扣率 <= 30%
  - low: 折扣率 <= 20%
- `timeRange`: 时间范围筛选 (all/hour/day)
- `page`: 页码(从1开始)
- `pageSize`: 每页条数(默认10，最大50)
- `sort`: 排序字段(discount/time/price)，默认按discount排序
- `order`: 排序方向(asc/desc)，默认desc

**响应示例**：
```json
{
  "total": 126,
  "page": 1,
  "pageSize": 10,
  "items": [
    {
      "id": "1",
      "time": "刚刚",
      "timeInMs": 1686837792000,  // 上架时间的毫秒级时间戳
      "nftName": "BoredApe #8765",
      "collectionName": "Bored Ape Yacht Club",
      "collectionIcon": "url_to_icon",
      "tokenId": "8765",
      "contractAddress": "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d",
      "currentPrice": 68.5,
      "marketPrice": 95.2,
      "discount": 28.0,
      "listingUrl": "https://...",
      "marketPlace": "OpenSea",
      "marketPlaceIcon": "url_to_marketplace_icon",
      "seller": "0x7823...45fa",
      "expiresIn": "2小时15分钟",  // 如果有上架过期时间
      "expiresAt": 1686844992000  // 过期时间戳
    },
    // 更多藏品...
  ]
}
```

**状态码**:
- 200: 成功
- 400: 参数错误
- 500: 服务器错误

**性能考虑**:
- 分页实现应在数据库层面进行，避免全量数据加载
- 每次API请求不应返回过多数据，建议限制pageSize最大值为50
- 应该实现部分响应式API，新数据可通过WebSocket推送

**WebSocket接口**:
```
WS /api/nft-snipe/stream
```

**WebSocket响应示例**:
```json
{
  "type": "new_discount_item",
  "data": {
    // 单条折扣藏品数据，格式同上
  }
}
```

### 3. 获取日历统计数据

```
GET /api/nft-snipe/calendar-data
```

**请求参数**：
- `startDate`: 开始日期 (YYYY-MM-DD)，默认为当前日期往前90天
- `endDate`: 结束日期 (YYYY-MM-DD)，默认为当前日期
- `view`: 视图类型 (count/profit)，默认为count

**响应示例**：
```json
{
  "startDate": "2023-03-17",
  "endDate": "2023-06-15",
  "view": "count",
  "calendarData": {
    "2023-04-01": {
      "count": 7,
      "profit": 15.3
    },
    "2023-04-02": {
      "count": 5,
      "profit": 10.8,
      "avgDiscount": 22.4 // 平均折扣率
    },
    // 更多日期数据...
  },
  "summary": {
    "totalCount": 245,
    "totalProfit": 532.7,
    "avgDailyCount": 8.2,
    "avgDailyProfit": 17.8,
    "bestDay": "2023-05-12",
    "bestDayCount": 23,
    "bestDayProfit": 42.5
  }
}
```

**状态码**:
- 200: 成功
- 400: 参数错误
- 500: 服务器错误

**缓存策略**:
- 历史数据可缓存24小时
- 当日数据缓存1小时

## 数据库设计建议

### 1. NFT折扣机会表 (nft_discount_opportunities)

```sql
CREATE TABLE nft_discount_opportunities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nft_id VARCHAR(255) NOT NULL COMMENT 'NFT唯一标识',
    collection_id VARCHAR(255) NOT NULL COMMENT '收藏集ID',
    collection_name VARCHAR(255) NOT NULL COMMENT '收藏集名称',
    collection_icon_url TEXT COMMENT '收藏集图标URL',
    contract_address VARCHAR(42) NOT NULL COMMENT '合约地址',
    token_id VARCHAR(255) NOT NULL COMMENT '代币ID',
    current_price DECIMAL(20,10) NOT NULL COMMENT '当前价格(ETH)',
    market_price DECIMAL(20,10) NOT NULL COMMENT '市场均价(ETH)',
    discount_rate DECIMAL(10,2) NOT NULL COMMENT '折扣率(%)',
    seller_address VARCHAR(42) NOT NULL COMMENT '卖家地址',
    marketplace VARCHAR(50) NOT NULL COMMENT '交易平台',
    marketplace_icon_url TEXT COMMENT '交易平台图标',
    listing_url TEXT NOT NULL COMMENT '购买链接',
    listing_time TIMESTAMP NOT NULL COMMENT '上架时间',
    expires_at TIMESTAMP NULL COMMENT '过期时间',
    expired BOOLEAN DEFAULT FALSE COMMENT '是否过期',
    purchased BOOLEAN DEFAULT FALSE COMMENT '是否已被购买',
    theoretical_profit DECIMAL(20,10) GENERATED ALWAYS AS (market_price - current_price) STORED COMMENT '理论利润',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录更新时间',
    
    INDEX idx_collection (collection_id),
    INDEX idx_listing_time (listing_time),
    INDEX idx_discount_rate (discount_rate),
    INDEX idx_current_price (current_price),
    INDEX idx_expired_purchased (expired, purchased),
    UNIQUE INDEX unique_token_listing (contract_address, token_id, listing_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='NFT折扣机会表';
```

**字段说明**:
- `nft_id`: 通常为 collection_name + "#" + token_id 形式
- `discount_rate`: 计算公式为 (market_price - current_price) / market_price * 100
- `expires_at`: 如果有明确的上架到期时间，记录在此
- `theoretical_profit`: 使用生成列自动计算理论利润

**索引策略**:
- 按折扣率创建索引，加速高折扣筛选
- 按上架时间创建索引，加速时间范围查询
- 按当前价格创建索引，支持价格排序
- 创建联合唯一索引，避免重复记录

### 2. 日历统计表 (nft_snipe_daily_stats)

```sql
CREATE TABLE nft_snipe_daily_stats (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL COMMENT '日期',
    opportunity_count INT NOT NULL DEFAULT 0 COMMENT '当日机会数量',
    purchased_count INT NOT NULL DEFAULT 0 COMMENT '当日已购买数量',
    avg_discount_rate DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '平均折扣率(%)',
    max_discount_rate DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '最大折扣率(%)',
    min_discount_rate DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '最小折扣率(%)',
    total_current_price DECIMAL(20,10) NOT NULL DEFAULT 0 COMMENT '总当前价格(ETH)',
    total_market_price DECIMAL(20,10) NOT NULL DEFAULT 0 COMMENT '总市场价格(ETH)',
    total_potential_profit DECIMAL(20,10) NOT NULL DEFAULT 0 COMMENT '总潜在收益(ETH)',
    best_opportunity_id BIGINT NULL COMMENT '最佳机会ID',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录更新时间',
    
    UNIQUE INDEX unique_date (date),
    INDEX idx_opportunity_count (opportunity_count),
    INDEX idx_potential_profit (total_potential_profit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='NFT狙击日历统计表';
```

**更新逻辑**:
应实现一个定时任务，每小时更新当日统计数据:

```sql
-- 更新当日统计示例SQL
INSERT INTO nft_snipe_daily_stats (
    date, 
    opportunity_count, 
    purchased_count,
    avg_discount_rate, 
    max_discount_rate, 
    min_discount_rate,
    total_current_price, 
    total_market_price, 
    total_potential_profit
)
SELECT 
    DATE(listing_time) as date,
    COUNT(*) as opportunity_count,
    SUM(CASE WHEN purchased = TRUE THEN 1 ELSE 0 END) as purchased_count,
    AVG(discount_rate) as avg_discount_rate,
    MAX(discount_rate) as max_discount_rate,
    MIN(discount_rate) as min_discount_rate,
    SUM(current_price) as total_current_price,
    SUM(market_price) as total_market_price,
    SUM(market_price - current_price) as total_potential_profit
FROM 
    nft_discount_opportunities
WHERE 
    DATE(listing_time) = CURRENT_DATE()
ON DUPLICATE KEY UPDATE
    opportunity_count = VALUES(opportunity_count),
    purchased_count = VALUES(purchased_count),
    avg_discount_rate = VALUES(avg_discount_rate),
    max_discount_rate = VALUES(max_discount_rate),
    min_discount_rate = VALUES(min_discount_rate),
    total_current_price = VALUES(total_current_price),
    total_market_price = VALUES(total_market_price),
    total_potential_profit = VALUES(total_potential_profit),
    updated_at = CURRENT_TIMESTAMP;
```

### 3. 收藏集价格表 (nft_collection_prices)

```sql
CREATE TABLE nft_collection_prices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    collection_id VARCHAR(255) NOT NULL COMMENT '收藏集ID',
    collection_name VARCHAR(255) NOT NULL COMMENT '收藏集名称',
    contract_address VARCHAR(42) NOT NULL COMMENT '合约地址',
    floor_price DECIMAL(20,10) NOT NULL COMMENT '地板价(ETH)',
    avg_price DECIMAL(20,10) NOT NULL COMMENT '平均价格(ETH)',
    median_price DECIMAL(20,10) NOT NULL COMMENT '中位价格(ETH)',
    volume_24h DECIMAL(20,10) NOT NULL DEFAULT 0 COMMENT '24小时交易量',
    sales_count_24h INT NOT NULL DEFAULT 0 COMMENT '24小时销售数量',
    price_change_24h DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '24小时价格变化(%)',
    price_history JSON COMMENT '价格历史数据',
    icon_url TEXT COMMENT '图标URL',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录更新时间',
    last_price_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最后价格更新时间',
    
    UNIQUE INDEX unique_collection (collection_id),
    UNIQUE INDEX unique_contract_address (contract_address),
    INDEX idx_floor_price (floor_price),
    INDEX idx_volume (volume_24h)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='NFT收藏集价格表';
```

## 后端服务实现建议

### 1. 数据采集服务

#### 关键功能点：
- **多平台API集成**：接入OpenSea、Blur、X2Y2等主要NFT交易平台API
- **价格异常检测**：实现NFT价格异常检测算法

#### 实现建议：
```python
# 价格异常检测算法伪代码
def detect_discount_opportunity(nft):
    # 获取收藏集价格信息
    collection_price = get_collection_price(nft.collection_id)
    
    # 计算折扣率
    discount_rate = (collection_price.avg_price - nft.price) / collection_price.avg_price * 100
    
    # 初步过滤条件
    if discount_rate < 15:  # 低于15%折扣不考虑
        return None
    
    # 获取该NFT的历史交易价格
    historical_prices = get_historical_prices(nft.contract_address, nft.token_id)
    
    # 计算历史平均价格
    if len(historical_prices) > 0:
        historical_avg = sum(historical_prices) / len(historical_prices)
        historical_discount = (historical_avg - nft.price) / historical_avg * 100
        
        # 如果相对历史价格也有折扣，则更有可能是真实机会
        if historical_discount > 10:
            confidence_score = min(discount_rate, historical_discount) * 0.8 + max(discount_rate, historical_discount) * 0.2
        else:
            confidence_score = discount_rate * 0.5  # 降低置信度
    else:
        confidence_score = discount_rate * 0.7  # 无历史数据，使用一般置信度
    
    # 考虑收藏集活跃度
    if collection_price.volume_24h > 10:  # 活跃收藏集
        confidence_score *= 1.2
    
    # 如果置信度足够高，认为是有效机会
    if confidence_score > 20:
        return {
            "nft": nft,
            "discount_rate": discount_rate,
            "confidence_score": confidence_score
        }
    
    return None
```

#### 实时监控服务架构：
- 使用Node.js或Go语言实现高性能API轮询
- 对于支持WebSocket的平台，使用事件订阅代替轮询
- 使用Redis作为缓存层，存储最近检测过的NFT，避免重复处理
- 使用消息队列(如RabbitMQ)处理发现的折扣机会

### 2. 实时推送服务

#### WebSocket服务实现：
```javascript
// 使用Node.js + Socket.IO实现WebSocket服务
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const redis = require('redis');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);
const redisClient = redis.createClient();

// 订阅Redis频道以接收新的折扣机会
const redisSub = redisClient.duplicate();
redisSub.subscribe('new_discount_opportunities');

// 当Redis频道收到新消息时，向所有连接的客户端推送
redisSub.on('message', (channel, message) => {
  if (channel === 'new_discount_opportunities') {
    const opportunity = JSON.parse(message);
    
    // 根据不同的折扣级别发送到不同的房间
    if (opportunity.discount_rate > 30) {
      io.to('high_discount').emit('new_opportunity', opportunity);
    } else if (opportunity.discount_rate > 20) {
      io.to('medium_discount').emit('new_opportunity', opportunity);
    } else {
      io.to('low_discount').emit('new_opportunity', opportunity);
    }
    
    // 同时向所有用户发送
    io.emit('new_opportunity', opportunity);
  }
});

// 当新客户端连接时
io.on('connection', (socket) => {
  console.log('New client connected');
  
  // 客户端可以加入特定的房间以接收过滤后的通知
  socket.on('join_room', (room) => {
    if (['high_discount', 'medium_discount', 'low_discount'].includes(room)) {
      socket.join(room);
    }
  });
  
  socket.on('disconnect', () => {
    console.log('Client disconnected');
  });
});

server.listen(3001, () => {
  console.log('WebSocket server listening on port 3001');
});
```

### 3. 统计分析服务

#### 定时任务实现：
使用cron作业定期更新统计数据：

```bash
# 示例crontab配置
# 每小时更新当天统计
0 * * * * /usr/bin/python /path/to/update_daily_stats.py

# 每天凌晨汇总前一天完整数据
5 0 * * * /usr/bin/python /path/to/finalize_daily_stats.py

# 每周一汇总上周数据
10 0 * * 1 /usr/bin/python /path/to/generate_weekly_report.py
```

## 监控指标建议

实现以下监控指标以评估系统性能：

1. **数据采集指标**:
   - 各平台API调用成功率和响应时间
   - 每小时/每天发现的折扣机会数量
   - 折扣机会平均置信度

2. **用户行为指标**:
   - 点击率：查看详情的用户比例
   - 转化率：点击"抢购"按钮的比例
   - 平均会话时长和页面停留时间

3. **技术性能指标**:
   - API响应时间（目标：P95 < 300ms）
   - WebSocket连接状态和稳定性
   - 后端服务器资源使用率

## 性能优化建议

1. **数据库优化**:
   ```sql
   -- 为热门查询创建复合索引
   CREATE INDEX idx_active_discount_time ON nft_discount_opportunities 
   (expired, purchased, discount_rate, listing_time);
   
   -- 使用分区表优化大表查询
   ALTER TABLE nft_discount_opportunities
   PARTITION BY RANGE (TO_DAYS(listing_time)) (
     PARTITION p_current VALUES LESS THAN (TO_DAYS(NOW())),
     PARTITION p_history VALUES LESS THAN MAXVALUE
   );
   ```

2. **缓存策略**:
   - 热门收藏集价格数据缓存：TTL 10分钟
   - 统计卡片数据缓存：TTL 5分钟
   - 日历数据缓存：TTL 1小时（当天数据除外）

3. **异步处理**:
   - 使用消息队列处理折扣检测逻辑
   - 实现数据更新的异步回调机制

## 安全考虑

1. **价格验证**:
   ```python
   # 防止虚假折扣诱导
   def validate_discount(nft):
       # 1. 多源数据验证
       opensea_price = get_opensea_price(nft)
       blur_price = get_blur_price(nft)
       
       # 检查价格一致性
       if abs(opensea_price - nft.price) / nft.price > 0.1:
           flag_potential_scam(nft)
           return False
       
       # 2. 历史价格波动分析
       recent_prices = get_recent_prices(nft, days=7)
       if is_price_manipulation(recent_prices):
           flag_suspicious_activity(nft)
           return False
       
       return True
   ```

2. **请求限制**:
   - 为API实现速率限制（每IP 60次/分钟）
   - WebSocket连接限制（每IP最多3个连接）

3. **数据隐私**:
   - 对卖家地址实施部分遮蔽（例如：0x1234...5678）
   - 实现敏感数据访问控制和审计日志

---

本文档提供了NFT狙击页面的详细技术规范和后端实现建议。后端开发人员应根据此文档实现相应的API和数据处理服务，以支持前端展示实时的低价NFT机会。 