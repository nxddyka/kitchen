package com.kitchen.common;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 系统响应码枚举
 */
@Getter
@AllArgsConstructor
public enum ResultCode {

    SUCCESS(200, "成功"),
    FAIL(500, "失败"),

    // 认证相关 4xx
    UNAUTHORIZED(401, "未登录或登录已过期"),
    FORBIDDEN(403, "无权限访问"),
    BAD_CREDENTIALS(4011, "用户名或密码错误"),
    ACCOUNT_DISABLED(4012, "账号已被禁用"),
    TOKEN_EXPIRED(4013, "Token已过期"),

    // 业务相关 5xx
    PARAM_ERROR(400, "参数校验失败"),
    RESOURCE_NOT_FOUND(404, "资源不存在"),
    RESOURCE_CONFLICT(409, "资源冲突（如用户名已存在）"),
    INTERNAL_ERROR(500, "系统内部错误");

    private final int code;
    private final String message;
}
