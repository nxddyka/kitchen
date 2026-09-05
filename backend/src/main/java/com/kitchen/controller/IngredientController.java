package com.kitchen.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kitchen.common.BusinessException;
import com.kitchen.common.Result;
import com.kitchen.common.ResultCode;
import com.kitchen.entity.Ingredient;
import com.kitchen.service.IngredientService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 食材控制器
 */
@Tag(name = "食材管理", description = "食材列表与详情")
@RestController
@RequestMapping("/api/ingredients")
@RequiredArgsConstructor
public class IngredientController {

    private final IngredientService ingredientService;

    @Operation(summary = "分页查询食材列表", description = "支持按名称搜索、按分类筛选")
    @GetMapping
    public Result<Page<Ingredient>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "12") int size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String category
    ) {
        return Result.success(ingredientService.page(page, size, keyword, category));
    }

    @Operation(summary = "查询食材详情")
    @GetMapping("/{id}")
    public Result<Ingredient> detail(@PathVariable Long id) {
        Ingredient ingredient = ingredientService.getById(id);
        if (ingredient == null) {
            throw new BusinessException(ResultCode.RESOURCE_NOT_FOUND);
        }
        return Result.success(ingredient);
    }
}
