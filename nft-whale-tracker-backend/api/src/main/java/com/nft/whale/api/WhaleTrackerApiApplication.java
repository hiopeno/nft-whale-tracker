package com.nft.whale.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

/**
 * NFT鲸鱼追踪API应用程序入口
 */
@SpringBootApplication
@ComponentScan(basePackages = {"com.nft.whale"})
public class WhaleTrackerApiApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(WhaleTrackerApiApplication.class, args);
    }
} 