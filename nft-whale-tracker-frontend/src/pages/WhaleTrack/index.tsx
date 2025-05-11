import React, { useEffect, useState, useRef } from 'react';
import { Card, Row, Col, Statistic, Table, Tag, Typography, Badge, Spin, List, Avatar, Divider, Modal, Space, Button, Radio, Tooltip, Select, message } from 'antd';
import {
  ArrowUpOutlined,
  ArrowDownOutlined,
  UserOutlined,
  SyncOutlined,
  SwapOutlined,
  FireOutlined,
  AreaChartOutlined,
  BarChartOutlined,
  WalletOutlined,
  PieChartOutlined,
  AlertOutlined,
  TransactionOutlined,
  DollarOutlined,
  HistoryOutlined,
  PlusOutlined,
  MinusOutlined,
  CrownOutlined,
  ThunderboltOutlined,
  QuestionOutlined,
  BulbOutlined,
  SmileOutlined,
  StarOutlined,
  StarFilled,
  SwapRightOutlined,
  CaretDownOutlined
} from '@ant-design/icons';
import ReactECharts from 'echarts-for-react';
import * as echarts from 'echarts/core';
import axios from 'axios';
import { API_ENDPOINTS } from '../../api/config';
import { dataLakeApi } from '../../api/api';

const { Title, Text } = Typography;

// 科技风格标题组件
const TechTitle: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <Title
    level={2}
    className="tech-page-title"
  >
    {children}
  </Title>
);

// 数据加载动画组件
const TechLoading: React.FC = () => (
  <div style={{ textAlign: 'center', padding: 20 }}>
    <Spin
      indicator={<SyncOutlined spin style={{ fontSize: 24, color: '#1890ff' }} />}
      tip={<Text style={{ color: 'rgba(255, 255, 255, 0.65)' }}>加载数据中...</Text>}
    />
  </div>
);

// 科技风格标签组件
const TechTag: React.FC<{ level: string }> = ({ level }) => {
  let tagProps = {
    className: 'neutral-tag',
    text: '普通',
    icon: <AlertOutlined />
  };

  if (level === 'HIGH') {
    tagProps = {
      className: 'danger-tag',
      text: '高风险',
      icon: <AlertOutlined />
    };
  } else if (level === 'MEDIUM') {
    tagProps = {
      className: 'warning-tag',
      text: '中等风险',
      icon: <AlertOutlined />
    };
  } else if (level === 'LOW') {
    tagProps = {
      className: 'success-tag',
      text: '低风险',
      icon: <AlertOutlined />
    };
  }

  return (
    <Tag
      className={tagProps.className}
      icon={tagProps.icon}
    >
      {tagProps.text}
    </Tag>
  );
};

// 自定义持仓变化组件
const HoldingChange: React.FC<{ value: number }> = ({ value }) => {
  if (value > 0) {
    return (
      <Statistic
        value={value}
        precision={0}
        prefix={<ArrowUpOutlined />}
        valueStyle={{
          color: 'var(--success)',
          fontSize: 16,
          textShadow: 'var(--text-shadow-success)'
        }}
        suffix="$"
      />
    );
  } else if (value < 0) {
    return (
      <Statistic
        value={Math.abs(value)} // 显示绝对值
        precision={0}
        prefix={<ArrowDownOutlined />}
        valueStyle={{
          color: 'var(--danger)',
          fontSize: 16,
          textShadow: 'var(--text-shadow-danger)'
        }}
        suffix="$"
      />
    );
  } else {
    return (
      <Statistic
        value={0}
        prefix={<SwapOutlined />}
        valueStyle={{
          color: 'var(--neutral)',
          fontSize: 16,
          textShadow: 'var(--text-shadow-subtle)'
        }}
        suffix="$"
      />
    );
  }
};

// LiveTransactionStream组件外部定义常量
const ACTION_TAGS = [
  { value: 'all', label: '全部', color: '#1890ff' },
  { value: 'whale_only', label: '仅鲸鱼', color: '#f5222d' },
  { value: 'normal', label: '非鲸鱼', color: '#a9a9a9' },
  { value: 'accumulate', label: '积累', color: '#52c41a' },
  { value: 'dump', label: '抛售', color: '#f5222d' },
  { value: 'flip', label: '短炒', color: '#faad14' },
  { value: 'explore', label: '探索', color: '#1890ff' },
  { value: 'profit', label: '获利', color: '#722ed1' },
  { value: 'fomo', label: '追高', color: '#eb2f96' },
  { value: 'bargain', label: '抄底', color: '#13c2c2' },
  { value: 'whale_buy', label: '鲸鱼买入', color: '#52c41a' },
  { value: 'whale_sell', label: '鲸鱼卖出', color: '#f5222d' }
] as const;

const TIME_OPTIONS = [
  { value: 'all', label: '全部' },
  { value: '10min', label: '十分钟内' },
  { value: '1hour', label: '一小时内' },
  { value: '4hours', label: '四小时内' },
  { value: '12hours', label: '十二小时内' }
] as const;

// 函数：将ads_whale_transactions数据转换为前端所需的交易数据格式
const transformWhaleTransactions = (rawData: any[]): any[] => {
  if (!rawData || !Array.isArray(rawData) || rawData.length === 0) {
    return [];
  }
  
  return rawData.map((item, index) => {
    // 确定鲸鱼类型和方向
    const fromIsWhale = item.from_whale_type !== 'NO_WHALE';
    const toIsWhale = item.to_whale_type !== 'NO_WHALE';
    const isWhale = fromIsWhale || toIsWhale;
    
    // 判断交易行为类型
    let actionType = 'explore';
    if (fromIsWhale && toIsWhale) {
      actionType = 'flip'; // 鲸鱼之间交易
    } else if (toIsWhale && !fromIsWhale) {
      actionType = 'accumulate'; // 鲸鱼买入
    } else if (fromIsWhale && !toIsWhale) {
      actionType = 'dump'; // 鲸鱼卖出
    }
    
    // 计算交易时间文本
    const txTime = new Date(item.tx_timestamp);
    const now = new Date();
    const diffMs = now.getTime() - txTime.getTime();
    const diffMins = Math.floor(diffMs / (1000 * 60));
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    
    let timeText = '';
    if (diffMins < 1) {
      timeText = '刚刚';
    } else if (diffMins < 60) {
      timeText = `${diffMins}分钟前`;
    } else {
      timeText = `${diffHours}小时${diffMins % 60 > 0 ? diffMins % 60 + '分钟' : ''}前`;
    }
    
    // NFT名称格式化
    const tokenIdNum = parseInt(item.token_id);
    const nftName = `${item.collection_name || 'Unknown'} #${!isNaN(tokenIdNum) ? tokenIdNum : item.token_id}`;
    
    // 地址格式化
    const formatAddr = (addr: string) => {
      if (!addr || addr.length < 10) return addr;
      return `${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}`;
    };
    
    // 鲸鱼地址
    const whaleAddress = toIsWhale ? item.to_address : (fromIsWhale ? item.from_address : '');
    
    // 价格变化计算 (如果有地板价，就计算与地板价的关系)
    const priceChange = item.floor_price_eth && item.floor_price_eth > 0 
      ? ((item.trade_price_eth / item.floor_price_eth - 1) * 100)
      : 0;
    
    return {
      id: `${item.tx_hash}-${index}`,
      time: timeText,
      nftName: nftName,
      collection: item.collection_name || 'Unknown',
      seller: formatAddr(item.from_address),
      buyer: formatAddr(item.to_address),
      price: Number(item.trade_price_eth) || 0,
      priceChange: Number(priceChange.toFixed(1)),
      rarityRank: Math.floor(Math.random() * 1000) + 1, // 模拟稀有度排名
      whaleInfluence: toIsWhale ? Number(item.to_influence_score) : (fromIsWhale ? Number(item.from_influence_score) : 0),
      actionType: actionType,
      isWhale: isWhale,
      whaleIsBuyer: toIsWhale,
      whaleSeller: fromIsWhale,
      whaleAddress: whaleAddress,
      marketplace: item.marketplace,
      logoUrl: item.logo_url, // 保留logo_url字段
      // 保留原始数据以便需要时使用
      rawData: item
    };
  });
};

