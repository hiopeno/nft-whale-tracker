-- 当天交易额Top30收藏集数据

-- NFT API数据表结构定义和数据导入

-- 设置执行参数
SET 'execution.checkpointing.interval' = '10s';
SET 'table.exec.state.ttl'= '8640000';
SET 'table.local-time-zone' = 'Asia/Shanghai';

/* 创建Paimon Catalog */
CREATE CATALOG paimon_hive WITH (
    'type' = 'paimon',
    'metastore' = 'hive',
    'uri' = 'thrift://192.168.254.133:9083',
    'hive-conf-dir' = '/opt/software/apache-hive-3.1.3-bin/conf',
    'hadoop-conf-dir' = '/opt/software/hadoop-3.1.3/etc/hadoop',
    'warehouse' = 'hdfs:////user/hive/warehouse'
);

USE CATALOG paimon_hive;
CREATE DATABASE IF NOT EXISTS ods;
USE ods;


-- 当天交易额Top30收藏集
CREATE TABLE IF NOT EXISTS ods_daily_top30_volume_collections (
    record_time TIMESTAMP,
    contract_address VARCHAR(255),
    contract_name VARCHAR(255),
    symbol VARCHAR(255),
    logo_url VARCHAR(1000),
    banner_url VARCHAR(1000),
    items_total INT,
    owners_total INT,
    verified BOOLEAN,
    opensea_verified BOOLEAN,
    sales_1d DECIMAL(30,10),
    sales_7d DECIMAL(30,10),
    sales_30d DECIMAL(30,10),
    sales_total DECIMAL(30,10),
    sales_change_1d VARCHAR(50),
    sales_change_7d VARCHAR(50),
    sales_change_30d VARCHAR(50),
    volume_1d DECIMAL(30,10),
    volume_7d DECIMAL(30,10),
    volume_30d DECIMAL(30,10),
    volume_total DECIMAL(30,10),
    floor_price DECIMAL(30,10),
    average_price_1d DECIMAL(30,10),
    average_price_7d DECIMAL(30,10),
    average_price_30d DECIMAL(30,10),
    average_price_total DECIMAL(30,10),
    average_price_change_1d VARCHAR(50),
    average_price_change_7d VARCHAR(50),
    average_price_change_30d VARCHAR(50),
    volume_change_1d VARCHAR(50),
    volume_change_7d VARCHAR(50),
    volume_change_30d VARCHAR(50),
    market_cap DECIMAL(30,10),
    PRIMARY KEY (record_time, contract_address) NOT ENFORCED
) WITH (
    'bucket' = '4',
    'file.format' = 'parquet',
    'merge-engine' = 'deduplicate',
    'changelog-producer' = 'input',
    'compaction.min.file-num' = '3',
    'compaction.max.file-num' = '30',
    'compaction.target-file-size' = '128MB'
);

