# ============================================================
# we1l-frontend 多阶段构建
# 阶段1 node：npm ci + vite build → dist/
# 阶段2 nginx：仅承载静态 SPA（反代/SSL 由 docker-websev/nginx/default.conf 提供）
# 用途：docker-websev/docker-compose.yml 的 nginx 服务 build 此上下文，
#       不再需要手动把 dist 拷进 frontend-dist/
# ============================================================

# ---- 阶段 1：构建 ----
FROM node:20-alpine AS build
WORKDIR /app

# 先拷依赖清单，利用层缓存（依赖不变时改源码不重装）
COPY package.json package-lock.json ./
RUN npm ci

# 再拷源码并构建（vue-tsc 类型检查 + vite 打包）
COPY . .
RUN npm run build

# ---- 阶段 2：运行态 ----
FROM nginx:1.27-alpine

# 清掉默认站点，避免与挂载的 default.conf 冲突
# （compose 会挂载 docker-websev/nginx/default.conf 覆盖此文件）
RUN rm -f /etc/nginx/conf.d/default.conf

# 烘焙静态产物；SPA history 回退/缓存策略由挂载的 default.conf 决定
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
