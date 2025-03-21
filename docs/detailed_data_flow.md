```mermaid
graph TD
    %% 数据源和ODS
    DataSource[区块链数据源] --> ODS[ods_nft_transaction_inc]
    
    %% ODS到DWD层
    ODS -->|清洗标准化| DWD_NFT[dwd_nft_transaction_inc]
    ODS -->|价格分析| DWD_Price[dwd_price_behavior_inc]
    
    %% DWD层详细信息
    DWD_NFT -->|id, nftId, collectionId| DWD_NFT_Details["{<br/>id, dt, transactionHash<br/>tokenId, nftId, collectionId<br/>seller, buyer, price<br/>price_usd, marketplace<br/>isWhaleTransaction<br/>}"]
    
    DWD_Price -->|id, nftId, price| DWD_Price_Details["{<br/>id, dt, nftId<br/>current_price, price_change<br/>market_avg_price<br/>floor_price, price_trend<br/>is_outlier<br/>}"]
    
    %% DWD到DIM层
    DWD_NFT -->|nftId, price, ts| DIM_NFT[dim_nft_full]
    DWD_NFT -->|buyer, seller| DIM_Wallet[dim_wallet_full]
    DWD_NFT -->|marketplace| DIM_Marketplace[dim_marketplace_full]
    DWD_Price -->|nftId, price_trend| DIM_NFT
    
    %% DIM层详细信息
    DIM_NFT -->|id, rarity_score| DIM_NFT_Details["{<br/>id, collection_id<br/>token_id, creator_address<br/>owner_address<br/>all_time_high_price<br/>holding_period_avg<br/>price_growth_30d<br/>liquidity_score<br/>}"]
    
    DIM_Wallet -->|address, wallet_type| DIM_Wallet_Details["{<br/>address, wallet_type<br/>total_asset_value_usd<br/>total_buy_count<br/>total_sell_count<br/>active_days<br/>profit_loss_usd<br/>trading_strategy<br/>influence_score<br/>}"]
    
    DIM_Marketplace -->|id, name| DIM_Marketplace_Details["{<br/>id, name<br/>marketplace_fee_ratio<br/>trading_volume_usd<br/>unique_users<br/>market_rank<br/>market_share<br/>}"]
    
    %% 应用层
    DIM_NFT -->|价值评估| App_Valuation[NFT价值评估]
    DIM_Wallet -->|用户画像| App_User[鲸鱼用户分析]
    DIM_Marketplace -->|市场分析| App_Market[市场趋势分析]
    
    %% 汇总应用
    App_Valuation --> Final_App[鲸鱼行为追踪与预测]
    App_User --> Final_App
    App_Market --> Final_App
    
    %% 样式定义
    classDef sourceClass fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef odsClass fill:#ffe6cc,stroke:#d79b00,stroke-width:1px;
    classDef dwdClass fill:#d5e8d4,stroke:#82b366,stroke-width:1px;
    classDef dwdDetailsClass fill:#d5e8d4,stroke:#82b366,stroke-width:1px,stroke-dasharray: 5 5;
    classDef dimClass fill:#dae8fc,stroke:#6c8ebf,stroke-width:1px;
    classDef dimDetailsClass fill:#dae8fc,stroke:#6c8ebf,stroke-width:1px,stroke-dasharray: 5 5;
    classDef appClass fill:#e1d5e7,stroke:#9673a6,stroke-width:1px;
    
    %% 应用样式
    class DataSource sourceClass;
    class ODS odsClass;
    class DWD_NFT,DWD_Price dwdClass;
    class DWD_NFT_Details,DWD_Price_Details dwdDetailsClass;
    class DIM_NFT,DIM_Wallet,DIM_Marketplace dimClass;
    class DIM_NFT_Details,DIM_Wallet_Details,DIM_Marketplace_Details dimDetailsClass;
    class App_Valuation,App_User,App_Market,Final_App appClass;
```

# NFT鲸鱼追踪系统 - 详细数据流图

## 表间关系说明

### ODS层到DWD层
- **ods_nft_transaction_inc → dwd_nft_transaction_inc**:
  - 标准化交易数据，添加价格换算（ETH/USD）
  - 标记鲸鱼交易，计算异常评分
  - 提取时间维度信息

- **ods_nft_transaction_inc → dwd_price_behavior_inc**:
  - 分析价格变动趋势和幅度
  - 计算相对地板价差异
  - 识别异常价格波动

### DWD层到DIM层
- **dwd_nft_transaction_inc → dim_nft_full**:
  - 汇总NFT交易历史
  - 计算交易频率、价格高低点
  - 识别当前持有者和创建者

- **dwd_nft_transaction_inc → dim_wallet_full**:
  - 分析用户交易行为
  - 统计买入/卖出比例
  - 评估用户影响力和活跃度

- **dwd_nft_transaction_inc → dim_marketplace_full**:
  - 计算平台交易量和用户数
  - 分析平台市场份额和增长率

## 核心表字段说明

### DWD层
- **dwd_nft_transaction_inc**: NFT交易明细，包含交易ID、NFT标识、买卖双方、价格、交易市场等
- **dwd_price_behavior_inc**: 价格行为分析，包含价格变动、偏离度、趋势判断等

### DIM层
- **dim_nft_full**: NFT画像，包含创建者、持有者、价格历史、流动性评分等
- **dim_wallet_full**: 钱包画像，包含交易统计、持仓资产、盈亏情况、活跃度等
- **dim_marketplace_full**: 市场画像，包含交易量、用户数、市场份额、费率等

## 技术实现
- **实时处理引擎**: Apache Flink
- **SQL语言**: Flink SQL
- **存储格式**: Paimon（支持增量更新）
- **元数据管理**: Hive Metastore
- **计算策略**: 增量计算 + 全量更新 