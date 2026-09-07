#!/bin/bash
# we1l.site B机部署脚本：WAR + JVM参数 + nginx /api 反代 + 重启 + 验证
set -e

echo "== 1/5 部署 WAR 到 Tomcat =="
rm -rf /var/lib/tomcat10/webapps/ROOT /var/lib/tomcat10/webapps/ROOT.war
cp /tmp/ROOT.war /var/lib/tomcat10/webapps/ROOT.war
chown tomcat:tomcat /var/lib/tomcat10/webapps/ROOT.war
echo "OK: ROOT.war -> /var/lib/tomcat10/webapps/"

echo "== 2/5 写入 JVM / 应用配置 =="
JWT_SECRET=$(cat /opt/we1l/.jwt_secret)
ADMIN_PASSWORD=$(cat /opt/we1l/.admin_pwd)
cp /etc/default/tomcat10 "/etc/default/tomcat10.bak.$(date +%Y%m%d%H%M%S)"
cat > /etc/default/tomcat10 <<EOF
JAVA_OPTS="-Djava.awt.headless=true -Dfile.encoding=UTF-8 -Xms512m -Xmx768m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=192m -XX:+UseZGC -XX:+ZGenerational -XX:MaxGCPauseMillis=20 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/we1l/oom/ -XX:+ExitOnOutOfMemoryError -Djava.security.egd=file:/dev/./urandom -DDB_PATH=/opt/we1l/data/we1l.db -DJWT_SECRET=$JWT_SECRET -DJWT_EXPIRE_HOURS=8 -DADMIN_USERNAME=admin -DADMIN_PASSWORD=$ADMIN_PASSWORD -DCORS_ORIGINS=https://we1l.site,https://www.we1l.site"
EOF
chmod 644 /etc/default/tomcat10
echo "OK: /etc/default/tomcat10 (已备份原文件)"

echo "== 3/5 nginx 增加 /api 反向代理 =="
if ! grep -q 'location /api/' /etc/nginx/sites-enabled/we1l.site-ssl.conf; then
  sed -i '/location ~ \/\\./i\
    location /api/ {\
        proxy_pass http://127.0.0.1:8080/api/;\
        proxy_set_header Host $host;\
        proxy_set_header X-Real-IP $remote_addr;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
    }
' /etc/nginx/sites-enabled/we1l.site-ssl.conf
  echo "OK: 已插入 /api location"
else
  echo "SKIP: /api location 已存在"
fi
nginx -t

echo "== 4/5 重启 Tomcat / 重载 nginx =="
mkdir -p /opt/we1l/data /opt/we1l/oom
chown -R tomcat:tomcat /opt/we1l/data /opt/we1l/oom
systemctl restart tomcat10
systemctl reload nginx

echo "== 5/5 等待启动并验证 =="
sleep 20
echo "--- Tomcat 直连 127.0.0.1:8080 /api/profile ---"
curl -s http://127.0.0.1:8080/api/profile | head -c 300; echo
echo "--- nginx HTTPS /api/profile ---"
curl -sk --resolve we1l.site:443:127.0.0.1 https://we1l.site/api/profile | head -c 300; echo
echo "--- 完成 ---"
