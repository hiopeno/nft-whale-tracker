package org.bigdatatechcir.whale.generator;

import org.bigdatatechcir.whale.model.*;
import org.bigdatatechcir.whale.util.RandomDataUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class NFTDataGenerator {
    private static final Logger logger = LoggerFactory.getLogger(NFTDataGenerator.class);
    
    // 存储已生成的数据，以便于后续生成具有关联关系的数据
    private static final Map<String, NFTCollection> collections = new ConcurrentHashMap<>();
    private static final Map<String, NFT> nfts = new ConcurrentHashMap<>();
    private static final Map<String, WhaleWallet> whaleWallets = new ConcurrentHashMap<>();
    private static final Map<String, NFTTransaction> transactions = new ConcurrentHashMap<>();
    private static final Map<String, NFTAlert> alerts = new ConcurrentHashMap<>();
    
    // 预设的鲸鱼钱包地址，用于生成鲸鱼交易
    private static final List<String> predefinedWhales = new ArrayList<>();
    
    // 初始化生成器，预先生成一些基础数据
    static {
        // 预生成10个鲸鱼钱包
        for (int i = 0; i < 10; i++) {
            String walletAddress = RandomDataUtil.randomWalletAddress();
            predefinedWhales.add(walletAddress);
            
            WhaleWallet whale = createWhaleWallet(walletAddress);
            whaleWallets.put(whale.getId(), whale);
        }
    }
    
    // 生成NFT收藏集
    public static NFTCollection generateCollection() {
        String id = RandomDataUtil.randomId();
        String name = RandomDataUtil.randomCollectionName();
        String description = "A collection of " + RandomDataUtil.randomInt(1000, 10000) + " unique " + name;
        String blockchain = RandomDataUtil.randomBlockchain();
        String contractAddress = RandomDataUtil.randomContractAddress();
        
        int totalSupply = RandomDataUtil.randomInt(1000, 10000);
        Double floorPrice = RandomDataUtil.randomFloorPrice();
        
        NFTCollection collection = NFTCollection.builder()
                .id(id)
                .name(name)
                .description(description)
                .symbol(name.replaceAll(" ", "").substring(0, Math.min(5, name.length())).toUpperCase())
                .imageUrl("https://example.com/collections/" + name.replaceAll(" ", "") + ".png")
                .bannerImageUrl("https://example.com/banners/" + name.replaceAll(" ", "") + ".png")
                .creator(RandomDataUtil.randomWalletAddress())
                .blockchain(blockchain)
                .contractAddress(contractAddress)
                .totalSupply(totalSupply)
                .floorPrice(floorPrice)
                .volume24h(floorPrice * RandomDataUtil.randomInt(10, 100))
                .volumeTotal(floorPrice * RandomDataUtil.randomInt(1000, 10000))
                .marketCap(floorPrice * totalSupply)
                .ownersCount(RandomDataUtil.randomInt(500, totalSupply))
                .category(RandomDataUtil.randomCategory())
                .verified(RandomDataUtil.randomBoolean(0.7))
                .createdAt(RandomDataUtil.randomTimestamp())
                .updatedAt(System.currentTimeMillis())
                .website("https://" + name.replaceAll(" ", "").toLowerCase() + ".io")
                .twitter("https://twitter.com/" + name.replaceAll(" ", "").toLowerCase())
                .discord("https://discord.gg/" + name.replaceAll(" ", "").toLowerCase())
                .build();
        
        collections.put(id, collection);
        return collection;
    }
    
    // 为指定收藏集生成NFT
    public static NFT generateNFT(String collectionId) {
        NFTCollection collection = collections.get(collectionId);
        if (collection == null) {
            throw new IllegalArgumentException("Collection not found: " + collectionId);
        }
        
        String id = RandomDataUtil.randomId();
        String tokenId = String.valueOf(RandomDataUtil.randomInt(1, 10000));
        
        // 为IPFS URI生成一个随机字符串
        String randomString = UUID.randomUUID().toString().replaceAll("-", "");
        int length = Math.min(randomString.length(), 44);
        
        NFT nft = NFT.builder()
                .id(id)
                .tokenId(tokenId)
                .name(collection.getName() + " #" + tokenId)
                .description("A unique NFT from the " + collection.getName() + " collection")
                .imageUrl("https://example.com/nfts/" + collection.getName().replaceAll(" ", "") + "/" + tokenId + ".png")
                .collectionId(collectionId)
                .collectionName(collection.getName())
                .creator(collection.getCreator())
                .owner(RandomDataUtil.randomWalletAddress())
                .mintPrice(RandomDataUtil.randomPrice())
                .lastSalePrice(RandomDataUtil.randomPrice())
                .blockchain(collection.getBlockchain())
                .contractAddress(collection.getContractAddress())
                .ipfsUri("ipfs://Qm" + randomString.substring(0, length))
                .metadataJson("{\"attributes\":[{\"trait_type\":\"Background\",\"value\":\"Blue\"},{\"trait_type\":\"Eyes\",\"value\":\"Sleepy\"}]}")
                .rarity(RandomDataUtil.randomInt(1, 100))
                .rarityRank(RandomDataUtil.randomRarityRank(collection.getTotalSupply()))
                .category(collection.getCategory())
                .verified(collection.getVerified())
                .createdAt(collection.getCreatedAt() + RandomDataUtil.randomInt(86400, 8640000) * 1000L)
                .updatedAt(System.currentTimeMillis())
                .floorPrice(collection.getFloorPrice())
                .status(RandomDataUtil.randomBoolean(0.3) ? "LISTED" : "UNLISTED")
                .build();
        
        nfts.put(id, nft);
        return nft;
    }
    
    // 生成NFT交易
    public static NFTTransaction generateTransaction(String nftId, boolean isWhaleTransaction) {
        NFT nft = nfts.get(nftId);
        if (nft == null) {
            throw new IllegalArgumentException("NFT not found: " + nftId);
        }
        
        String id = RandomDataUtil.randomId();
        String transactionHash = RandomDataUtil.randomTransactionHash();
        String transactionType = RandomDataUtil.randomTransactionType();
        
        String seller = nft.getOwner();
        String buyer;
        
        // 如果是鲸鱼交易，使用预定义的鲸鱼钱包
        if (isWhaleTransaction) {
            buyer = predefinedWhales.get(RandomDataUtil.randomInt(0, predefinedWhales.size() - 1));
        } else {
            buyer = RandomDataUtil.randomWalletAddress();
        }
        
        Double price;
        if (isWhaleTransaction) {
            // 鲸鱼交易价格较高
            price = RandomDataUtil.randomHighPrice();
        } else if (RandomDataUtil.randomBoolean(0.2)) {
            // 20%概率生成低价交易
            price = RandomDataUtil.randomLowPrice();
        } else {
            // 普通价格
            price = RandomDataUtil.randomPrice();
        }
        
        String marketplace = RandomDataUtil.randomMarketplace();
        Double marketplaceFee = price * 0.025; // 假设2.5%的市场费用
        Double royaltyFee = price * 0.075; // 假设7.5%的版税
        Double gasFee = RandomDataUtil.roundToDecimals(0.001 + RandomDataUtil.randomInt(1, 10) * 0.001, 6);
        
        NFTTransaction transaction = NFTTransaction.builder()
                .id(id)
                .transactionHash(transactionHash)
                .tokenId(nft.getTokenId())
                .nftId(nftId)
                .collectionId(nft.getCollectionId())
                .collectionName(nft.getCollectionName())
                .seller(seller)
                .buyer(buyer)
                .price(price)
                .currency("ETH")
                .transactionType(transactionType)
                .marketplace(marketplace)
                .marketplaceFee(marketplaceFee)
                .royaltyFee(royaltyFee)
                .gasFee(gasFee)
                .status("COMPLETED")
                .timestamp(System.currentTimeMillis())
                .blockNumber(String.valueOf(17000000 + RandomDataUtil.randomInt(1, 1000000)))
                .isWhaleTransaction(isWhaleTransaction)
                .priceUSD(price * 3000) // 假设ETH价格为3000美元
                .previousPrice(nft.getLastSalePrice())
                .priceChange(price - nft.getLastSalePrice())
                .priceChangePercent((price / nft.getLastSalePrice() - 1) * 100)
                .isOutlier(Math.abs(price / nft.getFloorPrice() - 1) > 0.5) // 如果价格偏离地板价50%以上，视为异常
                .floorDifference(price - nft.getFloorPrice())
                .build();
        
        // 更新NFT所有者和最后售价
        nft.setOwner(buyer);
        nft.setLastSalePrice(price);
        nft.setUpdatedAt(System.currentTimeMillis());
        
        // 更新用户交易数据
        updateWhaleStats(buyer, seller, transaction);
        
        // 可能产生提醒
        if (price < nft.getFloorPrice() * 0.8) {
            generateFloorPriceAlert(nft, price, marketplace);
        }
        
        transactions.put(id, transaction);
        return transaction;
    }
    
    // 更新鲸鱼钱包统计数据
    private static void updateWhaleStats(String buyer, String seller, NFTTransaction transaction) {
        // 更新买家数据
        WhaleWallet buyerWallet = whaleWallets.computeIfAbsent(buyer, NFTDataGenerator::createWhaleWallet);
        buyerWallet.setNftCount(buyerWallet.getNftCount() + 1);
        buyerWallet.setTotalValue(buyerWallet.getTotalValue() + transaction.getPrice());
        buyerWallet.setVolume24h(buyerWallet.getVolume24h() + transaction.getPrice());
        buyerWallet.setVolumeTotal(buyerWallet.getVolumeTotal() + transaction.getPrice());
        buyerWallet.setTransactionCount(buyerWallet.getTransactionCount() + 1);
        buyerWallet.setLastTransactionDate(transaction.getTimestamp());
        
        // 更新卖家数据
        if (whaleWallets.containsKey(seller)) {
            WhaleWallet sellerWallet = whaleWallets.get(seller);
            sellerWallet.setNftCount(sellerWallet.getNftCount() - 1);
            sellerWallet.setTotalValue(sellerWallet.getTotalValue() - transaction.getPrice());
            sellerWallet.setVolume24h(sellerWallet.getVolume24h() + transaction.getPrice());
            sellerWallet.setVolumeTotal(sellerWallet.getVolumeTotal() + transaction.getPrice());
            sellerWallet.setTransactionCount(sellerWallet.getTransactionCount() + 1);
            sellerWallet.setLastTransactionDate(transaction.getTimestamp());
        }
    }
    
    // 创建鲸鱼钱包
    private static WhaleWallet createWhaleWallet(String walletAddress) {
        String id = RandomDataUtil.randomId();
        
        return WhaleWallet.builder()
                .id(id)
                .walletAddress(walletAddress)
                .nickname(generateNickname())
                .totalValue(0.0)
                .nftCount(0)
                .collectionsCount(0)
                .volume24h(0.0)
                .volume7d(0.0)
                .volume30d(0.0)
                .volumeTotal(0.0)
                .firstTransactionDate(RandomDataUtil.randomTimestamp())
                .lastTransactionDate(RandomDataUtil.randomTimestamp())
                .transactionCount(0)
                .topCollections(new ArrayList<>())
                .profitLoss(0.0)
                .walletType(RandomDataUtil.randomWalletType())
                .averageHoldTime(RandomDataUtil.randomInt(1, 90) * 86400000.0) // 1-90天
                .verified(RandomDataUtil.randomBoolean(0.3))
                .whaleScore(RandomDataUtil.randomInt(50, 100) * 1.0)
                .build();
    }
    
    // 生成地板价提醒
    private static NFTAlert generateFloorPriceAlert(NFT nft, Double price, String marketplace) {
        String id = RandomDataUtil.randomId();
        
        Double floorDifference = price - nft.getFloorPrice();
        Double floorDifferencePercent = (price / nft.getFloorPrice() - 1) * 100;
        
        NFTAlert alert = NFTAlert.builder()
                .id(id)
                .nftId(nft.getId())
                .tokenId(nft.getTokenId())
                .collectionId(nft.getCollectionId())
                .collectionName(nft.getCollectionName())
                .alertType("FLOOR_PRICE")
                .price(price)
                .currency("ETH")
                .floorPrice(nft.getFloorPrice())
                .floorDifference(floorDifference)
                .floorDifferencePercent(floorDifferencePercent)
                .rarityRank(nft.getRarityRank())
                .marketplace(marketplace)
                .buyLink("https://" + marketplace.toLowerCase().replace(" ", "") + ".io/assets/" + nft.getContractAddress() + "/" + nft.getTokenId())
                .timestamp(System.currentTimeMillis())
                .status("NEW")
                .expiryTime(System.currentTimeMillis() + 3600000) // 1小时后过期
                .profitPotential(-floorDifference) // 潜在利润是地板价差的绝对值
                .riskScore(RandomDataUtil.randomInt(10, 90) * 1.0)
                .opportunityScore(RandomDataUtil.randomInt(50, 100) * 1.0)
                .build();
        
        alerts.put(id, alert);
        return alert;
    }
    
    // 生成随机的钱包昵称
    private static String generateNickname() {
        String[] prefixes = {"Crypto", "NFT", "Whale", "Degen", "Moon", "Ape", "Diamond", "Punk", "Pixel", "Alpha"};
        String[] suffixes = {"Holder", "Buyer", "Master", "King", "Queen", "Lord", "Baron", "Guru", "Wizard", "Hunter"};
        
        return prefixes[RandomDataUtil.randomInt(0, prefixes.length - 1)] + 
               suffixes[RandomDataUtil.randomInt(0, suffixes.length - 1)] + 
               RandomDataUtil.randomInt(100, 9999);
    }
    
    // 获取已生成的集合
    public static Collection<NFTCollection> getCollections() {
        return collections.values();
    }
    
    // 获取已生成的NFTs
    public static Collection<NFT> getNfts() {
        return nfts.values();
    }
    
    // 获取已生成的交易
    public static Collection<NFTTransaction> getTransactions() {
        return transactions.values();
    }
    
    // 获取已生成的鲸鱼钱包
    public static Collection<WhaleWallet> getWhaleWallets() {
        return whaleWallets.values();
    }
    
    // 获取已生成的提醒
    public static Collection<NFTAlert> getAlerts() {
        return alerts.values();
    }
    
    // 批量生成数据
    public static void generateBatchData(int collectionsCount, int nftsPerCollection, int transactionsCount) {
        logger.info("开始生成NFT数据: {} 个收藏集, 每个收藏集 {} 个NFT, {} 个交易", 
                    collectionsCount, nftsPerCollection, transactionsCount);
        
        // 生成收藏集
        List<NFTCollection> generatedCollections = IntStream.range(0, collectionsCount)
                .mapToObj(i -> generateCollection())
                .collect(Collectors.toList());
        
        // 为每个收藏集生成NFT
        List<NFT> generatedNFTs = generatedCollections.stream()
                .flatMap(collection -> IntStream.range(0, nftsPerCollection)
                        .mapToObj(i -> generateNFT(collection.getId())))
                .collect(Collectors.toList());
        
        // 生成交易
        List<String> nftIds = generatedNFTs.stream()
                .map(NFT::getId)
                .collect(Collectors.toList());
        
        IntStream.range(0, transactionsCount)
                .forEach(i -> {
                    String randomNftId = nftIds.get(RandomDataUtil.randomInt(0, nftIds.size() - 1));
                    // 20%的概率生成鲸鱼交易
                    boolean isWhaleTransaction = RandomDataUtil.randomBoolean(0.2);
                    generateTransaction(randomNftId, isWhaleTransaction);
                });
        
        logger.info("数据生成完成: 收藏集={}, NFTs={}, 交易={}, 鲸鱼钱包={}, 提醒={}",
                collections.size(), nfts.size(), transactions.size(), whaleWallets.size(), alerts.size());
    }
} 