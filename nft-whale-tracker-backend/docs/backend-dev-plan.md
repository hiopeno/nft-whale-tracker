# NFT鲸鱼追踪系统后端开发计划

## 一、项目概述

基于现有的数据湖架构（Apache Flink + Apache Paimon）和前端需求文档，我们需要开发一套完整的后端服务系统，为NFT鲸鱼追踪平台提供数据支持。后端系统将实现三个核心功能页面的API接口：巨鲸追踪页面、低价狙击页面和策略推荐页面。

## 相关代码位置

### 1. 数据湖代码位置
- **基础路径**: `/root/nft-whale-tracker/src/main/java/org/bigdatatechcir/whale/warehouse`
- **处理层级**:
  - ODS层(原始数据): `flink/paimon/ods`
  - DWD层(明细数据): `flink/paimon/dwd`
  - DWS层(汇总数据): `flink/paimon/dws`
  - DIM层(维度数据): `flink/paimon/dim`
  - ADS层(应用数据): `flink/paimon/ads`

### 2. 前端代码位置
- **基础路径**: `/root/nft-whale-tracker/nft-whale-tracker-frontend`
- **页面组件**:
  - 巨鲸追踪页面: `src/pages/WhaleTrack/index.tsx`
  - 低价狙击页面: `src/pages/NftSnipe/index.tsx`
  - 策略推荐页面: `src/pages/Strategy/index.tsx`
- **前端文档**: `/root/nft-whale-tracker/nft-whale-tracker-frontend/docs`

## 二、系统架构

### 整体架构
```
+-------------------+    +-------------------+    +-------------------+
|   数据采集层      |    |    数据处理层     |    |    应用服务层     |
| (已有ETL流程)     | -> | (Flink + Paimon)  | -> | (Spring Boot API) |
+-------------------+    +-------------------+    +-------------------+
                                                           |
                                                           v
                                               +-------------------+
                                               |    前端应用       |
                                               | (React)           |
                                               +-------------------+
```

### 技术栈选择
- **Web框架**: Spring Boot 2.7.x
- **API风格**: RESTful API + WebSocket（实时数据推送）
- **数据访问**: JDBC连接Paimon/Hive数据
- **缓存系统**: Redis缓存热点数据
- **权限管理**: JWT认证
- **监控系统**: Prometheus + Grafana

## 三、模块划分

### 1. 基础模块 (`backend-core`)
- 基础配置
- 数据库连接管理
- 通用工具类
- 错误处理

### 2. 数据访问模块 (`backend-data`)
- Paimon数据访问层
- 缓存管理
- 数据同步任务
- 数据转换服务

### 3. 业务模块
- **鲸鱼追踪模块** (`whale-tracking`)
- **低价狙击模块** (`nft-snipe`)
- **策略推荐模块** (`strategy-recommendation`)

### 4. API模块 (`backend-api`)
- RESTful API控制器
- WebSocket服务
- 接口文档生成

## 四、数据表设计

基于数据湖中已有的ADS层表结构设计API服务所需的数据模型：

### 1. 鲸鱼追踪相关表
```sql
-- 鲸鱼账户表
CREATE TABLE IF NOT EXISTS `whale_accounts` (
  `address` VARCHAR(42) PRIMARY KEY,
  `label` VARCHAR(50),
  `is_smart` BOOLEAN,
  `influence_score` DECIMAL(5,2),
  `first_seen` TIMESTAMP,
  `total_transaction_count` INT,
  `total_volume_eth` DECIMAL(20,8),
  `profit_rate` DECIMAL(5,2),
  `created_at` TIMESTAMP,
  `updated_at` TIMESTAMP
);

-- 实时交易表（同步自数据湖）
CREATE TABLE IF NOT EXISTS `whale_transactions` (
  `transaction_id` VARCHAR(66) PRIMARY KEY,
  `nft_id` VARCHAR(100),
  `collection_id` VARCHAR(100),
  `collection_name` VARCHAR(150),
  `seller_address` VARCHAR(42),
  `buyer_address` VARCHAR(42),
  `price_eth` DECIMAL(20,8),
  `price_usd` DECIMAL(20,8),
  `transaction_time` TIMESTAMP,
  `marketplace` VARCHAR(50),
  `action_type` VARCHAR(20),
  `is_whale_involved` BOOLEAN,
  `whale_is_buyer` BOOLEAN,
  `whale_is_seller` BOOLEAN,
  `rarity_rank` INT,
  `price_change_percentage` DECIMAL(5,2)
);

-- 鲸鱼流动性分析表
CREATE TABLE IF NOT EXISTS `collection_flow_analysis` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `collection_id` VARCHAR(100),
  `collection_name` VARCHAR(150),
  `time_range` VARCHAR(10),
  `whale_type` VARCHAR(10),
  `inflow_eth` DECIMAL(20,8),
  `outflow_eth` DECIMAL(20,8),
  `net_flow_eth` DECIMAL(20,8),
  `transaction_count` INT,
  `percentage_of_total` DECIMAL(5,2),
  `date` DATE,
  `updated_at` TIMESTAMP
);
```

