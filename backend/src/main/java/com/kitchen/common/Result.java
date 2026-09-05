package com.kitchen.common;

import lombok.Data;

/**
 * 统一响应结果封装
 *
 * @param <T> 数据类型
 */
@Data
public class Result<T> {

    private int code;
    private String message;
    private T data;

    private Result(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    /** 成功（无数据） */
    public static <T> Result<T> success() {
        return new Result<>(ResultCode.SUCCESS.getCode(), ResultCode.SUCCESS.getMessage(), null);
    }

    /** 成功（带数据） */
    public static <T> Result<T> success(T data) {
        return new Result<>(ResultCode.SUCCESS.getCode(), ResultCode.SUCCESS.getMessage(), data);
    }

    /** 失败（自定义消息） */
    public static <T> Result<T> error(String message) {
        return new Result<>(ResultCode.FAIL.getCode(), message, null);
    }

    /** 失败（自定义错误码） */
    public static <T> Result<T> error(int code, String message) {
        return new Result<>(code, message, null);
    }

    /** 根据枚举构建 */
    public static <T> Result<T> of(ResultCode resultCode) {
        return new Result<>(resultCode.getCode(), resultCode.getMessage(), null);
    }
}
