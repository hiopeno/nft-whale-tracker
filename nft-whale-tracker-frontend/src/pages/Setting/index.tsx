import React from 'react';
import { Card, Typography, Divider, Form, Input, Switch, Button, Select, Row, Col, Space, Slider } from 'antd';
import { 
  SettingOutlined, 
  BellOutlined, 
  ApiOutlined, 
  DatabaseOutlined, 
  SecurityScanOutlined,
  DollarOutlined
} from '@ant-design/icons';

const { Title, Text } = Typography;
const { Option } = Select;

// 技术风格的标题组件
const TechTitle: React.FC<{children: React.ReactNode}> = ({ children }) => (
  <Title 
    level={2} 
    className="tech-page-title"
  >
    {children}
  </Title>
);

const Setting: React.FC = () => {
  // 表单布局
  const formItemLayout = {
    labelCol: { span: 6 },
    wrapperCol: { span: 18 },
  };

  // 卡片样式
  const cardStyle = {
    marginBottom: 24,
    boxShadow: '0 0 15px rgba(24, 144, 255, 0.1)',
    border: '1px solid rgba(24, 144, 255, 0.2)',
    background: 'rgba(0, 21, 41, 0.7)'
  };

  // 表单项标题样式
  const labelStyle = {
    color: 'rgba(255, 255, 255, 0.85)'
  };

  return (
    <div style={{ color: 'rgba(255, 255, 255, 0.85)' }}>
      <TechTitle>系统设置</TechTitle>

      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <BellOutlined style={{ color: '#1890ff', marginRight: 8 }} />
            <Text style={{ color: 'rgba(255, 255, 255, 0.85)' }}>预警设置</Text>
          </div>
        } 
        style={cardStyle} 
        bordered={false}
      >
        <Form
          {...formItemLayout}
          initialValues={{ 
            alertThreshold: 'high', 
            minTransactionValue: 50,
            enableEmailAlert: true,
            enablePushAlert: true
          }}
          layout="horizontal"
        >
          <Form.Item 
            name="alertThreshold" 
            label={<span style={labelStyle}>预警阈值</span>}
          >
            <Select style={{ width: 200 }}>
              <Option value="high">仅高风险活动</Option>
              <Option value="medium">中高风险活动</Option>
              <Option value="all">所有异常活动</Option>
            </Select>
          </Form.Item>

          <Form.Item 
            name="minTransactionValue" 
            label={<span style={labelStyle}>最小交易金额 (ETH)</span>}
          >
            <Slider
              min={10}
              max={100}
              marks={{
                10: '10',
                25: '25',
                50: '50',
                75: '75',
                100: '100'
              }}
            />
          </Form.Item>

          <Form.Item 
            name="enableEmailAlert" 
            label={<span style={labelStyle}>邮件通知</span>} 
            valuePropName="checked"
          >
            <Switch />
          </Form.Item>

          <Form.Item 
            name="enablePushAlert" 
            label={<span style={labelStyle}>浏览器推送</span>} 
            valuePropName="checked"
          >
            <Switch />
          </Form.Item>
        </Form>
      </Card>

      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <ApiOutlined style={{ color: '#1890ff', marginRight: 8 }} />
            <Text style={{ color: 'rgba(255, 255, 255, 0.85)' }}>API配置</Text>
          </div>
        } 
        style={cardStyle} 
        bordered={false}
      >
        <Form
          {...formItemLayout}
          initialValues={{ 
            apiEndpoint: 'https://api.nft-whale-tracker.com',
            apiKey: '******************************'
          }}
          layout="horizontal"
        >
          <Form.Item 
            name="apiEndpoint" 
            label={<span style={labelStyle}>API端点</span>}
          >
            <Input />
          </Form.Item>

          <Form.Item 
            name="apiKey" 
            label={<span style={labelStyle}>API密钥</span>}
          >
            <Input.Password />
          </Form.Item>

          <Form.Item 
            name="apiRateLimit" 
            label={<span style={labelStyle}>请求频率限制</span>}
          >
            <Select style={{ width: 200 }}>
              <Option value="low">低 (10次/分钟)</Option>
              <Option value="medium">中 (30次/分钟)</Option>
              <Option value="high">高 (100次/分钟)</Option>
            </Select>
          </Form.Item>
        </Form>
      </Card>

      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <DollarOutlined style={{ color: '#1890ff', marginRight: 8 }} />
            <Text style={{ color: 'rgba(255, 255, 255, 0.85)' }}>交易设置</Text>
          </div>
        } 
        style={cardStyle} 
        bordered={false}
      >
        <Form
          {...formItemLayout}
          initialValues={{ 
            defaultGasPrice: 'medium',
            slippageTolerance: 2.5,
            autoRefresh: true
          }}
          layout="horizontal"
        >
          <Form.Item 
            name="defaultGasPrice" 
            label={<span style={labelStyle}>默认Gas价格</span>}
          >
            <Select style={{ width: 200 }}>
              <Option value="low">低 (慢速)</Option>
              <Option value="medium">中 (标准)</Option>
              <Option value="high">高 (快速)</Option>
            </Select>
          </Form.Item>

          <Form.Item 
            name="slippageTolerance" 
            label={<span style={labelStyle}>滑点容忍度 (%)</span>}
          >
            <Slider
              min={0.5}
              max={5}
              step={0.5}
              marks={{
                0.5: '0.5%',
                2.5: '2.5%',
                5: '5%'
              }}
            />
          </Form.Item>

          <Form.Item 
            name="autoRefresh" 
            label={<span style={labelStyle}>自动刷新数据</span>} 
            valuePropName="checked"
          >
            <Switch />
          </Form.Item>
        </Form>
      </Card>

      <Row gutter={16}>
        <Col span={24} style={{ textAlign: 'right' }}>
          <Space>
            <Button>恢复默认设置</Button>
            <Button type="primary">保存设置</Button>
          </Space>
        </Col>
      </Row>
    </div>
  );
};

export default Setting; 