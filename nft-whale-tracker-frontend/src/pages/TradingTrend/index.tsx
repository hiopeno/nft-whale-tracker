import React, { useState, useEffect } from 'react';
import { Card, Row, Col, Typography, Spin, Select, Radio, Space, Empty, Table, Button, Divider } from 'antd';
import { 
  SyncOutlined, 
  LineChartOutlined,
  SwapOutlined,
  WalletOutlined, 
  FileSearchOutlined
} from '@ant-design/icons';
import ReactECharts from 'echarts-for-react';
import * as echarts from 'echarts/core';

const { Title, Text } = Typography;
const { Option } = Select;

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

// 生成随机钱包地址
const generateRandomAddress = () => {
  const chars = '0123456789abcdef';
  let address = '0x';
  for (let i = 0; i < 40; i++) {
    address += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  // 返回格式化的地址，例如 0xabcd...1234
  return `${address.substring(0, 6)}...${address.substring(38, 42)}`;
};

// 生成NFT编号
const generateNftId = (collection: string) => {
  // 为不同的收藏集设置不同的ID范围
  const maxIds: { [key: string]: number } = {
    'BAYC': 10000,
    'CryptoPunks': 10000,
    'Azuki': 10000,
    'CloneX': 20000,
    'Doodles': 10000,
    'Moonbirds': 10000,
    'MAYC': 20000,
    'Otherdeeds': 100000,
    'CyberKongz': 5000,
    'Cool Cats': 9999
  };
  
  const max = maxIds[collection] || 10000;
  return `#${Math.floor(Math.random() * max) + 1}`;
};

// 生成模拟交易数据的函数
const generateTradeData = (collection: string, timeRange: 'day' | 'week' | 'month') => {
  // 根据不同的时间范围生成不同数量的数据点
  let days = 1;
  if (timeRange === 'week') days = 7;
  if (timeRange === 'month') days = 30;
  
  // 设置每个收藏集的基础价格和波动范围
  const basePrice: { [key: string]: number } = {
    'BAYC': 75.2,
    'CryptoPunks': 65.8,
    'Azuki': 12.4,
    'CloneX': 6.8,
    'Doodles': 8.2,
    'Moonbirds': 9.5,
    'MAYC': 16.3,
    'Otherdeeds': 2.7,
    'CyberKongz': 4.2,
    'Cool Cats': 1.8
  };
  
  const priceRange: { [key: string]: number } = {
    'BAYC': 8.5,
    'CryptoPunks': 7.3,
    'Azuki': 2.2,
    'CloneX': 1.5,
    'Doodles': 1.8,
    'Moonbirds': 2.1,
    'MAYC': 3.2,
    'Otherdeeds': 0.6,
    'CyberKongz': 0.9,
    'Cool Cats': 0.4
  };
  
  // 默认使用BAYC的数据
  const price = basePrice[collection] || basePrice['BAYC'];
  const range = priceRange[collection] || priceRange['BAYC'];
  
  // 获取当前时间作为结束时间
  const endDate = new Date();
  // 设置起始时间
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days + 1);
  startDate.setHours(0, 0, 0, 0);
  
  // 计算时间间隔
  const timeInterval = timeRange === 'day' ? 15 : (timeRange === 'week' ? 60 : 240); // 单位：分钟
  
  // 计算数据点数量
  const dataPoints = Math.floor((endDate.getTime() - startDate.getTime()) / (timeInterval * 60 * 1000));
  
  // 生成交易数据
  const data = [];
  let currentPrice = price;
  let currentDate = new Date(startDate);
  
  // 创建一些固定的鲸鱼地址，这样不同交易中可能出现相同的地址（模拟真实场景中的鲸鱼交易行为）
  const whaleAddresses = [
    '0xf34d...89ab', 
    '0xa278...56ef', 
    '0xc901...23de', 
    '0xb723...45fa', 
    '0xe567...90cd'
  ];
  
  for (let i = 0; i < dataPoints; i++) {
    // 添加一些随机波动
    const priceDelta = (Math.random() - 0.5) * range * 0.1;
    currentPrice += priceDelta;
    
    // 确保价格不会变为负数
    if (currentPrice < 0.1) currentPrice = 0.1;
    
    // 生成买卖地址
    let buyerAddress, sellerAddress;
    let to_is_whale = false;
    let from_is_whale = false;
    
    // 有20%概率使用鲸鱼地址作为买家或卖家
    if (Math.random() < 0.2) {
      buyerAddress = whaleAddresses[Math.floor(Math.random() * whaleAddresses.length)];
      to_is_whale = true; // 标记买家为鲸鱼
    } else {
      buyerAddress = generateRandomAddress();
    }
    
    if (Math.random() < 0.2) {
      sellerAddress = whaleAddresses[Math.floor(Math.random() * whaleAddresses.length)];
      from_is_whale = true; // 标记卖家为鲸鱼
    } else {
      sellerAddress = generateRandomAddress();
    }
    
    // 确保买家和卖家不是同一个地址
    while (buyerAddress === sellerAddress) {
      sellerAddress = generateRandomAddress();
      from_is_whale = false; // 重置卖家鲸鱼标记，因为地址已改变
    }
    
    // 生成NFT ID
    const nftId = generateNftId(collection);
    
    // 添加数据点
    data.push({
      id: `trade-${collection}-${i}`,
      time: currentDate.getTime(),
      date: currentDate.toISOString(),
      price: parseFloat(currentPrice.toFixed(2)),
      volume: Math.floor(Math.random() * 5) + 1,
      collection: collection,
      nftId: nftId,
      buyerAddress: buyerAddress,
      sellerAddress: sellerAddress,
      to_is_whale: to_is_whale,       // 新增：买家是否为鲸鱼
      from_is_whale: from_is_whale,   // 新增：卖家是否为鲸鱼
      // 添加一个显示名称，用于图表展示
      displayName: `${collection} ${nftId}`,
      // 为每笔交易添加一个随机的交易哈希
      txHash: `0x${Array(64).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('')}`
    });
    
    // 增加时间
    currentDate = new Date(currentDate.getTime() + timeInterval * 60 * 1000);
  }
  
  // 按时间排序
  return data.sort((a, b) => a.time - b.time);
};

