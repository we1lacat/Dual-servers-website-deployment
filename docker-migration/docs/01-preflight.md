# 01 · 迁移前体检：现状采集与就绪度核查

> 目标：迁移前把「线上现状」变成一张**配置基线表**，所有数值来自实测，不靠记忆推测。
> 原则：只做**只读**操作，不改动线上任何状态。

## 1. 组件 → 容器映射表

现有部署拆解，决定容器构建。示例（Spring Boot + 静态前端 + SQLite）：

| 现状组件 | 容器化方案 | 关键参数 | 变更点 |
|---|---|---|---|
| Tomcat + WAR | 单个 `backend` 容器，多阶段构建 | 基础镜像 `eclipse-temurin:21-jre`，JAR 直跑 | 去掉 Tomcat 外壳；`-D` 参数全部改环境变量 |
| 宿主 Nginx | `nginx:1.27-alpine` 容器 | 挂载自定义 `default.conf` | `proxy_pass 127.0.0.1:8080` → `http://backend:8080`（compose 服务名） |
| 前端静态目录 | 烘焙进 nginx 镜像（推荐，不可变） | `COPY dist → /usr/share/nginx/html` | 回滚靠镜像 tag，不再手工 scp dist |
| SQLite 库 | bind mount **整个目录** | `${HOST_DATA_DIR}:/data` | ⚠️ WAL 模式存在 `-wal`/`-shm` 文件，不能只挂单文件 |
| 证书 | bind mount 只读 | `/etc/letsencrypt:/etc/letsencrypt:ro` | certbot 仍在宿主续期，容器不管证书 |
| WireGuard | **留在宿主，不进容器** | — | WG 是内核模块，容器无法自建 wg0；容器需要访问隧道时用 `network_mode: host` 或宿主路由 |
| node_exporter | 留在宿主 | — | 与容器无冲突，能不动就不动 |
| 备份 cron | 宿主 cron + `docker exec` | — | 改动最小；也可独立 backup 容器 |

## 2. 环境变量映射（以 Spring Boot 为例）

原 systemd 里的 `-D` 参数 → 容器环境变量，**无需改代码**：

| 原 JVM 参数 | 容器环境变量 | 示例值 |
|---|---|---|
| `-Dspring.profiles.active=prod` | `SPRING_PROFILES_ACTIVE` | `prod` |
| `-DDB_PATH=/opt/myapp/data/app.db` | `DB_PATH` | `/data/app.db`（容器内路径） |
| `-DJWT_SECRET=...` | `JWT_SECRET` | 走 `.env` 注入，**绝不硬编码** |
| `-DCORS_ORIGINS=...` | `CORS_ORIGINS` | `https://example.com,https://www.example.com` |
| （自定义探活） | `OPS_MONITOR_URL` | `http://10.10.0.2:9090`（隧道对端） |

> ⚠️ **jar 直跑只认 `JAVA_TOOL_OPTIONS`**。`JAVA_OPTS` 是 Tomcat 的约定，`java -jar` 不读。这是从 WAR 迁到 JAR 容易踩的静默失败（见 pitfalls #11）。

JVM 内存参数：容器化后建议改用百分比，让 JVM 感知 cgroup 限制：

```text
-XX:MaxRAMPercentage=70 -XX:InitialRAMPercentage=25
-XX:+ExitOnOutOfMemoryError -XX:HeapDumpPath=/oom
```

## 3. 迁移前必须核实的 4 个硬约束

| # | 约束 | 核实 | 后果 |
|---|---|---|---|
| 1 | **内存** | `free -h; swapon --show`；对比 JVM 堆 + 容器开销 | backend 被 OOM-kill，compose 反复重启 |
| 2 | **SQLite WAL** | `ls` 数据目录有无 `-wal`/`-shm`；`PRAGMA journal_mode` | 只挂单文件 → 数据丢失 / 写入失败 |
| 3 | **内核态网络（WG 等）** | 容器内是否需要访问隧道网段 | 桥接容器探不到隧道对端 |
| 4 | **文件属主 uid** | `id <旧服务账号>`，取实际 uid/gid | 库文件权限 640，容器内非 root 写不进 |

## 4. 目标机就绪度检查（只读，大多无需 sudo）

```bash
# 系统 & 架构
cat /etc/os-release | grep PRETTY_NAME; uname -m

# Docker / compose 是否就绪
which docker && docker --version && docker compose version || echo "NO_DOCKER_OR_COMPOSE"

# 内存 + swap
free -h; swapon --show || echo "NO_SWAP"

# 磁盘
df -h / /opt 2>/dev/null

# 80/443 是否被占（决定要不要停旧服务）
ss -tlnp 2>/dev/null | grep -E ':80 |:443 |:8080 ' || echo "PORTS_FREE"

# 旧服务账号的 uid（决定容器 user: 对齐值）
id <旧服务账号> 2>/dev/null || echo "NO_SUCH_USER"

# 证书
sudo ls -d /etc/letsencrypt/live/* 2>/dev/null || echo "NO_LETSENCRYPT_LIVE"
# ⚠️ live/ 仅 root 可读：普通用户看不到 ≠ 证书不存在，误报过（见 pitfalls #16）

# 隧道可达性（如有）
wg show 2>/dev/null | head -8 || echo "NO_WG"
( timeout 3 bash -c 'cat < /dev/null > /dev/tcp/10.10.0.2/9090' && echo "PEER_REACHABLE" ) || echo "PEER_UNREACHABLE"

which certbot || echo "NO_CERTBOT"
```

> 📌 把输出留档成一张表，后面 compose 的 `.env`、`mem_limit`、`user:`、卷路径全都从这张表来。

## 5. 建议的切换顺序（全程可回滚）

1. **快照**：先把数据库拷一份到 `~/pre-docker.db`（有定时备份的靠备份兜底）。
2. **并行起容器**：只起 `backend`，宿主 8080 已占用就映射非标端口（如 `18080`），**不接管流量**。
3. **验证**：`curl 127.0.0.1:18080/api/...`，确认能读库、能连隧道对端。
4. **切流量**：反代从旧地址切到容器（改 `proxy_pass` → `nginx -t && reload`，**秒级回滚**：改回即可）。
5. **观察一个备份周期**，确认数据文件正常生成。
6. **下线旧服务**：`systemctl stop` → 稳定后再 `disable`，旧部署目录归档保留 30 天。

> 停机窗口理论为 0：Nginx reload 不中断存量连接，SQLite 单写者不受影响。
