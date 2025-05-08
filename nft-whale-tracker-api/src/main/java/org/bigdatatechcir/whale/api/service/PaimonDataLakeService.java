package org.bigdatatechcir.whale.api.service;

import lombok.extern.slf4j.Slf4j;
import org.apache.paimon.catalog.Catalog;
import org.apache.paimon.catalog.CatalogContext;
import org.apache.paimon.catalog.CatalogFactory;
import org.apache.paimon.catalog.Identifier;
import org.apache.paimon.data.BinaryString;
import org.apache.paimon.data.Decimal;
import org.apache.paimon.data.InternalRow;
import org.apache.paimon.data.Timestamp;
import org.apache.paimon.options.Options;
import org.apache.paimon.reader.RecordReader;
import org.apache.paimon.schema.Schema;
import org.apache.paimon.table.Table;
import org.apache.paimon.table.source.ReadBuilder;
import org.apache.paimon.table.source.Split;
import org.apache.paimon.table.source.TableRead;
import org.apache.paimon.types.DataField;
import org.apache.paimon.types.DataType;
import org.apache.paimon.types.DataTypes;
import org.apache.paimon.types.DecimalType;
import org.apache.paimon.types.RowType;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.time.LocalDateTime;
import java.util.*;
import java.util.Arrays;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicBoolean;

@Slf4j
@Service
public class PaimonDataLakeService {

    private Catalog catalog;
    private boolean catalogInitialized = false;
    
    // 缓存表结构信息，避免频繁读取元数据
    private final Map<String, RowType> tableSchemaCache = new ConcurrentHashMap<>();

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

    @PostConstruct
    public void init() {
        try {
            log.info("初始化Paimon数据湖连接...");
            log.info("配置信息: warehouse={}, metastore={}, uri={}", warehouse, metastore, uri);
            log.info("Hive配置目录: {}", hiveConfDir);
            log.info("Hadoop配置目录: {}", hadoopConfDir);
            
            // 根据Paimon文档创建Catalog
            Options options = new Options();
            options.set("type", "paimon");
            options.set("warehouse", warehouse);
            options.set("metastore", metastore);
            options.set("uri", uri);
            options.set("hive-conf-dir", hiveConfDir);
            options.set("hadoop-conf-dir", hadoopConfDir);
            
            log.info("Paimon配置选项: {}", options);
            
            CatalogContext context = CatalogContext.create(options);
            catalog = CatalogFactory.createCatalog(context);
            catalogInitialized = true;
            log.info("Paimon数据湖连接初始化完成");
            
            // 输出所有数据库和表，用于调试
            try {
                List<String> databases = catalog.listDatabases();
                log.info("获取到数据库列表: {}", databases);
                
                for (String db : databases) {
                    try {
                        List<String> tables = catalog.listTables(db);
                        log.info("数据库 {} 包含的表: {}", db, tables);
                    } catch (Exception e) {
                        log.warn("获取数据库 {} 的表列表失败: {}", db, e.getMessage());
                    }
                }
            } catch (Exception e) {
                log.warn("列出数据库或表时出错，但不影响服务启动: {}", e.getMessage());
            }
        } catch (Exception e) {
            log.error("初始化Paimon数据湖连接失败，服务将继续启动但数据湖功能将不可用", e);
            catalogInitialized = false;
        }
    }

    /**
     * 获取所有数据库列表
     */
    public List<String> listDatabases() {
        if (!catalogInitialized) {
            throw new RuntimeException("数据湖连接未初始化，无法获取数据库列表");
        }
        
        try {
            return catalog.listDatabases();
        } catch (Exception e) {
            throw new RuntimeException("获取数据库列表失败: " + e.getMessage(), e);
        }
    }

    /**
     * 获取指定数据库中的所有表
     */
    public List<String> listTables(String database) {
        if (!catalogInitialized) {
            throw new RuntimeException("数据湖连接未初始化，无法获取表列表");
        }
        
        try {
            return catalog.listTables(database);
        } catch (Exception e) {
            throw new RuntimeException(String.format("获取数据库 %s 的表列表失败: %s", database, e.getMessage()), e);
        }
    }

