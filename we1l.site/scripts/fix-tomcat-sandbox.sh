#!/bin/bash
# fix-tomcat-sandbox.sh v2 — 修复 Tomcat10 沙箱写权限
# 关键：unit 最后一段是 [Install]，路径赋值必须插在 [Service] 段内部，
#       直接追加到文件末尾会落在 [Install] 中被 systemd 静默忽略（v1 的 bug）。
set -u

SRC=/usr/lib/systemd/system/tomcat10.service
DST=/etc/systemd/system/tomcat10.service

echo "== 1. 生成 /etc 覆盖 unit（ReadWritePaths 插入 [Service] 段内）=="
awk '
/^\[/ {
  if (inSvc) {
    print ""
    print "# --- we1l.site: SQLite / OOM dump / 备份目录可写 ---"
    print "ReadWritePaths=/opt/we1l/data"
    print "ReadWritePaths=/opt/we1l/oom"
    print "ReadWritePaths=/opt/we1l/backup"
    inSvc = 0
  }
}
/^\[Service\]/ { inSvc = 1 }
{ print }
END {
  if (inSvc) {
    print ""
    print "# --- we1l.site: SQLite / OOM dump / 备份目录可写 ---"
    print "ReadWritePaths=/opt/we1l/data"
    print "ReadWritePaths=/opt/we1l/oom"
    print "ReadWritePaths=/opt/we1l/backup"
  }
}
' "$SRC" > "$DST"

echo "== 2. 自检：插入位置必须在 [Service] 与 [Install] 之间 =="
SVC=$(grep -n '^\[Service\]' "$DST" | head -1 | cut -d: -f1)
INS=$(grep -n '^\[Install\]' "$DST" | head -1 | cut -d: -f1)
RW=$(grep -n 'ReadWritePaths=/opt/we1l/data' "$DST" | head -1 | cut -d: -f1)
echo "Service@$SVC  we1l@$RW  Install@$INS"
if [ -n "$RW" ] && [ "$RW" -gt "$SVC" ] && [ "$RW" -lt "$INS" ]; then
  echo "INSERT_OK"
else
  echo "INSERT_FAIL —— 中止，未做 daemon-reload"
  exit 1
fi

echo "== 3. daemon-reload =="
systemctl daemon-reload; echo "daemon-reload exit=$?"
echo "-- 生效的 ReadWritePaths："
systemctl show tomcat10 -p ReadWritePaths

echo "== 4. 重启 Tomcat =="
systemctl restart tomcat10; echo "restart exit=$?"

echo "== 5. 等待 Spring 启动（最多 90 秒）=="
for i in $(seq 1 18); do
  sleep 5
  code=$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/profile 2>/dev/null || echo 000)
  echo "t=$((i*5))s  /api/profile -> HTTP $code"
  [ "$code" = "200" ] && break
done

echo "== 6. 验收 =="
stat -c '%s bytes  %n' /opt/we1l/data/* 2>/dev/null || echo "DB_NOT_CREATED"
echo "-- 直连 8080："
curl -s -m 10 http://127.0.0.1:8080/api/profile | head -c 300; echo
echo "-- HTTPS 入口："
curl -sk -m 10 --resolve we1l.site:443:127.0.0.1 https://we1l.site/api/profile | head -c 300; echo
echo "-- 登录接口（错密码应返回 401 JSON）："
curl -s -m 10 -X POST http://127.0.0.1:8080/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"wrong"}' | head -c 200; echo
echo "-- 进程挂载表（应出现 /opt/we1l）："
PID=$(systemctl show tomcat10 -p MainPID --value)
grep 'we1l' /proc/$PID/mountinfo | awk '{print $5, $6}' || echo "NO_WE1L_MOUNT"

echo "== 7. 导出最近日志供远程排查 =="
tail -n 100 /var/log/tomcat10/catalina.*.log > /tmp/tomcat-last.log 2>/dev/null \
  || journalctl -u tomcat10 -n 100 --no-pager > /tmp/tomcat-last.log
chmod 644 /tmp/tomcat-last.log

echo "== DONE =="
