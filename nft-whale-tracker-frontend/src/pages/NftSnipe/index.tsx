import React, { useState, useEffect, useRef } from 'react';
import { Card, Row, Col, Statistic, Typography, List, Tag, Avatar, Button, Space, Tooltip, Badge, Radio, Select, Calendar, Table } from 'antd';
import { ClockCircleOutlined, DollarOutlined, PercentageOutlined, FireOutlined, ArrowDownOutlined, ArrowUpOutlined, SwapOutlined, StarOutlined, TagOutlined, CaretDownOutlined, UserOutlined, SwapRightOutlined, CalendarOutlined } from '@ant-design/icons';
import type { RadioChangeEvent } from 'antd';
import type { Dayjs } from 'dayjs';
import dayjs from 'dayjs';

const { Text, Title } = Typography;

// 科技风格标题组件
const TechTitle: React.FC<{children: React.ReactNode}> = ({ children }) => (
  <Title 
    level={2} 
    className="tech-page-title"
  >
    {children}
  </Title>
);

// 低价藏品标签组件
const DiscountTag: React.FC<{discount: number}> = ({ discount }) => {
  let color = '#52c41a';
  
  if (discount > 20) {
    color = '#faad14';
  }
  
  if (discount > 30) {
    color = '#f5222d';
  }
  
  return (
    <Tag
      color={color}
      style={{ marginLeft: 8, fontSize: 12 }}
    >
      折扣: {discount}%
    </Tag>
  );
};

// 稀有度标签组件
const RarityTag: React.FC<{rarity: number, total: number}> = ({ rarity, total }) => {
  const percentage = Math.round((rarity / total) * 100);
  return (
    <Tag
      color="#1890ff"
      style={{ marginLeft: 8, fontSize: 12 }}
    >
      稀有度: TOP {percentage}%
    </Tag>
  );
};

// 定义筛选选项
const DISCOUNT_OPTIONS = [
  { value: 'all', label: '全部折扣' },
  { value: 'high_discount', label: '高折扣(>30%)', color: '#f5222d' },
  { value: 'medium_discount', label: '中折扣(>20%)', color: '#faad14' },
  { value: 'low_discount', label: '低折扣(≤20%)', color: '#52c41a' }
];

const TIME_OPTIONS = [
  { value: 'all', label: '全部时间' },
  { value: 'hour', label: '1小时内' },
  { value: 'day', label: '24小时内' }
];

// 渲染价格变化（改为显示相对市场价的折扣）
const renderPriceChange = (currentPrice: number, marketPrice: number) => {
  // 计算折扣率
  const discountRate = ((marketPrice - currentPrice) / marketPrice) * 100;
  
  // 折扣率始终是正数
  return (
    <Text style={{ color: '#f5222d', fontSize: 12 }}>
      <ArrowDownOutlined /> -{discountRate.toFixed(1)}%
    </Text>
  );
};