// 实时交易流组件
const LiveTransactionStream: React.FC = () => {
  const [transactions, setTransactions] = useState<any[]>([]);
  const [isNewItem, setIsNewItem] = useState<boolean>(false);
  const [trackedWhales, setTrackedWhales] = useState<string[]>([]);
  const listRef = useRef<HTMLDivElement>(null);
  const [walletModalVisible, setWalletModalVisible] = useState(false);
  const [selectedWalletAddress, setSelectedWalletAddress] = useState('');
  const [selectedWalletLabel, setSelectedWalletLabel] = useState('');
  const [hoveredItem, setHoveredItem] = useState<number | null>(null);
  const [tagFilter, setTagFilter] = useState<string>('whale_only'); // 默认设置为只显示鲸鱼交易
  const [timeFilter, setTimeFilter] = useState<string>('all');
  const [loading, setLoading] = useState<boolean>(false);
  const [lastUpdateTime, setLastUpdateTime] = useState<Date | null>(null);

  // 获取实际交易数据
  const fetchTransactions = async () => {
    try {
      setLoading(true);
      // 从数据湖获取ads_whale_transactions表数据，限制数量为200条
      const response: any = await dataLakeApi.queryTableData('ads', 'ads_whale_transactions', 200);
      
      if (Array.isArray(response) && response.length > 0) {
        console.log('获取到的原始交易数据:', response.length, '条');
        
        // 排序数据，确保最新的交易在前面
        const sortedData = [...response].sort((a, b) => {
          const dateA = new Date(a.tx_timestamp);
          const dateB = new Date(b.tx_timestamp);
          return dateB.getTime() - dateA.getTime();
        });
        
        // 转换数据格式
        const transformedData = transformWhaleTransactions(sortedData);
        
        // 更新状态
        setTransactions(transformedData);
        setLastUpdateTime(new Date());
      } else {
        console.warn('没有获取到交易数据或数据格式不正确');
      }
    } catch (error) {
      console.error('获取交易数据失败:', error);
    } finally {
      setLoading(false);
    }
  };

  // 初始化交易数据和追踪的鲸鱼地址
  useEffect(() => {
    // 获取实际数据
    fetchTransactions();
    
    // 初始化一些被追踪的鲸鱼地址 (这部分可以保留，或者从后端获取)
    setTrackedWhales(['0x5678...1234', '0x1234...5678']);
    
    // 设置定时刷新
    const refreshInterval = setInterval(() => {
      fetchTransactions();
    }, 60000); // 每分钟刷新一次数据
    
    return () => {
      clearInterval(refreshInterval);
    };
  }, []);

  // 新交易出现时滚动到顶部
  useEffect(() => {
    if (isNewItem && listRef.current) {
      listRef.current.scrollTop = 0;
    }
  }, [isNewItem]);

  // 修改获取NFT图片的逻辑，优先使用API返回的logo_url
  const getNftImage = (collection: string, logoUrl?: string) => {
    // 优先使用API返回的logo_url
    if (logoUrl && (logoUrl.startsWith('http') || logoUrl.startsWith('https'))) {
      console.log(`使用API返回的logo_url: ${logoUrl} 用于收藏集 ${collection}`);
      return logoUrl;
    }
    
    // 直接处理HOPE收藏集（如果没有logo_url）
    if (collection.toLowerCase() === 'hope') {
      return 'https://i.seadn.io/gcs/files/2d058acad86d29a218bd1fba24e9eb28.png?auto=format&dpr=1&w=256';
    }
    
    // 标准化集合名称（转为小写并移除空格）以便更好地匹配
    const normalizedCollection = collection.toLowerCase().replace(/\s+/g, '');
    
    const collections: { [key: string]: string } = {
      'bayc': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256',
      'azuki': 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256',
      'cryptopunks': 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?auto=format&dpr=1&w=256',
      'doodles': 'https://i.seadn.io/gae/7B0qai02OdHA8P_EOVK672qUliyjQdQDGNrACxs7WnTgZAkJa_wWURnIFKeOh5VTf8cfTqW3wQpozGEJpJpJnv_DqHDFWxcQplRFyw?auto=format&dpr=1&w=256',
      'clonex': 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?auto=format&dpr=1&w=256',
      'mayc': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=256',
      'moonbirds': 'https://i.seadn.io/gae/H-eyNE1MwL5ohL-tCfn_Xa1Sl9M9B4612tLYeUlQubzt4ewhr4huJIR5OLuyO3Z5PpJFSwdm7rq-TikAh7f5eUw338A2cy6HRH75?auto=format&dpr=1&w=256',
      'pudgypenguins': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=256',
      'otherdeeds': 'https://i.seadn.io/gae/yIm-M5-BpSDdTEIJRt5D6xphizhIdozXjqSITgK4phWq7MmAU3qE7Nw7POGCiPGyhtJ3ZFP8iJ29TFl-RLcGBWX5qI4-ZcnCPcsY4zI?auto=format&dpr=1&w=256',
      'wow': 'https://i.seadn.io/gae/EFAQpIktMraCrs8YLJy_FgjN9jOJW-O6cAZr9eriPZdkKvhJWEdre9wZOxTZL84HJN0GZxwNJXVPOZ8OQfYxgUMnR2JmrpdtWRK1?auto=format&dpr=1&w=256',
      'cyberkongz': 'https://i.seadn.io/gae/LIpf9z6Ux8uxn69auBME9FCTXpXqSYFo8ZLO1GaM8T7S3hiKScHaClXe0ZdhTv5br6FE2g5i-J5SobhKFsYfe6CIMCv-UfnrlYFWOM4?auto=format&dpr=1&w=256',
      'coolcats': 'https://i.seadn.io/gae/LIov33kogXOK4XZd2ESj29sqm_Hww5JSdO7AFn5wjt8xgnJJ0UpNV9yITqxra3s_LMEW1AnnrgOVB_hDpjJRA1uF4skI5Sdi_9rULi8?auto=format&dpr=1&w=256',
      'meebits': 'https://i.seadn.io/gae/d784iHHbqQFVH1XYD6HoT4u3y_Fsu_9FZUltWjnOzoYv7qqB5dLUqpOJ16kTQAGr-NORVYHOwzOqRkigvUrYoBCYAAltp8Zf-ZV3?auto=format&dpr=1&w=256',
      'cryptoadz': 'https://i.seadn.io/gae/iofetZEyiEIGcNyJKpbOafb_efJyeo7QOYnTog8qcQJhqoBU-Vu7mnijXM7SouWRtHKCuLIC9XDcGILXfyg0bnBZ6IPrWMA5VaCgygE?auto=format&dpr=1&w=256',
      'goblintown': 'https://i.seadn.io/gae/cb_wdEAmvry_noTCq1EDPD3eF04Wg3YxHPzGW9QjIjX9-hU-Q5y_rLpbEWhnmcSuYWRiV7bjZ6T41w8tgMqjEIHFWzG_AQT-qm1KnKU?auto=format&dpr=1&w=256',
      'degods': 'https://i.seadn.io/gae/FVTsD1oMUJHZiBkMibDgXimXQnJzYM9XxoMxTMR-JzHIQW-FGb0jlDfNTRbGZQBgQMKy6oVYDiCDfGTcSUAWatIKcGy4LMrAYnYl?auto=format&dpr=1&w=256',
      'milady': 'https://i.seadn.io/gae/a_frplnavZA9g4vN3SexO5rrtaBX_cBTaJYcgrPtwQIqPhzgzUendQxiwUdr51CGPE2QyPEa1DHnkW1wLrHAv5DgfC3BP-CRqDIVfGo?auto=format&dpr=1&w=256',
      'boredapeyachtclub': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256',
      'mutantapeyachtclub': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=256',
      'fidenza': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=256',
      'chromiesquiggle': 'https://i.seadn.io/gae/0qG8Y78s198F2R0xTOhje0UeK7GWpgKdLTdL2NF8e_siutxvxE5wNKoH_5XgLvCcB-jOq6hbidLuFAr2rzQBQkYNwu6_tUJhGnyom4I?auto=format&dpr=1&w=256',
      'autoglyphs': 'https://i.seadn.io/gae/JYz5dU8xK0FCzFp4NiOGkZGzVB77JQ2PMz9tMr7N2em9mvg8BpWHReqQOOK8RXwEMJbUqSY3ZFZyQB3c0jZ-lBb-MaijEOYc9bvzMA?auto=format&dpr=1&w=256',
      'nouns': 'https://i.seadn.io/gae/dQQcSXxzJJBw2FXB-aZFh-jAXrGWss2RfZxDY4Ykr8uqJT8-cY1FJR9cq9qMXmUtKK9GBEEzZ7kTXKd_iBDxT3lw1XwWT-wB3FveqA?auto=format&dpr=1&w=256',
      'loot': 'https://i.seadn.io/gae/Nhz0VbI2GV_PfS_9LDpwJzpH6xxbx0Mxoz2WwXNxmiifeI-JxgJZXD5IutgNTYZEYc3mB73MTJKc7G_9Hbv5ArjnWqpZ6-1wBYx0IQ?auto=format&dpr=1&w=256',
      'hope': 'https://i.seadn.io/gcs/files/2d058acad86d29a218bd1fba24e9eb28.png?auto=format&dpr=1&w=256'
    };

    // 处理特殊情况
    if (normalizedCollection.includes('bored') && normalizedCollection.includes('ape')) return collections['bayc'];
    if (normalizedCollection.includes('mutant') && normalizedCollection.includes('ape')) return collections['mayc'];
    if (normalizedCollection.includes('cool') && normalizedCollection.includes('cat')) return collections['coolcats'];
    if (normalizedCollection.includes('cyber') && normalizedCollection.includes('kong')) return collections['cyberkongz'];
    if (normalizedCollection.includes('pudgy')) return collections['pudgypenguins'];
    if (normalizedCollection.includes('cryptopunk')) return collections['cryptopunks'];
    
    // 检查集合名称是否存在，不区分大小写
    for (const [key, url] of Object.entries(collections)) {
      if (normalizedCollection.includes(key.toLowerCase())) {
        return url;
      }
    }

    // 检查是否有匹配的图标，如果没有，尝试模糊匹配
    if (collections[normalizedCollection]) {
      return collections[normalizedCollection];
    }
    
    // 尝试部分匹配
    for (const [key, url] of Object.entries(collections)) {
      if (normalizedCollection.includes(key) || key.includes(normalizedCollection)) {
        return url;
      }
    }

    // 如果找不到匹配的图标，使用默认图标
    const defaultLogo = 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256';
    console.log(`未找到"${collection}"的图标，使用默认图标`);
    return defaultLogo;
  };

  // 处理追踪/取消追踪鲸鱼
  const toggleTracking = (whaleAddress: string) => {
    // 检查是否已经追踪该鲸鱼
    const isTracked = trackedWhales.includes(whaleAddress);
    
    // 更新前端追踪状态
    setTrackedWhales(prev => {
      if (isTracked) {
        return prev.filter(addr => addr !== whaleAddress);
      } else {
        return [...prev, whaleAddress];
      }
    });
    
    // 如果是新追踪的鲸鱼，尝试将其添加到重点追踪鲸鱼列表
    if (!isTracked) {
      try {
        // 查找此鲸鱼在交易中的信息
        const whaleTransaction = transactions.find(tx => 
          (tx.whaleIsBuyer && tx.buyer === whaleAddress) || 
          (tx.whaleSeller && tx.seller === whaleAddress));
        
        console.log(`尝试将鲸鱼地址 ${whaleAddress} 添加到重点追踪鲸鱼列表...`);
        
        // 异步获取鲸鱼的完整数据
        const fetchWhaleDetails = async () => {
          try {
            // 从数据湖API获取鲸鱼详细信息（首先尝试ads_whale_tracking_list表）
            const response: any = await dataLakeApi.queryTableData('ads', 'ads_whale_tracking_list', 1000);
            
            if (Array.isArray(response) && response.length > 0) {
              // 查找匹配的鲸鱼详细数据
              const whaleDetail = response.find(item => item.wallet_address === whaleAddress);
              
              if (whaleDetail) {
                console.log('在ads_whale_tracking_list表中找到鲸鱼详细数据:', whaleDetail);
                
                // 构造完整的鲸鱼数据对象
                const whaleData = {
                  whaleId: `WHALE-${whaleDetail.tracking_id || whaleDetail.wallet_address.substring(0, 8)}`,
                  whaleAddress: whaleDetail.wallet_address,
                  trackingTime: whaleDetail.first_track_date ? new Date(whaleDetail.first_track_date).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
                  influence: whaleDetail.influence_score || 0,
                  trackingProfit: Number(whaleDetail.total_profit_usd) || 0,
                  trackingProfitRate: Number(whaleDetail.roi_percentage) || 0,
                  walletType: whaleDetail.wallet_type || 'TRACKING',
                  rawData: whaleDetail
                };
                
                // 发送包含完整鲸鱼数据的事件
                const event = new CustomEvent('whaleTracked', {
                  detail: {
                    action: 'add',
                    address: whaleAddress,
                    whaleData: whaleData
                  }
                });
                window.dispatchEvent(event);
                
                // 显示成功消息
                message.success(`成功将鲸鱼 ${formatAddress(whaleAddress)} 添加到重点追踪列表！`);
                return;
              }
            }
            
            // 如果在ads_whale_tracking_list表中未找到鲸鱼数据，尝试从ads_top_profit_whales表获取
            console.log('在ads_whale_tracking_list表中未找到鲸鱼数据，尝试从ads_top_profit_whales表获取...');
            const profitWhalesResponse: any = await dataLakeApi.queryTableData('ads', 'ads_top_profit_whales', 1000);
            
            if (Array.isArray(profitWhalesResponse) && profitWhalesResponse.length > 0) {
              const profitWhaleDetail = profitWhalesResponse.find(item => item.wallet_address === whaleAddress);
              
              if (profitWhaleDetail) {
                console.log('在ads_top_profit_whales表中找到鲸鱼详细数据:', profitWhaleDetail);
                
                // 构造完整的鲸鱼数据对象，从ads_top_profit_whales表提取更多详细信息
                const whaleData = {
                  whaleId: `WHALE-${profitWhaleDetail.wallet_address.substring(0, 8)}`,
                  whaleAddress: profitWhaleDetail.wallet_address,
                  trackingTime: profitWhaleDetail.first_seen_date || new Date().toISOString().split('T')[0],
                  influence: profitWhaleDetail.influence_score || 50,
                  trackingProfit: Number(profitWhaleDetail.total_profit_eth) * 2000 || 0, // 假设ETH价格为2000美元
                  trackingProfitRate: Number(profitWhaleDetail.roi_percentage) || 0,
                  walletType: profitWhaleDetail.wallet_type || 'TRACKING',
                  rawData: profitWhaleDetail
                };
                
                // 发送包含完整鲸鱼数据的事件
                const event = new CustomEvent('whaleTracked', {
                  detail: {
                    action: 'add',
                    address: whaleAddress,
                    whaleData: whaleData
                  }
                });
                window.dispatchEvent(event);
                
                // 显示成功消息
                message.success(`成功将鲸鱼 ${formatAddress(whaleAddress)} 添加到重点追踪列表！`);
                return;
              }
            }
            
            // 如果在ads_top_profit_whales表中也未找到，尝试从ads_top_roi_whales表获取
            console.log('在ads_top_profit_whales表中未找到鲸鱼数据，尝试从ads_top_roi_whales表获取...');
            const roiWhalesResponse: any = await dataLakeApi.queryTableData('ads', 'ads_top_roi_whales', 1000);
            
            if (Array.isArray(roiWhalesResponse) && roiWhalesResponse.length > 0) {
              const roiWhaleDetail = roiWhalesResponse.find(item => item.wallet_address === whaleAddress);
              
              if (roiWhaleDetail) {
                console.log('在ads_top_roi_whales表中找到鲸鱼详细数据:', roiWhaleDetail);
                
                // 构造完整的鲸鱼数据对象，从ads_top_roi_whales表提取更多详细信息
                const whaleData = {
                  whaleId: `WHALE-${roiWhaleDetail.wallet_address.substring(0, 8)}`,
                  whaleAddress: roiWhaleDetail.wallet_address,
                  trackingTime: roiWhaleDetail.first_seen_date || new Date().toISOString().split('T')[0],
                  influence: roiWhaleDetail.influence_score || 50,
                  trackingProfit: Number(roiWhaleDetail.total_profit_eth) * 2000 || 0, // 假设ETH价格为2000美元
                  trackingProfitRate: Number(roiWhaleDetail.roi_percentage) || 0,
                  walletType: 'SMART', // 假设在roi表中的都是聪明鲸鱼
                  rawData: roiWhaleDetail
                };
                
                // 发送包含完整鲸鱼数据的事件
                const event = new CustomEvent('whaleTracked', {
                  detail: {
                    action: 'add',
                    address: whaleAddress,
                    whaleData: whaleData
                  }
                });
                window.dispatchEvent(event);
                
                // 显示成功消息
                message.success(`成功将鲸鱼 ${formatAddress(whaleAddress)} 添加到重点追踪列表！`);
                return;
              }
            }
            
            // 如果在所有表中都未找到鲸鱼数据，使用交易数据构建基本信息
            console.log('在所有数据表中未找到鲸鱼详细数据，使用交易数据创建基本记录');
            
            // 从当前交易中提取信息创建基本的鲸鱼数据
            const basicWhaleData = {
              whaleId: `WHALE-${whaleAddress.substring(0, 8)}`,
              whaleAddress: whaleAddress,
              trackingTime: new Date().toISOString().split('T')[0],
              influence: whaleTransaction?.whaleInfluence || 50,
              trackingProfit: 0,
              trackingProfitRate: 0,
              walletType: 'TRACKING',
              // 添加一些从当前交易中可以获取的信息
              lastTransactionTime: new Date().toISOString(),
              lastTransactionType: whaleTransaction?.whaleIsBuyer ? 'BUY' : 'SELL',
              lastTransactionCollection: whaleTransaction?.collection || '',
              lastTransactionPrice: whaleTransaction?.price || 0
            };
            
            // 发送包含基本鲸鱼数据的事件
            const event = new CustomEvent('whaleTracked', {
              detail: {
                action: 'add',
                address: whaleAddress,
                whaleData: basicWhaleData
              }
            });
            window.dispatchEvent(event);
            
            // 显示成功消息
            message.success(`成功将鲸鱼 ${formatAddress(whaleAddress)} 添加到重点追踪列表！`);
          } catch (error) {
            console.error('获取鲸鱼详细数据失败:', error);
            
            // 发送只包含地址的基本事件
            const fallbackEvent = new CustomEvent('whaleTracked', {
              detail: {
                action: 'add',
                address: whaleAddress,
                whaleData: {
                  whaleId: `WHALE-${whaleAddress.substring(0, 8)}`,
                  whaleAddress: whaleAddress,
                  trackingTime: new Date().toISOString().split('T')[0],
                  influence: 50,
                  trackingProfit: 0,
                  trackingProfitRate: 0,
                  walletType: 'TRACKING'
                }
              }
            });
            window.dispatchEvent(fallbackEvent);
            
            // 显示成功消息（尽管获取详细数据失败）
            message.success(`已将鲸鱼 ${formatAddress(whaleAddress)} 添加到重点追踪列表，但无法获取详细数据`);
          }
        };
        
        // 执行异步获取
        fetchWhaleDetails();
        
      } catch (error) {
        console.error('添加鲸鱼到追踪列表失败:', error);
        message.error(`添加鲸鱼 ${formatAddress(whaleAddress)} 到追踪列表失败`);
      }
    } else {
      // 如果是取消追踪
      console.log(`取消追踪鲸鱼地址 ${whaleAddress}`);
      message.info(`已取消追踪鲸鱼 ${formatAddress(whaleAddress)}`);
      
      // 发送取消追踪事件
      const event = new CustomEvent('whaleTracked', {
        detail: {
          action: 'remove',
          address: whaleAddress
        }
      });
      window.dispatchEvent(event);
    }
  };

  // 判断一个鲸鱼是否被追踪
  const isWhaleTracked = (whaleAddress: string) => {
    return trackedWhales.includes(whaleAddress);
  };

  // 渲染交易方向标签
  const renderWhaleTag = (item: any) => {
    if (!item.isWhale) return null;

    if (item.whaleIsBuyer) {
      return (
        <Tag color="#52c41a" style={{ marginLeft: 8 }}>鲸鱼买入</Tag>
      );
    } else if (item.whaleSeller) {
      return (
        <Tag color="#f5222d" style={{ marginLeft: 8 }}>鲸鱼卖出</Tag>
      );
    }

    return null;
  };

  // 格式化地址显示，保留前6位和后4位
  const formatAddress = (address: string) => {
    if (!address || address.length < 12) return address;
    return `${address.substring(0, 6)}...${address.substring(address.length - 4)}`;
  };

  // 高亮鲸鱼地址
  const renderAddress = (address: string, isWhale: boolean, isBuyer: boolean, isSeller: boolean, item: any) => {
    if (!isWhale) return formatAddress(address);

    if ((isBuyer && address === item.buyer) || (isSeller && address === item.seller)) {
      return (
        <Text style={{ color: '#f5222d', fontWeight: 'bold' }}>{formatAddress(address)}</Text>
      );
    }

    return formatAddress(address);
  };

  // 新增函数：获取交易行为标签
  const getActionTypeTag = (actionType: string) => {
    const actionTypes: { [key: string]: { color: string, text: string } } = {
      'accumulate': { color: '#52c41a', text: '积累' },
      'dump': { color: '#f5222d', text: '抛售' },
      'flip': { color: '#faad14', text: '短炒' },
      'explore': { color: '#1890ff', text: '探索' },
      'profit': { color: '#722ed1', text: '获利' },
      'fomo': { color: '#eb2f96', text: '追高' },
      'bargain': { color: '#13c2c2', text: '抄底' }
    };

    const defaultType = { color: '#1890ff', text: '交易' };
    return actionTypes[actionType] || defaultType;
  };

  // 新增函数：渲染价格变化
  const renderPriceChange = (change: number) => {
    if (change > 0) {
      return (
        <Text style={{ color: '#52c41a', fontSize: 12 }}>
          <ArrowUpOutlined /> +{change.toFixed(1)}%
        </Text>
      );
    } else if (change < 0) {
      return (
        <Text style={{ color: '#f5222d', fontSize: 12 }}>
          <ArrowDownOutlined /> {change.toFixed(1)}%
        </Text>
      );
    } else {
      return (
        <Text style={{ color: '#d9d9d9', fontSize: 12 }}>
          <SwapOutlined /> 0%
        </Text>
      );
    }
  };

  // 新增函数：渲染鲸鱼影响力得分
  const renderInfluenceScore = (score: number) => {
    let color = '#1890ff';
    if (score >= 90) color = '#f5222d';
    else if (score >= 70) color = '#faad14';
    else if (score >= 50) color = '#52c41a';

    return (
      <div style={{ display: 'flex', alignItems: 'center' }}>
        <div style={{
          width: 35,
          height: 35,
          borderRadius: '50%',
          background: `conic-gradient(${color} ${score}%, transparent 0)`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          position: 'relative',
          border: `1px solid ${color}`
        }}>
          <div style={{
            width: 27,
            height: 27,
            borderRadius: '50%',
            background: '#001529',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 12,
            color
          }}>
            {score}
          </div>
        </div>
      </div>
    );
  };

  // 处理鲸鱼地址点击
  const handleWhaleAddressClick = (address: string, isWhale: boolean, label: string = '鲸鱼钱包') => {
    if (isWhale) {
      setSelectedWalletAddress(address);
      setSelectedWalletLabel(label);
      setWalletModalVisible(true);
    }
    // 普通地址不做任何处理
  };

  // 筛选交易数据
  const getFilteredTransactions = () => {
    let filtered = [...transactions];

    // 标签筛选
    if (tagFilter !== 'all') {
      filtered = filtered.filter(item => {
        if (tagFilter === 'whale_only') return item.isWhale; // 只显示鲸鱼交易
        if (tagFilter === 'normal') return !item.isWhale; // 只显示非鲸鱼交易
        if (tagFilter === 'whale_buy') return item.whaleIsBuyer;
        if (tagFilter === 'whale_sell') return item.whaleSeller;
        return item.actionType === tagFilter;
      });
    }

    // 时间筛选
    if (timeFilter !== 'all') {
      const now = new Date().getTime();
      const timeMap: { [key: string]: number } = {
        '10min': 10 * 60 * 1000,
        '1hour': 60 * 60 * 1000,
        '4hours': 4 * 60 * 60 * 1000,
        '12hours': 12 * 60 * 60 * 1000
      };

      filtered = filtered.filter(item => {
        // 将时间文本转换为相对时间（毫秒）
        const getTimeInMs = (timeText: string) => {
          if (timeText === '刚刚') return 0;
          const match = timeText.match(/(\d+)(.+)前/);
          if (!match) return 0;
          const [_, num, unit] = match;
          const unitMap: { [key: string]: number } = {
            '分钟': 60 * 1000,
            '小时': 60 * 60 * 1000
          };
          return Number(num) * (unitMap[unit] || 0);
        };

        const itemTime = getTimeInMs(item.time);
        return itemTime <= timeMap[timeFilter];
      });
    }

    // 限制返回数量为50条，提高渲染性能
    return filtered.slice(0, 50);
  };

  return (
    <Card
      title={
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <FireOutlined style={{ color: '#f5222d', marginRight: 8 }} />
            <Text style={{
              color: 'rgba(255, 255, 255, 0.85)',
              fontSize: 16,
              fontWeight: 500
            }}>
              实时鲸鱼交易流
            </Text>
            <Badge
              count={transactions.length}
              style={{
                backgroundColor: '#1890ff',
                marginLeft: 12,
                boxShadow: '0 0 8px rgba(24, 144, 255, 0.4)'
              }}
            />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <Select
              value={tagFilter}
              onChange={setTagFilter}
              style={{ width: 120 }}
              dropdownStyle={{ background: '#001529' }}
              placeholder="交易类型"
              bordered={false}
              suffixIcon={<CaretDownOutlined style={{ color: 'rgba(255, 255, 255, 0.45)' }} />}
            >
              {ACTION_TAGS.map(tag => (
                <Select.Option
                  key={tag.value}
                  value={tag.value}
                >
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    color: tag.value === 'all' ? 'rgba(255, 255, 255, 0.85)' : tag.color
                  }}>
                    {tag.value !== 'all' && <div style={{
                      width: 6,
                      height: 6,
                      borderRadius: '50%',
                      backgroundColor: tag.color,
                      marginRight: 6
                    }} />}
                    {tag.label}
                  </div>
                </Select.Option>
              ))}
            </Select>
            <Select
              value={timeFilter}
              onChange={setTimeFilter}
              style={{ width: 120 }}
              dropdownStyle={{ background: '#001529' }}
              placeholder="时间范围"
              bordered={false}
              suffixIcon={<CaretDownOutlined style={{ color: 'rgba(255, 255, 255, 0.45)' }} />}
            >
              {TIME_OPTIONS.map(option => (
                <Select.Option
                  key={option.value}
                  value={option.value}
                >
                  <Text style={{
                    color: option.value === 'all' ? 'rgba(255, 255, 255, 0.85)' : '#1890ff'
                  }}>
                    {option.label}
                  </Text>
                </Select.Option>
              ))}
            </Select>
          </div>
        </div>
      }
      className="tech-card"
      bordered={false}
      bodyStyle={{ padding: 0, maxHeight: '724px', overflow: 'auto' }}
      ref={listRef}
      style={{ height: '100%' }}
    >
      <List
        itemLayout="horizontal"
        dataSource={getFilteredTransactions()}
        renderItem={(item, index) => {
          const actionType = getActionTypeTag(item.actionType || 'explore');
          return (
            <List.Item
              className={index === 0 && isNewItem ? 'new-transaction-animation' : ''}
              style={{
                padding: '16px 24px',
                borderBottom: '1px solid rgba(24, 144, 255, 0.1)',
                background: hoveredItem === index
                  ? 'rgba(24, 144, 255, 0.25)'
                  : (index === 0 && isNewItem
                    ? 'rgba(24, 144, 255, 0.15)'
                    : 'rgba(245, 34, 45, 0.05)'),
                transition: 'all 0.3s ease',
                cursor: 'pointer'
              }}
              onMouseEnter={() => setHoveredItem(index)}
              onMouseLeave={() => setHoveredItem(null)}
              onDoubleClick={() => {
                // 双击整行时触发追踪功能
                if (item.whaleIsBuyer) {
                  toggleTracking(item.buyer);
                } else if (item.whaleSeller) {
                  toggleTracking(item.seller);
                }
              }}
            >
              <div style={{ display: 'flex', width: '100%' }}>
                {/* 左侧：NFT图片和鲸鱼影响力 */}
                <div style={{ marginRight: 16, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                  <Avatar
                    src={getNftImage(item.collection, item.logoUrl)}
                    size={60}
                    style={{
                      border: item.isWhale ? '2px solid #f5222d' : '1px solid rgba(24, 144, 255, 0.3)',
                      boxShadow: item.isWhale ? '0 0 10px rgba(245, 34, 45, 0.5)' : 'none',
                      marginBottom: 8
                    }}
                  />
                  {/* 删除影响力分数标签 */}
                </div>

                {/* 中间：交易详情 */}
                <div style={{ flex: 1 }}>
                  {/* 第一行：NFT名称、标签、时间 */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                    <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap' }}>
                      <Text style={{ color: '#1890ff', fontWeight: 'bold', fontSize: 16 }}>{item.nftName}</Text>
                      <Tag color={actionType.color} style={{ marginLeft: 8 }}>{actionType.text}</Tag>
                      {renderWhaleTag(item)}
                    </div>
                    <Text style={{ color: 'rgba(255, 255, 255, 0.45)', fontSize: 12 }}>{item.time}</Text>
                  </div>

                  {/* 第二行：收藏集 */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                    <div>
                      <Text style={{ color: 'rgba(255, 255, 255, 0.65)', fontSize: 13 }}>
                        收藏集: {item.collection}
                      </Text>
                    </div>
                    <div>
                      {/* 可以根据需要在这里添加其他信息 */}
                    </div>
                  </div>

                  {/* 第三行：交易双方 */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      background: 'rgba(0, 0, 0, 0.15)',
                      padding: '4px 8px',
                      borderRadius: '4px',
                      boxShadow: '0 1px 2px rgba(0,0,0,0.1)'
                    }}>
                      <Tooltip title={`卖家地址: ${item.seller}`}>
                        <div
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            cursor: item.whaleSeller ? 'pointer' : 'default',
                            padding: '2px 6px',
                            borderRadius: '4px',
                            background: item.whaleSeller ? 'rgba(245, 34, 45, 0.15)' : 'transparent',
                            border: item.whaleSeller ? '1px solid rgba(245, 34, 45, 0.3)' : 'none'
                          }}
                          onClick={() => handleWhaleAddressClick(item.seller, item.whaleSeller)}
                        >
                          <UserOutlined style={{
                            marginRight: 4,
                            color: item.whaleSeller ? '#f5222d' : 'rgba(255, 255, 255, 0.45)'
                          }} />
                          {item.whaleSeller ?
                            <Text style={{ color: '#f5222d', fontWeight: 'bold' }}>{formatAddress(item.seller)}</Text> :
                            <Text style={{ color: 'rgba(255, 255, 255, 0.65)' }}>{formatAddress(item.seller)}</Text>
                          }
                        </div>
                      </Tooltip>

                      <SwapRightOutlined style={{
                        margin: '0 8px',
                        color: 'rgba(255, 255, 255, 0.45)',
                        fontSize: 16
                      }} />

                      <Tooltip title={`买家地址: ${item.buyer}`}>
                        <div
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            cursor: item.whaleIsBuyer ? 'pointer' : 'default',
                            padding: '2px 6px',
                            borderRadius: '4px',
                            background: item.whaleIsBuyer ? 'rgba(245, 34, 45, 0.15)' : 'transparent',
                            border: item.whaleIsBuyer ? '1px solid rgba(245, 34, 45, 0.3)' : 'none'
                          }}
                          onClick={() => handleWhaleAddressClick(item.buyer, item.whaleIsBuyer)}
                        >
                          <UserOutlined style={{
                            marginRight: 4,
                            color: item.whaleIsBuyer ? '#f5222d' : 'rgba(255, 255, 255, 0.45)'
                          }} />
                          {item.whaleIsBuyer ?
                            <Text style={{ color: '#f5222d', fontWeight: 'bold' }}>{formatAddress(item.buyer)}</Text> :
                            <Text style={{ color: 'rgba(255, 255, 255, 0.65)' }}>{formatAddress(item.buyer)}</Text>
                          }
                        </div>
                      </Tooltip>
                    </div>
                  </div>

                </div>

                {/* 右侧：价格和收藏 */}
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', justifyContent: 'center', marginLeft: 16 }}>
                  <div style={{
                    color: '#f5222d',
                    fontWeight: 'bold',
                    textShadow: '0 0 5px rgba(245, 34, 45, 0.3)',
                    fontSize: 18,
                    marginBottom: 8,
                    whiteSpace: 'nowrap', // 确保不换行
                    overflow: 'hidden',    // 防止溢出
                    textOverflow: 'ellipsis' // 溢出时显示省略号
                  }}>
                    {item.price.toFixed(2)} ETH
                  </div>
                  <div style={{ marginTop: 8 }}>
                    <Button
                      size="small"
                      type="text"
                      icon={isWhaleTracked(item.whaleIsBuyer ? item.buyer : (item.whaleSeller ? item.seller : item.whaleAddress)) ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleTracking(item.whaleIsBuyer ? item.buyer : (item.whaleSeller ? item.seller : item.whaleAddress));
                      }}
                      style={{
                        color: isWhaleTracked(item.whaleIsBuyer ? item.buyer : (item.whaleSeller ? item.seller : item.whaleAddress)) ? '#faad14' : 'rgba(255, 255, 255, 0.45)',
                        transition: 'all 0.3s'
                      }}
                    >
                      {isWhaleTracked(item.whaleIsBuyer ? item.buyer : (item.whaleSeller ? item.seller : item.whaleAddress)) ? '已追踪' : '追踪'}
                    </Button>
                  </div>
                </div>
              </div>
            </List.Item>
          );
        }}
        pagination={{
          pageSize: 10,
          simple: true,
          style: { textAlign: 'center', margin: '16px 0', color: 'rgba(255, 255, 255, 0.65)' }
        }}
      />

      {/* 添加钱包分析模态框 */}
      <WalletAnalysisModal
        visible={walletModalVisible}
        onClose={() => setWalletModalVisible(false)}
        walletAddress={selectedWalletAddress}
        walletLabel={selectedWalletLabel}
      />
    </Card>
  );
};

