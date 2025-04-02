# NFT策略推荐页面开发文档

## 页面概述

策略推荐页面是NFT鲸鱼追踪系统的核心功能之一，旨在为用户提供智能化的NFT投资策略建议。该页面根据系统分析得出的市场情报，向用户推荐三类投资策略：跟随巨鲸买入、跟随巨鲸卖出和藏品狙击。用户可以查看这些策略的详情，并可以选择采纳或放弃这些策略。

## 功能模块

### 1. 统计卡片

页面顶部显示四个关键指标卡片：
- **可行策略**：当前系统中可用的活跃策略总数
- **采纳策略**：用户已采纳的策略数量
- **失效策略**：已过期或被放弃的策略数量
- **策略成功率**：采纳策略中成功盈利的百分比

### 2. 可行策略列表

主要展示区域包含一个表格，显示当前所有可行的投资策略，包括以下字段：
- 策略ID：唯一标识符
- 策略类型：跟随巨鲸买入、跟随巨鲸卖出或藏品狙击
- 收藏集：策略相关的NFT收藏集
- NFT ID：具体NFT的ID（对于巨鲸策略可能显示为"ALL"）
- 现价：NFT当前价格
- 优先级：策略推荐的优先级（1-5级）
- 操作：采纳或放弃策略的按钮

### 3. 历史策略查看

用户可以点击"采纳策略"和"失效策略"统计卡片，查看相应的历史记录：
- **采纳策略列表**：显示用户已采纳的所有策略及其状态
- **失效策略列表**：显示已过期或被放弃的策略，包含失效原因和时间

## 数据模型

### 策略（Strategy）数据模型

```typescript
interface Strategy {
  id: string;            // 策略唯一标识，格式如：STR-YYYYMMDDHHMMSS
  type: StrategyType;    // 策略类型：WHALE_BUY, WHALE_SELL, LOW_PRICE
  collectionId: string;  // 收藏集ID
  collectionName: string;// 收藏集名称
  nftId?: string;        // NFT ID，对于巨鲸策略可能为空
  currentPrice: number;  // 当前价格（ETH）
  priceTrend: 'up' | 'down'; // 价格趋势
  priority: number;      // 优先级（百分比，0-100）
  status: StrategyStatus;// 状态：ACTIVE, ADOPTED, EXPIRED
  createdAt: Date;       // 创建时间
  adoptedAt?: Date;      // 采纳时间
  expiredAt?: Date;      // 失效时间
  expiryReason?: string; // 失效原因
  successRate?: number;  // 预估成功率
}

enum StrategyType {
  WHALE_BUY = 'WHALE_BUY',   // 跟随巨鲸买入
  WHALE_SELL = 'WHALE_SELL', // 跟随巨鲸卖出
  LOW_PRICE = 'LOW_PRICE'    // 藏品狙击
}

enum StrategyStatus {
  ACTIVE = 'ACTIVE',     // 活跃策略
  ADOPTED = 'ADOPTED',   // 已采纳
  EXPIRED = 'EXPIRED'    // 已失效
}
```

## API接口设计

### 1. 获取策略数据

```
GET /api/strategies?status=active&page=1&pageSize=10
```

**请求参数**：
- `status`: 策略状态过滤（active, adopted, expired），可选
- `page`: 页码，默认为1
- `pageSize`: 每页数量，默认为10

