# NFT Whale Tracker 与 Paimon 数据湖集成指南

## 概述

本文档详细说明了如何将 NFT Whale Tracker 后端系统与 Paimon 数据湖进行集成，实现数据的查询和实时处理。

## 已集成的功能

1. **Paimon 数据查询**：通过 Flink SQL 查询 Paimon 数据湖中的数据
2. **实时数据获取**：使用 WebSocket 实时推送最新交易数据
3. **REST API**：提供 RESTful API 接口查询各类数据
4. **自定义查询**：支持自定义 SQL 查询 Paimon 数据

## 系统架构

```
+-----------------+    +-----------------+    +----------------+
|                 |    |                 |    |                |
|  前端应用        |<-->|  后端 API 服务   |<-->|  Paimon 数据湖  |
|                 |    |                 |    |                |
+-----------------+    +-----------------+    +----------------+
        ^                      ^
        |                      |
        v                      v
+------------------+    +-----------------+
|                  |    |                 |
| WebSocket 实时通信 |    | Flink SQL 引擎  |
|                  |    |                 |
+------------------+    +-----------------+
```

## 配置说明

### 1. 应用配置

在 `application.properties` 中配置 Paimon 连接信息：

```properties
# Paimon配置
paimon.catalog.type=paimon
paimon.catalog.metastore=hive
paimon.catalog.uri=thrift://192.168.254.133:9083
paimon.catalog.hive-conf-dir=/opt/software/apache-hive-3.1.3-bin/conf
paimon.catalog.hadoop-conf-dir=/opt/software/hadoop-3.1.3/etc/hadoop
paimon.catalog.warehouse=hdfs:////user/hive/warehouse

# Flink配置
flink.home=/opt/software/flink-1.18.1
```

### 2. 依赖项

在 `pom.xml` 中添加以下依赖：

```xml
<!-- Paimon 依赖 -->
<dependency>
    <groupId>org.apache.paimon</groupId>
    <artifactId>paimon-flink-1.18</artifactId>
    <version>${paimon.version}</version>
</dependency>

<dependency>
    <groupId>org.apache.paimon</groupId>
    <artifactId>paimon-hive-catalog</artifactId>
    <version>${paimon.version}</version>
</dependency>

<!-- Flink 依赖 -->
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-java</artifactId>
    <version>${flink.version}</version>
</dependency>

<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-streaming-java</artifactId>
    <version>${flink.version}</version>
</dependency>

<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-clients</artifactId>
    <version>${flink.version}</version>
</dependency>

<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-table-api-java-bridge</artifactId>
    <version>${flink.version}</version>
</dependency>

<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-table-planner_2.12</artifactId>
    <version>${flink.version}</version>
</dependency>
```

## API 接口说明

### 1. RESTful API

| 接口                      | 方法   | 描述                   |
|--------------------------|-------|------------------------|
| `/api/whale/transactions` | GET   | 获取最近的NFT交易数据     |
| `/api/whale/wallets`      | GET   | 获取鲸鱼钱包数据         |
| `/api/whale/collections`  | GET   | 获取热门NFT集合数据      |
| `/api/whale/query`        | POST  | 执行自定义SQL查询       |

### 2. WebSocket

| 端点                     | 描述                          |
|-------------------------|------------------------------|
| `/api/ws/transactions`   | 实时推送最新NFT交易数据         |

## 使用示例

### 1. 前端连接后端API

```typescript
import { fetchRecentTransactions } from './services/api';

// 获取最近交易
const transactions = await fetchRecentTransactions(20);
console.log(transactions);
```

### 2. 前端连接WebSocket实时数据

```typescript
import { createTransactionWebSocket } from './services/api';

// 创建WebSocket连接
const socket = createTransactionWebSocket();

// 监听消息
socket.onmessage = (event) => {
  const transactions = JSON.parse(event.data);
  console.log('新交易:', transactions);
};
```

## 故障排除

### 1. 连接Paimon失败

- 检查Hive Metastore是否正常运行
- 验证`thrift://`连接地址是否正确
- 确认Hadoop配置目录路径正确

### 2. 查询数据表失败

- 确认数据库和表名是否正确
- 检查SQL语法是否有误
- 验证表结构与查询字段是否匹配

## 参考资料

- [Paimon官方文档](https://paimon.apache.org/docs/master/)
- [Flink SQL文档](https://nightlies.apache.org/flink/flink-docs-master/docs/dev/table/sql/overview/)
- [Hive Metastore配置](https://cwiki.apache.org/confluence/display/Hive/AdminManual+MetastoreAdmin) 