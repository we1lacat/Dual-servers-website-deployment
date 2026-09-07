#!/bin/bash
# fix-swap.sh — 补上缺失的 swap（OOM 缓冲）
# 策略：优先 zram（压缩内存、无磁盘 I/O）；任一环节失败自动回退 swapfile，保证必有 swap
# 幂等：已存在 swap 则跳过
set -u

SWAPPINESS=10
ZRAM_SIZE=512M

have_swap() { swapon --show=NAME --noheadings 2>/dev/null | grep -q .; }

setup_swapfile() {
  echo "== 方案 B：1GB swapfile =="
  if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile 2>/dev/null \
      || dd if=/dev/zero of=/swapfile bs=1M count=1024 status=none
    chmod 600 /swapfile
  fi
  /sbin/mkswap /swapfile >/dev/null
  /sbin/swapon --priority 100 /swapfile
  if ! grep -q '^/swapfile' /etc/fstab; then
    echo '/swapfile none swap sw,pri=100 0 0' >> /etc/fstab
  fi
  echo "swapfile 就绪，并已写入 /etc/fstab 持久化"
}

echo "===== 现状 ====="
free -h | head -2
swapon --show 2>/dev/null || echo "（无 swap）"

# 统一的低 swappiness：swap 只当应急缓冲，平时仍优先用物理内存
echo "vm.swappiness=${SWAPPINESS}" > /etc/sysctl.d/99-swap.conf
sysctl -p /etc/sysctl.d/99-swap.conf >/dev/null 2>&1
echo "swappiness = $(cat /proc/sys/vm/swappiness)"

if have_swap; then
  echo "已有 swap，跳过创建。"
else
  # ---------------- 方案 A：zram（verbose，失败原因直接可见）----------------
  echo
  echo "== 方案 A：zram =="
  if /sbin/modprobe zram 2>&1; then
    DEV=""
    for a in lzo lzo-rle zstd; do
      out=$(/usr/sbin/zramctl --find --size "$ZRAM_SIZE" --algorithm "$a" 2>&1)
      rc=$?
      echo "  尝试 algo=$a → rc=$rc  $(echo "$out" | head -1)"
      if [ $rc -eq 0 ]; then
        DEV=$(echo "$out" | awk '{print $1; exit}')
        ALGO="$a"
        break
      fi
      /usr/sbin/zramctl --reset /dev/zram0 2>/dev/null
    done

    if [ -n "$DEV" ] && /sbin/mkswap "$DEV" >/dev/null 2>&1 && /sbin/swapon --priority 100 "$DEV" 2>/dev/null; then
      echo "zram swap 就绪：$DEV (algo=$ALGO)"

      # 开机自启：写一个可独立调用的 helper（unit 只负责调它）
      cat > /usr/local/sbin/zram-swap.sh <<HELPER
#!/bin/bash
set -u
ZRAMCTL=/usr/sbin/zramctl
case "\${1:-start}" in
  start)
    /sbin/modprobe zram 2>/dev/null
    swapon --show=NAME --noheadings 2>/dev/null | grep -q zram && { echo "zram swap 已启用"; exit 0; }
    dev=\$(\$ZRAMCTL --find --size $ZRAM_SIZE --algorithm $ALGO 2>/dev/null | awk '{print \$1; exit}')
    [ -n "\$dev" ] || { echo "创建 zram 设备失败"; exit 1; }
    /sbin/mkswap "\$dev" >/dev/null 2>&1
    /sbin/swapon --priority 100 "\$dev"
    echo "zram swap 就绪：\$dev"
    ;;
  stop)
    dev=\$(\$ZRAMCTL --noheadings -o NAME 2>/dev/null | head -1)
    [ -n "\$dev" ] && /sbin/swapoff "\$dev" 2>/dev/null
    [ -n "\$dev" ] && echo 1 > "/sys/block/\$(basename \$dev)/reset" 2>/dev/null
    ;;
esac
HELPER
      chmod 0755 /usr/local/sbin/zram-swap.sh

      cat > /etc/systemd/system/zram-swap.service <<UNIT
[Unit]
Description=Configure zram swap device
Documentation=https://www.kernel.org/doc/html/latest/admin-guide/blockdev/zram.html
DefaultDependencies=no
After=systemd-modules-load.service local-fs.target
Before=swap.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/zram-swap.sh start
ExecStop=/usr/local/sbin/zram-swap.sh stop

[Install]
WantedBy=sysinit.target
UNIT
      systemctl daemon-reload
      systemctl enable zram-swap.service >/dev/null 2>&1
      echo "zram 开机自启：$(systemctl is-enabled zram-swap.service 2>/dev/null)"
    else
      echo ">> zram 方案失败，回退 swapfile"
      /sbin/swapoff /dev/zram0 2>/dev/null
      /usr/sbin/zramctl --reset /dev/zram0 2>/dev/null
      setup_swapfile
    fi
  else
    echo ">> zram 模块不可用，直接走 swapfile"
    setup_swapfile
  fi
fi

echo
echo "===== 结果 ====="
free -h | head -3
swapon --show
echo "-- 持久化方式 --"
[ -f /etc/systemd/system/zram-swap.service ] && echo "zram systemd unit（enabled）" || true
grep -E '^/swapfile' /etc/fstab && echo "swapfile 已入 fstab" || true
echo "== DONE =="
