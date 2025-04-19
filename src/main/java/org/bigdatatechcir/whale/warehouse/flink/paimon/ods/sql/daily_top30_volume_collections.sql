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
(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xb8ea78fcacef50d41375e44e6814ebba36bb33c4', 'Good Vibes Club', 'GVC', 'https://i.seadn.io/s/raw/files/8ba2b8fe4048f4e6ea170550ca27a2f7.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xb8ea78fcacef50d41375e44e6814ebba36bb33c4/34487095:about:media:a8b9eeef-2abb-416b-8013-bdf34aefcc87.jpeg?w=500&auto=format', 6969, 2131, false, true, 212, 727, 3615, 9178, '35.9%', '53.05%', '-39.51%', 92.456, 285.2829, 1422.9148, 3231.0276, 0.3869, 0.4361, 0.3924, 0.0894, 0.352, '11.14%', '14.8%', '18.7%', '51.02%', '75.72%', '-28.21%', 2409.1833),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x60e4d786628fea6478f785a6d7e704777c86a7c6', 'MutantApeYachtClub', 'MAYC', 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?w=500&auto=format', 'https://i.seadn.io/gae/5c-HcdLMinTg3LvEwXYZYC-u5nN22Pn5ivTPYA4pVEsWJHU1rCobhUlHSFjZgCHPGSmcGMQGCrDCQU8BfSfygmL7Uol9MRQZt6-gqA?w=500&auto=format', 19551, 11801, false, true, 28, 291, 1178, 158100, '-45.1%', '-14.91%', '38.92%', 73.7198, 758.1871, 3029.9658, 1372522.9758, 2.475, 2.6329, 2.6055, 0, 8.6814, '0.91%', '1.64%', '15.8%', '-44.6%', '-13.52%', '60.86%', 50455.2657),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xd90829c6c6012e4dde506bd95d7499a04b9a56de', 'BROKEN', 'KEYS', 'https://i.seadn.io/gcs/files/0b586298cecf9dbce59a44b8c42addfd.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/c0dc8884fa170cfeef8feb774d84090e.png?w=500&auto=format', 48, 38, false, true, 2, 2, 2, 3, '100%', '100%', '100%', 65.5, 65.5, 65.5, 54.6425, 0, 32.75, 32.75, 0, 18.2142, '100%', '100%', '100%', '100%', '100%', '100%', 0),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xbd3531da5cf5857e7cfaa92426877b022e612cf8', 'PudgyPenguins', 'PPG', 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqg7RFi?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xbd3531da5cf5857e7cfaa92426877b022e612cf8.png', 8888, 5001, false, true, 6, 125, 627, 94470, '-14.29%', '-13.79%', '-28.1%', 65.14, 1223.9887, 6212.5387, 545319.4432, 9.585, 10.8567, 9.7919, 0, 5.7724, '14.32%', '3.68%', '7.96%', '-2.01%', '-10.62%', '-22.37%', 85001.2768),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d', 'BoredApeYachtClub', 'BAYC', 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256', 'https://i.seadn.io/gae/i5dYZRkVCUK97bfprQ3WXyrT9BnLSZtVKGJlKQ919uaUB0sxbngVCioaiyu9r6snqfi2aaTyIvv6DHm4m2R3y7hMajbsv14pSZK8mhs?auto=format&dpr=1&w=2048', 10000, 5460, false, true, 4, 68, 348, 62575, '100%', '-35.24%', '0%', 62.8815, 1061.7829, 5266.2831, 1956748.0195, 14.339, 15.7204, 15.6145, 0, 31.2704, '10.84%', '3.51%', '13.19%', '121.69%', '-32.97%', '13.19%', 153155),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x524cab2ec69124574082676e6f654a18df49a048', 'Lil Pudgys', 'LP', 'https://i.seadn.io/s/raw/files/649289b91d3d0cefccfe6b9c7f83f471.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x524cab2ec69124574082676e6f654a18df49a048/3826365:about:media:6efd80cc-0c7c-4233-83d4-5375c60f89eb.png?w=500&auto=format', 21905, 9871, false, true, 44, 512, 2082, 157267, '-13.73%', '-9.7%', '-31.58%', 52.3687, 627.6453, 2468.4218, 135687.0428, 1.186, 1.1902, 1.2259, 0, 0.8628, '3.97%', '12.18%', '18.82%', '-10.3%', '1.3%', '-18.71%', 25298.0845),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xed5af388653567af2f388e6224dc7c4b3241c544', 'Azuki', 'AZUKI', 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xed5af388653567af2f388e6224dc7c4b3241c544.png', 10000, 4175, false, true, 12, 145, 629, 108672, '-7.69%', '-9.38%', '-26.78%', 43.483, 399.6933, 1831.7351, 1008339.2474, 2.54, 3.6236, 2.7565, 0, 9.2787, '11.6%', '-11.59%', '-3.01%', '3.01%', '-19.87%', '-28.98%', 26366),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x59325733eb952a92e069c87f0a6168b29e80627f', 'Mocaverse', 'MOCA', 'https://i.seadn.io/gcs/files/6a0b776c9bb3973d1dd8d399353da9f5.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/20e81e38bb831b47e23b7ea0e13c6891.png?w=500&auto=format', 8888, 2282, false, true, 21, 47, 174, 15342, '162.5%', '-36.49%', '-22.67%', 39.22, 87.9779, 343.2465, 30306.1301, 1.908, 1.8676, 1.8719, 0, 1.9754, '2.63%', '4.17%', '0.68%', '169.41%', '-33.83%', '-22.14%', 15824.1952),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x5af0d9827e0c53e4799bb226655a1de152a425a5', 'Milady', 'MIL', 'https://i.seadn.io/gae/a_frplnavZA9g4vN3SexO5rrtaBX_cBTaJYcgrPtwQIqPhzgzUendQxiwUdr51CGPE2QyPEa1DHnkW1wLrHAv5DgfC3BP-CWpFq6BA?w=500&auto=format', 'https://i.seadn.io/gae/1TtiQPPiqoc6hqMw3xVYnlEatEi6QhRQGDQA3B3yZfhr2nuXbedAQCOcTs1UZot6-4FXSiYM6xOtHWcaJNwFdRyuOlC_q5erFRbMYA?w=500&auto=format', 10000, 5318, false, true, 11, 113, 572, 78461, '-54.17%', '-42.05%', '-44.84%', 32.6827, 350.9797, 1800.1712, 199079.7726, 2.925, 2.9712, 3.106, 0, 2.5373, '1.45%', '2.95%', '-14.68%', '-53.5%', '-40.34%', '-52.94%', 30771),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x769272677fab02575e84945f03eca517acc544cc', 'Captainz', 'Captainz', 'https://i.seadn.io/gcs/files/6df4d75778066bce740050615bc84e21.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 3317, false, true, 38, 251, 1152, 31371, '-49.33%', '84.56%', '-13.25%', 29.4501, 188.5888, 879.5289, 139901.4447, 0.738, 0.775, 0.7513, 0, 4.4596, '3.69%', '14.32%', '-24.32%', '-47.46%', '110.99%', '-34.35%', 6989.301),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x8a90cab2b38dba80c64b7734e58ee1db38b8992e', 'Doodles', 'DOODLE', 'https://i.seadn.io/s/raw/files/e663a85a2900fdd4bfe8f34a444b72d3.jpg?w=500&auto=format', 'https://i.seadn.io/gae/svc_rQkHVGf3aMI14v3pN-ZTI7uDRwN-QayvixX-nHSMZBgb1L1LReSg1-rXj4gNLJgAB0-yD8ERoT-Q2Gu4cy5AuSg-RdHF9bOxFDw?w=500&auto=format', 10000, 3866, false, true, 9, 154, 846, 78842, '-71.88%', '-37.9%', '-15.65%', 26.515, 451.6299, 2495.9473, 382729.6458, 3.039, 2.9461, 2.9327, 0, 4.8544, '1.51%', '3.17%', '-10.37%', '-71.45%', '-35.94%', '-24.4%', 28572),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xc143bbfcdbdbed6d454803804752a064a622c1f3', 'Async Blueprints', 'ASYNC-BLUEPRINT', 'https://i.seadn.io/gcs/files/d6fb878fdeebeff1518276539a2a8356.png?w=500&auto=format', 'https://i.seadn.io/gae/s-1NTQmqAWvx8wmLfPxnNba6FX3dsLMGe6-YCdcjGZQND0VkwYZtYA3TwyddRLBZzEULclDc8OctXs1jSKF2dejXYdiujiAmiJac?w=500&auto=format', 21481, 6468, false, true, 1, 8, 43, 6690, '-50%', '-55.56%', '-2.27%', 24.69, 98.2489, 338.2176, 11361.8633, 0.001, 24.69, 12.2811, 0, 1.6983, '24.41%', '61.9%', '84.61%', '-37.79%', '-28.04%', '80.41%', 149799.9016),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x6339e5e072086621540d0362c4e3cea0d643e114', 'Opepen Edition', 'OPEPEN', 'https://i.seadn.io/gcs/files/b1c9ed2e584b4f6e418bf1ca15311844.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x6339e5e072086621540d0362c4e3cea0d643e114/22896054:about:media:3e0e24fd-ac54-47b6-aad2-99b0bbe8218b.jpeg?w=500&auto=format', 16000, 3695, false, true, 30, 284, 1013, 197954, '50%', '30.28%', '37.45%', 19.4297, 203.1179, 486.6192, 87550.9051, 0.2377, 0.6477, 0.7152, 0, 0.4423, '15.72%', '46.59%', '30.15%', '73.58%', '90.95%', '78.86%', 9836.8),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x39ee2c7b3cb80254225884ca001f57118c8f21b6', 'Potatoz', 'Potatoz', 'https://i.seadn.io/gcs/files/129b97582f0071212ee7cf440644fc28.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 2432, false, true, 72, 171, 1006, 46481, '100%', '106.02%', '-24.76%', 18.3463, 42.1487, 245.095, 64208.9948, 0.273, 0.2548, 0.2465, 0, 1.3814, '-2.71%', '10.84%', '-22.98%', '94.57%', '128.35%', '-42.05%', 2249.775),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xb6a37b5d14d502c3ab0ae6f3a0e058bc9517786e', ',Azuki Elementals', 'ELEM', 'https://i.seadn.io/gcs/files/bbaf43ee4a02d5affb7e8fc186d0bdb5.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/79bc14c2aae31bcbfd428662e27541ad.jpg?w=500&auto=format', 17605, 6379, false, true, 55, 300, 2043, 94421, '-27.63%', '-22.28%', '-19.28%', 16.5896, 94.2289, 640.1182, 78368.6974, 0.2484, 0.3016, 0.3141, 0, 0.83, '6.5%', '-3.71%', '-14.12%', '-22.91%', '-25.15%', '-30.67%', 5756.835),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x9830b32f7210f0857a859c2a86387e4d1bb760b8', 'Kaito Genesis', 'KAITO', 'https://i.seadn.io/s/raw/files/94bdb2f6224f8508183610037489c3af.png?auto=format&dpr=1&w=48', 'null', 1500, 858, false, false, 8, 79, 343, 4142, '100%', '-27.52%', '-75.29%', 13.2089, 139.0354, 646.7624, 18567.531, 1.684, 1.6511, 1.7599, 1.05, 4.4827, '-2.7%', '3.96%', '-24.64%', '94.59%', '-24.65%', '-81.38%', 2612.85),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xbc37ee54f066e79c23389c55925f877f79f3cb84', 'Seeing Signs', '$IGN', 'https://i.seadn.io/s/raw/files/492e1e9573fe567735cf676364772570.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xbc37ee54f066e79c23389c55925f877f79f3cb84/34209058:about:media:332ab073-cc74-4098-a1cc-95c6109ed5cb.png?w=500&auto=format', 2025, 1312, false, false, 5, 77, 364, 860, '-72.22%', '-33.04%', '68.52%', 9.9, 154.4159, 731.3439, 1508.1065, 2.04, 1.98, 2.0054, 0.4, 1.7536, '-2.52%', '10.72%', '-16.14%', '-72.92%', '-25.86%', '41.32%', 3743.01),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xd4b7d9bb20fa20ddada9ecef8a7355ca983cccb1', 'Quirkies', 'QRKS', 'https://i.seadn.io/gcs/files/9fbc41e66c3fa82e0906c206e64a2d88.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/e381144b3dfcbfc5bdd7bb16a01cfdcb.jpg?w=500&auto=format', 5000, 1527, false, true, 12, 34, 103, 3349, '100%', '-10.53%', '60.94%', 9.8191, 26.9148, 80.7495, 3092.2984, 0.85, 0.8183, 0.7916, 0, 0.9233, '100%', '10.91%', '13.85%', '100%', '-0.75%', '83.23%', 3600.5),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x342639aa0ab0ab367075c1245847bd8d010b74d9', 'No More Liquidity: Genesis Pass', 'NML', 'https://i.seadn.io/s/raw/files/3b516a84fa4f3c4539cdbd04b3088c8f.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x342639aa0ab0ab367075c1245847bd8d010b74d9/31282842:about:media:f366f304-fdc8-4f12-9443-e0308bab7d16.jpeg?w=500&auto=format', 343, 330, false, true, 3, 5, 15, 591, '100%', '66.67%', '-28.57%', 9.76, 16.81, 49.509, 880.8052, 4.5, 3.2533, 3.362, 0, 1.4904, '100%', '12.07%', '12.74%', '100%', '86.78%', '-19.47%', 1101.03),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x8821bee2ba0df28761afff119d66390d594cd280', 'DeGods', 'DEGODS', 'https://i.seadn.io/s/raw/files/7e6fad40382fc62e13653ca7b1a6e0c7.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x8821bee2ba0df28761afff119d66390d594cd280/24414268:about:media:1d866541-27cb-4f08-8541-03cb9b6ade8b.png?w=500&auto=format', 9004, 1316, false, true, 14, 21, 76, 61798, '1,300%', '23.53%', '-57.06%', 9.5419, 15.6599, 48.7902, 223662.5831, 0.742, 0.6816, 0.7457, 0, 3.6193, '-63.16%', '10.61%', '8.45%', '415.78%', '36.62%', '-53.44%', 6158.736),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x790b2cf29ed4f310bf7641f013c65d4560d28371', 'Otherdeed Expanded', 'EXP', 'https://i.seadn.io/gcs/files/9583ab4792a83cd81d5075b59514a34a.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/6b321a0d888251dfb2608481c7498160.png?w=500&auto=format', 55357, 12570, false, true, 29, 269, 1391, 34804, '-9.38%', '-41.14%', '18.99%', 9.1446, 72.6485, 365.1537, 23658.7531, 0.172, 0.3153, 0.2701, 0, 0.6798, '0.99%', '24.13%', '21.14%', '-8.47%', '-26.94%', '44.12%', 12970.1451),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x282bdd42f4eb70e7a9d9f40c8fea0825b7f68c5d', 'CryptoPunks V1 (wrapped)', 'WPV1', 'https://i.seadn.io/gae/iIo0vm6cqiOaUwFI58-Rz61Watioc0GZ_SdhdcFJqgdYlQJNjjdzJ7-vodNEDJMG0ZJ-dE6yELuQfAJ6FzjpqtovU0bd3pLp1F1grg?w=500&auto=format', 'https://i.seadn.io/gae/Im1Lh14BMN_2ttQCWVRGufW7dnxUfnIB8UQSEbr4QVUyUEn-W298ixlTcJbAiLrRPqEnrhYCx8jwNXpvEdRneQKakznyXYLYsIbZsw?w=500&auto=format', 5087, 1111, false, true, 4, 10, 55, 8432, '100%', '-16.67%', '-35.29%', 8.939, 22.379, 145.3154, 54066.4426, 2.098, 2.2348, 2.2379, 0, 6.4121, '-24.12%', '-33.07%', '30.15%', '51.77%', '-44.22%', '-15.78%', 16310.9568),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x1a3c1bf0bd66eb15cd4a61b76a20fb68609f97ef', 'Morph Black', 'BLACK', '', 'null', 3000, 1838, false, false, 11, 147, 1267, 1225, '-47.62%', '-41.43%', '100%', 8.734, 130.5602, 1208.6507, 1174.6947, 0.7899, 0.794, 0.8882, 1.7, 0.9589, '-2.53%', '-9.48%', '100%', '-48.94%', '-46.99%', '100%', 2898.6),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x036721e5a769cc48b3189efbb9cce4471e8a48b1', 'Checks', 'CHECKS', 'https://i.seadn.io/gcs/files/86ce94827a5e991b18f382577fd00281.png?w=500&auto=format', 'https://openseauserdata.com/files/b5b93fd3ab94dcca25665dac14f430f2.svg', 11195, 1489, false, true, 25, 52, 130, 33657, '2,400%', '85.71%', '-50.19%', 7.6542, 25.9056, 68.2253, 26686.3392, 0.3099, 0.3062, 0.4982, 0, 0.7929, '-44.33%', '-13.93%', '81.84%', '1,291.67%', '59.85%', '-9.42%', 7145.7685),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x9378368ba6b85c1fba5b131b530f5f5bedf21a18', 'VeeFriends Series 2', 'VF2', 'https://i.seadn.io/s/raw/files/7c968bade1414b10fb5fd77d7c82e565.jpg?w=500&auto=format', 'https://i.seadn.io/gae/l7-Zz6ZYWJBu4kkFBxnHchfzg3uJlwmCZsfJt7QMJuiX1v7SQgUp-PveFFPi-Zd8J4m0ROQsGFgDcs96OXZu7JOIqC60kzTu7sQGAA?w=500&auto=format', 55555, 20096, false, true, 40, 375, 1245, 52096, '-29.82%', '-14.58%', '103.43%', 7.5205, 48.9919, 147.3077, 35272.0305, 0.0995, 0.188, 0.1306, 0, 0.6771, '43.18%', '13.27%', '-4.75%', '0.5%', '-3.2%', '93.84%', 6683.2665),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xd3d9ddd0cf0a5f0bfb8f7fceae075df687eaebab', 'Redacted Remilio Babies', 'TEST', 'https://i.seadn.io/gcs/files/9d6168e731afd02d5e878eb03876cfd4.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/f80f846ee3f0ce3c83fad5bdc25e3fb2.jpg?w=500&auto=format', 10000, 4263, false, true, 15, 107, 537, 67145, '87.5%', '-26.21%', '-47.2%', 7.5088, 60.2865, 325.0967, 54049.8071, 0.55, 0.5006, 0.5634, 0, 0.805, '-7.33%', '-7.65%', '-13.66%', '73.74%', '-31.85%', '-54.41%', 6151),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x49cf6f5d44e70224e2e23fdcdd2c053f30ada28b', 'CloneX', 'CloneX', 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x49cf6f5d44e70224e2e23fdcdd2c053f30ada28b/3569322:about:media:f6f63025-4215-453e-803f-2b34090dfa29.jpeg?w=500&auto=format', 19764, 9235, false, true, 38, 118, 847, 96624, '153.33%', '-64.02%', '-21.43%', 7.382, 35.2356, 174.2957, 470314.6385, 0.1898, 0.1943, 0.2986, 0, 4.8675, '-1.07%', '63.8%', '-11.6%', '150.53%', '-41.08%', '-30.54%', 4231.4724),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x8d9710f0e193d3f95c0723eaaf1a81030dc9116d', 'TOPIA Worlds', 'TOPIA Worlds', 'https://i.seadn.io/gcs/files/b14329da267669950c65d95b030a305f.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x8d9710f0e193d3f95c0723eaaf1a81030dc9116d/25938324:about:media:05813a18-15d9-41c3-b21f-4f17ba4d23d6.png?w=500&auto=format', 10000, 1097, false, true, 14, 37, 246, 4927, '1,300%', '-36.21%', '-22.15%', 7.301, 18.8012, 108.2769, 7314.59, 0.37, 0.5215, 0.5081, 0, 1.4846, '60.46%', '30.12%', '-4.66%', '2,146.46%', '-16.99%', '-25.79%', 4243),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0xc374a204334d4edd4c6a62f0867c752d65e9579c', 'Project AEON', 'AEON', 'https://i.seadn.io/s/raw/files/5bfdfb6f0307ee8efa28bcba6b620c1e.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xc374a204334d4edd4c6a62f0867c752d65e9579c/31000665:about:media:3395fcca-5f9f-4b2e-aa09-54bc46b5fd1a.jpeg?w=500&auto=format', 3333, 1124, false, true, 7, 59, 366, 13813, '-41.67%', '-56.62%', '-39.1%', 7.037, 56.685, 260.5212, 5504.6238, 0.899, 1.0053, 0.9608, 0, 0.3985, '5.93%', '11.77%', '50.07%', '-38.21%', '-51.51%', '-8.6%', 3055.3611),(CAST('2025-04-19 19:03:01' AS TIMESTAMP), '0x1de7abda2d73a01aa8dca505bdcb773841211daf', 'Sports Rollbots', 'SPORTSBOT', 'https://i.seadn.io/gae/vY0sat6irhxODPlVqkFbKpwwfvTttLmwa4jj8WfNyLK8s0R7aY_3IgXd38Zb54GA1yKxEXZ0bufRBllQAy_y0mzelIk27A6RaOx22A?w=500&auto=format', 'https://i.seadn.io/gae/57kEC5ISf2rx0C289XRZai0sIbsyKELEskI4tRWkEh8ZcTDZZaVfo8lcybI3jmKCaalzGV3PF6z2V7Fooam99Ef2HYQs-3Grt56srw?w=500&auto=format', 10000, 94, false, true, 3, 6, 36, 2190, '100%', '-53.85%', '-29.41%', 6.6808, 9.5013, 58.4968, 1596.5407, 0.4999, 2.2269, 1.5836, 0, 0.729, '100%', '19.26%', '75.25%', '100%', '-44.95%', '23.71%', 15089)
;
