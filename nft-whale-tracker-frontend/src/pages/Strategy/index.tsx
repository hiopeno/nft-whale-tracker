import React, { useState } from 'react';
import { Card, Table, Tag, Row, Col, Statistic, Progress, Badge, Divider, Typography, Modal, Button, Space, message, Tabs, Avatar } from 'antd';
import { 
  RiseOutlined, 
  FallOutlined, 
  PauseOutlined, 
  BarChartOutlined, 
  PieChartOutlined,
  PercentageOutlined,
  AlertOutlined,
  WarningOutlined,
  SafetyOutlined,
  ClockCircleOutlined,
  DollarOutlined,
  CheckOutlined,
  CloseOutlined,
  TagOutlined,
  PictureOutlined,
  NumberOutlined,
  FireOutlined,
  ReloadOutlined
} from '@ant-design/icons';
import ReactECharts from 'echarts-for-react';

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

// 更新风险标签组件
const RiskTag: React.FC<{risk: string}> = ({ risk }) => {
  let className: string;
  let icon = null;
  
  switch(risk) {
    case 'HIGH':
      className = 'danger-tag';
      icon = <AlertOutlined />;
      break;
    case 'MEDIUM':
      className = 'warning-tag';
      icon = <WarningOutlined />;
      break;
    case 'LOW':
    default:
      className = 'success-tag';
      icon = <SafetyOutlined />;
      break;
  }
  
  return (
    <Tag 
      icon={icon}
      className={className}
    >
      {risk === 'HIGH' ? '高风险' : risk === 'MEDIUM' ? '中风险' : '低风险'}
    </Tag>
  );
};

// 添加全局样式
const pageStyles = `
  /* 表格样式 */
  .ant-table {
    background: transparent !important;
    color: var(--text-primary);
  }
  
  .ant-table-thead > tr > th {
    background: rgba(0, 0, 0, 0.2) !important;
    color: var(--text-primary) !important;
    border-bottom: 1px solid rgba(24, 144, 255, 0.2) !important;
    padding: 12px 16px !important;
    font-weight: bold;
  }
  
  .ant-table-tbody > tr > td {
    border-bottom: 1px solid rgba(255, 255, 255, 0.05) !important;
    padding: 12px 16px !important;
    transition: all 0.3s !important;
  }
  
  .ant-table-tbody > tr.even-row {
    background: rgba(0, 0, 0, 0.1) !important;
  }
  
  .ant-table-tbody > tr.odd-row {
    background: rgba(24, 144, 255, 0.03) !important;
  }
  
  .ant-table-tbody > tr:hover > td {
    background: rgba(24, 144, 255, 0.1) !important;
  }
  
  /* 按钮动画效果 */
  @keyframes pulse {
    0% {
      transform: scale(1);
      opacity: 1;
    }
    50% {
      transform: scale(1.1);
      opacity: 0.7;
    }
    100% {
      transform: scale(1);
      opacity: 1;
    }
  }
  
  .adoption-buttons-container {
    display: flex;
    justify-content: center;
    align-items: center;
  }
  
  /* 标签样式 */
  .success-tag {
    color: var(--success) !important;
    background: rgba(82, 196, 26, 0.1) !important;
    border: 1px solid var(--success) !important;
  }
  
  .danger-tag {
    color: var(--danger) !important;
    background: rgba(255, 77, 79, 0.1) !important;
    border: 1px solid var(--danger) !important;
  }
  
  .primary-tag {
    color: var(--primary) !important;
    background: rgba(24, 144, 255, 0.1) !important;
    border: 1px solid var(--primary) !important;
  }
  
  /* 策略表格卡片样式 */
  .strategy-table-card {
    border: 1px solid rgba(24, 144, 255, 0.2) !important;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15), 0 0 12px rgba(24, 144, 255, 0.1) !important;
    overflow: hidden;
  }
  
  .strategy-table-card .ant-card-head {
    border-bottom: 1px solid rgba(24, 144, 255, 0.2);
    padding: 0 24px;
    background: linear-gradient(90deg, rgba(0, 21, 41, 0.8) 0%, rgba(0, 21, 41, 0.6) 100%);
    height: 60px;
  }
  
  .strategy-table-card .ant-card-body {
    overflow: hidden;
  }
  
  .strategy-table-card .ant-table {
    background: transparent !important;
  }
  
  .strategy-table-card .ant-table-thead > tr > th {
    background: rgba(0, 21, 41, 0.6) !important;
    border-bottom: 2px solid var(--primary) !important;
    color: var(--text-primary) !important;
    padding: 14px 16px;
    font-weight: 500;
    text-align: center;
  }
  
  .strategy-table-card .ant-table-thead > tr > th::before {
    display: none !important;
  }
  
  .tech-table-row {
    cursor: pointer;
    transition: all 0.3s;
  }
  
  .tech-table-row:hover > td {
    background: rgba(24, 144, 255, 0.1) !important;
    box-shadow: inset 0 0 10px rgba(24, 144, 255, 0.05);
  }
  
  .tech-table-row-even > td {
    background: rgba(0, 0, 0, 0.02);
  }
  
  .tech-table-row-odd > td {
    background: rgba(0, 21, 41, 0.3);
  }
  
  .strategy-table-card .ant-table-tbody > tr > td {
    border-bottom: 1px solid rgba(24, 144, 255, 0.1);
    padding: 12px 16px;
    transition: all 0.3s;
  }
  
  .strategy-table-card .ant-pagination {
    margin: 16px 24px 0 24px;
  }
  
  .strategy-table-card .ant-pagination-item {
    border-color: rgba(24, 144, 255, 0.3);
    background: rgba(0, 21, 41, 0.4);
  }
  
  .strategy-table-card .ant-pagination-item-active {
    background: var(--primary);
    border-color: var(--primary);
    box-shadow: 0 0 8px rgba(24, 144, 255, 0.5);
  }
  
  .strategy-table-card .ant-pagination-item-active a {
    color: white;
  }
  
  .strategy-table-card .ant-pagination-prev .ant-pagination-item-link,
  .strategy-table-card .ant-pagination-next .ant-pagination-item-link {
    background: rgba(0, 21, 41, 0.4);
    border-color: rgba(24, 144, 255, 0.3);
  }
  
  /* 优化表格为科技感十足的布局 */
  .strategy-table-card .ant-table-container {
    border: 1px solid rgba(24, 144, 255, 0.2);
    border-radius: 4px;
    margin: 0 24px;
    overflow: hidden;
  }
  
  /* 采纳和放弃按钮的悬浮容器 */
  .adoption-buttons-container {
    display: inline-flex;
    background: rgba(0, 21, 41, 0.4);
    border-radius: 8px;
    padding: 4px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
    border: 1px solid rgba(24, 144, 255, 0.15);
  }
`;

