package com.nft.whale.api.controller.whale;

import com.nft.whale.api.service.PaimonQueryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * 鲸鱼数据API控制器
 */
@RestController
@RequestMapping("/whale")
@RequiredArgsConstructor
@Slf4j
public class WhaleDataController {

    private final PaimonQueryService paimonQueryService;

    /**
     * 查询最近的NFT交易
     *
     * @param limit 限制条数，默认20
     * @return 交易数据列表
     */
    @GetMapping("/transactions")
    public ResponseEntity<List<Map<String, Object>>> getRecentTransactions(
            @RequestParam(value = "limit", defaultValue = "20") int limit) {
        log.info("查询最近NFT交易数据，限制{}条", limit);
        List<Map<String, Object>> transactions = paimonQueryService.queryRecentNFTTransactions(limit);
        return ResponseEntity.ok(transactions);
    }

    /**
     * 查询鲸鱼钱包列表
     *
     * @param limit 限制条数，默认10
     * @return 鲸鱼钱包数据列表
     */
    @GetMapping("/wallets")
    public ResponseEntity<List<Map<String, Object>>> getWhaleWallets(
            @RequestParam(value = "limit", defaultValue = "10") int limit) {
        log.info("查询鲸鱼钱包数据，限制{}条", limit);
        List<Map<String, Object>> wallets = paimonQueryService.queryWhaleWallets(limit);
        return ResponseEntity.ok(wallets);
    }

    /**
     * 查询热门NFT集合
     *
     * @param limit 限制条数，默认10
     * @return 热门NFT集合列表
     */
    @GetMapping("/collections")
    public ResponseEntity<List<Map<String, Object>>> getHotCollections(
            @RequestParam(value = "limit", defaultValue = "10") int limit) {
        log.info("查询热门NFT集合，限制{}条", limit);
        List<Map<String, Object>> collections = paimonQueryService.queryHotNFTCollections(limit);
        return ResponseEntity.ok(collections);
    }

    /**
     * 执行自定义SQL查询
     *
     * @param sql SQL语句
     * @return 查询结果
     */
    @PostMapping("/query")
    public CompletableFuture<ResponseEntity<List<Map<String, Object>>>> executeQuery(
            @RequestBody String sql) {
        log.info("执行自定义SQL查询: {}", sql);
        return paimonQueryService.executeQueryAsync(sql)
                .thenApply(ResponseEntity::ok);
    }
} 