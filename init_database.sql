-- =====================================================================================
-- 智能厨房辅助系统 · MySQL 数据库初始化脚本
-- =====================================================================================
-- 脚本名称: init_database.sql
-- 适用版本: MySQL 8.0+
-- 字符集:   utf8mb4 / utf8mb4_unicode_ci
-- 生成日期: 2026-08-10
-- 脚本特性:
--   1. 所有 CREATE TABLE 使用 IF NOT EXISTS，可重复执行不报错
--   2. 所有 ALTER TABLE ADD COLUMN 通过存储过程检查 information_schema 后再执行
--   3. 所有索引创建通过存储过程检查后再生效
--   4. 外键按依赖顺序创建，避免循环依赖
--   5. 脚本可安全重复执行（幂等性）
-- =====================================================================================

-- =====================================================================================
-- 【表格与字段声明清单】
-- =====================================================================================
-- 本脚本创建以下 13 张表，按依赖顺序排列：
--
-- 1. user（用户表）
--    id, username, password_hash, phone, email, avatar_url, preference_json,
--    role, status, last_login_at, created_at, updated_at
--
-- 2. ingredient（食材基础表）*** 新增 ***
--    id, name, category, image_url, nutrition_json, taste, season, description,
--    status, created_at, updated_at
--
-- 3. recipe（菜谱表）
--    id, title, description, difficulty, duration_min, cover_url, author_id,
--    servings, tags, like_count, view_count, status, created_at, updated_at
--
-- 4. recipe_ingredient（菜谱食材关联表）
--    id, recipe_id, ingredient_id, type, amount, unit
--
-- 5. recipe_step（菜谱步骤表）
--    id, recipe_id, step_no, content, image_url, duration_sec, tip
--
-- 6. section（论坛版块表）*** 新增 ***
--    id, name, description, icon_url, sort_order, post_count, status, created_at
--
-- 7. post（论坛帖子表）
--    id, recipe_id, section_id, author_id, title, content, like_count,
--    comment_count, view_count, is_essential, is_pinned, status,
--    created_at, updated_at
--
-- 8. comment（评论表）
--    id, post_id, parent_id, author_id, content, like_count, status,
--    created_at, updated_at
--
-- 9. favorite（收藏表）
--    id, user_id, target_id, target_type, created_at
--
-- 10. rating（评分表）
--     id, user_id, recipe_id, score, created_at
--
-- 11. notification（通知表）*** 新增 ***
--     id, user_id, type, title, content, target_id, target_type, is_read,
--     created_at
--
-- 12. report（举报表）*** 新增 ***
--     id, reporter_id, target_id, target_type, reason, status, handler_id,
--     handle_result, created_at, handled_at
--
-- 13. user_behavior（用户行为日志表）*** 新增 ***
--     id, user_id, action_type, target_id, target_type, extra_json, created_at
--
-- =====================================================================================


-- =====================================================================================
-- 第一部分：辅助存储过程（用于字段/索引的幂等添加）
-- =====================================================================================

-- 临时切换分隔符，以便定义存储过程
DELIMITER $$

-- -------------------------------------------------------------------------------------
-- 存储过程: add_column_if_not_exists
-- 功能: 检查某表某列是否存在，不存在则添加
-- 参数: p_table  表名, p_column 列名, p_definition 列定义(类型+属性)
-- -------------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `add_column_if_not_exists`$$
CREATE PROCEDURE `add_column_if_not_exists`(
    IN p_table      VARCHAR(128),
    IN p_column     VARCHAR(128),
    IN p_definition TEXT
)
BEGIN
    DECLARE col_count INT DEFAULT 0;

    SELECT COUNT(*) INTO col_count
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = p_table
      AND COLUMN_NAME  = p_column;

    IF col_count = 0 THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_column, '` ', p_definition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('[OK] 已添加列: ', p_table, '.', p_column) AS log_msg;
    ELSE
        SELECT CONCAT('[SKIP] 列已存在: ', p_table, '.', p_column) AS log_msg;
    END IF;
