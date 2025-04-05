package com.nft.whale.api.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.flink.table.api.ResultKind;
import org.apache.flink.table.api.TableEnvironment;
import org.apache.flink.table.api.TableResult;
import org.apache.flink.types.Row;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * Paimon查询服务
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class PaimonQueryService {
    
    private final TableEnvironment tableEnvironment;
    
    /**
     * 异步执行SQL查询
     *
     * @param sql SQL语句
     * @return 查询结果列表
     */
    public CompletableFuture<List<Map<String, Object>>> executeQueryAsync(String sql) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                return executeQuery(sql);
            } catch (Exception e) {
                log.error("执行Paimon查询失败: {}", e.getMessage(), e);
                throw new RuntimeException("执行Paimon查询失败", e);
            }
        });
    }

    /**
     * 执行SQL查询
     *
     * @param sql SQL语句
     * @return 查询结果列表
     */
    public List<Map<String, Object>> executeQuery(String sql) {
        log.info("执行Paimon SQL查询: {}", sql);
        TableResult tableResult = tableEnvironment.executeSql(sql);
        
        // 如果不是查询结果，直接返回空列表
        if (tableResult.getResultKind() != ResultKind.SUCCESS_WITH_CONTENT) {
            return new ArrayList<>();
        }
        
        List<Map<String, Object>> resultList = new ArrayList<>();
        String[] fieldNames = tableResult.getTableSchema().getFieldNames();
        
        try {
            // 使用迭代器获取结果
            for (Row row : tableResult.collect()) {
                Map<String, Object> rowMap = new HashMap<>();
                for (int i = 0; i < fieldNames.length; i++) {
                    String fieldName = fieldNames[i];
                    Object value = row.getField(i);
                    rowMap.put(fieldName, value);
                }
                resultList.add(rowMap);
                
                // 防止结果太多，设置上限
                if (resultList.size() >= 1000) {
                    log.warn("查询结果超过1000条，已截断");
                    break;
                }
            }
        } catch (Exception e) {
            log.error("处理查询结果失败: {}", e.getMessage(), e);
            throw new RuntimeException("处理查询结果失败", e);
        }
        
        return resultList;
    }
    
    /**
     * 查询ODS层最近的NFT交易数据
     *
     * @param limit 限制条数
     * @return 交易数据列表
     */
    public List<Map<String, Object>> queryRecentNFTTransactions(int limit) {
        String sql = String.format("USE ods; SELECT * FROM ods_nft_transaction_inc ORDER BY transaction_time DESC LIMIT %d", limit);
        return executeQuery(sql);
    }
    
    /**
     * 查询鲸鱼钱包数据
     *
     * @param limit 限制条数
     * @return 鲸鱼钱包数据列表
     */
    public List<Map<String, Object>> queryWhaleWallets(int limit) {
        String sql = String.format("USE dws; SELECT * FROM dws_whale_wallet ORDER BY total_value DESC LIMIT %d", limit);
        return executeQuery(sql);
    }
    
    /**
     * 查询热门NFT集合
     *
     * @param limit 限制条数
     * @return 热门NFT集合列表
     */
    public List<Map<String, Object>> queryHotNFTCollections(int limit) {
        String sql = String.format("USE dws; SELECT * FROM dws_nft_collection_stats ORDER BY transaction_count DESC LIMIT %d", limit);
        return executeQuery(sql);
    }
} 