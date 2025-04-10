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
(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb', 'CryptoPunks', 'PUNK', 'https://i.seadn.io/gae/BdxvLseXcfl57BiuQcQYdJ64v-aI8din7WPk0Pgo3qQFhAUH-B6i-dCqqc_mCkRIzULmwzwecnohLhrcH8A9mpWIZqA7ygc52Sr81hE?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb/2563:about:media:70594573-20b8-4f3d-b535-716084978052.png?w=500&auto=format', 10000, 3862, false, true, 8, 34, 159, 26316, '-20%', '9.68%', '72.83%', 473.61, 1710.4049, 8007.5073, 1297492.4453, 42.5, 59.2013, 50.306, 0, 49.3043, '27.07%', '-7.55%', '-12.23%', '1.66%', '1.39%', '51.7%', 525077),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d', 'BoredApeYachtClub', 'BAYC', 'https://i.seadn.io/gae/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB?auto=format&dpr=1&w=256', 'https://i.seadn.io/gae/i5dYZRkVCUK97bfprQ3WXyrT9BnLSZtVKGJlKQ919uaUB0sxbngVCioaiyu9r6snqfi2aaTyIvv6DHm4m2R3y7hMajbsv14pSZK8mhs?auto=format&dpr=1&w=2048', 10000, 5444, false, true, 17, 123, 390, 62491, '-19.05%', '61.84%', '-14.1%', 239.0257, 1904.0706, 5586.9211, 1955449.7778, 13.85, 14.0603, 15.4802, 0, 31.2917, '-8.68%', '4.23%', '5.52%', '-26.07%', '68.69%', '-9.35%', 153968),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xbd3531da5cf5857e7cfaa92426877b022e612cf8', 'PudgyPenguins', 'PPG', 'https://i.seadn.io/gae/yNi-XdGxsgQCPpqSio4o31ygAV6wURdIdInWRcFIl46UjUQ1eV7BEndGe8L661OoG-clRi7EgInLX4LPu9Jfw4fq0bnVYHqg7RFi?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xbd3531da5cf5857e7cfaa92426877b022e612cf8.png', 8888, 4972, false, true, 21, 170, 672, 94322, '75%', '11.11%', '-61.27%', 223.6357, 1629.029, 6475.8516, 543889.568, 9.249, 10.6493, 9.5825, 0, 5.7663, '18.95%', '-5.93%', '1.89%', '108.17%', '4.52%', '-60.54%', 86522.9024),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x8a90cab2b38dba80c64b7734e58ee1db38b8992e', 'Doodles', 'DOODLE', 'https://i.seadn.io/s/raw/files/e663a85a2900fdd4bfe8f34a444b72d3.jpg?w=500&auto=format', 'https://i.seadn.io/gae/svc_rQkHVGf3aMI14v3pN-ZTI7uDRwN-QayvixX-nHSMZBgb1L1LReSg1-rXj4gNLJgAB0-yD8ERoT-Q2Gu4cy5AuSg-RdHF9bOxFDw?w=500&auto=format', 10000, 3869, false, true, 50, 245, 869, 78674, '19.05%', '-12.5%', '-75.44%', 138.9356, 691.0157, 2541.9257, 382228.0662, 2.799, 2.7787, 2.8205, 0, 4.8584, '5.81%', '-5.26%', '-26.91%', '25.97%', '-17.11%', '-82.05%', 28796),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x60e4d786628fea6478f785a6d7e704777c86a7c6', 'MutantApeYachtClub', 'MAYC', 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?w=500&auto=format', 'https://i.seadn.io/gae/5c-HcdLMinTg3LvEwXYZYC-u5nN22Pn5ivTPYA4pVEsWJHU1rCobhUlHSFjZgCHPGSmcGMQGCrDCQU8BfSfygmL7Uol9MRQZt6-gqA?w=500&auto=format', 19550, 11763, false, true, 49, 319, 1033, 157823, '-33.78%', '29.67%', '-35.07%', 118.242, 799.484, 2541.6597, 1371791.9342, 2.35, 2.4131, 2.5062, 0, 8.692, '-3.65%', '-3.99%', '12.55%', '-36.2%', '24.5%', '-26.92%', 49911.15),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x5af0d9827e0c53e4799bb226655a1de152a425a5', 'Milady', 'MIL', 'https://i.seadn.io/gae/a_frplnavZA9g4vN3SexO5rrtaBX_cBTaJYcgrPtwQIqPhzgzUendQxiwUdr51CGPE2QyPEa1DHnkW1wLrHAv5DgfC3BP-CWpFq6BA?w=500&auto=format', 'https://i.seadn.io/gae/1TtiQPPiqoc6hqMw3xVYnlEatEi6QhRQGDQA3B3yZfhr2nuXbedAQCOcTs1UZot6-4FXSiYM6xOtHWcaJNwFdRyuOlC_q5erFRbMYA?w=500&auto=format', 10000, 5316, false, true, 33, 194, 660, 78317, '26.92%', '76.36%', '-62.13%', 102.459, 575.5574, 2143.4602, 198632.4177, 3.2, 3.1048, 2.9668, 0, 2.5363, '3.63%', '-10.88%', '-19.98%', '31.53%', '57.17%', '-69.7%', 30508),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x524cab2ec69124574082676e6f654a18df49a048', 'Lil Pudgys', 'LP', 'https://i.seadn.io/s/raw/files/649289b91d3d0cefccfe6b9c7f83f471.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x524cab2ec69124574082676e6f654a18df49a048/3826365:about:media:6efd80cc-0c7c-4233-83d4-5375c60f89eb.png?w=500&auto=format', 21905, 9850, false, true, 82, 453, 2142, 156657, '-11.83%', '28.33%', '-61.09%', 87.6926, 494.4035, 2407.681, 134954.4981, 1.0697, 1.0694, 1.0914, 0, 0.8615, '-0.86%', '-10.88%', '11.2%', '-12.59%', '14.36%', '-56.73%', 24559.886),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xed5af388653567af2f388e6224dc7c4b3241c544', 'Azuki', 'AZUKI', 'https://i.seadn.io/gae/H8jOCJuQokNqGBpkBN5wk1oZwO7LM8bNnrHCaekV2nKjnCqw6UB5oaH8XyNeBDj6bA_n1mjejzhFQUP3O1NfjFLHr3FOaeHcTOOT?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xed5af388653567af2f388e6224dc7c4b3241c544.png', 10000, 4196, false, true, 24, 134, 684, 108498, '0%', '6.35%', '-71.76%', 61.006, 374.6083, 1974.8247, 1007821.737, 2.52, 2.5419, 2.7956, 0, 9.2889, '-8.37%', '-7.53%', '-8.33%', '-8.37%', '-1.66%', '-74.11%', 28347),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x9830b32f7210f0857a859c2a86387e4d1bb760b8', 'Kaito Genesis', 'KAITO', 'https://i.seadn.io/s/raw/files/94bdb2f6224f8508183610037489c3af.png?auto=format&dpr=1&w=48', 'null', 1500, 843, false, false, 19, 116, 373, 4062, '-13.64%', '114.81%', '-83.36%', 35.2957, 197.4885, 734.2994, 18424.1621, 1.905, 1.8577, 1.7025, 1.05, 4.5357, '12.19%', '-23.47%', '-62.07%', '-3.11%', '64.4%', '-93.69%', 2638.35),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xc143bbfcdbdbed6d454803804752a064a622c1f3', 'Async Blueprints', 'ASYNC-BLUEPRINT', 'https://i.seadn.io/gcs/files/d6fb878fdeebeff1518276539a2a8356.png?w=500&auto=format', 'https://i.seadn.io/gae/s-1NTQmqAWvx8wmLfPxnNba6FX3dsLMGe6-YCdcjGZQND0VkwYZtYA3TwyddRLBZzEULclDc8OctXs1jSKF2dejXYdiujiAmiJac?w=500&auto=format', 21481, 6470, false, true, 10, 17, 45, 6682, '233.33%', '466.67%', '9.76%', 31.937, 145.117, 226.9117, 11319.8737, 16.99, 3.1937, 8.5363, 0, 1.6941, '-84.58%', '104.87%', '-6.84%', '-48.6%', '1,060.94%', '2.25%', 178187.0431),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xa3aee8bce55beea1951ef834b99f3ac60d1abeeb', 'VeeFriends', 'VFT', 'https://i.seadn.io/s/raw/files/7c968bade1414b10fb5fd77d7c82e565.jpg?w=500&auto=format', 'https://i.seadn.io/gae/4RYeNt3ET75VLMoCZz-fsOhXg8AW8qlkHfgkbA0FfEayNpsHvOZROygyy9IhY4LwrnJUXqkeDjBZBr8bCf0Ng_xUiRZqWRGng3sc?w=500&auto=format', 10255, 4782, false, true, 17, 109, 202, 10059, '0%', '194.59%', '28.66%', 29.379, 257.3747, 440.6296, 71289.3547, 1.66, 1.7282, 2.3612, 0, 7.0871, '-13.76%', '33.69%', '16.37%', '-13.76%', '293.84%', '49.73%', 22846.089),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x33fd426905f149f8376e227d0c9d3340aad17af1', 'The Memes by 6529', '', 'https://i.seadn.io/gcs/files/8573c42207ea4d7dc1bb6ed5c0b01243.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/422be663d7ec0bf67cbe6c2d6484f32c.jpg?w=500&auto=format', 346, 10206, false, true, 118, 488, 4980, 78797, '122.64%', '-28.65%', '483.82%', 26.0905, 124.9202, 632.2546, 24930.0473, 0.0639, 0.2211, 0.256, 0, 0.3164, '-33.74%', '56.86%', '67.33%', '47.5%', '11.88%', '876.28%', 78.8534),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xf39c410dac956ba98004f411e182fb4eed595270', 'One Gravity', 'OG', 'https://img.reservoir.tools/images/v2/mainnet/z9JRSpLYGu7%2BCZoKWtAuAGWMlxciEQCESPKStAj21DrxmGRXVKBW53eDAIqeQW8VlJb%2F2W8cSquGEy1cJilpJZE4uxiHbqxVkW4AbdQxUyY82DFt3UMPiZrddBh9RV%2Byij%2BiZHg40O4YBj7vns7tc%2BecRMgLM980PG7yuczoL1O%2B3o5eMGviJVZf3VNQnxO0xMndFLrcLciQO9ZSK46XZA%3D%3D?width=250', '', 1888, 1316, false, false, 16, 84, 1007, 1007, '60%', '21.74%', '100%', 26.018, 126.89, 1322.6835, 1322.6835, 1.989, 1.6261, 1.5106, 1.152, 1.3135, '-0.01%', '13.5%', '100%', '59.99%', '38.18%', '100%', 2788.1984),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x620b70123fb810f6c653da7644b5dd0b6312e4d8', 'Space Doodles', 'SDOODLE', 'https://i.seadn.io/gae/grtJLoHghmlq1Zh05DEc4S20t6_aESFq-nq07SyAsxDuOoRorjo1EQ9Z2L2Fb-LS7DgZt9Ar4Ra9l2KpBkSvvyu7wnVdhLkHcNFtQ8c?w=500&auto=format', 'https://i.seadn.io/gae/OtLzNR8meEExqjYpUKueXegelvgIifMchL7FUwFa_NtryDVtdVfi9Zvvv9ppz7weoUpNEaJuI-ZrqOl0WWCqpBp1CPk_huCpMvDgptE?w=500&auto=format', 7433, 1801, false, true, 8, 20, 43, 483, '300%', '17.65%', '10.26%', 25.3349, 61.2139, 214.6139, 3447.1204, 2.82, 3.1669, 3.0607, 0, 7.1369, '24.68%', '-61.94%', '20.76%', '398.72%', '-55.23%', '33.14%', 40865.1474),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xbc37ee54f066e79c23389c55925f877f79f3cb84', 'Seeing Signs', '$IGN', 'https://i.seadn.io/s/raw/files/492e1e9573fe567735cf676364772570.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xbc37ee54f066e79c23389c55925f877f79f3cb84/34209058:about:media:332ab073-cc74-4098-a1cc-95c6109ed5cb.png?w=500&auto=format', 2025, 1338, false, false, 15, 93, 304, 761, '-28.57%', '-4.12%', '36.94%', 23.229, 155.708, 641.4371, 1313.56, 1.85, 1.5486, 1.6743, 0.4, 1.7261, '-9.33%', '-25.01%', '-1.36%', '-35.24%', '-28.1%', '35.07%', 3798.6975),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xfbeef911dc5821886e1dda71586d90ed28174b7d', 'KnownOriginDigitalAsset', 'KODA', 'https://i.seadn.io/gae/53L422-5QSOKOaWTu3-EWZkymYoyFo6L60AnxPXqz4rNgX1-E162tIljSyVOa3hyVACvJNGdih4lFummnHPx-1Fa?w=500&auto=format', 'https://i.seadn.io/gcs/files/b3a9febaf13bc460f6231550b90b4375.jpg?w=500&auto=format', 27798, 6893, false, true, 1, 9, 48, 3855, '0%', '350%', '140%', 23, 93.6615, 195.0345, 8206.6893, 0.015, 23, 10.4068, 0, 2.1288, '416.85%', '135,053.25%', '-1.76%', '416.85%', '608,091.56%', '135.78%', 260386.6458),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x769272677fab02575e84945f03eca517acc544cc', 'Captainz', 'Captainz', 'https://i.seadn.io/gcs/files/6df4d75778066bce740050615bc84e21.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 3313, false, true, 33, 240, 1133, 31202, '50%', '-2.83%', '-26.33%', 22.0965, 166.2986, 899.4554, 139779.0816, 0.625, 0.6696, 0.6929, 0, 4.4798, '-2.15%', '-14.51%', '-31.5%', '46.79%', '-16.93%', '-49.54%', 7181.2818),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xb8ea78fcacef50d41375e44e6814ebba36bb33c4', 'Good Vibes Club', 'GVC', '', 'null', 6953, 2222, false, false, 62, 506, 8648, 8648, '19.23%', '-42.57%', '100%', 21.9368, 176.7016, 3048.4378, 3048.4378, 0.249, 0.3538, 0.3492, 0.0894, 0.3525, '12%', '-17.68%', '100%', '33.55%', '-52.72%', '100%', 2540.6262),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xb6a37b5d14d502c3ab0ae6f3a0e058bc9517786e', ',Azuki Elementals', 'ELEM', 'https://i.seadn.io/gcs/files/bbaf43ee4a02d5affb7e8fc186d0bdb5.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/79bc14c2aae31bcbfd428662e27541ad.jpg?w=500&auto=format', 17605, 6393, false, true, 76, 352, 2336, 94156, '55.1%', '-54.93%', '-63.55%', 21.6174, 113.7616, 798.0836, 78276.179, 0.238, 0.2844, 0.3232, 0, 0.8313, '-9.17%', '9.34%', '7.02%', '40.89%', '-50.73%', '-60.98%', 5665.289),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x59325733eb952a92e069c87f0a6168b29e80627f', 'Mocaverse', 'MOCA', 'https://i.seadn.io/gcs/files/6a0b776c9bb3973d1dd8d399353da9f5.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/20e81e38bb831b47e23b7ea0e13c6891.png?w=500&auto=format', 8888, 2286, false, true, 12, 66, 191, 15311, '33.33%', '120%', '-28.2%', 21.2883, 116.4786, 379.0156, 30245.3117, 1.98, 1.774, 1.7648, 0, 1.9754, '-8.44%', '-26.43%', '-1.1%', '22.08%', '61.86%', '-28.98%', 15611.772),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xdd012153e008346591153fff28b0dd6724f0c256', 'BEEPLE - SPRING/SUMMER COLLECTION 2021', 'BEEPLESPRINGCOLLECTION', 'https://i.seadn.io/gae/N7GezCIhjCnlzyklOSmlXGrWt5M3qpGTMGj17Vf-q0G0e7ivRYSzrKHUuhvSdp1OlTWeHR3d21hQhScm1_vS1aE9F_KglouuH70wdg?w=500&auto=format', 'https://i.seadn.io/gae/wRO8pzpo42PxJZQKkhvWPgyEpr0QkCrKnQC3rv5KdoxYt5e1yGv_U1P5A_iwWYzs9peXhZfg0DXmzAMcsd0ycCnfw9ZZkj19l-APKAo?w=500&auto=format', 511, 246, false, true, 2, 5, 6, 266, '100%', '100%', '100%', 17.5, 54.99, 61.89, 2860.9828, 7.77, 8.75, 10.998, 0, 10.7556, '25%', '100%', '-18.09%', '150%', '100%', '63.82%', 5619.978),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270', 'Art Blocks', 'BLOCKS', 'https://i.seadn.io/gcs/files/fd5e8fa6bb4e39cddcdb4c9a0b685c5e.png?auto=format&dpr=1&w=256', 'https://image.nftscan.com/eth/banner/0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270.png', 198051, 37998, false, true, 28, 172, 820, 233888, '12%', '56.36%', '6.91%', 16.4101, 89.9035, 490.7344, 445917.2025, 0.0288, 0.5861, 0.5227, 0, 1.9065, '-45.16%', '59.46%', '-16.21%', '-38.58%', '149.34%', '-10.43%', 96272.5911),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x1a3c1bf0bd66eb15cd4a61b76a20fb68609f97ef', 'Morph Black', 'BLACK', '', 'null', 3000, 2876, false, false, 16, 121, 939, 939, '-20%', '-85.21%', '100%', 15.4193, 114.7065, 895.464, 895.464, 0.987, 0.9637, 0.948, 1.7, 0.9536, '8.31%', '-0.68%', '100%', '-13.36%', '-85.31%', '100%', 2743.2),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xd3d9ddd0cf0a5f0bfb8f7fceae075df687eaebab', 'Redacted Remilio Babies', 'TEST', 'https://i.seadn.io/gcs/files/9d6168e731afd02d5e878eb03876cfd4.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/f80f846ee3f0ce3c83fad5bdc25e3fb2.jpg?w=500&auto=format', 10000, 4268, false, true, 25, 174, 678, 67006, '92.31%', '38.1%', '-62.33%', 15.0235, 101.5765, 410.175, 53960.5075, 0.5228, 0.6009, 0.5838, 0, 0.8053, '18.24%', '-5.79%', '-22.85%', '127.38%', '30.09%', '-70.94%', 5903),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xd887090fc6f9af10abe6cf287ac8011a3cb55a65', 'Quills Adventure', 'QA', '', 'null', 3333, 2500, false, false, 53, 373, 1506, 1506, '60.61%', '-67.08%', '100%', 14.3762, 85.16, 378.9667, 378.9667, 0.3, 0.2712, 0.2283, 0.2986, 0.2516, '7.88%', '-11.96%', '100%', '73.28%', '-71.01%', '100%', 754.9245),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xe6313d1776e4043d906d5b7221be70cf470f5e87', 'OnChainShiba', 'OCS', 'https://i.seadn.io/gcs/files/b77fda6a546e61cfddd84da43bb73d61.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/78c488d0b36686c15fa232a9b9bb9050.png?w=500&auto=format', 3000, 568, false, false, 1, 8, 98, 1324, '-66.67%', '-52.94%', '42.03%', 14.32, 62.17, 1021.1006, 6933.6256, 0.0996, 14.32, 7.7713, 0, 5.2369, '592.89%', '-60.35%', '34.79%', '130.97%', '-81.34%', '91.44%', 33561.6),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xfdf5acd92840e796955736b1bb9cc832740744ba', 'OVERWORLD INCARNA', 'INCARNA', 'https://i.seadn.io/s/raw/files/d67e16753135e677c05077781003de5b.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xfdf5acd92840e796955736b1bb9cc832740744ba/31240882:about:media:6e285846-35ec-4781-9a66-dd8f3b294768.jpeg?w=500&auto=format', 6000, 1326, false, true, 115, 173, 539, 12015, '1,816.67%', '22.7%', '23.06%', 13.9043, 22.9137, 71.2056, 12373.3437, 0.1049, 0.1209, 0.1324, 0, 1.0298, '-8.96%', '-7.99%', '33.84%', '1,644.8%', '12.95%', '64.79%', 823.2),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x7fb2d396a3cc840f2c4213f044566ed400159b40', 'Jirasan', 'JIRASAN', 'https://i.nfte.ai/ca/i1/8006297.avif', 'null', 10000, 2358, false, false, 47, 203, 965, 11280, '62.07%', '1.5%', '-54.27%', 13.8995, 55.9899, 321.3768, 6129.8619, 0.3089, 0.2957, 0.2758, 0.3, 0.5434, '5.46%', '-7.08%', '-23.66%', '70.94%', '-5.69%', '-65.09%', 2813),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0xb5af0c7f3885c1007e6699c357566610291585cb', 'Infinex Patrons', 'XPATRON', 'https://img.reservoir.tools/images/v2/mainnet/UCFGvQe5gAa2nbht56deXQy%2B4jSaP%2Fpbks%2F%2FiDwcJVkscsHsroj5cuCcmb4dn9YN1rbJ3CxbrambngSnETl3O%2FPY2AEFwmDdDozfNVOQmO0%2FoDHqReD7YtEaf0HCzfFB5BDk85D7nzpcvDA%2Bt7cIWT7La5yMONAgcSO5RKlqSNk%3D?width=250', 'null', 100000, 768, false, false, 6, 55, 155, 1971, '-25%', '150%', '-51.71%', 13.62, 126.586, 388.5339, 2788.2296, 2.44, 2.27, 2.3016, 1.36, 1.4146, '-5.67%', '-5.42%', '31%', '-29.25%', '136.45%', '-36.74%', 233470),(CAST('2025-04-10 15:25:38' AS TIMESTAMP), '0x790b2cf29ed4f310bf7641f013c65d4560d28371', 'Otherdeed Expanded', 'EXP', 'https://i.seadn.io/gcs/files/9583ab4792a83cd81d5075b59514a34a.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/6b321a0d888251dfb2608481c7498160.png?w=500&auto=format', 55347, 12564, false, true, 59, 468, 1424, 34570, '-31.4%', '50.48%', '15.3%', 13.4643, 105.6159, 363.897, 23596.6967, 0.1717, 0.2282, 0.2257, 0, 0.6826, '6.69%', '-31.77%', '30.29%', '-26.81%', '2.67%', '50.28%', 14179.9014)
;