END$$


-- -------------------------------------------------------------------------------------
-- 存储过程: add_index_if_not_exists
-- 功能: 检查某索引是否存在，不存在则创建
-- 参数: p_table 表名, p_index_name 索引名, p_index_def 索引定义(完整语句片段)
-- -------------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `add_index_if_not_exists`$$
CREATE PROCEDURE `add_index_if_not_exists`(
    IN p_table      VARCHAR(128),
    IN p_index_name VARCHAR(128),
    IN p_index_def  TEXT
)
BEGIN
    DECLARE idx_count INT DEFAULT 0;

    SELECT COUNT(*) INTO idx_count
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = p_table
      AND INDEX_NAME   = p_index_name;

    IF idx_count = 0 THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD ', p_index_def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('[OK] 已创建索引: ', p_table, '.', p_index_name) AS log_msg;
    ELSE
        SELECT CONCAT('[SKIP] 索引已存在: ', p_table, '.', p_index_name) AS log_msg;
    END IF;
END$$

DELIMITER ;


-- =====================================================================================
-- 第二部分：建表（CREATE TABLE IF NOT EXISTS）
-- 按依赖顺序: user → ingredient → recipe → 关联表 → section → post → comment → 其余
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- 1. 用户表（user）
--    存储: 账号、密码、手机、邮箱、头像、饮食偏好、角色权限、登录状态
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user` (
  `id`              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `username`        VARCHAR(50)  NOT NULL UNIQUE COMMENT '用户名',
  `password_hash`   VARCHAR(255) NOT NULL COMMENT 'BCrypt加密密码',
  `phone`           VARCHAR(20)  DEFAULT NULL UNIQUE COMMENT '手机号',
  `email`           VARCHAR(100) DEFAULT NULL UNIQUE COMMENT '邮箱(登录/找回密码)',
  `avatar_url`      VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
  `preference_json` JSON         DEFAULT NULL COMMENT '饮食偏好JSON(口味/忌口/厨艺等级)',
  `role`            TINYINT      NOT NULL DEFAULT 0 COMMENT '角色:0普通用户 1版主 2管理员',
  `status`          TINYINT      NOT NULL DEFAULT 1 COMMENT '状态:1正常 0禁用',
  `last_login_at`   DATETIME     DEFAULT NULL COMMENT '最后登录时间(活跃度统计)',
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  INDEX `idx_phone` (`phone`),
  INDEX `idx_email` (`email`),
  INDEX `idx_role` (`role`),
  INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';


-- -------------------------------------------------------------------------------------
-- 2. 食材基础表（ingredient）—— 新增
--    存储: 食材名称、分类、图片、营养信息、性味、季节
--    说明: MySQL 存基础数据，Neo4j 存图谱关系，两库通过 ingredient_id 关联
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ingredient` (
  `id`              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`            VARCHAR(100) NOT NULL UNIQUE COMMENT '食材名称',
  `category`        VARCHAR(50)  NOT NULL COMMENT '分类:蔬菜/水果/肉类/调料/蛋白质等',
  `image_url`       VARCHAR(500) DEFAULT NULL COMMENT '食材图片URL',
  `nutrition_json`  JSON         DEFAULT NULL COMMENT '营养信息JSON(热量/蛋白质/维生素等)',
  `taste`           VARCHAR(50)  DEFAULT NULL COMMENT '性味:寒/凉/温/热/平',
  `season`          VARCHAR(50)  DEFAULT NULL COMMENT '应季:春/夏/秋/冬/四季',
  `description`     TEXT         DEFAULT NULL COMMENT '食材简介',
  `status`          TINYINT      NOT NULL DEFAULT 1 COMMENT '状态:1正常 0下架',
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_category` (`category`),
  INDEX `idx_season` (`season`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='食材基础表';


-- -------------------------------------------------------------------------------------
-- 3. 菜谱表（recipe）
--    存储: 标题、简介、难度、时长、封面、作者、份数、标签、热度
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `recipe` (
  `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title`          VARCHAR(200) NOT NULL COMMENT '菜谱标题',
  `description`    TEXT         DEFAULT NULL COMMENT '菜谱简介',
  `difficulty`     TINYINT      NOT NULL DEFAULT 1 COMMENT '难度:1易 2中 3难',
  `duration_min`   INT          DEFAULT NULL COMMENT '烹饪时长(分钟)',
  `cover_url`      VARCHAR(500) DEFAULT NULL COMMENT '封面图URL',
  `author_id`      BIGINT UNSIGNED NOT NULL COMMENT '作者用户ID',
  `servings`       INT          DEFAULT NULL COMMENT '建议份数(按人数换算用量)',
  `tags`           VARCHAR(200) DEFAULT NULL COMMENT '标签(逗号分隔:家常菜,快手菜,...)',
  `like_count`     INT          NOT NULL DEFAULT 0 COMMENT '点赞数',
  `view_count`     INT          NOT NULL DEFAULT 0 COMMENT '浏览数',
  `status`         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态:1正常 0下架',
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_author` (`author_id`),
  INDEX `idx_difficulty` (`difficulty`),
  INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜谱表';


-- -------------------------------------------------------------------------------------
-- 4. 菜谱食材关联表（recipe_ingredient）
--    存储: 菜谱与食材的多对多关系，标注主料/辅料及用量
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `recipe_ingredient` (
  `id`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `recipe_id`     BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
  `ingredient_id` BIGINT UNSIGNED NOT NULL COMMENT '食材ID',
  `type`          ENUM('main','aux') NOT NULL DEFAULT 'main' COMMENT '类型:main主料 aux辅料',
  `amount`        DECIMAL(8,2)   DEFAULT NULL COMMENT '用量',
  `unit`          VARCHAR(20)    DEFAULT NULL COMMENT '单位(g/ml/个/勺)',
  UNIQUE KEY `uk_recipe_ingredient` (`recipe_id`, `ingredient_id`),
  INDEX `idx_ingredient` (`ingredient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜谱食材关联表';


-- -------------------------------------------------------------------------------------
-- 5. 菜谱步骤表（recipe_step）
--    存储: 菜谱的图文步骤，含序号、配图、耗时、小贴士
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `recipe_step` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `recipe_id`   BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
  `step_no`     INT NOT NULL COMMENT '步骤序号(从1开始)',
  `content`     TEXT NOT NULL COMMENT '步骤内容',
  `image_url`   VARCHAR(500) DEFAULT NULL COMMENT '步骤配图URL',
  `duration_sec` INT         DEFAULT NULL COMMENT '步骤耗时(秒)',
  `tip`         VARCHAR(200) DEFAULT NULL COMMENT '小贴士',
  INDEX `idx_recipe` (`recipe_id`, `step_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜谱步骤表';


-- -------------------------------------------------------------------------------------
-- 6. 论坛版块表（section）—— 新增
--    存储: 版块名称、描述、图标、排序、帖子数
--    说明: post 表引用 section_id，此表为前置依赖
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `section` (
  `id`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`          VARCHAR(100) NOT NULL UNIQUE COMMENT '版块名称',
  `description`   VARCHAR(500) DEFAULT NULL COMMENT '版块描述',
  `icon_url`      VARCHAR(500) DEFAULT NULL COMMENT '版块图标URL',
  `sort_order`    INT          NOT NULL DEFAULT 0 COMMENT '排序(越小越靠前)',
  `post_count`    INT          NOT NULL DEFAULT 0 COMMENT '帖子数(冗余计数)',
  `status`        TINYINT      NOT NULL DEFAULT 1 COMMENT '状态:1正常 0关闭',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='论坛版块表';


-- -------------------------------------------------------------------------------------
-- 7. 论坛帖子表（post）
--    存储: 帖子标题、富文本内容、关联菜谱/版块、点赞/评论/浏览数、精华/置顶
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `post` (
  `id`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `recipe_id`     BIGINT UNSIGNED DEFAULT NULL COMMENT '关联菜谱ID(可为空)',
  `section_id`    BIGINT UNSIGNED DEFAULT NULL COMMENT '版块ID',
  `author_id`     BIGINT UNSIGNED NOT NULL COMMENT '发帖用户ID',
  `title`         VARCHAR(200) NOT NULL COMMENT '帖子标题',
  `content`       LONGTEXT NOT NULL COMMENT '富文本内容',
  `like_count`    INT NOT NULL DEFAULT 0 COMMENT '点赞数',
  `comment_count` INT NOT NULL DEFAULT 0 COMMENT '评论数',
  `view_count`    INT NOT NULL DEFAULT 0 COMMENT '浏览数',
  `is_essential`  TINYINT NOT NULL DEFAULT 0 COMMENT '是否精华:0否 1是',
  `is_pinned`     TINYINT NOT NULL DEFAULT 0 COMMENT '是否置顶:0否 1是',
  `status`        TINYINT NOT NULL DEFAULT 1 COMMENT '状态:1正常 0删除 2屏蔽',
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '编辑时间',
  INDEX `idx_author` (`author_id`),
  INDEX `idx_section` (`section_id`),
  INDEX `idx_recipe` (`recipe_id`),
  INDEX `idx_essential` (`is_essential`),
  INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='论坛帖子表';


-- -------------------------------------------------------------------------------------
-- 8. 评论表（comment）
--    存储: 帖子评论及楼中楼回复，含点赞数和状态
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `comment` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `post_id`     BIGINT UNSIGNED NOT NULL COMMENT '帖子ID',
  `parent_id`   BIGINT UNSIGNED DEFAULT NULL COMMENT '父评论ID(楼中楼回复)',
  `author_id`   BIGINT UNSIGNED NOT NULL COMMENT '评论用户ID',
  `content`     VARCHAR(1000) NOT NULL COMMENT '评论内容',
  `like_count`  INT NOT NULL DEFAULT 0 COMMENT '点赞数',
  `status`      TINYINT NOT NULL DEFAULT 1 COMMENT '状态:1正常 0删除 2屏蔽',
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '编辑时间',
  INDEX `idx_post` (`post_id`),
  INDEX `idx_author` (`author_id`),
  INDEX `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论表';


-- -------------------------------------------------------------------------------------
-- 9. 收藏表（favorite）
--    存储: 用户对菜谱或帖子的收藏，通过 target_type 区分
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `favorite` (
  `id`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`       BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `target_id`     BIGINT UNSIGNED NOT NULL COMMENT '目标ID',
  `target_type`   ENUM('recipe','post') NOT NULL COMMENT '目标类型:recipe菜谱 post帖子',
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_target` (`user_id`, `target_id`, `target_type`),
  INDEX `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏表';


-- -------------------------------------------------------------------------------------
-- 10. 评分表（rating）
--     存储: 用户对菜谱的1-5星评分，一人一菜一评
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `rating` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`     BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `recipe_id`   BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
  `score`       TINYINT NOT NULL COMMENT '评分1-5星',
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_recipe` (`user_id`, `recipe_id`),
  INDEX `idx_recipe` (`recipe_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评分表';


-- -------------------------------------------------------------------------------------
-- 11. 通知表（notification）—— 新增
--     存储: 系统通知、评论回复提醒、点赞提醒等
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notification` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`     BIGINT UNSIGNED NOT NULL COMMENT '接收通知的用户ID',
  `type`        VARCHAR(30) NOT NULL COMMENT '类型:comment/reply/like/system/report',
  `title`       VARCHAR(200) NOT NULL COMMENT '通知标题',
  `content`     VARCHAR(500) DEFAULT NULL COMMENT '通知内容',
  `target_id`   BIGINT UNSIGNED DEFAULT NULL COMMENT '关联目标ID(帖子/评论/菜谱ID)',
  `target_type` VARCHAR(20)  DEFAULT NULL COMMENT '目标类型:post/comment/recipe',
  `is_read`     TINYINT NOT NULL DEFAULT 0 COMMENT '是否已读:0未读 1已读',
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_read` (`user_id`, `is_read`),
  INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知表';


-- -------------------------------------------------------------------------------------
-- 12. 举报表（report）—— 新增
--     存储: 用户举报帖子/评论的记录及处理结果
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `report` (
  `id`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `reporter_id`   BIGINT UNSIGNED NOT NULL COMMENT '举报人ID',
  `target_id`     BIGINT UNSIGNED NOT NULL COMMENT '被举报目标ID',
  `target_type`   ENUM('post','comment') NOT NULL COMMENT '目标类型:post帖子 comment评论',
  `reason`        VARCHAR(500) NOT NULL COMMENT '举报理由',
  `status`        TINYINT NOT NULL DEFAULT 0 COMMENT '状态:0待处理 1已处理-违规 2已处理-无误',
  `handler_id`    BIGINT UNSIGNED DEFAULT NULL COMMENT '处理人(管理员)ID',
  `handle_result` VARCHAR(500) DEFAULT NULL COMMENT '处理结果说明',
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `handled_at`    DATETIME DEFAULT NULL COMMENT '处理时间',
  INDEX `idx_status` (`status`),
  INDEX `idx_target` (`target_id`, `target_type`),
  INDEX `idx_reporter` (`reporter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='举报表';


-- -------------------------------------------------------------------------------------
-- 13. 用户行为日志表（user_behavior）—— 新增
--     存储: 用户浏览/收藏/评分/搜索等行为，用于推荐系统训练
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_behavior` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`     BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `action_type` VARCHAR(30) NOT NULL COMMENT '行为类型:view/favorite/rate/search/share',
  `target_id`   BIGINT UNSIGNED DEFAULT NULL COMMENT '目标ID',
  `target_type` VARCHAR(20) DEFAULT NULL COMMENT '目标类型:recipe/post/ingredient',
  `extra_json`  JSON DEFAULT NULL COMMENT '附加信息(搜索关键词/评分值等)',
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user` (`user_id`),
  INDEX `idx_action` (`action_type`),
  INDEX `idx_target` (`target_id`, `target_type`),
  INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户行为日志表';


-- =====================================================================================
-- 第三部分：补充缺失字段（幂等添加，用于已有表升级）
-- 通过 add_column_if_not_exists 存储过程检查后执行，安全可重复
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- user 表补充字段（从原 aaa.txt 升级时执行）
-- -------------------------------------------------------------------------------------
CALL add_column_if_not_exists('user', 'email',         "VARCHAR(100) DEFAULT NULL COMMENT '邮箱(登录/找回密码)'");
CALL add_column_if_not_exists('user', 'role',          "TINYINT NOT NULL DEFAULT 0 COMMENT '角色:0普通用户 1版主 2管理员'");
CALL add_column_if_not_exists('user', 'last_login_at', "DATETIME DEFAULT NULL COMMENT '最后登录时间'");

-- -------------------------------------------------------------------------------------
-- ingredient 表补充字段
-- -------------------------------------------------------------------------------------
CALL add_column_if_not_exists('ingredient', 'taste',        "VARCHAR(50) DEFAULT NULL COMMENT '性味:寒/凉/温/热/平'");
CALL add_column_if_not_exists('ingredient', 'season',       "VARCHAR(50) DEFAULT NULL COMMENT '应季:春/夏/秋/冬/四季'");
CALL add_column_if_not_exists('ingredient', 'description',  "TEXT DEFAULT NULL COMMENT '食材简介'");
CALL add_column_if_not_exists('ingredient', 'image_url',    "VARCHAR(500) DEFAULT NULL COMMENT '食材图片URL'");
CALL add_column_if_not_exists('ingredient', 'nutrition_json', "JSON DEFAULT NULL COMMENT '营养信息JSON'");
CALL add_column_if_not_exists('ingredient', 'status',       "TINYINT NOT NULL DEFAULT 1 COMMENT '状态:1正常 0下架'");
CALL add_column_if_not_exists('ingredient', 'updated_at',   "DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");

-- -------------------------------------------------------------------------------------
-- recipe 表补充字段
-- -------------------------------------------------------------------------------------
CALL add_column_if_not_exists('recipe', 'servings', "INT DEFAULT NULL COMMENT '建议份数(按人数换算用量)'");
CALL add_column_if_not_exists('recipe', 'tags',    "VARCHAR(200) DEFAULT NULL COMMENT '标签(逗号分隔)'");

-- -------------------------------------------------------------------------------------
-- post 表补充字段
-- -------------------------------------------------------------------------------------
CALL add_column_if_not_exists('post', 'updated_at',    "DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '编辑时间'");
CALL add_column_if_not_exists('post', 'is_essential',  "TINYINT NOT NULL DEFAULT 0 COMMENT '是否精华:0否 1是'");
CALL add_column_if_not_exists('post', 'is_pinned',     "TINYINT NOT NULL DEFAULT 0 COMMENT '是否置顶:0否 1是'");

-- -------------------------------------------------------------------------------------
-- comment 表补充字段
-- -------------------------------------------------------------------------------------
CALL add_column_if_not_exists('comment', 'updated_at', "DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '编辑时间'");
CALL add_column_if_not_exists('comment', 'status',     "TINYINT NOT NULL DEFAULT 1 COMMENT '状态:1正常 0删除 2屏蔽'");


-- =====================================================================================
-- 第四部分：补充索引（幂等创建）
-- =====================================================================================

-- user 表索引
CALL add_index_if_not_exists('user', 'idx_email', "INDEX `idx_email` (`email`)");
CALL add_index_if_not_exists('user', 'idx_role',  "INDEX `idx_role` (`role`)");

-- ingredient 表索引
CALL add_index_if_not_exists('ingredient', 'idx_category', "INDEX `idx_category` (`category`)");
CALL add_index_if_not_exists('ingredient', 'idx_season',   "INDEX `idx_season` (`season`)");

-- recipe 表索引
CALL add_index_if_not_exists('recipe', 'idx_difficulty', "INDEX `idx_difficulty` (`difficulty`)");

-- post 表索引
CALL add_index_if_not_exists('post', 'idx_recipe',    "INDEX `idx_recipe` (`recipe_id`)");
CALL add_index_if_not_exists('post', 'idx_essential', "INDEX `idx_essential` (`is_essential`)");

-- comment 表索引
CALL add_index_if_not_exists('comment', 'idx_parent', "INDEX `idx_parent` (`parent_id`)");

-- recipe 表全文索引（MySQL 8.0 ngram 分词器，支持中文全文搜索）
-- 注意: FULLTEXT 索引无法通过 ALTER TABLE ADD INDEX 幂等添加，
--       此处用存储过程检查后用专门的语句创建
-- 若数据库已支持 ngram，取消下面注释即可
-- CALL add_index_if_not_exists('recipe', 'ft_search', "FULLTEXT INDEX `ft_search` (`title`, `description`) WITH PARSER ngram");
-- CALL add_index_if_not_exists('post', 'ft_search', "FULLTEXT INDEX `ft_search` (`title`, `content`) WITH PARSER ngram");


-- =====================================================================================
-- 第五部分：清理临时存储过程
-- =====================================================================================

DROP PROCEDURE IF EXISTS `add_column_if_not_exists`;
DROP PROCEDURE IF EXISTS `add_index_if_not_exists`;


-- =====================================================================================
-- 脚本执行完毕
-- 验证方式:
--   SHOW TABLES;                                    -- 查看所有表
--   SELECT TABLE_NAME, TABLE_COMMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE();
--   SELECT COLUMN_NAME, COLUMN_TYPE, COLUMN_COMMENT FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user';
-- =====================================================================================
