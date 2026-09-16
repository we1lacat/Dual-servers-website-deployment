# 05 · 踩坑清单（迁移阶段排序）

> 现象 → 根因 → 修复。来自真实迁移的现场记录，按阶段归类。

## 阶段一：本地构建 / 推送

### 1. push 报 `unknown manifest class for application/vnd.oci.empty.v1+json`

- **现象**：`docker push` 到阿里云 ACR 个人版被拒。
- **根因**：Docker Desktop 的 BuildKit 默认给镜像附带 provenance / SBOM **证明清单**，其 config 类型正是 `application/vnd.oci.empty.v1+json`；该仓库不认这种 manifest。
- **修复**：构建时加 `--provenance=false --sbom=false`，并 `export BUILDX_NO_DEFAULT_ATTESTATIONS=1` 兜底。
- ⚠️ 带 attestation 的旧镜像**重新 build** 才能推，直接重 push 仍失败。

### 2. Debian 上 `docker compose` 不可用

- **现象**：`docker compose -f x.yml` 报 `unknown shorthand flag: 'f'`，或 `'compose' is not a docker command`。
- **根因**：Debian 的 `docker.io` 包**不自带 compose 插件**（`cli-plugins/` 里只有 buildx）。
- **修复**：`sudo apt-get install -y docker-compose`。⚠️ Debian 的包名是 `docker-compose`（v2.26，提供 `docker compose` 子命令），**不是** Docker 官方源的 `docker-compose-plugin`。装完 `docker compose version` 验证。

### 3. push 前没打 tag，直接 `denied`

- **现象**：`docker push myapp` 失败。
- **根因**：push 推的是 tag 里的全名 `[registry/][ns/]repo:tag`，本地名没有仓库前缀。
- **修复**：先 `docker tag <本地名> <registry>/<ns>/<repo>:<tag>` 再 push（见 `03` 文档）。

### 4. 服务器 `pull access denied` —— 其实是 sudo 凭据作用域

- **现象**：服务器 `docker compose pull` 报 `denied: requested access to the resource is denied`。
- **根因**：**`sudo docker` 读的是 root 的 `/root/.docker/config.json`**，与普通用户、与开发机的登录态互不相通。开发机登录过 ≠ 服务器能拉。
- **修复**：在**目标机**执行 `sudo docker login --username=<user> <registry>`。
- 另：云厂商「镜像仓库密码」是开通服务时单独设置的，不是云账号登录密码。

## 阶段二：服务器部署

### 5. apt 安装被全屏弹窗卡死（needrestart）

- **现象**：蓝色交互界面 `Which services should be restarted?`，SSH 里可能卡住甚至断连（重启网络服务时）。
- **修复**：交互时选 `<Cancel>`；脚本里统一加 `sudo env NEEDRESTART_MODE=l apt-get install -y <pkg>`（只列不重启、不交互）。系统级根治：`/etc/needrestart/needrestart.conf` 设 `$nrconf{restart} = 'l';`。

### 6. SQLite 写入失败：WAL + 属主双坑

- **现象**：容器起来但写库报错，或库里明明有权限却 `attempt to write a readonly database`。
- **根因 ①**：WAL 模式有 `-wal` / `-shm` 伴生文件，**必须挂载整个数据目录**，只挂 `.db` 单文件必出问题；
- **根因 ②**：宿主数据目录属主与容器内运行用户不一致，库文件 640 → 非 root 容器写不进。
- **修复**：卷挂整目录 `− ${HOST_DATA_DIR}:/data`；compose `user: "<uid>:<gid>"` 与宿主目录属主对齐（部署脚本里 `mkdir` 后立即 `chown`）。

### 7. 小内存机 OOM：mem_limit 与 JVM 堆不匹配

- **现象**：backend 反复重启，`docker inspect` 显示 OOMKilled。
- **根因**：固定 `-Xmx` 不感知 cgroup 限制；`-Xmx768m` + Metaspace + 线程栈实际要 ≥1.1G，而宿主可用内存可能只有 ~700MB。
- **修复**：JVM 改 `-XX:MaxRAMPercentage=70 -XX:InitialRAMPercentage=25`；`mem_limit` 按实测余量设（宁低勿高）；宿主开 swap 兜底。

### 8. nginx 起不来：证书 `live/` 目录名不匹配

- **现象**：nginx 容器启动即退，日志找不到证书文件。
- **根因**：certbot 的 `live/<证书名>/` 以**签发时的证书名**命名；nginx 配置写死了路径，名字对不上就 404。
- **修复**：签发时带 `--cert-name <与 nginx 配置一致的名字>`；迁移前 `sudo ls /etc/letsencrypt/live/` 核对（live 目录仅 root 可读，须 sudo）。

### 9. API 全 404：`proxy_pass` 末尾多了个斜杠

- **现象**：页面能开，`/api/xxx` 全 404。
- **根因**：`proxy_pass http://backend:8080/` 末尾的 `/` 会**剥掉** location 匹配的 `/api/` 段再拼接，后端收到的 URI 少了一段。
- **修复**：不带 URI 的写法 `proxy_pass http://backend:8080;`（完整请求 URI 透传）。前缀不匹配的场景才需要带路径改写。

### 10. 容器探不到隧道对端（WireGuard 等）

- **现象**：backend 跨机探活（如 `http://10.10.0.2:9090`）超时，宿主上却通。
- **根因**：桥接网络默认走宿主路由，多数情况能通；不通时是转发 / 防火墙问题。
- **修复**：优先查 `ip_forward` 与防火墙；兜底方案 `network_mode: host`（简单但牺牲网络隔离，且 nginx 反代要改 `127.0.0.1:8080`）。

## 阶段三：通用 / 环境类

### 11. `java -jar` | `JAVA_OPTS`差异

- **根因**：`JAVA_OPTS` 是 Tomcat 的约定变量，JVM 本体只认 `JAVA_TOOL_OPTIONS`（和命令行参数）。
- **修复**：compose 里统一用 `JAVA_TOOL_OPTIONS`。

### 12. `.env`

- **修复**：`.gitignore` 第一行就写 `.env` / `.env.prod`；仓库里只放 `.env.example`（键名 + 占位值）。

### 13. 本地 Docker 数据盘只涨不缩

- WSL2 后端的镜像数据在虚拟磁盘（`docker_data.vhdx`）里，删镜像后文件不自动缩小。
- **修复**：Docker Desktop → Troubleshoot → WSL disk cleanup，或 `diskpart` 压缩 vhdx。
