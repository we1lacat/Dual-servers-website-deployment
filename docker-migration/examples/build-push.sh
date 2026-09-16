#!/usr/bin/env bash
# ============================================================================
# build-push.sh —— 开发机本地构建并推送到私有镜像仓库
#
# 用法（Windows 建议用 Git Bash 跑；Linux/macOS 直接跑）：
#   bash build-push.sh
# 前置：
#   1) Docker（Desktop）已启动
#   2) 已 docker login 过目标仓库（登录态在 ~/.docker/config.json，本脚本复用，
#      全程不接触密码）
# ============================================================================
set -euo pipefail

# ---------- 按你的环境修改这几行 ----------
REGISTRY="<your-registry>"                 # 例：crpi-xxxxxxxx.cn-hangzhou.personal.cr.aliyuncs.com
NS="<your-namespace>"                      # 命名空间
REPO="myapp"                               # 同一仓库，tag 区分服务
REGISTRY_USER="<your-registry-user>"

# 源码位置（前后端各自的工程根，即 Dockerfile 所在目录 = 构建上下文）
BACKEND_SRC="${BACKEND_SRC:-./backend}"
FRONTEND_SRC="${FRONTEND_SRC:-./frontend}"

BACKEND_IMAGE="$REGISTRY/$NS/$REPO:backend"
FRONTEND_IMAGE="$REGISTRY/$NS/$REPO:frontend"

# 本地临时 tag（与仓库镜像区分开）
LOCAL_BACKEND="myapp-backend:local"
LOCAL_FRONTEND="myapp-frontend:local"

# 关闭 BuildKit 默认的 provenance/SBOM 证明清单。
# 否则镜像附带 application/vnd.oci.empty.v1+json 证明 manifest，
# 部分私有仓库（如阿里云 ACR 个人版）push 报：
#   error from registry: unknown manifest class for application/vnd.oci.empty.v1+json
# 已构建过的旧镜像须重新 build 后再 push（带 attestation 的旧镜像直接推仍失败）
export BUILDX_NO_DEFAULT_ATTESTATIONS=1
BUILD_OPTS="--provenance=false --sbom=false"

# [1/4] 登录（已登录则跳过；密码只在此处交互输入，不进脚本/不进聊天/不进 git）
if grep -q "$REGISTRY" ~/.docker/config.json 2>/dev/null; then
  echo "==> [1/4] 已登录 $REGISTRY，跳过 docker login"
else
  echo "==> [1/4] 登录 $REGISTRY（输入镜像仓库密码，非云账号登录密码）"
  docker login --username="$REGISTRY_USER" "$REGISTRY"
fi

echo "==> [2/4] 构建 backend（多阶段 maven 构建，耗时会较长）"
docker build $BUILD_OPTS -t "$LOCAL_BACKEND" -f "$BACKEND_SRC/Dockerfile" "$BACKEND_SRC"

echo "==> [3/4] 构建 frontend（node 出 dist，烘焙进 nginx）"
docker build $BUILD_OPTS -t "$LOCAL_FRONTEND" -f "$FRONTEND_SRC/Dockerfile" "$FRONTEND_SRC"

echo "==> [4/4] tag + push（push 推的是 tag 全名，本地名必须先 tag）"
docker tag "$LOCAL_BACKEND"  "$BACKEND_IMAGE"
docker tag "$LOCAL_FRONTEND" "$FRONTEND_IMAGE"
docker push "$BACKEND_IMAGE"
docker push "$FRONTEND_IMAGE"

echo
echo "✅ 推送完成。服务器侧执行："
echo "   sudo docker login --username=$REGISTRY_USER $REGISTRY   # 服务器须单独登录（root 凭据作用域）"
echo "   docker compose -f docker-compose.prod.yml --env-file .env pull"
echo "   docker compose -f docker-compose.prod.yml --env-file .env up -d"