### 2. 低价狙击相关表
```sql
-- 同步自ADS层的ads_bargain_opportunity表
CREATE TABLE IF NOT EXISTS `nft_bargain_opportunities` (
  `opportunity_id` VARCHAR(32) PRIMARY KEY,
  `nft_id` VARCHAR(100),
  `collection_id` VARCHAR(100),
  `discovery_time` TIMESTAMP,
  `current_price` DECIMAL(20,8),
  `market_reference_price` DECIMAL(20,8),
  `discount_percentage` DECIMAL(5,2),
  `urgency_score` DECIMAL(5,2),
  `investment_value_score` DECIMAL(5,2),
  `risk_score` DECIMAL(5,2),
  `opportunity_window` VARCHAR(30),
  `marketplace` VARCHAR(50),
  `status` VARCHAR(10),
  `expires_at` TIMESTAMP,
  `created_at` TIMESTAMP,
  `updated_at` TIMESTAMP
);

-- 低价狙击统计表
CREATE TABLE IF NOT EXISTS `bargain_statistics` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `date` DATE,
  `total_opportunities` INT,
  `high_discount_count` INT,
  `medium_discount_count` INT,
  `low_discount_count` INT,
  `avg_discount_percentage` DECIMAL(5,2),
  `total_potential_profit_eth` DECIMAL(20,8),
  `lowest_cost_eth` DECIMAL(20,8),
  `highest_discount` DECIMAL(5,2),
  `updated_at` TIMESTAMP
);
```

