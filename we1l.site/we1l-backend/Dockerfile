# ============================================================
# we1l.site 后端多阶段构建（B 方案：从源码出镜像，jar 不落地）
#
# 构建（本地 / CI 同一条命令，构建上下文 = 后端工程根）：
#   docker build -t we1l-backend:latest -f Dockerfile .
#
# 推送到阿里云 ACR（B 机生产用）：
#   docker tag we1l-backend:latest registry.cn-<地域>.aliyuncs.com/<命名空间>/we1l-backend:latest
#   docker push registry.cn-<地域>.aliyuncs.com/<命名空间>/we1l-backend:latest
# ============================================================

# ---- 构建阶段：完整 JDK + Maven ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
# 先拷 pom 再拷源码；如需依赖层缓存可在此插入 `mvn -B dependency:go-offline`
COPY pom.xml .
COPY src ./src
RUN mvn -B -ntp clean package -DskipTests

# ---- 运行阶段：仅 JRE，体积小 ----
FROM eclipse-temurin:21-jre
WORKDIR /app

# 数据 / 备份目录交给宿主机卷挂载；这里预建（容器以 root 运行，
# 避免 bind mount 权限问题；如需硬化可建非 root 用户并 chown，见注释）
RUN mkdir -p /opt/we1l/data /opt/we1l/backup

COPY --from=build /build/target/we1l-backend.jar app.jar

EXPOSE 8080

# MaxRAMPercentage=75：让 JVM 感知容器内存上限（B 机 2G），避免 OOM Kill
# prod profile 必须带：否则 data.sql 逻辑与 DB 初始化策略不生效
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar", "--spring.profiles.active=prod"]

# 硬化参考（取消注释以非 root 运行，需同步处理卷权限）：
# RUN groupadd -r we1l && useradd -r -g we1l we1l && chown -R we1l:we1l /opt/we1l /app
# USER we1l
