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
public class NFTCollection {
    private String id;
    private String name;
    private String description;
    private String symbol;
    private String imageUrl;
    private String bannerImageUrl;
    private String creator;
    private String blockchain;
    private String contractAddress;
    private Integer totalSupply;
    private Double floorPrice;
    private Double volume24h;
    private Double volumeTotal;
    private Double marketCap;
    private Integer ownersCount;
    private String category;
    private Boolean verified;
    private Long createdAt;
    private Long updatedAt;
    private String website;
    private String twitter;
    private String discord;
} 