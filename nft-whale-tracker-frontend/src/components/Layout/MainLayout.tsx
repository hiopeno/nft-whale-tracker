import React, { useState } from 'react';
import { Layout, Menu, theme } from 'antd';
import Icon from '@ant-design/icons';
import {
  MoneyCollectOutlined,
  SettingOutlined,
  BulbOutlined,
  LineChartOutlined
} from '@ant-design/icons';

const { Header, Content, Footer, Sider } = Layout;

// 添加鲸鱼图标组件
const WhaleSvg = () => (
  <svg viewBox="0 0 1024 1024" width="1em" height="1em" fill="currentColor">
    <path d="M896 554.5c0-24.1-3.2-47.4-9.2-69.5 0 0-1 0-1-1.1-47.4-183.6-215.7-326.3-416.8-341.1v-31.5l-42.1 42.1-42.1-42.1v25.2C210.4 147.8 63 291.5 16.7 474.1c-1 1.1-1 1.1-1 2.1-6.3 25.2-10.5 51.5-10.5 78.3 0 94.8 42.1 179.4 107.8 236.8 0 24.1-8.4 44.2-21 60-8.4 10.5-8.4 26.2 2.1 34.7 4.2 3.2 9.5 5.3 14.7 5.3 7.4 0 14.7-3.2 20-8.4 17.9-20 30.5-46.3 33.7-75.7 34.7 19 74.7 29.4 117.3 29.4 42.1 0 81.5-10.5 116.8-28.3 35.8 17.9 75.7 28.3 118.3 28.3 42.1 0 82-10.5 117.3-29.4 3.2 29.4 15.8 55.7 33.7 75.7 5.3 5.3 12.6 8.4 20 8.4 5.3 0 10.5-2.1 14.7-5.3 10.5-8.4 10.5-24.1 2.1-34.7-12.6-15.8-21-36.8-21-60 65.3-57.8 107.8-142.5 107.8-237.2v0.1zm-112 60.2c-1 0-2.1 0-3.2 0-27.3 0-52.5-9.5-72.5-25.2-12.6-9.5-30.5-8.4-41 3.2-11.6 12.6-10.5 31.5 2.1 42.1 29.4 23.1 66.2 37.9 105.1 41-20 31.5-47.9 57.8-80.4 76.8-5.3 3.2-10.5 4.2-16.8 3.2-8.4-1.1-17.9-2.1-27.3-2.1-59.9 0-113.1 27.3-148.9 69.5-35.8-42.1-89-69.5-148.9-69.5-9.5 0-18.9 1.1-27.3 2.1-5.3 1.1-11.6-1.1-16.8-3.2-32.6-18.9-60.4-45.2-80.4-76.8 39-3.2 75.7-17.9 105.1-41 12.6-10.5 13.7-29.4 2.1-42.1-10.5-11.6-28.3-12.6-41-3.2-20 15.8-45.2 25.2-72.5 25.2-1 0-2.1 0-3.2 0-8.4-68.3 11.6-134.1 52.5-187.8-20 78.3-2.1 164.6 52.5 228.8 6.3 7.4 15.8 10.5 24.1 8.4 10.5-1.1 22-2.1 33.7-2.1 64.1 0 121 36.8 148.9 90.6 27.3-53.6 84.1-90.6 148.9-90.6 11.6 0 23.1 1.1 33.7 2.1 9.5 2.1 18.9-1.1 24.1-8.4 54.6-64.1 72.5-150.5 52.5-228.8 41 53.7 60.9 119.5 52.5 187.8z" />
    <circle cx="694.5" cy="490.3" r="25" />
  </svg>
);

// 创建使用Ant Design Icon组件包装的鲸鱼图标
const WhaleIcon = (props: any) => <Icon component={WhaleSvg} {...props} />;

interface MainLayoutProps {
  children: React.ReactNode;
  setCurrentPage?: (key: string) => void;
}

