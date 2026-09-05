package com.kitchen.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 菜谱实体
 */
@Data
@TableName("recipe")
public class Recipe {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String title;

    private String description;

    /** 难度: 1易 2中 3难 */
    private Integer difficulty;

    private Integer durationMin;

    private String coverUrl;

    private Long authorId;

    private Integer servings;

    private String tags;

    private Integer likeCount;

    private Integer viewCount;

    /** 状态: 1正常 0下架 */
    private Integer status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
