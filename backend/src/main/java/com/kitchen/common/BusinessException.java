package com.kitchen.common;

import lombok.Getter;

/**
 * 业务异常
 * <p>
 * 用于在业务逻辑中抛出可预期的错误，由全局异常处理器捕获后返回给前端
 */
@Getter
public class BusinessException extends RuntimeException {

    private final int code;

    public BusinessException(String message) {
        super(message);
        this.code = ResultCode.FAIL.getCode();
    }

    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }

    public BusinessException(ResultCode resultCode) {
        super(resultCode.getMessage());
        this.code = resultCode.getCode();
    }
}
