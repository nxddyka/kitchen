package com.kitchen.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 食材实体
 */
@Data
@TableName("ingredient")
public class Ingredient {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 食材名称 */
    private String name;

    /** 分类:蔬菜/水果/肉类/调料/蛋白质等 */
    private String category;

    /** 食材图片URL */
    private String imageUrl;

    /** 营养信息JSON */
    private String nutritionJson;

    /** 性味:寒/凉/温/热/平 */
    private String taste;

    /** 应季:春/夏/秋/冬/四季 */
    private String season;

    /** 食材简介 */
    private String description;

    /** 状态:1正常 0下架 */
    private Integer status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
