#  Spring Boot 3 + Vue 3 重构版

**前后端分离架构**，视觉风格与内容完全沿用原站，新增 `/admin` 后台内容管理 + JWT 鉴权。

已经完成移动端适配

## 技术栈

| 层 | 技术 | 说明 |
|---|---|---|
| 后端 | Spring Boot 3.3 + MyBatis-Plus 3.5 + Spring Security + jjwt | JDK 21，Maven 构建，WAR 产物 |
| 持久化 | **SQLite**（默认，单文件，WAL） | 8 张业务表 + 1 张管理员表 |
| 前端 | Vue 3.5 + Vite 5 + TypeScript | vue-router / pinia / axios |
| UI / 图表 | Element Plus 2.x + ECharts 5 | 后台 CRUD / 前台折线图与雷达图 / 登录页 |
| 鉴权 | JWT (HS512, 8h 过期) | 入口在 Vue 前台**右上角小图标** → `/login` |

## 目录结构

```
we1l.site/
├── we1l-backend/                    # Spring Boot 后端
│   ├── pom.xml
│   └── src/main/
│       ├── java/site/we1l/
│       │   ├── common/       # Result 统一响应 / BusinessException / GlobalExceptionHandler
│       │   ├── config/       # MyBatis-Plus 分页插件占位
│       │   ├── auth/         # JwtUtil / JwtAuthFilter / SecurityConfig / AuthController / AuthService / AdminBootstrapRunner / JsonAuthenticationEntryPoint
│       │   ├── entity/       # 9 张表实体（BaseEntity 公共字段）
│       │   ├── mapper/       # MyBatis-Plus Mapper
│       │   ├── service/      # 业务层（前台查询 + 后台 CRUD）
│       │   └── controller/   # /api/** 前台只读 + /api/admin/** 管理 + /api/ops/status 运维状态
│       └── resources/
│           ├── application.yml          # SQLite 配置（默认）
│           ├── application-prod.yml     # 生产 profile（关闭 data.sql 重置，防丢数据）
│           ├── application-dev-h2.yml   # 本地 H2 冒烟测试 profile
│           └── db/schema.sql + data.sql # SQLite 方言建表 + 种子数据
├── we1l-frontend/                   # Vue 3 前端
│   ├── vite.config.ts               # @ 别名 + /api 代理（BACKEND_URL 可覆盖）
│   └── src/
│       ├── api/index.ts             # 统一 API 层（类型 + 拦截器 + 401 跳登录）
│       ├── auth/store.ts            # JWT token + user 持久化（localStorage）
│       ├── router/                  # 前台 3 页 + /login + /admin 9 页（含守卫）
│       ├── views/                   # Home / Notes / About / Login
│       ├── components/              # SiteHeader（含右上角登录入口 + 运行状态指示器）+ Footer + Charts
│       └── admin/                   # AdminLayout + CrudTable + 9 个管理页
├── scripts/                        # 运维脚本（部署 / 回滚 / node_exporter 安装等）
└── docs/部署操作文档.md              # 双服务器部署 SOP（公开脱敏版，地址均为占位符）
```

## 快速启动

### 1. 后端

```bash
cd we1l-backend
mvn spring-boot:run         # 默认 http://localhost:8080（连同 SQLite，DB 文件落在 ./data/we1l.db）
```

> 首次启动日志会打印 **默认管理员**（`admin / admin123456`）——登录后请立即修改。

### 2. 前端

```bash
cd we1l-frontend
npm install
npm run dev                 # http://localhost:5173，/api 代理到 8080
```

### 3. 访问

| 路径 | 说明 |
|---|---|
| http://localhost:5173/ | 前台首页（趋势折线图 + 快速入口） |
| http://localhost:5173/notes | 笔记 / 服务（作品 + 笔记 + 简历模板） |
| http://localhost:5173/about | 关于我（正在学习 + 技能条 + 雷达图 + 社交矩阵） |
| http://localhost:5173/login | 管理员登录（右上角） |
| http://localhost:5173/admin | 后台管理（需登录；9 个 CRUD 模块） |

