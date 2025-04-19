-- NFT交易数据记录统计查询
SET 'sql-client.execution.result-mode'='TABLEAU';
-- 设置执行参数
SET 'execution.checkpointing.interval' = '10s';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'pipeline.name' = 'NFT_Transaction_Count_Query';

-- 增加内存配置，避免OOM
SET 'jobmanager.memory.process.size' = '4096m';
SET 'taskmanager.memory.process.size' = '8192m';
SET 'taskmanager.memory.jvm-metaspace.size' = '512m';
SET 'taskmanager.memory.task.off-heap.size' = '1024m';

-- 使用Paimon Catalog
CREATE CATALOG paimon_hive WITH (
    'type' = 'paimon',
    'metastore' = 'hive',
    'uri' = 'thrift://192.168.254.133:9083',
    'hive-conf-dir' = '/opt/software/apache-hive-3.1.3-bin/conf',
    'hadoop-conf-dir' = '/opt/software/hadoop-3.1.3/etc/hadoop',
    'warehouse' = 'hdfs:////user/hive/warehouse'
);

USE CATALOG paimon_hive;
USE ods;

-- 查询记录总数
SELECT COUNT(*) AS total_records FROM ods_collection_transaction_inc;

-- 查询按合约地址分组的记录数（Top 10）
SELECT 
    contract_address,
    contract_name,
    COUNT(*) AS transaction_count
FROM ods_collection_transaction_inc
GROUP BY contract_address, contract_name
ORDER BY transaction_count DESC
LIMIT 10;

-- 查询最新的10条交易记录
SELECT
    record_time,
    hash,
    contract_address,
    contract_name,
    token_id,
    event_type,
    trade_price,
    trade_symbol
FROM ods_collection_transaction_inc
ORDER BY record_time DESC
LIMIT 10; 