// 价格走势图表组件
const PriceTrendChart: React.FC<{
  data: any[];
  loading: boolean;
  timeRange: 'day' | 'week' | 'month';
  onPointClick: (data: any) => void;
}> = ({ data, loading, timeRange, onPointClick }) => {
  // 图表配置
  const getOption = () => {
    // 如果没有数据，返回空配置
    if (data.length === 0) {
      return {
        title: {
          text: '无数据',
          left: 'center',
          top: 'center',
          textStyle: {
            color: 'rgba(255, 255, 255, 0.65)'
          }
        }
      };
    }
    
    // 提取时间和价格数据
    const timeData = data.map(item => item.time);
    const priceData = data.map(item => item.price);
    
    // 计算最大最小价格，用于设置y轴范围
    const minPrice = Math.min(...priceData) * 0.95;
    const maxPrice = Math.max(...priceData) * 1.05;
    
    // 为时间轴设定合适的刻度间隔
    const calculateTimeAxisInterval = () => {
      if (timeRange === 'day') {
        return 3600 * 1000 * 2; // 2小时
      } else if (timeRange === 'week') {
        return 3600 * 1000 * 24; // 1天
      } else {
        return 3600 * 1000 * 24 * 3; // 3天
      }
    };
    
    // 突出显示最高价和最低价
    const markPoints = [
      {
        name: '最高价',
        type: 'max',
        valueDim: 'y',
        symbol: 'circle',
        symbolSize: 10,
        label: {
          show: true,
          position: 'top',
          distance: 8,
          color: '#fff',
          backgroundColor: 'rgba(114, 46, 209, 0.8)',
          padding: [4, 8],
          borderRadius: 4,
          formatter: '{b}: {c} ETH',
          fontSize: 12
        },
        itemStyle: {
          color: '#722ed1'
        }
      },
      {
        name: '最低价',
        type: 'min',
        valueDim: 'y',
        symbol: 'circle',
        symbolSize: 10,
        label: {
          show: true,
          position: 'bottom',
          distance: 8,
          color: '#fff',
          backgroundColor: 'rgba(24, 144, 255, 0.8)',
          padding: [4, 8],
          borderRadius: 4,
          formatter: '{b}: {c} ETH',
          fontSize: 12
        },
        itemStyle: {
          color: '#1890ff'
        }
      }
    ];
    
    return {
      backgroundColor: 'transparent',
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'cross',
          crossStyle: {
            color: 'rgba(255, 255, 255, 0.3)'
          },
          lineStyle: {
            color: 'rgba(24, 144, 255, 0.6)',
            width: 1,
            type: 'dashed'
          },
          label: {
            backgroundColor: 'rgba(0, 21, 41, 0.8)',
            textStyle: {
              color: '#fff'
            }
          },
          shadowStyle: {
            color: 'rgba(24, 144, 255, 0.1)'
          }
        },
        formatter: (params: any) => {
          const dataIndex = params[0].dataIndex;
          const item = data[dataIndex];
          const date = new Date(item.time);
          const formattedDate = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
          
          // 为鲸鱼地址添加标记
          const buyerTag = item.to_is_whale ? ' 🐋' : '';
          const sellerTag = item.from_is_whale ? ' 🐋' : '';
          
          // 判断交易类型
          let tradeTypeColor = '#1890ff'; // 默认蓝色
          let tradeTypeName = '普通交易';
          
          if (item.to_is_whale) {
            tradeTypeColor = '#52c41a'; // 绿色
            tradeTypeName = '鲸鱼买入';
          } else if (item.from_is_whale) {
            tradeTypeColor = '#f5222d'; // 红色
            tradeTypeName = '鲸鱼卖出';
          }
          
          // 增强版提示框
          return `
            <div style="padding: 12px; border-radius: 4px; box-shadow: 0 3px 6px rgba(0,0,0,0.2);">
              <div style="font-weight: bold; margin-bottom: 10px; font-size: 13px; color: #fff;">${formattedDate}</div>
              <div style="margin-bottom: 8px; display: flex; align-items: center;">
                <span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background-color: ${tradeTypeColor}; margin-right: 6px;"></span>
                <span style="color: ${tradeTypeColor}; font-weight: bold;">${tradeTypeName}</span>
                <span style="margin-left: auto; background: rgba(24, 144, 255, 0.2); padding: 2px 6px; border-radius: 3px; color: #fff;">${item.price} ETH</span>
              </div>
              <div style="margin-bottom: 5px; font-size: 12px; color: rgba(255, 255, 255, 0.85);">
                <span style="color: rgba(255, 255, 255, 0.5);">NFT:</span> ${item.collection} ${item.nftId}
              </div>
              <div style="margin-bottom: 5px; font-size: 12px; color: rgba(255, 255, 255, 0.85);">
                <span style="color: rgba(255, 255, 255, 0.5);">买家:</span> ${item.buyerAddress}${buyerTag}
              </div>
              <div style="font-size: 12px; color: rgba(255, 255, 255, 0.85);">
                <span style="color: rgba(255, 255, 255, 0.5);">卖家:</span> ${item.sellerAddress}${sellerTag}
              </div>
            </div>
          `;
        },
        backgroundColor: 'rgba(0, 21, 41, 0.9)',
        borderColor: 'rgba(24, 144, 255, 0.3)',
        borderWidth: 1,
        padding: 0,
        textStyle: {
          color: 'rgba(255, 255, 255, 0.85)'
        },
        extraCssText: 'border-radius: 4px; backdrop-filter: blur(4px);'
      },
      grid: {
        left: '5%',
        right: '15%',
        bottom: '8%',
        top: '15%',
        containLabel: true
      },
      dataZoom: [
        {
          type: 'inside',
          start: 0,
          end: 100,
          filterMode: 'filter'
        },
        {
          show: true,
          type: 'slider',
          start: 0,
          end: 100,
          height: 20,
          bottom: '2%',
          borderColor: 'transparent',
          backgroundColor: 'rgba(255, 255, 255, 0.05)',
          fillerColor: 'rgba(24, 144, 255, 0.2)',
          handleIcon: 'path://M10.7,11.9v-1.3H9.3v1.3c-4.9,0.3-8.8,4.4-8.8,9.4c0,5,3.9,9.1,8.8,9.4v1.3h1.3v-1.3c4.9-0.3,8.8-4.4,8.8-9.4C19.5,16.3,15.6,12.2,10.7,11.9z M13.3,24.4H6.7V23h6.6V24.4z M13.3,19.6H6.7v-1.4h6.6V19.6z',
          handleSize: '80%',
          handleStyle: {
            color: '#1890ff',
            shadowBlur: 3,
            shadowColor: 'rgba(0, 0, 0, 0.6)',
            shadowOffsetX: 2,
            shadowOffsetY: 2
          },
          textStyle: {
            color: 'rgba(255, 255, 255, 0.65)'
          }
        }
      ],
      xAxis: {
        type: 'time',
        splitLine: {
          show: false
        },
        axisLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.2)'
          }
        },
        axisTick: {
          alignWithLabel: true,
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.2)'
          }
        },
        axisLabel: {
          color: 'rgba(255, 255, 255, 0.65)',
          margin: 12,
          formatter: (value: number) => {
            const date = new Date(value);
            if (timeRange === 'day') {
              return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
            } else if (timeRange === 'week') {
              return `${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:00`;
            } else {
              return `${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
            }
          },
          showMaxLabel: true,
          showMinLabel: true
        },
        splitNumber: 6,
        minInterval: calculateTimeAxisInterval(),
        boundaryGap: false
      },
      yAxis: {
        type: 'value',
        name: '价格 (ETH)',
        nameTextStyle: {
          padding: [0, 30, 0, 0],
          color: 'rgba(255, 255, 255, 0.65)',
          fontSize: 12,
          fontWeight: 'normal'
        },
        min: minPrice,
        max: maxPrice,
        position: 'left',
        axisLine: {
          show: false
        },
        axisTick: {
          show: false
        },
        splitNumber: 5,
        axisLabel: {
          color: 'rgba(255, 255, 255, 0.65)',
          formatter: '{value} ETH',
          margin: 10
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(255, 255, 255, 0.08)',
            type: 'dashed'
          }
        }
      },
      series: [
        {
          name: '价格',
          type: 'line',
          smooth: 0.3, // 适度平滑
          symbol: 'circle',
          symbolSize: (value: any, params: any) => {
            // 鲸鱼交易显示更大的点，普通交易不显示点
            const index = params.dataIndex;
            const item = data[index];
            return (item.to_is_whale || item.from_is_whale) ? 8 : 0; // 普通交易返回0，不显示点
          },
          sampling: 'average',
          itemStyle: {
            color: (params: any) => {
              const index = params.dataIndex;
              const item = data[index];
              // 根据鲸鱼买入/卖出状态设置不同颜色
              if (item.to_is_whale) {
                return '#52c41a'; // 绿色 - 鲸鱼买入
              } else if (item.from_is_whale) {
                return '#f5222d'; // 红色 - 鲸鱼卖出
              } else {
                return '#1890ff'; // 蓝色 - 普通交易
              }
            },
            // 添加阴影效果
            shadowColor: 'rgba(0, 0, 0, 0.3)',
            shadowBlur: 5
          },
          markPoint: {
            data: markPoints
          },
          lineStyle: {
            width: 3,
            shadowColor: 'rgba(24, 144, 255, 0.5)',
            shadowBlur: 10,
            // 线条使用渐变颜色
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              {
                offset: 0,
                color: 'rgba(24, 144, 255, 0.8)'
              },
              {
                offset: 1,
                color: 'rgba(24, 144, 255, 0.3)'
              }
            ])
          },
          areaStyle: {
            opacity: 0.3,
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              {
                offset: 0,
                color: 'rgba(24, 144, 255, 0.6)'
              },
              {
                offset: 0.5,
                color: 'rgba(24, 144, 255, 0.2)'
              },
              {
                offset: 1,
                color: 'rgba(24, 144, 255, 0.05)'
              }
            ])
          },
          emphasis: {
            focus: 'series',
            itemStyle: {
              shadowBlur: 10,
              shadowColor: 'rgba(255, 255, 255, 0.5)'
            }
          },
          data: data.map(item => [item.time, item.price])
        }
      ],
      legend: {
        data: ['价格'],
        textStyle: {
          color: 'rgba(255, 255, 255, 0.65)'
        },
        top: 10,
        icon: 'roundRect',
        itemWidth: 12,
        itemHeight: 4,
        itemGap: 20
      },
      graphic: [
        {
          type: 'group',
          right: 20,
          top: 50,
          children: [
            {
              type: 'rect',
              left: 'center',
              top: 'center',
              z: -1,
              shape: {
                width: 100,
                height: 60, // 减小高度，因为少了一个图例项
                r: 6
              },
              style: {
                fill: 'rgba(0, 21, 41, 0.6)',
                shadowBlur: 10,
                shadowColor: 'rgba(0, 0, 0, 0.3)',
                shadowOffsetX: 2,
                shadowOffsetY: 4
              }
            },
            {
              type: 'text',
              left: 10,
              top: 8,
              style: {
                text: '交易类型',
                fill: 'rgba(255, 255, 255, 0.85)',
                fontSize: 12,
                fontWeight: 'bold'
              }
            },
            {
              type: 'circle',
              shape: { r: 5 },
              left: 15,
              top: 30,
              style: { fill: '#52c41a' }
            },
            {
              type: 'text',
              style: {
                text: '鲸鱼买入',
                fill: 'rgba(255, 255, 255, 0.85)',
                fontSize: 12
              },
              left: 30,
              top: 25
            },
            {
              type: 'circle',
              shape: { r: 5 },
              left: 15,
              top: 55,
              style: { fill: '#f5222d' }
            },
            {
              type: 'text',
              style: {
                text: '鲸鱼卖出',
                fill: 'rgba(255, 255, 255, 0.85)',
                fontSize: 12
              },
              left: 30,
              top: 50
            }
          ]
        }
      ],
      animationDuration: 1500,
      animationEasing: 'cubicInOut',
      animationDelay: function (idx: number) {
        return idx * 20;
      }
    };
  };
  
  const onChartClick = (params: any) => {
    if (params.componentType === 'series') {
      const dataIndex = params.dataIndex;
      onPointClick(data[dataIndex]);
    }
  };
  
  if (loading) {
    return <TechLoading />;
  }
  
  return (
    <ReactECharts
      option={getOption()}
      style={{ height: 500, width: '100%' }}
      className="react-echarts"
      onEvents={{ click: onChartClick }}
    />
  );
};

// 交易明细表格组件
const TransactionTable: React.FC<{
  data: any[];
  loading: boolean;
}> = ({ data, loading }) => {
  const columns = [
    {
      title: '时间',
      dataIndex: 'time',
      key: 'time',
      render: (time: number) => {
        const date = new Date(time);
        return <span style={{ color: 'var(--text-primary)' }}>{`${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`}</span>;
      }
    },
    {
      title: 'NFT',
      dataIndex: 'displayName',
      key: 'displayName',
      render: (text: string) => <span style={{ color: 'var(--text-primary)' }}>{text}</span>
    },
    {
      title: '价格 (ETH)',
      dataIndex: 'price',
      key: 'price',
      render: (price: number) => <span style={{ color: 'var(--text-primary)' }}>{price.toFixed(2)}</span>
    },
    {
      title: '买家',
      dataIndex: 'buyerAddress',
      key: 'buyerAddress',
      render: (text: string, record: any) => (
        <span style={{ color: 'var(--text-primary)' }}>
          {text} {record.to_is_whale && <span title="鲸鱼">🐋</span>}
        </span>
      )
    },
    {
      title: '卖家',
      dataIndex: 'sellerAddress',
      key: 'sellerAddress',
      render: (text: string, record: any) => (
        <span style={{ color: 'var(--text-primary)' }}>
          {text} {record.from_is_whale && <span title="鲸鱼">🐋</span>}
        </span>
      )
    }
  ];
  
  return (
    <Table 
      columns={columns} 
      dataSource={data} 
      rowKey="id" 
      loading={loading}
      pagination={{ pageSize: 10 }}
      scroll={{ x: 'max-content' }}
      className="trading-table"
    />
  );
};

// 交易走势页面组件
const TradingTrend: React.FC = () => {
  // 状态定义
  const [selectedCollection, setSelectedCollection] = useState<string>('BAYC');
  const [timeRange, setTimeRange] = useState<'day' | 'week' | 'month'>('week');
  const [showTable, setShowTable] = useState<boolean>(false);
  const [selectedTrade, setSelectedTrade] = useState<any>(null);
  const [tradeData, setTradeData] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  
  // 收藏集选项
  const collections = [
    { value: 'BAYC', label: 'Bored Ape Yacht Club' },
    { value: 'CryptoPunks', label: 'CryptoPunks' },
    { value: 'Azuki', label: 'Azuki' },
    { value: 'CloneX', label: 'CloneX' },
    { value: 'Doodles', label: 'Doodles' },
    { value: 'Moonbirds', label: 'Moonbirds' },
    { value: 'MAYC', label: 'Mutant Ape Yacht Club' },
    { value: 'Otherdeeds', label: 'Otherdeeds' },
    { value: 'CyberKongz', label: 'CyberKongz' },
    { value: 'Cool Cats', label: 'Cool Cats' }
  ];
  
  // 集中获取数据
  useEffect(() => {
    setLoading(true);
    // 模拟API请求延迟
    const timer = setTimeout(() => {
      const data = generateTradeData(selectedCollection, timeRange);
      setTradeData(data);
      setLoading(false);
      // 清除选中的交易详情
      setSelectedTrade(null);
    }, 500);
    
    return () => clearTimeout(timer);
  }, [selectedCollection, timeRange]);
  
  const handlePointClick = (data: any) => {
    setSelectedTrade(data);
  };
  
  return (
    <div>
      <TechTitle>交易走势</TechTitle>
      
      <Row gutter={[16, 16]}>
        <Col span={24}>
          <Card 
            title={
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <LineChartOutlined style={{ color: 'var(--primary)', marginRight: 8 }} />
                <Text style={{ color: 'var(--text-primary)' }}>价格走势分析</Text>
              </div>
            } 
            bordered={false}
            extra={
              <Space>
                <Select 
                  value={selectedCollection}
                  onChange={setSelectedCollection}
                  style={{ width: 200 }}
                  dropdownStyle={{ background: 'var(--bg-dropdown)', color: 'var(--text-primary)' }}
                >
                  {collections.map(collection => (
                    <Option key={collection.value} value={collection.value}>{collection.label}</Option>
                  ))}
                </Select>
                <Radio.Group 
                  value={timeRange} 
                  onChange={e => setTimeRange(e.target.value)}
                  buttonStyle="solid"
                >
                  <Radio.Button value="day">当天</Radio.Button>
                  <Radio.Button value="week">一周</Radio.Button>
                  <Radio.Button value="month">一月</Radio.Button>
                </Radio.Group>
                <Button
                  type={showTable ? "primary" : "default"}
                  icon={<FileSearchOutlined />}
                  onClick={() => setShowTable(!showTable)}
                >
                  {showTable ? "隐藏表格" : "查看表格"}
                </Button>
              </Space>
            }
          >
            <PriceTrendChart 
              data={tradeData}
              loading={loading}
              timeRange={timeRange}
              onPointClick={handlePointClick}
            />
            
            {selectedTrade && (
              <div style={{ marginTop: 16, padding: 16, background: 'rgba(24, 144, 255, 0.1)', borderRadius: 8, border: '1px solid rgba(24, 144, 255, 0.2)' }}>
                <Title level={4} style={{ color: 'var(--text-primary)' }}>交易详情</Title>
                <Row gutter={16}>
                  <Col xs={24} sm={12} md={8} lg={6}>
                    <Text style={{ color: 'var(--text-secondary)' }}>NFT：</Text>
                    <Text style={{ color: 'var(--text-primary)' }}>{selectedTrade.collection} {selectedTrade.nftId}</Text>
                  </Col>
                  <Col xs={24} sm={12} md={8} lg={6}>
                    <Text style={{ color: 'var(--text-secondary)' }}>价格：</Text>
                    <Text style={{ color: 'var(--text-primary)' }}>{selectedTrade.price} ETH</Text>
                  </Col>
                  <Col xs={24} sm={12} md={8} lg={6}>
                    <Text style={{ color: 'var(--text-secondary)' }}>时间：</Text>
                    <Text style={{ color: 'var(--text-primary)' }}>{new Date(selectedTrade.time).toLocaleString()}</Text>
                  </Col>
                </Row>
                <Row gutter={16} style={{ marginTop: 8 }}>
                  <Col xs={24} sm={12}>
                    <Text style={{ color: 'var(--text-secondary)' }}>买家：</Text>
                    <Text style={{ color: 'var(--text-primary)' }}>
                      {selectedTrade.buyerAddress} {selectedTrade.to_is_whale && '🐋'}
                    </Text>
                  </Col>
                  <Col xs={24} sm={12}>
                    <Text style={{ color: 'var(--text-secondary)' }}>卖家：</Text>
                    <Text style={{ color: 'var(--text-primary)' }}>
                      {selectedTrade.sellerAddress} {selectedTrade.from_is_whale && '🐋'}
                    </Text>
                  </Col>
                </Row>
                <Row style={{ marginTop: 8 }}>
                  <Col span={24}>
                    <Text style={{ color: 'var(--text-secondary)' }}>交易哈希：</Text>
                    <Text style={{ color: 'var(--text-primary)' }}>{selectedTrade.txHash}</Text>
                  </Col>
                </Row>
              </div>
            )}
          </Card>
        </Col>
      </Row>
      
      {showTable && (
        <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
          <Col span={24}>
            <Card 
              title={
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <SwapOutlined style={{ color: 'var(--primary)', marginRight: 8 }} />
                  <Text style={{ color: 'var(--text-primary)' }}>交易明细</Text>
                </div>
              } 
              bordered={false}
            >
              <TransactionTable 
                data={tradeData}
                loading={loading}
              />
            </Card>
          </Col>
        </Row>
      )}
    </div>
  );
};

export default TradingTrend; 