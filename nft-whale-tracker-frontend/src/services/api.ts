import axios from 'axios';

// API基础URL
const API_BASE_URL = 'http://localhost:8080/api';

// WebSocket URL
export const WS_TRANSACTIONS_URL = 'ws://localhost:8080/api/ws/transactions';

// 创建axios实例
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

/**
 * 获取最近NFT交易数据
 * @param limit 限制条数
 */
export const fetchRecentTransactions = async (limit = 20) => {
  try {
    const response = await apiClient.get(`/whale/transactions?limit=${limit}`);
    return response.data;
  } catch (error) {
    console.error('获取交易数据失败:', error);
    throw error;
  }
};

/**
 * 获取鲸鱼钱包数据
 * @param limit 限制条数
 */
export const fetchWhaleWallets = async (limit = 10) => {
  try {
    const response = await apiClient.get(`/whale/wallets?limit=${limit}`);
    return response.data;
  } catch (error) {
    console.error('获取鲸鱼钱包数据失败:', error);
    throw error;
  }
};

/**
 * 获取热门NFT集合
 * @param limit 限制条数
 */
export const fetchHotCollections = async (limit = 10) => {
  try {
    const response = await apiClient.get(`/whale/collections?limit=${limit}`);
    return response.data;
  } catch (error) {
    console.error('获取热门NFT集合失败:', error);
    throw error;
  }
};

/**
 * 执行自定义SQL查询
 * @param sql SQL语句
 */
export const executeCustomQuery = async (sql: string) => {
  try {
    const response = await apiClient.post('/whale/query', sql);
    return response.data;
  } catch (error) {
    console.error('执行自定义查询失败:', error);
    throw error;
  }
};

/**
 * 创建WebSocket连接
 * @returns WebSocket实例
 */
export const createTransactionWebSocket = (): WebSocket => {
  const socket = new WebSocket(WS_TRANSACTIONS_URL);
  
  socket.onopen = () => {
    console.log('WebSocket连接已建立');
  };
  
  socket.onerror = (error) => {
    console.error('WebSocket错误:', error);
  };
  
  socket.onclose = (event) => {
    console.log('WebSocket连接已关闭:', event.code, event.reason);
  };
  
  return socket;
};

export default {
  fetchRecentTransactions,
  fetchWhaleWallets,
  fetchHotCollections,
  executeCustomQuery,
  createTransactionWebSocket,
}; 