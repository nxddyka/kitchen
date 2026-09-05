# 智能厨房辅助系统

> Spring Boot 3.2 + Java 21 + MyBatis-Plus + MySQL + Spring Security + JWT + Knife4j + Bootstrap 5

## 快速开始

### 前置条件

| 软件 | 版本 | 说明 |
|------|------|------|
| JDK | 21+ | Spring Boot 3 要求 |
| Maven | 3.8+ | 依赖管理 |
| MySQL | 8.0+ | 主数据库 |

### 运行

```bash
cd kitchen/backend
mvn clean package -DskipTests
java -jar target/kitchen-backend.jar
```

### 数据库配置

修改 `src/main/resources/application.yml` 中的数据库密码：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/kitchen_db?createDatabaseIfNotExist=true&...
    username: kitjek
    password: 你的密码
```

首次启动自动建库建表 + 插入测试数据（9条食材、6条菜谱、4条帖子）。

## 访问地址

| 地址 | 说明 |
|------|------|
| http://localhost:8080/kitchen/ | 系统入口（自动跳转登录或食材库） |
| http://localhost:8080/kitchen/login | 登录/注册页 |
| http://localhost:8080/kitchen/ingredients | 食材库主页（卡片式，一行3个，1:2比例） |
| http://localhost:8080/kitchen/recipes | 菜谱中心 |
| http://localhost:8080/kitchen/forum | 讨论社区 |
| http://localhost:8080/kitchen/profile | 个人中心 |
| http://localhost:8080/kitchen/doc.html | Knife4j API 文档（需 admin/admin123） |

初始管理员账号：`admin` / `admin123`

## 目录结构

```
backend/
├── src/main/
│   ├── java/com/kitchen/
│   │   ├── KitchenApplication.java
│   │   ├── common/                       # 统一响应 + 异常处理
│   │   ├── config/                       # Security/MyBatis/CORS/Knife4j/WebMvc
│   │   ├── security/                     # JWT 工具 + 认证过滤器
│   │   ├── entity/                       # User/Recipe/Ingredient
│   │   ├── mapper/                       # MyBatis-Plus Mapper
│   │   ├── dto/                          # 请求 DTO
│   │   ├── service/                      # 业务逻辑层
│   │   └── controller/                   # API 控制器
│   └── resources/
│       ├── application.yml
│       ├── schema.sql                    # 建表 + 测试数据
│       └── static/                       # 前端页面（Spring Boot 静态资源）
│           ├── index.html                # 根入口（自动跳转）
│           ├── login.html                # 登录/注册
│           ├── ingredients.html         # 食材库
│           ├── recipes.html              # 菜谱中心
│           ├── forum.html                # 讨论社区
│           ├── profile.html              # 个人中心
│           ├── css/theme.css             # 主题样式
│           └── js/                        # theme.js / api.js / auth.js
└── pom.xml
```

## API 列表

所有 API 统一前缀 `/kitchen/api`，响应结构 `{code, message, data}`。

### Auth 认证模块（无需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /kitchen/api/auth/login | 用户登录 |
| POST | /kitchen/api/auth/register | 用户注册 |

### Biz 业务模块（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /kitchen/api/recipes | 分页查询菜谱 |
| GET | /kitchen/api/recipes/{id} | 菜谱详情 |
| GET | /kitchen/api/ingredients | 分页查询食材 |
| GET | /kitchen/api/ingredients/{id} | 食材详情 |

### Sys 系统模块

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| GET | /kitchen/api/health | 否 | 健康检查 |
| GET | /kitchen/api/admin/users | 管理员 | 分页查询用户 |
| PUT | /kitchen/api/admin/users/{id}/status | 管理员 | 启用/禁用用户 |
| PUT | /kitchen/api/admin/users/{id}/role | 管理员 | 修改用户角色 |
