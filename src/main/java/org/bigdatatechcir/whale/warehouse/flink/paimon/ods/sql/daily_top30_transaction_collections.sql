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
(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x415a82e77642113701fe190554fddd7701c3b262', 'The Bears', 'BRS', 'https://i.seadn.io/gcs/files/cc9dff22af78221f1eda1931618387bb.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/a9d86572578d16967e7fedfd067ad365.png?w=500&auto=format', 10000, 1170, false, false, 216, 524, 3327, 4405, '50%', '-54.98%', '210.64%', 0.0409, 0.0557, 0.507, 0.614, 0, 0.0002, 0.0001, 0, 0.0001, '100%', '0%', '100%', '2,456.25%', '-19.04%', '376.06%', 1),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xd4416b13d2b3a9abae7acd5d6c2bbdbe25686401', 'NameWrapper', '', 'https://i.seadn.io/gae/0cOqWoYA7xL9CkUjGlxsjreSYBdrUBE0c6EO1COG4XE8UeP-Z30ckqUNiL872zHQHQU5MUNMNhfDpyXIP17hRSC5HQ?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/3072:about:media:252af124-c94f-43a8-b81a-ab886564116f.png?w=500&auto=format', 570706, 423914, false, true, 171, 753, 3489, 16271, '4.27%', '-1.83%', '42.35%', 0.2848, 4.1021, 15.7374, 1869.4709, 0.0001, 0.0017, 0.0054, 0, 0.1149, '1,600%', '-18.18%', '-78.57%', '1,160.18%', '-19.26%', '-69.44%', 2739.384),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x33fd426905f149f8376e227d0c9d3340aad17af1', 'The Memes by 6529', '', 'https://i.seadn.io/gcs/files/8573c42207ea4d7dc1bb6ed5c0b01243.jpg?w=500&auto=format', 'https://i.seadn.io/gcs/files/422be663d7ec0bf67cbe6c2d6484f32c.jpg?w=500&auto=format', 346, 10206, false, true, 118, 488, 4980, 78797, '122.64%', '-28.65%', '483.82%', 26.0905, 124.9202, 632.2546, 24930.0473, 0.0639, 0.2211, 0.256, 0, 0.3164, '-33.74%', '56.86%', '67.33%', '47.5%', '11.88%', '876.28%', 78.8534),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xfdf5acd92840e796955736b1bb9cc832740744ba', 'OVERWORLD INCARNA', 'INCARNA', 'https://i.seadn.io/s/raw/files/d67e16753135e677c05077781003de5b.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xfdf5acd92840e796955736b1bb9cc832740744ba/31240882:about:media:6e285846-35ec-4781-9a66-dd8f3b294768.jpeg?w=500&auto=format', 6000, 1326, false, true, 115, 173, 539, 12015, '1,816.67%', '22.7%', '23.06%', 13.9043, 22.9137, 71.2056, 12373.3437, 0.1049, 0.1209, 0.1324, 0, 1.0298, '-8.96%', '-7.99%', '33.84%', '1,644.8%', '12.95%', '64.79%', 823.2),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xbe9371326f91345777b04394448c23e2bfeaa826', 'Gemesis', 'OSP', 'https://openseauserdata.com/files/7ed181433ee09174f09a0e31b563d313.png', 'https://openseauserdata.com/files/71968315427ae68b7cfdfe43f173e10b.png', 94757, 50494, false, true, 85, 1162, 9847, 223091, '-43.33%', '-38.26%', '-75.02%', 2.7383, 37.1027, 373.0088, 10043.2572, 0.0319, 0.0322, 0.0319, 0, 0.045, '4.21%', '-7.8%', '-26.41%', '-40.97%', '-42.98%', '-81.64%', 3060.6511),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x495f947276749ce646f68ac8c248420045cb7b5e', 'OpenSea Shared Storefront', 'OPENSTORE', 'https://i.seadn.io/gae/6SbnRM2DItPqfKdOKvpxTQLtWrJX7kR1whmTTZEUggaQ4_Awh4ufFxu1Nj_natevEdr3wrXsEE0kbukZ2CJRdJDS?w=500&auto=format', 'null', 2121364, 738706, false, false, 84, 295, 1318, 2441716, '342.11%', '-19.84%', '28.71%', 8.2937, 34.1092, 118.2131, 447503.9744, 0.29, 0.0987, 0.1156, 0, 0.1833, '174.93%', '78.4%', '24.41%', '1,117.51%', '43.02%', '60.12%', 225925.266),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x524cab2ec69124574082676e6f654a18df49a048', 'Lil Pudgys', 'LP', 'https://i.seadn.io/s/raw/files/649289b91d3d0cefccfe6b9c7f83f471.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x524cab2ec69124574082676e6f654a18df49a048/3826365:about:media:6efd80cc-0c7c-4233-83d4-5375c60f89eb.png?w=500&auto=format', 21905, 9850, false, true, 82, 453, 2142, 156657, '-11.83%', '28.33%', '-61.09%', 87.6926, 494.4035, 2407.681, 134954.4981, 1.0697, 1.0694, 1.0914, 0, 0.8615, '-0.86%', '-10.88%', '11.2%', '-12.59%', '14.36%', '-56.73%', 24559.886),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xb6a37b5d14d502c3ab0ae6f3a0e058bc9517786e', ',Azuki Elementals', 'ELEM', 'https://i.seadn.io/gcs/files/bbaf43ee4a02d5affb7e8fc186d0bdb5.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/79bc14c2aae31bcbfd428662e27541ad.jpg?w=500&auto=format', 17605, 6393, false, true, 76, 352, 2336, 94156, '55.1%', '-54.93%', '-63.55%', 21.6174, 113.7616, 798.0836, 78276.179, 0.238, 0.2844, 0.3232, 0, 0.8313, '-9.17%', '9.34%', '7.02%', '40.89%', '-50.73%', '-60.98%', 5665.289),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x74f70713b0515e9f520d6c764352e45e227839b7', 'MetaWinners', 'MW', 'https://img.reservoir.tools/images/v2/mainnet/hc%2BnPcLmWxs%2FDW99DlBQ42k40ZoyYV5jCIms5qHjwvsJTzlw%2FEFEd9KxuktyBPBp0Vqi4oS1gxRDZeVfjbzp0HPiz1a56Ru0TJjr8abEKQX9co15SUMJIHfzghqi0tQrJUD1sdlwa3ZuIue8IL768Je44sKwlx7DhAJ0RfUJY2jTkV909NZzpMfbbR8n%2FN3bCaJEBSIM4LTlSHHWwHws3T6U0c56KUlKy3Liest1962DGTzb1GuFM4FsJG9xYvVKfWZqwHhKDo4p4lMNh35ChA%3D%3D.gif?width=250', '', 10000, 1461, false, false, 70, 368, 1506, 17289, '191.67%', '16.09%', '-33.86%', 12.1952, 60.033, 238.5815, 1851.7159, 0.13, 0.1742, 0.1631, 0.14, 0.1071, '3.51%', '6.12%', '-0.5%', '201.85%', '23.23%', '-34.19%', 1616),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xb8ea78fcacef50d41375e44e6814ebba36bb33c4', 'Good Vibes Club', 'GVC', '', 'null', 6953, 2222, false, false, 62, 506, 8648, 8648, '19.23%', '-42.57%', '100%', 21.9368, 176.7016, 3048.4378, 3048.4378, 0.249, 0.3538, 0.3492, 0.0894, 0.3525, '12%', '-17.68%', '100%', '33.55%', '-52.72%', '100%', 2540.6262),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x790b2cf29ed4f310bf7641f013c65d4560d28371', 'Otherdeed Expanded', 'EXP', 'https://i.seadn.io/gcs/files/9583ab4792a83cd81d5075b59514a34a.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/6b321a0d888251dfb2608481c7498160.png?w=500&auto=format', 55347, 12564, false, true, 59, 468, 1424, 34570, '-31.4%', '50.48%', '15.3%', 13.4643, 105.6159, 363.897, 23596.6967, 0.1717, 0.2282, 0.2257, 0, 0.6826, '6.69%', '-31.77%', '30.29%', '-26.81%', '2.67%', '50.28%', 14179.9014),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xd887090fc6f9af10abe6cf287ac8011a3cb55a65', 'Quills Adventure', 'QA', '', 'null', 3333, 2500, false, false, 53, 373, 1506, 1506, '60.61%', '-67.08%', '100%', 14.3762, 85.16, 378.9667, 378.9667, 0.3, 0.2712, 0.2283, 0.2986, 0.2516, '7.88%', '-11.96%', '100%', '73.28%', '-71.01%', '100%', 754.9245),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x3bfb2f2b61be8f2f147f5f53a906af00c263d9b3', '2049 // Reflections', 'FREYSA', 'https://i.seadn.io/s/raw/files/9286a0e35691ea592d239c66cd388fc0.png?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0x3bfb2f2b61be8f2f147f5f53a906af00c263d9b3/34062070:about:media:732d1cae-0bbf-49c2-b265-4ce2759933cb.png?w=500&auto=format', 2049, 1089, false, true, 53, 119, 349, 3254, '2,550%', '128.85%', '10.09%', 3.4139, 10.4692, 40.2338, 1254.2976, 0.0898, 0.0644, 0.088, 0.34, 0.3855, '-23.42%', '-32.15%', '-35.98%', '1,929.67%', '55.21%', '-29.54%', 184.2051),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xef0182dc0574cd5874494a120750fd222fdb909a', 'RumbleKongLeague', 'RKL', 'https://i.seadn.io/s/raw/files/866ed37820afd3d81fd2d942edbe5c0d.jpg?w=500&auto=format', 'https://i.seadn.io/s/primary-drops/0xef0182dc0574cd5874494a120750fd222fdb909a/830988:about:media:d27ddcfc-65bb-4b64-bba1-58bc3e305644.png?w=500&auto=format', 10000, 2564, false, true, 52, 151, 572, 22060, '246.67%', '16.15%', '56.28%', 3.2813, 10.3483, 48.111, 20760.2053, 0.0568, 0.0631, 0.0685, 0, 0.9411, '-18.48%', '-2.84%', '-59.08%', '182.6%', '12.99%', '-36.02%', 681),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x3396186436270488f49e723ba57fc93429b59128', 'GNOMA', 'GNOMA', 'https://img.reservoir.tools/images/v2/mainnet/7%2FrdF%2Fe%2F0iXY8HduhRCoIehkmFeXPeOQQFbbmIPfjCYtvMFrmqdAjfOCs7ouugyS6AeAExD8cTtNLoGP7wOOuLb6unjNSORKembDoHfuTXeQ3KNMBlKeMXiNYv5kS9AcjjVTWCaj0u3%2FSv%2BVJZH5ZPH4H7VfDPM440U0K%2BOBPF53AVkk1rpVsOpf3ToP0xPFoSBCZL5frcarw2FBKUYm9TbIInIfvIy8Zx0I8aEldLI%3D.png?width=250', '', 3233, 1501, false, false, 52, 382, 1544, 1602, '33.33%', '-9.05%', '2,608.77%', 1.024, 11.8994, 34.9009, 35.7533, 0.02, 0.0197, 0.0312, 0.0023, 0.0223, '-19.26%', '40.54%', '54.79%', '7.74%', '27.74%', '4,089.78%', 96.3434),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xd93ec495fabbdecd6dfa45bc60f9b634874b634b', 'Jimmy', 'JIMMY', '', 'null', 10000, 3882, false, false, 52, 310, 2970, 2970, '26.83%', '-33.62%', '100%', 1.1001, 6.9357, 102.8158, 102.8158, 0.0235, 0.0212, 0.0224, 0.0282, 0.0346, '7.07%', '-11.81%', '100%', '35.41%', '-41.43%', '100%', 248),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x8a90cab2b38dba80c64b7734e58ee1db38b8992e', 'Doodles', 'DOODLE', 'https://i.seadn.io/s/raw/files/e663a85a2900fdd4bfe8f34a444b72d3.jpg?w=500&auto=format', 'https://i.seadn.io/gae/svc_rQkHVGf3aMI14v3pN-ZTI7uDRwN-QayvixX-nHSMZBgb1L1LReSg1-rXj4gNLJgAB0-yD8ERoT-Q2Gu4cy5AuSg-RdHF9bOxFDw?w=500&auto=format', 10000, 3869, false, true, 50, 245, 869, 78674, '19.05%', '-12.5%', '-75.44%', 138.9356, 691.0157, 2541.9257, 382228.0662, 2.799, 2.7787, 2.8205, 0, 4.8584, '5.81%', '-5.26%', '-26.91%', '25.97%', '-17.11%', '-82.05%', 28796),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x9370045ce37f381500ac7d6802513bb89871e076', 'Ape Hater Club', 'AHC', 'https://i.seadn.io/gcs/files/8adc94c7acb060dc2063d99b649b6afa.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/e762fd5539f2b50fd06c4ce9db8b1377.gif?w=500&auto=format', 12222, 2170, false, true, 49, 98, 549, 17370, '716.67%', '-47.59%', '49.18%', 0.3665, 0.9927, 8.7597, 1636.3764, 0.01, 0.0075, 0.0101, 0, 0.0942, '-37.5%', '-16.53%', '22.14%', '409.03%', '-56.31%', '81.1%', 127.1088),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x60e4d786628fea6478f785a6d7e704777c86a7c6', 'MutantApeYachtClub', 'MAYC', 'https://i.seadn.io/gae/lHexKRMpw-aoSyB1WdFBff5yfANLReFxHzt1DOj_sg7mS14yARpuvYcUtsyyx-Nkpk6WTcUPFoG53VnLJezYi8hAs0OxNZwlw6Y-dmI?w=500&auto=format', 'https://i.seadn.io/gae/5c-HcdLMinTg3LvEwXYZYC-u5nN22Pn5ivTPYA4pVEsWJHU1rCobhUlHSFjZgCHPGSmcGMQGCrDCQU8BfSfygmL7Uol9MRQZt6-gqA?w=500&auto=format', 19550, 11763, false, true, 49, 319, 1033, 157823, '-33.78%', '29.67%', '-35.07%', 118.242, 799.484, 2541.6597, 1371791.9342, 2.35, 2.4131, 2.5062, 0, 8.692, '-3.65%', '-3.99%', '12.55%', '-36.2%', '24.5%', '-26.92%', 49911.15),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x306b1ea3ecdf94ab739f1910bbda052ed4a9f949', 'Beanz', 'BEANZ', 'https://i.seadn.io/gae/_R4fuC4QGYd14-KwX2bD1wf-AWjDF2VMabfqWFJhIgiN2FnAUpnD5PLdJORrhQ8gly7KcjhQZZpuzYVPF7CDSzsqmDh97z84j2On?w=500&auto=format', 'https://i.seadn.io/gae/WRcl2YH8E3_7884mcJ0DRN7STGqA8xZQKd-0MFmPftlxUR6i1xB9todMXRW2M6SIpXKAZ842UqKDm1UrkKG8nr7l9NjCkIw-GLQSFQ?w=500&auto=format', 19950, 8323, false, true, 48, 287, 1274, 166158, '23.08%', '-9.18%', '-60.88%', 6.8791, 51.3831, 207.4935, 218436.793, 0.1248, 0.1433, 0.179, 0, 1.3146, '-5.29%', '20.78%', '5.03%', '16.59%', '9.75%', '-58.94%', 3327.66),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x7fb2d396a3cc840f2c4213f044566ed400159b40', 'Jirasan', 'JIRASAN', 'https://i.nfte.ai/ca/i1/8006297.avif', 'null', 10000, 2358, false, false, 47, 203, 965, 11280, '62.07%', '1.5%', '-54.27%', 13.8995, 55.9899, 321.3768, 6129.8619, 0.3089, 0.2957, 0.2758, 0.3, 0.5434, '5.46%', '-7.08%', '-23.66%', '70.94%', '-5.69%', '-65.09%', 2813),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xa866dab55af2bcef47980bb311271f7132965f63', 'An1 Tokens', '', 'https://i.seadn.io/gcs/files/736e2db56aae628f129c60718e55ff59.png?w=500&auto=format', 'https://i.seadn.io/gcs/files/736e2db56aae628f129c60718e55ff59.png?w=500&auto=format', 10, 1685, false, false, 45, 155, 265, 569, '-31.82%', '307.89%', '22.12%', 0.0003, 0.0018, 0.0113, 0.2798, 0, 0, 0, 0, 0.0005, '0%', '-100%', '0%', '-40%', '-80.65%', '117.31%', 0.001),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xd47d8672e45a7204057baaa3622a3fa276d651e3', 'DickButtVerse', '3D=3B', 'https://i.seadn.io/gcs/files/3c305745935763b08c2d094cf6f9a61e.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/47b782ac2acc219e2542714c7ca169ea.png?w=500&auto=format', 5366, 1148, false, false, 45, 104, 153, 3961, '1,025%', '141.86%', '15,200%', 0.0219, 0.0409, 0.0493, 80.5377, 0.0003, 0.0005, 0.0004, 0, 0.0203, '-84.85%', '300%', '0%', '68.46%', '581.67%', '16,333.33%', 1.6098),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x963590fabdc1333d03bc3af42a6b2ab33e21e2ee', 'Immortals', '$SGI', 'https://i.seadn.io/gcs/files/65b163eaee2f95a2c25bfbd9f2c898ca.gif?w=500&auto=format', 'https://i.seadn.io/gcs/files/19253883b182960ffa6321eeebabecb2.png?w=500&auto=format', 9999, 1716, false, true, 44, 153, 1327, 34854, '1,000%', '80%', '38.23%', 3.1265, 10.353, 110.9968, 1440.6678, 0.0697, 0.0711, 0.0677, 0, 0.0413, '-5.95%', '-22.63%', '50.9%', '934.58%', '39.2%', '108.75%', 686.9313),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x5361fc8bd90fe2e3cd82e5326ddbe5aa4765b116', 'Vampire Punks', 'VPunks', 'https://img.reservoir.tools/images/v2/mainnet/z9JRSpLYGu7%2BCZoKWtAuAGdWptlhC4UVqExq%2BIguqyGFnf56DFV5L%2B4xyJGVphxd3Ywd0exQLHQScqin69vdSH5ZYUa0gP9IacPBLeuDzKcQxcvxnAC6nllhSTqILGokZSl4%2BNwiXPy56x9YiQGc5tOA7gG5TG8rvN5YU3mKej%2BanKFRYekVlECuWUX9Fbk0RGsQb1c9Z4atzjIl3O81ag%3D%3D?width=250', '', 9241, 3499, false, false, 42, 135, 225, 225, '600%', '237.5%', '100%', 0.0116, 0.022, 0.0462, 0.0462, 0.0002, 0.0003, 0.0002, 0.0004, 0.0002, '200%', '100%', '100%', '3,766.67%', '400%', '100%', 0.9241),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xb66a603f4cfe17e3d27b87a8bfcad319856518b8', 'Rarible', 'RARI', 'https://i.seadn.io/gae/FG0QJ00fN3c_FWuPeUr9-T__iQl63j9hn5d6svW8UqOmia5zp3lKHPkJuHcvhZ0f_Pd6P2COo9tt9zVUvdPxG_9BBw?w=500&auto=format', 'https://i.seadn.io/gcs/static/banners/rarible-banner4.png?w=500&auto=format', 16459, 26412, false, false, 42, 159, 802, 28047, '23.53%', '-55.96%', '449.32%', 0.0002, 0.9235, 2.3844, 6848.0744, 0, 0, 0.0058, 0, 0.2442, '-100%', '544.44%', '0%', '-99.85%', '181.55%', '441.66%', 0),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x7011ee079f579eb313012bddb92fd6f06fa43335', 'Yumemono ☆ 夢物', 'mono', '', 'null', 5200, 1423, false, false, 41, 418, 4369, 4369, '156.25%', '-75.78%', '100%', 1.776, 14.2854, 269.5803, 269.5803, 0.0239, 0.0433, 0.0342, 0.069, 0.0617, '-42.42%', '-48.1%', '100%', '47.61%', '-87.45%', '100%', 292.24),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x9378368ba6b85c1fba5b131b530f5f5bedf21a18', 'VeeFriends Series 2', 'VF2', 'https://i.seadn.io/s/raw/files/7c968bade1414b10fb5fd77d7c82e565.jpg?w=500&auto=format', 'https://i.seadn.io/gae/l7-Zz6ZYWJBu4kkFBxnHchfzg3uJlwmCZsfJt7QMJuiX1v7SQgUp-PveFFPi-Zd8J4m0ROQsGFgDcs96OXZu7JOIqC60kzTu7sQGAA?w=500&auto=format', 55555, 20045, false, true, 40, 435, 1087, 51784, '-63.3%', '96.83%', '144.27%', 5.3158, 47.2035, 124.3292, 35231.512, 0.0789, 0.1329, 0.1085, 0, 0.6804, '42.75%', '6.48%', '0.79%', '-47.64%', '109.65%', '146.19%', 5988.829),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0xbbbba1ee822c9b8fc134dea6adfc26603a9cbbbb', 'BitmapPunks', 'BMP', 'https://img.reservoir.tools/images/v2/mainnet/OZOACYlgslkWSExEBQXm4GqPs5dvboMeVVw%2Bdm%2FJmFbLudhgGnQMkH63A9c8bdfPcwx7MsLif7Yhy4OlXGMrda72dohGRnKij5MswoM%2F5SKX1a%2Fs9u%2Fo6Mda%2BNRsc6dGW22uJwXWpYxn7I6rd0X%2BStcBBJ4ARdbJu8BnrLj5pFOhpfXObfbsSQs2rlgSfbZb?width=250', '', 2099775, 15107, false, false, 39, 238, 4084, 43341, '2.63%', '-83.95%', '-42.66%', 0.0266, 0.7084, 17.9409, 81.1789, 0.0007, 0.0007, 0.003, 0.002, 0.0019, '0%', '-58.33%', '83.33%', '-6.01%', '-93.4%', '3.8%', 23727.4575),(CAST('2025-04-10 15:25:11' AS TIMESTAMP), '0x76be3b62873462d2142405439777e971754e8e77', 'parallel', 'LL', 'https://i.seadn.io/gae/Nnp8Pdo6EidK7eBduGnAn_JBvFsYGhNGMJ_fHJ_mzGMN_2Khu5snL5zmiUMcSsIqtANh19KqxXDs0iNq_aYbKC5smO3hiCSw9PlL?w=500&auto=format', 'https://i.seadn.io/gae/YPGHP7VAvzy-MCVU67CV85gSW_Di6LWbp-22LGEb3H6Yz9v4wOdAaAhiswnwwL5trMn8tZiJhgbdGuBN9wvpH10d_oGVjVIGM-zW5A?w=500&auto=format', 1090, 64085, false, true, 38, 347, 1241, 276492, '8.57%', '30.94%', '-49.61%', 0.7329, 9.0243, 17.6276, 95726.065, 0.0006, 0.0193, 0.026, 0, 0.3462, '6.63%', '160%', '82.05%', '15.58%', '240.75%', '-8.62%', 22.454)
;