// 交易趋势图表组件
const TransactionTrendChart: React.FC = () => {
  const getOption = () => {
    const dates = ['6月1日', '6月2日', '6月3日', '6月4日', '6月5日', '6月6日', '6月7日'];
    const volumes = [120, 132, 101, 134, 90, 230, 210];
    const amounts = [220000, 182000, 191000, 234000, 290000, 330000, 310000];

    return {
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'cross',
          crossStyle: {
            color: '#999'
          }
        },
        backgroundColor: 'rgba(0, 21, 41, 0.7)',
        borderColor: 'rgba(24, 144, 255, 0.2)',
        textStyle: {
          color: 'rgba(255, 255, 255, 0.85)'
        }
      },
      legend: {
        data: ['交易量', '交易金额'],
        textStyle: {
          color: 'rgba(255, 255, 255, 0.65)'
        }
      },
      grid: {
        left: '3%',
        right: '5%',
        bottom: '3%',
        containLabel: true
      },
      xAxis: [
        {
          type: 'category',
          data: dates,
          axisPointer: {
            type: 'shadow'
          },
          axisLine: {
            lineStyle: {
              color: 'rgba(255, 255, 255, 0.2)'
            }
          },
          axisLabel: {
            color: 'rgba(255, 255, 255, 0.65)'
          }
        }
      ],
      yAxis: [
        {
          type: 'value',
          name: '交易量',
          min: 0,
          max: 250,
          interval: 50,
          axisLabel: {
            formatter: '{value}',
            color: 'rgba(255, 255, 255, 0.65)'
          },
          nameTextStyle: {
            color: 'rgba(255, 255, 255, 0.65)'
          },
          splitLine: {
            lineStyle: {
              color: 'rgba(255, 255, 255, 0.1)'
            }
          }
        },
        {
          type: 'value',
          name: '交易金额',
          min: 0,
          max: 350000,
          interval: 50000,
          axisLabel: {
            formatter: '${value}',
            color: 'rgba(255, 255, 255, 0.65)'
          },
          nameTextStyle: {
            color: 'rgba(255, 255, 255, 0.65)'
          },
          splitLine: {
            lineStyle: {
              color: 'rgba(255, 255, 255, 0.1)'
            }
          }
        }
      ],
      series: [
        {
          name: '交易量',
          type: 'bar',
          data: volumes,
          itemStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(24, 144, 255, 0.9)' },
              { offset: 1, color: 'rgba(24, 144, 255, 0.4)' }
            ])
          }
        },
        {
          name: '交易金额',
          type: 'line',
          yAxisIndex: 1,
          data: amounts,
          symbol: 'circle',
          symbolSize: 8,
          lineStyle: {
            width: 3,
            color: '#52c41a'
          },
          itemStyle: {
            color: '#52c41a',
            borderColor: '#fff',
            borderWidth: 2
          }
        }
      ]
    };
  };

  return (
    <ReactECharts
      option={getOption()}
      style={{ height: '300px', width: '100%' }}
      className="react-echarts"
    />
  );
};

// 收藏集活跃度柱状图组件
const CollectionActivityChart: React.FC = () => {
  const getOption = () => {
    return {
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow'
        },
        backgroundColor: 'rgba(0, 21, 41, 0.7)',
        borderColor: 'rgba(24, 144, 255, 0.2)',
        textStyle: {
          color: 'rgba(255, 255, 255, 0.85)'
        }
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '5%',
        top: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'value',
        axisLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.2)'
          }
        },
        axisLabel: {
          color: 'rgba(255, 255, 255, 0.65)'
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.1)'
          }
        }
      },
      yAxis: {
        type: 'category',
        data: ['CryptoPunks', 'Azuki', 'BAYC', 'Doodles', 'CloneX'],
        axisLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.2)'
          }
        },
        axisLabel: {
          color: 'rgba(255, 255, 255, 0.65)'
        }
      },
      series: [
        {
          name: '交易次数',
          type: 'bar',
          data: [18, 23, 29, 12, 9],
          label: {
            show: true,
            position: 'right',
            color: 'rgba(255, 255, 255, 0.85)'
          },
          itemStyle: {
            color: function (params: any) {
              const colorList = [
                new echarts.graphic.LinearGradient(0, 0, 1, 0, [
                  { offset: 0, color: 'rgba(24, 144, 255, 0.4)' },
                  { offset: 1, color: 'rgba(24, 144, 255, 0.9)' }
                ]),
                new echarts.graphic.LinearGradient(0, 0, 1, 0, [
                  { offset: 0, color: 'rgba(82, 196, 26, 0.4)' },
                  { offset: 1, color: 'rgba(82, 196, 26, 0.9)' }
                ]),
                new echarts.graphic.LinearGradient(0, 0, 1, 0, [
                  { offset: 0, color: 'rgba(250, 173, 20, 0.4)' },
                  { offset: 1, color: 'rgba(250, 173, 20, 0.9)' }
                ]),
                new echarts.graphic.LinearGradient(0, 0, 1, 0, [
                  { offset: 0, color: 'rgba(245, 34, 45, 0.4)' },
                  { offset: 1, color: 'rgba(245, 34, 45, 0.9)' }
                ]),
                new echarts.graphic.LinearGradient(0, 0, 1, 0, [
                  { offset: 0, color: 'rgba(114, 46, 209, 0.4)' },
                  { offset: 1, color: 'rgba(114, 46, 209, 0.9)' }
                ])
              ];
              return colorList[params.dataIndex];
            }
          }
        }
      ]
    };
  };

  return (
    <ReactECharts
      option={getOption()}
      style={{ height: '250px', width: '100%' }}
      className="react-echarts"
    />
  );
};

// 前十鲸鱼交易额饼状图组件
const TopWhalesTradingVolumeChart: React.FC<{ timeRange: 'day' | 'week' | 'month' }> = ({ timeRange }) => {
  const [chartData, setChartData] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  
  // 使用useEffect获取数据
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        // 确定要使用的rank_timerange值
        const rankTimeRange = timeRange === 'day' ? 'DAY' : 
                             timeRange === 'week' ? '7DAYS' : '30DAYS';
        
        // 使用dataLakeApi从ads.ads_top_profit_whales表获取数据
        const response: any = await dataLakeApi.queryTableData('ads', 'ads_top_profit_whales', 30);
        
        // 检查数据是否有效
        if (Array.isArray(response) && response.length > 0) {
          // 筛选出特定时间范围的数据并按rank_num排序
          const filteredData = response
            .filter((item: any) => item.rank_timerange === rankTimeRange)
            .sort((a: any, b: any) => a.rank_num - b.rank_num)
            .slice(0, 10); // 只取前10名
          
          // 计算总收益额
          const totalProfit = filteredData.reduce((sum: number, item: any) => 
            sum + (Number(item.total_profit_eth) || 0), 0);
          
          // 将数据转换为图表需要的格式，包括百分比计算
          const formattedData = filteredData.map((item: any) => {
            const profitValue = Number(item.total_profit_eth) || 0;
            const percentage = totalProfit > 0 ? (profitValue / totalProfit * 100) : 0;
            
            return {
              name: item.wallet_address ? 
                `${item.wallet_address.substring(0, 6)}...${item.wallet_address.substring(item.wallet_address.length - 4)} (${percentage.toFixed(1)}%)` : 
                'Unknown',
              value: profitValue,
              percentage: percentage
            };
          });
          
          console.log('鲸鱼收益数据占比:', formattedData.map(item => 
            `${item.name}: ${item.value} ETH (${item.percentage.toFixed(1)}%)`).join('\n'));
            
          setChartData(formattedData);
        } else {
          // 如果没有数据，使用模拟数据
          setChartData(getMockData());
        }
      } catch (error) {
        console.error('获取鲸鱼收益数据失败', error);
        // 出错时使用模拟数据
        setChartData(getMockData());
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, [timeRange]);
  
  // 获取模拟数据的方法 - 保留原有的模拟数据作为备用
  const getMockData = () => {
    // 根据时间范围返回不同的数据
    if (timeRange === 'day') {
      return [
        { name: 'WHALE-0x5678 (20.5%)', value: 450000, percentage: 20.5 },
        { name: 'WHALE-0x7842 (17.3%)', value: 380000, percentage: 17.3 },
        { name: 'WHALE-0x1234 (14.6%)', value: 320000, percentage: 14.6 },
        { name: 'WHALE-0x2469 (12.8%)', value: 280000, percentage: 12.8 },
        { name: 'WHALE-0x8276 (10.5%)', value: 230000, percentage: 10.5 },
        { name: 'WHALE-0x3694 (8.7%)', value: 190000, percentage: 8.7 },
        { name: 'WHALE-0x9127 (6.8%)', value: 150000, percentage: 6.8 },
        { name: 'WHALE-0x8765 (5.5%)', value: 120000, percentage: 5.5 },
        { name: 'WHALE-0x6723 (4.1%)', value: 90000, percentage: 4.1 },
        { name: 'WHALE-0x1498 (3.2%)', value: 70000, percentage: 3.2 }
      ];
    } else if (timeRange === 'week') {
      return [
        { name: 'WHALE-0x5678 (20.1%)', value: 1250000, percentage: 20.1 },
        { name: 'WHALE-0x7842 (15.8%)', value: 980000, percentage: 15.8 },
        { name: 'WHALE-0x1234 (12.2%)', value: 760000, percentage: 12.2 },
        { name: 'WHALE-0x2469 (10.5%)', value: 650000, percentage: 10.5 },
        { name: 'WHALE-0x8276 (9.3%)', value: 580000, percentage: 9.3 },
        { name: 'WHALE-0x3694 (8.4%)', value: 520000, percentage: 8.4 },
        { name: 'WHALE-0x9127 (7.7%)', value: 480000, percentage: 7.7 },
        { name: 'WHALE-0x8765 (6.6%)', value: 410000, percentage: 6.6 },
        { name: 'WHALE-0x6723 (6.1%)', value: 380000, percentage: 6.1 },
        { name: 'WHALE-0x1498 (5.2%)', value: 320000, percentage: 5.2 }
      ];
    } else {
      return [
        { name: 'WHALE-0x5678 (19.1%)', value: 4850000, percentage: 19.1 },
        { name: 'WHALE-0x7842 (14.6%)', value: 3720000, percentage: 14.6 },
        { name: 'WHALE-0x2469 (11.6%)', value: 2950000, percentage: 11.6 },
        { name: 'WHALE-0x1234 (10.5%)', value: 2680000, percentage: 10.5 },
        { name: 'WHALE-0x3694 (9.6%)', value: 2450000, percentage: 9.6 },
        { name: 'WHALE-0x8276 (8.3%)', value: 2120000, percentage: 8.3 },
        { name: 'WHALE-0x9127 (7.8%)', value: 1980000, percentage: 7.8 },
        { name: 'WHALE-0x6723 (6.5%)', value: 1650000, percentage: 6.5 },
        { name: 'WHALE-0x8765 (6.0%)', value: 1520000, percentage: 6.0 },
        { name: 'WHALE-0x1498 (5.4%)', value: 1380000, percentage: 5.4 }
      ];
    }
  };

  const getOption = () => {
    const data = chartData;
    const totalVolume = data.reduce((sum, item) => sum + item.value, 0);

    return {
      tooltip: {
        trigger: 'item',
        formatter: (params: any) => {
          const item = data.find(d => d.name === params.name);
          const percent = item?.percentage || ((params.value / totalVolume) * 100).toFixed(1);
          return `<div style="display: flex; flex-direction: column; gap: 8px; padding: 8px 12px;">
                   <div style="font-size: 14px; font-weight: bold; color: #fff;">${params.name.split(' (')[0]}</div>
                   <div style="display: flex; justify-content: space-between; gap: 16px;">
                     <span style="color: rgba(255, 255, 255, 0.85);">收益额:</span>
                     <span style="color: #1890ff; font-weight: bold;">${params.value.toFixed(2)} ETH</span>
                   </div>
                   <div style="display: flex; justify-content: space-between; gap: 16px;">
                     <span style="color: rgba(255, 255, 255, 0.85);">占比:</span>
                     <span style="color: #52c41a; font-weight: bold;">${percent}%</span>
                   </div>
                 </div>`;
        },
        backgroundColor: 'rgba(0, 21, 41, 0.9)',
        borderColor: 'rgba(24, 144, 255, 0.3)',
        borderWidth: 1,
        borderRadius: 8,
        textStyle: {
          color: 'rgba(255, 255, 255, 0.85)'
        },
        extraCssText: 'box-shadow: 0 4px 12px rgba(0,0,0,0.15); backdrop-filter: blur(4px);'
      },
      legend: {
        type: 'scroll',
        orient: 'vertical',
        right: 10,
        top: 'center',
        data: data.map(item => item.name),
        textStyle: {
          color: 'rgba(255, 255, 255, 0.65)',
          fontSize: 12
        },
        itemWidth: 14,
        itemHeight: 14,
        pageIconColor: 'rgba(24, 144, 255, 0.8)',
        pageIconInactiveColor: 'rgba(24, 144, 255, 0.3)',
        pageIconSize: 12,
        pageTextStyle: {
          color: 'rgba(255, 255, 255, 0.65)'
        },
        itemGap: 12,
        formatter: (name: string) => {
          const item = data.find(d => d.name === name);
          const percent = ((item?.value || 0) / totalVolume * 100).toFixed(1);
          return `${name}  ${percent}%`;
        },
        selectedMode: true,
        select: {
          itemStyle: {
            shadowBlur: 10,
            shadowColor: 'rgba(24, 144, 255, 0.5)'
          }
        }
      },
      series: [
        {
          name: timeRange === 'day' ? '近一天交易额' : timeRange === 'week' ? '近一周交易额' : '近一月交易额',
          type: 'pie',
          radius: ['40%', '70%'],
          center: ['40%', '50%'],
          avoidLabelOverlap: true,
          itemStyle: {
            borderRadius: 8,
            borderColor: '#001529',
            borderWidth: 2,
            shadowBlur: 10,
            shadowColor: 'rgba(0, 0, 0, 0.3)'
          },
          label: {
            show: false,
            position: 'center',
            fontSize: 14,
            color: 'rgba(255, 255, 255, 0.85)',
            fontWeight: 'bold'
          },
          emphasis: {
            label: {
              show: true,
              formatter: (params: any) => {
                const percent = ((params.value / totalVolume) * 100).toFixed(1);
                return [
                  `{name|${params.name}}`,
                  `{value|${percent}%}`
                ].join('\n');
              },
              rich: {
                name: {
                  fontSize: 14,
                  color: 'rgba(255, 255, 255, 0.85)',
                  fontWeight: 'bold',
                  padding: [4, 0]
                },
                value: {
                  fontSize: 20,
                  color: '#1890ff',
                  fontWeight: 'bold',
                  padding: [4, 0]
                }
              }
            },
            itemStyle: {
              shadowBlur: 20,
              shadowColor: 'rgba(24, 144, 255, 0.5)'
            }
          },
          labelLine: {
            show: false
          },
          data: data.map((item, index) => ({
            ...item,
            itemStyle: {
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                {
                  offset: 0,
                  color: [
                    '#1890ff', '#52c41a', '#faad14', '#f5222d', '#722ed1',
                    '#13c2c2', '#eb2f96', '#fa541c', '#a0d911', '#2f54eb'
                  ][index]
                },
                {
                  offset: 1,
                  color: [
                    '#096dd9', '#389e0d', '#d48806', '#cf1322', '#531dab',
                    '#08979c', '#c41d7f', '#d4380d', '#7cb305', '#1d39c4'
                  ][index]
                }
              ])
            }
          }))
        }
      ],
      animation: true,
      animationDuration: 1500,
      animationEasing: 'cubicInOut',
      animationDelay: (idx: number) => idx * 100,
      universalTransition: true
    };
  };

  return (
    <>
      {loading ? (
        <TechLoading />
      ) : (
    <ReactECharts
      option={getOption()}
      style={{ height: '300px', width: '100%' }}
      className="react-echarts"
    />
      )}
    </>
  );
};

