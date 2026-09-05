-- =====================================================================================
-- 智能厨房辅助系统 · 数据库初始化脚本（Spring Boot 启动自动执行）
-- =====================================================================================
-- 说明：本脚本已整合 init_database.sql 为基准，兼容 Spring Boot schema.sql 初始化机制
--       （去除了 Spring Boot jdbc-init 不支持的 DELIMITER / 存储过程语法）
--
-- 包含 13 张表：
--   1. user（用户表）                — 字段齐全，索引：idx_phone/email/role/created
--   2. ingredient（食材基础表）      — 字段齐全，索引：idx_category/season
--   3. recipe（菜谱表）              — 字段齐全，索引：idx_author/difficulty/created
--   4. recipe_ingredient（菜谱食材关联表）
--   5. recipe_step（菜谱步骤表）
--   6. section（论坛版块表）
--   7. post（论坛帖子表）            — 字段齐全，索引：idx_author/section/recipe/essential/created
--   8. comment（评论表）             — 字段齐全，索引：idx_post/author/parent
--   9. favorite（收藏表）
--  10. rating（评分表）
--  11. notification（通知表）        — 字段齐全，索引：idx_user_read/created
--  12. report（举报表）              — 字段齐全，索引：idx_status/target/reporter
--  13. user_behavior（用户行为日志表） — 字段齐全，索引：idx_user/action/target/created
--
-- 特性：
--   - 所有建表使用 CREATE TABLE IF NOT EXISTS，可重复执行不报错
--   - 所有字段、索引、约束均内联在建表语句中，无需 ALTER TABLE 存储过程
--   - 初始管理员账号使用 INSERT IGNORE，重复执行不会冲突
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- 1. 用户表（user）
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
  INDEX `idx_phone`   (`phone`),
  INDEX `idx_email`   (`email`),
  INDEX `idx_role`    (`role`),
  INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- -------------------------------------------------------------------------------------