### 3. 策略推荐相关表
```sql
-- 同步自ADS层的ads_strategy_recommendation表
CREATE TABLE IF NOT EXISTS `investment_strategies` (
  `strategy_id` VARCHAR(32) PRIMARY KEY,
  `strategy_type` VARCHAR(10),
  `generation_time` TIMESTAMP,
  `expiry_time` TIMESTAMP,
  `target_entity` VARCHAR(10),
  `entity_id` VARCHAR(100),
  `entity_name` VARCHAR(150),
  `recommended_action` VARCHAR(15),
  `price_range` TEXT,
  `expected_return_rate` DECIMAL(5,2),
  `success_probability` DECIMAL(5,2),
  `rationale` TEXT,
  `market_context` TEXT,
  `status` VARCHAR(10) DEFAULT 'ACTIVE',
  `created_at` TIMESTAMP,
  `updated_at` TIMESTAMP
);

-- 用户策略关联表
CREATE TABLE IF NOT EXISTS `user_strategies` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` VARCHAR(42),
  `strategy_id` VARCHAR(32),
  `status` VARCHAR(10),
  `adopted_at` TIMESTAMP NULL,
  `expired_at` TIMESTAMP NULL,
  `expiry_reason` VARCHAR(50),
  `profit_amount` DECIMAL(20,8) NULL,
  `is_successful` BOOLEAN NULL,
  `created_at` TIMESTAMP,
  `updated_at` TIMESTAMP,
  UNIQUE KEY `user_strategy_unique` (`user_id`, `strategy_id`)
);
```

## 五、API接口详细设计

### 1. 鲸鱼追踪API

#### 1.1 获取鲸鱼统计数据
```
GET /api/whale-tracking/stats
```

**返回数据示例**:
```json
{
  "activeWhales": 128,
  "smartWhales": 65,
  "dumbWhales": 32,
  "successRate": 76.5
}
```

#### 1.2 获取实时交易流
```
GET /api/whale-tracking/transactions?page=1&pageSize=10
```

**请求参数**:
- `page`: 页码，默认为1
- `pageSize`: 每页条数，默认为10，最大50
- `whaleType`: 鲸鱼类型筛选 (all/smart/dumb)，可选
- `actionType`: 交易行为类型筛选，可选
- `collection`: 收藏集筛选，可选

**返回数据示例**:
```json
{
  "total": 1568,
  "page": 1,
  "pageSize": 10,
  "transactions": [
    {
      "id": "0x1234...",
      "time": "2023-06-17T09:30:15Z",
      "nftName": "BAYC #1234",
      "collection": "Bored Ape Yacht Club",
      "seller": "0xabc...",
      "buyer": "0xdef...",
      "price": 68.5,
      "priceChange": 5.2,
      "rarityRank": 423,
      "whaleInfluence": 82,
      "actionType": "accumulate",
      "isWhale": true,
      "whaleIsBuyer": true,
      "whaleIsSeller": false,
      "whaleAddress": "0xdef..."
    },
    // 更多交易...
  ]
}
```

#### 1.3 收藏集流向分析
```
GET /api/whale-tracking/collection-flow?timeRange=week&whaleType=all&flowType=inflow
```

**请求参数**:
- `timeRange`: 时间范围 (day/week/month)，默认week
- `whaleType`: 鲸鱼类型 (all/smart/dumb)，默认all
- `flowType`: 流向类型 (inflow/outflow)，默认inflow
- `limit`: 返回数量，默认10，最大20

**返回数据示例**:
```json
{
  "collections": [
    {
      "name": "Bored Ape Yacht Club",
      "value": 1256.8,
      "icon": "https://...",
      "timeRange": "week",
      "whaleType": "all",
      "flowType": "inflow",
      "transactionCount": 18,
      "percentageOfTotal": 23.5
    },
    // 更多收藏集...
  ]
}
```

#### 1.4 鲸鱼交易额分析
```
GET /api/whale-tracking/volume-analysis?timeRange=week
```

**请求参数**:
- `timeRange`: 时间范围 (day/week/month)，默认week
- `limit`: 返回数量，默认10，最大20

**返回数据示例**:
```json
{
  "whales": [
    {
      "whaleId": "0x1234...",
      "tradingVolume": 2458.65,
      "timeRange": "week",
      "percentageOfTotal": 12.5,
      "transactionCount": 32,
      "averageTransactionValue": 76.8,
      "dominantAction": "买入"
    },
    // 更多鲸鱼...
  ]
}
```

#### 1.5 鲸鱼收益率分析
```
GET /api/whale-tracking/profit-analysis?timeRange=month
```

**请求参数**:
- `timeRange`: 时间范围 (day/week/month)，默认month
- `limit`: 返回数量，默认10，最大20

**返回数据示例**:
```json
{
  "whales": [
    {
      "whaleId": "0x1234...",
      "profitRate": 58.6,
      "profit": 865.2,
      "timeRange": "month",
      "investmentAmount": 1476.2,
      "successfulTrades": 28,
      "failedTrades": 7
    },
    // 更多鲸鱼...
  ]
}
```

#### 1.6 钱包详细分析
```
GET /api/whale-tracking/wallet/{address}
```

**路径参数**:
- `address`: 钱包地址

**返回数据示例**:
```json
{
  "walletInfo": {
    "address": "0x1234...",
    "label": "鲸鱼钱包",
    "totalTransactions": 256,
    "totalVolume": 12485.6,
    "holdingValue": 8562.3,
    "profitLoss": 3245.8,
    "profitRate": 42.6,
    "firstActivity": "2022-03-15T12:34:56Z",
    "tradingTrends": [
      {
        "date": "2023-06-01",
        "value": 256.8
      },
      // 更多趋势数据...
    ],
    "nftHoldings": [
      {
        "name": "Bored Ape Yacht Club",
        "value": 3456.2,
        "count": 3,
        "acquisitionValue": 2845.6,
        "unrealizedProfit": 610.6
      },
      // 更多持有数据...
    ],
    "recentTransactions": [
      {
        "id": 12345,
        "time": "2023-06-15T09:30:15Z",
        "type": "买入",
        "collection": "Azuki",
        "tokenId": "3456",
        "price": 12.5,
        "withWhale": false,
        "profitLoss": null
      },
      // 更多交易记录...
    ],
    "frequentlyTradedWith": [
      {
        "address": "0xabcd...",
        "count": 12,
        "isWhale": true
      },
      // 更多交易对手...
    ]
  }
}
```

#### 1.7 WebSocket实时交易推送
```
WS /api/whale-tracking/stream
```

**事件示例**:
```json
{
  "type": "new_transaction",
  "data": {
    // 单条交易数据，格式同1.2接口
  }
}
```

### 2. 低价狙击API

#### 2.1 获取统计卡片数据
```
GET /api/nft-snipe/stats
```

**返回数据示例**:
```json
{
  "lowestCost": 5.2,
  "highestDiscountRate": 33.5,
  "potentialProfit": 58.2,
  "profitRate": 24.8,
  "lastUpdated": "2023-06-15T08:30:22Z"
}
```

#### 2.2 获取实时低价藏品
```
GET /api/nft-snipe/discount-items?discountLevel=high&timeRange=day&page=1&pageSize=10
```

**请求参数**:
- `discountLevel`: 折扣等级筛选 (all/high/medium/low)，默认all
- `timeRange`: 时间范围筛选 (all/hour/day)，默认day
- `page`: 页码，默认为1
- `pageSize`: 每页条数，默认为10，最大50
- `sort`: 排序字段(discount/time/price)，默认discount
- `order`: 排序方向(asc/desc)，默认desc

**返回数据示例**:
```json
{
  "total": 126,
  "page": 1,
  "pageSize": 10,
  "items": [
    {
      "id": "1",
      "time": "刚刚",
      "timeInMs": 1686837792000,
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
      "expiresIn": "2小时15分钟",
      "expiresAt": 1686844992000
    },
    // 更多藏品...
  ]
}
```

#### 2.3 获取日历统计数据
```
GET /api/nft-snipe/calendar-data?startDate=2023-03-01&endDate=2023-06-15&view=count
```

**请求参数**:
- `startDate`: 开始日期，格式YYYY-MM-DD，默认为当前日期前90天
- `endDate`: 结束日期，格式YYYY-MM-DD，默认为当前日期
- `view`: 视图类型(count/profit)，默认count

**返回数据示例**:
```json
{
  "calendarData": {
    "2023-04-01": {
      "count": 7,
      "profit": 15.3
    },
    "2023-04-02": {
      "count": 5,
      "profit": 10.8
    },
    // 更多日期数据...
  }
}
```

#### 2.4 WebSocket低价机会推送
```
WS /api/nft-snipe/stream
```

**事件示例**:
```json
{
  "type": "new_discount_item",
  "data": {
    // 单条折扣藏品数据，格式同2.2接口
  }
}
```

### 3. 策略推荐API

#### 3.1 获取策略数据
```
GET /api/strategies?status=active&page=1&pageSize=10
```

**请求参数**:
- `status`: 策略状态过滤（active/adopted/expired），可选
- `page`: 页码，默认为1
- `pageSize`: 每页数量，默认为10，最大50
- `type`: 策略类型过滤（WHALE_BUY/WHALE_SELL/LOW_PRICE），可选

**返回数据示例**:
```json
{
  "total": 100,
  "page": 1,
  "pageSize": 10,
  "data": [
    {
      "id": "STR-20230615143022",
      "type": "WHALE_BUY",
      "collectionId": "bayc",
      "collectionName": "Bored Ape Yacht Club",
      "nftId": "3429",
      "currentPrice": 68.25,
      "priceTrend": "up",
      "priority": 85,
      "status": "ACTIVE",
      "createdAt": "2023-06-15T14:30:22Z",
      "expiresAt": "2023-06-16T14:30:22Z",
      "rationale": "鲸鱼集中买入信号增强",
      "successRate": 76.5
    },
    // 更多策略...
  ]
}
```

#### 3.2 获取策略统计数据
```
GET /api/strategies/stats
```

**返回数据示例**:
```json
{
  "activeCount": 7,
  "adoptedCount": 2,
  "expiredCount": 3,
  "successRate": 76.8
}
```

#### 3.3 采纳策略
```
POST /api/strategies/:id/adopt
```

**路径参数**:
- `id`: 策略ID

**返回数据示例**:
```json
{
  "success": true,
  "strategy": {
    "id": "STR-20230615143022",
    "status": "ADOPTED",
    "adoptedAt": "2023-06-17T09:30:15Z"
  }
}
```

#### 3.4 放弃策略
```
POST /api/strategies/:id/abandon
```

**路径参数**:
- `id`: 策略ID

**请求体**:
```json
{
  "reason": "价格已变动"
}
```

**返回数据示例**:
```json
{
  "success": true,
  "strategy": {
    "id": "STR-20230615143022",
    "status": "EXPIRED",
    "expiredAt": "2023-06-17T09:30:15Z",
    "expiryReason": "用户放弃：价格已变动"
  }
}
```

## 六、数据同步机制

### 1. 定时数据同步任务

从数据湖同步数据到API服务数据库：

1. **实时数据同步（5分钟间隔）**
   - 交易数据 
   - 低价机会
   - 最新策略

2. **准实时数据同步（1小时间隔）**
   - 钱包信息更新
   - 收藏集流向数据
   - 交易额和收益率分析

3. **日常数据同步（每日）**
   - 历史统计数据
   - 策略成功率计算

### 2. 消息队列机制

使用Kafka处理实时数据流：
- 数据湖 -> Kafka -> 后端服务 -> WebSocket推送

### 3. 缓存策略

使用Redis缓存热点数据：
- API响应缓存（TTL 5分钟）
- 统计数据缓存（TTL 10分钟）
- 用户会话和权限缓存

## 七、性能优化策略

### 1. 数据库优化
- 合理设计索引
- 大表分区
- 批量操作优化
- 读写分离（必要时）

### 2. API性能优化
- 分页和限流
- 压缩传输
- 按需加载
- 异步处理长时间操作

### 3. 缓存优化
- 多级缓存策略
- 热点数据预加载
- 缓存穿透保护

## 八、安全与权限设计

### 1. 认证机制
- JWT令牌认证
- OAuth2集成（可选）
- API密钥认证（服务间）

### 2. 授权控制
- 基于角色的访问控制(RBAC)
- API访问限制
- 数据访问过滤

### 3. 安全措施
- HTTPS传输加密
- 敏感数据加密存储
- SQL注入防护
- XSS防护
- CSRF防护

## 九、项目开发计划

### 阶段一：环境搭建与基础框架（1周）
- 搭建Spring Boot框架
- 配置数据库连接
- 实现基础组件
- 搭建开发环境

### 阶段二：数据模型与同步机制（2周）
- 设计并实现数据库表
- 开发数据同步机制
- 测试数据流通性

### 阶段三：核心API实现（3周）
- 实现鲸鱼追踪API
- 实现低价狙击API
- 实现策略推荐API
- 单元测试与集成测试

### 阶段四：性能优化与安全加固（2周）
- 性能测试与优化
- 安全审计与加固
- 缓存策略实现

### 阶段五：文档编写与部署（1周）
- API文档生成
- 部署文档编写
- 系统部署与测试

## 十、监控与运维

### 1. 监控指标
- API响应时间
- 数据同步状态
- 系统资源使用情况
- 错误率统计

### 2. 告警机制
- API异常告警
- 数据同步失败告警
- 系统资源告警

### 3. 日志管理
- 分级日志
- 集中式日志收集
- 日志分析与可视化

## 十一、扩展性考虑

### 1. 微服务拆分（未来）
- 按业务域拆分服务
- API网关集成
- 服务注册与发现

### 2. 容器化部署
- Docker容器化
- Kubernetes编排
- CI/CD流水线

### 3. 弹性伸缩
- 负载均衡
- 自动扩缩容
- 流量调度 


针对三个前端页面的后端工作解析
一、鲸鱼追踪页面后端工作
API接口设计
统计数据接口 /api/whale-tracking/stats
提供活跃鲸鱼数量、智能鲸鱼数量、非智能鲸鱼数量和成功率等关键指标
数据需聚合计算，后期从Doris读取
实时交易列表接口 /api/whale-tracking/transactions
支持分页、筛选(鲸鱼类型、交易行为类型、收藏集)
需包含交易ID、时间、NFT名称、收藏集、卖家、买家、价格等详细信息
收藏集流向分析接口 /api/whale-tracking/collection-flow
提供不同时间范围、鲸鱼类型的收藏集资金流向数据
支持流入/流出筛选
鲸鱼交易额分析接口 /api/whale-tracking/volume-analysis
返回鲸鱼交易额排名
包含交易量、占比、交易次数等信息
钱包详细分析接口 /api/whale-tracking/wallet/{address}
提供指定钱包的详细信息、交易历史和持有情况
实时数据功能
WebSocket实时交易推送 /api/whale-tracking/stream
实现服务端推送技术，向前端实时推送新交易
需要设计消息格式和连接管理
二、低价狙击页面后端工作
API接口设计
低价统计卡片数据接口 /api/nft-snipe/stats
提供最低成本、最高折扣率、潜在利润等统计数据
实时低价藏品接口 /api/nft-snipe/discount-items
支持按折扣等级、时间范围筛选和排序
分页返回低价藏品详情，包含当前价格、市场价格、折扣等信息
日历统计数据接口 /api/nft-snipe/calendar-data
提供历史低价机会数量和潜在利润统计
支持日期范围查询
实时数据功能
WebSocket低价机会推送 /api/nft-snipe/stream
实时推送新的低价机会
需确保推送性能和及时性
三、策略推荐页面后端工作
API接口设计
策略列表接口 /api/strategies
支持按状态(活跃/已采纳/已过期)、类型筛选
分页返回策略数据，包含策略ID、类型、收藏集、优先级等信息
策略统计数据接口 /api/strategies/stats
提供活跃、已采纳、已过期策略数量和成功率
采纳策略接口 /api/strategies/:id/adopt
用户采纳策略的处理逻辑
更新策略状态和关联信息
放弃策略接口 /api/strategies/:id/abandon
处理用户放弃策略的请求
记录放弃原因
四、共同的后端工作
数据处理层
模型设计
根据前端需求设计实体类和DTO
映射数据库表结构
数据转换
将数据库查询结果转换为API响应格式
处理日期、价格等特殊字段格式化







NFT鲸鱼追踪系统后端开发计划（不含数据源集成）
一、项目结构与框架搭建（5天）
多模块项目创建
创建Spring Boot项目框架
配置多模块结构（core、api、service、model、mock）
配置Maven/Gradle依赖管理
基础配置与环境设置
配置application.yml（开发、测试、生产环境）
配置日志系统
配置全局异常处理
搭建API文档（OpenAPI/Swagger）
通用组件开发
统一响应结构（ApiResponse）
分页工具类
日期时间处理工具
通用校验器
二、API控制器实现（7天）
鲸鱼追踪API
统计数据接口
实时交易流接口
收藏集流向分析接口
鲸鱼交易额分析接口
鲸鱼收益率分析接口
钱包详细分析接口
低价狙击API
统计卡片数据接口
实时低价藏品接口
日历统计数据接口
策略推荐API
策略列表接口
策略统计接口
策略采纳与放弃接口
三、模拟数据层实现（5天）
数据模型定义
实体类与DTO定义
枚举类定义
转换器开发
模拟数据生成器
静态JSON数据文件
随机数据生成器
模拟数据更新机制
数据访问接口
抽象数据访问接口
模拟数据实现
为真实数据源预留接口
四、服务层实现（7天）
鲸鱼追踪服务
统计服务
交易流服务
收藏集分析服务
钱包分析服务
低价狙击服务
机会统计服务
低价发现服务
历史数据分析服务
策略推荐服务
策略管理服务
策略统计服务
用户策略关联服务
五、WebSocket实时服务实现（3天）
WebSocket配置
连接管理
会话追踪
安全配置
实时数据推送服务
鲸鱼交易推送
低价机会推送
自动断线重连机制
六、缓存层实现（3天）
Redis缓存配置
连接池配置
序列化器配置
缓存键生成策略
业务缓存实现
统计数据缓存
热点数据缓存
缓存更新策略