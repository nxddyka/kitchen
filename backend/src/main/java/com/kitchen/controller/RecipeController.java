package com.kitchen.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kitchen.common.BusinessException;
import com.kitchen.common.Result;
import com.kitchen.common.ResultCode;
import com.kitchen.entity.Recipe;
import com.kitchen.service.RecipeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 菜谱控制器
 * <p>
 * Controller 只负责参数接收与响应，查询逻辑下沉至 RecipeService
 */
@Tag(name = "菜谱管理", description = "菜谱浏览与详情")
@RestController
@RequestMapping("/api/recipes")
@RequiredArgsConstructor
public class RecipeController {

    private final RecipeService recipeService;

    @Operation(summary = "分页查询菜谱", description = "支持按标题关键词搜索")
    @GetMapping
    public Result<Page<Recipe>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword
    ) {
        return Result.success(recipeService.page(page, size, keyword));
    }

    @Operation(summary = "查询菜谱详情")
    @GetMapping("/{id}")
    public Result<Recipe> detail(@PathVariable Long id) {
        Recipe recipe = recipeService.getById(id);
        if (recipe == null) {
            throw new BusinessException(ResultCode.RESOURCE_NOT_FOUND);
        }
        return Result.success(recipe);
    }
}