**响应数据**：
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
      "createdAt": "2023-06-15T14:30:22Z"
    },
    // 更多策略...
  ]
}
```

### 2. 获取策略统计数据

```
GET /api/strategies/stats
```

**响应数据**：
```json
{
  "activeCount": 7,
  "adoptedCount": 2,
  "expiredCount": 3,
  "successRate": 76.8
}
```

### 3. 采纳策略

```
POST /api/strategies/:id/adopt
```

**请求参数**：
- `id`: 策略ID

**响应数据**：
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

### 4. 放弃策略

```
POST /api/strategies/:id/abandon
```

**请求参数**：
- `id`: 策略ID
- `reason`: 放弃原因（可选）

**响应数据**：
```json
{
  "success": true,
  "strategy": {
    "id": "STR-20230615143022",
    "status": "EXPIRED",
    "expiredAt": "2023-06-17T09:30:15Z",
    "expiryReason": "用户放弃"
  }
}
```

## 数据库设计建议

### 策略表（strategies）

| 字段名 | 类型 | 说明 |
|-------|------|------|
| id | VARCHAR(20) | 主键，策略ID |
| type | ENUM | 策略类型（WHALE_BUY, WHALE_SELL, LOW_PRICE）|
| collection_id | VARCHAR(50) | 收藏集ID |
| collection_name | VARCHAR(100) | 收藏集名称 |
| nft_id | VARCHAR(50) | NFT ID（可空）|
| current_price | DECIMAL(20,8) | 当前价格（ETH）|
| price_trend | ENUM | 价格趋势（up, down）|
| priority | TINYINT | 优先级（0-100）|
| status | ENUM | 状态（ACTIVE, ADOPTED, EXPIRED）|
| created_at | TIMESTAMP | 创建时间 |
| adopted_at | TIMESTAMP | 采纳时间（可空）|
| expired_at | TIMESTAMP | 失效时间（可空）|
| expiry_reason | VARCHAR(50) | 失效原因（可空）|
| success_rate | DECIMAL(5,2) | 策略预估成功率 |
| user_id | VARCHAR(50) | 采纳用户ID（可空）|

### 索引设计

- PRIMARY KEY (`id`)
- INDEX `idx_status` (`status`)
- INDEX `idx_type` (`type`)
- INDEX `idx_collection` (`collection_id`)
- INDEX `idx_user_status` (`user_id`, `status`)

## 后端实现建议

### 1. 策略生成服务

需要实现一个周期性运行的服务，根据市场数据生成新的投资策略：

- **巨鲸买入策略**：跟踪知名鲸鱼账户的买入行为，当多个鲸鱼集中买入某收藏集时，生成跟随买入策略
- **巨鲸卖出策略**：跟踪知名鲸鱼账户的卖出行为，当多个鲸鱼集中卖出某收藏集时，生成跟随卖出策略
- **藏品狙击策略**：分析市场中被低估的NFT，当发现价格明显低于市场平均水平时，生成狙击策略

### 2. 策略状态管理

实现对策略状态的管理机制：

- **状态更新**：处理用户的采纳和放弃操作
- **自动过期**：设置策略的有效期，超时后自动标记为过期
- **成功率计算**：根据历史数据计算策略类型的成功率

### 3. 通知系统

为用户提供策略相关的通知：

- **新策略通知**：当系统生成高优先级策略时通知用户
- **策略状态变更**：当采纳的策略执行成功或失败时通知用户
- **市场机会提醒**：特殊市场机会（如突发性价格下跌）的紧急通知

## 性能与安全考虑

### 性能优化

1. **分页加载**：策略列表应支持分页加载，避免一次返回大量数据
2. **缓存机制**：对统计数据和热门策略实施缓存
3. **异步处理**：策略采纳和放弃操作应异步处理，避免用户等待

### 安全措施

1. **访问控制**：确保用户只能访问和操作自己的策略
2. **操作限流**：防止短时间内频繁操作造成的系统压力
3. **数据加密**：敏感数据（如用户ID、交易数据）应加密存储

## 监控指标

后端应收集以下指标以评估系统性能：

1. **策略生成速率**：每小时/每天生成的新策略数量
2. **策略采纳率**：用户采纳策略的比例
3. **策略成功率**：不同类型策略的实际成功率
4. **API响应时间**：各接口的平均响应时间

## 未来优化方向

1. **个性化推荐**：根据用户历史行为和偏好，提供个性化的策略推荐
2. **策略多样化**：增加更多类型的策略，如套利策略、趋势跟踪策略等
3. **风险评估**：为每个策略添加更详细的风险评估指标
4. **社交功能**：允许用户分享和讨论策略，形成社区互动 