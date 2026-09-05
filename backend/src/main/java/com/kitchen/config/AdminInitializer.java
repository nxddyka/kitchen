package com.kitchen.config;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.kitchen.entity.User;
import com.kitchen.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * 管理员账号初始化器
 * <p>
 * BCrypt 哈希无法在 SQL 脚本中静态写死（编造的哈希无法通过校验），
 * 因此在应用启动时用 passwordEncoder 真实编码生成：
 * <ul>
 *   <li>admin 不存在 → 创建初始管理员（admin / admin123，role=2 管理员）</li>
 *   <li>admin 存在但密码不是 admin123 → 重置为默认密码（保证可用性）</li>
 *   <li>admin 存在且密码正确 → 不做任何操作</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminInitializer implements CommandLineRunner {

    private static final String ADMIN_USERNAME = "admin";
    private static final String ADMIN_PASSWORD = "admin123";
    private static final int ROLE_ADMIN = 2;

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        User admin = userMapper.selectOne(
            new LambdaQueryWrapper<User>().eq(User::getUsername, ADMIN_USERNAME)
        );

        if (admin == null) {
            // 首次启动：创建初始管理员
            User user = new User();
            user.setUsername(ADMIN_USERNAME);
            user.setPasswordHash(passwordEncoder.encode(ADMIN_PASSWORD));
            user.setRole(ROLE_ADMIN);
            user.setStatus(1);
            userMapper.insert(user);
            log.info("已创建初始管理员账号: {} / {}（role=2 管理员）", ADMIN_USERNAME, ADMIN_PASSWORD);
            return;
        }

        // 已存在：校验密码哈希是否为默认密码，不一致则重置（修复占位哈希等历史问题）
        if (!passwordEncoder.matches(ADMIN_PASSWORD, admin.getPasswordHash())) {
            User update = new User();
            update.setId(admin.getId());
            update.setPasswordHash(passwordEncoder.encode(ADMIN_PASSWORD));
            update.setRole(ROLE_ADMIN);
            update.setStatus(1);
            userMapper.updateById(update);
            log.info("检测到管理员密码哈希无效，已重置为默认密码: {} / {}", ADMIN_USERNAME, ADMIN_PASSWORD);
        } else {
            log.info("管理员账号校验通过: {}", ADMIN_USERNAME);
        }
    }
}
