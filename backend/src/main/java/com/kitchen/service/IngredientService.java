package com.kitchen.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kitchen.entity.Ingredient;
import com.kitchen.mapper.IngredientMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 食材服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class IngredientService {

    private final IngredientMapper ingredientMapper;

    /**
     * 分页查询食材
     *
     * @param page     页码
     * @param size     每页条数
     * @param keyword  搜索关键词（食材名称）
     * @param category 分类筛选
     * @return 分页结果
     */
    public Page<Ingredient> page(int page, int size, String keyword, String category) {
        Page<Ingredient> pageObj = new Page<>(page, size);
        LambdaQueryWrapper<Ingredient> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Ingredient::getStatus, 1)
               .orderByDesc(Ingredient::getCreatedAt);

        if (keyword != null && !keyword.isBlank()) {
            wrapper.like(Ingredient::getName, keyword);
        }
        if (category != null && !category.isBlank()) {
            wrapper.eq(Ingredient::getCategory, category);
        }

        return ingredientMapper.selectPage(pageObj, wrapper);
    }

    /**
     * 根据 ID 查询食材详情
     */
    public Ingredient getById(Long id) {
        Ingredient ingredient = ingredientMapper.selectById(id);
        if (ingredient == null) {
            return null;
        }
        return ingredient;
    }
}
