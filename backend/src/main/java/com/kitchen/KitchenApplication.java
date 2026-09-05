package com.kitchen;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 智能厨房辅助系统 · 后端启动类
 */
@SpringBootApplication
@MapperScan("com.kitchen.mapper")
public class KitchenApplication {

    public static void main(String[] args) {
        SpringApplication.run(KitchenApplication.class, args);
    }
}
