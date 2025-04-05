package com.nft.whale.api.config;

import com.nft.whale.core.websocket.WebSocketDataProvider;
import com.nft.whale.service.whale.WhaleTrackingService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * WebSocket适配器配置
 */
@Configuration
@RequiredArgsConstructor
public class WebSocketAdapterConfig {

    private final WhaleTrackingService whaleTrackingService;

    /**
     * 创建WhaleTrackingService到WebSocketDataProvider的适配器
     */
    @Bean
    public WebSocketDataProvider webSocketDataProvider() {
        return new WebSocketDataProvider() {
            @Override
            public Object getLatestTransaction() {
                return whaleTrackingService.getLatestTransaction();
            }
        };
    }
} 