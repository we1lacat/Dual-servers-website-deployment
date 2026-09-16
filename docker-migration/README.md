# 传统部署 到 Docker Compose 迁移

> 从一次**真实上线迁移**整理而成：单机 systemd + Tomcat(WAR) + 宿主 Nginx + SQLite(WAL) + Let's Encrypt + WireGuard 的传统部署，迁移到「本地多阶段构建 → 私有镜像仓库 → 服务器 `docker compose` 拉起」的容器化交付，全程可回滚、停机窗口理论为 0。
>
> ⚠️ 本仓库所有域名 / IP / 仓库地址 / 账号 / 密钥均已**脱敏**，替换为占位符或 RFC 5737 示例值，可直接套用到自己的项目。

## 适用场景

- 已有一个能跑的传统部署（systemd 服务 + 反代 + 静态站点），想迁移到 Docker Compose；
- 服务器配置低（如 2C2G），**不适合在服务器上做 Maven / Node 多阶段构建**，需要「本地构建 → 推镜像仓库 → 服务器拉取」的交付链路；
- 应用带**本地状态**（SQLite / 文件），需要处理好卷挂载与文件属主；
- 前后端分离（Spring Boot 后端 + SPA 前端），或任意「一个后端 + 一个静态前端」组合。

## 迁移链路总览

```
开发机                          镜像仓库                    服务器
──────                         ─────────                 ─────────
docker build (多阶段)
  backend:  maven → JRE
  frontend: node → nginx
        │
docker tag  <registry>/<ns>/backend:latest
docker push ───────────────▶  私有仓库（ACR/Harbor/Hub）
                              │
                              │   docker compose pull
                              ▼
                        docker compose up -d
                          ├─ backend (8080, 桥接内部)
                          └─ nginx   (80/443, 反代 + 静态)
```

核心原则：**不在目标服务器上构建**。镜像把「应用 + 依赖 + 配置」打包成不可变单元，服务器只做 pull + up，升级 / 回滚都等价于换一个镜像 tag。

## 仓库结构

```
.
├── docs/
│   ├── 01-preflight.md        # 迁移前：现状采集、组件映射、硬约束、只读检查
│   ├── 02-containerize.md     # 容器化：多阶段 Dockerfile + compose 本地编排
│   ├── 03-build-and-push.md   # 交付：构建 → tag → push 私有镜像仓库
│   ├── 04-deploy.md           # 上线：服务器部署脚本、验收、回滚
│   └── 05-pitfalls.md         # 踩坑清单（16 条，含根因与修复）
└── examples/                  # 可直接套用的模板（已通用化）
    ├── backend-Dockerfile
    ├── frontend-Dockerfile
    ├── docker-compose.prod.yml
    ├── .env.example
    ├── nginx-default.conf
    ├── build-push.sh          # 本地一键构建推送
    └── deploy-server.sh       # 服务器一键部署
```

## 快速开始

```bash
# 1. 按模板准备三个文件（examples/ 目录）
cp examples/.env.example .env          # 填入你的仓库地址 / 域名 / 密钥
#    按需修改 examples/docker-compose.prod.yml 与 examples/nginx-default.conf

# 2. 本地构建并推送镜像
bash examples/build-push.sh

# 3. 服务器上部署（先跑 docs/01 的只读检查确认就绪）
bash deploy-server.sh
```

## 迁移节奏（建议）

| 阶段 | 动作 | 回滚成本 |
|---|---|---|
| 1. 体检 | 按 `01-preflight.md` 只读采集现状，列组件映射表 | 0 |
| 2. 容器化 | 写 Dockerfile + compose，本地 `up -d --build` 全量验证 | 0（不动线上） |
| 3. 交付 | build → tag → push 到私有仓库；服务器只 pull | 换 tag 即回滚 |
| 4. 切换 | 旧服务与新容器**并行**（新容器先用非标端口），验证通过再接管 80/443 | 秒级（改回反代） |
| 5. 收尾 | 观察一个备份周期后再 disable 旧服务、清理旧目录 | 保留旧服务 30 天 |

## 验收

- [ ] 前台页面 + 后台管理页可访问（含 401 跳登录）
- [ ] API 反代正常（注意 `proxy_pass` 末尾**不要带斜杠**，见 pitfalls #9）
- [ ] HTTPS 证书挂载正常，容器重启后仍生效
- [ ] 数据库可写（SQLite WAL 整目录挂载 + uid 对齐，见 pitfalls #8）
- [ ] 定时备份在新容器环境下正常生成
- [ ] OOM 策略生效：`ExitOnOutOfMemoryError` 后 compose 自动拉起
- [ ] 监控 / 探活（如跨机 WireGuard）在容器网络模式下可达

## 环境约定

| 项 | 本手册示例值 | 说明 |
|---|---|---|
| 目标服务器 | Debian 13, 2C2G, 非 root 运维账号 | 适用于 Debian / RHEL 系 |
| 应用 | Spring Boot 3 后端 + Vue 3 前端 | 任意「后端 + 静态前端」同理 |
| 数据库 | SQLite（WAL 模式） | 换 MySQL/PG 时把卷换成数据目录即可 |
| 镜像仓库 | 阿里云 ACR 个人版 | Docker Hub / Harbor / GHCR 同理 |
| 证书 | Let's Encrypt（certbot，宿主管） | 容器只读挂载 `/etc/letsencrypt` |
| 组网 | WireGuard 隧道（10.10.0.0/24 示例） | 无组网需求可忽略相关章节 |

## License

MIT（可按需替换为你自己的协议）。
