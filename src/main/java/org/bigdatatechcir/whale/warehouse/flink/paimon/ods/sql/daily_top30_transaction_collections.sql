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
(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xb8ea78fcacef50d41375e44e6814ebba36bb33c4', 'Good Vibes Club', 'GVC', 'https://i.seadn.io/s/raw/files/8ba2b8fe4048f4e6ea170550ca27a2f7.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xb8ea78fcacef50d41375e44e6814ebba36bb33c4/34487095:about:media:a8b9eeef-2abb-416b-8013-bdf34aefcc87.jpeg?w=500&auto=format', 6969, 2097, false, true, 201, 842, 3500, 9178, '-6.07%', '67.73%', '-44.43%', 113.5281, 365.4691, 1408.4878, 3231.0276, 0.435, 0.5648, 0.434, 0.0894, 0.352, '28.57%', '24.14%', '19.94%', '20.76%', '108.25%', '-33.34%', 2409.1833),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xbe9371326f91345777b04394448c23e2bfeaa826', 'Gemesis', 'OSP', 'https://openseauserdata.com/files/7ed181433ee09174f09a0e31b563d313.png', 'https://openseauserdata.com/files/71968315427ae68b7cfdfe43f173e10b.png', 94757, 50685, false, true, 171, 1331, 5932, 224423, '128%', '23.35%', '-60.96%', 6.5115, 50.4926, 207.92, 10085.225, 0.0375, 0.0381, 0.0379, 0, 0.0449, '17.23%', '17.34%', '-16.82%', '166.89%', '45.04%', '-67.59%', 2956.4184),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xd4416b13d2b3a9abae7acd5d6c2bbdbe25686401', 'NameWrapper', '', 'https://i.seadn.io/gae/0cOqWoYA7xL9CkUjGlxsjreSYBdrUBE0c6EO1COG4XE8UeP-Z30ckqUNiL872zHQHQU5MUNMNhfDpyXIP17hRSC5HQ?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/3072:about:media:252af124-c94f-43a8-b81a-ab886564116f.png?w=500&auto=format', 573179, 425180, false, true, 147, 730, 3075, 16786, '0%', '5.64%', '2.3%', 0.3669, 2.4584, 16.552, 1871.4901, 0.0001, 0.0025, 0.0034, 0, 0.1115, '0%', '17.24%', '-50%', '1.78%', '21.55%', '-48.88%', 1776.8549),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x6339e5e072086621540d0362c4e3cea0d643e114', 'Opepen Edition', 'OPEPEN', 'https://i.seadn.io/gcs/files/b1c9ed2e584b4f6e418bf1ca15311844.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x6339e5e072086621540d0362c4e3cea0d643e114/22896054:about:media:3e0e24fd-ac54-47b6-aad2-99b0bbe8218b.jpeg?w=500&auto=format', 16000, 3695, false, true, 114, 310, 1110, 197954, '322.22%', '8.39%', '50%', 36.411, 173.733, 518.8184, 87550.9051, 0.2868, 0.3194, 0.5604, 0, 0.4423, '-43.85%', '-2.32%', '25.98%', '137.1%', '5.88%', '88.99%', 9836.8),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xc36cf0cfcb5d905b8b513860db0cfe63f6cf9f5c', 'Town Star', '', 'https://i.seadn.io/s/raw/files/234200827e15463ab011fa6b10e8a1c2.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/0b1d502e3523428b1abd47aa54d8dc9e.png?w=500&auto=format', 1972, 71894, false, true, 85, 482, 1374, 200718, '49.12%', '61.2%', '-18.31%', 0.3839, 15.1999, 52.2363, 56552.1646, 0.0001, 0.0045, 0.0315, 0, 0.2817, '-90.63%', '-28.41%', '80.09%', '-85.98%', '15.55%', '47.32%', 88.9372),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xb66a603f4cfe17e3d27b87a8bfcad319856518b8', 'Rarible', 'RARI', 'https://i.seadn.io/gae/FG0QJ00fN3c_FWuPeUr9-T__iQl63j9hn5d6svW8UqOmia5zp3lKHPkJuHcvhZ0f_Pd6P2COo9tt9zVUvdPxG_9BBw?w=500&auto=format', 'https://i.seadn.io/gcs/static/banners/rarible-banner4.png?w=500&auto=format', 16559, 26878, false, false, 75, 385, 1403, 28543, '7.14%', '-11.09%', '477.37%', 0.0004, 0.0164, 1.9044, 6848.3913, 0, 0, 0, 0, 0.2399, '0%', '-100%', '-71.43%', '-85.19%', '-96.33%', '61.23%', 0),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x4b15a9c28034dc83db40cd810001427d3bd7163d', 'HV-MTL', 'HV-MTL', 'https://i.seadn.io/gcs/files/82a7f92df6d60e41327b69cdafea8831.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/be397bd4615365ac3bcb5a13a3159b0b.gif?w=500&auto=format', 28378, 8489, false, true, 73, 574, 892, 39699, '-9.88%', '769.7%', '97.78%', 2.0963, 20.5753, 35.1436, 41769.4551, 0.0213, 0.0287, 0.0358, 0, 1.0522, '-8.6%', '-26.03%', '2.07%', '-17.47%', '544.67%', '101.65%', 1382.0086),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x350b892af9613f5d6ee6892acc7aee04e84e6fe8', 'Fluffy Squad', 'FLUFFY', 'https://i.seadn.io/s/raw/files/1059c2508ce985a38bbd6f7383a60b0a.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x350b892af9613f5d6ee6892acc7aee04e84e6fe8/34539761:about:media:e654d4ab-1900-4f22-86eb-4036c3cb675d.png?w=500&auto=format', 5391, 883, false, false, 69, 117, 118, 49, '100%', '11,600%', '100%', 0.0022, 0.0027, 0.0031, 0.0009, 0, 0, 0, 0.0004, 0, '0%', '-100%', '0%', '100%', '575%', '100%', 0),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x5361fc8bd90fe2e3cd82e5326ddbe5aa4765b116', 'Vampire Punks', 'VPunks', 'https://img.reservoir.tools/images/v2/mainnet/z9JRSpLYGu7%2BCZoKWtAuAGdWptlhC4UVqExq%2BIguqyGFnf56DFV5L%2B4xyJGVphxd3Ywd0exQLHQScqin69vdSH5ZYUa0gP9IacPBLeuDzKcQxcvxnAC6nllhSTqILGokZSl4%2BNwiXPy56x9YiQGc5tOA7gG5TG8rvN5YU3mKej%2BanKFRYekVlECuWUX9Fbk0RGsQb1c9Z4atzjIl3O81ag%3D%3D?width=250', '', 9306, 3533, false, false, 65, 67, 287, 235, '100%', '8.06%', '2,107.69%', 0.0146, 0.015, 0.0576, 0.0569, 0.0002, 0.0002, 0.0002, 0.0004, 0.0002, '100%', '-50%', '-81.82%', '100%', '-35.62%', '314.39%', 3.7224),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x7e6027a6a84fc1f6db6782c523efe62c923e46ff', 'Rare Pepe - Curated', '', 'https://i.seadn.io/gcs/files/b36c8411036867ffedd8d85c54079785.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/e3f46f74afc2df8875585f511edd940a.png?w=500&auto=format', 1691, 6103, false, true, 59, 356, 1003, 12554, '63.89%', '56.14%', '-25.59%', 3.8366, 27.7911, 86.7737, 2565.6316, 0.003, 0.065, 0.0781, 0, 0.2044, '-37.56%', '-35.13%', '65.08%', '2.39%', '1.22%', '22.95%', 134.6036),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x9378368ba6b85c1fba5b131b530f5f5bedf21a18', 'VeeFriends Series 2', 'VF2', 'https://i.seadn.io/s/raw/files/7c968bade1414b10fb5fd77d7c82e565.jpg?w=500&auto=format', 'https://i.seadn.io/gae/l7-Zz6ZYWJBu4kkFBxnHchfzg3uJlwmCZsfJt7QMJuiX1v7SQgUp-PveFFPi-Zd8J4m0ROQsGFgDcs96OXZu7JOIqC60kzTu7sQGAA?w=500&auto=format', 55555, 20096, false, true, 58, 381, 1277, 52096, '45%', '-0.78%', '102.7%', 7.1524, 49.4377, 151.6344, 35272.0305, 0.0993, 0.1233, 0.1298, 0, 0.6771, '-32.88%', '7.54%', '-4.58%', '-2.64%', '6.65%', '93.53%', 6683.2665),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xa0daea23850728b20b007b4d833f6853928288d6', 'Balance Pioneer Badge', 'BPBT', 'https://img.reservoir.tools/images/v2/mainnet/z9JRSpLYGu7%2BCZoKWtAuAGWMlxciEQCESPKStAj21DqsE%2FX30tFCXg5eJ2e002aPZ58eyUnczsKy2zFtGCSWDmiv3GW%2FhwzpUSWnmGFvoXMJdYIpwWBI9fXFb%2FW5dy3psr8a64Fna4%2FbxYHNDSNTpCEN%2Br3KVcYRbW8oPqiF%2FkcZG1P8TdZD4JlcilJSVYFeoqLwxOUKGTC0FOZXtCv5XA%3D%3D?width=250', '', 2000, 1459, false, false, 57, 119, 231, 1813, '280%', '526.32%', '56.08%', 1.7643, 3.2394, 6.0444, 133.57, 0.045, 0.031, 0.0272, 0.0593, 0.0737, '31.91%', '14.77%', '-15.48%', '400.79%', '619.23%', '31.89%', 49),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xd5a66b87801b6b8f9bfe7e42db24cf9b7e2f30ef', 'Infinite Petals by Sarah Meyohas', 'MEYOHAS-IP', 'https://img.reservoir.tools/images/v2/mainnet/z9JRSpLYGu7%2BCZoKWtAuAI8ipNM7MJ1GQZfU57rB7lKla5A%2B5nD3dK0dPzmfUOL4fu13c%2B7QFzov4SlgvL0gQmiW8QEUM99BMMCcoRcEGzQN5Spyg%2Fd8%2BkEQ0KKTO3Spac%2Fy71V8BZhIlihcJtGgf%2BIs%2BBkHNwIlROyJbPenkAomr%2BS4SStPAwK3gTVNBYouEnUOfdK0jGDRJI5bQ4GrLw%3D%3D?width=250', 'https://img.reservoir.tools/images/v2/mainnet/M4eOe%2BWm03o9r1%2F%2BIQ0oM0tpc7YU6ht6kmebKTnInXYRXJlOzRyGKO%2B%2FPV3puZ1NBRSEfbSYeqQE2kcYFzTYFCGDN2bhSr2wo7he7nFLDRY%3D', 2772, 711, false, true, 53, 677, 677, 90, '-57.94%', '100%', '100%', 3.929, 47.7994, 47.7994, 9.1818, 0.044, 0.0741, 0.0706, 0.05, 0.102, '74.35%', '100%', '100%', '-26.57%', '100%', '100%', 279.588),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x33fd426905f149f8376e227d0c9d3340aad17af1', 'The Memes by 6529', '', 'https://i.seadn.io/gcs/files/8573c42207ea4d7dc1bb6ed5c0b01243.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/422be663d7ec0bf67cbe6c2d6484f32c.jpg?w=500&auto=format', 349, 10190, false, true, 51, 474, 3375, 79627, '70%', '-35.69%', '8.66%', 6.8012, 91.4837, 605.7809, 25099.1299, 0.0545, 0.1334, 0.193, 0, 0.3152, '-25.85%', '-15.13%', '104.21%', '26%', '-45.42%', '121.99%', 78.0364),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x9f803635a5af311d9a3b73132482a95eb540f71a', 'The Great Color Study', '', 'https://i.seadn.io/gcs/files/3893e730186401d386e308d336d052f5.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/a67b3ac2420a273a72aa1ea71d5045f3.png?w=500&auto=format', 10, 847, false, true, 50, 54, 75, 2487, '2,400%', '390.91%', '212.5%', 26.1429, 27.2129, 31.8803, 777.0209, 0.529, 0.5229, 0.5039, 0, 0.3124, '86.75%', '120.53%', '110.86%', '4,568.38%', '982.5%', '558.75%', 2.312),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xb6a37b5d14d502c3ab0ae6f3a0e058bc9517786e', ',Azuki Elementals', 'ELEM', 'https://i.seadn.io/gcs/files/bbaf43ee4a02d5affb7e8fc186d0bdb5.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/79bc14c2aae31bcbfd428662e27541ad.jpg?w=500&auto=format', 17605, 6375, false, true, 49, 305, 2044, 94421, '-23.44%', '-26.68%', '-14.41%', 19.1722, 100.3465, 648.0102, 78368.6974, 0.2527, 0.3913, 0.329, 0, 0.83, '13.78%', '0.64%', '-13.72%', '-12.89%', '-26.21%', '-26.13%', 5756.835),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xb3b434f79f69b685c063860799bdc44dac7ef25e', 'Bytesons', 'SONS', 'https://i.seadn.io/gcs/files/91945f4595c6c0f188c57ddde808d4fe.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/b26be26510cf520340741901c16bc276.png?w=500&auto=format', 3000, 822, false, false, 48, 88, 218, 2831, '1,500%', '282.61%', '-59.33%', 0.5856, 0.9038, 1.9406, 25.2078, 0.007, 0.0122, 0.0103, 0, 0.0089, '351.85%', '-2.83%', '32.84%', '7,220%', '270.56%', '-45.61%', 27),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x02cf5c2e8f61fe50ce8f20a3b60838015f23c618', 'MOONCOURT BOOSTER', 'BOOSTER', 'https://i.seadn.io/gcs/files/e36e520509c21a67ac161dc5ed935e7c.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/45934f3035576bfc65f42d304109dbb4.png?w=500&auto=format', 918, 16, false, false, 47, 48, 91, 332, '100%', '140%', '295.65%', 2.4914, 2.5644, 5.6054, 22.328, 0.0489, 0.053, 0.0534, 0, 0.0673, '100%', '-25.83%', '-14.21%', '100%', '78.08%', '239.31%', 66.096),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x524cab2ec69124574082676e6f654a18df49a048', 'Lil Pudgys', 'LP', 'https://i.seadn.io/s/raw/files/649289b91d3d0cefccfe6b9c7f83f471.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x524cab2ec69124574082676e6f654a18df49a048/3826365:about:media:6efd80cc-0c7c-4233-83d4-5375c60f89eb.png?w=500&auto=format', 21905, 9857, false, true, 46, 423, 1941, 157267, '9.52%', '-36.96%', '-34.84%', 56.8735, 518.2294, 2304.2061, 135687.0428, 1.235, 1.2364, 1.2251, 0, 0.8628, '3.96%', '9.48%', '16.55%', '13.86%', '-30.98%', '-24.06%', 25298.0845),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x66d97206d62c34e8f2ec7d98623bf2c9dd21af11', 'tarifftown', 'TARIFF', 'https://i.seadn.io/s/raw/files/f45f4bad046ae460f2e45ed3ba1d608e.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x66d97206d62c34e8f2ec7d98623bf2c9dd21af11/34717121:about:media:3d172b21-4b34-4e7a-a9c0-5732f783f0c3.png?w=500&auto=format', 10000, 1926, false, false, 44, 2675, 2685, 2483, '-58.88%', '26,650%', '100%', 0.0653, 3.8791, 3.8799, 3.5417, 0.001, 0.0015, 0.0015, 0.0001, 0.0014, '15.38%', '1,400%', '100%', '-51.2%', '484,787.5%', '100%', 14),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x51bb4c8bb4901d6aa061282cd7ed916eec715a29', 'egg', 'EGG', 'https://i.seadn.io/s/raw/files/61c4ad2bca2156c37a4004b38c8923d8.gif?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x51bb4c8bb4901d6aa061282cd7ed916eec715a29/33243394:about:media:bfed82f9-1a3a-49d1-bb95-34f2599ed61a.png?w=500&auto=format', 3134, 928, false, true, 41, 151, 300, 11585, '95.24%', '403.33%', '42.18%', 2.6752, 6.7811, 13.0998, 1793.3742, 0.04, 0.0652, 0.0449, 0.011, 0.1548, '63%', '-16.23%', '29.29%', '218.36%', '321.47%', '83.93%', 155.133),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xef0182dc0574cd5874494a120750fd222fdb909a', 'RumbleKongLeague', 'RKL', 'https://i.seadn.io/s/raw/files/866ed37820afd3d81fd2d942edbe5c0d.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xef0182dc0574cd5874494a120750fd222fdb909a/830988:about:media:d27ddcfc-65bb-4b64-bba1-58bc3e305644.png?w=500&auto=format', 10000, 2559, false, true, 41, 106, 456, 22114, '-2.38%', '-15.87%', '-11.63%', 2.602, 8.2595, 33.3448, 20764.9191, 0.0689, 0.0635, 0.0779, 0, 0.939, '-28.41%', '5.27%', '-49.41%', '-30.13%', '-11.38%', '-55.28%', 768),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xab6c7a0a41765109075646b2100c54ef4c05e2fc', 'Wise Squirrels', 'WS', 'https://i.seadn.io/s/raw/files/8023ac2c76d961b69c2ef159864aacd4.png?w=500&auto=format', 'null', 4272, 223, false, false, 41, 41, 90, 81, '100%', '241.67%', '221.43%', 0.0534, 0.0534, 0.0925, 0.081, 0.001, 0.0013, 0.0013, 0.0032, 0.001, '100%', '8.33%', '-9.09%', '100%', '286.96%', '212.5%', 0),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x8cdbd7010bd197848e95c1fd7f6e870aac9b0d3c', 'AOI Engine', 'AOI', 'https://storage.nfte.ai/asset/collection/featured/a61ade6a-76f3-4ccd-98df-344b8b599d38.png', 'null', 16269, 4783, false, false, 40, 97, 288, 40388, '53.85%', '11.49%', '4.73%', 1.9229, 3.9797, 15.3522, 8394.9813, 0.0998, 0.0481, 0.041, 0, 0.2079, '81.51%', '-19.92%', '-1.11%', '178.68%', '-10.58%', '3.56%', 860.6301),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xca21d4228cdcc68d4e23807e5e370c07577dd152', 'Zorbs', 'ZORB', 'https://i.seadn.io/gae/O2J_GV66yHfYeHIl-ASFknUqJ1qPB-W1D6xB2Xk-Po9GVE5Te9hkBSPsjCVTTHzq1QYgLppo4LcDtHiV3pxeSfB1b9_fP5pGbiRuUg?w=500&auto=format', 'null', 56741, 37573, false, true, 38, 78, 256, 40597, '1,800%', '122.86%', '-63.11%', 0.256, 0.462, 1.3393, 2043.4175, 0.0077, 0.0067, 0.0059, 0, 0.0503, '21.82%', '63.89%', '-47.47%', '2,227.27%', '267.83%', '-80.47%', 226.964),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x79986af15539de2db9a5086382daeda917a9cf0c', 'Cryptovoxels Parcel', 'CVPA', 'https://i.seadn.io/gcs/files/0adc5259bd28de7939b2b3199817d960.png?w=500&auto=format', 'https://i.seadn.io/gae/kkh76pHC9GJP90HE8ZByQ5u3AVsGOarPIe846kb4BB03hYrHB4tOweNFdBu-3UwunEyR6TstvCe4DCu3VhY6MZ624JffEL1Ph4x8NPI?w=500&auto=format', 7937, 2490, false, true, 33, 43, 86, 13709, '3,200%', '53.57%', '258.33%', 1.9456, 2.5114, 4.8485, 25929.4182, 0.0444, 0.059, 0.0584, 0, 1.8914, '17.06%', '4.85%', '-16.81%', '3,760.32%', '61.14%', '198.17%', 429.3917),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x5088f6c95ee2e668907f153f709144ffc92d3abb', 'BeeOS', 'BeeOS', '', 'null', 2548, 1137, false, false, 32, 342, 1192, 2317, '28%', '-8.56%', '-7.53%', 0.3331, 4.2184, 16.3911, 30.6543, 0.0095, 0.0104, 0.0123, 0.0128, 0.0132, '-7.14%', '-7.52%', '9.52%', '18.5%', '-14.92%', '1.01%', 33.3788),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x39ee2c7b3cb80254225884ca001f57118c8f21b6', 'Potatoz', 'Potatoz', 'https://i.seadn.io/gcs/files/129b97582f0071212ee7cf440644fc28.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 2432, false, true, 31, 189, 1011, 46481, '-56.34%', '117.24%', '-25.39%', 7.7123, 46.9756, 245.1684, 64208.9948, 0.2469, 0.2488, 0.2485, 0, 1.3814, '-2.7%', '11.54%', '-22.94%', '-57.52%', '142.38%', '-42.5%', 2249.775),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0xd774557b647330c91bf44cfeab205095f7e6c367', 'Nakamigos', 'NKMGS', 'https://i.seadn.io/gcs/files/1619b033c453fe36c5d9e2ac451379a7.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/6cdaf5f7fc406df1b2861ade634aad63.png?w=500&auto=format', 20000, 5418, false, true, 29, 182, 1173, 160930, '11.54%', '-19.82%', '10.56%', 5.7209, 28.2201, 202.8618, 49472.6206, 0.1237, 0.1973, 0.1551, 0, 0.3074, '29.55%', '-8.28%', '-4.9%', '44.45%', '-26.48%', '5.2%', 3032),(CAST('2025-04-20 20:51:28' AS TIMESTAMP), '0x76be3b62873462d2142405439777e971754e8e77', 'parallel', 'LL', 'https://i.seadn.io/gae/Nnp8Pdo6EidK7eBduGnAn_JBvFsYGhNGMJ_fHJ_mzGMN_2Khu5snL5zmiUMcSsIqtANh19KqxXDs0iNq_aYbKC5smO3hiCSw9PlL?w=500&auto=format', 'https://i.seadn.io/gae/YPGHP7VAvzy-MCVU67CV85gSW_Di6LWbp-22LGEb3H6Yz9v4wOdAaAhiswnwwL5trMn8tZiJhgbdGuBN9wvpH10d_oGVjVIGM-zW5A?w=500&auto=format', 1090, 64198, false, true, 29, 318, 1226, 276783, '-35.56%', '39.47%', '-21.51%', 0.0756, 3.376, 18.5447, 95729.4676, 0.0006, 0.0026, 0.0106, 0, 0.3459, '-83.65%', '-55.83%', '39.81%', '-89.45%', '-38.41%', '10.37%', 21.255)
;
