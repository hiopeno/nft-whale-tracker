package org.bigdatatechcir.whale;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.bigdatatechcir.whale.generator.NFTDataGenerator;
import org.bigdatatechcir.whale.model.NFTTransaction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

import java.util.Properties;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@SpringBootApplication
@ComponentScan(basePackages = "org.bigdatatechcir.whale")
public class NFTDataGeneratorApplication implements CommandLineRunner {
    private static final Logger logger = LoggerFactory.getLogger(NFTDataGeneratorApplication.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    
    @Value("${kafka.bootstrap-servers:192.168.254.133:9092}")
    private String bootstrapServers;
    
    @Value("${kafka.topic:NFT_TRANSACTIONS}")
    private String topic;
    
    @Value("${generator.interval:1000}")
    private long interval;
    
    @Value("${generator.collections:10}")
    private int collectionsCount;
    
    @Value("${generator.nfts-per-collection:100}")
    private int nftsPerCollection;
    
    @Value("${generator.initial-transactions:1000}")
    private int initialTransactionsCount;
    
    @Value("${generator.continuous-mode:true}")
    private boolean continuousMode;
    
    public static void main(String[] args) {
        SpringApplication.run(NFTDataGeneratorApplication.class, args);
    }
    
    @Override
    public void run(String... args) throws Exception {
        logger.info("启动NFT数据生成器应用...");
        logger.info("配置: Kafka={}, Topic={}, 连续模式={}, 间隔={}ms", 
                    bootstrapServers, topic, continuousMode, interval);
        
        // 创建Kafka生产者配置
        Properties props = new Properties();
        props.put("bootstrap.servers", bootstrapServers);
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("acks", "all");
        props.put("retries", 3);
        props.put("max.block.ms", "3000");
        
        boolean useKafka = true;
        KafkaProducer<String, String> producer = null;
        
        try {
            producer = new KafkaProducer<>(props);
            producer.partitionsFor(topic);
            logger.info("成功连接到Kafka: {}", bootstrapServers);
        } catch (Exception e) {
            useKafka = false;
            logger.error("无法连接到Kafka: {}. 将输出到本地日志", e.getMessage());
        }
        
        final KafkaProducer<String, String> finalProducer = producer;
        final boolean finalUseKafka = useKafka;
        
        // 批量生成初始数据
        logger.info("生成初始NFT数据...");
        NFTDataGenerator.generateBatchData(collectionsCount, nftsPerCollection, initialTransactionsCount);
        
        if (continuousMode) {
            logger.info("启动连续数据生成模式...");
            
            // 使用ScheduledExecutorService定期生成新交易数据
            ScheduledExecutorService executorService = Executors.newSingleThreadScheduledExecutor();
            
            executorService.scheduleAtFixedRate(() -> {
                try {
                    // 随机选择一个NFT进行交易
                    String randomNftId = NFTDataGenerator.getNfts()
                            .stream()
                            .skip((int) (NFTDataGenerator.getNfts().size() * Math.random()))
                            .findFirst()
                            .orElseThrow(() -> new RuntimeException("无法找到NFT"))
                            .getId();
                    
                    // 20%概率生成鲸鱼交易
                    boolean isWhaleTransaction = Math.random() < 0.2;
                    
                    // 生成新交易
                    NFTTransaction transaction = NFTDataGenerator.generateTransaction(randomNftId, isWhaleTransaction);
                    String jsonTransaction = objectMapper.writeValueAsString(transaction);
                    
                    if (finalUseKafka && finalProducer != null) {
                        try {
                            finalProducer.send(new ProducerRecord<>(topic, transaction.getId(), jsonTransaction), 
                                (metadata, exception) -> {
                                    if (exception != null) {
                                        logger.error("发送消息到Kafka失败", exception);
                                        System.out.println("生成交易 (发送到Kafka失败): " + jsonTransaction);
                                    } else {
                                        logger.info("消息发送到分区 {} 偏移量 {}", 
                                                  metadata.partition(), metadata.offset());
                                    }
                                });
                        } catch (Exception e) {
                            logger.error("发送消息到Kafka失败", e);
                            System.out.println("生成交易 (发送到Kafka失败): " + jsonTransaction);
                        }
                    } else {
                        // 本地打印
                        System.out.println("生成交易 (本地打印模式): " + jsonTransaction);
                    }
                } catch (Exception e) {
                    logger.error("生成交易数据时发生错误", e);
                }
            }, 0, interval, TimeUnit.MILLISECONDS);
            
            // 添加JVM关闭钩子，确保资源正确释放
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                logger.info("关闭应用...");
                executorService.shutdown();
                if (finalProducer != null) {
                    finalProducer.close();
                }
            }));
        } else {
            // 单次运行模式，完成后退出
            logger.info("数据生成完成. 退出应用");
            if (finalProducer != null) {
                finalProducer.close();
            }
        }
    }
} 