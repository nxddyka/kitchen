package com.kitchen.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Knife4j 配置
 * <p>
 * - 界面标题：智能厨房辅助系统 API 文档
 * - 接口分组：Auth 认证模块 / Biz 业务模块 / Sys 系统模块
 * - 访问地址：http://localhost:8080/kitchen/doc.html
 * - 文档访问受 Knife4j basic auth 保护（配置在 application.yml）
 */
@Configuration
public class Knife4jConfig {

    // ==================== 分组配置 ====================

    /** Auth 认证模块：登录、注册 */
    @Bean
    public GroupedOpenApi authGroup() {
        return GroupedOpenApi.builder()
                .group("Auth-认证模块")
                .pathsToMatch("/api/auth/**")
                .build();
    }

    /** Biz 业务模块：食材管理、菜谱推荐 */
    @Bean
    public GroupedOpenApi bizGroup() {
        return GroupedOpenApi.builder()
                .group("Biz-业务模块")
                .pathsToMatch("/api/recipes/**", "/api/ingredients/**")
                .build();
    }

    /** Sys 系统模块：健康检查、用户管理 */
    @Bean
    public GroupedOpenApi sysGroup() {
        return GroupedOpenApi.builder()
                .group("Sys-系统模块")
                .pathsToMatch("/api/health/**", "/api/admin/**")
                .build();
    }

    // ==================== 全局 OpenAPI 配置 ====================

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("智能厨房辅助系统 API 文档")
                .description("AI 驱动的食材识别与菜谱推荐平台 · 后端接口文档")
                .version("0.1.0")
                .contact(new Contact().name("Kitchen Team")))
            // JWT 认证方案
            .addSecurityItem(new SecurityRequirement().addList("Bearer Authentication"))
            .components(new io.swagger.v3.oas.models.Components()
                .addSecuritySchemes("Bearer Authentication",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")
                        .in(SecurityScheme.In.HEADER)
                        .name("Authorization")));
    }
}