// 鲸鱼流入Top10收藏集统计图
const WhaleInflowCollectionsChart: React.FC<{
  timeRange: 'day' | 'week' | 'month',
  whaleType: 'all' | 'smart' | 'dumb'
}> = ({ timeRange, whaleType }) => {
  // 状态管理
  const [chartData, setChartData] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // 获取图表数据
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      setError(null);
      try {
        // 选择合适的数据表
        let database = 'ads';
        let table = 'ads_tracking_whale_collection_flow'; // 默认表
        
        // 根据鲸鱼类型选择不同的表
        if (whaleType === 'smart') {
          table = 'ads_smart_whale_collection_flow';
        } else if (whaleType === 'dumb') {
          table = 'ads_dumb_whale_collection_flow';
        }
        
        console.log(`尝试从 ${database}.${table} 获取鲸鱼净流入数据...`);
        
        // 从数据湖获取数据
        const response: any = await dataLakeApi.queryTableData(database, table, 1000);
        
        console.log('数据湖API返回的原始数据:', response);
        
        // 正确处理响应数据（response直接就是数组）
        if (response && Array.isArray(response) && response.length > 0) {
          // 输出第一条记录的所有字段，帮助调试
          console.log('数据湖返回的第一条记录字段:', Object.keys(response[0]));
          console.log('数据湖返回的第一条记录值:', response[0]);
          
          // 根据时间范围筛选数据
          let filteredData = [...response]; // 创建数组副本
          
          // 根据rank_timerange字段筛选
          const timeRangeMap: {[key: string]: string} = {
            'day': 'DAY',
            'week': '7DAYS',
            'month': '30DAYS'
          };
          const targetTimeRange = timeRangeMap[timeRange];
          
          console.log('筛选目标时间范围:', targetTimeRange);
          
          // 检查是否有flow_direction字段，如果没有，则直接按rank_timerange筛选
          const hasFlowDirectionField = response[0].hasOwnProperty('flow_direction');
          
          if (hasFlowDirectionField) {
            filteredData = filteredData.filter((item: any) => 
              item.rank_timerange === targetTimeRange && 
              item.flow_direction === 'INFLOW'
            );
            console.log(`按rank_timerange=${targetTimeRange}和flow_direction=INFLOW筛选后数据:`, filteredData.length);
          } else {
            filteredData = filteredData.filter((item: any) => 
              item.rank_timerange === targetTimeRange
            );
            console.log(`按rank_timerange=${targetTimeRange}筛选后数据:`, filteredData.length);
          }
          
          // 如果筛选后没有数据，尝试不进行flow_direction筛选
          if (filteredData.length === 0 && hasFlowDirectionField) {
            filteredData = response.filter((item: any) => item.rank_timerange === targetTimeRange);
            console.log(`重新只按rank_timerange=${targetTimeRange}筛选后数据:`, filteredData.length);
          }
          
          // 如果仍然没有数据，使用所有数据
          if (filteredData.length === 0) {
            filteredData = response;
            console.log('筛选后无数据，使用所有数据:', filteredData.length);
          }
          
          // 获取适当的净流量字段名
          let netFlowField = '';
          if (timeRange === 'day') {
            netFlowField = 'net_flow_eth'; // 尝试以下字段之一
          } else if (timeRange === 'week') {
            netFlowField = 'net_flow_7d_eth'; // 7天净流量
          } else {
            netFlowField = 'net_flow_30d_eth'; // 30天净流量
          }
          
          // 如果指定字段不存在，尝试使用通用字段
          if (!response[0].hasOwnProperty(netFlowField)) {
            netFlowField = 'net_flow_eth';
            console.log(`指定字段 ${netFlowField} 不存在，使用通用字段 net_flow_eth`);
          }
          
          console.log(`使用净流量字段: ${netFlowField}`);
          
          // 获取智能/愚蠢鲸鱼字段前缀
          let fieldPrefix = '';
          if (whaleType === 'smart') {
            fieldPrefix = 'smart_whale_';
          } else if (whaleType === 'dumb') {
            fieldPrefix = 'dumb_whale_';
          }
          
          // 完整的净流量字段名
          const fullNetFlowField = fieldPrefix ? fieldPrefix + netFlowField : netFlowField;
          
          console.log(`最终使用的净流量字段: ${fullNetFlowField}`);
          
          // 按照净流入量排序并获取前10
          let sortedData = filteredData.sort((a: any, b: any) => {
            // 获取流量值，根据是否有指定字段决定使用哪个字段
            let fieldA, fieldB;
            
            if (a.hasOwnProperty(fullNetFlowField) && b.hasOwnProperty(fullNetFlowField)) {
              fieldA = Math.abs(a[fullNetFlowField]) || 0;
              fieldB = Math.abs(b[fullNetFlowField]) || 0;
            } else if (a.hasOwnProperty(netFlowField) && b.hasOwnProperty(netFlowField)) {
              fieldA = Math.abs(a[netFlowField]) || 0;
              fieldB = Math.abs(b[netFlowField]) || 0;
            } else if (a.hasOwnProperty('net_flow_eth') && b.hasOwnProperty('net_flow_eth')) {
              fieldA = Math.abs(a.net_flow_eth) || 0;
              fieldB = Math.abs(b.net_flow_eth) || 0;
            } else {
              // 如果没有找到匹配的字段，尝试使用rank_num
              fieldA = -(a.rank_num || 999); // 通过负数转换，使rank_num小的排前面
              fieldB = -(b.rank_num || 999);
            }
            
            return fieldB - fieldA; // 降序排序
          }).slice(0, 10);

          console.log('排序后的前10条数据:', sortedData);

          // 格式化数据以适应图表
          const formattedData = sortedData.map((item: any) => {
            let value = 0;
            
            // 尝试获取净流入金额
            if (item.hasOwnProperty(fullNetFlowField)) {
              value = Math.abs(item[fullNetFlowField]) * 2000; // ETH价格为2000美元
            } else if (item.hasOwnProperty(netFlowField)) {
              value = Math.abs(item[netFlowField]) * 2000;
            } else if (item.hasOwnProperty('net_flow_eth')) {
              value = Math.abs(item.net_flow_eth) * 2000;
            } else {
              // 如果没有找到匹配的字段，使用排名的反比例作为值
              value = (100 - (item.rank_num || 0)) * 100000 / 100;
            }
            
            // 取值下限为100，确保有显示效果
            if (value < 100) value = 100;
            
            return {
              name: item.collection_name || '未知收藏集',
              value: value,
              icon: item.collection_address || item.collection_name || 'UNKNOWN',
              logoUrl: item.logo_url,
              rank: item.rank_num
            };
          });
          
          console.log('最终格式化的图表数据:', formattedData);
          setChartData(formattedData);
          setError(null); // 数据加载成功，清除错误状态
        } else {
          console.error('数据格式不正确或为空:', response);
          setError('数据格式不正确或为空');
          // 使用备用模拟数据
          setChartData(getBackupData());
        }
      } catch (err) {
        console.error('获取数据失败:', err);
        setError('获取数据失败');
        // 使用备用模拟数据
        setChartData(getBackupData());
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, [timeRange, whaleType]); // 时间范围或鲸鱼类型变化时重新获取数据

  // 备用模拟数据，当API调用失败时使用
  const getBackupData = () => {
    // 基础数据集
    let baseData: { name: string; value: number; icon: string }[] = [];

    // 根据时间范围选择基础数据集
    if (timeRange === 'day') {
      baseData = [
        { name: 'BAYC', value: 420000, icon: 'BAYC' },
        { name: 'CryptoPunks', value: 380000, icon: 'CryptoPunks' },
        { name: 'Azuki', value: 320000, icon: 'Azuki' },
        { name: 'Otherdeeds', value: 280000, icon: 'Otherdeeds' },
        { name: 'MAYC', value: 240000, icon: 'MAYC' },
        { name: 'CloneX', value: 210000, icon: 'CloneX' },
        { name: 'Moonbirds', value: 180000, icon: 'Moonbirds' },
        { name: 'Doodles', value: 150000, icon: 'Doodles' },
        { name: 'WoW', value: 120000, icon: 'WoW' },
        { name: 'CyberKongz', value: 100000, icon: 'CyberKongz' }
      ];
    } else if (timeRange === 'week') {
      baseData = [
        { name: 'CryptoPunks', value: 1850000, icon: 'CryptoPunks' },
        { name: 'BAYC', value: 1750000, icon: 'BAYC' },
        { name: 'Azuki', value: 1450000, icon: 'Azuki' },
        { name: 'MAYC', value: 1200000, icon: 'MAYC' },
        { name: 'Otherdeeds', value: 980000, icon: 'Otherdeeds' },
        { name: 'Moonbirds', value: 780000, icon: 'Moonbirds' },
        { name: 'CloneX', value: 680000, icon: 'CloneX' },
        { name: 'Doodles', value: 520000, icon: 'Doodles' },
        { name: 'Cool Cats', value: 380000, icon: 'Cool Cats' },
        { name: 'Meebits', value: 320000, icon: 'Meebits' }
      ];
    } else {
      baseData = [
        { name: 'CryptoPunks', value: 6250000, icon: 'CryptoPunks' },
        { name: 'BAYC', value: 5800000, icon: 'BAYC' },
        { name: 'Azuki', value: 3700000, icon: 'Azuki' },
        { name: 'MAYC', value: 2950000, icon: 'MAYC' },
        { name: 'Otherdeeds', value: 2450000, icon: 'Otherdeeds' },
        { name: 'CloneX', value: 1950000, icon: 'CloneX' },
        { name: 'Moonbirds', value: 1680000, icon: 'Moonbirds' },
        { name: 'Doodles', value: 1450000, icon: 'Doodles' },
        { name: 'Meebits', value: 1250000, icon: 'Meebits' },
        { name: 'Goblintown', value: 980000, icon: 'Goblintown' }
      ];
    }

    // 根据鲸鱼类型进一步筛选和调整数据
    if (whaleType === 'smart') {
      // 聪明鲸鱼通常会选择优质项目，且在早期进入
      return baseData.map(item => {
        const multiplier = ['CryptoPunks', 'BAYC', 'Azuki', 'Moonbirds', 'CloneX'].includes(item.name)
          ? 1.4  // 优质蓝筹项目加成
          : 0.7; // 其他项目减成
        return {
          ...item,
          value: Math.round(item.value * multiplier)
        };
      }).sort((a, b) => b.value - a.value).slice(0, 10);
    } else if (whaleType === 'dumb') {
      // 愚蠢鲸鱼通常会错过优质项目或买在顶部
      const dumbData = baseData.map(item => {
        const multiplier = ['Goblintown', 'Cool Cats', 'Meebits', 'Doodles'].includes(item.name)
          ? 1.6  // 投机性项目加成
          : 0.5; // 蓝筹项目减成
        return {
          ...item,
          value: Math.round(item.value * multiplier)
        };
      });
      // 添加一些特殊项目，愚蠢鲸鱼更可能投资这些
      if (timeRange === 'day') {
        dumbData.push(
          { name: 'NFT Worlds', value: 180000, icon: 'Cryptoadz' },
          { name: 'Pixelmon', value: 160000, icon: 'Goblintown' }
        );
      } else if (timeRange === 'week') {
        dumbData.push(
          { name: 'Pixelmon', value: 480000, icon: 'Goblintown' },
          { name: 'NFT Worlds', value: 420000, icon: 'Cryptoadz' }
        );
      } else {
        dumbData.push(
          { name: 'Pixelmon', value: 1850000, icon: 'Goblintown' },
          { name: 'NFT Worlds', value: 1680000, icon: 'Cryptoadz' }
        );
      }
      return dumbData.sort((a, b) => b.value - a.value).slice(0, 10);
    } else {
      // 所有鲸鱼
      return baseData;
    }
  };

  // 获取图标URL的函数
  const getIconUrl = (collection: string, logoUrl?: string) => {
    // 如果有logo_url字段，优先使用
    if (logoUrl && logoUrl.startsWith('http')) {
      return logoUrl;
    }
    
    // 标准化集合名称（转为小写并移除空格）以便更好地匹配
    const normalizedCollection = collection.toLowerCase().replace(/\s+/g, '');
    
    const collections: { [key: string]: string } = {
      'bayc': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256',
      'azuki': 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256',
      'cryptopunks': 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?auto=format&dpr=1&w=256',
      'doodles': 'https://i.seadn.io/gae/7B0qai02OdHA8P_EOVK672qUliyjQdQDGNrACxs7WnTgZAkJa_wWURnIFKeOh5VTf8cfTqW3wQpozGEJpJpJnv_DqHDFWxcQplRFyw?auto=format&dpr=1&w=256',
      'clonex': 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?auto=format&dpr=1&w=256',
      'mayc': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=256',
      'moonbirds': 'https://i.seadn.io/gae/H-eyNE1MwL5ohL-tCfn_Xa1Sl9M9B4612tLYeUlQubzt4ewhr4huJIR5OLuyO3Z5PpJFSwdm7rq-TikAh7f5eUw338A2cy6HRH75?auto=format&dpr=1&w=256',
      'pudgypenguins': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=256',
      'otherdeeds': 'https://i.seadn.io/gae/yIm-M5-BpSDdTEIJRt5D6xphizhIdozXjqSITgK4phWq7MmAU3qE7Nw7POGCiPGyhtJ3ZFP8iJ29TFl-RLcGBWX5qI4-ZcnCPcsY4zI?auto=format&dpr=1&w=256',
      'wow': 'https://i.seadn.io/gae/EFAQpIktMraCrs8YLJy_FgjN9jOJW-O6cAZr9eriPZdkKvhJWEdre9wZOxTZL84HJN0GZxwNJXVPOZ8OQfYxgUMnR2JmrpdtWRK1?auto=format&dpr=1&w=256',
      'cyberkongz': 'https://i.seadn.io/gae/LIpf9z6Ux8uxn69auBME9FCTXpXqSYFo8ZLO1GaM8T7S3hiKScHaClXe0ZdhTv5br6FE2g5i-J5SobhKFsYfe6CIMCv-UfnrlYFWOM4?auto=format&dpr=1&w=256',
      'coolcats': 'https://i.seadn.io/gae/LIov33kogXOK4XZd2ESj29sqm_Hww5JSdO7AFn5wjt8xgnJJ0UpNV9yITqxra3s_LMEW1AnnrgOVB_hDpjJRA1uF4skI5Sdi_9rULi8?auto=format&dpr=1&w=256',
      'meebits': 'https://i.seadn.io/gae/d784iHHbqQFVH1XYD6HoT4u3y_Fsu_9FZUltWjnOzoYv7qqB5dLUqpOJ16kTQAGr-NORVYHOwzOqRkigvUrYoBCYAAltp8Zf-ZV3?auto=format&dpr=1&w=256',
      'cryptoadz': 'https://i.seadn.io/gae/iofetZEyiEIGcNyJKpbOafb_efJyeo7QOYnTog8qcQJhqoBU-Vu7mnijXM7SouWRtHKCuLIC9XDcGILXfyg0bnBZ6IPrWMA5VaCgygE?auto=format&dpr=1&w=256',
      'goblintown': 'https://i.seadn.io/gae/cb_wdEAmvry_noTCq1EDPD3eF04Wg3YxHPzGW9QjIjX9-hU-Q5y_rLpbEWhnmcSuYWRiV7bjZ6T41w8tgMqjEIHFWzG_AQT-qm1KnKU?auto=format&dpr=1&w=256',
      'degods': 'https://i.seadn.io/gae/FVTsD1oMUJHZiBkMibDgXimXQnJzYM9XxoMxTMR-JzHIQW-FGb0jlDfNTRbGZQBgQMKy6oVYDiCDfGTcSUAWatIKcGy4LMrAYnYl?auto=format&dpr=1&w=256',
      'milady': 'https://i.seadn.io/gae/a_frplnavZA9g4vN3SexO5rrtaBX_cBTaJYcgrPtwQIqPhzgzUendQxiwUdr51CGPE2QyPEa1DHnkW1wLrHAv5DgfC3BP-CRqDIVfGo?auto=format&dpr=1&w=256',
      'boredapeyachtclub': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256',
      'mutantapeyachtclub': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=256',
      'fidenza': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=256',
      'chromiesquiggle': 'https://i.seadn.io/gae/0qG8Y78s198F2R0xTOhje0UeK7GWpgKdLTdL2NF8e_siutxvxE5wNKoH_5XgLvCcB-jOq6hbidLuFAr2rzQBQkYNwu6_tUJhGnyom4I?auto=format&dpr=1&w=256',
      'autoglyphs': 'https://i.seadn.io/gae/JYz5dU8xK0FCzFp4NiOGkZGzVB77JQ2PMz9tMr7N2em9mvg8BpWHReqQOOK8RXwEMJbUqSY3ZFZyQB3c0jZ-lBb-MaijEOYc9bvzMA?auto=format&dpr=1&w=256',
      'nouns': 'https://i.seadn.io/gae/dQQcSXxzJJBw2FXB-aZFh-jAXrGWss2RfZxDY4Ykr8uqJT8-cY1FJR9cq9qMXmUtKK9GBEEzZ7kTXKd_iBDxT3lw1XwWT-wB3FveqA?auto=format&dpr=1&w=256',
      'loot': 'https://i.seadn.io/gae/Nhz0VbI2GV_PfS_9LDpwJzpH6xxbx0Mxoz2WwXNxmiifeI-JxgJZXD5IutgNTYZEYc3mB73MTJKc7G_9Hbv5ArjnWqpZ6-1wBYx0IQ?auto=format&dpr=1&w=256',
      'hope': 'https://i.seadn.io/gcs/files/2d058acad86d29a218bd1fba24e9eb28.png?auto=format&dpr=1&w=256'
    };

    // 处理特殊情况
    if (normalizedCollection.includes('bored') && normalizedCollection.includes('ape')) return collections['bayc'];
    if (normalizedCollection.includes('mutant') && normalizedCollection.includes('ape')) return collections['mayc'];
    if (normalizedCollection.includes('cool') && normalizedCollection.includes('cat')) return collections['coolcats'];
    if (normalizedCollection.includes('cyber') && normalizedCollection.includes('kong')) return collections['cyberkongz'];
    if (normalizedCollection.includes('pudgy')) return collections['pudgypenguins'];
    if (normalizedCollection.includes('cryptopunk')) return collections['cryptopunks'];
    
    // 检查集合名称是否存在，不区分大小写
    for (const [key, url] of Object.entries(collections)) {
      if (normalizedCollection.includes(key.toLowerCase())) {
        return url;
      }
    }

    // 检查是否有匹配的图标，如果没有，尝试模糊匹配
    if (collections[normalizedCollection]) {
      return collections[normalizedCollection];
    }
    
    // 尝试部分匹配
    for (const [key, url] of Object.entries(collections)) {
      if (normalizedCollection.includes(key) || key.includes(normalizedCollection)) {
        return url;
      }
    }

    // 如果找不到匹配的图标，使用默认图标
    const defaultLogo = 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256';
    console.log(`未找到"${collection}"的图标，使用默认图标`);
    return defaultLogo;
  };

  // 准备ECharts配置
  const getOption = () => {
    if (loading) {
      return {
        title: {
          text: '加载中...',
          left: 'center',
          textStyle: {
            color: '#fff'
          }
        }
      };
    }

    // 即使有错误状态，如果chartData有数据，优先使用实际数据
    const data = chartData.length > 0 ? chartData : getBackupData();
    
    // 仅在没有实际数据且有错误时才显示错误提示
    if (error && chartData.length === 0) {
      return {
        title: {
          text: '数据加载失败，显示备用数据',
          left: 'center',
          textStyle: {
            color: '#fff'
          }
        }
      };
    }
    
    // 数据排序
    data.sort((a, b) => a.value - b.value);

    // 准备图标配置
    const icons = data.map(item => getIconUrl(item.icon, item.logoUrl));

    // 美化：创建渐变色系
    const colors = [
      ['#1890ff', '#36cfff'], // 蓝色渐变
      ['#52c41a', '#a0d911'], // 绿色渐变
      ['#faad14', '#ffec3d'], // 黄色渐变
      ['#f5222d', '#ff7875'], // 红色渐变
      ['#722ed1', '#b37feb'], // 紫色渐变
      ['#13c2c2', '#5cdbd3'], // 青色渐变
      ['#eb2f96', '#ff85c0'], // 粉色渐变
      ['#fa541c', '#ff9c6e'], // 橙色渐变
      ['#2f54eb', '#85a5ff'], // 深蓝渐变
      ['#fa8c16', '#ffc53d']  // 橙黄渐变
    ];

    return {
      title: {
        show: false // 不显示标题
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow',
          shadowStyle: {
            color: 'rgba(24, 144, 255, 0.1)'
          }
        },
        formatter: function (params: any) {
          const dataIndex = params[0].dataIndex;
          // 确保data是已定义的
          if (!data || !data[dataIndex]) return '';

          const value = data[dataIndex].value;
          const formattedValue = new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 0
          }).format(value);

          return `<div style="display: flex; align-items: center; padding: 8px 12px;">
                   <img src="${icons[dataIndex]}" style="width: 32px; height: 32px; margin-right: 12px; border-radius: 4px; box-shadow: 0 2px 8px rgba(0,0,0,0.15);" />
                   <div>
                     <div style="font-weight: bold; font-size: 14px; margin-bottom: 4px;">${data[dataIndex].name}</div>
                     <div style="font-size: 16px; color: #fff;">${formattedValue}</div>
                   </div>
                 </div>`;
        },
        backgroundColor: 'rgba(0, 21, 41, 0.85)',
        borderColor: 'rgba(24, 144, 255, 0.3)',
        borderWidth: 1,
        borderRadius: 8,
        textStyle: {
          color: 'rgba(255, 255, 255, 0.85)'
        },
        extraCssText: 'box-shadow: 0 4px 12px rgba(0,0,0,0.15); backdrop-filter: blur(4px);'
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '4%',
        top: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'value',
        axisLabel: {
          formatter: function (value: number) {
            if (value >= 1000000) {
              return '$' + (value / 1000000).toFixed(1) + 'M';
            } else if (value >= 1000) {
              return '$' + (value / 1000).toFixed(0) + 'K';
            }
            return '$' + value;
          },
          color: 'rgba(255, 255, 255, 0.75)',
          fontWeight: 'bold',
          fontSize: 12,
          margin: 14
        },
        axisLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.2)',
            width: 2
          }
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.08)',
            type: 'dashed'
          }
        },
        axisTick: {
          show: false
        }
      },
      yAxis: {
        type: 'category',
        data: data.map(item => ''),  // 空字符串，因为我们使用rich text显示图标
        axisLabel: {
          formatter: function (value: string, index: number) {
            return '{icon' + index + '|}';
          },
          rich: data.reduce((acc: any, item, index) => {
            acc['icon' + index] = {
              height: 32,
              width: 32,
              align: 'center',
              backgroundColor: {
                image: icons[index]
              },
              borderRadius: 4,
              shadowBlur: 5,
              shadowColor: 'rgba(0, 0, 0, 0.3)',
              shadowOffsetX: 2,
              shadowOffsetY: 2
            };
            return acc;
          }, {}),
          color: 'rgba(255, 255, 255, 0.8)',
          margin: 20
        },
        axisLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.2)',
            width: 2
          }
        },
        axisTick: {
          show: false
        },
        splitLine: {
          show: false
        }
      },
      series: [
        {
          name: '流入金额',
          type: 'bar',
          data: data.map((item, index) => ({
            value: item.value,
            itemStyle: {
              color: {
                type: 'linear',
                x: 0,
                y: 0,
                x2: 1,
                y2: 0,
                colorStops: [
                  { offset: 0, color: colors[index % colors.length][0] },
                  { offset: 1, color: colors[index % colors.length][1] }
                ]
              },
              borderRadius: [0, 8, 8, 0],
              shadowBlur: 10,
              shadowColor: 'rgba(0, 0, 0, 0.2)',
              shadowOffsetX: 5,
              shadowOffsetY: 5
            }
          })),
          label: {
            show: true,
            position: 'insideRight',
            formatter: function (params: any) {
              const dataIndex = params.dataIndex;
              // 确保data是已定义的
              if (!data || !data[dataIndex]) return '';
              return data[dataIndex].name;
            },
            color: '#fff',
            fontSize: 14,
            fontWeight: 'bold',
            textShadow: '1px 1px 3px rgba(0, 0, 0, 0.3)'
          },
          barWidth: '60%',
          emphasis: {
            itemStyle: {
              shadowBlur: 20,
              shadowColor: 'rgba(0, 0, 0, 0.3)'
            }
          },
          animationDelay: function (idx: number) {
            return idx * 100;
          }
        }
      ],
      animationEasing: 'elasticOut',
      animationDelayUpdate: function (idx: number) {
        return idx * 5;
      },
      animationDuration: 1500
    };
  };

  return (
    <div className="whale-inflow-chart">
      {loading && <TechLoading />}
    <ReactECharts
      option={getOption()}
      style={{ height: '400px', width: '100%' }}
      className="react-echarts"
    />
    </div>
  );
};

