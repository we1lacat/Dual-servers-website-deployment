#!/usr/bin/env bash
# rollback-frontend.sh — 前端一键回滚到上一版本
# 用法：sudo bash /tmp/rollback-frontend.sh
# 依赖：deploy-frontend.sh 部署时保留的 /var/www/we1l.site-vue.prev
set -u

DST=/var/www/we1l.site-vue
PREV="${DST}.prev"

if [ ! -d "$PREV" ]; then
  echo "没有找到上一版本 $PREV，无法回滚。当前生效目录："
  ls -ld "$DST"
  exit 1
fi

echo "== 回滚：把 $PREV 换回 $DST =="
mv "$DST" "${DST}.broken.$(date +%Y%m%d%H%M%S)"
mv "$PREV" "$DST"
chown -R www-data:www-data "$DST"
chmod -R a+rX "$DST"

echo "== 重载 nginx =="
nginx -t || { echo "nginx -t 失败，已中止"; exit 1; }
systemctl reload nginx; echo "reload exit=$?"

echo "== 验收 =="
for p in / /login /admin; do
  curl -sk -m 10 --resolve we1l.site:443:127.0.0.1 -o /dev/null -w "$p -> %{http_code}\n" "https://we1l.site$p"
done
echo "DONE（坏版本保留为 ${DST}.broken.*，确认无误后可自行删除）"
