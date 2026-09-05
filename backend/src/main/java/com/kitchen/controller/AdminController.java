package com.kitchen.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kitchen.common.Result;
import com.kitchen.entity.User;
import com.kitchen.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 管理后台控制器（仅管理员可访问）
 * <p>
 * 由 SecurityConfig 中 .requestMatchers("/admin/**").hasRole("ADMIN") 保证权限
 */
@Tag(name = "系统管理", description = "用户管理（仅管理员）")
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final UserService userService;

    @Operation(summary = "分页查询用户列表", description = "仅管理员可调用")
    @GetMapping("/users")
    public Result<Page<User>> userList(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword
    ) {
        return Result.success(userService.page(page, size, keyword));
    }

    @Operation(summary = "更新用户状态", description = "0禁用 1启用")
    @PutMapping("/users/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam int status) {
        userService.updateStatus(id, status);
        return Result.success();
    }

    @Operation(summary = "更新用户角色", description = "0普通用户 1版主 2管理员")
    @PutMapping("/users/{id}/role")
    public Result<Void> updateRole(@PathVariable Long id, @RequestParam int role) {
        userService.updateRole(id, role);
        return Result.success();
    }
}