-- 插入数据
INSERT INTO ods_daily_top30_volume_collections (
    record_time,
    contract_address,
    contract_name,
    symbol,
    logo_url,
    banner_url,
    items_total,
    owners_total,
    verified,
    opensea_verified,
    sales_1d,
    sales_7d,
    sales_30d,
    sales_total,
    sales_change_1d,
    sales_change_7d,
    sales_change_30d,
    volume_1d,
    volume_7d,
    volume_30d,
    volume_total,
    floor_price,
    average_price_1d,
    average_price_7d,
    average_price_30d,
    average_price_total,
    average_price_change_1d,
    average_price_change_7d,
    average_price_change_30d,
    volume_change_1d,
    volume_change_7d,
    volume_change_30d,
    market_cap
) VALUES
(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xb8ea78fcacef50d41375e44e6814ebba36bb33c4', 'Good Vibes Club', 'GVC', 'https://i.seadn.io/s/raw/files/8ba2b8fe4048f4e6ea170550ca27a2f7.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xb8ea78fcacef50d41375e44e6814ebba36bb33c4/34487095:about:media:a8b9eeef-2abb-416b-8013-bdf34aefcc87.jpeg?w=500&auto=format', 6969, 2097, false, true, 201, 842, 3500, 9178, '-6.07%', '67.73%', '-44.43%', 113.5281, 365.4691, 1408.4878, 3231.0276, 0.435, 0.5648, 0.434, 0.0894, 0.352, '28.57%', '24.14%', '19.94%', '20.76%', '108.25%', '-33.34%', 2409.1833),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x8a90cab2b38dba80c64b7734e58ee1db38b8992e', 'Doodles', 'DOODLE', 'https://i.seadn.io/s/raw/files/e663a85a2900fdd4bfe8f34a444b72d3.jpg?w=500&auto=format', 'https://i.seadn.io/gae/svc_rQkHVGf3aMI14v3pN-ZTI7uDRwN-QayvixX-nHSMZBgb1L1LReSg1-rXj4gNLJgAB0-yD8ERoT-Q2Gu4cy5AuSg-RdHF9bOxFDw?w=500&auto=format', 10000, 3866, false, true, 24, 149, 861, 78842, '100%', '-42.25%', '-4.97%', 71.2462, 436.8601, 2540.0825, 382729.6458, 2.9868, 2.9686, 2.9319, 0, 4.8544, '0%', '3.89%', '-8.7%', '99.99%', '-40%', '-13.24%', 28572),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x5af0d9827e0c53e4799bb226655a1de152a425a5', 'Milady', 'MIL', 'https://i.seadn.io/gae/a_frplnavZA9g4vN3SexO5rrtaBX_cBTaJYcgrPtwQIqPhzgzUendQxiwUdr51CGPE2QyPEa1DHnkW1wLrHAv5DgfC3BP-CWpFq6BA?w=500&auto=format', 'https://i.seadn.io/gae/1TtiQPPiqoc6hqMw3xVYnlEatEi6QhRQGDQA3B3yZfhr2nuXbedAQCOcTs1UZot6-4FXSiYM6xOtHWcaJNwFdRyuOlC_q5erFRbMYA?w=500&auto=format', 10000, 5318, false, true, 20, 112, 585, 78461, '66.67%', '-44.83%', '-41.09%', 59.948, 333.0402, 1835.8421, 199079.7726, 3.0352, 2.9974, 2.9736, 0, 2.5373, '1%', '-4.01%', '-14.62%', '68.33%', '-47.04%', '-49.7%', 30771),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x524cab2ec69124574082676e6f654a18df49a048', 'Lil Pudgys', 'LP', 'https://i.seadn.io/s/raw/files/649289b91d3d0cefccfe6b9c7f83f471.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x524cab2ec69124574082676e6f654a18df49a048/3826365:about:media:6efd80cc-0c7c-4233-83d4-5375c60f89eb.png?w=500&auto=format', 21905, 9857, false, true, 46, 423, 1941, 157267, '9.52%', '-36.96%', '-34.84%', 56.8735, 518.2294, 2304.2061, 135687.0428, 1.235, 1.2364, 1.2251, 0, 0.8628, '3.96%', '9.48%', '16.55%', '13.86%', '-30.98%', '-24.06%', 25298.0845),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb', 'CryptoPunks', 'PUNK', 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb/2563:about:media:70594573-20b8-4f3d-b535-716084978052.png?w=500&auto=format', 10000, 3862, false, true, 1, 14, 134, 26335, '100%', '-58.82%', '19.64%', 52, 732.74, 10709.3186, 1302421.0953, 42, 52, 52.3386, 0, 49.4559, '100%', '-68.63%', '38.49%', '100%', '-87.08%', '65.69%', 1456307),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xdca91409018ea80b71d21e818f00e76072969861', 'Spells of Genesis - Curated', '', 'https://i.seadn.io/gcs/files/fc37bf821646059213c64f11e47ce47c.png?w=500&auto=format', 'https://i.seadn.io/s/raw/files/16d284103546ce097b486f973453cec0.jpg?w=500&auto=format', 222, 747, false, true, 6, 36, 124, 1404, '-45.45%', '80%', '29.17%', 47.819, 62.2551, 76.7705, 603.7057, 0.03, 7.9698, 1.7293, 0, 0.43, '5,816.7%', '275.93%', '219.12%', '3,126.22%', '576.66%', '312.13%', 38.0064),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x60e4d786628fea6478f785a6d7e704777c86a7c6', 'MutantApeYachtClub', 'MAYC', 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?w=500&auto=format', 'https://i.seadn.io/gae/5c-HcdLMinTg3LvEwXYZYC-u5nN22Pn5ivTPYA4pVEsWJHU1rCobhUlHSFjZgCHPGSmcGMQGCrDCQU8BfSfygmL7Uol9MRQZt6-gqA?w=500&auto=format', 19551, 11801, false, true, 16, 287, 1189, 158100, '-40.74%', '-18.93%', '45.18%', 41.8791, 751.337, 3064.7187, 1372522.9758, 2.4587, 2.6174, 2.6179, 0, 8.6814, '-3.43%', '1.96%', '15.89%', '-42.77%', '-17.33%', '68.24%', 50455.2657),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xbd3531da5cf5857e7cfaa92426877b022e612cf8', 'PudgyPenguins', 'PPG', 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqg7RFi?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xbd3531da5cf5857e7cfaa92426877b022e612cf8.png', 8888, 5001, false, true, 4, 92, 586, 94470, '-42.86%', '-45.56%', '-30.24%', 38.313, 895.8197, 5807.622, 545319.4432, 9.584, 9.5783, 9.7372, 0, 5.7724, '-10.1%', '2.08%', '7.24%', '-48.63%', '-44.43%', '-25.19%', 85001.2768),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xed5af388653567af2f388e6224dc7c4b3241c544', 'Azuki', 'AZUKI', 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xed5af388653567af2f388e6224dc7c4b3241c544.png', 10000, 4175, false, true, 14, 107, 623, 108672, '0%', '-48.56%', '-25.57%', 38.2342, 305.9062, 1815.8537, 1008339.2474, 2.54, 2.731, 2.8589, 0, 9.2787, '-21.25%', '-2.91%', '-2.5%', '-21.25%', '-50.06%', '-27.43%', 26366),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x6339e5e072086621540d0362c4e3cea0d643e114', 'Opepen Edition', 'OPEPEN', 'https://i.seadn.io/gcs/files/b1c9ed2e584b4f6e418bf1ca15311844.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x6339e5e072086621540d0362c4e3cea0d643e114/22896054:about:media:3e0e24fd-ac54-47b6-aad2-99b0bbe8218b.jpeg?w=500&auto=format', 16000, 3695, false, true, 114, 310, 1110, 197954, '322.22%', '8.39%', '50%', 36.411, 173.733, 518.8184, 87550.9051, 0.2868, 0.3194, 0.5604, 0, 0.4423, '-43.85%', '-2.32%', '25.98%', '137.1%', '5.88%', '88.99%', 9836.8),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x9f803635a5af311d9a3b73132482a95eb540f71a', 'The Great Color Study', '', 'https://i.seadn.io/gcs/files/3893e730186401d386e308d336d052f5.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/a67b3ac2420a273a72aa1ea71d5045f3.png?w=500&auto=format', 10, 847, false, true, 50, 54, 75, 2487, '2,400%', '390.91%', '212.5%', 26.1429, 27.2129, 31.8803, 777.0209, 0.529, 0.5229, 0.5039, 0, 0.3124, '86.75%', '120.53%', '110.86%', '4,568.38%', '982.5%', '558.75%', 2.312),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xc143bbfcdbdbed6d454803804752a064a622c1f3', 'Async Blueprints', 'ASYNC-BLUEPRINT', 'https://i.seadn.io/gcs/files/d6fb878fdeebeff1518276539a2a8356.png?w=500&auto=format', 'https://i.seadn.io/gae/s-1NTQmqAWvx8wmLfPxnNba6FX3dsLMGe6-YCdcjGZQND0VkwYZtYA3TwyddRLBZzEULclDc8OctXs1jSKF2dejXYdiujiAmiJac?w=500&auto=format', 21481, 6468, false, true, 5, 13, 46, 6690, '400%', '-27.78%', '0%', 21.997, 120.2459, 338.3146, 11361.8633, 0.001, 4.3994, 9.2497, 0, 1.6983, '-82.18%', '21.94%', '61.58%', '-10.91%', '-11.93%', '61.59%', 149799.9016),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x1a3c1bf0bd66eb15cd4a61b76a20fb68609f97ef', 'Morph Black', 'BLACK', '', 'null', 3000, 1838, false, false, 29, 147, 1299, 1225, '107.14%', '-45.76%', '100%', 20.1555, 119.5468, 1231.0162, 1174.6947, 0.7287, 0.695, 0.8132, 1.7, 0.9589, '-11.09%', '-18.04%', '100%', '84.17%', '-55.54%', '100%', 2898.6),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xb6a37b5d14d502c3ab0ae6f3a0e058bc9517786e', ',Azuki Elementals', 'ELEM', 'https://i.seadn.io/gcs/files/bbaf43ee4a02d5affb7e8fc186d0bdb5.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/79bc14c2aae31bcbfd428662e27541ad.jpg?w=500&auto=format', 17605, 6375, false, true, 49, 305, 2044, 94421, '-23.44%', '-26.68%', '-14.41%', 19.1722, 100.3465, 648.0102, 78368.6974, 0.2527, 0.3913, 0.329, 0, 0.83, '13.78%', '0.64%', '-13.72%', '-12.89%', '-26.21%', '-26.13%', 5756.835),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xe64419a4a32bf73743118ed18a442c35f64d57d0', 'Minutes Network Token Validation Node', 'MNTx-VN', '', 'null', 2500, 519, false, false, 6, 27, 27, 11, '500%', '100%', '100%', 17.53, 81.594, 81.594, 34.564, 3.2, 2.9217, 3.022, 3.84, 3.1422, '-5.75%', '100%', '100%', '465.48%', '100%', '100%', 7855.5),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xba30e5f9bb24caa003e9f2f0497ad287fdf95623', 'BoredApeKennelClub', 'BAKC', 'https://i.seadn.io/gcs/files/c4dfc6be4d9c5d4f073de2efe181416a.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/a5414557ae405cb6233b4e2e4fa1d9e6.jpg?w=500&auto=format', 9602, 5205, false, true, 27, 71, 319, 72884, '285.71%', '5.97%', '12.72%', 16.8673, 42.5269, 182.7052, 317155.5167, 0.64, 0.6247, 0.599, 0, 4.3515, '6.86%', '7.5%', '17.67%', '312.16%', '13.91%', '32.64%', 5405.926),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x5946aeaab44e65eb370ffaa6a7ef2218cff9b47d', 'Creepz by OVERLORD', 'CBC', 'https://i.seadn.io/s/raw/files/27ad9c03712ad3f9f6078ea0c3f3dc68.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x5946aeaab44e65eb370ffaa6a7ef2218cff9b47d/4520978:about:media:56bd2aad-9785-4d33-b402-d1bb73feedaa.png?w=500&auto=format', 10463, 2341, false, true, 8, 64, 183, 9224, '166.67%', '64.1%', '-23.11%', 13.78, 122.4885, 326.5083, 21749.2674, 1.6909, 1.7225, 1.9139, 0, 2.3579, '-11.95%', '15.46%', '-10.9%', '134.79%', '89.48%', '-31.49%', 17930.4431),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x42069abfe407c60cf4ae4112bedead391dba1cdb', 'CryptoDickbutts S3', 'CDB', 'https://i.seadn.io/gae/vw-gp8yUYkQsxQN5xbHrWEhY7rQWQZhIjgO2tvLxu46VY6iwulwWZt5VFS2Q9gy9qJaiJk8QspZs0qaM9z1ODeIyeUUseABOxdfVrC8?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x42069abfe407c60cf4ae4112bedead391dba1cdb/834926:about:media:a91867fb-ab41-4216-81a3-aacd857a5000.png?w=500&auto=format', 5200, 2045, false, true, 16, 49, 162, 17130, '220%', '-33.78%', '121.92%', 12.6289, 29.8457, 96.2157, 19152.3715, 0.8644, 0.7893, 0.6091, 0, 1.1181, '-10.18%', '17.36%', '-9.04%', '187.41%', '-22.28%', '101.88%', 2637.96),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xd3d9ddd0cf0a5f0bfb8f7fceae075df687eaebab', 'Redacted Remilio Babies', 'TEST', 'https://i.seadn.io/gcs/files/9d6168e731afd02d5e878eb03876cfd4.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/f80f846ee3f0ce3c83fad5bdc25e3fb2.jpg?w=500&auto=format', 10000, 4263, false, true, 23, 112, 542, 67145, '43.75%', '-24.83%', '-46.18%', 12.3649, 62.9752, 326.2339, 54049.8071, 0.55, 0.5376, 0.5623, 0, 0.805, '7.48%', '-7.85%', '-13.74%', '54.51%', '-30.74%', '-53.57%', 6151),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x59325733eb952a92e069c87f0a6168b29e80627f', 'Mocaverse', 'MOCA', 'https://i.seadn.io/gcs/files/6a0b776c9bb3973d1dd8d399353da9f5.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/20e81e38bb831b47e23b7ea0e13c6891.png?w=500&auto=format', 8888, 2282, false, true, 6, 50, 174, 15342, '-68.42%', '-35.06%', '-18.31%', 11.3023, 93.6402, 342.4694, 30306.1301, 1.96, 1.8837, 1.8728, 0, 1.9754, '1.33%', '4.04%', '0.29%', '-68%', '-32.44%', '-18.07%', 15824.1952),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x7d8820fa92eb1584636f4f5b8515b5476b75171a', 'Murakami.Flowers', 'M.F', 'https://i.seadn.io/gae/8g0poMCQ5J9SZHMsBrefrXbwzFmOQ-333l5OtbqqPW8TSGO9Stm2Rhd7kwHKsKIZPLxDjzISeeDTZ1H35t7GswPRoIfzTnNPsLs7rxw?w=500&auto=format', 'https://i.seadn.io/gcs/files/21d3096668500ce54668cb0081533b66.png?w=500&auto=format', 10175, 5219, false, true, 20, 69, 235, 17560, '42.86%', '0%', '97.48%', 11.215, 26.3587, 73.5801, 29380.8213, 0.399, 0.5608, 0.382, 0, 1.6732, '88.31%', '46.36%', '48.46%', '169.04%', '46.34%', '193.19%', 2821.5275),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x062e691c2054de82f28008a8ccc6d7a1c8ce060d', 'PudgyPresent', 'PP', 'https://i.seadn.io/gcs/files/866691c691d0426769120db411b57e86.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/dd5cf2b160db47a2544a970f598b6cb6.png?w=500&auto=format', 7399, 2962, false, true, 28, 56, 264, 41808, '1,300%', '-44%', '-32.99%', 11.116, 22.4199, 120.4011, 22930.7077, 0.389, 0.397, 0.4004, 0, 0.5485, '4.58%', '1.26%', '0.11%', '1,364.17%', '-43.3%', '-32.93%', 2927.7843),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x306b1ea3ecdf94ab739f1910bbda052ed4a9f949', 'Beanz', 'BEANZ', 'https://i.seadn.io/gae/_R4fuC4QGYd14-KwX2bD1wf-AWjDF2VMabfqWFJhIgiN2FnAUpnD5PLdJORrhQ8gly7KcjhQZZpuzYVPF7CDSzsqmDh97z84j2On?w=500&auto=format', 'https://i.seadn.io/gae/WRcl2YH8E3_7884mcJ0DRN7STGqA8xZQKd-0MFmPftlxUR6i1xB9todMXRW2M6SIpXKAZ842UqKDm1UrkKG8nr7l9NjCkIw-GLQSFQ?w=500&auto=format', 19950, 8305, false, true, 23, 153, 1082, 166338, '15%', '-45.94%', '-16.38%', 10.5177, 28.819, 181.4972, 218461.7157, 0.14, 0.4573, 0.1884, 0, 1.3134, '224.79%', '31.2%', '7.36%', '273.42%', '-29.06%', '-10.21%', 2832.9),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xbc37ee54f066e79c23389c55925f877f79f3cb84', 'Seeing Signs', '$IGN', 'https://i.seadn.io/s/raw/files/492e1e9573fe567735cf676364772570.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xbc37ee54f066e79c23389c55925f877f79f3cb84/34209058:about:media:332ab073-cc74-4098-a1cc-95c6109ed5cb.png?w=500&auto=format', 2025, 1312, false, false, 5, 79, 367, 860, '-16.67%', '-33.05%', '70.7%', 10.43, 158.4559, 736.3639, 1508.1065, 2.1, 2.086, 2.0058, 0.4, 1.7536, '5.53%', '10.04%', '-16.28%', '-12.06%', '-26.33%', '42.91%', 3743.01),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270', 'Art Blocks', 'BLOCKS', 'https://i.seadn.io/gcs/files/fd5e8fa6bb4e39cddcdb4c9a0b685c5e.png?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270.png', 198051, 38012, false, true, 13, 245, 749, 234163, '-43.48%', '29.63%', '-23.49%', 10.0492, 33.7035, 294.2357, 446025.7279, 0.12, 0.773, 0.1376, 0, 1.9048, '1,697.67%', '-81.48%', '-46.09%', '916.82%', '-76%', '-58.75%', 87835.6185),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xd21818b6052df69eed04e9b2af564b75140aacb7', 'INSPIRATI4N', 'INSPIRATION', 'https://i.seadn.io/gae/yUIO5mWaHzRxV5pZWay_7R-mNVwv5tf_qucl2vAAzgo6eraATdf87L9DdHHcrRJxLAVaaDs7ZG_2I8DGDXKcOJBF6LB7HgtbWAi6rjQ?w=500&auto=format', 'https://i.seadn.io/gae/cS-nANxOx-V8pCWZKCJ2DSnoCkpqCnMtrIXACLr_nn1WdT613s1MinWOeze4SXteQDPYcbDKvkDA7aLdB5hUbhpa8HjhS5sEX6jF?w=500&auto=format', 5451, 1450, false, true, 17, 21, 40, 4006, '1,600%', '320%', '207.69%', 8.9701, 9.6925, 10.9586, 1048.1307, 0.0831, 0.5277, 0.4615, 0, 0.2616, '455.47%', '425.63%', '-31.62%', '9,342.21%', '2,107.86%', '110.36%', 478.5978),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x2ced5bc349d9241a314d3739f12f5f6f2bda6a68', 'PROOF Pass', 'PP', 'https://i.seadn.io/s/raw/files/08025fd11068e96327719191a52d00ae.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x2ced5bc349d9241a314d3739f12f5f6f2bda6a68/30911144:hero:desktop_hero_media:6dbc45f7-2ae8-44c2-a90e-7911632a41e2.png?w=500&auto=format', 222, 216, false, true, 1, 1, 3, 572, '100%', '100%', '-66.67%', 8.35, 8.35, 25.77, 932.904, 8.35, 8.35, 8.35, 0, 1.631, '100%', '100%', '18.96%', '100%', '100%', '-60.35%', 0),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x3e34ff1790bf0a13efd7d77e75870cb525687338', 'DAMAGE CONTROL', 'DAMGE', 'https://i.seadn.io/s/raw/files/2a03698df217570b09de93dd3e0a2d43.gif?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x3e34ff1790bf0a13efd7d77e75870cb525687338/31228811:about:media:bf571909-6758-422f-80a0-58c5c40c8000.gif?w=500&auto=format', 10, 914, false, true, 4, 25, 95, 1538, '0%', '-46.81%', '102.13%', 7.9, 41.9546, 125.7846, 1291.3097, 1.2, 1.975, 1.6782, 0, 0.8396, '59.69%', '23.93%', '77.98%', '59.69%', '-34.08%', '259.78%', 14.492),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0x39ee2c7b3cb80254225884ca001f57118c8f21b6', 'Potatoz', 'Potatoz', 'https://i.seadn.io/gcs/files/129b97582f0071212ee7cf440644fc28.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 2432, false, true, 31, 189, 1011, 46481, '-56.34%', '117.24%', '-25.39%', 7.7123, 46.9756, 245.1684, 64208.9948, 0.2469, 0.2488, 0.2485, 0, 1.3814, '-2.7%', '11.54%', '-22.94%', '-57.52%', '142.38%', '-42.5%', 2249.775),(CAST('2025-04-20 20:51:52' AS TIMESTAMP), '0xa3aee8bce55beea1951ef834b99f3ac60d1abeeb', 'VeeFriends', 'VFT', 'https://i.seadn.io/s/raw/files/7c968bade1414b10fb5fd77d7c82e565.jpg?w=500&auto=format', 'https://i.seadn.io/gae/4RYeNt3ET75VLMoCZz-fsOhXg8AW8qlkHfgkbA0FfEayNpsHvOZROygyy9IhY4LwrnJUXqkeDjBZBr8bCf0Ng_xUiRZqWRGng3sc?w=500&auto=format', 10255, 4773, false, true, 3, 17, 192, 10078, '200%', '-68.52%', '13.61%', 7.61, 33.72, 406.6366, 71324.9537, 1.67, 2.5367, 1.9835, 0, 7.0773, '44.95%', '3.73%', '4.21%', '334.86%', '-67.34%', '18.39%', 19849.578)
;