const MainLayout: React.FC<MainLayoutProps> = ({ children, setCurrentPage }) => {
  const [collapsed, setCollapsed] = useState(false);
  const {
    token: { borderRadiusLG },
  } = theme.useToken();

  // 处理菜单点击事件
  const handleMenuClick = ({ key }: { key: string }) => {
    if (setCurrentPage) {
      setCurrentPage(key);
    }
  };

  // Logo样式，带有边框发光效果
  const logoStyle = {
    height: 64,
    margin: '16px 0',
    color: 'var(--text-primary)',
    fontSize: collapsed ? 14 : 18,
    textAlign: 'center' as const,
    lineHeight: '64px',
    whiteSpace: 'nowrap' as const,
    overflow: 'hidden' as const,
    textOverflow: 'ellipsis' as const,
    padding: '0 8px',
    textShadow: 'var(--text-shadow-primary)',
    borderBottom: '1px solid var(--border-color)',
    position: 'relative' as const,
  };

  // 菜单项悬停发光效果
  const menuStyle = {
    background: 'transparent',
    borderRight: 0,
  };

  // 内容区域样式
  const contentBoxStyle = {
    padding: 24,
    minHeight: 360,
    background: 'var(--bg-secondary)',
    borderRadius: borderRadiusLG,
    boxShadow: 'var(--shadow-base)',
    border: '1px solid var(--border-color)',
    backdropFilter: 'blur(10px)',
  };

  // 为页面添加自定义样式
  React.useEffect(() => {
    // 添加全局样式
    const style = document.createElement('style');
    style.innerHTML = `
      .ant-menu-item:hover {
        box-shadow: 0 0 10px rgba(24, 144, 255, 0.5) !important;
        border-right: 3px solid #1890ff !important;
      }
      .ant-menu-item-selected {
        background: linear-gradient(90deg, rgba(24, 144, 255, 0.2), transparent) !important;
        border-right: 3px solid #1890ff !important;
        box-shadow: 0 0 15px rgba(24, 144, 255, 0.3) !important;
      }
      .ant-layout-sider {
        background: radial-gradient(circle at 10% 20%, #001529 0%, #000c17 90%) !important;
        box-shadow: 0 0 20px rgba(0, 0, 0, 0.6) !important;
      }
      .ant-card {
        background: rgba(0, 21, 41, 0.7) !important;
        border: 1px solid rgba(24, 144, 255, 0.2) !important;
        box-shadow: 0 0 15px rgba(24, 144, 255, 0.1) !important;
      }
      .ant-card-head {
        border-bottom: 1px solid rgba(24, 144, 255, 0.2) !important;
      }
      .ant-table {
        background: transparent !important;
      }
      .ant-table-thead > tr > th {
        background: rgba(0, 21, 41, 0.8) !important;
        border-bottom: 1px solid rgba(24, 144, 255, 0.3) !important;
      }
      .ant-table-tbody > tr:hover > td {
        background: rgba(24, 144, 255, 0.05) !important;
      }
      .ant-table-tbody > tr > td {
        border-bottom: 1px solid rgba(24, 144, 255, 0.1) !important;
      }
      .ant-statistic-title {
        color: rgba(255, 255, 255, 0.6) !important;
      }
      .ant-statistic-content {
        color: rgba(255, 255, 255, 0.9) !important;
      }
      body {
        background-color: #000c17;
      }
    `;
    document.head.appendChild(style);

    return () => {
      document.head.removeChild(style);
    };
  }, []);

  return (
    <Layout style={{ minHeight: '100vh', width: '100%' }}>
      <Sider 
        collapsible 
        collapsed={collapsed} 
        onCollapse={(value) => setCollapsed(value)}
        style={{ 
          overflow: 'auto', 
          height: '100vh', 
          position: 'fixed', 
          left: 0, 
          top: 0, 
          bottom: 0,
          background: 'var(--bg-primary)',
          boxShadow: 'var(--shadow-primary)'
        }}
      >
        <div 
          className="logo" 
          style={logoStyle}
        >
          {collapsed ? (
            <span className="sidebar-logo">NFT</span>
          ) : (
            <span className="sidebar-logo">NFT巨鲸追踪</span>
          )}
        </div>
        <Menu
          theme="dark"
          defaultSelectedKeys={['1']}
          mode="inline"
          style={menuStyle}
          onClick={handleMenuClick}
          items={[
            {
              key: '1',
              icon: <WhaleIcon />,
              label: '巨鲸追踪',
            },
            {
              key: '5',
              icon: <LineChartOutlined />,
              label: '交易走势',
            },
            {
              key: '2',
              icon: <MoneyCollectOutlined />,
              label: '藏品狙击',
            },
            {
              key: '3',
              icon: <BulbOutlined />,
              label: '策略推荐',
            },
            {
              key: '4',
              icon: <SettingOutlined />,
              label: '系统设置',
            },
          ]}
        />
      </Sider>
      <Layout style={{ marginLeft: collapsed ? 80 : 200, background: 'var(--bg-primary)' }}>
        <Header style={{ 
          padding: 0, 
          background: 'transparent', 
          boxShadow: 'var(--shadow-base)' 
        }} />
        <Content style={{ margin: '16px' }}>
          <div style={contentBoxStyle}>
            {children}
          </div>
        </Content>
        <Footer style={{ 
          textAlign: 'center', 
          background: 'transparent', 
          color: 'var(--text-tertiary)' 
        }}>
          {/* 移除版权信息 */}
        </Footer>
      </Layout>
    </Layout>
  );
};

export default MainLayout; 