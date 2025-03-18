package org.bigdatatechcir.whale.util;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

public class RandomDataUtil {
    private static final Random random = new SecureRandom();
    
    // 常用区块链
    private static final List<String> BLOCKCHAINS = Arrays.asList(
        "Ethereum", "Polygon", "Solana", "Arbitrum", "Base", "Optimism", "Avalanche", "BNB Chain"
    );
    
    // NFT市场
    private static final List<String> MARKETPLACES = Arrays.asList(
        "OpenSea", "Blur", "X2Y2", "Magic Eden", "Rarible", "LooksRare", "SuperRare", "Foundation", "Element"
    );
    
    // NFT类别
    private static final List<String> CATEGORIES = Arrays.asList(
        "Art", "Collectibles", "Games", "Metaverse", "PFP", "Photography", "Music", "Sports", "Utility"
    );
    
    // 事务类型
    private static final List<String> TRANSACTION_TYPES = Arrays.asList(
        "MINT", "TRANSFER", "SALE", "AUCTION", "OFFER_ACCEPTED", "BID_WON"
    );
    
    // 钱包类型
    private static final List<String> WALLET_TYPES = Arrays.asList(
        "COLLECTOR", "TRADER", "HOLDER", "FLIPPER"
    );
    
    // 预设的知名NFT收藏集
    private static final List<String> POPULAR_COLLECTIONS = Arrays.asList(
        "Bored Ape Yacht Club", "CryptoPunks", "Azuki", "Doodles", "Moonbirds", "Art Blocks", 
        "Clone X", "World of Women", "Pudgy Penguins", "VeeFriends", "DeGods", "Otherside"
    );
    
    // 生成随机ID
    public static String randomId() {
        return UUID.randomUUID().toString();
    }
    
    // 生成随机钱包地址 (Ethereum格式)
    public static String randomWalletAddress() {
        StringBuilder sb = new StringBuilder("0x");
        for (int i = 0; i < 40; i++) {
            sb.append(Integer.toHexString(random.nextInt(16)));
        }
        return sb.toString();
    }
    
    // 生成随机交易哈希
    public static String randomTransactionHash() {
        StringBuilder sb = new StringBuilder("0x");
        for (int i = 0; i < 64; i++) {
            sb.append(Integer.toHexString(random.nextInt(16)));
        }
        return sb.toString();
    }
    
    // 生成随机合约地址
    public static String randomContractAddress() {
        StringBuilder sb = new StringBuilder("0x");
        for (int i = 0; i < 40; i++) {
            sb.append(Integer.toHexString(random.nextInt(16)));
        }
        return sb.toString();
    }
    
    // 生成随机时间戳(过去1年内)
    public static Long randomTimestamp() {
        long now = Instant.now().getEpochSecond();
        long oneYearAgo = now - 365 * 24 * 60 * 60;
        return ThreadLocalRandom.current().nextLong(oneYearAgo, now) * 1000;
    }
    
    // 生成随机NFT价格 (0.01 - 100 ETH)
    public static Double randomPrice() {
        return roundToDecimals(0.01 + random.nextDouble() * 100, 4);
    }
    
    // 生成低价NFT价格 (0.001 - 0.1 ETH)
    public static Double randomLowPrice() {
        return roundToDecimals(0.001 + random.nextDouble() * 0.099, 4);
    }
    
    // 生成高价NFT价格 (10 - 1000 ETH)
    public static Double randomHighPrice() {
        return roundToDecimals(10 + random.nextDouble() * 990, 4);
    }
    
    // 生成随机区块链
    public static String randomBlockchain() {
        return BLOCKCHAINS.get(random.nextInt(BLOCKCHAINS.size()));
    }
    
    // 生成随机市场
    public static String randomMarketplace() {
        return MARKETPLACES.get(random.nextInt(MARKETPLACES.size()));
    }
    
    // 生成随机类别
    public static String randomCategory() {
        return CATEGORIES.get(random.nextInt(CATEGORIES.size()));
    }
    
    // 生成随机交易类型
    public static String randomTransactionType() {
        return TRANSACTION_TYPES.get(random.nextInt(TRANSACTION_TYPES.size()));
    }
    
    // 生成随机钱包类型
    public static String randomWalletType() {
        return WALLET_TYPES.get(random.nextInt(WALLET_TYPES.size()));
    }
    
    // 生成随机收藏集名称
    public static String randomCollectionName() {
        return POPULAR_COLLECTIONS.get(random.nextInt(POPULAR_COLLECTIONS.size()));
    }
    
    // 生成随机布尔值，带概率
    public static boolean randomBoolean(double trueProbability) {
        return random.nextDouble() < trueProbability;
    }
    
    // 生成随机整数
    public static int randomInt(int min, int max) {
        return min + random.nextInt(max - min + 1);
    }
    
    // 四舍五入到指定小数位
    public static double roundToDecimals(double value, int decimals) {
        double scale = Math.pow(10, decimals);
        return Math.round(value * scale) / scale;
    }
    
    // 生成随机稀有度排名
    public static int randomRarityRank(int collectionSize) {
        return 1 + random.nextInt(collectionSize);
    }
    
    // 生成随机地板价
    public static Double randomFloorPrice() {
        return roundToDecimals(0.05 + random.nextDouble() * 10, 4);
    }
    
    // 生成随机波动百分比
    public static Double randomChangePercent() {
        return roundToDecimals(-50 + random.nextDouble() * 100, 2);
    }
} 