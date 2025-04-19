-- 完成NFT交易表字段重命名的最后步骤
SET 'sql-client.execution.result-mode'='TABLEAU';
-- 设置执行参数
SET 'execution.checkpointing.interval' = '10s';
SET 'table.local-time-zone' = 'Asia/Shanghai';
SET 'pipeline.name' = 'Finalize_Transaction_Fields_Rename';

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

-- 删除原表
DROP TABLE IF EXISTS ods_collection_transaction_inc;

-- 重命名新表为原表名
ALTER TABLE ods_collection_transaction_inc_new RENAME TO ods_collection_transaction_inc;

-- 验证重命名成功
SHOW TABLES LIKE 'ods_collection_transaction%';

