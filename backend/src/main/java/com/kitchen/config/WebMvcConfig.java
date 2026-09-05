package com.kitchen.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC 配置
 * <p>
 * 将干净 URL（无 .html 后缀）转发到对应的静态 HTML 文件
 * 例如：/login → forward:/login.html
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // 根路径 → index.html（由 index.html 内 JS 判断登录状态后跳转）
        registry.addViewController("/").setViewName("forward:/index.html");

        // 页面路由：干净 URL → 对应 HTML 文件
        registry.addViewController("/login").setViewName("forward:/login.html");
        registry.addViewController("/ingredients").setViewName("forward:/ingredients.html");
        registry.addViewController("/recipes").setViewName("forward:/recipes.html");
        registry.addViewController("/forum").setViewName("forward:/forum.html");
        registry.addViewController("/profile").setViewName("forward:/profile.html");
    }
}
