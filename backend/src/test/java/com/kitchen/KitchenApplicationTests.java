package com.kitchen;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

/**
 * 应用启动测试
 * <p>
 * 验证 Spring 容器能正常初始化所有 Bean
 * 注意：此测试需要 MySQL 连接，若本地无 MySQL 可注释掉 @SpringBootTest
 */
@SpringBootTest
@TestPropertySource(properties = {
    "spring.sql.init.mode=never"
})
class KitchenApplicationTests {

    @Test
    void contextLoads() {
        // 验证 Spring 上下文加载成功
    }
}
