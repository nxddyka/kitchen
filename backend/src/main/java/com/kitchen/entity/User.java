package com.kitchen.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户实体
 */
@Data
@TableName("user")
public class User {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String username;

    private String passwordHash;

    private String phone;

    private String email;

    private String avatarUrl;

    /** 饮食偏好 JSON 字符串，MyBatis-Plus 自动映射 */
    private String preferenceJson;

    /** 角色: 0普通用户 1版主 2管理员 */
    private Integer role;

    /** 状态: 1正常 0禁用 */
    private Integer status;

    private LocalDateTime lastLoginAt;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    /** 登录响应时脱敏，不返回密码 */
    @TableField(exist = false)
    private String token;
}
