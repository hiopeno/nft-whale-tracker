package org.bigdatatechcir.whale.model;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import com.fasterxml.jackson.annotation.JsonInclude;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class NFTTransaction {
    private String id;
    private String transactionHash;
    private String tokenId;
    private String nftId;
    private String collectionId;
    private String collectionName;
    private String seller;
    private String buyer;
    private Double price;
    private String currency;
    private String transactionType; // MINT, TRANSFER, SALE, AUCTION, OFFER_ACCEPTED, BID_WON
    private String marketplace;
    private Double marketplaceFee;
    private Double royaltyFee;
    private Double gasFee;
    private String status; // PENDING, COMPLETED, FAILED
    private Long timestamp;
    private String blockNumber;
    private Boolean isWhaleTransaction;
    private Double priceUSD;
    private Double previousPrice;
    private Double priceChange;
    private Double priceChangePercent;
    private Boolean isOutlier; // 价格是否异常偏离
    private Double floorDifference; // 与地板价的差距
} 