## 鉴权机制

```
用户浏览前台 ── 看到右上角 👤 图标
   │ (点击)
   ▼
  /login（独立路由，Element Plus 卡片）
   │ 提交 admin / admin123456
   ▼
后端 /api/auth/login 校验 → BCrypt 校验 → 签发 JWT(8h) → 返回 { token, expireSeconds, user }
   ▼
前端 localStorage 持久化 → router.replace(/admin 或 ?redirect= 目标)
   ▼
后续请求自动带 Authorization: Bearer xxx
401 自动跳 /login（拦截器统一处理）
```

- **前台只读接口与登录接口公开**
- **`/api/admin/**` 必须带 token**（Spring Security 规则，401 返 JSON body，非 HTML 登录页）

## 接口清单

### 鉴权（公开 + 受保护）

| 方法 | 路径 | 鉴权 |
|---|---|---|
| `POST` | `/api/auth/login` | 公开 |
| `POST` | `/api/auth/logout` | 已登录 |
| `GET` | `/api/auth/me` | 已登录 |

### 前台只读（公开）

```
GET /api/profile
GET /api/trend
GET /api/learnings
GET /api/skills?type=BAR|RADAR
GET /api/socials
GET /api/works
GET /api/notes
GET /api/notes/{id}
GET /api/resumes
```

### 后台管理（必须 Bearer Token）

```
GET    /api/admin/stats
GET    /api/admin/{模块}/page
POST   /api/admin/{模块}
PUT    /api/admin/{模块}
DELETE /api/admin/{模块}/{id}
PUT    /api/admin/profile         # 站点档案（单记录）
```

统一响应：`{ code: 0, message: "success", data: ... }`；业务异常 code=400/401/403/404 + 字段错误信息；401 时 HTTP 状态 401 + 业务 code=401 + message="未登录或登录已过期"。

## 与原静态站的对照

| 原实现 | 重构后 |
|---|---|
| 三页硬编码 HTML 内容 | 数据库 9 张表，接口动态渲染 |
| app.js 手写 canvas 图表 | ECharts 组件（TrendChart / SkillRadar），数据来自接口 |
| style.css | 迁移至 `src/styles/global.css`，视觉不变 |
| 无后台 | `/admin` 9 个模块 CRUD + 站点档案表单，改完前台立即生效 |
| 无鉴权 | JWT 鉴权，右上角小图标入口 |
| 数据更新需改代码 | 后台表单维护，含排序 / 上下架 / 状态字段 |

## 构建产物

- 后端：`mvn package` → `we1l-backend/target/we1l-backend.war`（约 38MB，含 sqlite-jdbc + jjwt；部署到外置 Tomcat 10.1+）
- 前端：`npm run build`（含 vue-tsc 类型检查）→ `we1l-frontend/dist/`（ Nginx 托管）

## 生产部署

双服务器架构（B：Debian 备案机/唯一公网入口，Nginx + Tomcat + SQLite；A：监控/备份接收纯内网角色；WireGuard 隧道互联），完整操作步骤见 **[docs/部署操作文档.md](docs/部署操作文档.md)**（公开脱敏版，地址/账号均为占位符）。

文档重点章节：
- §3 Tomcat + JDK 21 + Nginx 动静分离部署
- §4 Prometheus + Grafana + 备份接收端
- §5 每日热备份 + 隧道推送 + 恢复演练
- §8 凭据与安全基线

## 备注

- 8080 端口被占用时：后端 `--server.port=xxxx`，前端 `BACKEND_URL=http://localhost:xxxx npm run dev`
- 种子数据内容全部来自原静态站文案，含 ICP 备案（`赣ICP备202xxxxxxx号-1`），后台「站点档案」可改
- 安全底线：JWT_SECRET 至少 32 字节随机；`/admin` 二次校验建议叠加 Nginx `auth_basic`