const Strategy: React.FC = () => {
  // 添加模态框状态控制
  const [isExpiredModalVisible, setIsExpiredModalVisible] = useState(false);
  // 添加采纳策略模态框状态控制
  const [isAdoptedModalVisible, setIsAdoptedModalVisible] = useState(false);
  
  // 添加时间范围的状态 - 暂时注释掉
  // const [timeRange, setTimeRange] = useState<'week' | 'month'>('week');

  // 更新表格列设置
  const columns = [
    {
      title: (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <BarChartOutlined style={{ marginRight: 6, color: 'var(--primary)' }} />
          <Text style={{ color: 'var(--text-primary)' }}>策略ID</Text>
        </div>
      ),
      dataIndex: 'entityId',
      key: 'entityId',
      width: 180,
      render: (id: string) => (
        <div style={{ 
          display: 'flex', 
          alignItems: 'center',
          background: 'rgba(24, 144, 255, 0.05)',
          padding: '4px 8px',
          borderRadius: '4px',
          border: '1px solid rgba(24, 144, 255, 0.15)'
        }}>
          <Text 
            style={{ 
              color: 'var(--primary)', 
              cursor: 'pointer', 
              textShadow: '0 0 8px rgba(24, 144, 255, 0.3)',
              fontFamily: 'monospace',
              fontWeight: 500
            }}
          >
            {id}
          </Text>
        </div>
      ),
    },
    {
      title: (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <TagOutlined style={{ marginRight: 6, color: 'var(--primary)' }} />
          <Text style={{ color: 'var(--text-primary)' }}>策略类型</Text>
        </div>
      ),
      dataIndex: 'strategyType',
      key: 'strategyType',
      width: 130,
      render: (type: string) => {
        let icon, text;
        const color = 'var(--primary)';
        const bgColor = 'rgba(24, 144, 255, 0.1)';
        const borderColor = 'rgba(24, 144, 255, 0.3)';
        
        if (type === 'WHALE_BUY') {
          icon = <RiseOutlined />;
          text = '跟随巨鲸买入';
        } else if (type === 'WHALE_SELL') {
          icon = <FallOutlined />;
          text = '跟随巨鲸卖出';
        } else if (type === 'LOW_PRICE') {
          icon = <DollarOutlined />;
          text = '藏品狙击';
        }
        
        return (
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            background: bgColor,
            padding: '4px 8px',
            borderRadius: '4px',
            border: `1px solid ${borderColor}`,
            boxShadow: `0 0 8px ${bgColor}`
          }}>
            <span style={{ marginRight: 6, color }}>{icon}</span>
            <Text style={{ color }}>{text}</Text>
          </div>
        );
      },
    },
    {
      title: (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <PictureOutlined style={{ marginRight: 6, color: 'var(--primary)' }} />
          <Text style={{ color: 'var(--text-primary)' }}>收藏集</Text>
        </div>
      ),
      dataIndex: 'collection',
      key: 'collection',
      width: 150,
      render: (collection: string) => {
        // 模拟收藏集图标映射
        const collectionIcons: {[key: string]: string} = {
          'Bored Ape Yacht Club': 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?w=500&auto=format',
          'CryptoPunks': 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?w=500&auto=format',
          'Azuki': 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?w=500&auto=format',
          'Doodles': 'https://i.seadn.io/gae/7B0qai02OdHA8P_EOVK672qUliyjQdQDGNrACxs7WnTgZAkJa_wWURnIFKeOh5VTf8cfTqW3wQpozGedaC9mteKphEOtztls02RlWQ?w=500&auto=format',
          'Meebits': 'https://i.seadn.io/gae/d784iHHbqQFVH1XYD6HoT4u3y_Fsu_9FZUltWjnOzoYv7qqB5dLUqpGyHBLwE8L4-599CUPZOjnNZZrWPMsGDXeAWnYAT-a3CK7G?w=500&auto=format',
          'CloneX': 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?w=500&auto=format',
          'Moonbirds': 'https://i.seadn.io/gae/H-eyNE1MwL5ohL-tCfn_Xa1Sl9M9B4612tLYeUlQubzt4ewhr4huJIR5OLuyO3Z5PpJFSwdm7rq-TikAh7f5eUw338A2cy6HRH75?w=500&auto=format',
        };
        
        // 获取收藏集图标，如果没有则使用默认图标
        const iconUrl = collectionIcons[collection] || 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?w=500&auto=format';
        
        return (
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Avatar 
              src={iconUrl} 
              size={24} 
              style={{ marginRight: 8, border: '1px solid rgba(24, 144, 255, 0.3)' }} 
            />
            <Text style={{ color: 'var(--text-primary)' }}>{collection}</Text>
          </div>
        );
      },
    },
    {
      title: (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <NumberOutlined style={{ marginRight: 6, color: 'var(--primary)' }} />
          <Text style={{ color: 'var(--text-primary)' }}>NFT ID</Text>
        </div>
      ),
      dataIndex: 'nftId',
      key: 'nftId',
      width: 100,
      render: (id: string, record: any) => {
        // 对于巨鲸驱动策略，统一标记为ALL
        if (record.strategyType === 'WHALE_BUY' || record.strategyType === 'WHALE_SELL') {
          return (
            <div style={{
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: '2px 10px',
              borderRadius: '12px',
              background: 'rgba(0, 0, 0, 0.2)',
              border: '1px solid rgba(255, 255, 255, 0.1)',
            }}>
              <Text style={{ 
                color: 'var(--text-tertiary)', 
                fontStyle: 'italic',
                fontSize: 12,
                textTransform: 'uppercase',
                letterSpacing: '1px'
              }}>
                ALL
              </Text>
            </div>
          );
        }
        
        return (
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '2px 8px',
            borderRadius: '12px',
            background: 'rgba(24, 144, 255, 0.05)',
            border: '1px solid rgba(24, 144, 255, 0.15)',
          }}>
            <Text style={{ 
              color: 'var(--text-secondary)',
              fontFamily: 'monospace',
              fontWeight: 500
            }}>
              #{id}
            </Text>
          </div>
        );
      },
    },
    {
      title: (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <DollarOutlined style={{ marginRight: 6, color: 'var(--primary)' }} />
          <Text style={{ color: 'var(--text-primary)' }}>现价</Text>
        </div>
      ),
      dataIndex: 'currentPrice',
      key: 'currentPrice',
      width: 120,
      render: (price: number, record: any) => {
        // 价格趋势图标和颜色
        const isUp = record.priceTrend === 'up';
        const icon = isUp ? <RiseOutlined /> : <FallOutlined />;
        const color = isUp ? 'var(--danger)' : 'var(--success)';
        const bgColor = isUp ? 'rgba(255, 77, 79, 0.1)' : 'rgba(82, 196, 26, 0.1)';
        const borderColor = isUp ? 'rgba(255, 77, 79, 0.3)' : 'rgba(82, 196, 26, 0.3)';
        
        return (
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            padding: '4px 10px',
            borderRadius: '4px',
            background: bgColor,
            border: `1px solid ${borderColor}`,
            boxShadow: `0 0 8px ${bgColor}`
          }}>
            <Text style={{ 
              color, 
              fontWeight: 'bold',
              textShadow: `0 0 10px ${bgColor}`
            }}>
              {icon} {price.toFixed(2)} 
              <span style={{ 
                fontSize: '12px', 
                marginLeft: '2px', 
                opacity: 0.8, 
                fontWeight: 'normal' 
              }}>
                ETH
              </span>
            </Text>
          </div>
        );
      },
    },
    {
      title: (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <FireOutlined style={{ marginRight: 6, color: 'var(--primary)' }} />
          <Text style={{ color: 'var(--text-primary)' }}>优先级</Text>
        </div>
      ),
      dataIndex: 'priority',
      key: 'priority',
      width: 120,
      render: (priority: number, record: any) => {
        // 将优先度百分比转换为1-5级
        const level = Math.ceil(priority / 20);
        
        // 根据策略类型设置颜色
        const baseColor = 'var(--primary)';
        const baseColorRgb = '24, 144, 255';
        
        return (
          <div style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            padding: '4px 8px',
            borderRadius: '4px',
            background: `rgba(${baseColorRgb}, 0.05)`,
            border: `1px solid rgba(${baseColorRgb}, 0.2)`,
          }}>
            <div style={{ 
              display: 'flex', 
              alignItems: 'center', 
              marginBottom: '2px'
            }}>
              {Array(5).fill(0).map((_, i) => (
                <div
                  key={i}
                  style={{
                    width: '8px',
                    height: '8px',
                    borderRadius: '50%',
                    margin: '0 2px',
                    background: i < level ? baseColor : 'rgba(255, 255, 255, 0.1)',
                    boxShadow: i < level ? `0 0 6px ${baseColor}` : 'none',
                    transition: 'all 0.3s ease',
                  }}
                />
              ))}
            </div>
            <Text style={{ 
              fontSize: '12px', 
              color: baseColor,
              fontWeight: 'bold'
            }}>
              {level === 5 ? '极高' : level === 4 ? '很高' : level === 3 ? '中等' : level === 2 ? '较低' : '低'}
              <span style={{ 
                fontSize: '10px', 
                opacity: 0.7, 
                marginLeft: '4px'
              }}>
                ({priority}%)
              </span>
            </Text>
          </div>
        );
      },
    },
    {
      title: (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <CheckOutlined style={{ marginRight: 6, color: 'var(--primary)' }} />
          <Text style={{ color: 'var(--text-primary)' }}>操作</Text>
        </div>
      ),
      key: 'adoption',
      width: 120,
      render: (_: any, record: any) => (
        <div className="adoption-buttons-container">
          <Button 
            type="text"
            icon={<CheckOutlined />} 
            onClick={(e) => record.onAdopt(e, record, '用户采纳')}
            className="adopt-button"
            style={{
              backgroundColor: 'rgba(82, 196, 26, 0.1)',
              border: '1px solid var(--success)',
              color: 'var(--success)',
              borderRadius: '6px',
              height: '32px',
              width: '32px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 0 8px rgba(82, 196, 26, 0.2)',
              transition: 'all 0.3s ease',
              margin: '0 4px'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.backgroundColor = 'rgba(82, 196, 26, 0.2)';
              e.currentTarget.style.boxShadow = '0 0 12px rgba(82, 196, 26, 0.3)';
              e.currentTarget.style.transform = 'scale(1.05)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = 'rgba(82, 196, 26, 0.1)';
              e.currentTarget.style.boxShadow = '0 0 8px rgba(82, 196, 26, 0.2)';
              e.currentTarget.style.transform = 'scale(1)';
            }}
            title="采纳策略"
          />
          <Button 
            type="text"
            icon={<CloseOutlined />} 
            onClick={(e) => record.onAdopt(e, record, '用户放弃')}
            className="abandon-button"
            style={{
              backgroundColor: 'rgba(255, 77, 79, 0.1)',
              border: '1px solid var(--danger)',
              color: 'var(--danger)',
              borderRadius: '6px',
              height: '32px',
              width: '32px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 0 8px rgba(255, 77, 79, 0.2)',
              transition: 'all 0.3s ease',
              margin: '0 4px'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.backgroundColor = 'rgba(255, 77, 79, 0.2)';
              e.currentTarget.style.boxShadow = '0 0 12px rgba(255, 77, 79, 0.3)';
              e.currentTarget.style.transform = 'scale(1.05)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = 'rgba(255, 77, 79, 0.1)';
              e.currentTarget.style.boxShadow = '0 0 8px rgba(255, 77, 79, 0.2)';
              e.currentTarget.style.transform = 'scale(1)';
            }}
            title="放弃策略"
          />
        </div>
      ),
    },
  ];

  // 更新模拟数据结构
  const [activeStrategies, setActiveStrategies] = useState([
    {
      key: '1',
      entityId: 'STR-20230615143022',
      strategyType: 'WHALE_BUY',
      collection: 'Bored Ape Yacht Club',
      nftId: '3429',
      currentPrice: 68.25,
      priceTrend: 'up',
      priority: 85, // 将转换为5级
    },
    {
      key: '2',
      entityId: 'STR-20230615152248',
      strategyType: 'LOW_PRICE',
      collection: 'CryptoPunks',
      nftId: '7804',
      currentPrice: 45.75,
      priceTrend: 'down',
      priority: 75, // 将转换为4级
    },
    {
      key: '3',
      entityId: 'STR-20230615163015',
      strategyType: 'WHALE_SELL',
      collection: 'Azuki',
      nftId: '5721',
      currentPrice: 23.40,
      priceTrend: 'up',
      priority: 90, // 将转换为5级 (绿色)
    },
    {
      key: '4',
      entityId: 'STR-20230616092734',
      strategyType: 'LOW_PRICE',
      collection: 'Doodles',
      nftId: '2941',
      currentPrice: 12.80,
      priceTrend: 'down',
      priority: 65, // 将转换为4级
    },
    {
      key: '5',
      entityId: 'STR-20230616104512',
      strategyType: 'WHALE_BUY',
      collection: 'Meebits',
      nftId: '9283',
      currentPrice: 9.15,
      priceTrend: 'up',
      priority: 45, // 将转换为3级
    },
    {
      key: '6',
      entityId: 'STR-20230616113045',
      strategyType: 'WHALE_SELL',
      collection: 'CloneX',
      nftId: '4920',
      currentPrice: 5.65,
      priceTrend: 'down',
      priority: 30, // 将转换为2级 (绿色)
    },
    {
      key: '7',
      entityId: 'STR-20230616125036',
      strategyType: 'LOW_PRICE',
      collection: 'Moonbirds',
      nftId: '3782',
      currentPrice: 8.20,
      priceTrend: 'up',
      priority: 15, // 将转换为1级
    },
  ]);

  // 失效策略数据
  const [expiredStrategies, setExpiredStrategies] = useState([
    {
      key: 'ex1',
      entityId: 'STR-20230612091823',
      strategyType: 'WHALE_BUY',
      collection: 'CyberKongz',
      nftId: '6281',
      currentPrice: 7.85,
      priceTrend: 'down',
      priority: 70, // 将转换为4级
      expiryReason: '价格变动',
      expiryTime: '2023-06-15 09:30:15',
    },
    {
      key: 'ex2',
      entityId: 'STR-20230613143522',
      strategyType: 'LOW_PRICE',
      collection: 'Art Blocks',
      nftId: '8347',
      currentPrice: 12.30,
      priceTrend: 'up',
      priority: 55, // 将转换为3级
      expiryReason: '鲸鱼调仓',
      expiryTime: '2023-06-16 14:22:38',
    },
    {
      key: 'ex3',
      entityId: 'STR-20230614081105',
      strategyType: 'WHALE_SELL',
      collection: 'World of Women',
      nftId: '2193',
      currentPrice: 3.50,
      priceTrend: 'down',
      priority: 80, // 将转换为4级 (绿色)
      expiryReason: '用户放弃',
      expiryTime: '2023-06-15 16:05:42',
    },
  ]);
  
  // 添加采纳策略数据
  const [adoptedStrategies, setAdoptedStrategies] = useState([
    {
      key: 'ad1',
      entityId: 'STR-20230611142236',
      strategyType: 'WHALE_BUY',
      collection: 'Pudgy Penguins',
      nftId: '5142',
      currentPrice: 11.45,
      priceTrend: 'up',
      priority: 88,
      adoptionTime: '2023-06-12 10:25:18'
    },
    {
      key: 'ad2',
      entityId: 'STR-20230612093048',
      strategyType: 'LOW_PRICE',
      collection: 'Otherdeed',
      nftId: '7623',
      currentPrice: 5.20,
      priceTrend: 'down',
      priority: 92,
      adoptionTime: '2023-06-13 09:15:33'
    }
  ]);
  
  // 策略数量统计图表配置 - 暂时注释掉
  /*
  const getStrategyStatsOption = () => {
    const stats = timeRange === 'week' ? weeklyStrategyStats : monthlyStrategyStats;
    
    return {
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow'
        },
        formatter: function (params: any) {
          let result = `${params[0].axisValue}<br/>`;
          params.forEach((param: any) => {
            // 为不同系列设置不同描述
            const seriesName = param.seriesName;
            const isSuccess = seriesName.includes('成功');
            const strategyType = seriesName.includes('低价狙击') ? '低价狙击' :
                              seriesName.includes('巨鲸买入') ? '巨鲸买入' : '巨鲸卖出';
            
            result += `${param.marker}${strategyType} ${isSuccess ? '成功' : '总计'}: ${param.value}<br/>`;
          });
          return result;
        },
        confine: true // 确保tooltip不会超出图表区域
      },
      legend: {
        data: ['低价狙击总计', '低价狙击成功', '巨鲸买入总计', '巨鲸买入成功', '巨鲸卖出总计', '巨鲸卖出成功'],
        textStyle: {
          color: 'var(--text-primary)'
        }
      },
      grid: {
        left: '5%',    // 增加左边距
        right: '5%',   // 增加右边距
        bottom: '10%', // 增加底部边距
        top: '15%',    // 增加顶部边距
        containLabel: true
      },
      xAxis: {
        type: 'category',
        data: stats.labels,
        axisLine: {
          lineStyle: {
            color: 'var(--border-color)'
          }
        },
        axisLabel: {
          color: 'var(--text-secondary)',
          rotate: stats.labels.length > 20 ? 45 : 0, // 当标签过多时旋转标签
          interval: stats.labels.length > 20 ? 'auto' : 0 // 自动间隔显示标签
        }
      },
      yAxis: {
        type: 'value',
        name: '策略数量',
        nameTextStyle: {
          color: 'var(--text-secondary)'
        },
        axisLine: {
          lineStyle: {
            color: 'var(--border-color)'
          }
        },
        axisLabel: {
          color: 'var(--text-secondary)'
        },
        splitLine: {
          lineStyle: {
            color: 'var(--border-color)',
            opacity: 0.3
          }
        }
      },
      series: [
        {
          name: '低价狙击总计',
          type: 'bar',
          stack: 'lowPrice',
          barWidth: '60%',
          barGap: '30%', // 不同系列的柱间距离
          barCategoryGap: '20%', // 同一系列的柱间距离
          itemStyle: {
            color: 'rgba(24, 144, 255, 0.8)' // 蓝色
          },
          emphasis: {
            focus: 'series'
          },
          data: stats.data.lowPrice.total
        },
        {
          name: '低价狙击成功',
          type: 'bar',
          stack: 'lowPrice',
          barWidth: '60%',
          itemStyle: {
            color: 'rgba(24, 144, 255, 0.4)' // 蓝色透明
          },
          emphasis: {
            focus: 'series'
          },
          data: stats.data.lowPrice.success
        },
        {
          name: '巨鲸买入总计',
          type: 'bar',
          stack: 'whaleBuy',
          barWidth: '60%',
          itemStyle: {
            color: 'rgba(82, 196, 26, 0.8)' // 绿色
          },
          emphasis: {
            focus: 'series'
          },
          data: stats.data.whaleBuy.total
        },
        {
          name: '巨鲸买入成功',
          type: 'bar',
          stack: 'whaleBuy',
          barWidth: '60%',
          itemStyle: {
            color: 'rgba(82, 196, 26, 0.4)' // 绿色透明
          },
          emphasis: {
            focus: 'series'
          },
          data: stats.data.whaleBuy.success
        },
        {
          name: '巨鲸卖出总计',
          type: 'bar',
          stack: 'whaleSell',
          barWidth: '60%',
          itemStyle: {
            color: 'rgba(255, 77, 79, 0.8)' // 红色
          },
          emphasis: {
            focus: 'series'
          },
          data: stats.data.whaleSell.total
        },
        {
          name: '巨鲸卖出成功',
          type: 'bar',
          stack: 'whaleSell',
          barWidth: '60%',
          itemStyle: {
            color: 'rgba(255, 77, 79, 0.4)' // 红色透明
          },
          emphasis: {
            focus: 'series'
          },
          data: stats.data.whaleSell.success
        }
      ]
    };
  };
  */

  // 为失效策略添加专用的表格列配置
  const expiredColumns = [
    // 保留策略ID
    columns.find(col => col.key === 'entityId')!,
    // 保留策略类型
    columns.find(col => col.key === 'strategyType')!,
    // 保留收藏集
    columns.find(col => col.key === 'collection')!,
    // 保留NFT ID
    columns.find(col => col.key === 'nftId')!,
    // 保留现价
    columns.find(col => col.key === 'currentPrice')!,
    // 保留优先级，但调整宽度
    {
      ...columns.find(col => col.key === 'priority')!,
      width: 120,
    },
    // 添加失效原因
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>失效原因</Text>,
      dataIndex: 'expiryReason',
      key: 'expiryReason',
      width: 100,
      render: (reason: string) => {
        let className = '';
        
        switch (reason) {
          case '价格变动':
            className = 'warning-tag';
            break;
          case '鲸鱼调仓':
            className = 'primary-tag';
            break;
          case '用户放弃':
            className = 'danger-tag';
            break;
          default:
            className = 'neutral-tag';
        }
        
        return (
          <Tag className={className}>
            {reason}
          </Tag>
        );
      },
    },
    // 添加失效时间
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>失效时间</Text>,
      dataIndex: 'expiryTime',
      key: 'expiryTime',
      width: 170,
      render: (time: string) => (
        <Text style={{ color: 'var(--text-tertiary)' }}>
          {time}
        </Text>
      ),
    },
  ];

  // 为采纳策略添加专用的表格列配置
  const adoptedColumns = [
    // 策略ID
    columns.find(col => col.key === 'entityId')!,
    // 策略类型
    columns.find(col => col.key === 'strategyType')!,
    // 收藏集
    columns.find(col => col.key === 'collection')!,
    // NFT ID
    columns.find(col => col.key === 'nftId')!,
    // 现价
    columns.find(col => col.key === 'currentPrice')!,
    // 优先级
    {
      ...columns.find(col => col.key === 'priority')!,
      width: 120,
    },
    // 添加采纳时间
    {
      title: <Text style={{ color: 'var(--text-primary)' }}>采纳时间</Text>,
      dataIndex: 'adoptionTime',
      key: 'adoptionTime',
      width: 170,
      render: (time: string) => (
        <Text style={{ color: 'var(--text-tertiary)' }}>
          {time}
        </Text>
      ),
    },
  ];

  // 处理用户采纳或放弃策略
  const handleStrategyAdoption = (e: React.MouseEvent, record: any, reason: string) => {
    e.stopPropagation(); // 阻止事件冒泡
    
    // 获取当前时间
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    const formattedDate = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    
    // 将策略从活跃列表移除
    const strategyToMove = {...record};
    delete strategyToMove.onAdopt; // 移除函数引用
    
    // 根据操作类型决定将策略放入采纳列表或失效列表
    if (reason === '用户采纳') {
      // 添加采纳时间
      strategyToMove.adoptionTime = formattedDate;
      strategyToMove.key = `ad${adoptedStrategies.length + 1}`;
      
      // 更新列表
      setActiveStrategies(activeStrategies.filter(item => item.key !== record.key));
      setAdoptedStrategies([...adoptedStrategies, strategyToMove]);
      
      // 显示操作成功的消息
      message.success(`已采纳策略 ${record.entityId}`);
    } else {
      // 添加失效原因和时间
      strategyToMove.expiryReason = reason;
      strategyToMove.expiryTime = formattedDate;
      strategyToMove.key = `ex${expiredStrategies.length + 1}`;
      
      // 更新列表
      setActiveStrategies(activeStrategies.filter(item => item.key !== record.key));
      setExpiredStrategies([...expiredStrategies, strategyToMove]);
      
      // 显示操作成功的消息
      message.success(`已放弃策略 ${record.entityId}`);
    }
  };

  // 为活跃策略列表中的每项添加采纳和放弃的处理函数
  const activeStrategiesWithHandler = activeStrategies.map(strategy => ({
    ...strategy,
    onAdopt: handleStrategyAdoption
  }));

  // 显示失效策略模态框
  const showExpiredModal = () => {
    setIsExpiredModalVisible(true);
  };

  // 隐藏失效策略模态框
  const handleExpiredCancel = () => {
    setIsExpiredModalVisible(false);
  };

  // 显示采纳策略模态框
  const showAdoptedModal = () => {
    setIsAdoptedModalVisible(true);
  };

  // 隐藏采纳策略模态框
  const handleAdoptedCancel = () => {
    setIsAdoptedModalVisible(false);
  };

  return (
    <div className="strategy-container" style={{ padding: '20px' }}>
      <style>{pageStyles}</style>
      <TechTitle>策略推荐</TechTitle>
      <Row gutter={16} style={{ marginBottom: 24 }}>
        <Col span={6}>
          <Card 
            className="tech-card"
            hoverable
            bordered={false}
          >
            <Statistic
              title={<Text style={{ color: 'var(--text-secondary)' }}>可行策略</Text>}
              value={activeStrategies.length}
              valueStyle={{ color: 'var(--primary)', textShadow: 'var(--text-shadow-primary)' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card 
            className="tech-card"
            hoverable
            bordered={false}
            onClick={showAdoptedModal}
            style={{ cursor: 'pointer' }}
          >
            <Statistic
              title={<Text style={{ color: 'var(--text-secondary)' }}>采纳策略</Text>}
              value={adoptedStrategies.length}
              valueStyle={{ color: 'var(--danger)', textShadow: 'var(--text-shadow-danger)' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card 
            className="tech-card"
            hoverable
            bordered={false}
            onClick={showExpiredModal}
            style={{ cursor: 'pointer' }}
          >
            <Statistic
              title={<Text style={{ color: 'var(--text-secondary)' }}>失效策略</Text>}
              value={expiredStrategies.length}
              valueStyle={{ color: 'var(--text-tertiary)', textShadow: 'var(--text-shadow-subtle)' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card 
            className="tech-card"
            hoverable
            bordered={false}
          >
            <Statistic
              title={<Text style={{ color: 'var(--text-secondary)' }}>策略成功率</Text>}
              value={76.8}
              precision={1}
              valueStyle={{ color: 'var(--success)', textShadow: 'var(--text-shadow-success)' }}
              suffix="%"
            />
          </Card>
        </Col>
      </Row>

      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <BarChartOutlined style={{ marginRight: 8, color: 'var(--primary)' }} />
            <Text style={{ 
              color: 'var(--text-primary)', 
              fontSize: 16, 
              fontWeight: 500,
              background: 'linear-gradient(90deg, rgba(24, 144, 255, 0.8) 0%, rgba(24, 144, 255, 0.4) 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              textShadow: '0 0 8px rgba(24, 144, 255, 0.3)'
            }}>
              可行策略列表
            </Text>
            <Badge 
              count={activeStrategies.length} 
              style={{ 
                marginLeft: 12, 
                backgroundColor: 'var(--primary)',
                boxShadow: '0 0 8px rgba(24, 144, 255, 0.5)'
              }} 
            />
          </div>
        } 
        className="tech-card strategy-table-card" 
        bordered={false}
        bodyStyle={{ padding: '0 0 16px 0' }}
        extra={
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Tag color="var(--success)" style={{ marginRight: 8 }}>更新时间: {new Date().toLocaleTimeString()}</Tag>
            <Button type="text" icon={<ReloadOutlined />} />
          </div>
        }
      >
        <Table 
          columns={columns} 
          dataSource={activeStrategiesWithHandler} 
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            pageSizeOptions: ['5', '10', '20'],
            showTotal: (total) => `共 ${total} 条策略`,
            size: 'small',
            showQuickJumper: true,
            itemRender: (page, type, originalElement) => {
              if (type === 'prev') {
                return <a>上一页</a>;
              }
              if (type === 'next') {
                return <a>下一页</a>;
              }
              return originalElement;
            }
          }}
          rowClassName={(record, index) => 
            `tech-table-row ${index % 2 === 0 ? 'tech-table-row-even' : 'tech-table-row-odd'}`
          }
          style={{ background: 'transparent' }}
          onRow={(record) => ({
            onClick: () => { message.info(`查看策略详情: ${record.entityId}`); },
          })}
        />
      </Card>
      
      {/* 策略统计图表 - 暂时注释掉 
      <Row gutter={16} style={{ marginBottom: 24, marginTop: 24 }}>
        <Col span={24}>
          <Card
            title={
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Text style={{ color: 'var(--text-primary)', fontSize: 16, fontWeight: 500 }}>
                  策略统计分析
                </Text>
                <div>
                  <Button 
                    type={timeRange === 'week' ? 'primary' : 'default'}
                    onClick={() => setTimeRange('week')}
                    style={{ marginRight: 8 }}
                  >
                    最近一周
                  </Button>
                  <Button 
                    type={timeRange === 'month' ? 'primary' : 'default'}
                    onClick={() => setTimeRange('month')}
                  >
                    最近一个月
                  </Button>
                </div>
              </div>
            }
            className="tech-card"
            bordered={false}
          >
            <Tabs
              defaultActiveKey="numbers"
              items={[
                {
                  key: 'numbers',
                  label: '策略数量统计',
                  children: (
                    <ReactECharts 
                      option={getStrategyStatsOption()} 
                      style={{ height: '350px' }} 
                      theme="dark"
                    />
                  ),
                },
              ]}
            />
          </Card>
        </Col>
      </Row>
      */}
      
      {/* 失效策略模态框 */}
      <Modal
        title={
          <Text style={{ color: 'var(--text-primary)' }}>
            失效策略列表
          </Text>
        }
        open={isExpiredModalVisible}
        onCancel={handleExpiredCancel}
        footer={null}
        width={1200}
        className="tech-modal"
        style={{ top: 20 }}
      >
        <Table 
          columns={expiredColumns} 
          dataSource={expiredStrategies} 
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            pageSizeOptions: ['5', '10', '20'],
            showTotal: (total) => `共 ${total} 条策略`,
            size: 'small',
            showQuickJumper: true,
            itemRender: (page, type, originalElement) => {
              if (type === 'prev') {
                return <a>上一页</a>;
              }
              if (type === 'next') {
                return <a>下一页</a>;
              }
              return originalElement;
            }
          }}
          rowClassName="tech-table-row"
          style={{ background: 'transparent' }}
          scroll={{ x: 1100 }}
        />
      </Modal>
      
      {/* 采纳策略模态框 */}
      <Modal
        title={
          <Text style={{ color: 'var(--text-primary)' }}>
            采纳策略列表
          </Text>
        }
        open={isAdoptedModalVisible}
        onCancel={handleAdoptedCancel}
        footer={null}
        width={1200}
        className="tech-modal"
        style={{ top: 20 }}
      >
        <Table 
          columns={adoptedColumns} 
          dataSource={adoptedStrategies} 
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            pageSizeOptions: ['5', '10', '20'],
            showTotal: (total) => `共 ${total} 条策略`,
            size: 'small',
            showQuickJumper: true,
            itemRender: (page, type, originalElement) => {
              if (type === 'prev') {
                return <a>上一页</a>;
              }
              if (type === 'next') {
                return <a>下一页</a>;
              }
              return originalElement;
            }
          }}
          rowClassName="tech-table-row"
          style={{ background: 'transparent' }}
          scroll={{ x: 1100 }}
        />
      </Modal>
    </div>
  );
};

export default Strategy; 