// 鲸鱼流出Top10收藏集统计图
const WhaleOutflowCollectionsChart: React.FC<{
  timeRange: 'day' | 'week' | 'month',
  whaleType: 'all' | 'smart' | 'dumb'
}> = ({ timeRange, whaleType }) => {
  // 状态管理
  const [chartData, setChartData] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // 获取图表数据
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      setError(null);
      try {
        // 选择合适的数据表
        let database = 'ads';
        let table = 'ads_tracking_whale_collection_flow'; // 默认表
        
        // 根据鲸鱼类型选择不同的表
        if (whaleType === 'smart') {
          table = 'ads_smart_whale_collection_flow';
        } else if (whaleType === 'dumb') {
          table = 'ads_dumb_whale_collection_flow';
        }
        
        console.log(`尝试从 ${database}.${table} 获取鲸鱼净流出数据...`);
        
        // 从数据湖获取数据
        const response: any = await dataLakeApi.queryTableData(database, table, 1000);
        
        console.log('数据湖API返回的原始数据(流出):', response);
        
        // 正确处理响应数据（response直接就是数组）
        if (response && Array.isArray(response) && response.length > 0) {
          // 输出第一条记录的所有字段，帮助调试
          console.log('数据湖返回的第一条记录字段(流出):', Object.keys(response[0]));
          console.log('数据湖返回的第一条记录值(流出):', response[0]);
          
          // 根据时间范围筛选数据
          let filteredData = [...response]; // 创建数组副本
          
          // 根据rank_timerange字段筛选
          const timeRangeMap: {[key: string]: string} = {
            'day': 'DAY',
            'week': '7DAYS',
            'month': '30DAYS'
          };
          const targetTimeRange = timeRangeMap[timeRange];
          
          console.log('筛选目标时间范围(流出):', targetTimeRange);
          
          // 检查是否有flow_direction字段，如果没有，则直接按rank_timerange筛选
          const hasFlowDirectionField = response[0].hasOwnProperty('flow_direction');
          
          if (hasFlowDirectionField) {
            filteredData = filteredData.filter((item: any) => 
              item.rank_timerange === targetTimeRange && 
              item.flow_direction === 'OUTFLOW'
            );
            console.log(`按rank_timerange=${targetTimeRange}和flow_direction=OUTFLOW筛选后数据:`, filteredData.length);
          } else {
            filteredData = filteredData.filter((item: any) => 
              item.rank_timerange === targetTimeRange
            );
            console.log(`按rank_timerange=${targetTimeRange}筛选后数据(流出):`, filteredData.length);
          }
          
          // 如果筛选后没有数据，尝试不进行flow_direction筛选
          if (filteredData.length === 0 && hasFlowDirectionField) {
            filteredData = response.filter((item: any) => item.rank_timerange === targetTimeRange);
            console.log(`重新只按rank_timerange=${targetTimeRange}筛选后数据(流出):`, filteredData.length);
          }
          
          // 如果仍然没有数据，使用所有数据
          if (filteredData.length === 0) {
            filteredData = response;
            console.log('筛选后无数据，使用所有数据(流出):', filteredData.length);
          }
          
          // 获取适当的净流量字段名
          let netFlowField = '';
          if (timeRange === 'day') {
            netFlowField = 'net_flow_eth'; // 尝试以下字段之一
          } else if (timeRange === 'week') {
            netFlowField = 'net_flow_7d_eth'; // 7天净流量
          } else {
            netFlowField = 'net_flow_30d_eth'; // 30天净流量
          }
          
          // 如果指定字段不存在，尝试使用通用字段
          if (!response[0].hasOwnProperty(netFlowField)) {
            netFlowField = 'net_flow_eth';
            console.log(`指定字段 ${netFlowField} 不存在，使用通用字段 net_flow_eth (流出)`);
          }
          
          console.log(`使用净流量字段(流出): ${netFlowField}`);
          
          // 获取智能/愚蠢鲸鱼字段前缀
          let fieldPrefix = '';
          if (whaleType === 'smart') {
            fieldPrefix = 'smart_whale_';
          } else if (whaleType === 'dumb') {
            fieldPrefix = 'dumb_whale_';
          }
          
          // 完整的净流量字段名
          const fullNetFlowField = fieldPrefix ? fieldPrefix + netFlowField : netFlowField;
          
          console.log(`最终使用的净流量字段(流出): ${fullNetFlowField}`);
          
          // 按照净流出量排序并获取前10
          let sortedData = filteredData.sort((a: any, b: any) => {
            // 获取流量值，根据是否有指定字段决定使用哪个字段
            let fieldA, fieldB;
            
            if (a.hasOwnProperty(fullNetFlowField) && b.hasOwnProperty(fullNetFlowField)) {
              fieldA = Math.abs(a[fullNetFlowField]) || 0;
              fieldB = Math.abs(b[fullNetFlowField]) || 0;
            } else if (a.hasOwnProperty(netFlowField) && b.hasOwnProperty(netFlowField)) {
              fieldA = Math.abs(a[netFlowField]) || 0;
              fieldB = Math.abs(b[netFlowField]) || 0;
            } else if (a.hasOwnProperty('net_flow_eth') && b.hasOwnProperty('net_flow_eth')) {
              fieldA = Math.abs(a.net_flow_eth) || 0;
              fieldB = Math.abs(b.net_flow_eth) || 0;
            } else {
              // 如果没有找到匹配的字段，尝试使用rank_num
              fieldA = -(a.rank_num || 999); // 通过负数转换，使rank_num小的排前面
              fieldB = -(b.rank_num || 999);
            }
            
            return fieldB - fieldA; // 降序排序
          }).slice(0, 10);

          console.log('排序后的前10条数据(流出):', sortedData);

          // 格式化数据以适应图表
          const formattedData = sortedData.map((item: any) => {
            let value = 0;
            
            // 尝试获取净流出金额
            if (item.hasOwnProperty(fullNetFlowField)) {
              value = Math.abs(item[fullNetFlowField]) * 2000; // ETH价格为2000美元
            } else if (item.hasOwnProperty(netFlowField)) {
              value = Math.abs(item[netFlowField]) * 2000;
            } else if (item.hasOwnProperty('net_flow_eth')) {
              value = Math.abs(item.net_flow_eth) * 2000;
            } else {
              // 如果没有找到匹配的字段，使用排名的反比例作为值
              value = (100 - (item.rank_num || 0)) * 100000 / 100;
            }
            
            // 取值下限为100，确保有显示效果
            if (value < 100) value = 100;
            
            return {
              name: item.collection_name || '未知收藏集',
              value: value,
              icon: item.collection_address || item.collection_name || 'UNKNOWN',
              logoUrl: item.logo_url,
              rank: item.rank_num
            };
          });
          
          console.log('最终格式化的图表数据(流出):', formattedData);
          setChartData(formattedData);
          setError(null); // 数据加载成功，清除错误状态
        } else {
          console.error('数据格式不正确或为空(流出):', response);
          setError('数据格式不正确或为空');
          // 使用备用模拟数据
          setChartData(getBackupData());
        }
      } catch (err) {
        console.error('获取数据失败(流出):', err);
        setError('获取数据失败');
        // 使用备用模拟数据
        setChartData(getBackupData());
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, [timeRange, whaleType]); // 时间范围或鲸鱼类型变化时重新获取数据

  // 备用模拟数据，当API调用失败时使用
  const getBackupData = () => {
    // 基础数据集 - 流出数据与流入数据略有不同
    let baseData: { name: string; value: number; icon: string }[] = [];

    // 根据时间范围选择基础数据集
    if (timeRange === 'day') {
      baseData = [
        { name: 'BAYC', value: 380000, icon: 'BAYC' },
        { name: 'CryptoPunks', value: 410000, icon: 'CryptoPunks' },
        { name: 'Moonbirds', value: 350000, icon: 'Moonbirds' },
        { name: 'Otherdeeds', value: 250000, icon: 'Otherdeeds' },
        { name: 'MAYC', value: 210000, icon: 'MAYC' },
        { name: 'CloneX', value: 180000, icon: 'CloneX' },
        { name: 'Azuki', value: 270000, icon: 'Azuki' },
        { name: 'Doodles', value: 130000, icon: 'Doodles' },
        { name: 'WoW', value: 140000, icon: 'WoW' },
        { name: 'CyberKongz', value: 90000, icon: 'CyberKongz' }
      ];
    } else if (timeRange === 'week') {
      baseData = [
        { name: 'CryptoPunks', value: 2050000, icon: 'CryptoPunks' },
        { name: 'BAYC', value: 1650000, icon: 'BAYC' },
        { name: 'Moonbirds', value: 1250000, icon: 'Moonbirds' },
        { name: 'MAYC', value: 1050000, icon: 'MAYC' },
        { name: 'Otherdeeds', value: 930000, icon: 'Otherdeeds' },
        { name: 'Azuki', value: 1300000, icon: 'Azuki' },
        { name: 'CloneX', value: 620000, icon: 'CloneX' },
        { name: 'Meebits', value: 480000, icon: 'Meebits' },
        { name: 'Doodles', value: 550000, icon: 'Doodles' },
        { name: 'Cool Cats', value: 320000, icon: 'Cool Cats' }
      ];
    } else {
      baseData = [
        { name: 'CryptoPunks', value: 5950000, icon: 'CryptoPunks' },
        { name: 'BAYC', value: 6100000, icon: 'BAYC' },
        { name: 'Azuki', value: 3500000, icon: 'Azuki' },
        { name: 'MAYC', value: 2750000, icon: 'MAYC' },
        { name: 'Moonbirds', value: 1950000, icon: 'Moonbirds' },
        { name: 'CloneX', value: 1850000, icon: 'CloneX' },
        { name: 'Otherdeeds', value: 2650000, icon: 'Otherdeeds' },
        { name: 'Doodles', value: 1250000, icon: 'Doodles' },
        { name: 'Meebits', value: 1350000, icon: 'Meebits' },
        { name: 'Goblintown', value: 880000, icon: 'Goblintown' }
      ];
    }

    // 根据鲸鱼类型进一步筛选和调整数据
    if (whaleType === 'smart') {
      // 聪明鲸鱼通常会选择在高点卖出优质项目
      return baseData.map(item => {
        const multiplier = ['CryptoPunks', 'BAYC', 'Azuki', 'Moonbirds', 'CloneX'].includes(item.name)
          ? 1.6  // 优质蓝筹项目加成
          : 0.6; // 其他项目减成
        return {
          ...item,
          value: Math.round(item.value * multiplier)
        };
      }).sort((a, b) => b.value - a.value).slice(0, 10);
    } else if (whaleType === 'dumb') {
      // 愚蠢鲸鱼通常会在低点卖出蓝筹项目
      const dumbData = baseData.map(item => {
        const multiplier = ['Goblintown', 'Cool Cats', 'Meebits', 'Doodles'].includes(item.name)
          ? 1.2  // 投机性项目普通卖出
          : 0.8; // 蓝筹项目在低点卖出
        return {
          ...item,
          value: Math.round(item.value * multiplier)
        };
      });
      // 添加一些特殊项目，愚蠢鲸鱼可能在亏损时卖出
      if (timeRange === 'day') {
        dumbData.push(
          { name: 'NFT Worlds', value: 150000, icon: 'Cryptoadz' },
          { name: 'Pixelmon', value: 130000, icon: 'Goblintown' }
        );
      } else if (timeRange === 'week') {
        dumbData.push(
          { name: 'Pixelmon', value: 450000, icon: 'Goblintown' },
          { name: 'NFT Worlds', value: 380000, icon: 'Cryptoadz' }
        );
      } else {
        dumbData.push(
          { name: 'Pixelmon', value: 1750000, icon: 'Goblintown' },
          { name: 'NFT Worlds', value: 1580000, icon: 'Cryptoadz' }
        );
      }
      return dumbData.sort((a, b) => b.value - a.value).slice(0, 10);
    } else {
      // 所有鲸鱼
      return baseData;
    }
  };

  // 获取图标URL的函数
  const getIconUrl = (collection: string, logoUrl?: string) => {
    // 如果有logo_url字段，优先使用
    if (logoUrl && logoUrl.startsWith('http')) {
      return logoUrl;
    }
    
    // 标准化集合名称（转为小写并移除空格）以便更好地匹配
    const normalizedCollection = collection.toLowerCase().replace(/\s+/g, '');
    
    const collections: { [key: string]: string } = {
      'bayc': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256',
      'azuki': 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256',
      'cryptopunks': 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?auto=format&dpr=1&w=256',
      'doodles': 'https://i.seadn.io/gae/7B0qai02OdHA8P_EOVK672qUliyjQdQDGNrACxs7WnTgZAkJa_wWURnIFKeOh5VTf8cfTqW3wQpozGEJpJpJnv_DqHDFWxcQplRFyw?auto=format&dpr=1&w=256',
      'clonex': 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?auto=format&dpr=1&w=256',
      'mayc': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=256',
      'moonbirds': 'https://i.seadn.io/gae/H-eyNE1MwL5ohL-tCfn_Xa1Sl9M9B4612tLYeUlQubzt4ewhr4huJIR5OLuyO3Z5PpJFSwdm7rq-TikAh7f5eUw338A2cy6HRH75?auto=format&dpr=1&w=256',
      'pudgypenguins': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=256',
      'otherdeeds': 'https://i.seadn.io/gae/yIm-M5-BpSDdTEIJRt5D6xphizhIdozXjqSITgK4phWq7MmAU3qE7Nw7POGCiPGyhtJ3ZFP8iJ29TFl-RLcGBWX5qI4-ZcnCPcsY4zI?auto=format&dpr=1&w=256',
      'wow': 'https://i.seadn.io/gae/EFAQpIktMraCrs8YLJy_FgjN9jOJW-O6cAZr9eriPZdkKvhJWEdre9wZOxTZL84HJN0GZxwNJXVPOZ8OQfYxgUMnR2JmrpdtWRK1?auto=format&dpr=1&w=256',
      'cyberkongz': 'https://i.seadn.io/gae/LIpf9z6Ux8uxn69auBME9FCTXpXqSYFo8ZLO1GaM8T7S3hiKScHaClXe0ZdhTv5br6FE2g5i-J5SobhKFsYfe6CIMCv-UfnrlYFWOM4?auto=format&dpr=1&w=256',
      'coolcats': 'https://i.seadn.io/gae/LIov33kogXOK4XZd2ESj29sqm_Hww5JSdO7AFn5wjt8xgnJJ0UpNV9yITqxra3s_LMEW1AnnrgOVB_hDpjJRA1uF4skI5Sdi_9rULi8?auto=format&dpr=1&w=256',
      'meebits': 'https://i.seadn.io/gae/d784iHHbqQFVH1XYD6HoT4u3y_Fsu_9FZUltWjnOzoYv7qqB5dLUqpOJ16kTQAGr-NORVYHOwzOqRkigvUrYoBCYAAltp8Zf-ZV3?auto=format&dpr=1&w=256',
      'cryptoadz': 'https://i.seadn.io/gae/iofetZEyiEIGcNyJKpbOafb_efJyeo7QOYnTog8qcQJhqoBU-Vu7mnijXM7SouWRtHKCuLIC9XDcGILXfyg0bnBZ6IPrWMA5VaCgygE?auto=format&dpr=1&w=256',
      'goblintown': 'https://i.seadn.io/gae/cb_wdEAmvry_noTCq1EDPD3eF04Wg3YxHPzGW9QjIjX9-hU-Q5y_rLpbEWhnmcSuYWRiV7bjZ6T41w8tgMqjEIHFWzG_AQT-qm1KnKU?auto=format&dpr=1&w=256',
      'degods': 'https://i.seadn.io/gae/FVTsD1oMUJHZiBkMibDgXimXQnJzYM9XxoMxTMR-JzHIQW-FGb0jlDfNTRbGZQBgQMKy6oVYDiCDfGTcSUAWatIKcGy4LMrAYnYl?auto=format&dpr=1&w=256',
      'milady': 'https://i.seadn.io/gae/a_frplnavZA9g4vN3SexO5rrtaBX_cBTaJYcgrPtwQIqPhzgzUendQxiwUdr51CGPE2QyPEa1DHnkW1wLrHAv5DgfC3BP-CRqDIVfGo?auto=format&dpr=1&w=256',
      'boredapeyachtclub': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256',
      'mutantapeyachtclub': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=256',
      'fidenza': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=256',
      'chromiesquiggle': 'https://i.seadn.io/gae/0qG8Y78s198F2R0xTOhje0UeK7GWpgKdLTdL2NF8e_siutxvxE5wNKoH_5XgLvCcB-jOq6hbidLuFAr2rzQBQkYNwu6_tUJhGnyom4I?auto=format&dpr=1&w=256',
      'autoglyphs': 'https://i.seadn.io/gae/JYz5dU8xK0FCzFp4NiOGkZGzVB77JQ2PMz9tMr7N2em9mvg8BpWHReqQOOK8RXwEMJbUqSY3ZFZyQB3c0jZ-lBb-MaijEOYc9bvzMA?auto=format&dpr=1&w=256',
      'nouns': 'https://i.seadn.io/gae/dQQcSXxzJJBw2FXB-aZFh-jAXrGWss2RfZxDY4Ykr8uqJT8-cY1FJR9cq9qMXmUtKK9GBEEzZ7kTXKd_iBDxT3lw1XwWT-wB3FveqA?auto=format&dpr=1&w=256',
      'loot': 'https://i.seadn.io/gae/Nhz0VbI2GV_PfS_9LDpwJzpH6xxbx0Mxoz2WwXNxmiifeI-JxgJZXD5IutgNTYZEYc3mB73MTJKc7G_9Hbv5ArjnWqpZ6-1wBYx0IQ?auto=format&dpr=1&w=256',
      'hope': 'https://i.seadn.io/gcs/files/2d058acad86d29a218bd1fba24e9eb28.png?auto=format&dpr=1&w=256'
    };

    // 处理特殊情况
    if (normalizedCollection.includes('bored') && normalizedCollection.includes('ape')) return collections['bayc'];
    if (normalizedCollection.includes('mutant') && normalizedCollection.includes('ape')) return collections['mayc'];
    if (normalizedCollection.includes('cool') && normalizedCollection.includes('cat')) return collections['coolcats'];
    if (normalizedCollection.includes('cyber') && normalizedCollection.includes('kong')) return collections['cyberkongz'];
    if (normalizedCollection.includes('pudgy')) return collections['pudgypenguins'];
    if (normalizedCollection.includes('cryptopunk')) return collections['cryptopunks'];
    
    // 检查集合名称是否存在，不区分大小写
    for (const [key, url] of Object.entries(collections)) {
      if (normalizedCollection.includes(key.toLowerCase())) {
        return url;
      }
    }

    // 检查是否有匹配的图标，如果没有，尝试模糊匹配
    if (collections[normalizedCollection]) {
      return collections[normalizedCollection];
    }
    
    // 尝试部分匹配
    for (const [key, url] of Object.entries(collections)) {
      if (normalizedCollection.includes(key) || key.includes(normalizedCollection)) {
        return url;
      }
    }

    // 如果找不到匹配的图标，使用默认图标
    const defaultLogo = 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256';
    console.log(`未找到"${collection}"的图标，使用默认图标`);
    return defaultLogo;
  };

  // 准备ECharts配置
  const getOption = () => {
    if (loading) {
      return {
        title: {
          text: '加载中...',
          left: 'center',
          textStyle: {
            color: '#fff'
          }
        }
      };
    }

    // 即使有错误状态，如果chartData有数据，优先使用实际数据
    const data = chartData.length > 0 ? chartData : getBackupData();
    
    // 仅在没有实际数据且有错误时才显示错误提示
    if (error && chartData.length === 0) {
      return {
        title: {
          text: '数据加载失败，显示备用数据',
          left: 'center',
          textStyle: {
            color: '#fff'
          }
        }
      };
    }
    
    // 数据排序
    data.sort((a, b) => a.value - b.value);

    // 准备图标配置
    const icons = data.map(item => getIconUrl(item.icon, item.logoUrl));

    // 美化：创建渐变色系
    const colors = [
      ['#f5222d', '#ff7875'], // 红色渐变
      ['#fa541c', '#ff9c6e'], // 橙色渐变
      ['#1890ff', '#36cfff'], // 蓝色渐变
      ['#52c41a', '#a0d911'], // 绿色渐变
      ['#722ed1', '#b37feb'], // 紫色渐变
      ['#13c2c2', '#5cdbd3'], // 青色渐变
      ['#eb2f96', '#ff85c0'], // 粉色渐变
      ['#2f54eb', '#85a5ff'], // 深蓝渐变
      ['#fa8c16', '#ffc53d'], // 橙黄渐变
      ['#d48806', '#cf1322']  // 红色渐变
    ];

    return {
      title: {
        show: false // 不显示标题
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow',
          shadowStyle: {
            color: 'rgba(24, 144, 255, 0.1)'
          }
        },
        formatter: function (params: any) {
          const dataIndex = params[0].dataIndex;
          // 确保data是已定义的
          if (!data || !data[dataIndex]) return '';

          const value = data[dataIndex].value;
          const formattedValue = new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 0
          }).format(value);

          return `<div style="display: flex; align-items: center; padding: 8px 12px;">
                   <img src="${icons[dataIndex]}" style="width: 32px; height: 32px; margin-right: 12px; border-radius: 4px; box-shadow: 0 2px 8px rgba(0,0,0,0.15);" />
                   <div>
                     <div style="font-weight: bold; font-size: 14px; margin-bottom: 4px;">${data[dataIndex].name}</div>
                     <div style="font-size: 16px; color: #fff;">${formattedValue}</div>
                   </div>
                 </div>`;
        },
        backgroundColor: 'rgba(0, 21, 41, 0.85)',
        borderColor: 'rgba(24, 144, 255, 0.3)',
        borderWidth: 1,
        borderRadius: 8,
        textStyle: {
          color: 'rgba(255, 255, 255, 0.85)'
        },
        extraCssText: 'box-shadow: 0 4px 12px rgba(0,0,0,0.15); backdrop-filter: blur(4px);'
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '4%',
        top: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'value',
        axisLabel: {
          formatter: function (value: number) {
            if (value >= 1000000) {
              return '$' + (value / 1000000).toFixed(1) + 'M';
            } else if (value >= 1000) {
              return '$' + (value / 1000).toFixed(0) + 'K';
            }
            return '$' + value;
          },
          color: 'rgba(255, 255, 255, 0.75)',
          fontWeight: 'bold',
          fontSize: 12,
          margin: 14
        },
        axisLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.2)',
            width: 2
          }
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.08)',
            type: 'dashed'
          }
        },
        axisTick: {
          show: false
        }
      },
      yAxis: {
        type: 'category',
        data: data.map(item => ''),  // 空字符串，因为我们使用rich text显示图标
        axisLabel: {
          formatter: function (value: string, index: number) {
            return '{icon' + index + '|}';
          },
          rich: data.reduce((acc: any, item, index) => {
            acc['icon' + index] = {
              height: 32,
              width: 32,
              align: 'center',
              backgroundColor: {
                image: icons[index]
              },
              borderRadius: 4,
              shadowBlur: 5,
              shadowColor: 'rgba(0, 0, 0, 0.3)',
              shadowOffsetX: 2,
              shadowOffsetY: 2
            };
            return acc;
          }, {}),
          color: 'rgba(255, 255, 255, 0.8)',
          margin: 20
        },
        axisLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.2)',
            width: 2
          }
        },
        axisTick: {
          show: false
        },
        splitLine: {
          show: false
        }
      },
      series: [
        {
          name: '流出金额',
          type: 'bar',
          data: data.map((item, index) => ({
            value: item.value,
            itemStyle: {
              color: {
                type: 'linear',
                x: 0,
                y: 0,
                x2: 1,
                y2: 0,
                colorStops: [
                  { offset: 0, color: colors[index % colors.length][0] },
                  { offset: 1, color: colors[index % colors.length][1] }
                ]
              },
              borderRadius: [0, 8, 8, 0],
              shadowBlur: 10,
              shadowColor: 'rgba(0, 0, 0, 0.2)',
              shadowOffsetX: 5,
              shadowOffsetY: 5
            }
          })),
          label: {
            show: true,
            position: 'insideRight',
            formatter: function (params: any) {
              const dataIndex = params.dataIndex;
              // 确保data是已定义的
              if (!data || !data[dataIndex]) return '';
              return data[dataIndex].name;
            },
            color: '#fff',
            fontSize: 14,
            fontWeight: 'bold',
            textShadow: '1px 1px 3px rgba(0, 0, 0, 0.3)'
          },
          barWidth: '60%',
          emphasis: {
            itemStyle: {
              shadowBlur: 20,
              shadowColor: 'rgba(0, 0, 0, 0.3)'
            }
          },
          animationDelay: function (idx: number) {
            return idx * 100;
          }
        }
      ],
      animationEasing: 'elasticOut',
      animationDelayUpdate: function (idx: number) {
        return idx * 5;
      },
      animationDuration: 1500
    };
  };

  return (
    <div className="whale-outflow-chart">
      {loading && <TechLoading />}
    <ReactECharts
      option={getOption()}
      style={{ height: '400px', width: '100%' }}
      className="react-echarts"
    />
    </div>
  );
};

