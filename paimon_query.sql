-- 设置结果显示模式
SET 'sql-client.execution.result-mode'='TABLEAU';

-- 创建Paimon Catalog
CREATE CATALOG paimon_hive WITH (
    'type' = 'paimon',
    'metastore' = 'hive',
    'uri' = 'thrift://192.168.254.133:9083',
    'hive-conf-dir' = '/opt/software/apache-hive-3.1.3-bin/conf',
    'hadoop-conf-dir' = '/opt/software/hadoop-3.1.3/etc/hadoop',
    'warehouse' = 'hdfs:////user/hive/warehouse'
);

-- 使用Paimon Catalog
USE CATALOG paimon_hive;

-- 查看所有数据库
SHOW DATABASES;

-- 使用ODS数据库
USE ods;

-- 查看所有表
SHOW TABLES;

-- 查询鲸鱼钱包数据(取10条)
SELECT * FROM ods_nft_transaction_inc LIMIT 1; 