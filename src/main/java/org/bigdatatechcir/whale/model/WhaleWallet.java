package org.bigdatatechcir.whale.model;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class WhaleWallet {
    private String id;
    private String walletAddress;
    private String nickname;
    private Double totalValue;
    private Integer nftCount;
    private Integer collectionsCount;
    private Double volume24h;
    private Double volume7d;
    private Double volume30d;
    private Double volumeTotal;
    private Long firstTransactionDate;
    private Long lastTransactionDate;
    private Integer transactionCount;
    private List<String> topCollections;
    private Double profitLoss;
    private String walletType; // COLLECTOR, TRADER, HOLDER, FLIPPER
    private Double averageHoldTime;
    private Boolean verified;
    private String profileImageUrl;
    private String twitter;
    private String website;
    private Double whaleScore; // 鲸鱼评分，影响力指数
} 