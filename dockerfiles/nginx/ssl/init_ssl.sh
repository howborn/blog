#!/bin/bash

echo "### Stoping nginx ..."
docker-compose down

echo "### Starting nginx ..."
docker-compose -f docker-compose.yml -f network-override.yml up --force-recreate --build -d

# 是否启动完成
until [ "`docker inspect -f {{.State.Running}} nginx`"=="true" ]; do
    echo "### Wait nginx docker start ..."
    sleep 0.1;
done;

echo "### Gen nginx ssl ..."
docker exec nginx /bin/bash /var/www/ssl/refresh_cert.sh

echo "### Restart nginx ..."
docker exec nginx nginx -s reload