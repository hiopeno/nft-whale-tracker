package org.bigdatatechcir.whale.api.test;

import org.bigdatatechcir.whale.api.service.PaimonDataLakeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * 数据湖访问测试类
 * 使用方法：在启动应用时添加 --spring.profiles.active=test 参数
 * 例如：java -jar target/nft-whale-tracker-api-1.0.0.jar --server.port=8081 --spring.profiles.active=test
 */
@Component
@Profile("test")
public class WhaleDataTest implements CommandLineRunner {

    @Autowired
    private PaimonDataLakeService dataLakeService;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("======== 开始测试数据湖访问 ========");
        
        // 测试数据库连接
        testConnection();
        
        // 测试获取交易数据
        testWhaleTransactions();
        
        // 测试获取追踪列表
        testWhaleTrackingList();
        
        System.out.println("======== 数据湖访问测试完成 ========");
    }
    
    private void testConnection() {
        System.out.println("\n=== 测试数据湖连接 ===");
        try {
            List<String> databases = dataLakeService.listDatabases();
            System.out.println("获取到数据库列表: " + databases);
            
            if (!databases.isEmpty()) {
                String firstDb = "ads";
                List<String> tables = dataLakeService.listTables(firstDb);
                System.out.println("数据库 " + firstDb + " 中的表: " + tables);
                
                if (!tables.isEmpty()) {
                    String firstTable = tables.get(0);
                    List<Map<String, Object>> schema = dataLakeService.getTableSchema(firstDb, firstTable);
                    System.out.println("表 " + firstTable + " 的结构:");
                    schema.forEach(field -> 
                        System.out.println("  " + field.get("name") + ": " + field.get("type")));
                }
            }
            System.out.println("数据湖连接测试成功");
        } catch (Exception e) {
            System.err.println("数据湖连接测试失败: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void testWhaleTransactions() {
        System.out.println("\n=== 测试获取鲸鱼交易数据 ===");
        try {
            int limit = 5; // 只获取少量数据用于测试
            List<Map<String, Object>> transactions = dataLakeService.getTableData("ads", "ads_whale_transactions", limit);
            System.out.println("获取到 " + transactions.size() + " 条交易记录");
            
            // 打印数据示例
            if (!transactions.isEmpty()) {
                System.out.println("数据示例:");
                transactions.forEach(this::printRecord);
            } else {
                System.out.println("未获取到交易数据");
            }
        } catch (Exception e) {
            System.err.println("获取鲸鱼交易数据失败: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void testWhaleTrackingList() {
        System.out.println("\n=== 测试获取鲸鱼追踪列表 ===");
        try {
            int limit = 5; // 只获取少量数据用于测试
            List<Map<String, Object>> trackingList = dataLakeService.getTableData("ads", "ads_whale_tracking_list", limit);
            System.out.println("获取到 " + trackingList.size() + " 条追踪记录");
            
            // 打印数据示例
            if (!trackingList.isEmpty()) {
                System.out.println("数据示例:");
                trackingList.forEach(this::printRecord);
            } else {
                System.out.println("未获取到追踪数据");
            }
        } catch (Exception e) {
            System.err.println("获取鲸鱼追踪列表失败: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void printRecord(Map<String, Object> record) {
        System.out.println("--------------------");
        record.forEach((key, value) -> System.out.println(key + ": " + value));
    }
} 