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
(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d', 'BoredApeYachtClub', 'BAYC', 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256', 'https://i.seadn.io/gae/i5dYZRkVCUK97bfprQ3WXyrT9BnLSZtVKGJlKQ919uaUB0sxbngVCioaiyu9r6snqfi2aaTyIvv6DHm4m2R3y7hMajbsv14pSZK8mhs?auto=format&dpr=1&w=2048', 10000, 5451, false, true, 16, 94, 361, 62542, '128.57%', '-9.62%', '-23.68%', 285.917, 1447.7551, 5361.5169, 1956263.0165, 14.69, 17.8698, 15.4017, 0, 31.2792, '11.7%', '-1.79%', '10.94%', '155.32%', '-11.23%', '-15.33%', 155088),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xbd3531da5cf5857e7cfaa92426877b022e612cf8', 'PudgyPenguins', 'PPG', 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqg7RFi?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xbd3531da5cf5857e7cfaa92426877b022e612cf8.png', 8888, 4990, false, true, 28, 149, 633, 94431, '-20%', '-23.2%', '-63.18%', 271.1046, 1445.2517, 6227.5326, 544941.2451, 10, 9.6823, 9.6997, 0, 5.7708, '-2.03%', '-0.02%', '5.45%', '-21.63%', '-23.21%', '-61.17%', 85211.9224),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb', 'CryptoPunks', 'PUNK', 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb/2563:about:media:70594573-20b8-4f3d-b535-716084978052.png?w=500&auto=format', 10000, 3863, false, true, 4, 34, 146, 26331, '100%', '3.03%', '33.94%', 225.99, 5692.67, 11322.1326, 1302203.1153, 42.49, 56.4975, 167.4315, 0, 49.4551, '27.26%', '215.65%', '35.4%', '154.52%', '225.22%', '81.36%', 1477015),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x524cab2ec69124574082676e6f654a18df49a048', 'Lil Pudgys', 'LP', 'https://i.seadn.io/s/raw/files/649289b91d3d0cefccfe6b9c7f83f471.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x524cab2ec69124574082676e6f654a18df49a048/3826365:about:media:6efd80cc-0c7c-4233-83d4-5375c60f89eb.png?w=500&auto=format', 21905, 9857, false, true, 92, 650, 2156, 157105, '-28.68%', '77.6%', '-59.73%', 118.2511, 747.6569, 2518.6046, 135485.6386, 1.299, 1.2853, 1.1502, 0, 0.8624, '4.79%', '0.6%', '16.47%', '-25.27%', '78.68%', '-53.1%', 24886.2705),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x8a90cab2b38dba80c64b7734e58ee1db38b8992e', 'Doodles', 'DOODLE', 'https://i.seadn.io/s/raw/files/e663a85a2900fdd4bfe8f34a444b72d3.jpg?w=500&auto=format', 'https://i.seadn.io/gae/svc_rQkHVGf3aMI14v3pN-ZTI7uDRwN-QayvixX-nHSMZBgb1L1LReSg1-rXj4gNLJgAB0-yD8ERoT-Q2Gu4cy5AuSg-RdHF9bOxFDw?w=500&auto=format', 10000, 3865, false, true, 41, 243, 858, 78815, '46.43%', '10.96%', '-74.68%', 115.515, 691.9923, 2538.2969, 382645.8497, 2.91, 2.8174, 2.8477, 0, 4.855, '-4.76%', '-3.81%', '-24.99%', '39.46%', '6.73%', '-81%', 28548),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x60e4d786628fea6478f785a6d7e704777c86a7c6', 'MutantApeYachtClub', 'MAYC', 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?w=500&auto=format', 'https://i.seadn.io/gae/5c-HcdLMinTg3LvEwXYZYC-u5nN22Pn5ivTPYA4pVEsWJHU1rCobhUlHSFjZgCHPGSmcGMQGCrDCQU8BfSfygmL7Uol9MRQZt6-gqA?w=500&auto=format', 19550, 11785, false, true, 29, 341, 1073, 158025, '26.09%', '18.82%', '-29.31%', 80.2919, 885.6167, 2713.5559, 1372330.368, 2.47, 2.7687, 2.5971, 0, 8.6843, '9.46%', '0.57%', '16.13%', '38.01%', '19.5%', '-17.91%', 50092.965),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xed5af388653567af2f388e6224dc7c4b3241c544', 'Azuki', 'AZUKI', 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xed5af388653567af2f388e6224dc7c4b3241c544.png', 10000, 4201, false, true, 15, 181, 627, 108624, '-70%', '32.12%', '-69.34%', 42.0639, 541.2303, 1908.1831, 1008218.3014, 2.5888, 2.8043, 2.9902, 0, 9.2817, '11.1%', '6.67%', '1.44%', '-66.67%', '40.93%', '-68.9%', 26963),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x1a3c1bf0bd66eb15cd4a61b76a20fb68609f97ef', 'Morph Black', 'BLACK', '', 'null', 3000, 1877, false, false, 44, 291, 1186, 1186, '-32.31%', '24.36%', '100%', 40.3134, 286.6593, 1141.7058, 1141.7058, 0.8784, 0.9162, 0.9851, 1.7, 0.9627, '-8.02%', '5.32%', '100%', '-37.74%', '30.98%', '100%', 2925),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x6339e5e072086621540d0362c4e3cea0d643e114', 'Opepen Edition', 'OPEPEN', 'https://i.seadn.io/gcs/files/b1c9ed2e584b4f6e418bf1ca15311844.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x6339e5e072086621540d0362c4e3cea0d643e114/22896054:about:media:3e0e24fd-ac54-47b6-aad2-99b0bbe8218b.jpeg?w=500&auto=format', 16000, 3692, false, true, 42, 283, 1060, 197857, '-48.78%', '43.65%', '64.85%', 33.1562, 169.0426, 476.7699, 87476.7312, 0.239, 0.7894, 0.5973, 0, 0.4421, '14.47%', '41.54%', '55.16%', '-41.36%', '103.34%', '155.8%', 8574.4),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xb8ea78fcacef50d41375e44e6814ebba36bb33c4', 'Good Vibes Club', 'GVC', '', 'null', 6969, 2194, false, false, 80, 490, 6252, 9005, '25%', '-11.71%', '127.02%', 25.841, 167.4767, 2724.2064, 3172.2914, 0.255, 0.323, 0.3418, 0.0894, 0.3523, '-25.27%', '-7.57%', '167.63%', '-6.58%', '-18.4%', '507.64%', 2446.119),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x769272677fab02575e84945f03eca517acc544cc', 'Captainz', 'Captainz', 'https://i.seadn.io/gcs/files/6df4d75778066bce740050615bc84e21.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 3307, false, true, 30, 151, 1043, 31292, '25%', '-40.32%', '-33.44%', 24.4453, 106.6386, 820.2239, 139844.9822, 0.649, 0.8148, 0.7062, 0, 4.469, '8.99%', '-2.99%', '-27.23%', '36.24%', '-42.1%', '-51.57%', 6965.3034),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x5af0d9827e0c53e4799bb226655a1de152a425a5', 'Milady', 'MIL', 'https://i.seadn.io/gae/a_frplnavZA9g4vN3SexO5rrtaBX_cBTaJYcgrPtwQIqPhzgzUendQxiwUdr51CGPE2QyPEa1DHnkW1wLrHAv5DgfC3BP-CWpFq6BA?w=500&auto=format', 'https://i.seadn.io/gae/1TtiQPPiqoc6hqMw3xVYnlEatEi6QhRQGDQA3B3yZfhr2nuXbedAQCOcTs1UZot6-4FXSiYM6xOtHWcaJNwFdRyuOlC_q5erFRbMYA?w=500&auto=format', 10000, 5316, false, true, 8, 169, 565, 78417, '-63.64%', '-0.59%', '-67.34%', 24.219, 527.8748, 1829.1515, 198948.7077, 3.1888, 3.0274, 3.1235, 0, 2.5371, '-17.61%', '5.59%', '-18.12%', '-70.04%', '4.97%', '-73.26%', 30578),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xbc37ee54f066e79c23389c55925f877f79f3cb84', 'Seeing Signs', '$IGN', 'https://i.seadn.io/s/raw/files/492e1e9573fe567735cf676364772570.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xbc37ee54f066e79c23389c55925f877f79f3cb84/34209058:about:media:332ab073-cc74-4098-a1cc-95c6109ed5cb.png?w=500&auto=format', 2025, 1314, false, false, 11, 115, 350, 835, '175%', '51.32%', '68.27%', 18.406, 210.6045, 719.186, 1456.6965, 2.098, 1.6733, 1.8313, 0.4, 1.7445, '-20.79%', '-1.62%', '-10.89%', '117.82%', '48.87%', '49.95%', 3601.8675),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xc143bbfcdbdbed6d454803804752a064a622c1f3', 'Async Blueprints', 'ASYNC-BLUEPRINT', 'https://i.seadn.io/gcs/files/d6fb878fdeebeff1518276539a2a8356.png?w=500&auto=format', 'https://i.seadn.io/gae/s-1NTQmqAWvx8wmLfPxnNba6FX3dsLMGe6-YCdcjGZQND0VkwYZtYA3TwyddRLBZzEULclDc8OctXs1jSKF2dejXYdiujiAmiJac?w=500&auto=format', 21481, 6470, false, true, 2, 18, 45, 6688, '100%', '260%', '25%', 16.6782, 135.8489, 256.8124, 11361.6626, 16.99, 8.3391, 7.5472, 0, 1.6988, '100%', '-40.6%', '9.68%', '100%', '113.83%', '37.11%', 173800.6229),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xb6a37b5d14d502c3ab0ae6f3a0e058bc9517786e', ',Azuki Elementals', 'ELEM', 'https://i.seadn.io/gcs/files/bbaf43ee4a02d5affb7e8fc186d0bdb5.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/79bc14c2aae31bcbfd428662e27541ad.jpg?w=500&auto=format', 17605, 6400, false, true, 47, 356, 2096, 94377, '-2.08%', '24.48%', '-58.99%', 16.6095, 118.4405, 671.8979, 78354.9892, 0.2525, 0.3534, 0.3327, 0, 0.8302, '-10.3%', '-1.01%', '-2.02%', '-12.16%', '23.21%', '-59.82%', 5781.482),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x3696cd00618a08c8793208385ae526677c889d4a', '.MAX PAIN AND FRENS OPEN EDITION BURNS BY XCOPY', 'MAXPAINANDFRENSOPENEDITIONBURNSBYXCOPY', 'https://i.seadn.io/s/raw/files/8ca9eb1a40c8f193ccb8fecabad09e45.gif?w=500&auto=format', 'https://i.seadn.io/gae/Q8NGS6NQOkObTZSeny1_fHahcxTUrowHZaj-ixH6k_0O111LGmBCwEaED8RyzqJgyalKFYK8ryLGX4xFJ4BDy7fKZY5G5YuxpEr_vA?w=500&auto=format', 77, 68, false, true, 1, 2, 4, 71, '100%', '100%', '300%', 15, 30, 48.04, 710.5254, 0.875, 15, 15, 0, 10.0074, '100%', '100%', '50.13%', '100%', '100%', '500.5%', 1155),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xb5af0c7f3885c1007e6699c357566610291585cb', 'Infinex Patrons', 'XPATRON', 'https://img.reservoir.tools/images/v2/mainnet/UCFGvQe5gAa2nbht56deXQy%2B4jSaP%2Fpbks%2F%2FiDwcJVkscsHsroj5cuCcmb4dn9YN1rbJ3CxbrambngSnETl3O%2FPY2AEFwmDdDozfNVOQmO0%2FoDHqReD7YtEaf0HCzfFB5BDk85D7nzpcvDA%2Bt7cIWT7La5yMONAgcSO5RKlqSNk%3D?width=250', 'null', 100000, 762, false, false, 6, 31, 135, 1985, '500%', '-34.04%', '-55%', 13.7599, 71.1919, 331.147, 2820.1795, 2.44, 2.2933, 2.2965, 1.36, 1.4207, '2.38%', '-1.71%', '20.54%', '514.28%', '-35.17%', '-45.76%', 223870),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x33fd426905f149f8376e227d0c9d3340aad17af1', 'The Memes by 6529', '', 'https://i.seadn.io/gcs/files/8573c42207ea4d7dc1bb6ed5c0b01243.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/422be663d7ec0bf67cbe6c2d6484f32c.jpg?w=500&auto=format', 347, 10193, false, true, 87, 771, 5441, 79393, '-68.71%', '66.88%', '507.25%', 13.3254, 160.5701, 727.7914, 25045.9955, 0.0568, 0.1532, 0.2083, 0, 0.3155, '-8.76%', '-11.1%', '51.87%', '-71.45%', '48.34%', '821.5%', 73.8416),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270', 'Art Blocks', 'BLOCKS', 'https://i.seadn.io/gcs/files/fd5e8fa6bb4e39cddcdb4c9a0b685c5e.png?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270.png', 198051, 38001, false, true, 15, 178, 761, 234010, '-54.55%', '15.58%', '-13.33%', 13.042, 137.9983, 481.235, 446011.8065, 0.2252, 0.8695, 0.7753, 0, 1.906, '521.52%', '122.09%', '-9.76%', '182.4%', '156.66%', '-21.79%', 133585.3995),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x9378368ba6b85c1fba5b131b530f5f5bedf21a18', 'VeeFriends Series 2', 'VF2', 'https://i.seadn.io/s/raw/files/7c968bade1414b10fb5fd77d7c82e565.jpg?w=500&auto=format', 'https://i.seadn.io/gae/l7-Zz6ZYWJBu4kkFBxnHchfzg3uJlwmCZsfJt7QMJuiX1v7SQgUp-PveFFPi-Zd8J4m0ROQsGFgDcs96OXZu7JOIqC60kzTu7sQGAA?w=500&auto=format', 55555, 20108, false, true, 84, 367, 1144, 51985, '100%', '13.62%', '119.16%', 11.0818, 44.3324, 135.2013, 35258.633, 0.094, 0.1319, 0.1208, 0, 0.6782, '29.06%', '7.76%', '1.03%', '158.2%', '22.44%', '121.4%', 6394.3805),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x9830b32f7210f0857a859c2a86387e4d1bb760b8', 'Kaito Genesis', 'KAITO', 'https://i.seadn.io/s/raw/files/94bdb2f6224f8508183610037489c3af.png?auto=format&dpr=1&w=48', 'null', 1500, 843, false, false, 6, 82, 319, 4102, '-14.29%', '-8.89%', '-85.72%', 11.07, 144.3505, 618.1261, 18495.1865, 1.9, 1.845, 1.7604, 1.05, 4.5088, '2.01%', '2.08%', '-60.99%', '-12.56%', '-7%', '-94.43%', 2556.9),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xc374a204334d4edd4c6a62f0867c752d65e9579c', 'Project AEON', 'AEON', 'https://i.seadn.io/s/raw/files/5bfdfb6f0307ee8efa28bcba6b620c1e.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xc374a204334d4edd4c6a62f0867c752d65e9579c/31000665:about:media:3395fcca-5f9f-4b2e-aa09-54bc46b5fd1a.jpeg?w=500&auto=format', 3333, 1135, false, true, 12, 122, 426, 13787, '100%', '50.62%', '-24.2%', 10.7008, 114.5266, 268.3455, 5479.1814, 0.8999, 0.8917, 0.9387, 0, 0.3974, '100%', '87.74%', '24.41%', '100%', '182.77%', '-5.7%', 2828.3838),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xc7cc3e8c6b69dc272ccf64cbff4b7503cbf7c1c5', 'The Fungible by Pak', 'THEFUNGIBLEBYPAK', 'https://i.seadn.io/gae/ijC_URNi0k014Oqzfp2-1K73DUCfTcOTcm84ny_5pXeSUKMw3iUV-WSZU_5UZlVKiuA5BnFZGvvysoqvxQerQQMmizl5aDN3BGjtzw?w=500&auto=format', 'https://i.seadn.io/gae/04R95soeAPKXzrCMplv5W5eWJoFjGyHxgcRPvcY9msd5NSD0JUXEshWHstwBVi2By-MEVmO577ti9yDRDM13Vyl1cebVJkzUFYQq5hw?w=500&auto=format', 137, 87, false, true, 1, 2, 4, 38, '100%', '100%', '100%', 10.24, 12.24, 15.73, 188.9137, 2.6, 10.24, 6.12, 0, 4.9714, '100%', '100%', '222.34%', '100%', '100%', '544.67%', 838.44),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xd32cb5f76989a27782e44c5297aaba728ad61669', 'HyPC License', 'HyPCL', '', '', 12988, 326, false, false, 28, 81, 173, 1854, '47.37%', '268.18%', '-0.57%', 10.0765, 39.7305, 103.0332, 1055.6609, 0.32, 0.3599, 0.4905, 0.0463, 0.5694, '50.52%', '-43.5%', '8.17%', '121.84%', '108%', '7.54%', 0),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x3e34ff1790bf0a13efd7d77e75870cb525687338', 'DAMAGE CONTROL', 'DAMGE', 'https://i.seadn.io/s/raw/files/2a03698df217570b09de93dd3e0a2d43.gif?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x3e34ff1790bf0a13efd7d77e75870cb525687338/31228811:about:media:bf571909-6758-422f-80a0-58c5c40c8000.gif?w=500&auto=format', 10, 917, false, true, 7, 41, 81, 1525, '-46.15%', '86.36%', '62%', 9.6819, 56.2, 96.4749, 1268.217, 1.1979, 1.3831, 1.3707, 0, 0.8316, '-18.56%', '23.34%', '57.35%', '-56.15%', '129.88%', '154.92%', 13.623),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xc73b17179bf0c59cd5860bb25247d1d1092c1088', 'QQL Mint Pass', 'QQL-MP', 'https://i.seadn.io/gcs/files/820d3d4f318f9140c251081d324beaa2.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/a365957dc0e1d73accd8fdbbeae20881.png?w=500&auto=format', 999, 312, false, true, 6, 9, 13, 1157, '500%', '200%', '550%', 9.58, 13.83, 19.03, 11705.9331, 1.99, 1.5967, 1.5367, 0, 10.1175, '27.74%', '13.83%', '8.43%', '666.4%', '241.48%', '604.84%', 1535.1633),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xf39c410dac956ba98004f411e182fb4eed595270', 'One Gravity', 'OG', 'https://img.reservoir.tools/images/v2/mainnet/z9JRSpLYGu7%2BCZoKWtAuAGWMlxciEQCESPKStAj21DrxmGRXVKBW53eDAIqeQW8VlJb%2F2W8cSquGEy1cJilpJZE4uxiHbqxVkW4AbdQxUyY82DFt3UMPiZrddBh9RV%2Byij%2BiZHg40O4YBj7vns7tc%2BecRMgLM980PG7yuczoL1O%2B3o5eMGviJVZf3VNQnxO0xMndFLrcLciQO9ZSK46XZA%3D%3D?width=250', '', 1888, 1311, false, false, 6, 55, 374, 1034, '20%', '-29.49%', '-43.33%', 9.498, 87.8729, 494.9859, 1365.2964, 1.635, 1.583, 1.5977, 1.152, 1.3204, '2.66%', '11.55%', '0.36%', '23.19%', '-21.34%', '-43.13%', 2928.6656),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0xe41af8c3f0decf206c3afb9dbf2e7643f349e0b9', 'CambriaFounders', 'CFDR', 'https://i.nfte.ai/ca/i1/8157192.avif', 'null', 1500, 959, false, false, 11, 75, 175, 1399, '37.5%', '38.89%', '62.04%', 8.8604, 58.2404, 124.8072, 613.2963, 0.83, 0.8055, 0.7765, 0.235, 0.4384, '5.03%', '6.56%', '20.29%', '44.42%', '48.01%', '94.91%', 1156.8),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x25e6cfd042294a716ff60603ca01e92555ca9426', 'unused_1', '5', 'https://i.seadn.io/s/raw/files/46cd383e47b2badd7d118d340d5450e4.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x25e6cfd042294a716ff60603ca01e92555ca9426/29811651:about:media:48bc6056-2546-4635-9e2b-7e92c7b8b3fd.jpeg?w=500&auto=format', 9966, 2142, false, true, 2, 4, 89, 11483, '0%', '-80.95%', '-73.67%', 8.746, 9.043, 9.7489, 317.3762, 0.0041, 4.373, 2.2608, 0.025, 0.0276, '2,844.78%', '55,041.46%', '2,507.14%', '2,844.78%', '10,282.32%', '587.41%', 11279.5188),(CAST('2025-04-15 14:15:47' AS TIMESTAMP), '0x74f70713b0515e9f520d6c764352e45e227839b7', 'MetaWinners', 'MW', 'https://img.reservoir.tools/images/v2/mainnet/hc%2BnPcLmWxs%2FDW99DlBQ42k40ZoyYV5jCIms5qHjwvsJTzlw%2FEFEd9KxuktyBPBp0Vqi4oS1gxRDZeVfjbzp0HPiz1a56Ru0TJjr8abEKQX9co15SUMJIHfzghqi0tQrJUD1sdlwa3ZuIue8IL768Je44sKwlx7DhAJ0RfUJY2jTkV909NZzpMfbbR8n%2FN3bCaJEBSIM4LTlSHHWwHws3T6U0c56KUlKy3Liest1962DGTzb1GuFM4FsJG9xYvVKfWZqwHhKDo4p4lMNh35ChA%3D%3D.gif?width=250', '', 10000, 1447, false, false, 47, 358, 1534, 17545, '-2.08%', '0.85%', '-31.61%', 7.5914, 59.0634, 247.0722, 1893.4039, 0.1325, 0.1615, 0.165, 0.14, 0.1079, '-7.29%', '4.17%', '0.12%', '-9.22%', '5.04%', '-31.53%', 1629)
;