// 实时低价藏品流组件
const LiveDiscountStream: React.FC = () => {
  const [discountItems, setDiscountItems] = useState<any[]>([]);
  const [isNewItem, setIsNewItem] = useState(false);
  const [tagFilter, setTagFilter] = useState<string>('all');
  const [timeFilter, setTimeFilter] = useState<string>('all');
  const [hoveredItem, setHoveredItem] = useState<number | null>(null);
  const listRef = useRef<HTMLDivElement>(null);

  // 模拟数据
  const mockDiscountItems = [
    {
      id: '1',
      time: '刚刚',
      nftName: 'BoredApe #8765',
      collectionName: 'Bored Ape Yacht Club',
      collectionIcon: 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?w=500&auto=format',
      currentPrice: 68.5,
      marketPrice: 95.2,
      discount: 28.0,
      rarity: 234,
      totalSupply: 10000,
      listingUrl: 'https://opensea.io/assets/ethereum/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d/8765',
      marketPlace: 'OpenSea',
      seller: '0x7823...45fa',
      lastSalePrice: 75.2,
      priceChange: -8.9
    },
    {
      id: '2',
      time: '2分钟前',
      nftName: 'CryptoPunk #4578',
      collectionName: 'CryptoPunks',
      collectionIcon: 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?w=500&auto=format',
      currentPrice: 58.2,
      marketPrice: 77.5,
      discount: 24.9,
      rarity: 567,
      totalSupply: 10000,
      listingUrl: 'https://opensea.io/assets/ethereum/0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb/4578',
      marketPlace: 'Blur',
      seller: '0x3467...12ab',
      lastSalePrice: 62.5,
      priceChange: -6.8
    },
    {
      id: '3',
      time: '5分钟前',
      nftName: 'Azuki #2341',
      collectionName: 'Azuki',
      collectionIcon: 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?w=500&auto=format',
      currentPrice: 9.8,
      marketPrice: 14.2,
      discount: 31.0,
      rarity: 132,
      totalSupply: 10000,
      listingUrl: 'https://opensea.io/assets/ethereum/0xed5af388653567af2f388e6224dc7c4b3241c544/2341',
      expiresIn: '2小时15分钟',
      marketPlace: 'OpenSea',
      seller: '0xd678...34ef',
      lastSalePrice: 10.5,
      priceChange: 0.7
    },
    {
      id: '4',
      time: '8分钟前',
      nftName: 'Doodle #6789',
      collectionName: 'Doodles',
      collectionIcon: 'https://i.seadn.io/gae/7B0qai02OdHA8P_EOVK672qUliyjQdQDGNrACxs7WnTgZAkJa_wWURnIFKeOh5VTf8cfTqW3wQpozGedaC9mteKphEOtztls02RlWQ?w=500&auto=format',
      currentPrice: 5.2,
      marketPrice: 6.5,
      discount: 20.0,
      rarity: 3452,
      totalSupply: 10000,
      listingUrl: 'https://opensea.io/assets/ethereum/0x8a90cab2b38dba80c64b7734e58ee1db38b8992e/6789',
      expiresIn: '3小时42分钟',
      marketPlace: 'Blur',
      seller: '0x8765...4321',
      lastSalePrice: 5.8,
      priceChange: 0.6
    },
    {
      id: '5',
      time: '12分钟前',
      nftName: 'Moonbird #4231',
      collectionName: 'Moonbirds',
      collectionIcon: 'https://i.seadn.io/gae/H-eyNE1MwL5ohL-tCfn_Xa1Sl9M9B4612tLYeUlQubzt4ewhr4huJIR5OLuyO3Z5PpJFSwdm7rq-TikAh7f5eUw338A2cy6HRH75?w=500&auto=format',
      currentPrice: 6.8,
      marketPrice: 9.7,
      discount: 29.9,
      rarity: 567,
      totalSupply: 10000,
      listingUrl: 'https://opensea.io/assets/ethereum/0x23581767a106ae21c074b2276d25e5c3e136a68b/4231',
      expiresIn: '1小时5分钟',
      marketPlace: 'OpenSea',
      seller: '0x1234...5678',
      lastSalePrice: 7.2,
      priceChange: 0.4
    }
  ];
  
  // 模拟数据加载和实时更新
  useEffect(() => {
    // 初始数据
    setDiscountItems(mockDiscountItems.slice(0, 3));
    
    // 模拟实时更新
    const interval = setInterval(() => {
      const randomIndex = Math.floor(Math.random() * mockDiscountItems.length);
      const newItem = {
        ...mockDiscountItems[randomIndex],
        id: Date.now().toString(),
        time: '刚刚',
        expiresIn: `${Math.floor(Math.random() * 3) + 1}小时${Math.floor(Math.random() * 59) + 1}分钟`,
        currentPrice: parseFloat((mockDiscountItems[randomIndex].currentPrice * (0.95 + Math.random() * 0.1)).toFixed(2)),
        lastSalePrice: parseFloat((mockDiscountItems[randomIndex].currentPrice * (1.05 + Math.random() * 0.15)).toFixed(2)),
      };
      
      // 更新折扣率
      newItem.discount = parseFloat((((newItem.marketPrice - newItem.currentPrice) / newItem.marketPrice) * 100).toFixed(1));
      
      setDiscountItems(prev => [newItem, ...prev.slice(0, 4)]);
      setIsNewItem(true);
      
      setTimeout(() => {
        setIsNewItem(false);
      }, 1000);
      
    }, 10000); // 每10秒更新一次
    
    return () => clearInterval(interval);
  }, []);
  
  // 获取过滤后的低价藏品
  const getFilteredDiscountItems = () => {
    let filtered = [...discountItems];
    
    // 根据标签筛选
    if (tagFilter !== 'all') {
      filtered = filtered.filter(item => {
        if (tagFilter === 'high_discount' && item.discount > 30) return true;
        if (tagFilter === 'medium_discount' && item.discount > 20 && item.discount <= 30) return true;
        if (tagFilter === 'low_discount' && item.discount <= 20) return true;
        return false;
      });
    }
    
    // 根据时间筛选
    if (timeFilter !== 'all') {
      // 由于我们的时间是模拟的，这里简单处理
      if (timeFilter === 'hour') {
        filtered = filtered.filter(item => item.time === '刚刚' || item.time.includes('分钟前'));
      }
      if (timeFilter === 'day') {
        filtered = filtered.filter(item => !item.time.includes('天前'));
      }
    }
    
    return filtered;
  };
  
        return (
    <Card 
      title={
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Text style={{ 
              color: 'rgba(255, 255, 255, 0.85)', 
              fontSize: 16, 
              fontWeight: 500 
            }}>
              实时低价藏品流
            </Text>
            <Badge 
              count={getFilteredDiscountItems().length} 
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
              placeholder="折扣范围"
              bordered={false}
              suffixIcon={<CaretDownOutlined style={{ color: 'rgba(255, 255, 255, 0.45)' }} />}
            >
              {DISCOUNT_OPTIONS.map(option => (
                <Select.Option 
                  key={option.value} 
                  value={option.value}
                >
                  <div style={{ 
                    display: 'flex', 
                    alignItems: 'center',
                    color: option.value === 'all' ? 'rgba(255, 255, 255, 0.85)' : option.color
                  }}>
                    {option.value !== 'all' && <div style={{
                      width: 6,
                      height: 6,
                      borderRadius: '50%',
                      backgroundColor: option.color,
                      marginRight: 6
                    }} />}
                    {option.label}
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
      bodyStyle={{ padding: 0, overflow: 'auto', height: '100%' }}
      ref={listRef}
    >
      <List
        itemLayout="horizontal"
        dataSource={getFilteredDiscountItems()}
        renderItem={(item, index) => (
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
          >
            <div style={{ display: 'flex', width: '100%' }}>
              {/* 左侧：NFT图片 */}
              <div style={{ marginRight: 16, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                <Avatar 
                  src={item.collectionIcon} 
                  size={60} 
                  style={{ 
                    border: item.discount > 30 ? '2px solid #f5222d' : '1px solid rgba(24, 144, 255, 0.3)',
                    boxShadow: item.discount > 30 ? '0 0 10px rgba(245, 34, 45, 0.5)' : 'none',
                    marginBottom: 8
                  }} 
                />
              </div>
              
              {/* 中间：交易详情 */}
              <div style={{ flex: 1 }}>
                {/* 第一行：NFT名称、标签、时间 */}
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                  <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap' }}>
                    <Text style={{ color: '#1890ff', fontWeight: 'bold', fontSize: 16 }}>{item.nftName}</Text>
                    <Tag 
                      color="#f5222d"
                      style={{ marginLeft: 8, fontSize: 12 }}
                    >
                      折扣: {item.discount.toFixed(1)}%
                    </Tag>
                    <Tag 
                      color={item.marketPlace === 'OpenSea' ? '#2081E2' : '#0052FF'} 
                      style={{ marginLeft: 8, fontSize: 12 }}
                    >
                      {item.marketPlace}
                    </Tag>
                  </div>
                  <Text style={{ color: 'rgba(255, 255, 255, 0.45)', fontSize: 12 }}>{item.time}</Text>
                </div>
                
                {/* 第二行：收藏集 */}
                <div style={{ marginBottom: 6 }}>
                  <Text style={{ color: 'rgba(255, 255, 255, 0.65)', fontSize: 13 }}>
                    收藏集: {item.collectionName}
                  </Text>
                </div>
                
                {/* 第三行：卖家、价格信息 */}
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                  <div style={{ 
                    display: 'flex', 
                    alignItems: 'center',
                    background: 'rgba(0, 0, 0, 0.15)',
                    padding: '4px 8px',
                    borderRadius: '4px',
                    boxShadow: '0 1px 2px rgba(0,0,0,0.1)',
                    height: 24
                  }}>
                    <Tooltip title={`卖家地址: ${item.seller}`}>
                      <div style={{ 
                        display: 'flex', 
                        alignItems: 'center',
                        padding: '2px 6px',
                        borderRadius: '4px',
                        background: 'transparent',
                        lineHeight: '20px'
                      }}>
                        <UserOutlined style={{ 
                          marginRight: 4,
                          color: 'rgba(255, 255, 255, 0.45)',
                          fontSize: 14
                        }} />
                        <Text style={{ 
                          color: 'rgba(255, 255, 255, 0.65)',
                          fontSize: 13
                        }}>{item.seller}</Text>
                      </div>
                    </Tooltip>
                  </div>
                </div>
              </div>
              
              {/* 右侧：价格和抢购按钮 */}
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', justifyContent: 'center', marginLeft: 16 }}>
                <div style={{ 
                  color: '#f5222d', 
                  fontWeight: 'bold', 
                  textShadow: '0 0 5px rgba(245, 34, 45, 0.3)',
                  fontSize: 18,
                  marginBottom: 8
                }}>
                  {item.currentPrice.toFixed(2)} ETH
                </div>
                {renderPriceChange(item.currentPrice, item.marketPrice)}
                <div style={{ marginTop: 8 }}>
                  <Button 
                    type="primary" 
                    danger
                    size="small"
                    icon={<FireOutlined />}
                    style={{
                      background: '#f5222d',
                      borderColor: '#f5222d',
                      boxShadow: '0 2px 6px rgba(255, 77, 79, 0.2)',
                    }}
                    onClick={() => window.open(item.listingUrl, '_blank')}
                  >
                    抢购
                  </Button>
                </div>
              </div>
            </div>
          </List.Item>
        )}
      />
    </Card>
  );
};

// NFT藏品统计日历组件
const NftCalendar: React.FC = () => {
  const [dataType, setDataType] = useState<'count' | 'profit'>('count');
  
  // 生成模拟数据 - 最近3个月的数据
  const generateMockData = () => {
    const today = dayjs();
    const startDate = dayjs().subtract(2, 'month').startOf('month');
    const endDate = dayjs().endOf('month');
    
    const mockData: {[key: string]: {count: number; profit: number}} = {};
    
    // 从2个月前到当前月底生成数据
    let currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isSame(endDate)) {
      const dateStr = currentDate.format('YYYY-MM-DD');
      
      // 生成随机数据，越接近当前日期，数据越多
      const dateWeight = Math.min(1, 1 - (today.diff(currentDate, 'day') / 60));
      
      // 过去的日期有数据，未来日期没有数据
      if (currentDate.isBefore(today) || currentDate.isSame(today)) {
        const count = Math.floor(Math.random() * 10 * dateWeight) + 1;
        
        const avgDiscount = Math.random() * 0.2 + 0.15; // 15%-35%的折扣
        const avgPrice = Math.random() * 20 + 5; // 5-25 ETH
        
        // 理论收益 = 折扣率 * 平均价格 * 藏品数
        const profit = parseFloat((count * avgPrice * avgDiscount).toFixed(2));
        
        mockData[dateStr] = { count, profit };
      }
      
      currentDate = currentDate.add(1, 'day');
    }
    
    return mockData;
  };
  
  const calendarData = generateMockData();
  
  // 渲染日期单元格
  const dateCellRender = (date: Dayjs) => {
    const dateStr = date.format('YYYY-MM-DD');
    const data = calendarData[dateStr];
    
    if (!data || (dataType === 'count' && data.count === 0) || (dataType === 'profit' && data.profit === 0)) {
      return <div className="cell-content empty-cell"></div>;
    }
    
    // 获取显示值的强度(0-1)
    const getIntensity = (value: number, isProfit: boolean) => {
      // 收益和数量使用不同的评分标准
      const intensity = isProfit 
        ? Math.min(1, value / 15) 
        : Math.min(1, value / 7);
      
      return Math.max(0.3, intensity); // 最小透明度为0.3
    };
    
    if (dataType === 'count') {
      const intensity = getIntensity(data.count, false);
      return (
        <div className="cell-content">
          <div className="data-dot" style={{ opacity: intensity }}></div>
          <span className="data-value">{data.count}</span>
        </div>
      );
    } else {
      const intensity = getIntensity(data.profit, true);
      return (
        <div className="cell-content">
          <div className="data-dot" style={{ opacity: intensity }}></div>
          <span className="data-value">{data.profit} <span className="eth-unit">ETH</span></span>
        </div>
      );
    }
  };
  
  // 处理数据类型切换
  const handleDataTypeChange = (e: RadioChangeEvent) => {
    setDataType(e.target.value);
  };
  
  return (
    <Card 
      className="tech-card"
      title={
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <CalendarOutlined style={{ marginRight: 8, color: '#1890ff' }} />
            <Text style={{ color: 'rgba(255, 255, 255, 0.85)', fontSize: 16, fontWeight: 500 }}>
              藏品统计日历
            </Text>
          </div>
          <Radio.Group 
            value={dataType} 
            onChange={handleDataTypeChange} 
            buttonStyle="solid"
            size="small"
          >
            <Radio.Button value="count">低价藏品数量</Radio.Button>
            <Radio.Button value="profit">理论可获收益</Radio.Button>
          </Radio.Group>
        </div>
      }
      bordered={false}
    >
      <Calendar 
        dateCellRender={dateCellRender}
        fullscreen={false}
        className="nft-calendar"
      />
      <style>{`
        .nft-calendar .ant-picker-calendar-date-content {
          height: 40px;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        .nft-calendar .cell-content.empty-cell {
          height: 18px;
        }
        .nft-calendar .ant-radio-button-wrapper {
          background: rgba(0, 21, 41, 0.5);
          border-color: #1890ff;
          color: rgba(255, 255, 255, 0.65);
        }
        .nft-calendar .ant-radio-button-wrapper-checked {
          background: #1890ff;
          color: white;
        }
        .nft-calendar .ant-badge-count {
          font-size: 12px;
          min-width: 18px;
          height: 18px;
          line-height: 18px;
        }
        
        /* 暗色主题样式 */
        .nft-calendar {
          background: rgba(0, 21, 41, 0.7);
          border-radius: 4px;
        }
        .nft-calendar .ant-picker-panel {
          background: transparent;
        }
        .nft-calendar .ant-picker-calendar-header {
          color: rgba(255, 255, 255, 0.85);
          border-bottom: 1px solid rgba(24, 144, 255, 0.2);
          padding: 8px 0;
        }
        .nft-calendar .ant-picker-calendar-header .ant-picker-calendar-mode-switch {
          display: none;
        }
        .nft-calendar .ant-select-selector,
        .nft-calendar .ant-select-dropdown {
          background: rgba(0, 21, 41, 0.8) !important;
          color: rgba(255, 255, 255, 0.85) !important;
          border-color: rgba(24, 144, 255, 0.3) !important;
        }
        .nft-calendar .ant-select-arrow {
          color: rgba(255, 255, 255, 0.6);
        }
        .nft-calendar .ant-picker-cell {
          color: rgba(255, 255, 255, 0.45);
          width: 14.28%; /* 100% / 7 = 14.28% 正好是每周七天 */
          box-sizing: border-box;
          padding: 0;
        }
        .nft-calendar .ant-picker-cell-in-view {
          color: rgba(255, 255, 255, 0.85);
        }
        .nft-calendar .ant-picker-cell-selected .ant-picker-calendar-date,
        .nft-calendar .ant-picker-calendar-date-today {
          background: rgba(24, 144, 255, 0.2);
          border-color: #1890ff;
        }
        .nft-calendar .ant-picker-cell-disabled {
          color: rgba(255, 255, 255, 0.15);
          background: rgba(0, 0, 0, 0.1);
        }
        .nft-calendar .ant-picker-calendar-date {
          background: rgba(0, 21, 41, 0.4);
          border-color: rgba(24, 144, 255, 0.1);
          transition: all 0.3s;
          height: 0;
          padding-bottom: 100%; /* 使单元格成为正方形 */
          position: relative;
          width: 100%;
          box-sizing: border-box;
        }
        .nft-calendar .ant-picker-calendar-date:hover {
          background: rgba(24, 144, 255, 0.1);
        }
        .nft-calendar .ant-picker-calendar-date-value {
          color: rgba(255, 255, 255, 0.85);
          position: absolute;
          top: 8px;
          left: 8px;
        }
        .nft-calendar .ant-picker-calendar-date-content {
          position: absolute;
          top: 50%;
          left: 0;
          width: 100%;
          transform: translateY(-50%);
          height: auto;
          min-height: unset;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        .nft-calendar .ant-picker-content th {
          color: rgba(255, 255, 255, 0.65);
          font-weight: normal;
        }
        .nft-calendar .ant-picker-content td {
          height: 0; /* 重置td的高度，让内容自己撑起来 */
          position: relative;
          padding: 0;
        }
        .nft-calendar .data-dot {
          width: 16px;
          height: 16px;
          border-radius: 50%;
          background-color: #1890ff;
          margin-bottom: 4px;
          box-shadow: 0 0 8px rgba(24, 144, 255, 0.3);
          transition: all 0.3s ease;
        }
        .nft-calendar .cell-content:hover .data-dot {
          transform: scale(1.2);
          box-shadow: 0 0 12px rgba(24, 144, 255, 0.5);
        }
        .nft-calendar .data-value {
          font-size: 13px;
          color: rgba(255, 255, 255, 0.85);
          font-weight: 500;
        }
        .nft-calendar .eth-unit {
          font-size: 10px;
          color: rgba(255, 255, 255, 0.65);
          font-weight: normal;
          margin-left: 2px;
        }
        .nft-calendar .cell-content {
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          width: 100%;
          height: 100%;
        }
      `}</style>
    </Card>
  );
};

// 统计卡片组件
const StatisticCard: React.FC<{
  title: string;
  value: string | number;
  icon: React.ReactNode;
  color: string;
}> = ({ title, value, icon, color }) => {
  return (
    <Card 
      className="tech-card"
      hoverable
      bordered={false}
    >
      <Statistic
        title={<Text style={{ color: 'rgba(255, 255, 255, 0.65)' }}>{title}</Text>}
        value={value}
        valueStyle={{ color, textShadow: `0 0 10px ${color}50` }}
        prefix={icon}
      />
    </Card>
  );
};

// 折扣机会表格组件
const DiscountOpportunitiesTable: React.FC = () => {
  // 模拟表格数据
  const mockTableData = Array.from({ length: 10 }).map((_, index) => {
    const currentPrice = parseFloat((Math.random() * 70 + 30).toFixed(2));
    const marketPrice = parseFloat((currentPrice * (1 + Math.random() * 0.4 + 0.1)).toFixed(2));
    const discountRate = parseFloat(((marketPrice - currentPrice) / marketPrice * 100).toFixed(1));
    
    return {
      key: index,
      nftId: `#${Math.floor(Math.random() * 10000)}`,
      collectionId: ['Bored Ape Yacht Club', 'CryptoPunks', 'Azuki', 'Doodles', 'CloneX'][Math.floor(Math.random() * 5)],
      currentPrice: currentPrice,
      marketPrice: marketPrice,
      discountRate: discountRate,
    };
  });

  const columns = [
    {
      title: 'NFT ID',
      dataIndex: 'nftId',
      key: 'nftId',
      render: (text: string) => <Text style={{ color: '#1890ff' }}>{text}</Text>,
    },
    {
      title: '藏品ID',
      dataIndex: 'collectionId',
      key: 'collectionId',
      render: (text: string) => (
        <Tag color="blue" style={{ background: 'rgba(24, 144, 255, 0.15)' }}>
          {text}
        </Tag>
      ),
    },
    {
      title: '当前价格',
      dataIndex: 'currentPrice',
      key: 'currentPrice',
      sorter: (a: any, b: any) => a.currentPrice - b.currentPrice,
      render: (price: number) => <Text style={{ color: '#f5222d' }}>{price.toFixed(2)} ETH</Text>,
    },
    {
      title: '市场价格',
      dataIndex: 'marketPrice',
      key: 'marketPrice',
      sorter: (a: any, b: any) => a.marketPrice - b.marketPrice,
      render: (price: number) => <Text>{price.toFixed(2)} ETH</Text>,
    },
    {
      title: '折扣率',
      dataIndex: 'discountRate',
      key: 'discountRate',
      sorter: (a: any, b: any) => b.discountRate - a.discountRate,
      render: (rate: number) => (
        <Text style={{ color: '#52c41a' }}>
          {rate}% <ArrowDownOutlined style={{ fontSize: 12 }} />
        </Text>
      ),
    },
    {
      title: '操作',
      key: 'action',
      render: () => (
        <Button 
          type="primary" 
          danger 
              size="small" 
          style={{ background: '#f5222d', borderColor: '#f5222d' }}
        >
          购买
        </Button>
      ),
    },
  ];

  return (
          <Card 
            className="tech-card"
      title={
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <PercentageOutlined style={{ marginRight: 8, color: '#52c41a' }} />
          <Text style={{ color: 'rgba(255, 255, 255, 0.85)', fontSize: 16, fontWeight: 500 }}>
            低价藏品列表
          </Text>
        </div>
      }
            bordered={false}
          >
      <Table 
        dataSource={mockTableData} 
        columns={columns} 
        pagination={{ pageSize: 5 }}
        className="tech-table"
      />
      <style>{`
        .tech-table .ant-table {
          background: transparent;
        }
        .tech-table .ant-table-thead > tr > th {
          background: rgba(0, 21, 41, 0.5);
          color: rgba(255, 255, 255, 0.85);
          border-bottom: 1px solid #1890ff30;
        }
        .tech-table .ant-table-tbody > tr > td {
          border-bottom: 1px solid #1890ff30;
        }
        .tech-table .ant-table-tbody > tr:hover > td {
          background: rgba(24, 144, 255, 0.1);
        }
        .tech-table .ant-pagination-item {
          background: rgba(0, 21, 41, 0.5);
          border-color: #1890ff50;
        }
        .tech-table .ant-pagination-item-active {
          background: #1890ff;
          border-color: #1890ff;
        }
        .tech-table .ant-pagination-item-active a {
          color: white;
        }
        .tech-table .ant-pagination-prev .ant-pagination-item-link,
        .tech-table .ant-pagination-next .ant-pagination-item-link {
          background: rgba(0, 21, 41, 0.5);
          border-color: #1890ff50;
          color: rgba(255, 255, 255, 0.65);
        }
      `}</style>
          </Card>
  );
};

const NftSnipe: React.FC = () => {
  return (
    <div className="nft-snipe-page">
      <TechTitle>藏品狙击</TechTitle>
      
      <Row gutter={16} className="statistic-cards">
        <Col xs={24} sm={12} md={6}>
          <StatisticCard 
            title="最低狙击成本" 
            value="5.2 ETH"
            icon={<DollarOutlined />} 
            color="var(--blue-color)" 
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatisticCard 
            title="最高折扣率" 
            value="33.5%" 
            icon={<PercentageOutlined />} 
            color="var(--green-color)" 
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatisticCard 
            title="可获收益" 
            value="58.2 ETH" 
            icon={<DollarOutlined />} 
            color="var(--orange-color)" 
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatisticCard 
            title="收益率" 
            value="24.8%" 
            icon={<ArrowUpOutlined />} 
            color="var(--pink-color)" 
          />
        </Col>
      </Row>

      <Row gutter={16} className="content-section equal-height-cards">
        <Col xs={24} md={12}>
          <LiveDiscountStream />
        </Col>
        <Col xs={24} md={12}>
          <NftCalendar />
        </Col>
      </Row>
    </div>
  );
};

export default NftSnipe; 

const pageStyles = `
  .nft-snipe-page {
    padding: 24px;
  }

  .nft-snipe-page .page-title {
    color: rgba(255, 255, 255, 0.85);
    margin-bottom: 24px;
    font-weight: 500;
  }

  .tech-text-effect {
    text-shadow: 0 0 10px rgba(24, 144, 255, 0.5);
  }

  .nft-snipe-page .statistic-cards {
    margin-bottom: 24px;
  }

  .nft-snipe-page .content-section {
    margin-bottom: 24px;
  }

  .tech-card {
    background: rgba(0, 21, 41, 0.7);
    border: 1px solid rgba(24, 144, 255, 0.3);
    border-radius: 4px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }

  .tech-card .ant-card-head {
    border-bottom: 1px solid rgba(24, 144, 255, 0.3);
    color: rgba(255, 255, 255, 0.85);
  }

  .tech-card:hover {
    border-color: rgba(24, 144, 255, 0.5);
    box-shadow: 0 4px 16px rgba(24, 144, 255, 0.2);
  }

  .ant-statistic-title {
    color: rgba(255, 255, 255, 0.65);
  }
  
  :root {
    --blue-color: #1890ff;
    --green-color: #52c41a;
    --orange-color: #fa8c16;
    --pink-color: #eb2f96;
    --danger-color: #f5222d;
  }

  .equal-height-cards {
    display: flex;
  }

  .equal-height-cards > .ant-col {
    display: flex;
  }

  .equal-height-cards > .ant-col > .tech-card {
    width: 100%;
    display: flex;
    flex-direction: column;
  }

  .equal-height-cards > .ant-col > .tech-card > .ant-card-body {
    flex: 1;
    overflow: auto;
  }
`; 