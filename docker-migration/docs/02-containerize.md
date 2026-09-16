# 02 · 容器化：多阶段 Dockerfile + compose 本地编排

> 目标：本地 `docker compose up -d --build` 能完整跑通并验证，才谈得上推送和上线。
> 完整模板见 `examples/backend-Dockerfile`、`examples/frontend-Dockerfile`、`examples/docker-compose.prod.yml`。

## 1. 后端：多阶段构建（jar 不落地）

```dockerfile
# ---- 构建阶段：完整 JDK + Maven ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
# 先拷 pom 再拷源码，利用层缓存（依赖不变时改源码不重拉）
COPY pom.xml .
COPY src ./src
RUN mvn -B -ntp clean package -DskipTests

# ---- 运行阶段：仅 JRE，体积小 ----
FROM eclipse-temurin:21-jre
WORKDIR /app
RUN mkdir -p /data /backup          # 真实路径由卷挂载覆盖
COPY --from=build /build/target/app-backend.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar", "--spring.profiles.active=prod"]
```

要点：

- **两阶段分离**：构建产物只带 JRE 运行态，镜像从 ~700MB 降到 ~250MB 级；
- **依赖层缓存**：`COPY pom.xml` 与 `COPY src` 分开写，改代码不触发依赖重下；
- 数据目录**交给卷**，不进镜像层；
- 非原 root 硬化见模板注释（需同步处理卷属主，与 `04` 的 uid 对齐联动）。

## 2. 前端：构建产物烘焙进 nginx

```dockerfile
# ---- 阶段 1：构建 ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- 阶段 2：运行态 ----
FROM nginx:1.27-alpine
RUN rm -f /etc/nginx/conf.d/default.conf     # 由 compose 挂载的 default.conf 接管
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

要点：

- 前端产物进镜像 = **不可变交付**，回滚就是换 tag；比「scp dist 到服务器目录」可靠得多；
- 反代 / SSL 配置不烘进镜像，由 compose 挂载的 `default.conf` 提供（单一真相源在编排层）。

## 3. 生产编排（服务器版 compose）

```yaml
services:
  backend:
    image: "${BACKEND_IMAGE}"            # 来自 .env：私有仓库地址，服务器只 pull 不 build
    restart: unless-stopped
    user: "${APP_UID:-1000}:${APP_GID:-1000}"   # 对齐宿主数据目录属主，防 SQLite 640 写失败
    environment:
      SPRING_PROFILES_ACTIVE: prod
      DB_PATH: /data/app.db
      JWT_SECRET: ${JWT_SECRET}          # 密钥全部走 .env 注入，绝不硬编码
      JAVA_TOOL_OPTIONS: >-
        -XX:MaxRAMPercentage=70 -XX:InitialRAMPercentage=25
        -XX:+ExitOnOutOfMemoryError -XX:HeapDumpPath=/oom
    volumes:
      - ${HOST_DATA_DIR}:/data           # SQLite 主库：WAL 需挂整个目录
      - ${HOST_BACKUP_DIR}:/backup
      - ${HOST_OOM_DIR}:/oom
    expose: ["8080"]                     # 只在编排网络内暴露，不发布宿主端口
    mem_limit: 512m                      # 小内存机宁低勿高，配 swap 兜底
    networks: [app-net]

  nginx:
    image: "${FRONTEND_IMAGE}"
    restart: unless-stopped
    depends_on: [backend]
    ports: ["80:80", "443:443"]
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ${HOST_CERT_DIR}:/etc/letsencrypt:ro       # 证书宿主管，只读挂载
      - ${HOST_CERTBOT_DIR}:/var/www/certbot:ro    # ACME webroot
    networks: [app-net]

networks:
  app-net:
    driver: bridge
```

关键取舍：

| 决策点 | 本手册选择 | 理由 |
|---|---|---|
| 服务器 build 还是 pull？ | **pull**（compose 里不写 `build:`） | 2C2G 跑 Maven/Node 构建必 OOM 或极慢 |
| backend 是否发布端口？ | 不发布（`expose`） | 唯一入口是 nginx，攻击面最小 |
| 证书进容器？ | 不进，宿主 certbot + `:ro` 挂载 | 续期不动容器 |
| 需要隧道网络？ | 默认桥接；探活不通再切 `network_mode: host` | host 模式牺牲隔离，模板里留注释变体 |
| 密钥放哪？ | 同目录 `.env`（已 gitignore） | compose 原生 `--env-file` 读取 |

## 4. 本地验证清单

```bash
docker compose up -d --build
docker compose ps                        # 两个服务都 Up
curl -I http://localhost/                # 301 到 https
curl -kI https://localhost/              # 200
curl -k https://localhost/api/<任一接口>  # 反代 + 后端 + 数据库全链路
docker compose logs --tail=50 backend    # 无权限 / 连接类报错
```

> 📌 本地验证通过 = Dockerfile、compose、nginx 配置、卷路径四者都正确。之后上线遇到的
> 问题只会来自「服务器环境差异」（uid / 内存 / 证书路径），这些归 `01-preflight` 管。
