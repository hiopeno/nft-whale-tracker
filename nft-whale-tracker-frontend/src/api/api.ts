import axios from 'axios';
import { API_BASE_URL, API_ENDPOINTS } from './config';

// 创建axios实例
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000, // 请求超时时间
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    // 可以在这里处理请求前的操作，例如添加token
    const token = localStorage.getItem('token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器
api.interceptors.response.use(
  (response) => {
    return response.data;
  },
  (error) => {
    // 处理错误响应
    console.error('API请求错误:', error);
    return Promise.reject(error);
  }
);

// API函数
export const whaleTrackingApi = {
  // 获取鲸鱼统计数据
  getWhaleStats: async () => {
    return api.get(API_ENDPOINTS.whaleTracking.stats);
  },
  
  // 获取交易列表
  getTransactions: async (params?: { 
    page?: number; 
    pageSize?: number; 
    whaleType?: string; 
    actionType?: string;
    collection?: string;
  }) => {
    return api.get(API_ENDPOINTS.whaleTracking.transactions, { params });
  },
  
  // 获取收藏集流向数据
  getCollectionFlow: async (params?: {
    timeRange?: string;
    whaleType?: string;
    flowType?: string;
    limit?: number;
  }) => {
    return api.get(API_ENDPOINTS.whaleTracking.collectionFlow, { params });
  },
  
  // 获取鲸鱼交易额分析
  getVolumeAnalysis: async (params?: {
    timeRange?: string;
    limit?: number;
  }) => {
    return api.get(API_ENDPOINTS.whaleTracking.volumeAnalysis, { params });
  },
  
  // 获取鲸鱼收益率分析
  getProfitAnalysis: async (params?: {
    timeRange?: string;
    limit?: number;
  }) => {
    return api.get(API_ENDPOINTS.whaleTracking.profitAnalysis, { params });
  },
  
  // 获取钱包详细信息
  getWalletInfo: async (address: string) => {
    return api.get(API_ENDPOINTS.whaleTracking.wallet(address));
  },
};

export const websocketApi = {
  // 获取WebSocket服务状态
  getStatus: async () => {
    return api.get(API_ENDPOINTS.websocket.status);
  },
  
  // 发送系统通知
  sendNotification: async (message: any) => {
    return api.post(API_ENDPOINTS.websocket.sendNotification, message);
  },
  
  // 发送交易通知
  sendTransactionNotification: async (notification: any) => {
    return api.post(API_ENDPOINTS.websocket.sendTransactionNotification, notification);
  },
  
  // 发送低价机会通知
  sendDealOpportunity: async (opportunity: any) => {
    return api.post(API_ENDPOINTS.websocket.sendDealOpportunity, opportunity);
  },
  
  // 设置交易通知启用状态
  setTransactionNotificationEnabled: async (enabled: boolean) => {
    return api.post(`${API_ENDPOINTS.websocket.setTransactionNotificationEnabled}?enabled=${enabled}`);
  },
  
  // 设置低价机会检测启用状态
  setDealOpportunityEnabled: async (enabled: boolean) => {
    return api.post(`${API_ENDPOINTS.websocket.setDealOpportunityEnabled}?enabled=${enabled}`);
  },
  
  // 手动触发市场扫描
  scanMarketplace: async () => {
    return api.post(API_ENDPOINTS.websocket.scanMarketplace);
  },
};

export default api; 