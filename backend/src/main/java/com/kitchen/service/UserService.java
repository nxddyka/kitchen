package com.kitchen.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kitchen.common.BusinessException;
import com.kitchen.common.ResultCode;
import com.kitchen.entity.User;
import com.kitchen.mapper.UserMapper;
import com.kitchen.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * 用户服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    /**
     * 用户注册
     */
    public User register(String username, String password) {
        // 校验用户名是否已存在
        Long count = userMapper.selectCount(
            new LambdaQueryWrapper<User>().eq(User::getUsername, username)
        );
        if (count > 0) {
            throw new BusinessException(ResultCode.RESOURCE_CONFLICT.getCode(), "用户名已存在");
        }

        User user = new User();
        user.setUsername(username);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setRole(0);
        user.setStatus(1);
        userMapper.insert(user);
        log.info("用户注册成功: id={}, username={}", user.getId(), username);
        return user;
    }

    /**
     * 用户登录
     */
    public User login(String username, String password) {
        User user = userMapper.selectOne(
            new LambdaQueryWrapper<User>().eq(User::getUsername, username)
        );

        if (user == null) {
            throw new BusinessException(ResultCode.BAD_CREDENTIALS);
        }

        if (user.getStatus() == 0) {
            throw new BusinessException(ResultCode.ACCOUNT_DISABLED);
        }

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new BusinessException(ResultCode.BAD_CREDENTIALS);
        }

        // 更新最后登录时间
        User update = new User();
        update.setId(user.getId());
        update.setLastLoginAt(LocalDateTime.now());
        userMapper.updateById(update);

        // 生成 Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername(), user.getRole());
        user.setToken(token);
        user.setPasswordHash(null); // 脱敏
        log.info("用户登录成功: id={}, username={}", user.getId(), username);
        return user;
    }

    /**
     * 根据 ID 查询用户
     */
    public User getById(Long id) {
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(ResultCode.RESOURCE_NOT_FOUND);
        }
        user.setPasswordHash(null);
        return user;
    }

    // ==================== 管理员方法 ====================

    /**
     * 分页查询用户列表（管理员）
     */
    public Page<User> page(int page, int size, String keyword) {
        Page<User> pageObj = new Page<>(page, size);
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByDesc(User::getCreatedAt);

        if (keyword != null && !keyword.isBlank()) {
            wrapper.like(User::getUsername, keyword);
        }

        Page<User> result = userMapper.selectPage(pageObj, wrapper);
        // 脱敏：清除密码
        result.getRecords().forEach(u -> u.setPasswordHash(null));
        return result;
    }

    /**
     * 更新用户状态（启用/禁用）
     */
    public void updateStatus(Long id, int status) {
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(ResultCode.RESOURCE_NOT_FOUND);
        }
        User update = new User();
        update.setId(id);
        update.setStatus(status);
        userMapper.updateById(update);
        log.info("管理员更新用户状态: id={}, status={}", id, status);
    }

    /**
     * 更新用户角色
     */
    public void updateRole(Long id, int role) {
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(ResultCode.RESOURCE_NOT_FOUND);
        }
        User update = new User();
        update.setId(id);
        update.setRole(role);
        userMapper.updateById(update);
        log.info("管理员更新用户角色: id={}, role={}", id, role);
    }
}
