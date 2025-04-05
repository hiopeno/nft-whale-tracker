/**
 * API配置文件
 */

// API基础URL，根据不同环境配置不同的URL
const API_BASE_URL = process.env.NODE_ENV === 'production'
  ? '/api' // 生产环境下使用相对路径，由nginx代理转发
  : 'http://localhost:8080'; // 开发环境直接连接后端

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
    stats: `${API_VERSION}/whale-tracking/stats`,
    transactions: `${API_VERSION}/whale-tracking/transactions`,
    collectionFlow: `${API_VERSION}/whale-tracking/collection-flow`,
    volumeAnalysis: `${API_VERSION}/whale-tracking/volume-analysis`,
    profitAnalysis: `${API_VERSION}/whale-tracking/profit-analysis`,
    wallet: (address: string) => `${API_VERSION}/whale-tracking/wallet/${address}`,
  },
  
  // WebSocket相关
  websocket: {
    status: `${API_VERSION}/websocket/status`,
    sendNotification: `${API_VERSION}/websocket/send-notification`,
    sendTransactionNotification: `${API_VERSION}/websocket/send-transaction-notification`,
    sendDealOpportunity: `${API_VERSION}/websocket/send-deal-opportunity`,
    setTransactionNotificationEnabled: `${API_VERSION}/websocket/transaction-notification/enabled`,
    setDealOpportunityEnabled: `${API_VERSION}/websocket/deal-opportunity/enabled`,
    scanMarketplace: `${API_VERSION}/websocket/scan-marketplace`,
  },
};

// WebSocket主题
const WS_TOPICS = {
  transactions: '/topic/transactions',
  dealOpportunities: '/topic/deal-opportunities',
  systemNotifications: '/topic/system-notifications',
};

// 导出配置
export { API_BASE_URL, WS_BASE_URL, API_ENDPOINTS, WS_TOPICS }; 