    /**
     * 获取表结构信息
     */
    public List<Map<String, Object>> getTableSchema(String database, String tableName) {
        if (!catalogInitialized) {
            throw new RuntimeException("数据湖连接未初始化，无法获取表结构");
        }
        
        try {
            RowType rowType = getTableRowType(database, tableName);
            List<Map<String, Object>> result = new ArrayList<>();
            
            for (int i = 0; i < rowType.getFieldCount(); i++) {
                Map<String, Object> fieldInfo = new HashMap<>();
                fieldInfo.put("name", rowType.getFieldNames().get(i));
                fieldInfo.put("type", rowType.getFieldTypes().get(i).toString());
                result.add(fieldInfo);
            }
            
            return result;
        } catch (Exception e) {
            throw new RuntimeException(String.format("获取表 %s.%s 结构失败: %s", database, tableName, e.getMessage()), e);
        }
    }

    /**
     * 获取表的RowType信息
     */
    private RowType getTableRowType(String database, String tableName) {
        if (!catalogInitialized) {
            throw new RuntimeException("数据湖连接未初始化，无法获取表结构");
        }
        
        String key = database + "." + tableName;
        
        if (tableSchemaCache.containsKey(key)) {
            return tableSchemaCache.get(key);
        }
        
        // 对于特定的表使用硬编码字段定义
        if ("ads".equals(database)) {
            if ("ads_tracking_whale_collection_flow".equals(tableName)) {
                // 根据数据字典定义字段
                List<String> fieldNames = Arrays.asList(
                    "snapshot_date", "collection_address", "collection_name", "flow_direction", 
                    "rank_timerange", "rank_num", "net_flow_eth", "net_flow_usd", "net_flow_7d_eth", 
                    "net_flow_30d_eth", "floor_price_eth", "floor_price_change_1d", 
                    "unique_whale_buyers", "unique_whale_sellers", "whale_trading_percentage", 
                    "smart_whale_percentage", "dumb_whale_percentage", "trend_indicator", 
                    "data_source", "etl_time"
                );
                
                List<DataType> fieldTypes = Arrays.asList(
                    DataTypes.DATE(), DataTypes.STRING(), DataTypes.STRING(), DataTypes.STRING(),
                    DataTypes.STRING(), DataTypes.INT(), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10),
                    DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(10, 2),
                    DataTypes.INT(), DataTypes.INT(), DataTypes.DECIMAL(10, 2),
                    DataTypes.DECIMAL(10, 2), DataTypes.DECIMAL(10, 2), DataTypes.STRING(),
                    DataTypes.STRING(), DataTypes.TIMESTAMP(3)
                );
                
                RowType rowType = RowType.of(fieldTypes.toArray(new DataType[0]), fieldNames.toArray(new String[0]));
                tableSchemaCache.put(key, rowType);
                log.info("使用硬编码字段定义: ads.ads_tracking_whale_collection_flow");
                return rowType;
            } else if ("ads_whale_transactions".equals(tableName)) {
                // 根据数据字典定义字段
                List<String> fieldNames = Arrays.asList(
                    "snapshot_date", "tx_hash", "contract_address", "token_id", 
                    "tx_timestamp", "from_address", "to_address", "from_whale_type",
                    "to_whale_type", "from_influence_score", "to_influence_score", "collection_name",
                    "trade_price_eth", "trade_price_usd", "floor_price_eth", "price_to_floor_ratio",
                    "marketplace", "data_source", "etl_time"
                );
                
                List<DataType> fieldTypes = Arrays.asList(
                    DataTypes.DATE(), DataTypes.STRING(), DataTypes.STRING(), DataTypes.STRING(),
                    DataTypes.TIMESTAMP(3), DataTypes.STRING(), DataTypes.STRING(), DataTypes.STRING(),
                    DataTypes.STRING(), DataTypes.DECIMAL(10, 2), DataTypes.DECIMAL(10, 2), DataTypes.STRING(),
                    DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(10, 2),
                    DataTypes.STRING(), DataTypes.STRING(), DataTypes.TIMESTAMP(3)
                );
                
                RowType rowType = RowType.of(fieldTypes.toArray(new DataType[0]), fieldNames.toArray(new String[0]));
                tableSchemaCache.put(key, rowType);
                log.info("使用硬编码字段定义: ads.ads_whale_transactions");
                return rowType;
            } else if ("ads_whale_tracking_list".equals(tableName)) {
                // 根据数据字典定义字段
                List<String> fieldNames = Arrays.asList(
                    "snapshot_date", "wallet_address", "wallet_type", "tracking_id", 
                    "first_track_date", "tracking_days", "last_active_date", "status",
                    "total_profit_eth", "total_profit_usd", "roi_percentage", "influence_score", 
                    "total_tx_count", "success_rate", "favorite_collections", "inactive_days",
                    "is_top30_volume", "is_top100_balance", "rank_by_volume", "rank_by_profit",
                    "data_source", "etl_time"
                );
                
                List<DataType> fieldTypes = Arrays.asList(
                    DataTypes.DATE(), DataTypes.STRING(), DataTypes.STRING(), DataTypes.STRING(),
                    DataTypes.DATE(), DataTypes.INT(), DataTypes.DATE(), DataTypes.STRING(),
                    DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(10, 2), DataTypes.DECIMAL(10, 2),
                    DataTypes.INT(), DataTypes.DECIMAL(10, 2), DataTypes.STRING(), DataTypes.INT(),
                    DataTypes.BOOLEAN(), DataTypes.BOOLEAN(), DataTypes.INT(), DataTypes.INT(),
                    DataTypes.STRING(), DataTypes.TIMESTAMP(3)
                );
                
                RowType rowType = RowType.of(fieldTypes.toArray(new DataType[0]), fieldNames.toArray(new String[0]));
                tableSchemaCache.put(key, rowType);
                log.info("使用硬编码字段定义: ads.ads_whale_tracking_list");
                return rowType;
            } else if ("ads_dumb_whale_collection_flow".equals(tableName)) {
                // 根据数据字典定义ads_dumb_whale_collection_flow表字段
                List<String> fieldNames = Arrays.asList(
                    "snapshot_date", "collection_address", "collection_name", "flow_direction", 
                    "rank_timerange", "rank_num", "dumb_whale_net_flow_eth", "dumb_whale_net_flow_usd", "dumb_whale_net_flow_7d_eth", 
                    "dumb_whale_net_flow_30d_eth", "dumb_whale_buyers", "dumb_whale_sellers", 
                    "dumb_whale_buy_volume_eth", "dumb_whale_sell_volume_eth", "dumb_whale_trading_percentage", 
                    "floor_price_eth", "floor_price_change_1d", "trend_indicator", 
                    "data_source", "etl_time"
                );
                
                List<DataType> fieldTypes = Arrays.asList(
                    DataTypes.DATE(), DataTypes.STRING(), DataTypes.STRING(), DataTypes.STRING(),
                    DataTypes.STRING(), DataTypes.INT(), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10),
                    DataTypes.DECIMAL(30, 10), DataTypes.INT(), DataTypes.INT(),
                    DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(10, 2),
                    DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(10, 2), DataTypes.STRING(),
                    DataTypes.STRING(), DataTypes.TIMESTAMP(3)
                );
                
                RowType rowType = RowType.of(fieldTypes.toArray(new DataType[0]), fieldNames.toArray(new String[0]));
                tableSchemaCache.put(key, rowType);
                log.info("使用硬编码字段定义: ads.ads_dumb_whale_collection_flow");
                return rowType;
            } else if ("ads_smart_whale_collection_flow".equals(tableName)) {
                // 根据数据字典定义ads_smart_whale_collection_flow表字段
                List<String> fieldNames = Arrays.asList(
                    "snapshot_date", "collection_address", "collection_name", "flow_direction", 
                    "rank_timerange", "rank_num", "smart_whale_net_flow_eth", "smart_whale_net_flow_usd", "smart_whale_net_flow_7d_eth", 
                    "smart_whale_net_flow_30d_eth", "smart_whale_buyers", "smart_whale_sellers", 
                    "smart_whale_buy_volume_eth", "smart_whale_sell_volume_eth", "smart_whale_trading_percentage", 
                    "floor_price_eth", "floor_price_change_1d", "trend_indicator", 
                    "data_source", "etl_time"
                );
                
                List<DataType> fieldTypes = Arrays.asList(
                    DataTypes.DATE(), DataTypes.STRING(), DataTypes.STRING(), DataTypes.STRING(),
                    DataTypes.STRING(), DataTypes.INT(), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10),
                    DataTypes.DECIMAL(30, 10), DataTypes.INT(), DataTypes.INT(),
                    DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(10, 2),
                    DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(10, 2), DataTypes.STRING(),
                    DataTypes.STRING(), DataTypes.TIMESTAMP(3)
                );
                
