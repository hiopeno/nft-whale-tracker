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
(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x66d97206d62c34e8f2ec7d98623bf2c9dd21af11', 'tarifftown', 'TARIFF', '', 'null', 10000, 1971, false, false, 1504, 1505, 1505, 1505, '150,300%', '100%', '100%', 1.9606, 1.9607, 1.9607, 1.9607, 0.0016, 0.0013, 0.0013, 0.0001, 0.0013, '1,200%', '100%', '100%', '1,960,500%', '100%', '100%', 13),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xbe9371326f91345777b04394448c23e2bfeaa826', 'Gemesis', 'OSP', 'https://openseauserdata.com/files/7ed181433ee09174f09a0e31b563d313.png', 'https://openseauserdata.com/files/71968315427ae68b7cfdfe43f173e10b.png', 94757, 50592, false, true, 206, 1130, 7889, 223944, '56.06%', '-29.42%', '-80.35%', 6.2717, 36.1964, 288.0746, 10070.8044, 0.0288, 0.0304, 0.032, 0, 0.045, '1%', '-0.31%', '-29.54%', '57.77%', '-29.48%', '-86.14%', 3041.6997),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x415a82e77642113701fe190554fddd7701c3b262', 'The Bears', 'BRS', 'https://i.seadn.io/gcs/files/cc9dff22af78221f1eda1931618387bb.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/a9d86572578d16967e7fedfd067ad365.png?w=500&auto=format', 10000, 1182, false, false, 134, 863, 3524, 4905, '143.64%', '426.22%', '156.1%', 0.018, 0.5252, 0.7078, 1.0952, 0.0005, 0.0001, 0.0006, 0, 0.0002, '-80%', '500%', '-33.33%', '-34.55%', '3,878.79%', '82.23%', 5),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x524cab2ec69124574082676e6f654a18df49a048', 'Lil Pudgys', 'LP', 'https://i.seadn.io/s/raw/files/649289b91d3d0cefccfe6b9c7f83f471.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x524cab2ec69124574082676e6f654a18df49a048/3826365:about:media:6efd80cc-0c7c-4233-83d4-5375c60f89eb.png?w=500&auto=format', 21905, 9857, false, true, 92, 650, 2156, 157105, '-28.68%', '77.6%', '-59.73%', 118.2511, 747.6569, 2518.6046, 135485.6386, 1.299, 1.2853, 1.1502, 0, 0.8624, '4.79%', '0.6%', '16.47%', '-25.27%', '78.68%', '-53.1%', 24886.2705),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x33fd426905f149f8376e227d0c9d3340aad17af1', 'The Memes by 6529', '', 'https://i.seadn.io/gcs/files/8573c42207ea4d7dc1bb6ed5c0b01243.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/422be663d7ec0bf67cbe6c2d6484f32c.jpg?w=500&auto=format', 347, 10193, false, true, 87, 771, 5441, 79393, '-68.71%', '66.88%', '507.25%', 13.3254, 160.5701, 727.7914, 25045.9955, 0.0568, 0.1532, 0.2083, 0, 0.3155, '-8.76%', '-11.1%', '51.87%', '-71.45%', '48.34%', '821.5%', 73.8416),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x9378368ba6b85c1fba5b131b530f5f5bedf21a18', 'VeeFriends Series 2', 'VF2', 'https://i.seadn.io/s/raw/files/7c968bade1414b10fb5fd77d7c82e565.jpg?w=500&auto=format', 'https://i.seadn.io/gae/l7-Zz6ZYWJBu4kkFBxnHchfzg3uJlwmCZsfJt7QMJuiX1v7SQgUp-PveFFPi-Zd8J4m0ROQsGFgDcs96OXZu7JOIqC60kzTu7sQGAA?w=500&auto=format', 55555, 20108, false, true, 84, 367, 1144, 51985, '100%', '13.62%', '119.16%', 11.0818, 44.3324, 135.2013, 35258.633, 0.094, 0.1319, 0.1208, 0, 0.6782, '29.06%', '7.76%', '1.03%', '158.2%', '22.44%', '121.4%', 6394.3805),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xbbbba1ee822c9b8fc134dea6adfc26603a9cbbbb', 'BitmapPunks', 'BMP', 'https://img.reservoir.tools/images/v2/mainnet/OZOACYlgslkWSExEBQXm4GqPs5dvboMeVVw%2Bdm%2FJmFbLudhgGnQMkH63A9c8bdfPcwx7MsLif7Yhy4OlXGMrda72dohGRnKij5MswoM%2F5SKX1a%2Fs9u%2Fo6Mda%2BNRsc6dGW22uJwXWpYxn7I6rd0X%2BStcBBJ4ARdbJu8BnrLj5pFOhpfXObfbsSQs2rlgSfbZb?width=250', '', 2099775, 15058, false, false, 82, 386, 3713, 43648, '290.48%', '27.39%', '-42.21%', 0.0597, 0.3984, 17.3106, 81.5209, 0.0006, 0.0007, 0.001, 0.002, 0.0019, '0%', '-64.29%', '88%', '280.25%', '-52.42%', '7.81%', 2099.775),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x7e6027a6a84fc1f6db6782c523efe62c923e46ff', 'Rare Pepe - Curated', '', 'https://i.seadn.io/gcs/files/b36c8411036867ffedd8d85c54079785.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/e3f46f74afc2df8875585f511edd940a.png?w=500&auto=format', 1691, 6092, false, true, 81, 287, 879, 12422, '440%', '91.33%', '-53.49%', 5.2672, 30.2363, 78.8263, 2560.9993, 0.0055, 0.065, 0.1054, 0, 0.2062, '-56.14%', '-10.68%', '151.26%', '136.9%', '70.89%', '16.78%', 178.7387),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xb8ea78fcacef50d41375e44e6814ebba36bb33c4', 'Good Vibes Club', 'GVC', '', 'null', 6969, 2194, false, false, 80, 490, 6252, 9005, '25%', '-11.71%', '127.02%', 25.841, 167.4767, 2724.2064, 3172.2914, 0.255, 0.323, 0.3418, 0.0894, 0.3523, '-25.27%', '-7.57%', '167.63%', '-6.58%', '-18.4%', '507.64%', 2446.119),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x2c88aa0956bc9813505d73575f653f69ada60923', 'Wolf Game - Genesis Land', 'LAND', 'https://i.seadn.io/gae/MNZ_7zfZRZ-AFrMOPh7Bylc7IkPr-RvGjSGj_YKSrkYX_QKTzQFUvqs4UKx_FTsY1ioGOHYJjRTkiIDuyShcT1li69EilYucMeqhKSY?w=500&auto=format', 'https://i.seadn.io/gae/MjCw3iPNhn0ZmH3S6MvkIYr1ZQLxHRSdQ8HcLAz_536HZi60OWoWBaHM-wtA-TDNOkXdj4qJyYPKBuR5jh89HDyZgJ8j_mJ6HoxFpA?w=500&auto=format', 19973, 3190, false, true, 76, 264, 452, 38776, '590.91%', '230%', '273.55%', 0.8566, 5.9609, 13.1222, 17724.8168, 0.0129, 0.0113, 0.0226, 0, 0.4571, '-58.15%', '-55.86%', '-11.31%', '188.9%', '45.53%', '231.85%', 485.3439),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xc36cf0cfcb5d905b8b513860db0cfe63f6cf9f5c', 'Town Star', '', 'https://i.seadn.io/s/raw/files/234200827e15463ab011fa6b10e8a1c2.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/0b1d502e3523428b1abd47aa54d8dc9e.png?w=500&auto=format', 1972, 71831, false, true, 65, 334, 1387, 200539, '4.84%', '3.73%', '-15.53%', 0.7901, 13.7079, 48.3662, 56542.2713, 0.0001, 0.0122, 0.041, 0, 0.282, '713.33%', '30.16%', '94.97%', '763.5%', '35.18%', '64.6%', 71.3864),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x04b392cc6cda280c41e6fd637359f6d7f3ecbc30', 'WAFUKU GEN', 'WFK', 'https://i.seadn.io/gcs/files/51cc433516833993eed5e04a5b751972.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/de4f8c13caa5e4d580f1fadbdce1d79b.png?w=500&auto=format', 11559, 2337, false, false, 63, 77, 229, 12488, '3,050%', '48.08%', '-65.92%', 0.6973, 0.968, 3.6675, 774.3872, 0.0169, 0.0111, 0.0126, 0, 0.062, '-27.45%', '-23.17%', '32.23%', '2,178.76%', '13.5%', '-55.01%', 150.267),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xd4416b13d2b3a9abae7acd5d6c2bbdbe25686401', 'NameWrapper', '', 'https://i.seadn.io/gae/0cOqWoYA7xL9CkUjGlxsjreSYBdrUBE0c6EO1COG4XE8UeP-Z30ckqUNiL872zHQHQU5MUNMNhfDpyXIP17hRSC5HQ?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/3072:about:media:252af124-c94f-43a8-b81a-ab886564116f.png?w=500&auto=format', 572348, 424711, false, true, 59, 697, 3514, 16630, '-26.25%', '4.97%', '38.56%', 0.1014, 1.6625, 16.8342, 1870.8256, 0.0001, 0.0017, 0.0024, 0, 0.1125, '-48.48%', '-67.12%', '-60.66%', '-61.85%', '-65.8%', '-45.63%', 2804.4905),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x495f947276749ce646f68ac8c248420045cb7b5e', 'OpenSea Shared Storefront', 'OPENSTORE', 'https://i.seadn.io/gae/6SbnRM2DItPqfKdOKvpxTQLtWrJX7kR1whmTTZEUggaQ4_Awh4ufFxu1Nj_natevEdr3wrXsEE0kbukZ2CJRdJDS?w=500&auto=format', 'null', 2121483, 738790, false, false, 55, 375, 1358, 2441984, '30.95%', '14.68%', '21.47%', 0.6961, 16.2212, 114.7298, 447511.0178, 0.0168, 0.0127, 0.0433, 0, 0.1833, '-28.25%', '-63.77%', '27.64%', '-6.4%', '-58.49%', '54.95%', 170142.9366),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x9a74559843f7721f69651eca916b780ef78bd060', 'Poglin: Battle For Havens Destiny', 'POGLIN-1', 'https://i.seadn.io/s/raw/files/9b975bb19f1cef0837efcff36f62c413.png?w=500&auto=format', 'https://stream.mux.com/00svoiaiF02BXX9Q5nGRdMGvzcu7HsREtFRwkM7mJVmRA/high.mp4', 5600, 1292, false, true, 52, 56, 199, 17774, '100%', '700%', '71.55%', 1.806, 1.8951, 6.1747, 2591.7597, 0.04, 0.0347, 0.0338, 0, 0.1458, '100%', '37.96%', '37.17%', '100%', '1,005.66%', '135.28%', 187.04),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xd93ec495fabbdecd6dfa45bc60f9b634874b634b', 'Jimmy', 'JIMMY', '', 'null', 10000, 3853, false, false, 48, 219, 3094, 3094, '77.78%', '-31.78%', '100%', 1.0706, 4.7205, 105.5828, 105.5828, 0.0269, 0.0223, 0.0216, 0.0282, 0.0341, '-0.45%', '-13.6%', '100%', '76.96%', '-41.18%', '100%', 215),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x74f70713b0515e9f520d6c764352e45e227839b7', 'MetaWinners', 'MW', 'https://img.reservoir.tools/images/v2/mainnet/hc%2BnPcLmWxs%2FDW99DlBQ42k40ZoyYV5jCIms5qHjwvsJTzlw%2FEFEd9KxuktyBPBp0Vqi4oS1gxRDZeVfjbzp0HPiz1a56Ru0TJjr8abEKQX9co15SUMJIHfzghqi0tQrJUD1sdlwa3ZuIue8IL768Je44sKwlx7DhAJ0RfUJY2jTkV909NZzpMfbbR8n%2FN3bCaJEBSIM4LTlSHHWwHws3T6U0c56KUlKy3Liest1962DGTzb1GuFM4FsJG9xYvVKfWZqwHhKDo4p4lMNh35ChA%3D%3D.gif?width=250', '', 10000, 1447, false, false, 47, 358, 1534, 17545, '-2.08%', '0.85%', '-31.61%', 7.5914, 59.0634, 247.0722, 1893.4039, 0.1325, 0.1615, 0.165, 0.14, 0.1079, '-7.29%', '4.17%', '0.12%', '-9.22%', '5.04%', '-31.53%', 1629),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xb6a37b5d14d502c3ab0ae6f3a0e058bc9517786e', ',Azuki Elementals', 'ELEM', 'https://i.seadn.io/gcs/files/bbaf43ee4a02d5affb7e8fc186d0bdb5.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/79bc14c2aae31bcbfd428662e27541ad.jpg?w=500&auto=format', 17605, 6400, false, true, 47, 356, 2096, 94377, '-2.08%', '24.48%', '-58.99%', 16.6095, 118.4405, 671.8979, 78354.9892, 0.2525, 0.3534, 0.3327, 0, 0.8302, '-10.3%', '-1.01%', '-2.02%', '-12.16%', '23.21%', '-59.82%', 5781.482),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x8c6def540b83471664edc6d5cf75883986932674', 'goblintown', 'GOBLIN', 'https://i.seadn.io/gae/cb_wdEAmvry_noTfeuQzhqKpghhZWQ_sEhuGS9swM03UM8QMEVJrndu0ZRdLFgGVqEPeCUzOHGTUllxug9U3xdvt0bES6VFdkRCKPqg?w=500&auto=format', 'https://i.seadn.io/gae/U1IY0rRHvXZ9K7fqDgBBJVnkJhlv0YrL0aMfYzY4XzTkWGyWroq8-GymDy_1e3S17Ze_FPIwg9yjheKxp42SSzUBrp_744yrA16XHKo?w=500&auto=format', 9999, 4448, false, true, 46, 116, 423, 12323, '170.59%', '-15.94%', '-40.42%', 5.2955, 14.1686, 58.4138, 2917.7011, 0.119, 0.1151, 0.1221, 0, 0.2368, '-5.73%', '-13.53%', '-10.85%', '155.19%', '-27.3%', '-46.9%', 1232.8767),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x1a3c1bf0bd66eb15cd4a61b76a20fb68609f97ef', 'Morph Black', 'BLACK', '', 'null', 3000, 1877, false, false, 44, 291, 1186, 1186, '-32.31%', '24.36%', '100%', 40.3134, 286.6593, 1141.7058, 1141.7058, 0.8784, 0.9162, 0.9851, 1.7, 0.9627, '-8.02%', '5.32%', '100%', '-37.74%', '30.98%', '100%', 2925),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x8ff1523091c9517bc328223d50b52ef450200339', 'RugGenesis NFT', '✺RUGNFT', 'https://i.seadn.io/gae/I4Jd-ET3UY7eKLYeC7WxrmJTsyxrsXHG0Zg_Yqif0vpFhO9oA6fMdzHX6ze0g4nzSFsjP7RZSyDMPUdeuJxDCjPx9moPzPJkqeVBeco?w=500&auto=format', 'https://i.seadn.io/gae/e7k5z8bajMs_siuo_Y3pw0xmWPboGTOi5PHikzn_k00izWoFmqY1KM5ZSMItE336lx-QqXlnJdZtal8g4eoUq_sFW_UJOEmInkA48io?w=500&auto=format', 20000, 6902, false, true, 42, 167, 422, 41254, '425%', '53.21%', '-13.52%', 4.0887, 18.1477, 51.9861, 16676.7315, 0.0913, 0.0974, 0.1087, 0, 0.4042, '-4.13%', '-23.07%', '-10.01%', '403.04%', '17.82%', '-22.2%', 2420),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x6339e5e072086621540d0362c4e3cea0d643e114', 'Opepen Edition', 'OPEPEN', 'https://i.seadn.io/gcs/files/b1c9ed2e584b4f6e418bf1ca15311844.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x6339e5e072086621540d0362c4e3cea0d643e114/22896054:about:media:3e0e24fd-ac54-47b6-aad2-99b0bbe8218b.jpeg?w=500&auto=format', 16000, 3692, false, true, 42, 283, 1060, 197857, '-48.78%', '43.65%', '64.85%', 33.1562, 169.0426, 476.7699, 87476.7312, 0.239, 0.7894, 0.5973, 0, 0.4421, '14.47%', '41.54%', '55.16%', '-41.36%', '103.34%', '155.8%', 8574.4),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x8a90cab2b38dba80c64b7734e58ee1db38b8992e', 'Doodles', 'DOODLE', 'https://i.seadn.io/s/raw/files/e663a85a2900fdd4bfe8f34a444b72d3.jpg?w=500&auto=format', 'https://i.seadn.io/gae/svc_rQkHVGf3aMI14v3pN-ZTI7uDRwN-QayvixX-nHSMZBgb1L1LReSg1-rXj4gNLJgAB0-yD8ERoT-Q2Gu4cy5AuSg-RdHF9bOxFDw?w=500&auto=format', 10000, 3865, false, true, 41, 243, 858, 78815, '46.43%', '10.96%', '-74.68%', 115.515, 691.9923, 2538.2969, 382645.8497, 2.91, 2.8174, 2.8477, 0, 4.855, '-4.76%', '-3.81%', '-24.99%', '39.46%', '6.73%', '-81%', 28548),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x67b8afddb494c16b779e6f23e1de5dbf3437f857', 'Mintify Genesis', 'MNFGEN', 'https://i.seadn.io/s/raw/files/cb573e475e3ce1c5d0594203dada37bd.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x67b8afddb494c16b779e6f23e1de5dbf3437f857/28078179:about:media:bd675f02-4ccf-4767-bfa2-2143a4359ebf.png?w=500&auto=format', 5876, 1025, false, true, 39, 110, 706, 12397, '550%', '25%', '-4.59%', 0.5925, 1.9209, 16.4668, 1008.4511, 0.0194, 0.0152, 0.0175, 0, 0.0813, '-10.59%', '-15.05%', '-73.37%', '480.88%', '6.12%', '-74.58%', 105.768),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xec7f8a34b97ac65caad3841659f2cd54285a3950', 'Impostors Pet', 'PET', 'https://i.seadn.io/gae/gzMNhfUEBDR9e4yaGiU11fX28VMkotYPjXyLh48UJTl2qDZj-B4k7P4RvBIAjfDSFOrQ054RhYXnzobnccHjRkIXBBUwW0Vm5EN18w?w=500&auto=format', 'https://i.seadn.io/gae/suCKD2bm4bQvvX2zpltV3xGrn_gUJ826c0efGBD2nkdVmFXvKJBBMiLtpiQHSEE5N02JbDgl_Nn08rvjJQTUtC2sTagejdH5Jwdd_Q?w=500&auto=format', 8789, 3259, false, false, 36, 67, 144, 5948, '1,100%', '55.81%', '100%', 1.6586, 3.9492, 7.6508, 1150.7977, 0.039, 0.0461, 0.0589, 0, 0.1935, '-39.34%', '23.48%', '-32.44%', '627.14%', '92.47%', '35.26%', 551.9492),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x0c56f29b8d90eea71d57cadeb3216b4ef7494abc', 'CLOAKS', 'CLOAKS', 'https://i.seadn.io/gcs/files/777e28922e6c3cabf9e0786fd76c1118.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/67c3d4d15d8bdbce6e807b2641a15ab2.png?w=500&auto=format', 20000, 3652, false, true, 34, 189, 1028, 39347, '161.54%', '-44.74%', '29.63%', 1.5538, 7.8814, 47.1255, 2964.4786, 0.0395, 0.0457, 0.0417, 0, 0.0753, '-39.87%', '2.46%', '2.23%', '57.35%', '-43.39%', '32.71%', 802),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xc31085b262b3d57c649f8747e4f083685697176e', 'Impostors UFO', 'UFO', 'https://i.seadn.io/gae/G9OrgtEv8XmsvtMAGGOWTLvxKE1z8vdkuYmaJIvuSSAhkpZMSYO6zdquxDXPV5sQPRFaPpC7z40nNrrSbVhj9d63FzBeFgjG1S8P?w=500&auto=format', 'https://i.seadn.io/gae/gTswmIIXZpUVyP0VCPuotUBk0z_WLun97D4dNRPfYMDTl4WOdUk8kTV6Z6Kh3TpPkK3B_GCAocYhALpSJemIvB8w0yaMvNBC2D5vhPU?w=500&auto=format', 9410, 3441, false, false, 34, 57, 132, 7994, '580%', '119.23%', '100%', 1.4154, 3.5499, 6.4789, 1936.2816, 0.0449, 0.0416, 0.0623, 0, 0.2422, '-54.08%', '12.05%', '-42.44%', '212.59%', '145.41%', '15.13%', 603.181),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x76be3b62873462d2142405439777e971754e8e77', 'parallel', 'LL', 'https://i.seadn.io/gae/Nnp8Pdo6EidK7eBduGnAn_JBvFsYGhNGMJ_fHJ_mzGMN_2Khu5snL5zmiUMcSsIqtANh19KqxXDs0iNq_aYbKC5smO3hiCSw9PlL?w=500&auto=format', 'https://i.seadn.io/gae/YPGHP7VAvzy-MCVU67CV85gSW_Di6LWbp-22LGEb3H6Yz9v4wOdAaAhiswnwwL5trMn8tZiJhgbdGuBN9wvpH10d_oGVjVIGM-zW5A?w=500&auto=format', 1090, 64130, false, true, 34, 224, 1158, 276640, '-8.11%', '-39.13%', '-46.56%', 0.6927, 3.5041, 18.0068, 95727.9207, 0.0006, 0.0204, 0.0156, 0, 0.346, '518.18%', '-34.45%', '103.95%', '460.44%', '-60.06%', '9.91%', 24.743),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0x769272677fab02575e84945f03eca517acc544cc', 'Captainz', 'Captainz', 'https://i.seadn.io/gcs/files/6df4d75778066bce740050615bc84e21.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/62448fe425d5e5e2bd44ded754865f37.png?w=500&auto=format', 9999, 3307, false, true, 30, 151, 1043, 31292, '25%', '-40.32%', '-33.44%', 24.4453, 106.6386, 820.2239, 139844.9822, 0.649, 0.8148, 0.7062, 0, 4.469, '8.99%', '-2.99%', '-27.23%', '36.24%', '-42.1%', '-51.57%', 6965.3034),(CAST('2025-04-15 14:15:22' AS TIMESTAMP), '0xb06e04c7ea0f8c1a47f190d7585d60778b426a81', 'Gorilla Gangsters', 'GG', '', 'null', 1051, 167, false, false, 30, 98, 131, 131, '2,900%', '880%', '100%', 0.0241, 0.0659, 0.0944, 0.0944, 0.0009, 0.0008, 0.0007, 0.0018, 0.0007, '0%', '40%', '100%', '2,912.5%', '1,143.4%', '100%', 0.7357)
;
