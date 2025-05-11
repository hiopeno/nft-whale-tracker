import React, { useState, useEffect } from 'react';
import { Card, Typography, Divider, Form, Input, Switch, Button, Select, Row, Col, Space, Slider, Tabs, Table, message } from 'antd';
import { 
  SettingOutlined, 
  BellOutlined, 
  ApiOutlined, 
  DatabaseOutlined, 
  SecurityScanOutlined,
  DollarOutlined,
  ReloadOutlined
} from '@ant-design/icons';
import { websocketApi, dataLakeApi } from '../../api/api';

const { Title, Text } = Typography;
const { TabPane } = Tabs;
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
  const [transactionNotificationEnabled, setTransactionNotificationEnabled] = useState(true);
  const [dealOpportunityEnabled, setDealOpportunityEnabled] = useState(true);
  const [loading, setLoading] = useState(false);
  
  // 数据湖浏览器状态
  const [databases, setDatabases] = useState<string[]>([]);
  const [selectedDatabase, setSelectedDatabase] = useState<string>('');
  const [tables, setTables] = useState<string[]>([]);
  const [selectedTable, setSelectedTable] = useState<string>('');
  const [tableSchema, setTableSchema] = useState<any[]>([]);
  const [tableData, setTableData] = useState<any[]>([]);
  const [dataLoading, setDataLoading] = useState(false);
  
  useEffect(() => {
    // 加载数据库列表
    loadDatabases();
  }, []);
  
  // 加载数据库列表
  const loadDatabases = async () => {
    try {
      setDataLoading(true);
      const response: any = await dataLakeApi.getDatabases();
      setDatabases(Array.isArray(response) ? response : []);
      setDataLoading(false);
      
      if (Array.isArray(response) && response.length > 0) {
        setSelectedDatabase(response[0]);
        loadTables(response[0]);
      }
    } catch (error) {
      console.error('加载数据库列表失败', error);
      message.error('加载数据库列表失败');
      setDataLoading(false);
    }
  };
  
  // 加载表列表
  const loadTables = async (database: string) => {
    try {
      setDataLoading(true);
      const response: any = await dataLakeApi.getTables(database);
      setTables(Array.isArray(response) ? response : []);
      setDataLoading(false);
      
      if (Array.isArray(response) && response.length > 0) {
        setSelectedTable(response[0]);
        loadTableSchema(database, response[0]);
        loadTableData(database, response[0]);
      } else {
        setSelectedTable('');
        setTableSchema([]);
        setTableData([]);
      }
    } catch (error) {
      console.error(`加载数据库 ${database} 的表列表失败`, error);
      message.error(`加载数据库 ${database} 的表列表失败`);
      setDataLoading(false);
    }
  };
  
  // 加载表结构
  const loadTableSchema = async (database: string, table: string) => {
    try {
      setDataLoading(true);
      const response: any = await dataLakeApi.getTableSchema(database, table);
      setTableSchema(Array.isArray(response) ? response : []);
      setDataLoading(false);
    } catch (error) {
      console.error(`加载表 ${database}.${table} 的结构失败`, error);
      message.error(`加载表 ${database}.${table} 的结构失败`);
      setDataLoading(false);
    }
  };
  
  // 加载表数据
  const loadTableData = async (database: string, table: string, limit: number = 1000) => {
    try {
      setDataLoading(true);
      const response: any = await dataLakeApi.queryTableData(database, table, limit);
      setTableData(Array.isArray(response) ? response : []);
      setDataLoading(false);
    } catch (error) {
      console.error(`查询表 ${database}.${table} 数据失败`, error);
      message.error(`查询表 ${database}.${table} 数据失败`);
      setDataLoading(false);
    }
  };
  
  // 处理数据库选择变化
  const handleDatabaseChange = (value: string) => {
    setSelectedDatabase(value);
    setSelectedTable('');
    setTableSchema([]);
    setTableData([]);
    loadTables(value);
  };
  
  // 处理表选择变化
  const handleTableChange = (value: string) => {
    setSelectedTable(value);
    setTableSchema([]);
    setTableData([]);
    loadTableSchema(selectedDatabase, value);
    loadTableData(selectedDatabase, value);
  };
  
  // 刷新当前表数据
  const refreshTableData = () => {
    if (selectedDatabase && selectedTable) {
      loadTableData(selectedDatabase, selectedTable);
    }
  };

  // 开启/关闭交易通知
  const toggleTransactionNotification = async (checked: boolean) => {
    setLoading(true);
    try {
      await websocketApi.setTransactionNotificationEnabled(checked);
      setTransactionNotificationEnabled(checked);
      message.success(`${checked ? '开启' : '关闭'}交易通知成功`);
    } catch (error) {
      message.error(`${checked ? '开启' : '关闭'}交易通知失败`);
      console.error(error);
    }
    setLoading(false);
  };

  // 开启/关闭低价机会检测
  const toggleDealOpportunity = async (checked: boolean) => {
    setLoading(true);
    try {
      await websocketApi.setDealOpportunityEnabled(checked);
      setDealOpportunityEnabled(checked);
      message.success(`${checked ? '开启' : '关闭'}低价机会检测成功`);
    } catch (error) {
      message.error(`${checked ? '开启' : '关闭'}低价机会检测失败`);
      console.error(error);
    }
    setLoading(false);
  };

  // 手动触发市场扫描
  const scanMarketplace = async () => {
    setLoading(true);
    try {
      await websocketApi.scanMarketplace();
      message.success('触发市场扫描成功');
    } catch (error) {
      message.error('触发市场扫描失败');
      console.error(error);
    }
    setLoading(false);
  };

  // 构建表格列
  const getColumns = () => {
    if (tableData.length === 0 || !tableData[0]) return [];
    
    // 如果有表结构信息，使用表结构的字段顺序
    if (tableSchema.length > 0) {
      // 从表结构中获取字段名称顺序
      const fieldOrder = tableSchema.map(field => field.name);
      
      // 根据表结构字段顺序创建columns
      return fieldOrder.map(fieldName => {
        // 检查数据中是否存在该字段
        if (tableData[0].hasOwnProperty(fieldName)) {
          return {
            title: fieldName,
            dataIndex: fieldName,
            key: fieldName,
            ellipsis: true,
            render: (text: any) => {
              if (text === null || text === undefined) return '-';
              if (typeof text === 'object') return JSON.stringify(text);
              return String(text);
            }
          };
        }
        return null;
      }).filter(Boolean) as {
        title: string;
        dataIndex: string;
        key: string;
        ellipsis: boolean;
        render: (text: any) => string;
      }[]; // 过滤掉不存在的字段并指定类型
    }
    
    // 如果没有表结构信息，则使用默认顺序
    return Object.keys(tableData[0]).map(key => ({
      title: key,
      dataIndex: key,
      key: key,
      ellipsis: true,
      render: (text: any) => {
        if (text === null || text === undefined) return '-';
        if (typeof text === 'object') return JSON.stringify(text);
        return String(text);
      }
    }));
  };
  
  // 表结构列
  const schemaColumns = [
    {
      title: '字段名',
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: '类型',
      dataIndex: 'type',
      key: 'type',
    }
  ];

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
    color: '#ffffff'
  };
  
  // 全局文本样式
  const textStyle = {
    color: '#ffffff'
  };
  
  // 表格样式
  const tableStyle = {
    color: '#ffffff'
  };
  
  // 添加自定义样式到组件中
  useEffect(() => {
    // 添加全局样式
    const style = document.createElement('style');
    style.innerHTML = `
      .ant-form-item-label > label {
        color: #ffffff !important;
      }
      
      .ant-form-item-extra {
        color: rgba(255, 255, 255, 0.65) !important;
      }
      
      .ant-table {
        color: #ffffff !important;
      }
      
      .ant-card-head-title, .ant-card-extra {
        color: #ffffff !important;
      }
      
      .ant-table-thead > tr > th {
        color: #ffffff !important;
      }
      
      .ant-table-tbody > tr > td {
        color: #ffffff !important;
      }
      
      .ant-tabs-tab {
        color: rgba(255, 255, 255, 0.65) !important;
      }
      
      .ant-tabs-tab.ant-tabs-tab-active .ant-tabs-tab-btn {
        color: #ffffff !important;
      }
      
      .ant-select-selection-item {
        color: #ffffff !important;
      }
      
      .ant-select-item-option-content {
        color: #ffffff !important;
      }
      
      .ant-select-dropdown {
        background-color: #001529 !important;
      }
      
      .ant-select-item-option-selected:not(.ant-select-item-option-disabled) {
        background-color: #1890ff3d !important;
      }
      
      .ant-divider-inner-text {
        color: #ffffff !important;
      }
      
      .ant-form-item {
        color: #ffffff !important;
      }
      
      .ant-input, .ant-input-password {
        color: #ffffff !important;
        background-color: rgba(0, 21, 41, 0.5) !important;
        border-color: #1890ff5e !important;
      }
      
      .ant-select-selector {
        color: #ffffff !important;
        background-color: rgba(0, 21, 41, 0.5) !important;
        border-color: #1890ff5e !important;
      }
    `;
    document.head.appendChild(style);

    return () => {
      document.head.removeChild(style);
    };
  }, []);

  return (
    <div style={{ color: '#ffffff' }}>
      <TechTitle>系统设置</TechTitle>

      <Tabs defaultActiveKey="1">
        <TabPane tab="通知设置" key="1">
          <Row gutter={[16, 16]}>
            <Col span={24}>
              <Card title="实时通知设置" bordered={false}>
                <Form layout="vertical">
                  <Form.Item label="交易通知" extra="接收鲸鱼交易的实时通知">
                    <Switch 
                      checked={transactionNotificationEnabled} 
                      onChange={toggleTransactionNotification} 
                      loading={loading}
                    />
                  </Form.Item>
                  
                  <Form.Item label="低价机会通知" extra="接收NFT低价出售机会的实时通知">
                    <Switch 
                      checked={dealOpportunityEnabled} 
                      onChange={toggleDealOpportunity} 
                      loading={loading}
                    />
                  </Form.Item>
                  
                  <Form.Item>
                    <Button 
                      type="primary" 
                      onClick={scanMarketplace} 
                      loading={loading}
                    >
                      手动触发市场扫描
                    </Button>
                  </Form.Item>
                </Form>
              </Card>
            </Col>
          </Row>
        </TabPane>
        
        <TabPane tab="数据湖浏览器" key="2">
          <Row gutter={[16, 16]}>
            <Col span={24}>
              <Card title="数据湖浏览器" extra={<Button icon={<ReloadOutlined />} onClick={loadDatabases}>刷新</Button>} bordered={false}>
                <div style={{ marginBottom: '16px' }}>
                  <Form layout="inline">
                    <Form.Item label="数据库">
                      <Select 
                        value={selectedDatabase} 
                        onChange={handleDatabaseChange} 
                        style={{ width: 180 }}
                        loading={dataLoading}
                      >
                        {databases.map(db => (
                          <Option key={db} value={db}>{db}</Option>
                        ))}
                      </Select>
                    </Form.Item>
                    
                    <Form.Item label="表">
                      <Select 
                        value={selectedTable} 
                        onChange={handleTableChange} 
                        style={{ width: 220 }}
                        loading={dataLoading}
                      >
                        {tables.map(table => (
                          <Option key={table} value={table}>{table}</Option>
                        ))}
                      </Select>
                    </Form.Item>
                    
                    <Form.Item>
                      <Button 
                        type="primary"
                        icon={<DatabaseOutlined />}
                        onClick={refreshTableData}
                        loading={dataLoading}
                      >
                        查询
                      </Button>
                    </Form.Item>
                  </Form>
                </div>
                
                <Table 
                  columns={getColumns()} 
                  dataSource={tableData} 
                  rowKey={(record, index) => index?.toString() || '0'}
                  size="small"
                  scroll={{ x: true }}
                  pagination={{ pageSize: 5 }}
                  loading={dataLoading}
                />
              </Card>
            </Col>
          </Row>
        </TabPane>
      </Tabs>

      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <BellOutlined style={{ color: '#1890ff', marginRight: 8 }} />
            <Text style={textStyle}>预警设置</Text>
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
            <Text style={textStyle}>API配置</Text>
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
            <Text style={textStyle}>交易设置</Text>
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