/**
 * API配置文件
 */

// API基础URL，根据不同环境配置不同的URL
const API_BASE_URL = process.env.NODE_ENV === 'production'
  ? '/api' // 生产环境下使用相对路径，由nginx代理转发
  : 'http://localhost:8886/api'; // 开发环境直接连接后端API服务

// WebSocket基础URL
const WS_BASE_URL = process.env.NODE_ENV === 'production'
  ? '/ws' // 生产环境下使用相对路径
  : 'ws://localhost:8080/ws'; // 开发环境直接连接后端WebSocket

// API版本
const API_VERSION = '/api';

// API端点
const API_ENDPOINTS = {
  // 鲸鱼追踪相关
  whaleTracking: {
    stats: `/whale-tracking/stats`,
    transactions: `/whale-tracking/transactions`,
    collectionFlow: `/whale-tracking/collection-flow`,
    volumeAnalysis: `/whale-tracking/volume-analysis`,
    profitAnalysis: `/whale-tracking/profit-analysis`,
    wallet: (address: string) => `/whale-tracking/wallet/${address}`,
  },
  
  // WebSocket相关
  websocket: {
    status: `/websocket/status`,
    sendNotification: `/websocket/send-notification`,
    sendTransactionNotification: `/websocket/send-transaction-notification`,
    sendDealOpportunity: `/websocket/send-deal-opportunity`,
    setTransactionNotificationEnabled: `/websocket/transaction-notification/enabled`,
    setDealOpportunityEnabled: `/websocket/deal-opportunity/enabled`,
    scanMarketplace: `/websocket/scan-marketplace`,
  },
  
  // 数据湖通用查询
  dataLake: {
    databases: `/data/databases`,
    tables: (database: string) => `/data/tables/${database}`,
    schema: (database: string, table: string) => `/data/schema/${database}/${table}`,
    query: (database: string, table: string, limit: number = 100) => 
      `/data/query/${database}/${table}?limit=${limit}`,
  }
};

// WebSocket主题
const WS_TOPICS = {
  transactions: '/topic/transactions',
  dealOpportunities: '/topic/deal-opportunities',
  systemNotifications: '/topic/system-notifications',
};

// 导出配置
export { API_BASE_URL, WS_BASE_URL, API_ENDPOINTS, WS_TOPICS }; 