// 鲸鱼收益率Top10饼状图组件
const WhalesProfitRateChart: React.FC<{ timeRange: 'day' | 'week' | 'month' }> = ({ timeRange }) => {
  const [chartData, setChartData] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const chartRef = useRef<any>(null);
  
  // 使用useEffect获取数据
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        // 确定要使用的rank_timerange值
        const rankTimeRange = timeRange === 'day' ? 'DAY' : 
                             timeRange === 'week' ? '7DAYS' : '30DAYS';
        
        // 使用dataLakeApi从ads.ads_top_roi_whales表获取数据
        const response: any = await dataLakeApi.queryTableData('ads', 'ads_top_roi_whales', 30);
        
        // 检查数据是否有效
        if (Array.isArray(response) && response.length > 0) {
          // 筛选出特定时间范围的数据并按rank_num排序
          const filteredData = response
            .filter((item: any) => item.rank_timerange === rankTimeRange)
            .sort((a: any, b: any) => a.rank_num - b.rank_num)
            .slice(0, 10); // 只取前10名
          
          // 将数据转换为图表需要的格式
          const formattedData = filteredData.map((item: any) => ({
            name: item.wallet_address ? 
              `${item.wallet_address.substring(0, 6)}...${item.wallet_address.substring(item.wallet_address.length - 4)}` : 
              'Unknown',
            value: Number(item.roi_percentage) || 0,
            profit: Number(item.total_profit_eth) || 0
          }));
          
          console.log('鲸鱼收益率数据:', formattedData.map(item => 
            `${item.name}: +${item.value.toFixed(2)}%, 收益: ${item.profit.toFixed(2)} ETH`).join('\n'));
            
          setChartData(formattedData);
          
          // 如果已经有图表实例，直接更新数据
          if (chartRef.current && chartRef.current.getEchartsInstance) {
            const echartsInstance = chartRef.current.getEchartsInstance();
            echartsInstance.setOption(getOption(formattedData));
          }
        } else {
          // 如果没有数据，使用模拟数据
          const mockData = getMockData();
          setChartData(mockData);
          
          // 如果已经有图表实例，直接更新数据
          if (chartRef.current && chartRef.current.getEchartsInstance) {
            const echartsInstance = chartRef.current.getEchartsInstance();
            echartsInstance.setOption(getOption(mockData));
          }
        }
      } catch (error) {
        console.error('获取鲸鱼收益率数据失败', error);
        // 出错时使用模拟数据
        const mockData = getMockData();
        setChartData(mockData);
        
        // 如果已经有图表实例，直接更新数据
        if (chartRef.current && chartRef.current.getEchartsInstance) {
          const echartsInstance = chartRef.current.getEchartsInstance();
          echartsInstance.setOption(getOption(mockData));
        }
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, [timeRange]);
  
  // 获取模拟数据的方法 - 保留原有的模拟数据作为备用
  const getMockData = () => {
    // 根据时间范围返回不同的收益率数据
    if (timeRange === 'day') {
      return [
        { name: 'WHALE-0x3694', value: 42.5, profit: 180000 },
        { name: 'WHALE-0x7842', value: 38.2, profit: 150000 },
        { name: 'WHALE-0x2469', value: 35.6, profit: 142000 },
        { name: 'WHALE-0x5678', value: 32.1, profit: 128000 },
        { name: 'WHALE-0x9127', value: 28.4, profit: 115000 },
        { name: 'WHALE-0x1234', value: 25.7, profit: 102000 },
        { name: 'WHALE-0x8276', value: 22.3, profit: 89000 },
        { name: 'WHALE-0x6723', value: 19.8, profit: 78000 },
        { name: 'WHALE-0x8765', value: 17.2, profit: 68000 },
        { name: 'WHALE-0x1498', value: 15.5, profit: 62000 }
      ];
    } else if (timeRange === 'week') {
      return [
        { name: 'WHALE-0x2469', value: 156.2, profit: 850000 },
        { name: 'WHALE-0x7842', value: 142.8, profit: 780000 },
        { name: 'WHALE-0x3694', value: 128.5, profit: 720000 },
        { name: 'WHALE-0x5678', value: 115.3, profit: 650000 },
        { name: 'WHALE-0x9127', value: 98.7, profit: 580000 },
        { name: 'WHALE-0x1234', value: 87.4, profit: 520000 },
        { name: 'WHALE-0x8276', value: 76.2, profit: 450000 },
        { name: 'WHALE-0x6723', value: 68.5, profit: 380000 },
        { name: 'WHALE-0x8765', value: 57.8, profit: 320000 },
        { name: 'WHALE-0x1498', value: 48.6, profit: 280000 }
      ];
    } else {
      return [
        { name: 'WHALE-0x2469', value: 325.8, profit: 2850000 },
        { name: 'WHALE-0x7842', value: 298.4, profit: 2450000 },
        { name: 'WHALE-0x3694', value: 276.5, profit: 2180000 },
        { name: 'WHALE-0x5678', value: 245.2, profit: 1950000 },
        { name: 'WHALE-0x9127', value: 218.7, profit: 1720000 },
        { name: 'WHALE-0x1234', value: 196.4, profit: 1580000 },
        { name: 'WHALE-0x8276', value: 178.2, profit: 1420000 },
        { name: 'WHALE-0x6723', value: 156.5, profit: 1280000 },
        { name: 'WHALE-0x8765', value: 142.8, profit: 1150000 },
        { name: 'WHALE-0x1498', value: 128.6, profit: 980000 }
      ];
    }
  };

  const getOption = (data = chartData) => {
    // 检查数据是否有效
    if (!data || data.length === 0) {
      return {
        title: {
          text: '暂无数据',
          left: 'center',
          top: 'center',
          textStyle: {
            color: 'rgba(255, 255, 255, 0.5)',
            fontSize: 16
          }
        }
      };
    }
    
    const totalProfit = data.reduce((sum, item) => sum + item.profit, 0);

    return {
      title: {
        show: false // 不显示标题
      },
      tooltip: {
        trigger: 'item',
        formatter: (params: any) => {
          const item = data.find(d => d.name === params.name);
          const percent = ((params.value / data.reduce((sum, item) => sum + item.value, 0)) * 100).toFixed(1);
          return `<div style="display: flex; flex-direction: column; gap: 8px; padding: 8px 12px;">
                   <div style="font-size: 14px; font-weight: bold; color: #fff;">${params.name}</div>
                   <div style="display: flex; justify-content: space-between; gap: 16px;">
                     <span style="color: rgba(255, 255, 255, 0.85);">收益率:</span>
                     <span style="color: #52c41a; font-weight: bold;">+${params.value.toFixed(2)}%</span>
                   </div>
                   <div style="display: flex; justify-content: space-between; gap: 16px;">
                     <span style="color: rgba(255, 255, 255, 0.85);">收益额:</span>
                     <span style="color: #1890ff; font-weight: bold;">${item?.profit.toFixed(2)} ETH</span>
                   </div>
                   <div style="display: flex; justify-content: space-between; gap: 16px;">
                     <span style="color: rgba(255, 255, 255, 0.85);">占比:</span>
                     <span style="color: #722ed1; font-weight: bold;">${percent}%</span>
                   </div>
                 </div>`;
        },
        backgroundColor: 'rgba(0, 21, 41, 0.9)',
        borderColor: 'rgba(24, 144, 255, 0.3)',
        borderWidth: 1,
        borderRadius: 8,
        textStyle: {
          color: 'rgba(255, 255, 255, 0.85)'
        },
        extraCssText: 'box-shadow: 0 4px 12px rgba(0,0,0,0.15); backdrop-filter: blur(4px);'
      },
      legend: {
        type: 'scroll',
        orient: 'vertical',
        right: 10,
        top: 'center',
        data: data.map(item => item.name),
        textStyle: {
          color: 'rgba(255, 255, 255, 0.65)',
          fontSize: 12
        },
        itemWidth: 14,
        itemHeight: 14,
        pageIconColor: 'rgba(24, 144, 255, 0.8)',
        pageIconInactiveColor: 'rgba(24, 144, 255, 0.3)',
        pageIconSize: 12,
        pageTextStyle: {
          color: 'rgba(255, 255, 255, 0.65)'
        },
        itemGap: 12,
        formatter: (name: string) => {
          const item = data.find(d => d.name === name);
          return `${name}  +${item?.value.toFixed(2)}%`;
        },
        selectedMode: true,
        select: {
          itemStyle: {
            shadowBlur: 10,
            shadowColor: 'rgba(24, 144, 255, 0.5)'
          }
        }
      },
      series: [
        {
          name: timeRange === 'day' ? '当天收益率' : timeRange === 'week' ? '近一周收益率' : '近一月收益率',
          type: 'pie',
          radius: ['40%', '70%'],
          center: ['40%', '50%'],
          avoidLabelOverlap: true,
          itemStyle: {
            borderRadius: 8,
            borderColor: '#001529',
            borderWidth: 2,
            shadowBlur: 10,
            shadowColor: 'rgba(0, 0, 0, 0.3)'
          },
          label: {
            show: false,
            position: 'center',
            fontSize: 14,
            color: 'rgba(255, 255, 255, 0.85)',
            fontWeight: 'bold'
          },
          emphasis: {
            label: {
              show: true,
              formatter: (params: any) => {
                return [
                  `{name|${params.name}}`,
                  `{value|+${params.value.toFixed(2)}%}`
                ].join('\n');
              },
              rich: {
                name: {
                  fontSize: 14,
                  color: 'rgba(255, 255, 255, 0.85)',
                  fontWeight: 'bold',
                  padding: [4, 0]
                },
                value: {
                  fontSize: 20,
                  color: '#52c41a',
                  fontWeight: 'bold',
                  padding: [4, 0]
                }
              }
            },
            itemStyle: {
              shadowBlur: 20,
              shadowColor: 'rgba(24, 144, 255, 0.5)'
            }
          },
          labelLine: {
            show: false
          },
          data: data.map((item, index) => ({
            name: item.name,
            value: item.value,
            itemStyle: {
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                {
                  offset: 0,
                  color: [
                    '#52c41a', '#1890ff', '#722ed1', '#eb2f96', '#faad14',
                    '#13c2c2', '#f5222d', '#a0d911', '#2f54eb', '#fa541c'
                  ][index % 10]
                },
                {
                  offset: 1,
                  color: [
                    '#389e0d', '#096dd9', '#531dab', '#c41d7f', '#d48806',
                    '#08979c', '#cf1322', '#7cb305', '#1d39c4', '#d4380d'
                  ][index % 10]
                }
              ])
            }
          }))
        }
      ],
      animation: true,
      animationDuration: 1500,
      animationEasing: 'cubicInOut',
      animationDelay: (idx: number) => idx * 100,
      universalTransition: true
    };
  };

  // 当数据变化时手动更新图表
  useEffect(() => {
    if (chartRef.current && chartRef.current.getEchartsInstance) {
      const echartsInstance = chartRef.current.getEchartsInstance();
      echartsInstance.setOption(getOption());
    }
  }, [chartData]);

  return (
    <>
      {loading ? (
        <TechLoading />
      ) : (
    <ReactECharts
          ref={chartRef}
      option={getOption()}
      style={{ height: '300px', width: '100%' }}
      className="react-echarts"
          notMerge={true}
          lazyUpdate={false}
    />
      )}
    </>
  );
};

