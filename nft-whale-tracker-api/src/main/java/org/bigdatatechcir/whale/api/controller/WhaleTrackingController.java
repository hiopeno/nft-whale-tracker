package org.bigdatatechcir.whale.api.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bigdatatechcir.whale.api.service.PaimonDataLakeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/whale-tracking")
@RequiredArgsConstructor
public class WhaleTrackingController {

    private final PaimonDataLakeService dataLakeService;

    /**
     * 获取鲸鱼交易记录 (ads_whale_transactions)
     */
    @GetMapping("/transactions")
    public ResponseEntity<List<Map<String, Object>>> getTransactions(
            @RequestParam(defaultValue = "100") int limit) {
        
        log.debug("请求获取鲸鱼交易列表: limit={}", limit);
        
        String database = "ads";
        String table = "ads_whale_transactions";
        
        // 检查表是否存在
        if (!dataLakeService.tableExists(database, table)) {
            log.warn("表 {}.{} 不存在，无法获取鲸鱼交易数据", database, table);
            return ResponseEntity.ok(Collections.emptyList());
        }
        
        // 获取原始交易数据 - 从ads_whale_transactions表
        List<Map<String, Object>> transactions = dataLakeService.getTableData(database, table, limit);
        
        return ResponseEntity.ok(transactions);
    }

    /**
     * 获取鲸鱼追踪列表 (ads_whale_tracking_list)
     */
    @GetMapping("/tracking-list")
    public ResponseEntity<List<Map<String, Object>>> getWhaleTrackingList(
            @RequestParam(defaultValue = "100") int limit) {
        
        log.debug("请求获取鲸鱼追踪列表: limit={}", limit);
        
        String database = "ads";
        String table = "ads_whale_tracking_list";
        
        // 检查表是否存在
        if (!dataLakeService.tableExists(database, table)) {
            log.warn("表 {}.{} 不存在，无法获取鲸鱼追踪数据", database, table);
            return ResponseEntity.ok(Collections.emptyList());
        }
        
        List<Map<String, Object>> result = dataLakeService.getTableData(database, table, limit);
        
        return ResponseEntity.ok(result);
    }

    /**
     * 测试数据湖连接
     */
    @GetMapping("/test-connection")
    public ResponseEntity<Map<String, Object>> testPaimonConnection() {
        log.info("测试Paimon数据湖连接");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            // 获取数据库列表
            List<String> databases = dataLakeService.listDatabases();
            result.put("databases", databases);
            
            // 如果有数据库，尝试获取第一个数据库的表
            if (!databases.isEmpty()) {
                String firstDb = databases.get(0);
                List<String> tables = dataLakeService.listTables(firstDb);
                result.put("tables", tables);
                result.put("database", firstDb);
                
                // 如果有表，尝试获取第一个表的结构
                if (!tables.isEmpty()) {
                    String firstTable = tables.get(0);
                    List<Map<String, Object>> schema = dataLakeService.getTableSchema(firstDb, firstTable);
                    result.put("schema", schema);
                    result.put("table", firstTable);
                    
                    // 尝试获取表数据
                    List<Map<String, Object>> data = dataLakeService.getTableData(firstDb, firstTable, 5);
                    result.put("data", data);
                }
            }
            
            result.put("status", "success");
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("测试Paimon数据湖连接失败", e);
            result.put("status", "error");
            result.put("error", e.getMessage());
            return ResponseEntity.status(500).body(result);
        }
    }
} 