                RowType rowType = RowType.of(fieldTypes.toArray(new DataType[0]), fieldNames.toArray(new String[0]));
                tableSchemaCache.put(key, rowType);
                log.info("使用硬编码字段定义: ads.ads_smart_whale_collection_flow");
                return rowType;
            } else if ("ads_top_profit_whales".equals(tableName)) {
                // 根据数据字典定义ads_top_profit_whales表字段
                List<String> fieldNames = Arrays.asList(
                    "snapshot_date", "wallet_address", "rank_timerange", "rank_num", "wallet_tag", 
                    "total_profit_eth", "total_profit_usd", "profit_7d_eth", "profit_30d_eth", 
                    "best_collection", "best_collection_profit_eth", "total_tx_count", 
                    "first_track_date", "tracking_days", "influence_score", 
                    "data_source", "etl_time"
                );
                
                List<DataType> fieldTypes = Arrays.asList(
                    DataTypes.DATE(), DataTypes.STRING(), DataTypes.STRING(), DataTypes.INT(), DataTypes.STRING(),
                    DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10),
                    DataTypes.STRING(), DataTypes.DECIMAL(30, 10), DataTypes.INT(),
                    DataTypes.DATE(), DataTypes.INT(), DataTypes.DECIMAL(10, 2),
                    DataTypes.STRING(), DataTypes.TIMESTAMP(3)
                );
                
                RowType rowType = RowType.of(fieldTypes.toArray(new DataType[0]), fieldNames.toArray(new String[0]));
                tableSchemaCache.put(key, rowType);
                log.info("使用硬编码字段定义: ads.ads_top_profit_whales");
                return rowType;
            } else if ("ads_top_roi_whales".equals(tableName)) {
                // 根据数据字典定义ads_top_roi_whales表字段
                List<String> fieldNames = Arrays.asList(
                    "snapshot_date", "wallet_address", "rank_timerange", "rank_num", "wallet_tag", 
                    "roi_percentage", "total_buy_volume_eth", "total_sell_volume_eth", "total_profit_eth", 
                    "roi_7d_percentage", "roi_30d_percentage", "best_collection_roi", "best_collection_roi_percentage", 
                    "avg_hold_days", "first_track_date", "influence_score", 
                    "data_source", "etl_time"
                );
                
                List<DataType> fieldTypes = Arrays.asList(
                    DataTypes.DATE(), DataTypes.STRING(), DataTypes.STRING(), DataTypes.INT(), DataTypes.STRING(),
                    DataTypes.DECIMAL(10, 2), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10),
                    DataTypes.DECIMAL(10, 2), DataTypes.DECIMAL(10, 2), DataTypes.STRING(), DataTypes.DECIMAL(10, 2),
                    DataTypes.INT(), DataTypes.DATE(), DataTypes.DECIMAL(10, 2),
                    DataTypes.STRING(), DataTypes.TIMESTAMP(3)
                );
                
                RowType rowType = RowType.of(fieldTypes.toArray(new DataType[0]), fieldNames.toArray(new String[0]));
                tableSchemaCache.put(key, rowType);
                log.info("使用硬编码字段定义: ads.ads_top_roi_whales");
                return rowType;
            }
        }
        
        try {
            // 获取表
            Identifier identifier = Identifier.create(database, tableName);
            Table table = catalog.getTable(identifier);
            
            // 创建ReadBuilder
            ReadBuilder readBuilder = table.newReadBuilder();
            
            // 尝试使用反射获取表的RowType
            try {
                java.lang.reflect.Field typeField = readBuilder.newRead().getClass().getDeclaredField("type");
                typeField.setAccessible(true);
                Object typeObj = typeField.get(readBuilder.newRead());
                
                if (typeObj instanceof RowType) {
                    RowType rowType = (RowType) typeObj;
                    tableSchemaCache.put(key, rowType);
                    log.info("成功获取表 {}.{} 的RowType", database, tableName);
                    return rowType;
                }
            } catch (Exception e) {
                log.warn("通过ReadBuilder反射获取RowType失败: {}", e.getMessage());
            }
            
            // 尝试使用Schema信息获取RowType
            try {
                java.lang.reflect.Method method = table.getClass().getMethod("schema");
                method.setAccessible(true);
                Schema schema = (Schema) method.invoke(table);
                
                if (schema != null) {
                    RowType rowType = (RowType) schema.rowType();
                    tableSchemaCache.put(key, rowType);
                    log.info("通过Schema成功获取表 {}.{} 的RowType", database, tableName);
                    return rowType;
                }
            } catch (Exception e) {
                log.warn("通过Schema获取RowType失败: {}", e.getMessage());
            }
            
            // 如果以上方法都失败，尝试读取一行数据来推断结构
            try {
                List<Split> splits = readBuilder.newScan().plan().splits();
                if (!splits.isEmpty()) {
                    TableRead read = readBuilder.newRead();
                    RecordReader<InternalRow> reader = read.createReader(Collections.singletonList(splits.get(0)));
                    
                    // 获取第一行数据来推断表结构
                    final List<String> fieldNames = new ArrayList<>();
                    final List<DataType> fieldTypes = new ArrayList<>();
                    final AtomicBoolean hasRow = new AtomicBoolean(false);
                    
                    reader.forEachRemaining(row -> {
                        if (!hasRow.get()) {
                            hasRow.set(true);
                            // 从行数据中推断字段信息，只能获取基本类型信息
                            for (int i = 0; i < row.getFieldCount(); i++) {
                                fieldNames.add("field_" + i);
                                
                                if (row.isNullAt(i)) {
                                    fieldTypes.add(DataTypes.STRING());
                                } else {
                                    // 尝试推断类型
                                    try {
                                        row.getInt(i);
                                        fieldTypes.add(DataTypes.INT());
                                        continue;
                                    } catch (Exception ignored) {}
                                    
                                    try {
                                        row.getLong(i);
                                        fieldTypes.add(DataTypes.BIGINT());
                                        continue;
                                    } catch (Exception ignored) {}
                                    
                                    try {
                                        row.getDouble(i);
                                        fieldTypes.add(DataTypes.DOUBLE());
                                        continue;
                                    } catch (Exception ignored) {}
                                    
                                    try {
                                        row.getString(i);
                                        fieldTypes.add(DataTypes.STRING());
                                        continue;
                                    } catch (Exception ignored) {}
                                    
                                    // 默认使用STRING类型
                                    fieldTypes.add(DataTypes.STRING());
                                }
                            }
                        }
                    });
                    
                    if (hasRow.get()) {
                        RowType rowType = RowType.of(fieldTypes.toArray(new DataType[0]), fieldNames.toArray(new String[0]));
                        tableSchemaCache.put(key, rowType);
                        log.info("通过读取数据推断表 {}.{} 的RowType", database, tableName);
                        return rowType;
                    }
                }
            } catch (Exception e) {
                log.warn("通过读取数据推断表结构失败: {}", e.getMessage());
            }
            
            throw new RuntimeException(String.format("无法获取表 %s.%s 的结构信息", database, tableName));
        } catch (Exception e) {
            throw new RuntimeException(String.format("获取表 %s.%s 结构失败: %s", database, tableName, e.getMessage()), e);
        }
    }

    /**
     * 获取指定表的数据
     */
    public List<Map<String, Object>> getTableData(String database, String table, int limit) {
        if (!catalogInitialized) {
            throw new RuntimeException("数据湖连接未初始化，无法获取数据");
        }
        
        // 检查表是否存在
        if (!tableExists(database, table)) {
            throw new RuntimeException(String.format("表 %s.%s 不存在，无法获取数据", database, table));
        }
        
        try {
            // 获取表结构
            RowType rowType = getTableRowType(database, table);
            
            // 获取表对象并创建读取器
            Identifier identifier = Identifier.create(database, table);
            Table paimonTable = catalog.getTable(identifier);
            ReadBuilder readBuilder = paimonTable.newReadBuilder();
            
            // 计划查询
            List<Split> splits = readBuilder.newScan().plan().splits();
            if (splits.isEmpty()) {
                log.info("表 {}.{} 没有数据", database, table);
                return Collections.emptyList();
            }
            
            // 读取数据
            TableRead read = readBuilder.newRead();
            List<Map<String, Object>> result = new ArrayList<>();
            AtomicInteger count = new AtomicInteger(0);
            
            log.info("开始读取表 {}.{} 数据，请求 {} 条记录", database, table, limit);
            
            for (Split split : splits) {
                if (count.get() >= limit) {
                    break;
                }
                
                RecordReader<InternalRow> reader = read.createReader(Collections.singletonList(split));
                
                // 使用forEachRemaining替代while循环
                reader.forEachRemaining(row -> {
                    if (count.get() < limit) {
                        Map<String, Object> record = new HashMap<>();
                        
                        // 转换每个字段的值
                        for (int i = 0; i < rowType.getFieldCount(); i++) {
                            String fieldName = rowType.getFieldNames().get(i);
                            DataType fieldType = rowType.getFieldTypes().get(i);
                            
                            // 检查字段索引是否超出范围
                            if (i >= row.getFieldCount()) {
                                record.put(fieldName, null);
                                continue;
                            }
                            
                            // 检查是否为空值
                            if (row.isNullAt(i)) {
                                record.put(fieldName, null);
                                continue;
                            }
                            
                            try {
                                Object value = convertToJavaObject(row, i, fieldType, fieldName);
                                record.put(fieldName, value);
                            } catch (Exception e) {
                                log.warn("转换字段 {} 值时出错: {}", fieldName, e.getMessage());
                                record.put(fieldName, null);
                            }
                        }
                        
                        result.add(record);
                        count.incrementAndGet();
                    }
                });
            }
            
            log.info("成功读取表 {}.{} 数据 {} 条", database, table, count.get());
            return result;
        } catch (Exception e) {
            throw new RuntimeException(String.format("获取表 %s.%s 数据失败: %s", database, table, e.getMessage()), e);
        }
    }

    /**
     * 将Paimon内部数据类型转换为Java对象
     * 注意：此方法针对ADS层的数据做了特殊处理，确保日期和时间戳类型正确转换
     * 
     * @param row 数据行
     * @param pos 字段位置
     * @param type 字段类型
     * @param fieldName 字段名称，用于特殊处理某些字段
     * @return 转换后的Java对象
     */
    private Object convertToJavaObject(InternalRow row, int pos, DataType type, String fieldName) {
        if (row.isNullAt(pos)) {
            return null;
        }

        try {
            switch (type.getTypeRoot()) {
                case CHAR:
                case VARCHAR:
                    try {
                        BinaryString binaryString = row.getString(pos);
                        return binaryString != null ? binaryString.toString() : null;
                    } catch (Exception e) {
                        log.warn("转换VARCHAR/CHAR类型出错: 位置={}, 错误={}", pos, e.getMessage());
                        return null;
                    }
                case BOOLEAN:
                    return row.getBoolean(pos);
                case TINYINT:
                    return row.getByte(pos);
                case SMALLINT:
                    return row.getShort(pos);
                case INTEGER:
                    return row.getInt(pos);
                case BIGINT:
                    return row.getLong(pos);
                case FLOAT:
                    return row.getFloat(pos);
                case DOUBLE:
                    return row.getDouble(pos);
                case DECIMAL:
                    try {
                    DecimalType decimalType = (DecimalType) type;
                    Decimal decimal = row.getDecimal(pos, decimalType.getPrecision(), decimalType.getScale());
                        return decimal != null ? decimal.toBigDecimal() : null;
                    } catch (Exception e) {
                        log.warn("转换DECIMAL类型出错: 位置={}, 错误={}", pos, e.getMessage());
                        return null;
                    }
                case DATE:
                    try {
                        // 将从Unix纪元开始的天数转换为java.sql.Date对象
                        int epochDays = row.getInt(pos);
                        
                        // 检查是否为snapshot_date字段且格式可能是YYYYMMDD格式
                        if ("snapshot_date".equals(fieldName) && epochDays > 19000000 && epochDays < 30000000) {
                            // 尝试解析为YYYYMMDD格式的日期值
                            try {
                                String dateStr = String.valueOf(epochDays);
                                if (dateStr.length() == 8) {
                                    // 提取年月日部分
                                    int year = Integer.parseInt(dateStr.substring(0, 4));
                                    int month = Integer.parseInt(dateStr.substring(4, 6));
                                    int day = Integer.parseInt(dateStr.substring(6, 8));
                                    
                                    // 检查日期的有效性
                                    if (year >= 1970 && year <= 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                                        java.util.Calendar cal = java.util.Calendar.getInstance();
                                        cal.set(year, month - 1, day); // 月份从0开始
                                        
                                        return new java.sql.Date(cal.getTimeInMillis());
                                    }
                                } else if (dateStr.length() == 5) {
                                    // 可能是天数编码，尝试直接转换
                                    // 每天的毫秒数 = 24小时 * 60分钟 * 60秒 * 1000毫秒
                                    long milliseconds = epochDays * 24L * 60L * 60L * 1000L;
                                    return new java.sql.Date(milliseconds);
                                }
                            } catch (Exception dateEx) {
                                log.warn("解析snapshot_date异常: {}, 值={}", dateEx.getMessage(), epochDays);
                            }
                        }
                        
                        // 检查日期值是否在合理范围内
                        if (epochDays < 0 || epochDays > 100000) { // 约273年的天数
                            log.warn("日期天数超出合理范围: {}, 位置={}, 字段={}", epochDays, pos, fieldName);
                            
                            // 如果是snapshot_date字段，尝试返回当前日期
                            if ("snapshot_date".equals(fieldName)) {
                                log.info("修复snapshot_date字段，替换为当前日期");
                                return new java.sql.Date(System.currentTimeMillis());
                            }
                            
                            return null;
                        }
                        
                        // 每天的毫秒数 = 24小时 * 60分钟 * 60秒 * 1000毫秒
                        long milliseconds = epochDays * 24L * 60L * 60L * 1000L;
                        java.sql.Date date = new java.sql.Date(milliseconds);
                        
                        return date;
                    } catch (Exception e) {
                        log.warn("转换DATE类型出错: 位置={}, 字段={}, 错误={}", pos, fieldName, e.getMessage());
                        
                        // 如果是snapshot_date字段，返回当前日期
                        if ("snapshot_date".equals(fieldName)) {
                            log.info("转换snapshot_date出错，替换为当前日期");
                            return new java.sql.Date(System.currentTimeMillis());
                        }
                        
                        return null;
                    }
                case TIME_WITHOUT_TIME_ZONE:
                    try {
                        int timeOfDayMillis = row.getInt(pos);
                        // 时间以一天内的毫秒数表示，范围从0到86400000
                        if (timeOfDayMillis < 0 || timeOfDayMillis > 86400000) {
                            log.warn("时间毫秒数超出有效范围: {}, 位置={}", timeOfDayMillis, pos);
                            return null;
                        }
                        
                        // 转换为java.sql.Time对象
                        return new java.sql.Time(timeOfDayMillis);
                    } catch (Exception e) {
                        log.warn("转换TIME类型出错: 位置={}, 错误={}", pos, e.getMessage());
                        return null;
                    }
                case TIMESTAMP_WITHOUT_TIME_ZONE:
                case TIMESTAMP_WITH_LOCAL_TIME_ZONE:
                    try {
                    Timestamp timestamp = row.getTimestamp(pos, 3);
                        if (timestamp == null) {
                            return null;
                        }
                        
                        long micros = timestamp.getMillisecond(); // 实际上是微秒值
                        
                        // 检查是否为微秒单位（比毫秒大1000倍）
                        boolean isMicroseconds = micros > 1000000000000L; // 如果大于2001年的毫秒时间戳，很可能是微秒
                        
                        // 转换为毫秒
                        long millis = isMicroseconds ? micros / 1000 : micros;
                        
                        log.debug("处理时间戳: 原始值={}, 转换后={}, 单位推测={}", 
                                 micros, millis, isMicroseconds ? "微秒" : "毫秒");
                        
                        // 验证时间戳是否在合理范围内 (1970年至2100年)
                        if (millis < 0 || millis > 4102444800000L) { // 2100年之前的毫秒数
                            log.warn("时间戳毫秒值超出有效范围(转换后): {}, 原始值={}, 位置={}", 
                                    millis, micros, pos);
                            
                            // 对于ADS层的etl_time字段，如果值异常，返回当前时间
                            if ("etl_time".equals(fieldName)) {
                                log.info("修复ADS层etl_time字段，替换为当前时间");
                                return new java.sql.Timestamp(System.currentTimeMillis());
                            }
                            
                            return null;
                        }
                        
                        // 创建标准的java.sql.Timestamp对象
                        java.sql.Timestamp sqlTimestamp = new java.sql.Timestamp(millis);
                        
                        // 验证生成的年份是否合理(1970-2100)
                        java.util.Calendar cal = java.util.Calendar.getInstance();
                        cal.setTimeInMillis(millis);
                        int year = cal.get(java.util.Calendar.YEAR);
                        
                        if (year < 1970 || year > 2100) {
                            log.warn("时间戳年份超出合理范围: {}, 位置={}", year, pos);
                            
                            // 对于ADS层的etl_time字段，如果值异常，返回当前时间
                            if ("etl_time".equals(fieldName)) {
                                log.info("修复ADS层etl_time字段，替换为当前时间");
                                return new java.sql.Timestamp(System.currentTimeMillis());
                            }
                            
                            return null;
                        }
                        
                        return sqlTimestamp;
                    } catch (Exception timestampException) {
                        log.info("etl_time字段转换异常，替换为当前时间: {}", timestampException.getMessage());
                        return new java.sql.Timestamp(System.currentTimeMillis());
                    }
                default:
                    // 对于未知或复杂类型，尝试转为字符串
                    try {
                        BinaryString binaryString = row.getString(pos);
                        return binaryString != null ? binaryString.toString() : null;
                    } catch (Exception e) {
                        log.warn("无法将未知类型 {} 转换为字符串，位置={}", type.getTypeRoot(), pos);
                        return null;
                    }
            }
        } catch (Exception e) {
            log.warn("转换字段值时出错: 位置={}, 类型={}, 错误={}", pos, type.getTypeRoot(), e.getMessage());
            
            // 根据类型进行特定的恢复尝试
            try {
                switch (type.getTypeRoot()) {
                    case CHAR:
                    case VARCHAR:
                        return row.getString(pos) != null ? row.getString(pos).toString() : null;
                    case BOOLEAN:
                        return row.getBoolean(pos);
                    case INTEGER:
                    case TINYINT:
                    case SMALLINT:
                        return row.getInt(pos);
                    case BIGINT:
                        return row.getLong(pos);
                    case FLOAT:
                    case DOUBLE:
                    case DECIMAL:
                        return row.getDouble(pos);
                    case DATE:
                        int days = row.getInt(pos);
                        return days >= 0 ? new java.sql.Date(days * 24L * 60L * 60L * 1000L) : null;
                    case TIMESTAMP_WITHOUT_TIME_ZONE:
                    case TIMESTAMP_WITH_LOCAL_TIME_ZONE:
                        // 对于etl_time字段，如果转换失败，返回当前时间
                        if ("etl_time".equals(fieldName)) {
                            try {
                                Timestamp ts = row.getTimestamp(pos, 3);
                                if (ts == null) {
                                    log.info("etl_time字段为null，替换为当前时间");
                                    return new java.sql.Timestamp(System.currentTimeMillis());
                                }
                                
                                long micros = ts.getMillisecond(); // 实际上是微秒值
                                
                                // 检查是否为微秒单位（比毫秒大1000倍）
                                boolean isMicroseconds = micros > 1000000000000L; // 如果大于2001年的毫秒时间戳，很可能是微秒
                                
                                // 转换为毫秒
                                long millis = isMicroseconds ? micros / 1000 : micros;
                                
                                if (millis < 0 || millis > 4102444800000L) {
                                    log.info("etl_time字段时间戳值异常(转换后): {}，原始值={}，替换为当前时间", 
                                            millis, micros);
                                    return new java.sql.Timestamp(System.currentTimeMillis());
                                }
                                
                                return new java.sql.Timestamp(millis);
                            } catch (Exception timestampException) {
                                log.info("etl_time字段转换异常，替换为当前时间: {}", timestampException.getMessage());
                                return new java.sql.Timestamp(System.currentTimeMillis());
                            }
                        } else {
                            Timestamp ts = row.getTimestamp(pos, 3);
                            if (ts != null) {
                                long micros = ts.getMillisecond(); // 实际上是微秒值
                                
                                // 检查是否为微秒单位（比毫秒大1000倍）
                                boolean isMicroseconds = micros > 1000000000000L; // 如果大于2001年的毫秒时间戳，很可能是微秒
                                
                                // 转换为毫秒
                                long millis = isMicroseconds ? micros / 1000 : micros;
                                
                                return new java.sql.Timestamp(millis);
                            } else {
                                return null;
                            }
                        }
                    default:
                        return null;
                }
            } catch (Exception recoveryError) {
                log.warn("恢复转换失败: 位置={}, 字段={}, 错误={}", pos, fieldName, recoveryError.getMessage());
                
                // 如果是etl_time字段，始终返回当前时间
                if ("etl_time".equals(fieldName)) {
                    return new java.sql.Timestamp(System.currentTimeMillis());
                }
            
            return null; // 所有尝试都失败时返回null
            }
        }
    }

    /**
     * 获取鲸鱼交易数据 - ads_whale_transactions
     */
    public List<Map<String, Object>> getWhaleTransactions(int limit) {
        return getTableData("ads", "ads_whale_transactions", limit);
    }

    /**
     * 获取鲸鱼统计数据 - ads_whale_tracking_list
     */
    public List<Map<String, Object>> getWhaleTrackingList(int limit) {
        return getTableData("ads", "ads_whale_tracking_list", limit);
    }

    /**
     * 检查指定的数据库和表是否存在
     * @param database 数据库名称
     * @param table 表名称
     * @return 如果数据库和表都存在则返回true，否则返回false
     */
    public boolean tableExists(String database, String table) {
        if (!catalogInitialized) {
            throw new RuntimeException("数据湖连接未初始化，无法检查表是否存在");
        }
        
        try {
            // 首先检查数据库是否存在
            List<String> databases = catalog.listDatabases();
            if (!databases.contains(database)) {
                log.warn("数据库 {} 不存在", database);
                return false;
            }
            
            // 检查表是否存在
            List<String> tables = catalog.listTables(database);
            if (!tables.contains(table)) {
                log.warn("表 {}.{} 不存在", database, table);
                return false;
            }
            
            return true;
        } catch (Exception e) {
            throw new RuntimeException(String.format("检查表 %s.%s 是否存在时出错: %s", 
                                                   database, table, e.getMessage()), e);
        }
    }
} 