// 钱包分析模态框组件
const WalletAnalysisModal: React.FC<{
  visible: boolean;
  onClose: () => void;
  walletAddress: string;
  walletLabel: string;
}> = ({ visible, onClose, walletAddress, walletLabel }) => {
  const [loading, setLoading] = useState(true);
  const [walletData, setWalletData] = useState<any>(null);

  useEffect(() => {
    if (visible) {
      // 模拟API请求加载钱包数据
      const timer = setTimeout(() => {
        // 模拟钱包数据
        setWalletData({
          totalTransactions: 128,
          totalVolume: 3456789,
          holdingValue: 1234567,
          tradingTrends: [
            { date: '5月2日', value: 123456 },
            { date: '5月3日', value: 234567 },
            { date: '5月4日', value: 345678 },
            { date: '5月5日', value: 456789 },
            { date: '5月6日', value: 567890 },
            { date: '5月7日', value: 678901 },
            { date: '6月1日', value: 789012 }
          ],
          nftHoldings: [
            { name: 'CryptoPunks', value: 3 },
            { name: 'Azuki', value: 5 },
            { name: 'BAYC', value: 2 },
            { name: 'Doodles', value: 4 },
            { name: 'CloneX', value: 1 }
          ],
          recentTransactions: [
            { id: 1, time: '2023-06-07 14:23', type: '买入', collection: 'Azuki', tokenId: '#8364', price: 12.5 },
            { id: 2, time: '2023-06-06 09:45', type: '卖出', collection: 'BAYC', tokenId: '#2354', price: 78.2 },
            { id: 3, time: '2023-06-05 18:12', type: '买入', collection: 'Doodles', tokenId: '#6542', price: 8.7 },
            { id: 4, time: '2023-06-04 11:38', type: '买入', collection: 'CryptoPunks', tokenId: '#3542', price: 65.4 },
            { id: 5, time: '2023-06-03 20:05', type: '卖出', collection: 'CloneX', tokenId: '#1267', price: 9.3 }
          ]
        });
        setLoading(false);
      }, 1500);

      return () => clearTimeout(timer);
    }
  }, [visible]);

  const getHoldingsChartOption = () => {
    if (!walletData) return {};

    return {
      tooltip: {
        trigger: 'item',
        formatter: '{a} <br/>{b}: {c} ({d}%)',
        backgroundColor: 'rgba(0, 21, 41, 0.7)',
        borderColor: 'rgba(24, 144, 255, 0.2)',
        textStyle: {
          color: 'rgba(255, 255, 255, 0.85)'
        }
      },
      legend: {
        orient: 'vertical',
        right: 10,
        top: 'center',
        data: walletData.nftHoldings.map((item: any) => item.name),
        textStyle: {
          color: 'rgba(255, 255, 255, 0.65)',
          fontSize: 12
        },
        itemWidth: 14,
        itemHeight: 14
      },
      series: [
        {
          name: 'NFT持有',
          type: 'pie',
          radius: ['40%', '70%'],
          avoidLabelOverlap: false,
          label: {
            show: false
          },
          emphasis: {
            label: {
              show: true,
              fontSize: 12,
              fontWeight: 'bold'
            }
          },
          labelLine: {
            show: false
          },
          data: walletData.nftHoldings.map((item: any) => ({
            name: item.name,
            value: item.value
          })),
          itemStyle: {
            borderRadius: 4,
            borderColor: '#001529',
            borderWidth: 2
          }
        }
      ],
      color: ['#1890ff', '#52c41a', '#faad14', '#f5222d', '#722ed1']
    };
  };

  return (
    <Modal
      title={
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <WalletOutlined style={{ color: '#1890ff', marginRight: 8 }} />
          <Text style={{ color: 'rgba(255, 255, 255, 0.85)' }}>
            钱包分析 - {walletLabel} ({walletAddress})
          </Text>
        </div>
      }
      visible={visible}
      onCancel={onClose}
      footer={null}
      width={900}
      centered
      bodyStyle={{
        padding: '20px',
        background: '#001529',
        maxHeight: '80vh',
        overflowY: 'auto'
      }}
    >
      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <Spin size="large" />
          <div style={{ marginTop: 16, color: 'rgba(255, 255, 255, 0.65)' }}>加载钱包数据中...</div>
        </div>
      ) : (
        <>
          <Row gutter={16} style={{ marginBottom: 24 }}>
            <Col span={8}>
              <Card
                className="tech-card"
                bordered={false}
                style={{ height: '100%' }}
              >
                <Statistic
                  title={<Text style={{ color: 'var(--text-secondary)' }}>总交易次数</Text>}
                  value={walletData.totalTransactions}
                  prefix={<TransactionOutlined style={{ color: 'var(--primary)' }} />}
                  valueStyle={{ color: 'var(--primary)', textShadow: 'var(--text-shadow-primary)' }}
                />
              </Card>
            </Col>
            <Col span={8}>
              <Card
                className="tech-card"
                bordered={false}
                style={{ height: '100%' }}
              >
                <Statistic
                  title={<Text style={{ color: 'var(--text-secondary)' }}>总交易额</Text>}
                  value={walletData.totalVolume}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: 'var(--success)' }} />}
                  suffix="$"
                  valueStyle={{ color: 'var(--success)', textShadow: 'var(--text-shadow-success)' }}
                />
              </Card>
            </Col>
            <Col span={8}>
              <Card
                className="tech-card"
                bordered={false}
                style={{ height: '100%' }}
              >
                <Statistic
                  title={<Text style={{ color: 'var(--text-secondary)' }}>当前持有价值</Text>}
                  value={walletData.holdingValue}
                  precision={0}
                  prefix={<PieChartOutlined style={{ color: 'var(--warning)' }} />}
                  suffix="$"
                  valueStyle={{ color: 'var(--warning)', textShadow: 'var(--text-shadow-warning)' }}
                />
              </Card>
            </Col>
          </Row>

          <Row gutter={16} style={{ marginBottom: 24 }}>
            <Col span={16}>
              <Card
                title={
                  <div style={{ display: 'flex', alignItems: 'center' }}>
                    <AreaChartOutlined style={{ color: 'var(--primary)', marginRight: 8 }} />
                    <Text style={{ color: 'var(--text-primary)' }}>交易趋势分析</Text>
                  </div>
                }
                className="tech-card"
                bordered={false}
              >
                <ReactECharts
                  option={{
                    tooltip: {
                      trigger: 'axis',
                      backgroundColor: 'rgba(0, 21, 41, 0.7)',
                      borderColor: 'rgba(24, 144, 255, 0.2)',
                      textStyle: {
                        color: 'rgba(255, 255, 255, 0.85)'
                      }
                    },
                    grid: {
                      left: '3%',
                      right: '4%',
                      bottom: '3%',
                      containLabel: true
                    },
                    xAxis: {
                      type: 'category',
                      boundaryGap: false,
                      data: walletData.tradingTrends.map((item: any) => item.date),
                      axisLine: {
                        lineStyle: {
                          color: 'rgba(255, 255, 255, 0.2)'
                        }
                      },
                      axisLabel: {
                        color: 'rgba(255, 255, 255, 0.65)'
                      }
                    },
                    yAxis: {
                      type: 'value',
                      axisLine: {
                        lineStyle: {
                          color: 'rgba(255, 255, 255, 0.2)'
                        }
                      },
                      axisLabel: {
                        color: 'rgba(255, 255, 255, 0.65)',
                        formatter: '${value}'
                      },
                      splitLine: {
                        lineStyle: {
                          color: 'rgba(255, 255, 255, 0.1)'
                        }
                      }
                    },
                    series: [
                      {
                        name: '交易金额',
                        type: 'line',
                        smooth: true,
                        lineStyle: {
                          width: 3,
                          shadowColor: 'rgba(24, 144, 255, 0.5)',
                          shadowBlur: 10
                        },
                        symbol: 'circle',
                        symbolSize: 8,
                        itemStyle: {
                          color: 'var(--primary)',
                          borderColor: '#fff',
                          borderWidth: 2
                        },
                        areaStyle: {
                          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                            {
                              offset: 0,
                              color: 'rgba(24, 144, 255, 0.4)'
                            },
                            {
                              offset: 1,
                              color: 'rgba(24, 144, 255, 0.1)'
                            }
                          ])
                        },
                        data: walletData.tradingTrends.map((item: any) => item.value)
                      }
                    ]
                  }}
                  style={{ height: '250px', width: '100%' }}
                  className="react-echarts"
                />
              </Card>
            </Col>
            <Col span={8}>
              <Card
                title={
                  <div style={{ display: 'flex', alignItems: 'center' }}>
                    <PieChartOutlined style={{ color: 'var(--primary)', marginRight: 8 }} />
                    <Text style={{ color: 'var(--text-primary)' }}>NFT持有分布</Text>
                  </div>
                }
                className="tech-card"
                bordered={false}
              >
                <ReactECharts
                  option={getHoldingsChartOption()}
                  style={{ height: '250px', width: '100%' }}
                  className="react-echarts"
                />
              </Card>
            </Col>
          </Row>

          <Card
            title={
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <HistoryOutlined style={{ color: 'var(--primary)', marginRight: 8 }} />
                <Text style={{ color: 'var(--text-primary)' }}>近期交易</Text>
              </div>
            }
            className="tech-card"
            bordered={false}
          >
            <List
              itemLayout="horizontal"
              dataSource={walletData.recentTransactions}
              renderItem={(item: any) => (
                <List.Item>
                  <List.Item.Meta
                    avatar={
                      <Avatar
                        style={{
                          backgroundColor: item.type === '买入' ? 'var(--success)' : 'var(--danger)',
                          boxShadow: `0 0 10px ${item.type === '买入' ? 'rgba(82, 196, 26, 0.3)' : 'rgba(245, 34, 45, 0.3)'}`
                        }}
                        icon={item.type === '买入' ? <PlusOutlined /> : <MinusOutlined />}
                      />
                    }
                    title={
                      <Text style={{
                        color: 'var(--text-primary)',
                        fontSize: 14,
                        fontWeight: 500
                      }}>
                        {item.type} - {item.collection} {item.tokenId}
                      </Text>
                    }
                    description={
                      <Space>
                        <Text style={{ color: 'var(--text-secondary)', fontSize: 12 }}>{item.time}</Text>
                        <Divider type="vertical" style={{ borderLeftColor: 'rgba(255, 255, 255,.08)' }} />
                        <Text style={{
                          color: item.type === '买入' ? 'var(--success)' : 'var(--danger)',
                          fontSize: 14,
                          fontWeight: 500
                        }}>
                          {item.type === '买入' ? '+' : '-'} {item.price} ETH
                        </Text>
                      </Space>
                    }
                  />
                </List.Item>
              )}
            />
          </Card>
        </>
      )}
    </Modal>
  );
};

// 鲸鱼列表模态框组件
const WhaleListModal: React.FC<{
  visible: boolean;
  onClose: () => void;
  type: 'tracked' | 'smart' | 'dumb' | 'all';
  onSelectWhale: (whaleId: string) => void;
  trackedWhales: string[];
  trackedWhalesData?: any[]; // 添加可选的完整鲸鱼数据参数
}> = ({ visible, onClose, type, onSelectWhale, trackedWhales, trackedWhalesData = [] }) => {
  const [loading, setLoading] = useState(true);
  const [whaleList, setWhaleList] = useState<any[]>([]);

  // 根据类型获取标题
  const getTitle = () => {
    switch (type) {
      case 'tracked':
        return '重点追踪鲸鱼列表';
      case 'smart':
        return '聪明鲸鱼列表';
      case 'dumb':
        return '愚蠢鲸鱼列表';
      case 'all':
        return '所有鲸鱼列表';
      default:
        return '鲸鱼列表';
    }
  };

  // 根据类型获取图标
  const getIcon = () => {
    switch (type) {
      case 'tracked':
        return <UserOutlined style={{ color: 'var(--primary)' }} />;
      case 'smart':
        return <BulbOutlined style={{ color: 'var(--success)' }} />;
      case 'dumb':
        return <SmileOutlined style={{ color: 'var(--warning)', transform: 'rotate(180deg)' }} />;
      case 'all':
        return <UserOutlined style={{ color: 'var(--danger)' }} />;
      default:
        return <UserOutlined />;
    }
  };

  // 渲染影响力星级
  const renderStars = (influence: number) => {
    const starCount = Math.round(influence / 20);
    return (
      <div>
        {[...Array(5)].map((_, i) => (
          <StarFilled 
            key={i}
            style={{ 
              color: i < starCount ? 'var(--warning)' : 'var(--text-quaternary)',
              marginRight: 2
            }} 
          />
        ))}
      </div>
    );
  };

  useEffect(() => {
    if (visible) {
      // 加载状态
      setLoading(true);
      
      // 定义一个函数来获取真实数据
      const fetchRealWhaleData = async () => {
        try {
          // 如果是重点追踪鲸鱼类型，且有传入的trackedWhalesData数据，优先使用
          if (type === 'tracked' && trackedWhalesData && trackedWhalesData.length > 0) {
            console.log('使用从Dashboard传入的完整鲸鱼数据:', trackedWhalesData.length, '条');
            
            // 转换数据格式（如果需要）
            const formattedData = trackedWhalesData.map((item, index) => ({
              key: index.toString(),
              ...item
            }));
            
            setWhaleList(formattedData);
            setLoading(false);
            return;
          }
          
          // 如果没有传入数据或不是重点追踪类型，从API获取数据
          // 从数据湖API获取ads_whale_tracking_list表数据
          const response: any = await dataLakeApi.queryTableData('ads', 'ads_whale_tracking_list', 1000);
          
          if (Array.isArray(response) && response.length > 0) {
            console.log('获取到的鲸鱼追踪列表数据:', response.length, '条');
            
            // 根据传入的type类型筛选数据
            let filteredData = response;
            
            if (type === 'smart') {
              filteredData = response.filter(item => item.wallet_type === 'SMART');
            } else if (type === 'dumb') {
              filteredData = response.filter(item => item.wallet_type === 'DUMB');
            } else if (type === 'tracked') {
              // 使用用户手动追踪的鲸鱼列表，而不是数据库中的TRACKING类型
              if (trackedWhales && trackedWhales.length > 0) {
                // 筛选出地址在trackedWhales中的鲸鱼
                filteredData = response.filter(item => 
                  trackedWhales.includes(item.wallet_address)
                );
                console.log(`显示用户手动追踪的 ${filteredData.length} 只鲸鱼，而不是数据库中的TRACKING类型`);
              } else {
                // 如果用户没有手动追踪任何鲸鱼，则返回空数组
                filteredData = [];
                console.log('用户尚未追踪任何鲸鱼，显示空列表');
              }
            }
            
            // 转换为前端需要的格式
            const transformedData = filteredData.map((item, index) => ({
              key: index.toString(),
              whaleId: `WHALE-${item.tracking_id || item.wallet_address.substring(0, 8)}`,
              whaleAddress: item.wallet_address,
              trackingTime: item.first_track_date ? new Date(item.first_track_date).toISOString().split('T')[0] : '',
              influence: item.influence_score || 0,
              trackingProfit: Number(item.total_profit_usd) || 0,
              trackingProfitRate: Number(item.roi_percentage) || 0,
              // 保留原始数据以备需要
              rawData: item
            }));
            
            // 更新状态
            setWhaleList(transformedData);
          } else {
            console.warn('没有获取到鲸鱼追踪数据或数据格式不正确');
            // 获取失败时使用模拟数据
            useMockData();
          }
        } catch (error) {
          console.error('获取鲸鱼追踪数据失败:', error);
          // 获取失败时使用模拟数据
          useMockData();
        } finally {
          setLoading(false);
        }
      };
      
      // 模拟数据生成函数（作为备份）
      const useMockData = () => {
        console.log('使用模拟鲸鱼数据');
        // 这里保留原有的模拟数据生成逻辑
        let data: any[] = [];

        if (type === 'tracked') {
          // 如果是重点追踪鲸鱼列表，根据是否有用户追踪的鲸鱼来返回数据
          if (trackedWhales && trackedWhales.length > 0) {
            // 如果有用户追踪的鲸鱼，返回模拟数据
          data = [
            {
              key: '1',
              whaleId: 'WHALE-0x1234',
                whaleAddress: '0x1234...5678',
                trackingTime: '2023-04-15',
              influence: 89,
                trackingProfit: 420000,
                trackingProfitRate: 14.8
              },
              // ...其他模拟数据
            ];
          } else {
            // 如果没有用户追踪的鲸鱼，返回空数组
            data = [];
            console.log('用户未追踪任何鲸鱼，返回空模拟数据');
          }
        } else if (type === 'smart') {
          data = [
            {
              key: '1',
              whaleId: 'WHALE-0x2469',
              whaleAddress: '0x2469...7890',
              trackingTime: '2023-03-20',
              influence: 98,
              trackingProfit: 1250000,
              trackingProfitRate: 48.1
            },
            // ...其他模拟数据
          ];
        } else if (type === 'dumb') {
          data = [
            {
              key: '1',
              whaleId: 'WHALE-0x3254',
              whaleAddress: '0x3254...4321',
              trackingTime: '2023-02-10',
              influence: 45,
              trackingProfit: -380000,
              trackingProfitRate: -28.6
            },
            // ...其他模拟数据
          ];
        } else {
          // 全部类型的模拟数据
          data = [
            // ...模拟数据
          ];
        }

        setWhaleList(data);
        setLoading(false);
      };

      // 尝试获取真实数据
      fetchRealWhaleData();
    }
  }, [visible, type, trackedWhales, trackedWhalesData]);

  // 定义表格列
  const columns = [
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>鲸鱼ID</Text>,
      dataIndex: 'whaleId',
      key: 'whaleId',
      width: 180,
      render: (id: string) => (
        <Text
          style={{
            color: 'var(--primary)',
            cursor: 'pointer',
            textShadow: '0 0 8px rgba(24, 144, 255, 0.3)',
            textDecoration: 'underline'
          }}
          onClick={() => onSelectWhale(id)}
        >
          {id}
        </Text>
      ),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>影响力</Text>,
      dataIndex: 'influence',
      key: 'influence',
      width: 120,
      render: (influence: number) => renderStars(influence),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>鲸鱼地址</Text>,
      dataIndex: 'whaleAddress',
      key: 'whaleAddress',
      width: 180,
      render: (address: string) => (
        <Text style={{ color: 'var(--text-secondary)' }}>
          {address ? `${address.substring(0, 6)}...${address.substring(address.length - 4)}` : '-'}
        </Text>
      ),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>追踪时间</Text>,
      dataIndex: 'trackingTime',
      key: 'trackingTime',
      width: 120,
      render: (time: string, record: any) => {
        // 从原始数据中获取追踪时间
        const trackingDate = record.rawData?.first_track_date ? 
          new Date(record.rawData.first_track_date) : null;
          
        // 如果有追踪时间，格式化为YYYY-MM-DD
        const formattedDate = trackingDate ? 
          trackingDate.toISOString().split('T')[0] : 
          (time || '-');
          
        return (
          <Text style={{ color: 'var(--text-secondary)' }}>
            {formattedDate}
          </Text>
        );
      },
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>追踪以来收益</Text>,
      dataIndex: 'trackingProfit',
      key: 'trackingProfit',
      width: 150,
      render: (profit: number, record: any) => {
        // 从原始数据中获取收益额（优先使用total_profit_usd，备选用total_profit_eth并乘以假设的ETH价格2000）
        let actualProfit = profit;
        if (record.rawData) {
          if (record.rawData.total_profit_usd !== undefined) {
            actualProfit = Number(record.rawData.total_profit_usd);
          } else if (record.rawData.total_profit_eth !== undefined) {
            actualProfit = Number(record.rawData.total_profit_eth) * 2000; // 假设ETH价格为2000美元
          }
        }
        
        return (
          <Text
            style={{
              color: actualProfit >= 0 ? 'var(--success)' : 'var(--danger)',
              fontWeight: 'bold'
            }}
          >
            ${actualProfit ? actualProfit.toLocaleString() : '0'}
          </Text>
        );
      },
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>追踪以来收益率</Text>,
      dataIndex: 'trackingProfitRate',
      key: 'trackingProfitRate',
      width: 150,
      render: (rate: number, record: any) => {
        // 从原始数据中获取收益率
        let actualRate = rate;
        if (record.rawData && record.rawData.roi_percentage !== undefined) {
          actualRate = Number(record.rawData.roi_percentage);
        }
        
        return (
          <div style={{ display: 'flex', alignItems: 'center' }}>
            {actualRate >= 0 ? (
              <ArrowUpOutlined style={{ color: 'var(--success)', marginRight: 8 }} />
            ) : (
              <ArrowDownOutlined style={{ color: 'var(--danger)', marginRight: 8 }} />
            )}
            <Text
              style={{
                color: actualRate >= 0 ? 'var(--success)' : 'var(--danger)',
                fontWeight: 'bold'
              }}
            >
              {actualRate ? Math.abs(actualRate).toFixed(2) : '0.00'}%
            </Text>
          </div>
        );
      },
    }
  ];

  return (
    <Modal
      title={
        <div style={{ display: 'flex', alignItems: 'center' }}>
          {getIcon()}
          <Text style={{ color: 'rgba(255, 255, 255, 0.85)', marginLeft: 8 }}>
            {getTitle()}
          </Text>
        </div>
      }
      visible={visible}
      onCancel={onClose}
      footer={null}
      width={1200}
      className="tech-modal"
      style={{ top: 20 }}
    >
      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <Spin size="large" />
          <div style={{ marginTop: 16, color: 'rgba(255, 255, 255, 0.65)' }}>加载鲸鱼数据中...</div>
        </div>
      ) : (
        <Table
          columns={columns}
          dataSource={whaleList}
          pagination={{
            pageSize: 5,
            showSizeChanger: true,
            pageSizeOptions: ['5', '10', '20'],
            showTotal: (total) => `共 ${total} 只鲸鱼`,
            size: 'small',
            showQuickJumper: true,
          }}
          rowClassName="tech-table-row"
          style={{ background: 'transparent' }}
          scroll={{ x: 1080 }}
        />
      )}
    </Modal>
  );
};

