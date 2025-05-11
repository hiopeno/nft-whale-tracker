# NFT巨鲸追踪系统前端

## 项目概述

本项目是NFT巨鲸追踪系统的前端部分，提供了以下功能：

- 巨鲸追踪：实时展示鲸鱼钱包活动与分析
- 交易走势：展示NFT市场交易趋势
- 藏品狙击：快速发现低价NFT交易机会
- 策略推荐：提供NFT交易策略建议
- 系统设置：配置用户偏好和系统参数

## 技术栈

- React 18 + TypeScript
- Vite 构建工具
- Ant Design + Ant Design Pro Components
- ECharts + echarts-for-react 数据可视化
- SockJS + STOMP 实时通信
- Axios HTTP客户端
- Dayjs 日期处理库

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
│   │   ├── api.ts           # API调用函数
│   │   ├── config.ts        # API配置
│   │   ├── index.ts         # API导出
│   │   └── websocket.ts     # WebSocket服务
│   ├── assets/              # 静态资源文件
│   ├── components/          # 共用组件
│   │   └── Layout/          # 布局组件
│   ├── hooks/               # 自定义hooks
│   ├── pages/               # 页面组件
│   │   ├── WhaleTrack/      # 巨鲸追踪页面
│   │   ├── TradingTrend/    # 交易走势页面
│   │   ├── NftSnipe/        # 藏品狙击页面
│   │   ├── Strategy/        # 策略推荐页面
│   │   └── Setting/         # 系统设置页面
│   ├── services/            # 服务逻辑
│   ├── store/               # 状态管理
│   ├── styles/              # 样式文件
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

## 特性介绍

### 实时数据更新

前端通过WebSocket与后端保持实时连接，接收以下类型的实时通知：

1. 鲸鱼交易动态：监控大户交易活动
2. 低价机会提醒：发现价格异常的NFT
3. 系统消息通知：接收系统级别的提醒

### 数据可视化

使用ECharts实现丰富的数据可视化图表：

1. 交易量趋势图
2. 价格波动图表
3. 鲸鱼活动热力图
4. 资金流向关系图

### 主题设计

采用科技感十足的暗色主题设计，包含：

1. 发光边框效果
2. 渐变背景色
3. 元素悬停动画
4. 高对比度数据展示

## 与后端对接

### REST API对接

前端通过`/src/api/api.ts`中定义的函数与后端REST API进行交互：

```typescript
// 示例：获取鲸鱼统计数据
api.getWhaleStats().then(data => {
  console.log(data);
});

// 示例：获取交易列表
api.getTransactions({
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

## 环境配置

### 开发环境配置

在开发环境中，前端默认连接`http://localhost:8886/api`和`ws://localhost:8886/websocket`。如需修改，请在`/src/api/config.ts`中调整配置。

### 生产环境配置

在生产环境中，前端使用相对路径`/api`和`/websocket`，通过Nginx代理转发到后端服务器。
