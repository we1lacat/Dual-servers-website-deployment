#!/bin/bash
# deploy-frontend.sh — 让 nginx 指向新构建的 Vue 前端（SPA）
# 前置：前端产物已打包为 /tmp/frontend-dist.tar.gz（内容为 dist-new 目录下的文件）
set -u

DST=/var/www/we1l.site-vue
CONF=/etc/nginx/sites-enabled/we1l.site-ssl.conf
TARBALL=/tmp/frontend-dist.tar.gz

echo "== 1. 解压前端产物 → $DST =="
# 轮换：先把当前线上版本挪到 .prev，再解压新版本。
# 这样新版本有问题时可以一键回滚，不用重新构建上传。
if [ -d "$DST" ]; then
  rm -rf "${DST}.prev"
  mv "$DST" "${DST}.prev"
  echo "已把上一版本保留为 ${DST}.prev"
fi
mkdir -p "$DST"
tar -xzf "$TARBALL" -C "$DST"
chown -R www-data:www-data "$DST"
chmod -R a+rX "$DST"
echo "-- 文件清单：$(ls "$DST" | tr '\n' ' ')，assets 共 $(ls "$DST/assets" | wc -l) 个"

echo "== 2. 备份并修改 nginx 配置 =="
# 注意：备份绝不能放在 sites-enabled/ 内，nginx 的 include sites-enabled/* 会把它
#       当成配置一起加载，导致 443 端口出现重复 server 块 → nginx -t 失败 → reload 无效
mkdir -p /root/nginx-backups
cp -n "$CONF" "/root/nginx-backups/we1l.site-ssl.conf.bak.$(date +%Y%m%d%H%M%S)"
# 清理历史遗留（上一版脚本曾把 bak 写在 sites-enabled 里）
rm -f /etc/nginx/sites-enabled/*.bak.*
# root 指向新前端
sed -i "s#^\s*root /var/www/we1l.site;#    root $DST;#" "$CONF"
# SPA fallback：=404 会让 /login /admin /notes 等前端路由直接 404
sed -i 's#try_files.*=404;#try_files $uri $uri/ /index.html;#' "$CONF"
echo "-- 改动后的关键行："
grep -n 'root \|try_files' "$CONF"

echo "== 3. 语法检查（失败即中止，避免拿坏配置 reload）=="
nginx -t || { echo "nginx -t 失败，已中止，配置未生效"; exit 1; }

echo "== 4. 重载 nginx =="
systemctl reload nginx; echo "reload exit=$?"

echo "== 5. 验收 =="
H="-k --resolve we1l.site:443:127.0.0.1"
for p in / /login /admin /notes /about; do
  code=$(curl -sk -m 10 --resolve we1l.site:443:127.0.0.1 -o /dev/null -w '%{http_code}' "https://we1l.site$p")
  echo "https://we1l.site$p -> HTTP $code"
done
echo "-- 首页内容（应为 Vue 挂载点）--"
curl -sk -m 10 --resolve we1l.site:443:127.0.0.1 https://we1l.site/ | head -c 300; echo
echo "-- 静态资源（应 200 且 content-type 为 js/css）--"
JS=$(ls "$DST/assets" | grep -m1 '\.js$')
CSS=$(ls "$DST/assets" | grep -m1 '\.css$')
curl -sk -m 10 --resolve we1l.site:443:127.0.0.1 -o /dev/null -w "/assets/$JS  -> HTTP %{http_code} (%{content_type})\n" "https://we1l.site/assets/$JS"
curl -sk -m 10 --resolve we1l.site:443:127.0.0.1 -o /dev/null -w "/assets/$CSS -> HTTP %{http_code} (%{content_type})\n" "https://we1l.site/assets/$CSS"
echo "-- API 反代（应仍走 Tomcat）--"
curl -sk -m 10 --resolve we1l.site:443:127.0.0.1 https://we1l.site/api/profile | head -c 200; echo

echo "== DONE =="
echo "回滚：把 $CONF 里 root 改回 /var/www/we1l.site（备份在 /root/nginx-backups/），然后 nginx -t && systemctl reload nginx"
