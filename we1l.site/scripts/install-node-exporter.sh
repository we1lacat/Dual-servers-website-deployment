#!/bin/bash
# install-node-exporter.sh — 官方二进制方式安装 Prometheus Node Exporter
# 前置：/tmp/node_exporter-1.12.1.linux-amd64.tar.gz 已上传
# 要点：只监听 WireGuard 隧道地址，公网/云内网一律不可达，云安全组无需放行 9100
set -eu

VER=1.12.1
WG_IP=10.10.0.1              # B 机在 WireGuard 里的地址；A 机安装时改成 10.10.0.2
PORT=9100
PUB_IP=<B_PUBLIC_IP>          # 仅用于"公网不可达"自测占位，替换为实际公网 IP 或直接跳过
TARBALL=/tmp/node_exporter-${VER}.linux-amd64.tar.gz
EXPECTED_SHA=b51d8a76aa2a9156a55d501aca6276fae09e262259a5e4e831d2c2222f084e63

echo "== 1. 校验 SHA256（必须与官方 sha256sums.txt 一致）=="
echo "${EXPECTED_SHA}  ${TARBALL}" | sha256sum -c -

echo "== 2. 解包并安装二进制 =="
cd /tmp
tar -xzf "${TARBALL}"
install -m 0755 "node_exporter-${VER}.linux-amd64/node_exporter" /usr/local/bin/node_exporter
/usr/local/bin/node_exporter --version 2>&1 | head -3

echo "== 3. 创建专用系统用户与 textfile 目录 =="
id -u node_exporter >/dev/null 2>&1 || \
  useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
mkdir -p /var/lib/node_exporter/textfile
chown -R node_exporter:node_exporter /var/lib/node_exporter

echo "== 4. 写 systemd unit（只绑隧道地址 + 只读加固）=="
cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target wg-quick@wg0.service
Wants=network-online.target wg-quick@wg0.service

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \\
  --web.listen-address=${WG_IP}:${PORT} \\
  --collector.textfile.directory=/var/lib/node_exporter/textfile
Restart=on-failure
RestartSec=5

# 导出器只读，无需任何写权限
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ProtectKernelTunables=yes
ProtectControlGroups=yes
RestrictSUIDSGID=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node_exporter
sleep 2
echo "-- 服务状态：$(systemctl is-active node_exporter)"

echo "== 5. 验证 =="
echo "-- 监听地址（必须只有隧道 IP，不能出现 0.0.0.0:9100）--"
ss -lntp | grep "${PORT}" || echo "未监听，检查日志：journalctl -u node_exporter -n 30"

echo "-- 指标条数 --"
curl -s -m 5 "http://${WG_IP}:${PORT}/metrics" | grep -c '^node_' || true
echo "-- 主机信息 --"
curl -s -m 5 "http://${WG_IP}:${PORT}/metrics" | grep -m1 '^node_uname_info' || true

echo "-- 公网 IP 访问应失败（证明没有暴露到公网；PUB_IP 需替换为实际值）--"
curl -s -m 5 -o /dev/null -w "${PUB_IP}:9100 -> %{http_code}\n" \
  http://${PUB_IP}:9100/metrics || echo "公网不可达（符合预期）"

echo "== DONE =="
echo "下一步：在 A 机的 prometheus.yml 里加 target '${WG_IP}:${PORT}'"

echo "-- 遗留检查 --"
if [ -d /opt/node_exporter ]; then
  echo "发现手工解包的旧版本目录 /opt/node_exporter（1.8.2，未启用）。"
  echo "确认无需可删除：sudo rm -rf /opt/node_exporter"
fi
