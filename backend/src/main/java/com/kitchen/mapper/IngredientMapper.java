package com.kitchen.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kitchen.entity.Ingredient;
import org.apache.ibatis.annotations.Mapper;

/**
 * 食材 Mapper
 */
@Mapper
public interface IngredientMapper extends BaseMapper<Ingredient> {
}
