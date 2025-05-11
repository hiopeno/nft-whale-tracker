-- 鲸鱼钱包地址维度表 - DIM层重构
-- 设置执行参数
SET
    'execution.checkpointing.interval' = '10s';

SET
    'table.exec.state.ttl' = '8640000';

SET
    'table.local-time-zone' = 'Asia/Shanghai';

-- 设置为批处理模式
SET
    'execution.runtime-mode' = 'batch';

-- 设置忽略NULL值
SET
    'table.exec.sink.not-null-enforcer' = 'DROP';

-- 设置Paimon sink配置
SET
    'table.exec.sink.upsert-materialize' = 'NONE';

-- 添加重启策略配置
SET
    'restart-strategy' = 'fixed-delay';

SET
    'restart-strategy.fixed-delay.attempts' = '3';

SET
    'restart-strategy.fixed-delay.delay' = '10s';

-- 优化资源配置
SET
    'jobmanager.memory.process.size' = '2g';

SET
    'taskmanager.memory.process.size' = '4g';

SET
    'taskmanager.numberOfTaskSlots' = '2';

/* 创建Paimon Catalog */
CREATE CATALOG paimon_hive
WITH
    (
        'type' = 'paimon',
        'metastore' = 'hive',
        'uri' = 'thrift://192.168.254.133:9083',
        'hive-conf-dir' = '/opt/software/apache-hive-3.1.3-bin/conf',
        'hadoop-conf-dir' = '/opt/software/hadoop-3.1.3/etc/hadoop',
        'warehouse' = 'hdfs:////user/hive/warehouse'
    );

USE CATALOG paimon_hive;

CREATE DATABASE IF NOT EXISTS dim;

USE dim;

-- 创建鲸鱼钱包地址维度表（精简版）
CREATE TABLE
    IF NOT EXISTS dim_whale_address (
        wallet_address VARCHAR(255), -- 钱包地址
        first_track_date DATE, -- 首次追踪日期
        last_active_date DATE, -- 最后活跃日期
        is_whale BOOLEAN, -- 是否为鲸鱼
        whale_type VARCHAR(50), -- 鲸鱼类型(追踪中/聪明/愚蠢)
        labels VARCHAR(500), -- 标签(JSON格式)
        status VARCHAR(20), -- 状态(活跃/不活跃)
        etl_time TIMESTAMP, -- ETL处理时间
        PRIMARY KEY (wallet_address) NOT ENFORCED
    )
WITH
    (
        'bucket' = '8',
        'bucket-key' = 'wallet_address',
        'file.format' = 'parquet',
        'merge-engine' = 'deduplicate',
        'changelog-producer' = 'lookup',
        'compaction.min.file-num' = '5',
        'compaction.max.file-num' = '50',
        'compaction.target-file-size' = '256MB'
    );

-- 1. 识别新加入的鲸鱼钱包并插入
INSERT INTO
    dim_whale_address
WITH
    potential_whales AS (
        SELECT DISTINCT
            wallet_address,
            MIN(tx_date) AS first_track_date,
            MAX(tx_date) AS last_active_date,
            TRUE AS is_whale,
            'TRACKING' AS whale_type, -- 初始状态为追踪中
            '[]' AS labels, -- 初始无标签
            'ACTIVE' AS status,
            CURRENT_TIMESTAMP AS etl_time
        FROM
            (
                -- 聚合从DWD层获取的交易数据，识别可能的鲸鱼
                SELECT
                    tx_date,
                    from_address AS wallet_address
                FROM
                    dwd.dwd_transaction_clean
                WHERE
                    tx_date >= TIMESTAMPADD (DAY, -30, CURRENT_DATE)
                UNION ALL
                SELECT
                    tx_date,
                    to_address AS wallet_address
                FROM
                    dwd.dwd_transaction_clean
                WHERE
                    tx_date >= TIMESTAMPADD (DAY, -30, CURRENT_DATE)
            ) t
            JOIN (
                -- 关联已知鲸鱼名单
                SELECT
                    account_address
                FROM
                    ods.ods_daily_top30_volume_wallets
                UNION
                SELECT
                    account_address
                FROM
                    ods.ods_top100_balance_wallets
            ) w ON t.wallet_address = w.account_address
        GROUP BY
            wallet_address
    )
SELECT
    *
FROM
    potential_whales pw
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            dim_whale_address dw
        WHERE
            dw.wallet_address = pw.wallet_address
    );

