package com.nft.whale.api.config;

import lombok.Data;
import org.apache.flink.api.common.restartstrategy.RestartStrategies;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.TableEnvironment;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Paimon数据湖配置
 */
@Configuration
@Data
public class PaimonConfig {

    @Value("${paimon.catalog.type}")
    private String catalogType;

    @Value("${paimon.catalog.metastore}")
    private String metastore;

    @Value("${paimon.catalog.uri}")
    private String uri;

    @Value("${paimon.catalog.hive-conf-dir}")
    private String hiveConfDir;

    @Value("${paimon.catalog.hadoop-conf-dir}")
    private String hadoopConfDir;

    @Value("${paimon.catalog.warehouse}")
    private String warehouse;

    @Value("${flink.home}")
    private String flinkHome;

    /**
     * 创建Flink Stream执行环境
     */
    @Bean
    public StreamExecutionEnvironment streamExecutionEnvironment() {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setRestartStrategy(RestartStrategies.fixedDelayRestart(3, 5000));
        env.setParallelism(1);
        return env;
    }

    /**
     * 创建Flink Table环境
     */
    @Bean
    public TableEnvironment tableEnvironment() {
        EnvironmentSettings settings = EnvironmentSettings.newInstance().inBatchMode().build();
        TableEnvironment tableEnv = TableEnvironment.create(settings);
        
        // 配置Paimon Catalog
        tableEnv.executeSql(String.format(
                "CREATE CATALOG paimon_hive WITH (" +
                        "'type' = '%s', " +
                        "'metastore' = '%s', " +
                        "'uri' = '%s', " +
                        "'hive-conf-dir' = '%s', " +
                        "'hadoop-conf-dir' = '%s', " +
                        "'warehouse' = '%s'" +
                        ")",
                catalogType, metastore, uri, hiveConfDir, hadoopConfDir, warehouse));
        
        // 使用Paimon Catalog
        tableEnv.executeSql("USE CATALOG paimon_hive");
        
        return tableEnv;
    }

    /**
     * 创建Stream Table环境（用于流式查询）
     */
    @Bean
    public StreamTableEnvironment streamTableEnvironment(StreamExecutionEnvironment env) {
        return StreamTableEnvironment.create(env);
    }
} 