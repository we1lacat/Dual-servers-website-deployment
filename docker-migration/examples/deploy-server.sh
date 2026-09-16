#!/usr/bin/env bash
# ============================================================================
# deploy-server.sh —— 目标服务器一键部署（Debian 系，非 root 运维账号）
#
# 在服务器上执行：  bash deploy-server.sh
# 脚本含 sudo 步骤，会在终端交互式提示输入密码。
#
# 前置（可先跑 docs/01 的只读检查确认就绪）：
#   ~/deploy/ 下已有 docker-compose.prod.yml / .env / nginx/default.conf
#   镜像已推送到私有仓库（build-push.sh）
# ============================================================================
set -euo pipefail

# ---------- 按你的环境修改这几行 ----------
DEPLOY_SRC="$HOME/deploy"                  # 配置文件所在目录
APP_DIR=/opt/myapp                         # 应用根目录（数据/配置/编排都放这）
OLD_SERVICE="tomcat10"                     # 要停掉的旧服务（按 01-preflight 实测改）
CERT_NAME="example.com"                    # 证书名（须与 nginx 配置里 live/<名字> 一致）
REGISTRY_USER="<your-registry-user>"

echo "==> [1/6] 确保 Docker + compose 插件就绪"
if ! command -v docker >/dev/null 2>&1; then
  # NEEDRESTART_MODE=l：needrestart 只列不重启、不交互
  # （否则 apt 弹全屏"重启哪些服务"，SSH 里可能卡死/断连，见 docs/05 #5）
  sudo env NEEDRESTART_MODE=l apt-get update
  sudo env NEEDRESTART_MODE=l apt-get install -y docker.io
  sudo systemctl enable --now docker
else
  echo "    Docker 已安装：$(docker --version)"
fi
# ⚠️ Debian 的 compose 插件包名是 docker-compose（提供 `docker compose` 子命令），
#    并非 Docker 官方源的 docker-compose-plugin。缺它则 docker compose 不可用。
if ! sudo docker compose version >/dev/null 2>&1; then
  echo "    安装 docker compose 插件 …"
  sudo env NEEDRESTART_MODE=l apt-get install -y docker-compose
fi
sudo docker compose version

echo "==> [2/6] 停旧服务（释放内存 + 被容器替代；先 stop 验证稳定后再 disable）"
if systemctl list-units --all 2>/dev/null | grep -q "$OLD_SERVICE"; then
  sudo systemctl stop "$OLD_SERVICE" && echo "    $OLD_SERVICE 已停"
  # 回滚用：sudo systemctl start $OLD_SERVICE
  # 稳定后：sudo systemctl disable $OLD_SERVICE
else
  echo "    未发现 $OLD_SERVICE，跳过"
fi

echo "==> [3/6] 检查现有证书（live/ 仅 root 可读，看不到 ≠ 不存在，须 sudo）"
if sudo certbot certificates 2>/dev/null | grep -q "$CERT_NAME"; then
  echo "    ✅ 证书已存在，无需签发"
else
  echo "    ⚠️ 未查到证书。若确需签发（standalone 独占 80，先确认 80 空闲）："
  echo "       sudo certbot certonly --standalone -d $CERT_NAME -d www.$CERT_NAME --cert-name $CERT_NAME"
  echo "    注意：务必带 --cert-name，否则 live 目录名与 nginx 写死的路径不匹配。"
fi

echo "==> [4/6] 建目录 + 安装配置到 $APP_DIR"
sudo mkdir -p "$APP_DIR/data" "$APP_DIR/backup" "$APP_DIR/oom" "$APP_DIR/nginx"
sudo cp "$DEPLOY_SRC/docker-compose.prod.yml" "$APP_DIR/docker-compose.prod.yml"
sudo cp "$DEPLOY_SRC/.env"                   "$APP_DIR/.env"
sudo cp "$DEPLOY_SRC/nginx/default.conf"     "$APP_DIR/nginx/default.conf"
# 卷目录属主对齐 .env 里的 APP_UID/APP_GID（SQLite WAL 文件权限 640，属主不对写不进）
APP_UID="$(sed -n 's/^APP_UID=//p' "$DEPLOY_SRC/.env")"
APP_GID="$(sed -n 's/^APP_GID=//p' "$DEPLOY_SRC/.env")"
sudo chown -R "${APP_UID}:${APP_GID}" "$APP_DIR/data" "$APP_DIR/backup" "$APP_DIR/oom"
echo "    属主确认："; ls -ld "$APP_DIR/data" "$APP_DIR/backup" "$APP_DIR/oom"

echo "==> [5/6] 登录镜像仓库（未登录时）+ 拉取镜像并启动"
cd "$APP_DIR"
# ⚠️ sudo docker 使用 root 的 /root/.docker/config.json（与普通用户、开发机互不相通）
REGISTRY="$(sed -n 's/^REGISTRY=//p' .env)"
if [ -n "$REGISTRY" ] && ! sudo grep -q "$REGISTRY" /root/.docker/config.json 2>/dev/null; then
  echo "    未登录镜像仓库，请输入镜像仓库密码（开通服务时设置的那个）："
  sudo docker login --username="$REGISTRY_USER" "$REGISTRY"
fi
sudo docker compose -f docker-compose.prod.yml --env-file .env pull
sudo docker compose -f docker-compose.prod.yml --env-file .env up -d

echo "==> [6/6] 状态"
sudo docker compose -f docker-compose.prod.yml --env-file .env ps
echo
echo "查看日志："
echo "  sudo docker compose -f docker-compose.prod.yml --env-file .env logs -f --tail=80"
echo "本机验证："
echo "  curl -I http://localhost ; curl -kI https://localhost"
echo "公网验证："
echo "  curl -I https://<你的域名>/"