const Dashboard: React.FC = () => {
  // 基础状态管理
  const [activeTab, setActiveTab] = useState('home');
  const [selectedTimeRange, setSelectedTimeRange] = useState<'day' | 'week' | 'month'>('day');
  const [selectedWhaleType, setSelectedWhaleType] = useState<'all' | 'smart' | 'dumb'>('all');
  
  // 数据加载状态
  const [loading, setLoading] = useState(true);
  const [statsData, setStatsData] = useState({
    activeWhales: 0,
    smartWhales: 0,
    dumbWhales: 0,
    successRate: 0,
    totalWhales: 0 // 添加所有鲸鱼字段
  });
  
  // 追踪鲸鱼状态
  const [trackedWhales, setTrackedWhales] = useState<string[]>([]);
  
  // 存储鲸鱼完整数据
  const [trackedWhalesData, setTrackedWhalesData] = useState<any[]>([]);
  
  // 钱包分析模态框状态
  const [modalVisible, setModalVisible] = useState(false);
  const [selectedWallet, setSelectedWallet] = useState<{ address: string, label: string }>({ address: '', label: '' });

  // 鲸鱼列表模态框状态
  const [whaleListModalVisible, setWhaleListModalVisible] = useState(false);
  const [whaleListType, setWhaleListType] = useState<'tracked' | 'smart' | 'dumb' | 'all'>('all');

  // 鲸鱼钱包模态框状态
  const [whaleAddressModalVisible, setWhaleAddressModalVisible] = useState(false);
  const [selectedWhaleId, setSelectedWhaleId] = useState<string | null>(null);

  // 鲸鱼交易额图表状态
  const [whalesVolumeTimeRange, setWhalesVolumeTimeRange] = useState<'day' | 'week' | 'month'>('week');

  // 鲸鱼收益率图表状态
  const [whalesProfitTimeRange, setWhalesProfitTimeRange] = useState<'day' | 'week' | 'month'>('week');

  // 鲸鱼流入/流出状态
  const [isInflow, setIsInflow] = useState(true);
  const [inflowTimeRange, setInflowTimeRange] = useState<'day' | 'week' | 'month'>('week');
  const [inflowWhaleType, setInflowWhaleType] = useState<'all' | 'smart' | 'dumb'>('all');

  // 监听鲸鱼追踪事件，更新重点追踪鲸鱼计数
  useEffect(() => {
    const handleWhaleTracked = (event: any) => {
      const { action, address, whaleData } = event.detail;
      
      if (action === 'add') {
        // 更新重点追踪鲸鱼计数
        setStatsData((prev: any) => ({
          ...prev,
          activeWhales: prev.activeWhales + 1
        }));
        
        // 如果有完整的鲸鱼数据，将其添加到追踪列表中
        if (whaleData) {
          console.log(`添加完整的鲸鱼数据到重点追踪列表:`, whaleData);
          
          // 添加到trackedWhales数组（地址）
          setTrackedWhales(prev => {
            if (prev.includes(address)) {
              return prev;
            }
            return [...prev, address];
          });
          
          // 添加完整的鲸鱼数据到trackedWhalesData状态
          setTrackedWhalesData(prev => {
            // 检查是否已存在相同地址的数据
            const existingIndex = prev.findIndex(whale => whale.whaleAddress === address);
            if (existingIndex >= 0) {
              // 如果已存在，更新数据
              const updatedData = [...prev];
              updatedData[existingIndex] = whaleData;
              return updatedData;
            } else {
              // 如果不存在，添加新数据
              return [...prev, whaleData];
            }
          });
        } else {
          console.log(`仅添加鲸鱼地址到重点追踪列表:`, address);
          
          // 仅添加地址
          setTrackedWhales(prev => {
            if (prev.includes(address)) {
              return prev;
            }
            return [...prev, address];
          });
        }
        
        console.log(`重点追踪鲸鱼增加，当前数量: ${statsData.activeWhales + 1}`);
      } else if (action === 'remove') {
        // 更新重点追踪鲸鱼计数
        setStatsData((prev: any) => ({
          ...prev,
          activeWhales: Math.max(0, prev.activeWhales - 1) // 确保不会出现负数
        }));
        
        // 从追踪列表中移除该鲸鱼地址
        setTrackedWhales(prev => prev.filter(addr => addr !== address));
        
        // 从完整数据列表中移除
        setTrackedWhalesData(prev => prev.filter(whale => whale.whaleAddress !== address));
        
        console.log(`重点追踪鲸鱼减少，当前数量: ${Math.max(0, statsData.activeWhales - 1)}`);
      }
    };
    
    // 添加事件监听器
    window.addEventListener('whaleTracked', handleWhaleTracked);
    
    // 清理函数
    return () => {
      window.removeEventListener('whaleTracked', handleWhaleTracked);
    };
  }, [statsData.activeWhales]); // 依赖于当前的activeWhales值

  // 加载模拟数据
  useEffect(() => {
    const timer = setTimeout(() => {
      // 设置模拟数据 - 根据正确的鲸鱼分类逻辑
      const mockSmartWhales = 8;     // 聪明鲸鱼
      const mockDumbWhales = 4;      // 愚蠢鲸鱼
      const mockTrackingWhales = 5;  // 追踪鲸鱼(从数据库获取但不单独展示的)
      // 所有鲸鱼 = 聪明鲸鱼 + 愚蠢鲸鱼 + 追踪鲸鱼
      const mockTotalWhales = mockSmartWhales + mockDumbWhales + mockTrackingWhales; // 总计17只鲸鱼
      
      setStatsData({
        activeWhales: 0,             // 重点追踪鲸鱼初始为0（用户尚未选择）
        smartWhales: mockSmartWhales,
        dumbWhales: mockDumbWhales,
        successRate: 85.7,
        totalWhales: mockTotalWhales // 所有鲸鱼 = 聪明鲸鱼(8) + 愚蠢鲸鱼(4) + 追踪鲸鱼(5) = 17
      });
      
      setLoading(false);
    }, 1500);

    return () => clearTimeout(timer);
  }, []);

  // 当组件加载时，获取初始数据
  useEffect(() => {
    // 初始化状态：所有鲸鱼列表包含所有鲸鱼，重点追踪鲸鱼列表为空
    const initializeWhaleData = async () => {
      try {
        // 从数据湖获取鲸鱼追踪列表数据
        const response: any = await dataLakeApi.queryTableData('ads', 'ads_whale_tracking_list', 1000);
        
        if (Array.isArray(response) && response.length > 0) {
          console.log('初始化鲸鱼分类：获取到鲸鱼数据', response.length, '条');
          
          // 重点追踪鲸鱼列表初始为空（用户尚未选择任何重点追踪的鲸鱼）
          setTrackedWhales([]);
          
          // 统计各类鲸鱼数量
          const smartWhales = response.filter(item => item.wallet_type === 'SMART').length;
          const dumbWhales = response.filter(item => item.wallet_type === 'DUMB').length;
          const trackingWhales = response.filter(item => item.wallet_type === 'TRACKING').length;
          
          // 计算所有鲸鱼的总数（聪明鲸鱼 + 愚蠢鲸鱼 + 追踪鲸鱼）
          const totalWhales = smartWhales + dumbWhales + trackingWhales;
          
          setStatsData((prev: any) => ({
            ...prev,
            activeWhales: 0, // 重点追踪鲸鱼初始为0（用户尚未选择任何鲸鱼）
            smartWhales: smartWhales,
            dumbWhales: dumbWhales,
            // 所有鲸鱼 = 聪明鲸鱼 + 愚蠢鲸鱼 + 追踪鲸鱼
            totalWhales: totalWhales
          }));
          
          console.log(`初始化完成：聪明鲸鱼 ${smartWhales} 只，愚蠢鲸鱼 ${dumbWhales} 只，追踪鲸鱼 ${trackingWhales} 只，所有鲸鱼 ${totalWhales} 只，重点追踪鲸鱼 0 只`);
        } else {
          console.warn('初始化鲸鱼数据失败：没有获取到鲸鱼数据');
          
          // 即使API调用失败，也确保设置默认值
          setStatsData((prev: any) => ({
            ...prev,
            activeWhales: 0,  // 重点追踪鲸鱼（用户选择的）
            smartWhales: 0,   // 聪明鲸鱼
            dumbWhales: 0,    // 愚蠢鲸鱼
            totalWhales: 0    // 所有鲸鱼
          }));
          
          setTrackedWhales([]);
        }
      } catch (error) {
        console.error('初始化鲸鱼数据失败:', error);
        
        // 出错时也确保设置默认值
        setStatsData((prev: any) => ({
          ...prev,
          activeWhales: 0,  // 重点追踪鲸鱼（用户选择的）
          smartWhales: 0,   // 聪明鲸鱼
          dumbWhales: 0,    // 愚蠢鲸鱼
          totalWhales: 0    // 所有鲸鱼
        }));
        
        setTrackedWhales([]);
      }
    };
    
    // 执行初始化
    initializeWhaleData();
  }, []);

  // 处理点击钱包地址
  const handleWalletClick = (address: string, label: string) => {
    setSelectedWallet({ address, label });
    setModalVisible(true);
  };

  // 处理点击鲸鱼统计卡片
  const handleWhaleCardClick = (type: 'tracked' | 'smart' | 'dumb' | 'all') => {
    setWhaleListType(type);
    setWhaleListModalVisible(true);
  };

  // 处理点击鲸鱼ID
  const handleWhaleClick = (whaleId: string) => {
    // 从鲸鱼ID提取一个地址（移除WHALE-前缀，保留后面的部分）
    const whaleAddress = whaleId.replace('WHALE-', '');
    
    // 为这个鲸鱼生成一个默认的标签名称
    const whaleLabel = `鲸鱼钱包 ${whaleId}`;
    
    // 直接打开钱包分析模态框
    setSelectedWallet({ address: whaleAddress, label: whaleLabel });
    setModalVisible(true);
    setWhaleListModalVisible(false); // 关闭鲸鱼列表模态框
  };

  // 模拟鲸鱼钱包关系数据
  const getWhaleAddresses = (whaleId: string) => {
    // 这里根据鲸鱼ID返回对应的钱包地址数据
    // 实际应用中，这些数据应该通过API获取
    const whaleMap: { [key: string]: any[] } = {
      'WHALE-0x1234': [
        {
          key: '1',
          address: '0x1234...5678',
          influenceScore: 86,
          holdingValue: 1250000,
          holdingChange: 25000,
          holdingProfit: 180000,
          netProfit: 120000
        },
        {
          key: '2',
          address: '0x8765...4321',
          influenceScore: 74,
          holdingValue: 880000,
          holdingChange: -15000,
          holdingProfit: 140000,
          netProfit: 95000
        },
        {
          key: '3',
          address: '0xabcd...efgh',
          influenceScore: 68,
          holdingValue: 1120000,
          holdingChange: 35000,
          holdingProfit: 110000,
          netProfit: 80000
        }
      ],
      'WHALE-0x5678': [
        {
          key: '1',
          address: '0x5678...1234',
          influenceScore: 92,
          holdingValue: 1750000,
          holdingChange: 50000,
          holdingProfit: 350000,
          netProfit: 210000
        },
        {
          key: '2',
          address: '0xefgh...abcd',
          influenceScore: 81,
          holdingValue: 1250000,
          holdingChange: 30000,
          holdingProfit: 260000,
          netProfit: 180000
        }
      ]
    };

    // 返回鲸鱼钱包数据，如果不存在则返回空数组
    return whaleMap[whaleId] || [];
  };

  // 表格列配置
  const columns = [
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>钱包地址</Text>,
      dataIndex: 'address',
      key: 'address',
      width: 180,
      render: (address: string, record: any) => (
        <Text
          style={{
            color: 'var(--primary)',
            cursor: 'pointer',
            textShadow: '0 0 8px rgba(24, 144, 255, 0.3)',
            textDecoration: 'underline'
          }}
          onClick={() => handleWalletClick(address, record.label || '鲸鱼钱包')}
        >
          {address}
        </Text>
      ),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>影响力评分</Text>,
      dataIndex: 'influenceScore',
      key: 'influenceScore',
      width: 140,
      render: (score: number) => {
        let color = 'var(--success)';
        if (score > 80) {
          color = 'var(--danger)';
        } else if (score > 60) {
          color = 'var(--warning)';
        }
        return (
          <Statistic
            value={score}
            valueStyle={{ fontSize: 16, color }}
            suffix={
              <Text style={{ fontSize: 12, color: 'var(--text-secondary)' }}>/100</Text>
            }
          />
        );
      },
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>持仓金额</Text>,
      dataIndex: 'holdingValue',
      key: 'holdingValue',
      width: 140,
      render: (value: number) => (
        <Statistic
          value={value}
          precision={0}
          valueStyle={{
            color: 'var(--warning)',
            fontSize: 16,
            textShadow: 'var(--text-shadow-warning)'
          }}
          suffix="$"
        />
      ),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>持仓变化</Text>,
      dataIndex: 'holdingChange',
      key: 'holdingChange',
      width: 140,
      render: (change: number) => <HoldingChange value={change} />,
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>持有收益</Text>,
      dataIndex: 'holdingProfit',
      key: 'holdingProfit',
      width: 140,
      render: (value: number) => (
        <Statistic
          value={value}
          precision={0}
          valueStyle={{
            color: 'var(--success)',
            fontSize: 16,
            textShadow: 'var(--text-shadow-success)'
          }}
          prefix={<ArrowUpOutlined />}
          suffix="$"
        />
      ),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>净收益</Text>,
      dataIndex: 'netProfit',
      key: 'netProfit',
      width: 140,
      render: (value: number) => (
        <Statistic
          value={value}
          precision={0}
          valueStyle={{
            color: 'var(--success)',
            fontSize: 16,
            textShadow: 'var(--text-shadow-success)'
          }}
          prefix={<ArrowUpOutlined />}
          suffix="$"
        />
      ),
    },
  ];

  if (loading) return <TechLoading />;

  return (
    <div style={{ color: 'var(--text-primary)' }}>
      <TechTitle>巨鲸追踪</TechTitle>
      <Row gutter={16} style={{ marginBottom: 24 }}>
        <Col span={6}>
          <Card
            className="tech-card"
            hoverable
            bordered={false}
            onClick={() => handleWhaleCardClick('tracked')}
            style={{ cursor: 'pointer' }}
          >
            <Statistic
              title={<Text style={{ color: 'var(--text-secondary)' }}>重点追踪鲸鱼</Text>}
              value={statsData.activeWhales}
              prefix={<UserOutlined style={{ color: 'var(--primary)' }} />}
              valueStyle={{ color: 'var(--primary)', textShadow: 'var(--text-shadow-primary)' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card
            className="tech-card"
            hoverable
            bordered={false}
            onClick={() => handleWhaleCardClick('smart')}
            style={{ cursor: 'pointer' }}
          >
            <Statistic
              title={<Text style={{ color: 'var(--text-secondary)' }}>聪明鲸鱼</Text>}
              value={statsData.smartWhales}
              prefix={<BulbOutlined style={{ color: 'var(--success)' }} />}
              valueStyle={{ color: 'var(--success)', textShadow: 'var(--text-shadow-success)' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card
            className="tech-card"
            hoverable
            bordered={false}
            onClick={() => handleWhaleCardClick('dumb')}
            style={{ cursor: 'pointer' }}
          >
            <Statistic
              title={<Text style={{ color: 'var(--text-secondary)' }}>愚蠢鲸鱼</Text>}
              value={statsData.dumbWhales}
              prefix={<SmileOutlined style={{ color: 'var(--warning)', transform: 'rotate(180deg)' }} />}
              valueStyle={{ color: 'var(--warning)', textShadow: 'var(--text-shadow-warning)' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card
            className="tech-card"
            hoverable
            bordered={false}
            onClick={() => handleWhaleCardClick('all')}
            style={{ cursor: 'pointer' }}
          >
            <Statistic
              title={<Text style={{ color: 'var(--text-secondary)' }}>所有鲸鱼</Text>}
              value={statsData.totalWhales}
              prefix={<UserOutlined style={{ color: 'var(--danger)' }} />}
              valueStyle={{ color: 'var(--danger)', textShadow: 'var(--text-shadow-danger)' }}
            />
          </Card>
        </Col>
      </Row>

      <Row gutter={16} style={{ marginBottom: 24 }}>
        <Col span={12}>
          <LiveTransactionStream />
        </Col>
        <Col span={12}>
          <Row gutter={[0, 16]}>
            <Col span={24}>
              {/* 前十鲸鱼交易额饼状图 */}
              <Card
                title={
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <PieChartOutlined style={{ color: 'var(--primary)', marginRight: 8 }} />
                      <Text style={{
                        color: 'var(--text-primary)',
                        fontSize: 16,
                        fontWeight: 500
                      }}>
                        鲸鱼收益额Top10
                      </Text>
                    </div>
                    <div>
                      <Radio.Group
                        value={whalesVolumeTimeRange}
                        onChange={(e) => setWhalesVolumeTimeRange(e.target.value)}
                        size="small"
                      >
                        <Radio.Button value="day" style={{ color: whalesVolumeTimeRange === 'day' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: whalesVolumeTimeRange === 'day' ? '#1890ff' : 'transparent' }}>当天</Radio.Button>
                        <Radio.Button value="week" style={{ color: whalesVolumeTimeRange === 'week' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: whalesVolumeTimeRange === 'week' ? '#1890ff' : 'transparent' }}>近一周</Radio.Button>
                        <Radio.Button value="month" style={{ color: whalesVolumeTimeRange === 'month' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: whalesVolumeTimeRange === 'month' ? '#1890ff' : 'transparent' }}>近一月</Radio.Button>
                      </Radio.Group>
                    </div>
                  </div>
                }
                className="tech-card"
                bordered={false}
              >
                <TopWhalesTradingVolumeChart timeRange={whalesVolumeTimeRange} />
              </Card>
            </Col>
            <Col span={24}>
              <Card
                title={
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <PieChartOutlined style={{ color: '#52c41a', marginRight: 8 }} />
                      <Text style={{
                        color: 'var(--text-primary)',
                        fontSize: 16,
                        fontWeight: 500
                      }}>
                        鲸鱼收益率Top10
                      </Text>
                    </div>
                    <div>
                      <Radio.Group
                        value={whalesProfitTimeRange}
                        onChange={(e) => setWhalesProfitTimeRange(e.target.value)}
                        size="small"
                      >
                        <Radio.Button value="day" style={{ color: whalesProfitTimeRange === 'day' ? '#fff' : '#52c41a', borderColor: '#52c41a', backgroundColor: whalesProfitTimeRange === 'day' ? '#52c41a' : 'transparent' }}>当天</Radio.Button>
                        <Radio.Button value="week" style={{ color: whalesProfitTimeRange === 'week' ? '#fff' : '#52c41a', borderColor: '#52c41a', backgroundColor: whalesProfitTimeRange === 'week' ? '#52c41a' : 'transparent' }}>近一周</Radio.Button>
                        <Radio.Button value="month" style={{ color: whalesProfitTimeRange === 'month' ? '#fff' : '#52c41a', borderColor: '#52c41a', backgroundColor: whalesProfitTimeRange === 'month' ? '#52c41a' : 'transparent' }}>近一月</Radio.Button>
                      </Radio.Group>
                    </div>
                  </div>
                }
                className="tech-card"
                bordered={false}
              >
                <WhalesProfitRateChart timeRange={whalesProfitTimeRange} />
              </Card>
            </Col>
          </Row>
        </Col>
      </Row>

      <Row gutter={16} style={{ marginBottom: 24 }}>
        <Col span={24}>
          <Card
            title={
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <BarChartOutlined style={{ color: 'var(--primary)', marginRight: 8 }} />
                  <Text style={{
                    color: 'var(--text-primary)',
                    fontSize: 16,
                    fontWeight: 500
                  }}>
                    鲸鱼{isInflow ? '净流入' : '净流出'}Top10收藏集
                  </Text>
                </div>
                <div>
                  <Space>
                    {/* 添加流入/流出切换按钮 */}
                    <Radio.Group
                      value={isInflow ? 'inflow' : 'outflow'}
                      onChange={(e) => setIsInflow(e.target.value === 'inflow')}
                      size="small"
                      style={{ marginRight: 24 }}
                    >
                      <Radio.Button value="inflow" style={{ color: isInflow ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: isInflow ? '#1890ff' : 'transparent' }}>净流入</Radio.Button>
                      <Radio.Button value="outflow" style={{ color: !isInflow ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: !isInflow ? '#1890ff' : 'transparent' }}>净流出</Radio.Button>
                    </Radio.Group>

                    <Radio.Group
                      value={inflowWhaleType}
                      onChange={(e) => setInflowWhaleType(e.target.value)}
                      size="small"
                      style={{ marginRight: 24 }}
                    >
                      <Radio.Button value="all" style={{ color: inflowWhaleType === 'all' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: inflowWhaleType === 'all' ? '#1890ff' : 'transparent' }}>所有鲸鱼</Radio.Button>
                      <Radio.Button value="smart" style={{ color: inflowWhaleType === 'smart' ? '#fff' : '#52c41a', borderColor: '#52c41a', backgroundColor: inflowWhaleType === 'smart' ? '#52c41a' : 'transparent' }}>聪明鲸鱼</Radio.Button>
                      <Radio.Button value="dumb" style={{ color: inflowWhaleType === 'dumb' ? '#fff' : '#f5222d', borderColor: '#f5222d', backgroundColor: inflowWhaleType === 'dumb' ? '#f5222d' : 'transparent' }}>愚蠢鲸鱼</Radio.Button>
                    </Radio.Group>

                    <Radio.Group
                      value={inflowTimeRange}
                      onChange={(e) => setInflowTimeRange(e.target.value)}
                      size="small"
                    >
                      <Radio.Button value="day" style={{ color: inflowTimeRange === 'day' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: inflowTimeRange === 'day' ? '#1890ff' : 'transparent' }}>当天</Radio.Button>
                      <Radio.Button value="week" style={{ color: inflowTimeRange === 'week' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: inflowTimeRange === 'week' ? '#1890ff' : 'transparent' }}>近一周</Radio.Button>
                      <Radio.Button value="month" style={{ color: inflowTimeRange === 'month' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: inflowTimeRange === 'month' ? '#1890ff' : 'transparent' }}>近一月</Radio.Button>
                    </Radio.Group>
                  </Space>
                </div>
              </div>
            }
            className="tech-card"
            bordered={false}
            style={{ marginBottom: 24 }}
          >
            {isInflow ? (
              <WhaleInflowCollectionsChart timeRange={inflowTimeRange} whaleType={inflowWhaleType} />
            ) : (
              <WhaleOutflowCollectionsChart timeRange={inflowTimeRange} whaleType={inflowWhaleType} />
            )}
          </Card>
        </Col>
      </Row>

      {/* 鲸鱼列表模态框 */}
      <WhaleListModal
        visible={whaleListModalVisible}
        onClose={() => setWhaleListModalVisible(false)}
        type={whaleListType}
        onSelectWhale={handleWhaleClick}
        trackedWhales={trackedWhales}
        trackedWhalesData={trackedWhalesData} // 添加完整的鲸鱼数据
      />

      {/* 鲸鱼钱包模态框 */}
      {selectedWhaleId && (
        <Modal
          title={
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <WalletOutlined style={{ color: 'var(--primary)', marginRight: 8 }} />
              <Text style={{ color: 'rgba(255, 255, 255, 0.85)' }}>
                鲸鱼钱包列表 - {selectedWhaleId}
              </Text>
            </div>
          }
          visible={whaleAddressModalVisible}
          onCancel={() => setWhaleAddressModalVisible(false)}
          footer={null}
          width={1200}
          className="tech-modal"
          style={{ top: 20 }}
        >
          <Table
            columns={columns}
            dataSource={getWhaleAddresses(selectedWhaleId)}
            pagination={false}
            rowClassName="tech-table-row"
            style={{ background: 'transparent' }}
            scroll={{ x: 1080 }}
          />
        </Modal>
      )}

      {/* 钱包分析模态框 */}
      {selectedWallet && (
        <WalletAnalysisModal
          visible={modalVisible}
          onClose={() => setModalVisible(false)}
          walletAddress={selectedWallet.address}
          walletLabel={selectedWallet.label}
        />
      )}
    </div>
  );
};

export default Dashboard; 