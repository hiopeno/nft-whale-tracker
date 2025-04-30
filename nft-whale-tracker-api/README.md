# NFT鲸鱼追踪器API服务

这是一个基于Spring Boot的API服务，直接通过Apache Paimon Java API连接数据湖，为NFT鲸鱼追踪器前端提供数据支持。

## 项目结构

```
nft-whale-tracker-api/
├── src/                           # 源代码
│   ├── main/
│   │   ├── java/
│   │   │   └── org/bigdatatechcir/whale/api/
│   │   │       ├── config/        # 配置类
│   │   │       ├── controller/    # REST控制器
│   │   │       ├── service/       # 服务层
│   │   │       └── Application.java # 应用启动类
│   │   └── resources/
│   │       └── application.yml    # 应用配置文件
├── pom.xml                        # Maven配置
├── run.sh                         # 运行脚本
└── README.md                      # 项目说明
```

## 功能特性

- 直接通过Paimon Java API读取数据湖中的数据
- 提供REST API服务，供前端调用
- 支持鲸鱼追踪、交易分析等数据查询
- 提供通用数据湖查询接口
- 模拟WebSocket相关API服务

## 技术栈

- Java 8
- Spring Boot 2.7.8
- Apache Paimon 1.0.1
- Hadoop 3.1.3
- Hive 3.1.3

## 环境要求

- JDK 1.8+
- Maven 3.6+
- Hadoop环境
- Hive元数据服务

## 安装与运行

1. 克隆项目

```bash
cd /root/nft-whale-tracker
git clone https://github.com/your-username/nft-whale-tracker-api.git
cd nft-whale-tracker-api
```

2. 编译项目

```bash
mvn clean package -DskipTests
```

3. 运行应用

```bash
./run.sh
```

或者直接运行JAR文件：

```bash
java -jar target/nft-whale-tracker-api-1.0.0.jar
```

## API接口使用指南

服务默认运行在 `8886` 端口，所有API路径前缀为 `/api`。

### 1. 数据湖通用查询API

这些API允许您直接查询底层数据湖中的任何表。

#### 1.1 获取数据库列表

```
GET /api/data/databases
```

**请求示例:**
```bash
curl -X GET http://localhost:8886/api/data/databases
```

**响应示例:**
```json
[
  "ads",
  "ods",
  "dwd"
]
```

#### 1.2 获取指定数据库的表列表

```
GET /api/data/tables/{database}
```

**请求示例:**
```bash
curl -X GET http://localhost:8886/api/data/tables/ads
```

**响应示例:**
```json
[
  "ads_whale_transactions",
  "ads_whale_tracking_list",
  "ads_collection_stats"
]
```

#### 1.3 获取表结构信息

```
GET /api/data/schema/{database}/{table}
```

**请求示例:**
```bash
curl -X GET http://localhost:8886/api/data/schema/ads/ads_whale_transactions
```

**响应示例:**
```json
[
  {"name": "transaction_id", "type": "VARCHAR(64)"},
  {"name": "wallet_address", "type": "VARCHAR(42)"},
  {"name": "collection", "type": "VARCHAR(255)"},
  {"name": "token_id", "type": "VARCHAR(64)"},
  {"name": "price", "type": "DECIMAL(20,8)"},
  {"name": "transaction_time", "type": "TIMESTAMP(3)"},
  {"name": "action_type", "type": "VARCHAR(20)"}
]
```

#### 1.4 查询表数据

```
GET /api/data/query/{database}/{table}?limit={limit}
```

**参数:**
- `limit`: 返回记录的最大数量，默认为100

**请求示例:**
```bash
curl -X GET http://localhost:8886/api/data/query/ads/ads_whale_transactions?limit=5
```

**响应示例:**
```json
[
  {
    "transaction_id": "0x1234567890abcdef",
    "wallet_address": "0xabcdef1234567890",
    "collection": "Bored Ape Yacht Club",
    "token_id": "1234",
    "price": 100.5,
    "transaction_time": "2023-06-15T14:30:45",
    "action_type": "BUY"
  },
  ...
]
```

### 2. 鲸鱼追踪专用API

这些API专门用于NFT鲸鱼交易分析。

#### 2.1 获取鲸鱼交易记录

```
GET /api/whale-tracking/transactions?limit={limit}
```

**参数:**
- `limit`: 返回记录的最大数量，默认为100

**请求示例:**
```bash
curl -X GET http://localhost:8886/api/whale-tracking/transactions?limit=10
```

**响应示例:**
```json
[
  {
    "transaction_id": "0x1234567890abcdef",
    "wallet_address": "0xabcdef1234567890",
    "collection": "Bored Ape Yacht Club",
    "token_id": "1234",
    "price": 100.5,
    "transaction_time": "2023-06-15T14:30:45",
    "action_type": "BUY",
    "whale_type": "MEGA_WHALE"
  },
  ...
]
```

