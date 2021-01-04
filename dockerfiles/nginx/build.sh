#!/bin/bash

dir="/var/www/ssl"
certs_dir="$dir/certs"

mkdir -p dir/challenges

# 是否启用HTTPS
if [ "$ENABLE_SSL" = "false" ]; then

    # 修改nginx配置, 不启用HTTPS
    sed -i '/ssl/d' /etc/nginx/nginx.conf
else

    # 每2个月更新一次, 并重启nginx容器
    ssl_cron="0 0 1 */2 * $dir/refresh_cert.sh && nginx -s reload 2>> /var/log/acme_tiny.log"
    crontab -l | { cat; echo "$ssl_cron"; } | crontab -
fi

# 前台启动
nginx -g "daemon off;"