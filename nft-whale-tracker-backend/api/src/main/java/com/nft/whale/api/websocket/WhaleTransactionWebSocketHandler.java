package com.nft.whale.api.websocket;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nft.whale.api.service.PaimonQueryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * 鲸鱼交易WebSocket处理器
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class WhaleTransactionWebSocketHandler extends TextWebSocketHandler {

    private final PaimonQueryService paimonQueryService;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final List<WebSocketSession> sessions = new CopyOnWriteArrayList<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        log.info("建立新的WebSocket连接: {}", session.getId());
        sessions.add(session);
        
        // 连接建立后立即发送一些初始数据
        try {
            List<Map<String, Object>> transactions = paimonQueryService.queryRecentNFTTransactions(10);
            if (!transactions.isEmpty()) {
                sendToSession(session, transactions);
            }
        } catch (Exception e) {
            log.error("发送初始数据失败: {}", e.getMessage(), e);
        }
    }

    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) {
        log.info("收到消息: {}", message.getPayload());
        // 这里可以处理客户端发来的消息，如特定查询请求
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        log.info("WebSocket连接关闭: {}, 状态: {}", session.getId(), status);
        sessions.remove(session);
    }

    /**
     * 定时查询最新交易并推送
     * 每5秒执行一次
     */
    @Scheduled(fixedRate = 5000)
    public void pushLatestTransactions() {
        if (sessions.isEmpty()) {
            return; // 没有活跃连接，不执行查询
        }
        
        try {
            List<Map<String, Object>> transactions = paimonQueryService.queryRecentNFTTransactions(5);
            if (!transactions.isEmpty()) {
                broadcastToAllSessions(transactions);
            }
        } catch (Exception e) {
            log.error("推送最新交易数据失败: {}", e.getMessage(), e);
        }
    }
    
    /**
     * 向所有会话广播消息
     */
    private void broadcastToAllSessions(Object data) {
        String message;
        try {
            message = objectMapper.writeValueAsString(data);
        } catch (JsonProcessingException e) {
            log.error("序列化消息失败: {}", e.getMessage(), e);
            return;
        }
        
        TextMessage textMessage = new TextMessage(message);
        
        for (WebSocketSession session : sessions) {
            if (session.isOpen()) {
                try {
                    session.sendMessage(textMessage);
                } catch (IOException e) {
                    log.error("发送消息到会话{}失败: {}", session.getId(), e.getMessage(), e);
                }
            }
        }
    }
    
    /**
     * 向特定会话发送消息
     */
    private void sendToSession(WebSocketSession session, Object data) {
        if (!session.isOpen()) {
            return;
        }
        
        try {
            String message = objectMapper.writeValueAsString(data);
            session.sendMessage(new TextMessage(message));
        } catch (IOException e) {
            log.error("发送消息到会话{}失败: {}", session.getId(), e.getMessage(), e);
        }
    }
} 