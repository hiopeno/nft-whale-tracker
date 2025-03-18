# NFT鲸鱼追踪与低价NFT狙击系统

该项目是一个基于大数据技术栈的NFT数据分析系统，主要功能包括NFT鲸鱼钱包追踪和低价NFT交易狙击。

## 功能特点

- **NFT交易数据生成**：模拟真实NFT交易数据，包括收藏集、NFT资产、交易记录等
- **鲸鱼钱包追踪**：识别和追踪大额NFT交易和持有者，提供鲸鱼活动分析
- **低价NFT狙击**：发现低于地板价的NFT交易机会，实时提醒
- **异常交易检测**：识别价格异常波动和可疑交易模式
- **数据可视化**：提供直观的数据图表和Dashboard

## 技术栈

- **数据生成**：Java + Spring Boot
- **消息队列**：Kafka
- **数据处理**：Flink
- **数据存储**：Iceberg/Hudi
- **数据分析**：Doris
- **数据可视化**：Superset

## 项目结构

```
nft-whale-tracker/
├── src/                        # 源代码
│   ├── main/
│   │   ├── java/
│   │   │   └── org/bigdatatechcir/whale/
│   │   │       ├── model/      # 数据模型
│   │   │       ├── generator/  # 数据生成器
│   │   │       ├── util/       # 工具类
│   │   │       └── service/    # 服务类
│   │   └── resources/          # 配置文件
└── pom.xml                     # Maven配置
```

## 安装和运行

### 前置条件

- JDK 8+
- Maven 3.6+
- Kafka
- Flink (可选)

### 构建和运行

1. 克隆项目
   ```bash
   git clone https://github.com/yourusername/nft-whale-tracker.git
   cd nft-whale-tracker
   ```

2. 编译项目
   ```bash
   mvn clean package
   ```

3. 运行模拟数据生成器
   ```bash
   java -jar target/nft-whale-tracker-1.0-SNAPSHOT-executable.jar
   ```

4. 配置选项
   
   可以通过修改`application.properties`文件或者运行时传入系统属性来配置应用：
   
   ```bash
   java -Dgenerator.interval=2000 -Dgenerator.collections=5 -jar target/nft-whale-tracker-1.0-SNAPSHOT-executable.jar
   ```

## 数据模型

- **NFT**: NFT资产信息模型
- **NFTCollection**: NFT收藏集模型
- **NFTTransaction**: NFT交易记录模型
- **WhaleWallet**: 鲸鱼钱包模型
- **NFTAlert**: NFT提醒模型，用于低价狙击

## 后续开发计划

- 集成机器学习模型进行价格预测
- 添加区块链数据实时抓取功能
- 开发Web界面和移动应用
- 支持更多区块链网络
- 添加交易机会自动执行功能

## 贡献

欢迎贡献代码、报告问题或提出改进建议。

## 许可证

[MIT License](LICENSE) 