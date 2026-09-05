package com.kitchen.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kitchen.entity.Recipe;
import org.apache.ibatis.annotations.Mapper;

/**
 * 菜谱 Mapper
 */
@Mapper
public interface RecipeMapper extends BaseMapper<Recipe> {
}
