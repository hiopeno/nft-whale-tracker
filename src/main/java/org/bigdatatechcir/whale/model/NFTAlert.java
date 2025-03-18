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
public class NFTAlert {
    private String id;
    private String nftId;
    private String tokenId;
    private String collectionId;
    private String collectionName;
    private String alertType; // FLOOR_PRICE, WHALE_PURCHASE, PRICE_DROP, RARE_LISTING
    private Double price;
    private String currency;
    private Double floorPrice;
    private Double floorDifference;
    private Double floorDifferencePercent;
    private Integer rarityRank;
    private String marketplace;
    private String buyLink;
    private Long timestamp;
    private String status; // NEW, NOTIFIED, EXPIRED, SOLD
    private Long expiryTime;
    private String buyer; // 若已售出
    private Long soldTime; // 若已售出
    private Double soldPrice; // 若已售出
    private Double profitPotential; // 潜在利润
    private Double riskScore; // 风险评分
    private Double opportunityScore; // 机会评分
} 