package org.bigdatatechcir.whale.api.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bigdatatechcir.whale.api.service.PaimonDataLakeService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 数据湖通用查询API控制器
 * 提供对Paimon数据湖中任意表的查询支持
 */
@Slf4j
@RestController
@RequestMapping("/data")
@RequiredArgsConstructor
public class DataLakeController {

    private final PaimonDataLakeService dataLakeService;

    /**
     * 获取所有数据库列表
     */
    @GetMapping("/databases")
    public ResponseEntity<?> getDatabases() {
        log.debug("请求获取数据库列表");
        try {
            List<String> databases = dataLakeService.listDatabases();
            return ResponseEntity.ok(databases);
        } catch (Exception e) {
            log.error("获取数据库列表失败", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * 获取指定数据库中的所有表
     */
    @GetMapping("/tables/{database}")
    public ResponseEntity<?> getTables(@PathVariable String database) {
        log.debug("请求获取数据库 {} 的表列表", database);
        try {
            List<String> tables = dataLakeService.listTables(database);
            return ResponseEntity.ok(tables);
        } catch (Exception e) {
            log.error("获取表列表失败", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * 获取指定表的字段信息
     */
    @GetMapping("/schema/{database}/{table}")
    public ResponseEntity<?> getTableSchema(@PathVariable String database, @PathVariable String table) {
        log.debug("请求获取表结构: database={}, table={}", database, table);
        try {
            List<Map<String, Object>> schema = dataLakeService.getTableSchema(database, table);
            return ResponseEntity.ok(schema);
        } catch (Exception e) {
            log.error("获取表结构失败", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * 查询指定表的数据
     */
    @GetMapping("/query/{database}/{table}")
    public ResponseEntity<?> queryTableData(
            @PathVariable String database,
            @PathVariable String table,
            @RequestParam(defaultValue = "10") int limit) {
        log.debug("请求查询表数据: database={}, table={}, limit={}", database, table, limit);
        
        try {
            // 检查表是否存在
            if (!dataLakeService.tableExists(database, table)) {
                Map<String, String> error = new HashMap<>();
                error.put("error", String.format("表 %s.%s 不存在", database, table));
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
            }
            
            List<Map<String, Object>> data = dataLakeService.getTableData(database, table, limit);
            return ResponseEntity.ok(data);
        } catch (Exception e) {
            log.error("查询表数据失败", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * 获取鲸鱼交易列表数据
     */
    @GetMapping("/whale/transactions")
    public ResponseEntity<?> getWhaleTransactions(@RequestParam(defaultValue = "10") int limit) {
        log.debug("请求获取鲸鱼交易列表，条数: {}", limit);
        try {
            List<Map<String, Object>> transactions = dataLakeService.getWhaleTransactions(limit);
            return ResponseEntity.ok(transactions);
        } catch (Exception e) {
            log.error("获取鲸鱼交易列表失败", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * 获取鲸鱼跟踪列表
     */
    @GetMapping("/whale/tracking")
    public ResponseEntity<?> getWhaleTrackingList(@RequestParam(defaultValue = "10") int limit) {
        log.debug("请求获取鲸鱼跟踪列表，条数: {}", limit);
        try {
            List<Map<String, Object>> trackingList = dataLakeService.getWhaleTrackingList(limit);
            return ResponseEntity.ok(trackingList);
        } catch (Exception e) {
            log.error("获取鲸鱼跟踪列表失败", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }
} 