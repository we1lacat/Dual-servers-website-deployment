#!/usr/bin/env bash
# ============================================================================
# 服务器 · 受限部署入口（CI 的唯一可执行目标）
#
# 配置方式（两处缺一不可）：
#   1) authorized_keys 里该 CI 公钥的条目：
#        command="/home/<user>/deploy/remote-deploy.sh",restrict ssh-ed25519 AAAA... gh-actions-deploy
#      - command= ：无论客户端请求什么命令，都只执行本脚本
#      - restrict ：禁掉 pty / 端口转发 / agent 转发 / X11 / user-rc
#   2) /etc/sudoers.d/<name>（仅两条，参数逐字一致）：
#        <user> ALL=(root) NOPASSWD: /usr/bin/docker compose -f /opt/myapp/docker-compose.prod.yml --env-file /opt/myapp/.env pull
#        <user> ALL=(root) NOPASSWD: /usr/bin/docker compose -f /opt/myapp/docker-compose.prod.yml --env-file /opt/myapp/.env up -d
#
# ⚠️ 下面两条命令的参数必须与 sudoers **逐字一致（含绝对路径）**，否则 NOPASSWD 不命中，
#    sudo -n 会报 "a password is required"（见 docs/06 §5.2）。
# ============================================================================
set -euo pipefail

cd /opt/myapp

sudo -n docker compose -f /opt/myapp/docker-compose.prod.yml --env-file /opt/myapp/.env pull
sudo -n docker compose -f /opt/myapp/docker-compose.prod.yml --env-file /opt/myapp/.env up -d

echo "==> 部署完成（镜像 tag 见 /opt/myapp/.env）"
