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
public class NFT {
    private String id;
    private String tokenId;
    private String name;
    private String description;
    private String imageUrl;
    private String collectionId;
    private String collectionName;
    private String creator;
    private String owner;
    private Double mintPrice;
    private Double lastSalePrice;
    private String blockchain;
    private String contractAddress;
    private String ipfsUri;
    private String metadataJson;
    private Integer rarity;
    private Integer rarityRank;
    private String category;
    private Boolean verified;
    private Long createdAt;
    private Long updatedAt;
    private Double floorPrice;
    private String status; // LISTED, UNLISTED, AUCTIONED
} 