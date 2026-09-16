# Dual-servers-website-deployment

双服务器网站部署实践仓库。以 [we1l.site](we1l.site/)（Spring Boot 3 + Vue 3 个人站点）为具体案例，沉淀**跨地域双机部署 + 容器化交付**的完整链路：架构设计、运维脚本、部署 SOP、以及可复用于其他项目的「传统部署 → Docker」迁移手册。

> 本仓库所有部署文档、脚本均为**公开脱敏版**：公网 IP、域名、ACR 账号、SSH 账号、密钥文件等均已替换为占位符或外部读取（`$(cat /opt/...)`），可直接开源。

## 架构概览

```
                        公网（仅 B 机暴露）
                              │
            ┌─────────────────┴─────────────────┐
            │                                   │
       A 机（监控 / 备份）              B 机（备案机 / 唯一入口）
   Alibaba Cloud Linux 3          Debian 13
   ├─ Prometheus + Grafana        ├─ Nginx（SSL 终止 + 反代 + 静态）
   ├─ 备份接收端                   ├─ 应用（Tomcat 或 Docker）
   └─ 纯内网角色                   └─ SQLite（单文件 + WAL）
            │                                   │
            └──────── WireGuard 隧道 ───────────┘
              （10.10.0.0/24，A↔B 互通，A 不直连公网）
```

- **B 机**为唯一公网入口：Nginx 承担 SSL 终止、反向代理、静态资源分发；后端经 Tomcat 或 Docker 运行；数据落本地 SQLite。
- **A 机**仅经 WireGuard 与 B 机互通，承担监控采集与每日热备份接收，不直接暴露公网。
- 凭据（JWT_SECRET / 管理员密码）由 B 机本地文件提供，不进仓库。

## 仓库结构

```
Dual-servers-website-deployment/
├── README.md                      # 本文件：总入口与导航
├── LICENSE
├── .gitignore
├── we1l.site/                     # 具体案例：站点源码 + 部署产物
│   ├── README.md                  # 技术栈、接口清单、本地启动
│   ├── docker-compose.prod.yml    # 生产编排（Nginx + 后端 + 前端，含 .env 注入）
│   ├── nginx-default.conf         # 反代 / 静态 / SSL 配置模板
│   ├── Dockerfile (we1l-backend / we1l-frontend)  # 多阶段构建
│   ├── docs/部署操作文档.md         # 双机部署 SOP（572 行，脱敏版）
│   ├── scripts/                   # 部署 / 回滚 / 监控 agent 安装等运维脚本
│   ├── we1l-backend/              # Spring Boot 3（JDK 21，WAR）
│   └── we1l-frontend/             # Vue 3 + Vite
└── docker-migration/             # 通用「传统 → Docker」迁移手册（可复用于任意项目）
    ├── README.md                  # 交付链路总览 + 快速开始 + 验收清单
    ├── docs/01~05                 # 体检 / 容器化 / 构建推送 / 部署 / 踩坑集
    └── examples/                  # 7 个可套用模板（Dockerfile×2 / compose / .env / nginx / 脚本×2）
```

## 快速导航

| 你想做的事 | 看这里 |
|---|---|
| 了解双机部署完整步骤 | `we1l.site/docs/部署操作文档.md` |
| 跑通本地前后端 | `we1l.site/README.md` → 快速启动 |
| 用 Docker 交付 we1l.site | `we1l.site/docker-compose.prod.yml` + `docker-migration/` |
| 把任意传统部署改成 Docker | `docker-migration/README.md` |
| 部署 / 回滚 / 安装监控 | `we1l.site/scripts/` |

## 两种交付形态

1. **传统部署（Tomcat）**：`mvn package` 出 WAR → 推到 B 机 Tomcat 10.1+，由 Nginx 反代。详见 `docs/部署操作文档.md` §3。
2. **容器化部署（Docker）**：多阶段 Dockerfile 构建镜像 → 推私有仓库（ACR 等）→ B 机 `docker compose` 一键拉起。详见 `docker-migration/`。

## 安全基线

- JWT_SECRET ≥ 32 字节随机；管理员默认口令 `admin123456` **仅本地冒烟用**，生产须改。
- `/admin` 建议叠加 Nginx `auth_basic` 二次校验。
- 所有密钥均走环境变量 / 本地文件，仓库内零明文。
