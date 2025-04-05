# NFT鲸鱼追踪系统

本项目是一个用于追踪NFT市场中鲸鱼活动的系统，包含前端和后端两个部分。

## 项目结构

- `nft-whale-tracker-frontend` - 前端项目（React + TypeScript）
- `nft-whale-tracker-backend` - 后端项目（Spring Boot + Java）
- `docker-compose.yml` - Docker Compose配置文件，用于启动整个系统

## 功能特点

- 鲸鱼账户监控与分析
- NFT交易实时追踪
- 低价机会自动检测
- WebSocket实时推送
- 交易数据可视化

## 如何运行

### 开发环境

#### 后端

1. 进入后端目录：`cd nft-whale-tracker-backend`
2. 使用Maven构建：`./mvnw clean install -DskipTests`
3. 运行Spring Boot应用：`./mvnw spring-boot:run`
4. 后端将在 http://localhost:8080 上运行

#### 前端

1. 进入前端目录：`cd nft-whale-tracker-frontend`
2. 安装依赖：`npm install`
3. 启动开发服务器：`npm start`
4. 前端将在 http://localhost:3000 上运行

### 生产环境（使用Docker）

整个系统可以使用Docker Compose一键启动：

```bash
docker-compose up -d
```

访问地址：http://localhost

## 前后端对接

前后端之间通过以下方式进行数据交互：

1. **REST API**：前端通过HTTP请求获取数据和触发后端操作
2. **WebSocket**：后端通过WebSocket向前端推送实时消息，如新交易通知和低价机会

详细API文档请参考各项目目录中的文档。

## 技术栈

### 前端

- React 18
- TypeScript
- Ant Design
- ECharts
- Axios
- SockJS & STOMP

### 后端

- Spring Boot 2.7
- Spring WebSocket
- Spring Data JPA
- H2数据库（开发环境）
- Lombok

## 许可证

MIT 