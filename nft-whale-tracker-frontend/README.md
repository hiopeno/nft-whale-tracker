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
│   │   ├── WhaleTrack/      # 仪表盘页面
│   │   ├── NftSnipe/        # 机会页面
│   │   └── Strategy/        # 策略页面
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
