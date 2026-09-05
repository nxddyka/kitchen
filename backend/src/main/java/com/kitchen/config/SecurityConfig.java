package com.kitchen.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kitchen.common.Result;
import com.kitchen.common.ResultCode;
import com.kitchen.security.JwtAuthenticationFilter;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Spring Security 配置
 * <p>
 * - 静态页面和资源：全部放行（页面内 JS 自行检查登录状态）
 * - API 接口：/api/auth/** 和 /api/health 放行，其余需 JWT 认证
 * - /api/admin/** 仅管理员可访问
 * - 未认证返回 401 JSON，前端拦截后跳转登录页
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // 放行 OPTIONS 预检
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                // 放行 Knife4j / Swagger 文档路径
                .requestMatchers(
                        "/doc.html",
                        "/swagger-ui.html",
                        "/swagger-ui/**",
                        "/v3/api-docs/**",
                        "/webjars/**",
                        "/favicon.ico"
                ).permitAll()
                // 放行 API：登录注册、健康检查
                .requestMatchers("/api/auth/**", "/api/health").permitAll()
                // 管理后台仅管理员可访问
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                // 其余 /api/** 接口需认证
                .requestMatchers("/api/**").authenticated()
                // 非 /api 路径（页面路由）全部放行
                .anyRequest().permitAll()
            )
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint((request, response, authException) -> {
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.setCharacterEncoding("UTF-8");
                    Result<Void> result = Result.of(ResultCode.UNAUTHORIZED);
                    new ObjectMapper().writeValue(response.getWriter(), result);
                })
                .accessDeniedHandler((request, response, accessDeniedException) -> {
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.setCharacterEncoding("UTF-8");
                    Result<Void> result = Result.of(ResultCode.FORBIDDEN);
                    new ObjectMapper().writeValue(response.getWriter(), result);
                })
            )
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
