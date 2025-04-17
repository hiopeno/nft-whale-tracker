# NFT鲸鱼追踪系统前端

## 项目概述

本项目是NFT鲸鱼追踪系统的前端部分，提供了以下功能：

- 鲸鱼追踪仪表盘：实时展示鲸鱼钱包活动
- 低价NFT机会：展示低价NFT交易机会
- 交易策略推荐：提供NFT交易策略建议

## 技术栈

- React 18 + TypeScript
- Ant Design + Ant Design Pro Components
- ECharts
- Docker

## 开发环境

### 前置条件

- Node.js 16+
- npm 8+
- Docker (可选，用于容器化部署)

### 安装依赖

```bash
npm install
```

### 本地开发

```bash
npm run dev
```

### 构建项目

```bash
npm run build
```

## Docker部署

### 构建镜像

```bash
docker build -t nft-whale-tracker-frontend .
```

### 运行容器

```bash
docker run -d -p 80:80 --name nft-whale-tracker-frontend nft-whale-tracker-frontend
```

### 使用Docker Compose

```bash
docker-compose up -d
```

## 项目结构

```
nft-whale-tracker-frontend/
├── public/                  # 静态资源
├── src/                     # 源代码
│   ├── api/                 # API接口
│   ├── assets/              # 资源文件
│   ├── components/          # 共用组件
│   │   └── Layout/          # 布局组件
│   ├── hooks/               # 自定义hooks
│   ├── pages/               # 页面组件
│   │   ├── WhaleTrack/      # 鲸鱼追踪页面
│   │   ├── NftSnipe/        # 藏品狙击页面
│   │   └── Strategy/        # 策略推荐页面
│   ├── store/               # 状态管理
│   ├── utils/               # 工具函数
│   ├── App.tsx              # 应用入口
│   └── main.tsx             # 主入口
├── .gitignore               # git忽略文件
├── docker-compose.yml       # Docker Compose配置
├── Dockerfile               # Docker配置
├── index.html               # HTML模板
├── nginx.conf               # Nginx配置
├── package.json             # 项目依赖
├── README.md                # 项目说明
├── tsconfig.json            # TypeScript配置
└── vite.config.ts           # Vite配置
```

## 后续计划

- 添加用户认证
- 实现实时数据更新
- 增加图表与分析功能
- 优化移动端体验

## 与后端对接

本前端项目通过API和WebSocket与后端进行对接，对接方式如下：

### REST API对接

前端通过`/src/api/api.ts`中定义的函数与后端REST API进行交互：

```typescript
// 示例：获取鲸鱼统计数据
whaleTrackingApi.getWhaleStats().then(data => {
  console.log(data);
});

// 示例：获取交易列表
whaleTrackingApi.getTransactions({
  page: 1,
  pageSize: 10,
  whaleType: 'all'
}).then(data => {
  console.log(data);
});
```

### WebSocket对接

前端通过`/src/api/websocket.ts`中的WebSocketService与后端WebSocket进行实时消息交互：

```typescript
// 在应用入口初始化WebSocket服务
import { initWebSocket, websocketService } from './api';
initWebSocket();

// 订阅交易通知
websocketService.subscribeTransactions((message) => {
  console.log('收到交易通知:', message);
});

// 订阅低价机会
websocketService.subscribeDealOpportunities((message) => {
  console.log('收到低价机会:', message);
});

// 订阅系统通知
websocketService.subscribeSystemNotifications((message) => {
  console.log('收到系统通知:', message);
});
```

### 开发环境配置

在开发环境中，前端默认连接`http://localhost:8080`和`ws://localhost:8080/ws`。如需修改，请在`/src/api/config.ts`中调整配置。

### 生产环境配置

在生产环境中，前端使用相对路径`/api`和`/ws`，通过Nginx代理转发到后端服务器。
