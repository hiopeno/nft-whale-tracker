import { WS_BASE_URL, WS_TOPICS } from './config';
import SockJS from 'sockjs-client';
import { Client, IMessage } from '@stomp/stompjs';

class WebSocketService {
  private client: Client | null = null;
  private connected: boolean = false;
  private subscriptions: { [key: string]: { id: string; callback: (message: any) => void } } = {};
  private reconnectAttempts: number = 0;
  private readonly maxReconnectAttempts: number = 5;
  private reconnectTimeout: number = 3000; // 初始重连间隔3秒
  private reconnectTimer: NodeJS.Timeout | null = null;

  /**
   * 初始化WebSocket客户端
   */
  public init(): void {
    this.client = new Client({
      webSocketFactory: () => new SockJS(WS_BASE_URL),
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000,
      debug: (msg) => {
        if (process.env.NODE_ENV !== 'production') {
          console.log('WebSocket Debug:', msg);
        }
      },
      onConnect: this.onConnect.bind(this),
      onDisconnect: this.onDisconnect.bind(this),
      onStompError: this.onError.bind(this),
    });

    this.connect();
  }

  /**
   * 连接WebSocket服务器
   */
  public connect(): void {
    if (this.client && !this.connected) {
      console.log('连接WebSocket服务器...');
      try {
        this.client.activate();
      } catch (error) {
        console.error('WebSocket连接错误:', error);
        this.handleReconnect();
      }
    }
  }

  /**
   * 处理连接成功事件
   */
  private onConnect(): void {
    console.log('WebSocket连接成功');
    this.connected = true;
    this.reconnectAttempts = 0;
    this.reconnectTimeout = 3000; // 重置重连间隔
    
    // 重新订阅之前的主题
    Object.keys(this.subscriptions).forEach(topic => {
      const { callback } = this.subscriptions[topic];
      this.subscribe(topic, callback);
    });
    
    // 发送连接消息
    this.sendConnectMessage();
  }

  /**
   * 发送连接消息
   */
  private sendConnectMessage(): void {
    const userId = localStorage.getItem('userId') || `user-${Date.now()}`;
    if (this.client && this.connected) {
      this.client.publish({
        destination: '/app/connect',
        body: JSON.stringify({
          content: userId,
          timestamp: new Date().toISOString(),
        }),
      });
    }
  }

  /**
   * 处理连接断开事件
   */
  private onDisconnect(): void {
    console.log('WebSocket连接断开');
    this.connected = false;
    this.handleReconnect();
  }

  /**
   * 处理连接错误事件
   */
  private onError(frame: any): void {
    console.error('WebSocket错误:', frame);
    this.connected = false;
    this.handleReconnect();
  }

  /**
   * 处理重连逻辑
   */
  private handleReconnect(): void {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`尝试重连 (${this.reconnectAttempts}/${this.maxReconnectAttempts})，将在${this.reconnectTimeout / 1000}秒后重试...`);
      
      if (this.reconnectTimer) {
        clearTimeout(this.reconnectTimer);
      }
      
      this.reconnectTimer = setTimeout(() => {
        this.connect();
      }, this.reconnectTimeout);
      
      // 指数退避策略
      this.reconnectTimeout = Math.min(this.reconnectTimeout * 1.5, 30000);
    } else {
      console.error('达到最大重连次数，请手动刷新页面重试');
    }
  }

  /**
   * 订阅指定主题
   * @param topic 主题路径
   * @param callback 消息回调函数
   */
  public subscribe(topic: string, callback: (message: any) => void): void {
    if (!this.client) {
      console.error('WebSocket客户端未初始化');
      return;
    }

    if (this.connected) {
      const subscription = this.client.subscribe(topic, (message: IMessage) => {
        try {
          const payload = JSON.parse(message.body);
          callback(payload);
        } catch (error) {
          console.error('解析WebSocket消息错误:', error);
        }
      });
      
      this.subscriptions[topic] = {
        id: subscription.id,
        callback,
      };
      
      console.log(`已订阅主题: ${topic}`);
    } else {
      // 如果未连接，先保存订阅信息，连接成功后再订阅
      this.subscriptions[topic] = {
        id: '',
        callback,
      };
      console.log(`已保存主题订阅，等待连接: ${topic}`);
    }
  }

  /**
   * 取消订阅指定主题
   * @param topic 主题路径
   */
  public unsubscribe(topic: string): void {
    if (!this.client || !this.subscriptions[topic]) {
      return;
    }

    const subscription = this.subscriptions[topic];
    
    if (this.connected && subscription.id) {
      this.client.unsubscribe(subscription.id);
      console.log(`已取消订阅主题: ${topic}`);
    }
    
    delete this.subscriptions[topic];
  }

  /**
   * 发送消息到指定目标
   * @param destination 目标路径
   * @param body 消息内容
   */
  public sendMessage(destination: string, body: any): void {
    if (!this.client || !this.connected) {
      console.error('WebSocket未连接，无法发送消息');
      return;
    }

    this.client.publish({
      destination,
      body: JSON.stringify(body),
    });
  }

  /**
   * 断开WebSocket连接
   */
  public disconnect(): void {
    if (this.client && this.connected) {
      this.client.deactivate();
      this.connected = false;
      this.subscriptions = {};
      console.log('已断开WebSocket连接');
    }
    
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
  }

  /**
   * 订阅交易通知
   * @param callback 消息回调函数
   */
  public subscribeTransactions(callback: (message: any) => void): void {
    this.subscribe(WS_TOPICS.transactions, callback);
  }

  /**
   * 订阅低价机会
   * @param callback 消息回调函数
   */
  public subscribeDealOpportunities(callback: (message: any) => void): void {
    this.subscribe(WS_TOPICS.dealOpportunities, callback);
  }

  /**
   * 订阅系统通知
   * @param callback 消息回调函数
   */
  public subscribeSystemNotifications(callback: (message: any) => void): void {
    this.subscribe(WS_TOPICS.systemNotifications, callback);
  }

  /**
   * 设置交易订阅参数
   * @param params 订阅参数
   */
  public setTransactionSubscription(params: any): void {
    if (this.client && this.connected) {
      this.sendMessage('/app/subscribe/transactions', params);
    }
  }

  /**
   * 设置低价机会订阅参数
   * @param params 订阅参数
   */
  public setDealOpportunitySubscription(params: any): void {
    if (this.client && this.connected) {
      this.sendMessage('/app/subscribe/deal-opportunities', params);
    }
  }
}

// 创建单例实例
const websocketService = new WebSocketService();

export default websocketService; 