#### 2.2 获取鲸鱼追踪列表

```
GET /api/whale-tracking/tracking-list?limit={limit}
```

**参数:**
- `limit`: 返回记录的最大数量，默认为100

**请求示例:**
```bash
curl -X GET http://localhost:8886/api/whale-tracking/tracking-list?limit=10
```

**响应示例:**
```json
[
  {
    "wallet_address": "0xabcdef1234567890",
    "whale_type": "MEGA_WHALE",
    "total_volume": 5000.75,
    "avg_holding_period": 45.3,
    "profit_ratio": 2.34,
    "collections_traded": 24,
    "last_active": "2023-06-15T14:30:45"
  },
  ...
]
```

#### 2.3 测试数据湖连接

```
GET /api/whale-tracking/test-connection
```

**请求示例:**
```bash
curl -X GET http://localhost:8886/api/whale-tracking/test-connection
```

**响应示例:**
```json
{
  "status": "success",
  "databases": ["ads", "ods", "dwd"],
  "tables": ["ads_whale_transactions", "ads_whale_tracking_list"],
  "database": "ads",
  "table": "ads_whale_transactions",
  "schema": [
    {"name": "transaction_id", "type": "VARCHAR(64)"}
  ],
  "data": [
    {"transaction_id": "0x1234567890abcdef"}
  ]
}
```

### 3. WebSocket模拟API

这些API模拟了WebSocket通知功能。

#### 3.1 获取WebSocket服务状态

```
GET /api/websocket/status
```

**请求示例:**
```bash
curl -X GET http://localhost:8886/api/websocket/status
```

**响应示例:**
```json
{
  "status": "running",
  "connectedClients": 1,
  "transactionNotificationEnabled": true,
  "dealOpportunityEnabled": true
}
```

#### 3.2 发送交易通知

```
POST /api/websocket/send-transaction-notification
```

**请求体示例:**
```json
{
  "type": "transaction",
  "walletAddress": "0xabcdef1234567890",
  "collection": "Bored Ape Yacht Club",
  "tokenId": "1234",
  "price": 100.5,
  "actionType": "BUY"
}
```

**请求示例:**
```bash
curl -X POST http://localhost:8886/api/websocket/send-transaction-notification \
  -H "Content-Type: application/json" \
  -d '{"type":"transaction","walletAddress":"0xabcdef1234567890","collection":"Bored Ape Yacht Club","tokenId":"1234","price":100.5,"actionType":"BUY"}'
```

**响应示例:**
```json
{
  "success": true,
  "messageId": 1686840645000
}
```

#### 3.3 发送低价机会通知

```
POST /api/websocket/send-deal-opportunity
```

**请求体示例:**
```json
{
  "collection": "Bored Ape Yacht Club",
  "tokenId": "1234",
  "price": 80.5,
  "floorPrice": 100.0,
  "discount": 19.5,
  "marketplace": "OpenSea"
}
```

**请求示例:**
```bash
curl -X POST http://localhost:8886/api/websocket/send-deal-opportunity \
  -H "Content-Type: application/json" \
  -d '{"collection":"Bored Ape Yacht Club","tokenId":"1234","price":80.5,"floorPrice":100.0,"discount":19.5,"marketplace":"OpenSea"}'
```

**响应示例:**
```json
{
  "success": true,
  "messageId": 1686840645001
}
```

### 4. 使用注意事项

1. 确保服务正常运行并可访问，默认地址为 `http://localhost:8886/api`
2. 对于大量数据查询，请合理使用`limit`参数限制返回记录数
3. API响应中的错误信息会包含在响应体中，格式为`{"error": "错误信息"}`
4. 所有时间戳格式为ISO-8601标准：`YYYY-MM-DDTHH:MM:SS`
5. 价格通常以ETH为单位

### 5. 常见问题排查

1. **无法连接服务器**
   - 检查服务是否已启动：`ps -ef | grep nft-whale-tracker-api`
   - 检查端口是否被占用：`netstat -tulpn | grep 8886`

2. **数据查询返回空结果**
   - 检查数据湖连接配置是否正确
   - 检查数据库/表名是否存在
   - 查看日志获取详细错误信息：`tail -f api.log`

3. **服务启动失败**
   - 检查JDK版本是否符合要求
   - 确保数据湖配置正确
   - 查看启动日志排查具体问题

## 性能优化建议

1. 对频繁访问的表数据添加缓存机制
2. 考虑添加连接池管理Paimon Catalog连接
3. 针对大表查询添加分页优化
4. 添加异步处理机制处理耗时操作

## 许可证

[MIT License](LICENSE) 