-- 2. 更新现有鲸鱼钱包信息
-- 先删除要更新的记录
DELETE FROM dim_whale_address
WHERE
    wallet_address IN (
        SELECT DISTINCT
            dw.wallet_address
        FROM
            dim_whale_address dw
            JOIN dwd.dwd_whale_transaction_detail wtd ON (
                dw.wallet_address = wtd.from_address
                OR dw.wallet_address = wtd.to_address
            )
        WHERE
            wtd.tx_date > dw.last_active_date
    );

-- 然后重新插入更新后的数据
INSERT INTO
    dim_whale_address
SELECT
    dw.wallet_address,
    dw.first_track_date,
    GREATEST (
        dw.last_active_date,
        COALESCE(MAX(wtd.tx_date), dw.last_active_date)
    ) AS last_active_date,
    dw.is_whale,
    CASE
    -- 对新鲸鱼：追踪7天后进行评估
    -- 对已分类鲸鱼：每周周日重新评估
        WHEN (
            dw.whale_type = 'TRACKING'
            AND TIMESTAMPDIFF (DAY, dw.first_track_date, CURRENT_DATE) >= 7
        )
        OR ( TIMESTAMPDIFF (DAY, dw.first_track_date, CURRENT_DATE) >= 7) -- 周日，1代表周日，2代表周一，以此类推
        THEN
        -- 基于7天成功率和ROI指标综合判断鲸鱼类型
        CASE
        -- 聪明鲸鱼：成功率≥75% 且 7天ROI为正
            WHEN EXISTS (
                SELECT
                    1
                FROM
                    dws.dws_whale_daily_stats stats
                    JOIN (
                        -- 获取7天ROI
                        SELECT
                            wallet_address,
                            CASE
                                WHEN SUM(
                                    CASE
                                        WHEN stat_date >= TIMESTAMPADD (DAY, -7, CURRENT_DATE) THEN daily_profit_eth
                                        ELSE 0
                                    END
                                ) > 0 THEN AVG(
                                    CASE
                                        WHEN stat_date >= TIMESTAMPADD (DAY, -7, CURRENT_DATE) THEN daily_roi_percentage
                                        ELSE NULL
                                    END
                                )
                                ELSE 0
                            END AS roi_7d_percentage
                        FROM
                            dws.dws_whale_daily_stats
                        GROUP BY
                            wallet_address
                    ) roi ON stats.wallet_address = roi.wallet_address
                WHERE
                    stats.wallet_address = dw.wallet_address
                    AND stats.success_rate_7d >= 65
                    AND roi.roi_7d_percentage > 0 -- ROI为正
            ) THEN 'SMART'
            -- 愚蠢鲸鱼：成功率<25% 且 7天ROI为负
            WHEN EXISTS (
                SELECT
                    1
                FROM
                    dws.dws_whale_daily_stats stats
                    JOIN (
                        -- 获取7天ROI
                        SELECT
                            wallet_address,
                            CASE
                                WHEN SUM(
                                    CASE
                                        WHEN stat_date >= TIMESTAMPADD (DAY, -7, CURRENT_DATE) THEN daily_profit_eth
                                        ELSE 0
                                    END
                                ) < 0 THEN AVG(
                                    CASE
                                        WHEN stat_date >= TIMESTAMPADD (DAY, -7, CURRENT_DATE) THEN daily_roi_percentage
                                        ELSE NULL
                                    END
                                )
                                ELSE 0
                            END AS roi_7d_percentage
                        FROM
                            dws.dws_whale_daily_stats
                        GROUP BY
                            wallet_address
                    ) roi ON stats.wallet_address = roi.wallet_address
                WHERE
                    stats.wallet_address = dw.wallet_address
                    AND stats.success_rate_7d < 35
                    AND roi.roi_7d_percentage < 0 -- ROI为负
            ) THEN 'DUMB'
            -- 其他情况继续追踪
            ELSE 'TRACKING'
        END
        ELSE dw.whale_type
    END AS whale_type,
    dw.labels,
   -- CASE
    --    WHEN MAX(wtd.tx_date) >= TIMESTAMPADD (DAY, -7, CURRENT_DATE) THEN 'ACTIVE'
    --    ELSE 'INACTIVE'
   -- END AS status,
   'ACTIVE' AS status,
    CURRENT_TIMESTAMP AS etl_time
FROM
    dim_whale_address dw
    LEFT JOIN dwd.dwd_whale_transaction_detail wtd ON (
        dw.wallet_address = wtd.from_address
        OR dw.wallet_address = wtd.to_address
    )
    AND wtd.tx_date > dw.last_active_date
GROUP BY
    dw.wallet_address,
    dw.first_track_date,
    dw.last_active_date,
    dw.is_whale,
    dw.whale_type,
    dw.labels;