package com.nft.whale.core.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.standard.ServerEndpointExporter;

/**
 * WebSocket基础配置类
 */
@Configuration
@EnableWebSocket
public class WebSocketBaseConfig implements WebSocketConfigurer {

    /**
     * 注册WebSocket处理器
     *
     * @param registry WebSocket处理器注册表
     */
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // WebSocket处理器将在具体实现中注册
    }

    /**
     * 注册ServerEndpointExporter Bean
     * 该Bean会自动注册使用@ServerEndpoint注解声明的端点
     *
     * @return ServerEndpointExporter实例
     */
    @Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }
} 