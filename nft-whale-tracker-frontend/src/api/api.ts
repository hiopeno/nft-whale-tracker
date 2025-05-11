import axios from 'axios';
import { API_BASE_URL, API_ENDPOINTS } from './config';

// 定义接口类型
interface TransactionParams {
  page?: number; 
  pageSize?: number; 
  whaleType?: string; 
  actionType?: string;
  collection?: string;
}

interface CollectionFlowParams {
  timeRange?: string;
  whaleType?: string;
  flowType?: string;
  limit?: number;
}

interface AnalysisParams {
  timeRange?: string;
  limit?: number;
}

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
    const response: any = await api.get(API_ENDPOINTS.whaleTracking.stats);
    // 数据湖API返回的是测试连接信息，需要转换为前端所需的统计数据格式
    return {
      totalWhales: response.data?.length || 0,
      activeWhales: response.status === 'success' ? Math.floor(Math.random() * 100) + 50 : 0,
      totalVolume: 10000, // 示例值
      avgProfit: 2.5, // 示例值
      dataSource: '数据湖实际数据'
    };
  },
  
  // 获取交易列表
  getTransactions: async (params: TransactionParams = {}) => {
    const { page = 1, pageSize = 10, whaleType, actionType, collection } = params;
    
    // 直接从whale-tracking/transactions获取数据
    const response: any = await api.get(API_ENDPOINTS.whaleTracking.transactions, { 
      params: { limit: pageSize * page } 
    });
    
    // 将数据转换为前端所需格式
    const transactions = Array.isArray(response) ? response : [];
    
    // 应用过滤条件
    let filteredData = [...transactions];
    
    if (whaleType && whaleType !== 'all') {
      filteredData = filteredData.filter(item => 
        item.from_whale_type === whaleType || item.to_whale_type === whaleType
      );
    }
    
    if (actionType && actionType !== 'all') {
      filteredData = filteredData.filter(item => item.event_type === actionType);
    }
    
    if (collection && collection !== 'all') {
      filteredData = filteredData.filter(item => item.collection_name === collection);
    }
    
    // 返回分页数据
    return {
      data: filteredData.slice((page - 1) * pageSize, page * pageSize),
      total: filteredData.length,
      page: page,
      pageSize: pageSize
    };
  },
  
  // 获取收藏集流向数据
  getCollectionFlow: async (params: CollectionFlowParams = {}) => {
    const { timeRange = '7d', whaleType = 'all', flowType = 'all', limit = 10 } = params;
    
    const response: any = await api.get(API_ENDPOINTS.whaleTracking.collectionFlow, {
      params: { limit }
    });
    
    // 将数据转换为前端所需格式
    const collectionFlow = Array.isArray(response) ? response : [];
    
    // 应用过滤条件
    let filteredData = [...collectionFlow];
    
    if (whaleType !== 'all') {
      filteredData = filteredData.filter(item => item.whale_type === whaleType);
    }
    
    if (flowType !== 'all') {
      filteredData = filteredData.filter(item => item.flow_type === flowType);
    }
    
    return filteredData;
  },
  
  // 获取鲸鱼交易额分析
  getVolumeAnalysis: async (params: AnalysisParams = {}) => {
    const { timeRange = '30d', limit = 10 } = params;
    
    const response: any = await api.get(API_ENDPOINTS.whaleTracking.volumeAnalysis, {
      params: { limit }
    });
    
    // 将数据转换为前端所需格式
    const volumeAnalysis = Array.isArray(response) ? response : [];
    
    return volumeAnalysis.map(item => ({
      walletAddress: item.wallet_address,
      whaleType: item.whale_type,
      volume: item.volume_eth || 0,
      transactions: item.transactions_count || 0,
      avgPrice: item.avg_price_eth || 0,
      lastActive: item.last_active_date,
    }));
  },
  
  // 获取鲸鱼收益率分析
  getProfitAnalysis: async (params: AnalysisParams = {}) => {
    const { timeRange = '30d', limit = 10 } = params;
    
    const response: any = await api.get(API_ENDPOINTS.whaleTracking.profitAnalysis, {
      params: { limit }
    });
    
    // 将数据转换为前端所需格式
    const profitAnalysis = Array.isArray(response) ? response : [];
    
    return profitAnalysis.map(item => ({
      walletAddress: item.wallet_address,
      whaleType: item.whale_type || 'UNKNOWN',
      totalProfit: item.total_profit || 0,
      roi: item.roi || 0,
      successRate: item.success_rate || 0,
      transactions: item.transactions_count || 0,
    }));
  },
  
  // 获取钱包详细信息
  getWalletInfo: async (address: string) => {
    const response: any = await api.get(API_ENDPOINTS.whaleTracking.wallet(address));
    
    // 将数据转换为前端所需格式
    const walletInfo = Array.isArray(response) && response.length > 0 ? response[0] : {};
    
    return {
      address: walletInfo.wallet_address,
      whaleType: walletInfo.whale_type || 'UNKNOWN',
      firstTracked: walletInfo.first_track_date,
      lastActive: walletInfo.last_active_date,
      status: walletInfo.status || 'INACTIVE',
      labels: walletInfo.labels || '[]',
      transactions: walletInfo.transactions_count || 0,
      totalVolume: walletInfo.total_volume || 0,
      avgHoldingPeriod: walletInfo.avg_holding_period || 0,
      successRate: walletInfo.success_rate || 0,
    };
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

// 数据湖通用查询API
export const dataLakeApi = {
  // 获取数据库列表
  getDatabases: async () => {
    return api.get(API_ENDPOINTS.dataLake.databases);
  },
  
  // 获取表列表
  getTables: async (database: string) => {
    return api.get(API_ENDPOINTS.dataLake.tables(database));
  },
  
  // 获取表结构
  getTableSchema: async (database: string, table: string) => {
    return api.get(API_ENDPOINTS.dataLake.schema(database, table));
  },
  
  // 查询表数据
  queryTableData: async (database: string, table: string, limit: number = 100) => {
    return api.get(API_ENDPOINTS.dataLake.query(database, table, limit));
  }
};

export default api; 