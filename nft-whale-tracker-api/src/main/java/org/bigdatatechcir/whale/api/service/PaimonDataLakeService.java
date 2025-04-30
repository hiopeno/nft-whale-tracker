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
                    "rank_num", "net_flow_eth", "net_flow_usd", "net_flow_7d_eth", 
                    "net_flow_30d_eth", "floor_price_eth", "floor_price_change_1d", 
                    "unique_whale_buyers", "unique_whale_sellers", "whale_trading_percentage", 
                    "smart_whale_percentage", "dumb_whale_percentage", "trend_indicator", 
                    "data_source", "etl_time"
                );
                
                List<DataType> fieldTypes = Arrays.asList(
                    DataTypes.DATE(), DataTypes.STRING(), DataTypes.STRING(), DataTypes.STRING(),
                    DataTypes.INT(), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10), DataTypes.DECIMAL(30, 10),
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
                                Object value = convertToJavaObject(row, i, fieldType);
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
     */
    private Object convertToJavaObject(InternalRow row, int pos, DataType type) {
        try {
            switch (type.getTypeRoot()) {
                case CHAR:
                case VARCHAR:
                    return row.getString(pos).toString();
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
                    DecimalType decimalType = (DecimalType) type;
                    Decimal decimal = row.getDecimal(pos, decimalType.getPrecision(), decimalType.getScale());
                    return decimal.toBigDecimal();
                case DATE:
                    return row.getInt(pos); // 日期以天数存储，从Unix纪元开始
                case TIME_WITHOUT_TIME_ZONE:
                    return row.getInt(pos); // 时间以毫秒存储
                case TIMESTAMP_WITHOUT_TIME_ZONE:
                case TIMESTAMP_WITH_LOCAL_TIME_ZONE:
                    Timestamp timestamp = row.getTimestamp(pos, 3);
                    return new java.sql.Timestamp(timestamp.getMillisecond());
                default:
                    // 对于未知或复杂类型，尝试转为字符串
                    try {
                        return row.getString(pos).toString();
                    } catch (Exception e) {
                        log.warn("无法将类型 {} 转换为字符串，位置={}", type.getTypeRoot(), pos);
                        return null;
                    }
            }
        } catch (Exception e) {
            log.warn("转换字段值时出错: 位置={}, 类型={}, 错误={}", pos, type.getTypeRoot(), e.getMessage());
            
            // 尝试各种可能的类型转换
            try {
                return row.getString(pos).toString();
            } catch (Exception ignored) {}
            
            try {
                return row.getInt(pos);
            } catch (Exception ignored) {}
            
            try {
                return row.getLong(pos);
            } catch (Exception ignored) {}
            
            try {
                return row.getDouble(pos);
            } catch (Exception ignored) {}
            
            return null; // 所有尝试都失败时返回null
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