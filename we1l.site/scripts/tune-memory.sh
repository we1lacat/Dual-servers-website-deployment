#!/bin/bash
# tune-memory.sh — B 机内存优化
#   1) 配置 zram swap：给没有 swap 的机器一个 OOM 缓冲（压缩内存，无磁盘 I/O）
#   2) Tomcat 堆初始值 -Xms512m → -Xms256m：立刻释放约 250MB 常驻内存
# 两者都可重复执行（幂等）。
set -u

ZRAM_SIZE=512M
SWAPPINESS=10
ZRAMCTL=/usr/sbin/zramctl
HELPER=/usr/local/sbin/zram-swap.sh
UNIT=/etc/systemd/system/zram-swap.service

echo "===== 优化前 ====="
free -h | head -2
echo "-- swap --"
swapon --show || echo "（无 swap）"

# ---------------------------------------------------------------- 1. zram swap
echo
echo "== 1. 配置 zram swap（${ZRAM_SIZE}）=="

# 探测可用压缩算法：本机内核只有 lzo，写成回退链以兼容其他机器
ALGO=""
DEV=""
for a in zstd lzo-rle lzo; do
  /sbin/modprobe zram 2>/dev/null
  d=$("$ZRAMCTL" --find --size "$ZRAM_SIZE" --algorithm "$a" 2>/dev/null | awk '{print $1}')
  if [ -n "$d" ] && [ -b "$d" ]; then
    ALGO="$a"; DEV="$d"
    echo "压缩算法：$ALGO    设备：$DEV"
    break
  fi
done

if [ -z "$DEV" ]; then
  echo "无法创建 zram 设备（内核模块或压缩后端缺失），跳过 swap 配置"
else
  /sbin/mkswap "$DEV" >/dev/null 2>&1
  /sbin/swapon --priority 100 "$DEV"
  echo "-- 当前 swap --"
  swapon --show

  # 开机自动生效：helper 脚本 + systemd oneshot
  cat > "$HELPER" <<EOF
#!/bin/bash
# 由 scripts/tune-memory.sh 生成，勿手工编辑
set -u
SIZE=${ZRAM_SIZE}
ALGO=${ALGO}
ZRAMCTL=${ZRAMCTL}

case "\${1:-start}" in
  start)
    /sbin/modprobe zram 2>/dev/null
    if swapon --show=NAME --noheadings 2>/dev/null | grep -q 'zram'; then
      echo "zram swap 已启用"; exit 0
    fi
    dev=\$(\$ZRAMCTL --find --size "\$SIZE" --algorithm "\$ALGO" 2>/dev/null | awk '{print \$1}')
    [ -n "\$dev" ] || { echo "创建 zram 设备失败"; exit 1; }
    /sbin/mkswap "\$dev" >/dev/null 2>&1
    /sbin/swapon --priority 100 "\$dev"
    echo "zram swap 就绪：\$dev"
    ;;
  stop)
    dev=\$(\$ZRAMCTL --noheadings -o NAME 2>/dev/null | head -1)
    [ -n "\$dev" ] && swapoff "\$dev" 2>/dev/null
    [ -n "\$dev" ] && echo 1 > "/sys/block/\$(basename \$dev)/reset" 2>/dev/null
    ;;
esac
EOF
  chmod 0755 "$HELPER"

  cat > "$UNIT" <<EOF
[Unit]
Description=Configure zram swap device
Documentation=https://www.kernel.org/doc/html/latest/admin-guide/blockdev/zram.html
DefaultDependencies=no
After=systemd-modules-load.service local-fs.target
Before=swap.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$HELPER start
ExecStop=$HELPER stop

[Install]
WantedBy=sysinit.target
EOF

  # 低 swappiness：zram 只作为 OOM 缓冲，正常情况下仍优先使用物理内存
  echo "vm.swappiness=${SWAPPINESS}" > /etc/sysctl.d/99-zram-swap.conf
  sysctl -p /etc/sysctl.d/99-zram-swap.conf

  systemctl daemon-reload
  systemctl enable zram-swap.service
  echo "zram 开机自启：$(systemctl is-enabled zram-swap.service)"
fi

# ------------------------------------------------------------- 2. Tomcat 堆初始值
echo
echo "== 2. Tomcat 堆初始值 -Xms512m → -Xms256m =="
if grep -q -- '-Xms512m' /etc/default/tomcat10 2>/dev/null; then
  cp -n /etc/default/tomcat10 /root/nginx-backups/tomcat10-default.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null \
    || cp -n /etc/default/tomcat10 /etc/default/tomcat10.bak.$(date +%Y%m%d%H%M%S)
  sed -i 's/-Xms512m/-Xms256m/' /etc/default/tomcat10
  echo "已修改：$(grep -o -- '-Xms[0-9]*m' /etc/default/tomcat10)"
  echo "重启 tomcat10（约 30 秒不可用）..."
  systemctl restart tomcat10
  for i in $(seq 1 18); do
    sleep 5
    code=$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/profile 2>/dev/null || echo 000)
    echo "t=$((i*5))s  /api/profile -> HTTP $code"
    [ "$code" = "200" ] && break
  done
else
  echo "未找到 -Xms512m（可能已改过），跳过。当前：$(grep -o -- '-Xm[sx][0-9]*m' /etc/default/tomcat10 2>/dev/null | tr '\n' ' ')"
fi

# ------------------------------------------------------------------------- 汇总
echo
echo "===== 优化后 ====="
free -h | head -3
echo "-- swap --"
swapon --show
echo "-- zram 设备 --"
"$ZRAMCTL" 2>/dev/null
echo "-- JVM 参数 --"
grep -o -- '-Xm[sx][0-9]*m' /etc/default/tomcat10 | tr '\n' ' '; echo
echo "-- 服务自检 --"
curl -s -m 10 -o /dev/null -w 'HTTP 8080  /api/profile -> %{http_code}\n' http://127.0.0.1:8080/api/profile
curl -sk -m 10 --resolve we1l.site:443:127.0.0.1 -o /dev/null -w 'HTTPS      /api/profile -> %{http_code}\n' https://we1l.site/api/profile
ps -o pid,user,pmem,rss,comm --no-headers -C java | awk '{printf "java RSS: %.1fMB (%s%%)\n", $4/1024, $3}'

echo "== DONE =="
