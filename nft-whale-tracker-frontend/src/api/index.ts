import api, { whaleTrackingApi, websocketApi } from './api';
import websocketService from './websocket';
import { API_BASE_URL, WS_BASE_URL, API_ENDPOINTS, WS_TOPICS } from './config';

// 初始化WebSocket服务
const initWebSocket = () => {
  websocketService.init();
};

export {
  api,
  whaleTrackingApi,
  websocketApi,
  websocketService,
  API_BASE_URL,
  WS_BASE_URL,
  API_ENDPOINTS,
  WS_TOPICS,
  initWebSocket,
}; 