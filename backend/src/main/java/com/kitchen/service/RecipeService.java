package com.kitchen.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kitchen.entity.Recipe;
import com.kitchen.mapper.RecipeMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 菜谱服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RecipeService {

    private final RecipeMapper recipeMapper;

    /**
     * 分页查询菜谱
     *
     * @param page    页码
     * @param size    每页条数
     * @param keyword 搜索关键词（菜谱标题）
     * @return 分页结果
     */
    public Page<Recipe> page(int page, int size, String keyword) {
        Page<Recipe> pageObj = new Page<>(page, size);
        LambdaQueryWrapper<Recipe> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Recipe::getStatus, 1)
               .orderByDesc(Recipe::getCreatedAt);

        if (keyword != null && !keyword.isBlank()) {
            wrapper.like(Recipe::getTitle, keyword);
        }

        return recipeMapper.selectPage(pageObj, wrapper);
    }

    /**
     * 根据 ID 查询菜谱详情
     */
    public Recipe getById(Long id) {
        return recipeMapper.selectById(id);
    }
}
