import React, { useEffect, useState, useRef } from 'react';
import { Card, Row, Col, Statistic, Table, Tag, Typography, Badge, Spin, List, Avatar, Divider, Modal, Space, Button, Radio, Tooltip, Select } from 'antd';
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

const { Title, Text } = Typography;

// 科技风格标题组件
const TechTitle: React.FC<{children: React.ReactNode}> = ({ children }) => (
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
const TechTag: React.FC<{level: string}> = ({ level }) => {
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
const HoldingChange: React.FC<{value: number}> = ({ value }) => {
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
  const [tagFilter, setTagFilter] = useState<string>('all');
  const [timeFilter, setTimeFilter] = useState<string>('all');

  // 模拟交易数据
  const sampleTransactions = [
    {
      id: '1',
      time: '刚刚',
      nftName: 'Bored Ape #5689',
      collection: 'BAYC',
      seller: '0x7823...45fa',
      buyer: '0xa245...78de',
      price: 72.5,
      priceChange: +15.3, // 价格变化百分比
      rarityRank: 226,    // 稀有度排名
      whaleInfluence: 89,  // 鲸鱼影响力得分
      actionType: 'accumulate', // 操作类型：积累
      isWhale: true,
      whaleIsBuyer: true, // 鲸鱼是买家
      whaleSeller: false, // 鲸鱼不是卖家
      whaleAddress: '0xa245...78de', // 哪个地址是鲸鱼
    },
    {
      id: '2',
      time: '2分钟前',
      nftName: 'Azuki #2456',
      collection: 'Azuki',
      seller: '0x3467...12ab',
      buyer: '0xf123...90cd',
      price: 12.8,
      priceChange: -3.7,
      rarityRank: 1458,
      whaleInfluence: 0,
      actionType: 'explore',
      isWhale: false,
      whaleIsBuyer: false,
      whaleSeller: false,
      whaleAddress: '',
    },
    {
      id: '3',
      time: '5分钟前',
      nftName: 'CryptoPunk #7804',
      collection: 'CryptoPunks',
      seller: '0xd678...34ef',
      buyer: '0x5678...1234',
      price: 83.2,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x5678...1234',
    },
    {
      id: '4',
      time: '8分钟前',
      nftName: 'Doodle #8901',
      collection: 'Doodles',
      seller: '0x8765...4321',
      buyer: '0x2345...6789',
      price: 8.5,
      isWhale: false,
      whaleIsBuyer: false,
      whaleSeller: false,
      whaleAddress: '',
    },
    {
      id: '5',
      time: '12分钟前',
      nftName: 'CloneX #3478',
      collection: 'CloneX',
      seller: '0x1234...5678',
      buyer: '0x9012...3456',
      price: 15.3,
      isWhale: true,
      whaleIsBuyer: false,
      whaleSeller: true,
      whaleAddress: '0x1234...5678',
    },
    // 新增15条鲸鱼交易数据
    {
      id: '9',
      time: '15分钟前',
      nftName: 'Otherdeed #7821',
      collection: 'Otherdeeds',
      seller: '0xab23...f456',
      buyer: '0x7842...9e12',
      price: 32.4,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x7842...9e12',
    },
    {
      id: '10',
      time: '18分钟前',
      nftName: 'World of Women #3265',
      collection: 'WoW',
      seller: '0x2469...78ab',
      buyer: '0xce34...df56',
      price: 7.2,
      isWhale: true,
      whaleIsBuyer: false,
      whaleSeller: true,
      whaleAddress: '0x2469...78ab',
    },
    {
      id: '11',
      time: '22分钟前',
      nftName: 'CyberKongz #435',
      collection: 'CyberKongz',
      seller: '0x8276...34ef',
      buyer: '0x3694...12cd',
      price: 14.8,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: true,
      whaleAddress: '0x8276...34ef', // 这里两个都是鲸鱼，标记卖家
    },
    {
      id: '12',
      time: '25分钟前',
      nftName: 'Cool Cats #2176',
      collection: 'Cool Cats',
      seller: '0x9127...56gh',
      buyer: '0x1498...23ab',
      price: 5.1,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x1498...23ab',
    },
    {
      id: '13',
      time: '30分钟前',
      nftName: 'Meebits #8932',
      collection: 'Meebits',
      seller: '0x6723...9f01',
      buyer: '0x5678...1234',
      price: 42.7,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x5678...1234',
    },
    {
      id: '14',
      time: '35分钟前',
      nftName: 'BAYC #7652',
      collection: 'BAYC',
      seller: '0x1234...5678',
      buyer: '0x3254...78ef',
      price: 95.3,
      isWhale: true,
      whaleIsBuyer: false,
      whaleSeller: true,
      whaleAddress: '0x1234...5678',
    },
    {
      id: '15',
      time: '40分钟前',
      nftName: 'Cryptoadz #563',
      collection: 'Cryptoadz',
      seller: '0x5431...ab78',
      buyer: '0x7890...23cd',
      price: 6.8,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x7890...23cd',
    },
    {
      id: '16',
      time: '45分钟前',
      nftName: 'Azuki #9875',
      collection: 'Azuki',
      seller: '0xa245...78de',
      buyer: '0xd785...12ef',
      price: 16.2,
      isWhale: true,
      whaleIsBuyer: false,
      whaleSeller: true,
      whaleAddress: '0xa245...78de',
    },
    {
      id: '17',
      time: '50分钟前',
      nftName: 'CloneX #2143',
      collection: 'CloneX',
      seller: '0x3426...90ab',
      buyer: '0x8765...4321',
      price: 18.7,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x8765...4321',
    },
    {
      id: '18',
      time: '52分钟前',
      nftName: 'Doodles #1532',
      collection: 'Doodles',
      seller: '0x7842...9e12',
      buyer: '0xab23...f456',
      price: 9.4,
      isWhale: true,
      whaleIsBuyer: false,
      whaleSeller: true,
      whaleAddress: '0x7842...9e12',
    },
    {
      id: '19',
      time: '1小时前',
      nftName: 'MAYC #4231',
      collection: 'MAYC',
      seller: '0xe987...12df',
      buyer: '0x2469...78ab',
      price: 28.5,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x2469...78ab',
    },
    {
      id: '20',
      time: '1小时5分钟前',
      nftName: 'Pudgy Penguins #1893',
      collection: 'Pudgy Penguins',
      seller: '0x8276...34ef',
      buyer: '0x9127...56gh',
      price: 11.2,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: true,
      whaleAddress: '0x9127...56gh', // 买家是鲸鱼
    },
    {
      id: '21',
      time: '1小时10分钟前',
      nftName: 'CryptoPunks #3214',
      collection: 'CryptoPunks',
      seller: '0x5678...1234',
      buyer: '0x6723...9f01',
      price: 110.5,
      isWhale: true,
      whaleIsBuyer: false,
      whaleSeller: true,
      whaleAddress: '0x5678...1234',
    },
    {
      id: '22',
      time: '1小时20分钟前',
      nftName: 'Moonbirds #4328',
      collection: 'Moonbirds',
      seller: '0x3694...12cd',
      buyer: '0x1498...23ab',
      price: 23.7,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x1498...23ab',
    },
    {
      id: '23',
      time: '1小时30分钟前',
      nftName: 'Goblintown #1267',
      collection: 'Goblintown',
      seller: '0x7890...23cd',
      buyer: '0x1234...5678',
      price: 3.2,
      isWhale: true,
      whaleIsBuyer: true,
      whaleSeller: false,
      whaleAddress: '0x1234...5678',
    }
  ];

  // 初始化交易数据
  useEffect(() => {
    setTransactions(sampleTransactions);
    // 初始化一些被追踪的鲸鱼地址
    setTrackedWhales(['0x5678...1234', '0x1234...5678']);
  }, []);

  // 模拟定时添加新交易
  useEffect(() => {
    const newTransactions = [
      {
        id: '6',
        time: '刚刚',
        nftName: 'Mutant Ape #2341',
        collection: 'MAYC',
        seller: '0x5690...78ab',
        buyer: '0x1234...5678', // 鲸鱼
        price: 20.5,
        isWhale: true,
        whaleIsBuyer: true,
        whaleSeller: false,
        whaleAddress: '0x1234...5678',
      },
      {
        id: '7',
        time: '刚刚',
        nftName: 'Moonbird #5673',
        collection: 'Moonbirds',
        seller: '0x8765...4321', // 鲸鱼
        buyer: '0xc456...d789',
        price: 10.2,
        isWhale: true,
        whaleIsBuyer: false,
        whaleSeller: true,
        whaleAddress: '0x8765...4321',
      },
      {
        id: '8',
        time: '刚刚',
        nftName: 'Pudgy Penguin #671',
        collection: 'Pudgy Penguins',
        seller: '0xe987...12df',
        buyer: '0x3426...90ab',
        price: 4.7,
        isWhale: false,
        whaleIsBuyer: false,
        whaleSeller: false,
        whaleAddress: '',
      },
    ];

    let index = 0;
    const interval = setInterval(() => {
      if (index < newTransactions.length) {
        const newTransaction = newTransactions[index];
        setTransactions(prev => {
          const updated = [newTransaction, ...prev.slice(0, 4)];
          return updated;
        });
        setIsNewItem(true);
        setTimeout(() => setIsNewItem(false), 1000);
        index++;
      } else {
        clearInterval(interval);
      }
    }, 8000);  // 每8秒添加一个新交易

    return () => clearInterval(interval);
  }, []);

  // 新交易出现时滚动到顶部
  useEffect(() => {
    if (isNewItem && listRef.current) {
      listRef.current.scrollTop = 0;
    }
  }, [isNewItem]);

  // 获取NFT图片 (模拟)
  const getNftImage = (collection: string) => {
    const collections: {[key: string]: string} = {
      'BAYC': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=1000',
      'Azuki': 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=1000',
      'CryptoPunks': 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?auto=format&dpr=1&w=1000',
      'Doodles': 'https://i.seadn.io/gae/7B0qai02OdHA8P_EOVK672qUliyjQdQDGNrACxs7WnTgZAkJa_wWURnIFKeOh5VTf8cfTqW3wQpozGEJpJpJnv_DqHDFWxcQplRFyw?auto=format&dpr=1&w=1000',
      'CloneX': 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?auto=format&dpr=1&w=1000',
      'MAYC': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=1000',
      'Moonbirds': 'https://i.seadn.io/gae/H-eyNE1MwL5ohL-tCfn_Xa1Sl9M9B4612tLYeUlQubzt4ewhr4huJIR5OLuyO3Z5PpJFSwdm7rq-TikAh7f5eUw338A2cy6HRH75?auto=format&dpr=1&w=1000',
      'Pudgy Penguins': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=1000',
      // 新增收藏集图标
      'Otherdeeds': 'https://i.seadn.io/gae/yIm-M5-BpSDdTEIJRt5D6xphizhIdozXjqSITgK4phWq7MmAU3qE7Nw7POGCiPGyhtJ3ZFP8iJ29TFl-RLcGBWX5qI4-ZcnCPcsY4zI?auto=format&dpr=1&w=256',
      'WoW': 'https://i.seadn.io/gae/EFAQpIktMraCrs8YLJy_FgjN9jOJW-O6cAZr9eriPZdkKvhJWEdre9wZOxTZL84HJN0GZxwNJXVPOZ8OQfYxgUMnR2JmrpdtWRK1?auto=format&dpr=1&w=256',
      'CyberKongz': 'https://i.seadn.io/gae/LIpf9z6Ux8uxn69auBME9FCTXpXqSYFo8ZLO1GaM8T7S3hiKScHaClXe0ZdhTv5br6FE2g5i-J5SobhKFsYfe6CIMCv-UfnrlYFWOM4?auto=format&dpr=1&w=256',
      'Cool Cats': 'https://i.seadn.io/gae/LIov33kogXOK4XZd2ESj29sqm_Hww5JSdO7AFn5wjt8xgnJJ0UpNV9yITqxra3s_LMEW1AnnrgOVB_hDpjJRA1uF4skI5Sdi_9rULi8?auto=format&dpr=1&w=256',
      'Meebits': 'https://i.seadn.io/gae/d784iHHbqQFVH1XYD6HoT4u3y_Fsu_9FZUltWjnOzoYv7qqB5dLUqpOJ16kTQAGr-NORVYHOwzOqRkigvUrYoBCYAAltp8Zf-ZV3?auto=format&dpr=1&w=256',
      'Cryptoadz': 'https://i.seadn.io/gae/iofetZEyiEIGcNyJKpbOafb_efJyeo7QOYnTog8qcQJhqoBU-Vu7mnijXM7SouWRtHKCuLIC9XDcGILXfyg0bnBZ6IPrWMA5VaCgygE?auto=format&dpr=1&w=256',
      'Goblintown': 'https://i.seadn.io/gae/cb_wdEAmvry_noTCq1EDPD3eF04Wg3YxHPzGW9QjIjX9-hU-Q5y_rLpbEWhnmcSuYWRiV7bjZ6T41w8tgMqjEIHFWzG_AQT-qm1KnKU?auto=format&dpr=1&w=256'
    };
    
    return collections[collection] || 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=1000';
  };

  // 处理追踪/取消追踪鲸鱼
  const toggleTracking = (whaleAddress: string) => {
    setTrackedWhales(prev => {
      if (prev.includes(whaleAddress)) {
        return prev.filter(addr => addr !== whaleAddress);
      } else {
        return [...prev, whaleAddress];
      }
    });
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
    const actionTypes: {[key: string]: {color: string, text: string}} = {
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

    return filtered;
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
              count={getFilteredTransactions().length} 
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
                  src={getNftImage(item.collection)} 
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
                  
                  {/* 第二行：收藏集、稀有度、价格对比 */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                <div>
                      <Text style={{ color: 'rgba(255, 255, 255, 0.65)', fontSize: 13 }}>
                        收藏集: {item.collection}
                  </Text>
                      {item.rarityRank && (
                        <Text style={{ color: 'rgba(255, 255, 255, 0.55)', fontSize: 13, marginLeft: 12 }}>
                          稀有度排名: #{item.rarityRank}
                    </Text>
                      )}
                  </div>
+                 <div>
+                   {/* 可以根据需要在这里添加其他信息 */}
+                 </div>
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
                    marginBottom: 8
              }}>
                {item.price} ETH
                  </div>
                  {renderPriceChange(item.priceChange || 0)}
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
            color: function(params: any) {
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
const TopWhalesTradingVolumeChart: React.FC<{timeRange: 'day' | 'week' | 'month'}> = ({ timeRange }) => {
  // 获取图表数据
  const getChartData = () => {
    // 根据时间范围返回不同的数据
    if (timeRange === 'day') {
      return [
        { name: 'WHALE-0x5678', value: 450000 },
        { name: 'WHALE-0x7842', value: 380000 },
        { name: 'WHALE-0x1234', value: 320000 },
        { name: 'WHALE-0x2469', value: 280000 },
        { name: 'WHALE-0x8276', value: 230000 },
        { name: 'WHALE-0x3694', value: 190000 },
        { name: 'WHALE-0x9127', value: 150000 },
        { name: 'WHALE-0x8765', value: 120000 },
        { name: 'WHALE-0x6723', value: 90000 },
        { name: 'WHALE-0x1498', value: 70000 }
      ];
    } else if (timeRange === 'week') {
      return [
        { name: 'WHALE-0x5678', value: 1250000 },
        { name: 'WHALE-0x7842', value: 980000 },
        { name: 'WHALE-0x1234', value: 760000 },
        { name: 'WHALE-0x2469', value: 650000 },
        { name: 'WHALE-0x8276', value: 580000 },
        { name: 'WHALE-0x3694', value: 520000 },
        { name: 'WHALE-0x9127', value: 480000 },
        { name: 'WHALE-0x8765', value: 410000 },
        { name: 'WHALE-0x6723', value: 380000 },
        { name: 'WHALE-0x1498', value: 320000 }
      ];
    } else {
      return [
        { name: 'WHALE-0x5678', value: 4850000 },
        { name: 'WHALE-0x7842', value: 3720000 },
        { name: 'WHALE-0x2469', value: 2950000 },
        { name: 'WHALE-0x1234', value: 2680000 },
        { name: 'WHALE-0x3694', value: 2450000 },
        { name: 'WHALE-0x8276', value: 2120000 },
        { name: 'WHALE-0x9127', value: 1980000 },
        { name: 'WHALE-0x6723', value: 1650000 },
        { name: 'WHALE-0x8765', value: 1520000 },
        { name: 'WHALE-0x1498', value: 1380000 }
      ];
    }
  };

  const getOption = () => {
    const data = getChartData();
    const totalVolume = data.reduce((sum, item) => sum + item.value, 0);
    
    return {
      tooltip: {
        trigger: 'item',
        formatter: (params: any) => {
          const percent = ((params.value / totalVolume) * 100).toFixed(1);
          return `<div style="display: flex; flex-direction: column; gap: 8px; padding: 8px 12px;">
                   <div style="font-size: 14px; font-weight: bold; color: #fff;">${params.name}</div>
                   <div style="display: flex; justify-content: space-between; gap: 16px;">
                     <span style="color: rgba(255, 255, 255, 0.85);">交易额:</span>
                     <span style="color: #1890ff; font-weight: bold;">$${params.value.toLocaleString()}</span>
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
    <ReactECharts
      option={getOption()}
      style={{ height: '300px', width: '100%' }}
      className="react-echarts"
    />
  );
};

// 鲸鱼流入Top10收藏集统计图
const WhaleInflowCollectionsChart: React.FC<{
  timeRange: 'day' | 'week' | 'month',
  whaleType: 'all' | 'smart' | 'dumb'
}> = ({ timeRange, whaleType }) => {
  // 获取图表数据
  const getChartData = () => {
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
  const getIconUrl = (collection: string) => {
    const collections: {[key: string]: string} = {
      'BAYC': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256',
      'Azuki': 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256',
      'CryptoPunks': 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?auto=format&dpr=1&w=256',
      'Doodles': 'https://i.seadn.io/gae/7B0qai02OdHA8P_EOVK672qUliyjQdQDGNrACxs7WnTgZAkJa_wWURnIFKeOh5VTf8cfTqW3wQpozGEJpJpJnv_DqHDFWxcQplRFyw?auto=format&dpr=1&w=256',
      'CloneX': 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?auto=format&dpr=1&w=256',
      'MAYC': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=256',
      'Moonbirds': 'https://i.seadn.io/gae/H-eyNE1MwL5ohL-tCfn_Xa1Sl9M9B4612tLYeUlQubzt4ewhr4huJIR5OLuyO3Z5PpJFSwdm7rq-TikAh7f5eUw338A2cy6HRH75?auto=format&dpr=1&w=256',
      'Pudgy Penguins': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=256',
      // 新增收藏集图标
      'Otherdeeds': 'https://i.seadn.io/gae/yIm-M5-BpSDdTEIJRt5D6xphizhIdozXjqSITgK4phWq7MmAU3qE7Nw7POGCiPGyhtJ3ZFP8iJ29TFl-RLcGBWX5qI4-ZcnCPcsY4zI?auto=format&dpr=1&w=256',
      'WoW': 'https://i.seadn.io/gae/EFAQpIktMraCrs8YLJy_FgjN9jOJW-O6cAZr9eriPZdkKvhJWEdre9wZOxTZL84HJN0GZxwNJXVPOZ8OQfYxgUMnR2JmrpdtWRK1?auto=format&dpr=1&w=256',
      'CyberKongz': 'https://i.seadn.io/gae/LIpf9z6Ux8uxn69auBME9FCTXpXqSYFo8ZLO1GaM8T7S3hiKScHaClXe0ZdhTv5br6FE2g5i-J5SobhKFsYfe6CIMCv-UfnrlYFWOM4?auto=format&dpr=1&w=256',
      'Cool Cats': 'https://i.seadn.io/gae/LIov33kogXOK4XZd2ESj29sqm_Hww5JSdO7AFn5wjt8xgnJJ0UpNV9yITqxra3s_LMEW1AnnrgOVB_hDpjJRA1uF4skI5Sdi_9rULi8?auto=format&dpr=1&w=256',
      'Meebits': 'https://i.seadn.io/gae/d784iHHbqQFVH1XYD6HoT4u3y_Fsu_9FZUltWjnOzoYv7qqB5dLUqpOJ16kTQAGr-NORVYHOwzOqRkigvUrYoBCYAAltp8Zf-ZV3?auto=format&dpr=1&w=256',
      'Cryptoadz': 'https://i.seadn.io/gae/iofetZEyiEIGcNyJKpbOafb_efJyeo7QOYnTog8qcQJhqoBU-Vu7mnijXM7SouWRtHKCuLIC9XDcGILXfyg0bnBZ6IPrWMA5VaCgygE?auto=format&dpr=1&w=256',
      'Goblintown': 'https://i.seadn.io/gae/cb_wdEAmvry_noTCq1EDPD3eF04Wg3YxHPzGW9QjIjX9-hU-Q5y_rLpbEWhnmcSuYWRiV7bjZ6T41w8tgMqjEIHFWzG_AQT-qm1KnKU?auto=format&dpr=1&w=256'
    };
    
    return collections[collection] || 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=1000';
  };

  // 准备ECharts配置
  const getOption = () => {
    const data = getChartData();
    // 数据排序
    data.sort((a, b) => a.value - b.value);
    
    // 准备图标配置
    const icons = data.map(item => getIconUrl(item.icon));
    
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
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow',
          shadowStyle: {
            color: 'rgba(24, 144, 255, 0.1)'
          }
        },
        formatter: function(params: any) {
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
          formatter: function(value: number) {
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
          formatter: function(value: string, index: number) {
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
            formatter: function(params: any) {
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
          animationDelay: function(idx: number) {
            return idx * 100;
          }
        }
      ],
      animationEasing: 'elasticOut',
      animationDelayUpdate: function(idx: number) {
        return idx * 5;
      },
      animationDuration: 1500
    };
  };

  return (
    <ReactECharts
      option={getOption()}
      style={{ height: '400px', width: '100%' }}
      className="react-echarts"
    />
  );
};

// 鲸鱼流出Top10收藏集统计图
const WhaleOutflowCollectionsChart: React.FC<{
  timeRange: 'day' | 'week' | 'month',
  whaleType: 'all' | 'smart' | 'dumb'
}> = ({ timeRange, whaleType }) => {
  // 获取图表数据
  const getChartData = () => {
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
  const getIconUrl = (collection: string) => {
    const collections: {[key: string]: string} = {
      'BAYC': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256',
      'Azuki': 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256',
      'CryptoPunks': 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?auto=format&dpr=1&w=256',
      'Doodles': 'https://i.seadn.io/gae/7B0qai02OdHA8P_EOVK672qUliyjQdQDGNrACxs7WnTgZAkJa_wWURnIFKeOh5VTf8cfTqW3wQpozGEJpJpJnv_DqHDFWxcQplRFyw?auto=format&dpr=1&w=256',
      'CloneX': 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?auto=format&dpr=1&w=256',
      'MAYC': 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?auto=format&dpr=1&w=256',
      'Moonbirds': 'https://i.seadn.io/gae/H-eyNE1MwL5ohL-tCfn_Xa1Sl9M9B4612tLYeUlQubzt4ewhr4huJIR5OLuyO3Z5PpJFSwdm7rq-TikAh7f5eUw338A2cy6HRH75?auto=format&dpr=1&w=256',
      'Pudgy Penguins': 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqIDgOa?auto=format&dpr=1&w=256',
      'Otherdeeds': 'https://i.seadn.io/gae/yIm-M5-BpSDdTEIJRt5D6xphizhIdozXjqSITgK4phWq7MmAU3qE7Nw7POGCiPGyhtJ3ZFP8iJ29TFl-RLcGBWX5qI4-ZcnCPcsY4zI?auto=format&dpr=1&w=256',
      'WoW': 'https://i.seadn.io/gae/EFAQpIktMraCrs8YLJy_FgjN9jOJW-O6cAZr9eriPZdkKvhJWEdre9wZOxTZL84HJN0GZxwNJXVPOZ8OQfYxgUMnR2JmrpdtWRK1?auto=format&dpr=1&w=256',
      'CyberKongz': 'https://i.seadn.io/gae/LIpf9z6Ux8uxn69auBME9FCTXpXqSYFo8ZLO1GaM8T7S3hiKScHaClXe0ZdhTv5br6FE2g5i-J5SobhKFsYfe6CIMCv-UfnrlYFWOM4?auto=format&dpr=1&w=256',
      'Cool Cats': 'https://i.seadn.io/gae/LIov33kogXOK4XZd2ESj29sqm_Hww5JSdO7AFn5wjt8xgnJJ0UpNV9yITqxra3s_LMEW1AnnrgOVB_hDpjJRA1uF4skI5Sdi_9rULi8?auto=format&dpr=1&w=256',
      'Meebits': 'https://i.seadn.io/gae/d784iHHbqQFVH1XYD6HoT4u3y_Fsu_9FZUltWjnOzoYv7qqB5dLUqpOJ16kTQAGr-NORVYHOwzOqRkigvUrYoBCYAAltp8Zf-ZV3?auto=format&dpr=1&w=256',
      'Cryptoadz': 'https://i.seadn.io/gae/iofetZEyiEIGcNyJKpbOafb_efJyeo7QOYnTog8qcQJhqoBU-Vu7mnijXM7SouWRtHKCuLIC9XDcGILXfyg0bnBZ6IPrWMA5VaCgygE?auto=format&dpr=1&w=256',
      'Goblintown': 'https://i.seadn.io/gae/cb_wdEAmvry_noTCq1EDPD3eF04Wg3YxHPzGW9QjIjX9-hU-Q5y_rLpbEWhnmcSuYWRiV7bjZ6T41w8tgMqjEIHFWzG_AQT-qm1KnKU?auto=format&dpr=1&w=256'
    };
    
    return collections[collection] || '';
  };

  // 准备ECharts配置
  const getOption = () => {
    const data = getChartData();
    // 数据排序
    data.sort((a, b) => a.value - b.value);
    
    // 准备图标配置
    const icons = data.map(item => getIconUrl(item.icon));
    
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
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow',
          shadowStyle: {
            color: 'rgba(24, 144, 255, 0.1)'
          }
        },
        formatter: function(params: any) {
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
          formatter: function(value: number) {
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
          formatter: function(value: string, index: number) {
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
            formatter: function(params: any) {
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
          animationDelay: function(idx: number) {
            return idx * 100;
          }
        }
      ],
      animationEasing: 'elasticOut',
      animationDelayUpdate: function(idx: number) {
        return idx * 5;
      },
      animationDuration: 1500
    };
  };

  return (
    <ReactECharts
      option={getOption()}
      style={{ height: '400px', width: '100%' }}
      className="react-echarts"
    />
  );
};

// 鲸鱼收益率Top10饼状图组件
const WhalesProfitRateChart: React.FC<{timeRange: 'day' | 'week' | 'month'}> = ({ timeRange }) => {
  // 获取图表数据
  const getChartData = () => {
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

  const getOption = () => {
    const data = getChartData();
    const totalProfit = data.reduce((sum, item) => sum + item.profit, 0);
    
    return {
      tooltip: {
        trigger: 'item',
        formatter: (params: any) => {
          const item = data.find(d => d.name === params.name);
          const percent = ((params.value / data.reduce((sum, item) => sum + item.value, 0)) * 100).toFixed(1);
          return `<div style="display: flex; flex-direction: column; gap: 8px; padding: 8px 12px;">
                   <div style="font-size: 14px; font-weight: bold; color: #fff;">${params.name}</div>
                   <div style="display: flex; justify-content: space-between; gap: 16px;">
                     <span style="color: rgba(255, 255, 255, 0.85);">收益率:</span>
                     <span style="color: #52c41a; font-weight: bold;">+${params.value}%</span>
                   </div>
                   <div style="display: flex; justify-content: space-between; gap: 16px;">
                     <span style="color: rgba(255, 255, 255, 0.85);">收益额:</span>
                     <span style="color: #1890ff; font-weight: bold;">$${item?.profit.toLocaleString()}</span>
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
          return `${name}  +${item?.value}%`;
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
                  `{value|+${params.value}%}`
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
                  ][index] 
                },
                { 
                  offset: 1, 
                  color: [
                    '#389e0d', '#096dd9', '#531dab', '#c41d7f', '#d48806',
                    '#08979c', '#cf1322', '#7cb305', '#1d39c4', '#d4380d'
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
    <ReactECharts
      option={getOption()}
      style={{ height: '300px', width: '100%' }}
      className="react-echarts"
    />
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
}> = ({ visible, onClose, type, onSelectWhale }) => {
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

  useEffect(() => {
    if (visible) {
      // 模拟API请求加载鲸鱼数据
      const timer = setTimeout(() => {
        // 模拟不同类型的鲸鱼数据
        let data: any[] = [];
        
        if (type === 'tracked') {
          data = [
            {
              key: '1',
              whaleId: 'WHALE-0x1234',
              mainNft: 'CryptoPunks',
              influence: 89,
              totalHolding: 3250000,
              totalProfit: 420000,
              profitPercent: 14.8,
              totalNetProfit: 280000,
              netProfitPercent: 9.8,
              addressCount: 3
            },
            {
              key: '2',
              whaleId: 'WHALE-0x8765',
              mainNft: 'Azuki',
              influence: 76,
              totalHolding: 1850000,
              totalProfit: 250000,
              profitPercent: 15.6,
              totalNetProfit: 165000,
              netProfitPercent: 10.2,
              addressCount: 2
            },
            {
              key: '3',
              whaleId: 'WHALE-0x5678',
              mainNft: 'BAYC',
              influence: 95,
              totalHolding: 4120000,
              totalProfit: 830000,
              profitPercent: 25.2,
              totalNetProfit: 550000,
              netProfitPercent: 16.5,
              addressCount: 4
            },
            {
              key: '4',
              whaleId: 'WHALE-0xabcd',
              mainNft: 'Doodles',
              influence: 82,
              totalHolding: 1450000,
              totalProfit: 180000,
              profitPercent: 14.2,
              totalNetProfit: 120000,
              netProfitPercent: 9.2,
              addressCount: 2
            },
            {
              key: '5',
              whaleId: 'WHALE-0x9876',
              mainNft: 'CloneX',
              influence: 71,
              totalHolding: 980000,
              totalProfit: -120000,
              profitPercent: -10.9,
              totalNetProfit: -180000,
              netProfitPercent: -15.5,
              addressCount: 2
            }
          ];
        } else if (type === 'smart') {
          data = [
            {
              key: '1',
              whaleId: 'WHALE-0x2469',
              mainNft: 'BAYC',
              influence: 98,
              totalHolding: 3850000,
              totalProfit: 1250000,
              profitPercent: 48.1,
              totalNetProfit: 850000,
              netProfitPercent: 32.7,
              addressCount: 3
            },
            {
              key: '2',
              whaleId: 'WHALE-0x7842',
              mainNft: 'CryptoPunks',
              influence: 94,
              totalHolding: 5120000,
              totalProfit: 1840000,
              profitPercent: 56.2,
              totalNetProfit: 1220000,
              netProfitPercent: 37.3,
              addressCount: 4
            },
            {
              key: '3',
              whaleId: 'WHALE-0x5678',
              mainNft: 'BAYC',
              influence: 91,
              totalHolding: 4120000,
              totalProfit: 830000,
              profitPercent: 25.2,
              totalNetProfit: 550000,
              netProfitPercent: 16.5,
              addressCount: 4
            },
            {
              key: '4',
              whaleId: 'WHALE-0x3694',
              mainNft: 'Art Blocks',
              influence: 88,
              totalHolding: 2850000,
              totalProfit: 780000,
              profitPercent: 37.7,
              totalNetProfit: 520000,
              netProfitPercent: 25.2,
              addressCount: 2
            },
            {
              key: '5',
              whaleId: 'WHALE-0x9127',
              mainNft: 'Moonbirds',
              influence: 85,
              totalHolding: 1250000,
              totalProfit: 430000,
              profitPercent: 52.5,
              totalNetProfit: 290000,
              netProfitPercent: 35.4,
              addressCount: 2
            }
          ];
        } else if (type === 'dumb') {
          data = [
            {
              key: '1',
              whaleId: 'WHALE-0x3254',
              mainNft: 'Doodles',
              influence: 45,
              totalHolding: 950000,
              totalProfit: -380000,
              profitPercent: -28.6,
              totalNetProfit: -450000,
              netProfitPercent: -33.8,
              addressCount: 2
            },
            {
              key: '2',
              whaleId: 'WHALE-0x9876',
              mainNft: 'CloneX',
              influence: 38,
              totalHolding: 980000,
              totalProfit: -120000,
              profitPercent: -10.9,
              totalNetProfit: -180000,
              netProfitPercent: -15.5,
              addressCount: 2
            },
            {
              key: '3',
              whaleId: 'WHALE-0x5431',
              mainNft: 'Pudgy Penguins',
              influence: 52,
              totalHolding: 520000,
              totalProfit: -210000,
              profitPercent: -28.8,
              totalNetProfit: -280000,
              netProfitPercent: -35.0,
              addressCount: 1
            },
            {
              key: '4',
              whaleId: 'WHALE-0x7890',
              mainNft: 'Moonbirds',
              influence: 42,
              totalHolding: 680000,
              totalProfit: -150000,
              profitPercent: -18.1,
              totalNetProfit: -210000,
              netProfitPercent: -23.6,
              addressCount: 2
            }
          ];
        } else if (type === 'all') {
          // 鲸鱼名单综合数据（35个）
          data = [
            // 智能鲸鱼数据（8个）
            {
              key: '1',
              whaleId: 'WHALE-0x2469',
              mainNft: 'BAYC',
              influence: 98,
              totalHolding: 3850000,
              totalProfit: 1250000,
              profitPercent: 48.1,
              totalNetProfit: 850000,
              netProfitPercent: 32.7,
              addressCount: 3
            },
            {
              key: '2',
              whaleId: 'WHALE-0x7842',
              mainNft: 'CryptoPunks',
              influence: 94,
              totalHolding: 5120000,
              totalProfit: 1840000,
              profitPercent: 56.2,
              totalNetProfit: 1220000,
              netProfitPercent: 37.3,
              addressCount: 4
            },
            {
              key: '3',
              whaleId: 'WHALE-0x5678',
              mainNft: 'BAYC',
              influence: 91,
              totalHolding: 4120000,
              totalProfit: 830000,
              profitPercent: 25.2,
              totalNetProfit: 550000,
              netProfitPercent: 16.5,
              addressCount: 4
            },
            {
              key: '4',
              whaleId: 'WHALE-0x3694',
              mainNft: 'Art Blocks',
              influence: 88,
              totalHolding: 2850000,
              totalProfit: 780000,
              profitPercent: 37.7,
              totalNetProfit: 520000,
              netProfitPercent: 25.2,
              addressCount: 2
            },
            {
              key: '5',
              whaleId: 'WHALE-0x9127',
              mainNft: 'Moonbirds',
              influence: 85,
              totalHolding: 1250000,
              totalProfit: 430000,
              profitPercent: 52.5,
              totalNetProfit: 290000,
              netProfitPercent: 35.4,
              addressCount: 2
            },
            {
              key: '6',
              whaleId: 'WHALE-0x6245',
              mainNft: 'Pudgy Penguins',
              influence: 82,
              totalHolding: 1720000,
              totalProfit: 620000,
              profitPercent: 56.4,
              totalNetProfit: 420000,
              netProfitPercent: 38.2,
              addressCount: 2
            },
            {
              key: '7',
              whaleId: 'WHALE-0x8132',
              mainNft: 'Meebits',
              influence: 80,
              totalHolding: 2230000,
              totalProfit: 910000,
              profitPercent: 68.9,
              totalNetProfit: 620000,
              netProfitPercent: 46.9,
              addressCount: 3
            },
            {
              key: '8',
              whaleId: 'WHALE-0x4519',
              mainNft: 'CloneX',
              influence: 78,
              totalHolding: 1930000,
              totalProfit: 740000,
              profitPercent: 62.2,
              totalNetProfit: 495000,
              netProfitPercent: 41.5,
              addressCount: 2
            },
            // 追踪鲸鱼数据（上面已有3个，补充2个）
            {
              key: '9',
              whaleId: 'WHALE-0x1234',
              mainNft: 'CryptoPunks',
              influence: 89,
              totalHolding: 3250000,
              totalProfit: 420000,
              profitPercent: 14.8,
              totalNetProfit: 280000,
              netProfitPercent: 9.8,
              addressCount: 3
            },
            {
              key: '10',
              whaleId: 'WHALE-0xabcd',
              mainNft: 'Doodles',
              influence: 82,
              totalHolding: 1450000,
              totalProfit: 180000,
              profitPercent: 14.2,
              totalNetProfit: 120000,
              netProfitPercent: 9.2,
              addressCount: 2
            },
            // 愚蠢鲸鱼数据（4个）
            {
              key: '11',
              whaleId: 'WHALE-0x3254',
              mainNft: 'Doodles',
              influence: 45,
              totalHolding: 950000,
              totalProfit: -380000,
              profitPercent: -28.6,
              totalNetProfit: -450000,
              netProfitPercent: -33.8,
              addressCount: 2
            },
            {
              key: '12',
              whaleId: 'WHALE-0x9876',
              mainNft: 'CloneX',
              influence: 38,
              totalHolding: 980000,
              totalProfit: -120000,
              profitPercent: -10.9,
              totalNetProfit: -180000,
              netProfitPercent: -15.5,
              addressCount: 2
            },
            {
              key: '13',
              whaleId: 'WHALE-0x5431',
              mainNft: 'Pudgy Penguins',
              influence: 52,
              totalHolding: 520000,
              totalProfit: -210000,
              profitPercent: -28.8,
              totalNetProfit: -280000,
              netProfitPercent: -35.0,
              addressCount: 1
            },
            {
              key: '14',
              whaleId: 'WHALE-0x7890',
              mainNft: 'Moonbirds',
              influence: 42,
              totalHolding: 680000,
              totalProfit: -150000,
              profitPercent: -18.1,
              totalNetProfit: -210000,
              netProfitPercent: -23.6,
              addressCount: 2
            },
            // 新增鲸鱼数据（21个）
            {
              key: '15',
              whaleId: 'WHALE-0xbb32',
              mainNft: 'MAYC',
              influence: 75,
              totalHolding: 1350000,
              totalProfit: 320000,
              profitPercent: 31.1,
              totalNetProfit: 245000,
              netProfitPercent: 23.8,
              addressCount: 2
            },
            {
              key: '16',
              whaleId: 'WHALE-0xcc67',
              mainNft: 'Otherdeed',
              influence: 72,
              totalHolding: 980000,
              totalProfit: 210000,
              profitPercent: 27.3,
              totalNetProfit: 165000,
              netProfitPercent: 21.4,
              addressCount: 2
            },
            {
              key: '17',
              whaleId: 'WHALE-0xdd78',
              mainNft: 'DeGods',
              influence: 68,
              totalHolding: 875000,
              totalProfit: 195000,
              profitPercent: 28.6,
              totalNetProfit: 145000,
              netProfitPercent: 21.2,
              addressCount: 1
            },
            {
              key: '18',
              whaleId: 'WHALE-0xee59',
              mainNft: 'Milady',
              influence: 76,
              totalHolding: 920000,
              totalProfit: 185000,
              profitPercent: 25.2,
              totalNetProfit: 140000,
              netProfitPercent: 19.1,
              addressCount: 3
            },
            {
              key: '19',
              whaleId: 'WHALE-0xff12',
              mainNft: 'Azuki',
              influence: 64,
              totalHolding: 1250000,
              totalProfit: 280000,
              profitPercent: 28.9,
              totalNetProfit: 195000,
              netProfitPercent: 20.1,
              addressCount: 2
            },
            {
              key: '20',
              whaleId: 'WHALE-0x1a45',
              mainNft: 'Fidenza',
              influence: 77,
              totalHolding: 1750000,
              totalProfit: 510000,
              profitPercent: 41.1,
              totalNetProfit: 375000,
              netProfitPercent: 30.2,
              addressCount: 2
            },
            {
              key: '21',
              whaleId: 'WHALE-0x2b23',
              mainNft: 'Chromie Squiggle',
              influence: 66,
              totalHolding: 950000,
              totalProfit: 215000,
              profitPercent: 29.2,
              totalNetProfit: 165000,
              netProfitPercent: 22.4,
              addressCount: 1
            },
            {
              key: '22',
              whaleId: 'WHALE-0x3c56',
              mainNft: 'Autoglyphs',
              influence: 83,
              totalHolding: 2250000,
              totalProfit: 750000,
              profitPercent: 50.0,
              totalNetProfit: 560000,
              netProfitPercent: 37.3,
              addressCount: 2
            },
            {
              key: '23',
              whaleId: 'WHALE-0x4d89',
              mainNft: 'CoolCats',
              influence: 62,
              totalHolding: 720000,
              totalProfit: 150000,
              profitPercent: 26.3,
              totalNetProfit: 105000,
              netProfitPercent: 18.4,
              addressCount: 1
            },
            {
              key: '24',
              whaleId: 'WHALE-0x5e91',
              mainNft: 'Nouns',
              influence: 79,
              totalHolding: 2650000,
              totalProfit: 920000,
              profitPercent: 53.2,
              totalNetProfit: 680000,
              netProfitPercent: 39.3,
              addressCount: 3
            },
            {
              key: '25',
              whaleId: 'WHALE-0x6f34',
              mainNft: 'Cryptoadz',
              influence: 58,
              totalHolding: 840000,
              totalProfit: -95000,
              profitPercent: -10.2,
              totalNetProfit: -150000,
              netProfitPercent: -16.1,
              addressCount: 2
            },
            {
              key: '26',
              whaleId: 'WHALE-0x7g65',
              mainNft: 'Goblintown',
              influence: 54,
              totalHolding: 420000,
              totalProfit: -65000,
              profitPercent: -13.4,
              totalNetProfit: -110000,
              netProfitPercent: -22.7,
              addressCount: 1
            },
            {
              key: '27',
              whaleId: 'WHALE-0x8h12',
              mainNft: 'Loot',
              influence: 49,
              totalHolding: 380000,
              totalProfit: -125000,
              profitPercent: -24.8,
              totalNetProfit: -190000,
              netProfitPercent: -37.6,
              addressCount: 1
            },
            {
              key: '28',
              whaleId: 'WHALE-0x9i54',
              mainNft: 'Dooplicator',
              influence: 61,
              totalHolding: 590000,
              totalProfit: 85000,
              profitPercent: 16.8,
              totalNetProfit: 55000,
              netProfitPercent: 10.9,
              addressCount: 1
            },
            {
              key: '29',
              whaleId: 'WHALE-0xaj78',
              mainNft: 'BAKC',
              influence: 72,
              totalHolding: 1120000,
              totalProfit: 280000,
              profitPercent: 33.3,
              totalNetProfit: 210000,
              netProfitPercent: 25.0,
              addressCount: 2
            },
            {
              key: '30',
              whaleId: 'WHALE-0xbk90',
              mainNft: 'Sandbox Land',
              influence: 67,
              totalHolding: 1580000,
              totalProfit: 430000,
              profitPercent: 37.4,
              totalNetProfit: 320000,
              netProfitPercent: 27.8,
              addressCount: 3
            },
            {
              key: '31',
              whaleId: 'WHALE-0xcl23',
              mainNft: 'Decentraland',
              influence: 59,
              totalHolding: 920000,
              totalProfit: 180000,
              profitPercent: 24.3,
              totalNetProfit: 130000,
              netProfitPercent: 17.6,
              addressCount: 2
            },
            {
              key: '32',
              whaleId: 'WHALE-0xdm45',
              mainNft: 'CloneX',
              influence: 55,
              totalHolding: 650000,
              totalProfit: -80000,
              profitPercent: -11.0,
              totalNetProfit: -120000,
              netProfitPercent: -16.5,
              addressCount: 1
            },
            {
              key: '33',
              whaleId: 'WHALE-0xen67',
              mainNft: 'Moonbirds',
              influence: 69,
              totalHolding: 980000,
              totalProfit: 250000,
              profitPercent: 34.2,
              totalNetProfit: 190000,
              netProfitPercent: 26.0,
              addressCount: 2
            },
            {
              key: '34',
              whaleId: 'WHALE-0xfo89',
              mainNft: 'Crypto Punks',
              influence: 71,
              totalHolding: 1850000,
              totalProfit: 520000,
              profitPercent: 39.1,
              totalNetProfit: 380000,
              netProfitPercent: 28.6,
              addressCount: 2
            },
            {
              key: '35',
              whaleId: 'WHALE-0xgp12',
              mainNft: 'BAYC',
              influence: 74,
              totalHolding: 2120000,
              totalProfit: 680000,
              profitPercent: 47.2,
              totalNetProfit: 510000,
              netProfitPercent: 35.4,
              addressCount: 3
            }
          ];
        }
        
        setWhaleList(data);
        setLoading(false);
      }, 1000);
      
      return () => clearTimeout(timer);
    }
  }, [visible, type]);

  // 在WhaleListModal组件中添加渲染星级的函数
  const renderStars = (influence: number) => {
    // 将影响力分数（0-100）转换为星级（1-5）
    const starCount = Math.max(1, Math.min(5, Math.ceil(influence / 20)));
    return (
      <div style={{ display: 'flex', alignItems: 'center' }}>
        {Array(5).fill(0).map((_, index) => (
          <StarFilled 
            key={index}
            style={{ 
              color: index < starCount ? '#faad14' : 'rgba(255, 255, 255, 0.15)',
              fontSize: 14,
              marginRight: 2
            }} 
          />
        ))}
        <Text style={{ 
          marginLeft: 8, 
          fontSize: 12, 
          color: 'rgba(255, 255, 255, 0.45)' 
        }}>
          ({influence}分)
        </Text>
      </div>
    );
  };

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
      width: 200,
      render: (influence: number) => renderStars(influence),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>重仓NFT</Text>,
      dataIndex: 'mainNft',
      key: 'mainNft',
      width: 150,
      render: (nft: string) => (
        <Badge 
          color="var(--primary)" 
          text={<Text style={{ color: 'var(--text-primary)' }}>{nft}</Text>} 
        />
      ),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>总持仓金额</Text>,
      dataIndex: 'totalHolding',
      key: 'totalHolding',
      width: 150,
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
      title: <Text style={{ color: 'var(--text-primary)' }}>总持有收益</Text>,
      dataIndex: 'totalProfit',
      key: 'totalProfit',
      width: 150,
      render: (value: number, record: any) => (
        <div>
          <Statistic
            value={value}
            precision={0}
            prefix={value >= 0 ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
            valueStyle={{ 
              color: value >= 0 ? 'var(--success)' : 'var(--danger)', 
              fontSize: 16, 
              textShadow: value >= 0 ? 'var(--text-shadow-success)' : 'var(--text-shadow-danger)'
            }}
            suffix="$"
          />
          <Text style={{ 
            color: value >= 0 ? 'var(--success)' : 'var(--danger)',
            fontSize: 12,
            marginLeft: 8
          }}>
            {value >= 0 ? '+' : ''}{record.profitPercent}%
          </Text>
        </div>
      ),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>总净收益</Text>,
      dataIndex: 'totalNetProfit',
      key: 'totalNetProfit',
      width: 150,
      render: (value: number, record: any) => (
        <div>
          <Statistic
            value={value}
            precision={0}
            prefix={value >= 0 ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
            valueStyle={{ 
              color: value >= 0 ? 'var(--success)' : 'var(--danger)', 
              fontSize: 16, 
              textShadow: value >= 0 ? 'var(--text-shadow-success)' : 'var(--text-shadow-danger)'
            }}
            suffix="$"
          />
          <Text style={{ 
            color: value >= 0 ? 'var(--success)' : 'var(--danger)',
            fontSize: 12,
            marginLeft: 8
          }}>
            {value >= 0 ? '+' : ''}{record.netProfitPercent}%
          </Text>
        </div>
      ),
    },
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>关联钱包数</Text>,
      dataIndex: 'addressCount',
      key: 'addressCount',
      width: 100,
      render: (count: number) => (
        <Badge 
          count={count} 
          style={{ 
            backgroundColor: 'var(--primary)',
            fontWeight: 'bold',
            boxShadow: '0 0 8px var(--primary)'
          }} 
        />
      ),
    },
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
  // 添加数据加载状态
  const [loading, setLoading] = useState(true);
  const [statsData, setStatsData] = useState<any>(null);
  const [whaleData, setWhaleData] = useState<any[]>([]);

  // 添加钱包分析模态框状态
  const [modalVisible, setModalVisible] = useState(false);
  const [selectedWallet, setSelectedWallet] = useState<{address: string, label: string} | null>(null);

  // 添加鲸鱼列表模态框状态
  const [whaleListModalVisible, setWhaleListModalVisible] = useState(false);
  const [whaleListType, setWhaleListType] = useState<'tracked' | 'smart' | 'dumb' | 'all'>('tracked');
  
  // 添加鲸鱼钱包模态框状态
  const [whaleAddressModalVisible, setWhaleAddressModalVisible] = useState(false);
  const [selectedWhaleId, setSelectedWhaleId] = useState<string | null>(null);

  // 添加前十鲸鱼交易额图表时间范围状态
  const [whalesVolumeTimeRange, setWhalesVolumeTimeRange] = useState<'day' | 'week' | 'month'>('week');

  // 添加鲸鱼流入收藏集图表时间范围状态
  const [inflowTimeRange, setInflowTimeRange] = useState<'day' | 'week' | 'month'>('week');

  // 添加鲸鱼流入收藏集图表鲸鱼类型状态
  const [inflowWhaleType, setInflowWhaleType] = useState<'all' | 'smart' | 'dumb'>('all');

  // 添加鲸鱼流入/流出状态
  const [isInflow, setIsInflow] = useState(true);

  // 添加鲸鱼收益率图表时间范围状态
  const [whalesProfitTimeRange, setWhalesProfitTimeRange] = useState<'day' | 'week' | 'month'>('week');

  // 处理点击钱包地址
  const handleWalletClick = (address: string, label: string) => {
    setSelectedWallet({address, label});
    setModalVisible(true);
  };

  // 处理点击鲸鱼统计卡片
  const handleWhaleCardClick = (type: 'tracked' | 'smart' | 'dumb' | 'all') => {
    setWhaleListType(type);
    setWhaleListModalVisible(true);
  };

  // 处理点击鲸鱼ID
  const handleWhaleClick = (whaleId: string) => {
    setSelectedWhaleId(whaleId);
    setWhaleAddressModalVisible(true);
    setWhaleListModalVisible(false); // 关闭鲸鱼列表模态框
  };

  // 模拟鲸鱼钱包关系数据
  const getWhaleAddresses = (whaleId: string) => {
    // 这里根据鲸鱼ID返回对应的钱包地址数据
    // 实际应用中，这些数据应该通过API获取
    const whaleMap: {[key: string]: any[]} = {
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
        },
        {
          key: '3',
          address: '0x9876...5432',
          influenceScore: 65,
          holdingValue: 620000,
          holdingChange: -8000,
          holdingProfit: 120000,
          netProfit: 75000
        },
        {
          key: '4',
          address: '0x2345...6789',
          influenceScore: 78,
          holdingValue: 500000,
          holdingChange: 12000,
          holdingProfit: 100000,
          netProfit: 65000
        }
      ],
      'WHALE-0x8765': [
        {
          key: '1',
          address: '0x8765...4321',
          influenceScore: 74,
          holdingValue: 880000,
          holdingChange: -15000,
          holdingProfit: 140000,
          netProfit: 95000
        },
        {
          key: '2',
          address: '0x1234...5678',
          influenceScore: 86,
          holdingValue: 970000,
          holdingChange: 22000,
          holdingProfit: 165000,
          netProfit: 110000
        }
      ]
    };
    
    // 为其他鲸鱼ID生成随机数据
    if (!whaleMap[whaleId]) {
      const addressCount = Math.floor(Math.random() * 3) + 1; // 1-3个钱包
      const addresses = [];
      
      for (let i = 0; i < addressCount; i++) {
        // 生成随机地址
        const randomHex = () => Math.floor(Math.random() * 16).toString(16);
        const randomAddress = `0x${Array(4).fill(0).map(() => randomHex()).join('')}...${Array(4).fill(0).map(() => randomHex()).join('')}`;
        
        const holdingValue = Math.floor(Math.random() * 1500000) + 500000; // 500000-2000000
        const holdingProfit = Math.floor(Math.random() * 300000) + 50000; // 50000-350000
        const netProfit = Math.floor(holdingProfit * (0.5 + Math.random() * 0.4)); // 50%-90% of holdingProfit
        
        addresses.push({
          key: (i + 1).toString(),
          address: randomAddress,
          influenceScore: Math.floor(Math.random() * 40) + 60, // 60-99
          holdingValue: holdingValue,
          holdingChange: Math.floor(Math.random() * 200000) - 100000, // -100000 to 100000
          holdingProfit: holdingProfit,
          netProfit: netProfit
        });
      }
      
      return addresses;
    }
    
    return whaleMap[whaleId] || [];
  };

  // 模拟数据加载
  useEffect(() => {
    const timer = setTimeout(() => {
      // 模拟数据
      setStatsData({
        activeWhales: 5,
        smartWhales: 8,
        dumbWhales: 4, 
        successRate: 85.7,
      });

      setWhaleData([
        {
          key: '1',
          address: '0x1234...5678',
          label: '巨鲸A',
          influenceScore: 86,
          alertLevel: 'HIGH',
          recentActivity: '买入3个NFT',
          holdingValue: 1250000,
          holdingChange: 25000,
          holdingProfit: 180000,
          netProfit: 120000
        },
        {
          key: '2',
          address: '0x8765...4321',
          label: '巨鲸B',
          influenceScore: 74,
          alertLevel: 'MEDIUM',
          recentActivity: '卖出5个NFT',
          holdingValue: 880000,
          holdingChange: -15000,
          holdingProfit: 140000,
          netProfit: 95000
        },
        {
          key: '3',
          address: '0x5678...1234',
          label: '巨鲸C',
          influenceScore: 92,
          alertLevel: 'HIGH',
          recentActivity: '买入10个NFT',
          holdingValue: 1750000,
          holdingChange: 50000,
          holdingProfit: 350000,
          netProfit: 210000
        },
        {
          key: '4',
          address: '0xabcd...efgh',
          label: '巨鲸D',
          influenceScore: 78,
          alertLevel: 'MEDIUM',
          recentActivity: '买入2个NFT',
          holdingValue: 950000,
          holdingChange: 18000,
          holdingProfit: 175000,
          netProfit: 115000
        },
        {
          key: '5',
          address: '0x9876...5432',
          label: '巨鲸E',
          influenceScore: 65,
          alertLevel: 'LOW',
          recentActivity: '卖出1个NFT',
          holdingValue: 620000,
          holdingChange: -8000,
          holdingProfit: 85000,
          netProfit: 55000
        }
      ]);

      setLoading(false);
    }, 1000);

    return () => clearTimeout(timer);
  }, []);

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
          onClick={() => handleWalletClick(address, record.label)}
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
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>持仓变化</Text>,
      dataIndex: 'holdingChange',
      key: 'holdingChange',
      width: 140,
      render: (change: number) => <HoldingChange value={change} />,
    },
  ];

  // 添加表格样式和动画效果
  useEffect(() => {
    const style = document.createElement('style');
    style.innerHTML = `
      .ant-table-thead > tr > th {
        color: var(--text-primary) !important;
        font-weight: bold !important;
        border-bottom: 1px solid var(--border-color) !important;
      }
      
      /* 强制设置Statistic组件颜色 */
      .ant-statistic-content-value {
        color: inherit !important;
      }
      
      /* 新交易动画效果 */
      @keyframes newTransaction {
        0% {
          background-color: rgba(24, 144, 255, 0.4);
        }
        100% {
          background-color: rgba(24, 144, 255, 0.05);
        }
      }
      
      .new-transaction-animation {
        animation: newTransaction 2s ease-out;
      }
      
      /* 模态框样式优化 */
      .ant-modal-content {
        background: #001529 !important;
        border: 1px solid var(--border-color) !important;
        box-shadow: 0 0 20px var(--border-color) !important;
      }
      
      .ant-modal-header {
        background: #000c17 !important;
        border-bottom: 1px solid var(--border-color) !important;
      }
      
      .ant-modal-title {
        color: var(--text-primary) !important;
      }
      
      .ant-modal-close {
        color: var(--text-secondary) !important;
      }
      
      .ant-modal-close:hover {
        color: var(--text-primary) !important;
      }
    `;
    document.head.appendChild(style);
    
    return () => {
      document.head.removeChild(style);
    };
  }, []);

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
              value={35}
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
                        鲸鱼交易额Top10
                  </Text>
                    </div>
                    <div>
                      <Radio.Group 
                        value={whalesVolumeTimeRange} 
                        onChange={(e) => setWhalesVolumeTimeRange(e.target.value)}
                        size="small"
                      >
                        <Radio.Button value="day" style={{color: whalesVolumeTimeRange === 'day' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: whalesVolumeTimeRange === 'day' ? '#1890ff' : 'transparent'}}>当天</Radio.Button>
                        <Radio.Button value="week" style={{color: whalesVolumeTimeRange === 'week' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: whalesVolumeTimeRange === 'week' ? '#1890ff' : 'transparent'}}>近一周</Radio.Button>
                        <Radio.Button value="month" style={{color: whalesVolumeTimeRange === 'month' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: whalesVolumeTimeRange === 'month' ? '#1890ff' : 'transparent'}}>近一月</Radio.Button>
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
                        <Radio.Button value="day" style={{color: whalesProfitTimeRange === 'day' ? '#fff' : '#52c41a', borderColor: '#52c41a', backgroundColor: whalesProfitTimeRange === 'day' ? '#52c41a' : 'transparent'}}>当天</Radio.Button>
                        <Radio.Button value="week" style={{color: whalesProfitTimeRange === 'week' ? '#fff' : '#52c41a', borderColor: '#52c41a', backgroundColor: whalesProfitTimeRange === 'week' ? '#52c41a' : 'transparent'}}>近一周</Radio.Button>
                        <Radio.Button value="month" style={{color: whalesProfitTimeRange === 'month' ? '#fff' : '#52c41a', borderColor: '#52c41a', backgroundColor: whalesProfitTimeRange === 'month' ? '#52c41a' : 'transparent'}}>近一月</Radio.Button>
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
                      <Radio.Button value="inflow" style={{color: isInflow ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: isInflow ? '#1890ff' : 'transparent'}}>净流入</Radio.Button>
                      <Radio.Button value="outflow" style={{color: !isInflow ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: !isInflow ? '#1890ff' : 'transparent'}}>净流出</Radio.Button>
                    </Radio.Group>

                    <Radio.Group 
                      value={inflowWhaleType} 
                      onChange={(e) => setInflowWhaleType(e.target.value)}
                      size="small"
                      style={{ marginRight: 24 }}
                    >
                      <Radio.Button value="all" style={{color: inflowWhaleType === 'all' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: inflowWhaleType === 'all' ? '#1890ff' : 'transparent'}}>所有鲸鱼</Radio.Button>
                      <Radio.Button value="smart" style={{color: inflowWhaleType === 'smart' ? '#fff' : '#52c41a', borderColor: '#52c41a', backgroundColor: inflowWhaleType === 'smart' ? '#52c41a' : 'transparent'}}>聪明鲸鱼</Radio.Button>
                      <Radio.Button value="dumb" style={{color: inflowWhaleType === 'dumb' ? '#fff' : '#f5222d', borderColor: '#f5222d', backgroundColor: inflowWhaleType === 'dumb' ? '#f5222d' : 'transparent'}}>愚蠢鲸鱼</Radio.Button>
                    </Radio.Group>

                    <Radio.Group 
                      value={inflowTimeRange} 
                      onChange={(e) => setInflowTimeRange(e.target.value)}
                      size="small"
                    >
                      <Radio.Button value="day" style={{color: inflowTimeRange === 'day' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: inflowTimeRange === 'day' ? '#1890ff' : 'transparent'}}>当天</Radio.Button>
                      <Radio.Button value="week" style={{color: inflowTimeRange === 'week' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: inflowTimeRange === 'week' ? '#1890ff' : 'transparent'}}>近一周</Radio.Button>
                      <Radio.Button value="month" style={{color: inflowTimeRange === 'month' ? '#fff' : '#1890ff', borderColor: '#1890ff', backgroundColor: inflowTimeRange === 'month' ? '#1890ff' : 'transparent'}}>近一月</Radio.Button>
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
            scroll={{ x: 880 }}
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