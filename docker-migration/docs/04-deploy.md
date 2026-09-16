# 04 · 上线：服务器部署、验收与回滚

> 完整脚本见 `examples/deploy-server.sh`（通用化模板，含 sudo 交互提示）。
> 前置：`01-preflight.md` 的只读检查已通过，镜像已推送（`03-build-and-push.md`）。

## 1. 服务器侧准备（脚本自动化部分）

| 步骤 | 命令要点 | 说明 |
|---|---|---|
| ① 装 Docker + compose 插件 | `apt-get install -y docker.io docker-compose` | ⚠️ Debian 包名是 `docker-compose`，不是官方源的 `docker-compose-plugin`（pitfalls #2） |
| ② 停旧服务 | `systemctl stop <旧服务>` | 先停再验证，稳定后才 `disable`；回滚 = `start` |
| ③ 检查证书 | `certbot certificates` | 已有则跳过；没有则 standalone 签发（独占 80） |
| ④ 建目录 + 属主 | `mkdir -p /opt/myapp/{data,backup,oom}` + `chown <uid>:<gid>` | **必须与容器 `user:` 一致**，否则 SQLite 640 写失败 |
| ⑤ 安装配置 | compose / .env / nginx conf 拷到 `/opt/myapp/` | `.env` 含密钥，不入 git |
| ⑥ 登录仓库 + 拉起 | `docker compose pull && up -d` | ⚠️ `sudo docker` 用的是 **root 的** `~/.docker/config.json`（pitfalls #4） |

## 2. 环境变量模板（`.env`）

见 `examples/.env.example`。三类内容：

```bash
# ---- 镜像（私有仓库） ----
REGISTRY=<registry>
BACKEND_IMAGE=${REGISTRY}/<ns>/myapp:backend
FRONTEND_IMAGE=${REGISTRY}/<ns>/myapp:frontend

# ---- 应用 ----
JWT_SECRET=...              # 密钥区：绝不提交 git / 打进镜像层
CORS_ORIGINS=https://example.com,https://www.example.com

# ---- 宿主路径与属主（服务器实测值，来自 01-preflight） ----
HOST_DATA_DIR=/opt/myapp/data
HOST_CERT_DIR=/etc/letsencrypt
APP_UID=987                 # 旧服务账号的实际 uid，各机不同
APP_GID=987
```

## 3. 证书：签发与续期

```bash
# 首次签发（standalone 独占 80，需先确认 80 空闲）
sudo certbot certonly --standalone -d example.com -d www.example.com --cert-name www.example.com
```

> ⚠️ **务必带 `--cert-name`**：certbot 的 `live/` 目录名以证书名命名，而 nginx 配置里写死了
> `live/<证书名>/fullchain.pem`。名字对不上，nginx 直接起不来（pitfalls #10）。

迁移后宿主已无 web 服务时，续期策略二选一：

1. **webroot 模式**：nginx 容器挂载 ACME 目录对外暴露 `/.well-known/acme-challenge/`（本手册编排默认形态）；
2. **standalone 模式**：续期前临时停 nginx 容器，续完再起（`certbot renew --pre-hook ... --post-hook ...`）。

## 4. 启动与验收

```bash
cd /opt/myapp
docker compose -f docker-compose.prod.yml --env-file .env up -d

docker compose ps                                   # 两服务 Up
curl -I  http://localhost/                          # 301
curl -kI https://localhost/                         # 200
curl -k  https://localhost/api/<健康接口>            # 全链路（反代→backend→DB）
docker compose logs --tail=80 backend               # 观察启动 + 无权限报错
```

公网验收：`curl -I https://<你的域名>/` 与 API 各返回 200，TLS 证书校验通过。

## 5. 回滚预案

| 阶段 | 回滚动作 | 成本 |
|---|---|---|
| 容器起不来 | `docker compose down`，`systemctl start <旧服务>` | 秒级 |
| 跑了但数据异常 | down 容器 → 用迁移前快照恢复 DB → start 旧服务 | 分钟级 |
| 稳定运行后 | 旧服务保留 30 天再 disable + 清理；镜像回滚 = `:latest` 指回旧 digest 或用版本 tag | — |

> 「旧服务 stop 但不 disable」作为默认状态观察一个备份周期，是最低成本的保险。

## 6. 长期运行

```bash
# 日志
docker compose logs -f --tail=100

# 升级（开发机重新 build-push 后）
docker compose pull && docker compose up -d

# 数据备份沿用宿主 cron（脚本改用 docker exec 进 backend，或直接打包挂载目录）
```

- WireGuard、node_exporter、备份 cron **继续留在宿主**，不强行容器化；
- 遗留旧目录先归档（如 `/opt/myapp/archive-pre-docker/`）， 7 天后无重大事故再归档。