-- 2. 食材基础表（ingredient）
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
  INDEX `idx_season`   (`season`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='食材基础表';

-- -------------------------------------------------------------------------------------
-- 3. 菜谱表（recipe）
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
  INDEX `idx_author`     (`author_id`),
  INDEX `idx_difficulty` (`difficulty`),
  INDEX `idx_created`    (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜谱表';

-- -------------------------------------------------------------------------------------
-- 4. 菜谱食材关联表（recipe_ingredient）
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
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `recipe_step` (
  `id`           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `recipe_id`    BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
  `step_no`      INT NOT NULL COMMENT '步骤序号(从1开始)',
  `content`      TEXT NOT NULL COMMENT '步骤内容',
  `image_url`    VARCHAR(500) DEFAULT NULL COMMENT '步骤配图URL',
  `duration_sec` INT DEFAULT NULL COMMENT '步骤耗时(秒)',
  `tip`          VARCHAR(200) DEFAULT NULL COMMENT '小贴士',
  INDEX `idx_recipe` (`recipe_id`, `step_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='菜谱步骤表';

-- -------------------------------------------------------------------------------------
-- 6. 论坛版块表（section）
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
  INDEX `idx_author`    (`author_id`),
  INDEX `idx_section`   (`section_id`),
  INDEX `idx_recipe`    (`recipe_id`),
  INDEX `idx_essential` (`is_essential`),
  INDEX `idx_created`   (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='论坛帖子表';

-- -------------------------------------------------------------------------------------
-- 8. 评论表（comment）
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
  INDEX `idx_post`   (`post_id`),
  INDEX `idx_author` (`author_id`),
  INDEX `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论表';

-- -------------------------------------------------------------------------------------
-- 9. 收藏表（favorite）
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `favorite` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`     BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `target_id`   BIGINT UNSIGNED NOT NULL COMMENT '目标ID',
  `target_type` ENUM('recipe','post') NOT NULL COMMENT '目标类型:recipe菜谱 post帖子',
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_target` (`user_id`, `target_id`, `target_type`),
  INDEX `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏表';

-- -------------------------------------------------------------------------------------
-- 10. 评分表（rating）
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `rating` (
  `id`         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`    BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `recipe_id`  BIGINT UNSIGNED NOT NULL COMMENT '菜谱ID',
  `score`      TINYINT NOT NULL COMMENT '评分1-5星',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_recipe` (`user_id`, `recipe_id`),
  INDEX `idx_recipe` (`recipe_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评分表';

-- -------------------------------------------------------------------------------------
-- 11. 通知表（notification）
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
  INDEX `idx_created`   (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知表';

-- -------------------------------------------------------------------------------------
-- 12. 举报表（report） — 原 schema.sql 缺失，来自 init_database.sql
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
  INDEX `idx_status`   (`status`),
  INDEX `idx_target`   (`target_id`, `target_type`),
  INDEX `idx_reporter` (`reporter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='举报表';

-- -------------------------------------------------------------------------------------
-- 13. 用户行为日志表（user_behavior）
-- -------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_behavior` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`     BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `action_type` VARCHAR(30) NOT NULL COMMENT '行为类型:view/favorite/rate/search/share',
  `target_id`   BIGINT UNSIGNED DEFAULT NULL COMMENT '目标ID',
  `target_type` VARCHAR(20) DEFAULT NULL COMMENT '目标类型:recipe/post/ingredient',
  `extra_json`  JSON DEFAULT NULL COMMENT '附加信息(搜索关键词/评分值等)',
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user`    (`user_id`),
  INDEX `idx_action`  (`action_type`),
  INDEX `idx_target`  (`target_id`, `target_type`),
  INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户行为日志表';

-- =====================================================================================
-- 初始数据说明：管理员账号不由 SQL 插入（BCrypt 哈希无法在 SQL 中静态生成），
-- 由 AdminInitializer 在应用启动时用 passwordEncoder 真实编码创建/维护：
--   - admin 不存在 → 创建（admin / admin123，role=2）
--   - admin 存在但密码不是 admin123 → 重置为 admin123
-- =====================================================================================

-- =====================================================================================
-- 测试数据：食材、菜谱、论坛版块、帖子（INSERT IGNORE 保证幂等）
-- =====================================================================================

-- 食材数据（9条，覆盖蔬菜/水果/肉类/调料/蛋白质）
INSERT IGNORE INTO `ingredient` (`id`, `name`, `category`, `taste`, `season`, `description`, `status`) VALUES
(1, '番茄',   '蔬菜',   '寒', '夏',   '富含番茄红素和维生素C，适合炒食或做汤', 1),
(2, '土豆',   '蔬菜',   '平', '四季', '淀粉含量高，可炒、炖、炸，百搭食材', 1),
(3, '鸡蛋',   '蛋白质', '平', '四季', '优质蛋白质来源，烹饪方式多样', 1),
(4, '黄瓜',   '蔬菜',   '凉', '夏',   '清脆爽口，可生食或凉拌', 1),
(5, '鸡胸肉', '肉类',   '温', '四季', '低脂高蛋白，适合健身人群', 1),
(6, '胡萝卜', '蔬菜',   '平', '秋',   '富含胡萝卜素，有益视力', 1),
(7, '大葱',   '调料',   '温', '四季', '提味增香，去腥解腻', 1),
(8, '苹果',   '水果',   '凉', '秋',   '富含膳食纤维和维生素，可直接食用或入菜', 1),
(9, '豆腐',   '蛋白质', '凉', '四季', '植物蛋白，口感嫩滑，吸收性强', 1);

-- 菜谱数据（6条）
INSERT IGNORE INTO `recipe` (`id`, `title`, `description`, `difficulty`, `duration_min`, `author_id`, `servings`, `tags`, `like_count`, `view_count`, `status`) VALUES
(1, '番茄炒蛋',     '经典家常菜，酸甜可口，下饭神器', 1, 15, 1, 2, '家常菜,快手菜', 128, 1024, 1),
(2, '酸辣土豆丝',   '爽脆开胃，酸辣适中，人人爱吃', 1, 20, 1, 2, '家常菜,快手菜', 96, 856, 1),
(3, '黄瓜拌鸡丝',   '清爽解腻，高蛋白低脂，适合夏天', 2, 25, 1, 2, '凉拌菜,健康餐', 45, 320, 1),
(4, '胡萝卜炒鸡蛋', '色彩鲜艳，营养均衡，老少皆宜', 1, 15, 1, 2, '家常菜,营养', 38, 280, 1),
(5, '苹果鸡肉沙拉', '水果入菜，清新健康，饱腹感强', 2, 30, 1, 2, '沙拉,健康餐,减脂', 52, 410, 1),
(6, '葱烧豆腐',     '葱香浓郁，豆腐嫩滑，下饭首选', 2, 20, 1, 2, '家常菜,素菜', 67, 520, 1);

-- 菜谱食材关联数据
INSERT IGNORE INTO `recipe_ingredient` (`recipe_id`, `ingredient_id`, `type`, `amount`, `unit`) VALUES
(1, 1, 'main', 2, '个'),
(1, 3, 'main', 3, '个'),
(2, 2, 'main', 1, '个'),
(3, 4, 'main', 1, '根'),
(3, 5, 'main', 200, 'g'),
(4, 6, 'main', 1, '根'),
(4, 3, 'main', 2, '个'),
(5, 8, 'main', 1, '个'),
(5, 5, 'main', 150, 'g'),
(6, 9, 'main', 1, '块'),
(6, 7, 'aux', 2, '根');

-- 论坛版块数据
INSERT IGNORE INTO `section` (`id`, `name`, `description`, `sort_order`, `status`) VALUES
(1, '菜谱讨论', '分享做菜心得，讨论菜谱做法', 1, 1),
(2, '食材百科', '食材知识、选购技巧、营养分析', 2, 1),
(3, '经验交流', '厨房技巧、厨具推荐、新手问答', 3, 1);

-- 论坛帖子数据（4条）
INSERT IGNORE INTO `post` (`id`, `section_id`, `author_id`, `title`, `content`, `like_count`, `comment_count`, `view_count`, `is_essential`, `status`) VALUES
(1, 1, 1, '番茄炒蛋的秘诀是什么？', '每次做番茄炒蛋都感觉差点意思，是番茄要去皮还是鸡蛋要先炒？大家来分享下经验，谢谢！', 25, 2, 156, 1, 1),
(2, 1, 1, '分享一道家常红烧肉的做法', '肥而不腻的红烧肉，关键在于炒糖色和炖煮时间。下面是我的详细步骤：\n1. 五花肉切块焯水\n2. 锅中放少许油加冰糖炒糖色\n3. 放入肉块翻炒上色\n4. 加酱油、料酒、水炖40分钟\n5. 大火收汁即可', 42, 1, 320, 1, 1),
(3, 2, 1, '秋天适合吃什么食材？', '换季了，想了解秋天有哪些应季食材适合日常烹饪？求推荐！', 18, 0, 89, 0, 1),
(4, 3, 1, '新手学厨：刀工练习心得', '从切土豆丝开始练习，总结了一些入门技巧和大家分享：\n1. 切片要薄而均匀\n2. 切丝时手指弯曲保护指尖\n3. 刀要保持锋利\n4. 切菜时保持专注', 30, 0, 200, 0, 1);

-- 评论数据
INSERT IGNORE INTO `comment` (`id`, `post_id`, `author_id`, `content`, `like_count`, `status`) VALUES
(1, 1, 1, '番茄一定要去皮，口感更好！用开水烫一下就能轻松去皮。', 8, 1),
(2, 1, 1, '鸡蛋先炒到半凝固再盛出，最后和番茄一起翻炒，这样鸡蛋更嫩。', 5, 1),
(3, 2, 1, '糖色的火候很关键，冰糖比白糖更好上色。', 12, 1);
