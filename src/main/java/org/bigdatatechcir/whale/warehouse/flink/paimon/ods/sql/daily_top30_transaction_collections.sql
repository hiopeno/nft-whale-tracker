-- 当天交易数Top30收藏集数据

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


-- 当天交易数Top30收藏集
CREATE TABLE IF NOT EXISTS ods_daily_top30_transaction_collections (
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
INSERT INTO ods_daily_top30_transaction_collections (
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
(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xb8ea78fcacef50d41375e44e6814ebba36bb33c4', 'Good Vibes Club', 'GVC', 'https://i.seadn.io/s/raw/files/8ba2b8fe4048f4e6ea170550ca27a2f7.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xb8ea78fcacef50d41375e44e6814ebba36bb33c4/34487095:about:media:a8b9eeef-2abb-416b-8013-bdf34aefcc87.jpeg?w=500&auto=format', 6969, 2131, false, true, 212, 727, 3615, 9178, '35.9%', '53.05%', '-39.51%', 92.456, 285.2829, 1422.9148, 3231.0276, 0.3869, 0.4361, 0.3924, 0.0894, 0.352, '11.14%', '14.8%', '18.7%', '51.02%', '75.72%', '-28.21%', 2409.1833),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xd4416b13d2b3a9abae7acd5d6c2bbdbe25686401', 'NameWrapper', '', 'https://i.seadn.io/gae/0cOqWoYA7xL9CkUjGlxsjreSYBdrUBE0c6EO1COG4XE8UeP-Z30ckqUNiL872zHQHQU5MUNMNhfDpyXIP17hRSC5HQ?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/3072:about:media:252af124-c94f-43a8-b81a-ab886564116f.png?w=500&auto=format', 573179, 425180, false, true, 148, 640, 3069, 16786, '16.54%', '-9.35%', '3.3%', 0.3037, 2.2707, 16.4452, 1871.4901, 0.0001, 0.0021, 0.0035, 0, 0.1115, '-34.38%', '-40.68%', '-50.91%', '-24.55%', '-45.79%', '-49.73%', 1776.8549),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xd5a66b87801b6b8f9bfe7e42db24cf9b7e2f30ef', 'Infinite Petals by Sarah Meyohas', 'MEYOHAS-IP', 'https://img.reservoir.tools/images/v2/mainnet/z9JRSpLYGu7%2BCZoKWtAuAI8ipNM7MJ1GQZfU57rB7lKla5A%2B5nD3dK0dPzmfUOL4fu13c%2B7QFzov4SlgvL0gQmiW8QEUM99BMMCcoRcEGzQN5Spyg%2Fd8%2BkEQ0KKTO3Spac%2Fy71V8BZhIlihcJtGgf%2BIs%2BBkHNwIlROyJbPenkAomr%2BS4SStPAwK3gTVNBYouEnUOfdK0jGDRJI5bQ4GrLw%3D%3D?width=250', 'https://img.reservoir.tools/images/v2/mainnet/M4eOe%2BWm03o9r1%2F%2BIQ0oM0tpc7YU6ht6kmebKTnInXYRXJlOzRyGKO%2B%2FPV3puZ1NBRSEfbSYeqQE2kcYFzTYFCGDN2bhSr2wo7he7nFLDRY%3D', 2772, 715, false, true, 129, 623, 623, 90, '-8.51%', '100%', '100%', 5.5514, 43.8303, 43.8303, 9.1818, 0.0472, 0.043, 0.0704, 0.05, 0.102, '-34.25%', '100%', '100%', '-39.78%', '100%', '100%', 279.588),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x7c98ef950dcb9d1cc035636aab4291a81711237a', 'MisfitsNFT', 'MISFITS', 'https://i.seadn.io/gae/MQjIf4Jj5xI6iKHKTzPa7bZzw2m6h_fuBqqNIBA7O88YKDN21-arT-Jd5lNNk4j_AoHvq3TBGyDz3PNQCi9sCRKE7mWRYqFZZWLAJw?w=500&auto=format', 'https://i.seadn.io/gae/stmApuibnYUNHmUyBuQdPlvTWpe9xbkLIgAsEBnpd0-Em8tSqKeHBwWiiF8kQhKe6q2Ned4yEXGFg7vc4bZBt9_BDKIkF7Qny50Khps?w=500&auto=format', 3352, 633, false, false, 116, 219, 279, 1339, '1,833.33%', '895.45%', '564.29%', 0.7897, 1.851, 2.9759, 31.0452, 0.0097, 0.0068, 0.0085, 0, 0.0232, '-57.76%', '-57.71%', '-30.07%', '716.65%', '319.16%', '363.32%', 62.6824),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x606e017d1fed04d7f540694eb4ce8e86a8ff1081', 'GOMBLE SpaceKids', 'GOMBLE SpaceKids', 'https://i.seadn.io/s/raw/files/09609731aea7697543a20fe96173d124.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x606e017d1fed04d7f540694eb4ce8e86a8ff1081/33403696:about:media:ba5f2a46-4ff1-46a9-9a5d-6c7c8bf315dd.png?w=500&auto=format', 5555, 162, false, false, 113, 180, 246, 5655, '151.11%', '1,536.36%', '219.48%', 1.1372, 2.9344, 8.105, 697.5529, 0.0101, 0.0101, 0.0163, 0.1555, 0.1234, '-46.56%', '-69.93%', '-65.48%', '33.38%', '392.43%', '10.43%', 291.082),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x66d97206d62c34e8f2ec7d98623bf2c9dd21af11', 'tarifftown', 'TARIFF', 'https://i.seadn.io/s/raw/files/f45f4bad046ae460f2e45ed3ba1d608e.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x66d97206d62c34e8f2ec7d98623bf2c9dd21af11/34717121:about:media:3d172b21-4b34-4e7a-a9c0-5732f783f0c3.png?w=500&auto=format', 10000, 1926, false, false, 106, 2640, 2640, 2483, '430%', '100%', '100%', 0.1325, 3.8133, 3.8133, 3.5417, 0.0012, 0.0013, 0.0014, 0.0001, 0.0014, '-27.78%', '100%', '100%', '276.42%', '100%', '100%', 14),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xe83dd605b70b47c8af86580bdd4fcb987ff36e60', 'BTFDRabbits', 'BTFD', 'https://i.seadn.io/s/raw/files/334937567b8fb4c7bd9fbcc8fe346c07.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xe83dd605b70b47c8af86580bdd4fcb987ff36e60/19613925:about:media:08b39c6a-dee2-4e97-9117-d970cd56ff22.gif?w=500&auto=format', 10000, 2218, false, true, 96, 241, 382, 19338, '209.68%', '330.36%', '158.11%', 0.8414, 2.6384, 4.683, 204.3654, 0.0108, 0.0088, 0.0109, 0, 0.0106, '-35.29%', '-44.95%', '16.04%', '99.53%', '137.93%', '198.19%', 198),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x4b15a9c28034dc83db40cd810001427d3bd7163d', 'HV-MTL', 'HV-MTL', 'https://i.seadn.io/gcs/files/82a7f92df6d60e41327b69cdafea8831.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/be397bd4615365ac3bcb5a13a3159b0b.gif?w=500&auto=format', 28378, 8489, false, true, 91, 505, 820, 39699, '-63.6%', '689.06%', '70.83%', 2.8797, 18.5605, 33.0895, 41769.4551, 0.0321, 0.0316, 0.0368, 0, 1.0522, '-20%', '-25.35%', '1%', '-70.88%', '488.59%', '72.35%', 1382.0086),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xb66a603f4cfe17e3d27b87a8bfcad319856518b8', 'Rarible', 'RARI', 'https://i.seadn.io/gae/FG0QJ00fN3c_FWuPeUr9-T__iQl63j9hn5d6svW8UqOmia5zp3lKHPkJuHcvhZ0f_Pd6P2COo9tt9zVUvdPxG_9BBw?w=500&auto=format', 'https://i.seadn.io/gcs/static/banners/rarible-banner4.png?w=500&auto=format', 16559, 26878, false, false, 83, 499, 1347, 28543, '118.42%', '87.59%', '496.02%', 0.0027, 0.2313, 2.4215, 6848.3913, 0, 0, 0.0005, 0, 0.2399, '-100%', '-58.33%', '-37.93%', '-73%', '-26.15%', '264.74%', 0),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x39ee2c7b3cb80254225884ca001f57118c8f21b6', 'Potatoz', 'Potatoz', 'https://i.seadn.io/gcs/files/129b97582f0071212ee7cf440644fc28.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 2432, false, true, 72, 171, 1006, 46481, '100%', '106.02%', '-24.76%', 18.3463, 42.1487, 245.095, 64208.9948, 0.273, 0.2548, 0.2465, 0, 1.3814, '-2.71%', '10.84%', '-22.98%', '94.57%', '128.35%', '-42.05%', 2249.775),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xfc483e27b2bb7d0df1e4a010b3b81bfb585fa2e1', 'PepeWizardsNFT', 'PWZRDS', 'https://i.seadn.io/gcs/files/e46a5a229935568021500ea7183922fc.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/d76b47dd0ec421b1dd00b2c4bf76a5e5.jpg?w=500&auto=format', 3700, 2041, false, false, 72, 75, 127, 1371, '100%', '70.45%', '100%', 0.8458, 0.8461, 0.8477, 6.8425, 0, 0.0117, 0.0113, 0, 0.005, '100%', '100%', '100%', '100%', '70,408.33%', '100%', 0),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xc36cf0cfcb5d905b8b513860db0cfe63f6cf9f5c', 'Town Star', '', 'https://i.seadn.io/s/raw/files/234200827e15463ab011fa6b10e8a1c2.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/0b1d502e3523428b1abd47aa54d8dc9e.png?w=500&auto=format', 1972, 71894, false, true, 62, 451, 1355, 200718, '-12.68%', '49.83%', '-19.54%', 2.7924, 14.9227, 55.7272, 56552.1646, 0.0001, 0.045, 0.0331, 0, 0.2817, '140.64%', '-31.61%', '102.46%', '109.8%', '2.34%', '62.87%', 88.9372),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xbe9371326f91345777b04394448c23e2bfeaa826', 'Gemesis', 'OSP', 'https://openseauserdata.com/files/7ed181433ee09174f09a0e31b563d313.png', 'https://openseauserdata.com/files/71968315427ae68b7cfdfe43f173e10b.png', 94757, 50708, false, true, 62, 1340, 6138, 224423, '-62.42%', '33.6%', '-62.29%', 2.0467, 49.5384, 214.7715, 10085.225, 0.0318, 0.033, 0.037, 0, 0.0449, '-19.32%', '12.12%', '-19.91%', '-69.68%', '49.69%', '-69.83%', 2956.4184),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xb6a37b5d14d502c3ab0ae6f3a0e058bc9517786e', ',Azuki Elementals', 'ELEM', 'https://i.seadn.io/gcs/files/bbaf43ee4a02d5affb7e8fc186d0bdb5.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/79bc14c2aae31bcbfd428662e27541ad.jpg?w=500&auto=format', 17605, 6379, false, true, 55, 300, 2043, 94421, '-27.63%', '-22.28%', '-19.28%', 16.5896, 94.2289, 640.1182, 78368.6974, 0.2484, 0.3016, 0.3141, 0, 0.83, '6.5%', '-3.71%', '-14.12%', '-22.91%', '-25.15%', '-30.67%', 5756.835),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x64256b6409150e8b2b25a456a17dcf171209542a', 'SSR Wives', 'SSRWIVES', 'https://i.seadn.io/gcs/files/2b1b2076ccb5a17d3f629dcd533338b9.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/43c57719df8b42645100812c3cd6712c.jpg?w=500&auto=format', 3210, 740, false, false, 54, 55, 63, 3459, '100%', '5,400%', '43.18%', 0.3212, 0.3314, 0.4408, 122.976, 0.0199, 0.0059, 0.006, 0, 0.0356, '100%', '-68.09%', '-38.6%', '100%', '1,662.77%', '-12.33%', 46.545),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xbfd2030a15df8dd65f4dd9cce4690a312beda820', 'MonoBitz', 'MONO', 'https://i.seadn.io/gcs/files/995c36e017c2c02aa2a6d90e1bcecb78.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/513594d47ea9bdf5b3ffc2bbca65c8f2.png?w=500&auto=format', 6969, 2037, false, false, 52, 58, 120, 1227, '5,100%', '480%', '100%', 0.0005, 0.0012, 0.0053, 7.2688, 0, 0, 0, 0, 0.0059, '-100%', '-100%', '0%', '400%', '-20%', '100%', 0.6969),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x5e90bb26a930038d7c139ca6a39cb1b5da8e5f60', 'Guardian Kongz', 'GDK', 'https://i.seadn.io/gae/aIiQYDDqLK8HkwhtYx0QvrjiNsOC6lqD_vw3Nx45a4S_KvEwxiIAws_5KKNddvqpYfTVBF_0SU6uU18VF8NSfk65rYhY2obTinBLig4?w=500&auto=format', 'https://i.seadn.io/gae/cnXVG1FIkHxNyKtJI58ZMsEAM3BB8vfP9_nVwM_Z4VwrKKqUFDfh-QbKj1y2u93b0Qde2n0__SqY2MTQr8sWH8STEqlXsVyhps6tXw?w=500&auto=format', 5000, 1280, false, false, 48, 50, 50, 1418, '2,300%', '100%', '100%', 0.0066, 0.0066, 0.0066, 94.5018, 0.001, 0.0001, 0.0001, 0, 0.0666, '100%', '100%', '100%', '100%', '100%', '100%', 0),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x76be3b62873462d2142405439777e971754e8e77', 'parallel', 'LL', 'https://i.seadn.io/gae/Nnp8Pdo6EidK7eBduGnAn_JBvFsYGhNGMJ_fHJ_mzGMN_2Khu5snL5zmiUMcSsIqtANh19KqxXDs0iNq_aYbKC5smO3hiCSw9PlL?w=500&auto=format', 'https://i.seadn.io/gae/YPGHP7VAvzy-MCVU67CV85gSW_Di6LWbp-22LGEb3H6Yz9v4wOdAaAhiswnwwL5trMn8tZiJhgbdGuBN9wvpH10d_oGVjVIGM-zW5A?w=500&auto=format', 1090, 64188, false, true, 47, 329, 1225, 276783, '0%', '30.04%', '-24.2%', 0.7177, 3.4425, 18.5646, 95729.4676, 0.0006, 0.0153, 0.0105, 0, 0.3459, '115.49%', '-53.54%', '43.4%', '114.75%', '-39.78%', '8.25%', 21.255),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x524cab2ec69124574082676e6f654a18df49a048', 'Lil Pudgys', 'LP', 'https://i.seadn.io/s/raw/files/649289b91d3d0cefccfe6b9c7f83f471.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x524cab2ec69124574082676e6f654a18df49a048/3826365:about:media:6efd80cc-0c7c-4233-83d4-5375c60f89eb.png?w=500&auto=format', 21905, 9871, false, true, 44, 512, 2082, 157267, '-13.73%', '-9.7%', '-31.58%', 52.3687, 627.6453, 2468.4218, 135687.0428, 1.186, 1.1902, 1.2259, 0, 0.8628, '3.97%', '12.18%', '18.82%', '-10.3%', '1.3%', '-18.71%', 25298.0845),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xa00108f4cfb6400d43c911af0d7a3422f7c011e5', 'Shines', 'SHN', 'https://i.seadn.io/gae/SijDxu652TZHdfGnZVj1EolP9znDzt6X7BsV-IAxuId0PD67BflhE-vaTTZJadLBH4_pEPQqy4JaGATsWX0_zfUIfZkEbPwA1AVJlA?w=500&auto=format', 'https://i.seadn.io/gae/vl8pbfEgf9pPwC34TtlyffTtVQmDzu1uazBX6GY04Qe4T0hpzDr8zSYbHvPIhnytbYJX70gzbyWoglLfp3ous1Gk10jFvXcbUw-F?w=500&auto=format', 3333, 1016, false, false, 44, 74, 108, 5924, '633.33%', '289.47%', '100%', 0.0004, 0.004, 0.0055, 251.3559, 0, 0, 0.0001, 0, 0.0424, '0%', '100%', '100%', '100%', '900%', '100%', 0.3333),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x1f01f454bd3142682a74e9eb93bdc0f7b8b12940', 'Chubby Grubby', 'CHUB', 'https://i.seadn.io/gcs/files/5667b4f22ad7349e8576a097348fa2e0.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/0c23a6e7d7338841e2c49ad619ec14c2.gif?w=500&auto=format', 10000, 3707, false, false, 44, 56, 60, 4182, '1,000%', '5,500%', '100%', 0.0004, 0.0006, 0.0008, 11.2402, 0, 0, 0, 0, 0.0027, '0%', '0%', '0%', '100%', '100%', '100%', 0),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xef0182dc0574cd5874494a120750fd222fdb909a', 'RumbleKongLeague', 'RKL', 'https://i.seadn.io/s/raw/files/866ed37820afd3d81fd2d942edbe5c0d.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xef0182dc0574cd5874494a120750fd222fdb909a/830988:about:media:d27ddcfc-65bb-4b64-bba1-58bc3e305644.png?w=500&auto=format', 10000, 2559, false, true, 43, 71, 422, 22114, '437.5%', '-60.34%', '-17.42%', 3.7839, 6.1688, 31.3431, 20764.9191, 0.0939, 0.088, 0.0869, 0, 0.939, '44.26%', '26.31%', '-48.97%', '675.71%', '-49.91%', '-57.88%', 768),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x9378368ba6b85c1fba5b131b530f5f5bedf21a18', 'VeeFriends Series 2', 'VF2', 'https://i.seadn.io/s/raw/files/7c968bade1414b10fb5fd77d7c82e565.jpg?w=500&auto=format', 'https://i.seadn.io/gae/l7-Zz6ZYWJBu4kkFBxnHchfzg3uJlwmCZsfJt7QMJuiX1v7SQgUp-PveFFPi-Zd8J4m0ROQsGFgDcs96OXZu7JOIqC60kzTu7sQGAA?w=500&auto=format', 55555, 20096, false, true, 40, 375, 1245, 52096, '-29.82%', '-14.58%', '103.43%', 7.5205, 48.9919, 147.3077, 35272.0305, 0.0995, 0.188, 0.1306, 0, 0.6771, '43.18%', '13.27%', '-4.75%', '0.5%', '-3.2%', '93.84%', 6683.2665),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x769272677fab02575e84945f03eca517acc544cc', 'Captainz', 'Captainz', 'https://i.seadn.io/gcs/files/6df4d75778066bce740050615bc84e21.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 3317, false, true, 38, 251, 1152, 31371, '-49.33%', '84.56%', '-13.25%', 29.4501, 188.5888, 879.5289, 139901.4447, 0.738, 0.775, 0.7513, 0, 4.4596, '3.69%', '14.32%', '-24.32%', '-47.46%', '110.99%', '-34.35%', 6989.301),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x49cf6f5d44e70224e2e23fdcdd2c053f30ada28b', 'CloneX', 'CloneX', 'https://i.seadn.io/gae/XN0XuD8Uh3jyRWNtPTFeXJg_ht8m5ofDx6aHklOiy4amhFuWUa0JaR6It49AH8tlnYS386Q0TW_-Lmedn0UET_ko1a3CbJGeu5iHMg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x49cf6f5d44e70224e2e23fdcdd2c053f30ada28b/3569322:about:media:f6f63025-4215-453e-803f-2b34090dfa29.jpeg?w=500&auto=format', 19764, 9235, false, true, 38, 118, 847, 96624, '153.33%', '-64.02%', '-21.43%', 7.382, 35.2356, 174.2957, 470314.6385, 0.1898, 0.1943, 0.2986, 0, 4.8675, '-1.07%', '63.8%', '-11.6%', '150.53%', '-41.08%', '-30.54%', 4231.4724),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x5765a0ca7d8b98b04b80323d327e611beeeb2092', 'Raccoons: Genesis Pass', 'RGP', 'https://i.seadn.io/s/raw/files/069cafcc29da58d96eebd9fddde3baac.gif?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x5765a0ca7d8b98b04b80323d327e611beeeb2092/34178666:about:media:8441ca30-8166-4cf5-b038-ef3ec8c91426.jpeg?w=500&auto=format', 3300, 2843, false, false, 36, 182, 952, 3520, '28.57%', '71.7%', '89.64%', 1.4748, 7.1143, 76.5124, 1004.898, 0.048, 0.041, 0.0391, 0.4354, 0.2855, '4.33%', '-34.62%', '-61.62%', '33.9%', '12.28%', '-27.25%', 156.42),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0xf48b45479ba7e121a3542626d5a5f3b07ec5b65d', 'Outlaws', 'OUT', 'https://i.seadn.io/gcs/files/89e91706142a1003abab1d864370fe62.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/8cc7558e77154bfa99bc568f05e97253.png?w=500&auto=format', 10001, 2798, false, true, 35, 122, 135, 28476, '34.62%', '2,950%', '17.39%', 0.2587, 0.7587, 0.8042, 3181.4918, 0.0095, 0.0074, 0.0062, 0, 0.1117, '51.02%', '58.97%', '87.5%', '103.54%', '4,732.48%', '115.72%', 67.0067),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x9c9679a608c4d983631e088529be74f683a47471', 'YKpanda', 'YK', 'https://i.seadn.io/s/raw/files/04a3beddab9f27eadd5d7e6ed178abb1.gif?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x9c9679a608c4d983631e088529be74f683a47471/34205582:about:media:5e60e2eb-9cae-48f6-9896-81c6bbb6085a.png?w=500&auto=format', 803, 593, false, false, 33, 80, 283, 586, '135.71%', '321.05%', '-19.37%', 5.61, 13.727, 46.805, 86.359, 0, 0.17, 0.1716, 0.08, 0.1474, '0.12%', '9.23%', '20.55%', '136.01%', '360.02%', '-2.79%', 135.2252),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x0c56f29b8d90eea71d57cadeb3216b4ef7494abc', 'CLOAKS', 'CLOAKS', 'https://i.seadn.io/gcs/files/777e28922e6c3cabf9e0786fd76c1118.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/67c3d4d15d8bdbce6e807b2641a15ab2.png?w=500&auto=format', 20000, 3653, false, true, 32, 150, 946, 39392, '77.78%', '-29.58%', '30.48%', 1.8812, 8.2896, 44.0229, 2966.6534, 0.0399, 0.0588, 0.0553, 0, 0.0753, '20%', '44.39%', '-6.44%', '113.31%', '1.59%', '22.18%', 856),(CAST('2025-04-19 19:02:32' AS TIMESTAMP), '0x2187093a2736442d0b5c5d5464b98fc703e3b88d', 'Land of Valeria', 'VOL', 'https://i.seadn.io/gcs/files/05882aae180e1b34ee7e8c67110e37b3.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/74904bc286db669b03e0710677cb1480.png?w=500&auto=format', 10000, 1660, false, false, 31, 71, 137, 5470, '244.44%', '491.67%', '-84.93%', 0.1497, 0.7024, 1.2102, 1382.0953, 0.0121, 0.0048, 0.0099, 0, 0.2527, '-64.71%', '76.79%', '-31.78%', '22.6%', '949.93%', '-89.68%', 116)
;
