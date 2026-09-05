package com.kitchen.controller;

import com.kitchen.common.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 健康检查控制器
 * <p>
 * 用于验证服务是否正常运行，无需认证
 */
@Tag(name = "系统", description = "健康检查")
@RestController
@RequestMapping("/api/health")
public class HealthController {

    @Operation(summary = "健康检查")
    @GetMapping
    public Result<Map<String, Object>> health() {
        return Result.success(Map.of(
            "status", "UP",
            "service", "kitchen-backend",
            "version", "0.1.0",
            "timestamp", LocalDateTime.now().toString()
        ));
    }
}
