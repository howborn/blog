---
title: 使用Docker轻松部署Hexo博客系统
date: 2020-12-27 14:00:00
tags:
- 工具
- 系统设计
categories:
- 系统设计
---

我的 [博客](https://www.fanhaobai.com) 停服已经有几个月了，主要原因是使用的 [Google Cloud](https://cloud.google.com/free/) 免费服务器已经到期了，而整个博客系统的迁移成本很大，因此迟迟没有开启服务。

![预览图](//img0.fanhaobai.com/2020/12/hexo-to-docker/704035c6-348e-439b-9048-d05a2a18ef1f.png)<!--more-->

这周末，终于有时间来彻底解决博客迁移问题了。通过改造 Hexo 博客系统，使其支持 Docker 部署，彻底摆脱了运行环境依赖，以后再更换云服务器厂商时，就可以做到快速平滑迁移了。

我的博客做过定制化改造，使用的是 [hexo-theme-yilia](https://github.com/fan-haobai/hexo-theme-yilia) 作为主题，评论使用的是 [disqus-php-api](https://github.com/fan-haobai/disqus-php-api)，支持 HTTPS 协议，因此本次改造主要涉及这些。

## Docker 环境

### 云服务器

由于没有了 Google Cloud 的免费使用资格，只能在国内挑选较便宜的腾讯云云服务器厂商，购买了一台低配云服务器。

这台服务器的操作系统是 [CentOS]()，我们选用 [Docker Compose](https://docs.docker.com/compose/install/) 作为容器编排工具。

### 安装 Docker

```bash
# 1.删除旧的Docker版本
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# 2.添加Docker源
sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# 3.安装Docker
sudo yum install docker-ce docker-ce-cli containerd.io
sudo yum install docker-ce-20.10.1 docker-ce-cli-20.10.1 containerd.io

# 4.启动Docker
sudo systemctl start docker

# 5.查看Docker版本
docker -v
Docker version 20.10.1, build 831ebea
```

### 安装 Docker Compose

```bash
# 1.获取docker-compose脚本
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 2.增加可执行权限
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# 3.查看版本
docker-compose --version
docker-compose version 1.27.4, build 40524192
```

## 项目改造

### 调整目录结构

之前的目录结构较为单一，需调整项目目录结构。调整后的目录结构如下：

```bash
├── _config.yml           # Hexo配置文件
├── disqus                # Disqus评论
├── themes                # Hexo主题
│   └── yilia             # hexo-theme-yilia主题
├── source                # 文章.md文件
├── public                # Hexo发布后的静态资源文件
├── dockerfiles           # Dockerfile文件
│   ├── nginx
│   ├── nodejs
│   └── php
├── docker-compose.yml    # 容器编排配置
├── docker.env            # Docker环境变量文件
├── docker.example.env    # Docker环境变量示例文件
├── network-override.yml  # 容器编排配置（特殊网络）
└── package.json          # Hexo依赖包
```

其中，`disqus` 和 `yilia` 目录分别对应 [disqus-php-api](https://github.com/fan-haobai/disqus-php-api) 和 [hexo-theme-yilia](https://github.com/fan-haobai/hexo-theme-yilia) 这 2 个子项目，并采用 `submodule` 模式管理这些源代码。

> 在 `submodule` 模式下，`clone` 和 `pull` 命令会有一些变化，分别为 `git clone --recursive https://github.com/fan-haobai/blog.git`
和 `git pull && git submodule foreach git pull origin master`。

### 编排容器

本博客系统，主要依赖 `NodeJS`、`PHP`、`Nginx` 环境，因此分别构建 3 个容器。

### 配置 docker-compose.yml

Docker Compose 会根据 `docker-compose.yml` 配置文件，来自动编排容器。配置如下：

```bash
version: '3'
services:
  nginx:
    restart: always
    build: ./dockerfiles/nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      # 博客源代码
      - "/var/www/blog:/var/www/blog"
      # HTTPS证书
      - "/var/www/ssl/certs:/var/www/ssl/certs"
      # Nginx配置
      - "$PWD/dockerfiles/nginx/conf.d:/etc/nginx/conf.d"
    command: /bin/bash /build.sh
    env_file:
      - docker.env
    extra_hosts:
      - "raw.githubusercontent.com:199.232.96.133"
    container_name: "nginx"
  nodejs:
    build: ./dockerfiles/nodejs
    ports:
      - "4000:4000"
    volumes:
      - "/var/www/blog:/var/www/blog"
    container_name: "nodejs"
  php:
    restart: always
    build: ./dockerfiles/php
    expose:
      - "9000"
    volumes:
      - "/var/www/blog:/var/www/blog"
    container_name: "php"
```

其中，`services` 下为需要编排的 `nodejs`、`php`、`nginx` 容器服务。每个容器服务都可以灵活配置，常见的配置参数如下：

* restart：容器退出时，是否重启
* build：构建容器 Dockerfile 文件所在的目录
* ports：映射端口
* volumes：挂载目录
* command：容器启动后执行的命令
* env_file：环境变量文件
* extra_hosts：域名IP映射
* container_name：容器名称

> Docker Compose 支持多配置文件，且为覆盖关系。因此将 `ssl-override.yml` 作为获取 HTTPS 证书时启动容器的配置文件。

### 配置 docker.env

环境变量统一配置在 `docker.env` 文件中，并增加示例环境文件 `docker.example.env`。环境变量目前较少，如下：

```bash
# 是否启用HTTPS证书
ENABLE_SSL=true

# 支持HTTPS协议的域名
SSL_DOMAINS=fanhaobai.com,www.fanhaobai.com
```

### 构建 Dockerfile

Dockerfile 文件统一放在 `dockerfiles` 目录下，并分别建立 `nodejs`、`php`、`nginx` 文件夹。

#### NodeJS

该容器下需要安装 `git`、`npm`。Dockerfile 文件如下：

```bash
FROM node:12-alpine

RUN echo "Asia/Shanghai" > /etc/timezone \
    && echo "https://mirrors.ustc.edu.cn/alpine/v3.9/main/" > /etc/apk/repositories  \
    && npm config set registry https://registry.npm.taobao.org \
    && apk add --no-cache git \
    && npm install hexo-cli -g

ADD *.sh /
RUN chmod 777 /*.sh

EXPOSE 4000

ENTRYPOINT ["sh", "/build.sh"]
```

其中，`build.sh` 为容器的启动脚本，主要作用为生成静态资源文件。内容如下：

```bash
#!/bin/bash

cd /var/www/blog

# 生成静态资源
/bin/sh /build_hexo.sh

hexo s
```

脚本 `build_hexo.sh` 内容如下：

```bash
#!/bin/bash

cd /var/www/blog

# 更新代码
git pull && git submodule foreach git pull origin master

# 生成静态资源
npm install --force
# hexo clean
hexo g
```

#### PHP

该容器基于官方的基础镜像，安装一些必要的扩展。Dockerfile 文件如下：

```bash
FROM php:7.3.7-fpm-alpine3.9

RUN echo 'https://mirrors.aliyun.com/alpine/v3.9/main/' > /etc/apk/repositories && \
    echo 'https://mirrors.aliyun.com/alpine/v3.9/community/' >> /etc/apk/repositories

# 安装扩展
RUN apk add --no-cache $PHPIZE_DEPS \
    && apk add --no-cache libstdc++ libzip-dev vim\
    && apk update \
    && apk del $PHPIZE_DEPS
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
    && apk update \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) opcache \
    && docker-php-ext-install -j$(nproc) bcmath

# 配置文件
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
ADD conf.d/* $PHP_INI_DIR/conf.d/
```

其中，`conf.d` 下为 `php` 的配置文件。

#### Nginx

* Dockerfile 文件

该容器基于官方的基础镜像，并安装 `cron`、`wget`、`python`。Dockerfile 文件如下：

```bash
FROM nginx:latest

# 安装cron等
RUN sed -i s@/deb.debian.org/@/mirrors.aliyun.com/@g /etc/apt/sources.list \
    && apt-get update && apt-get install -y cron wget python

# 启动脚本和配置
ADD build.sh build.sh
ADD nginx.conf /etc/nginx/nginx.conf

# HTTPS证书生成脚本
ADD ssl/* /var/www/ssl/
RUN chmod +x /var/www/ssl/*.sh

RUN chmod 777 -R /var/log/nginx
```

其中，`conf.d` 下为 `nginx` 的配置文件，`ssl` 下为 HTTPS 证书的生成脚本。

* HTTPS 证书生成脚本

`ssl` 下的 `init_ssl.sh` 为首次获取 HTTPS 证书脚本，`refresh_cert.sh` 为更新 HTTPS 证书脚本。

其中，`init_ssl.sh` 脚本内容如下：

```bash
#!/bin/bash

echo "### Stoping nginx ..."
docker-compose down

# 启动容器
echo "### Starting nginx ..."
docker-compose -f docker-compose.yml -f ssl-override.yml up --force-recreate --build -d

# 是否启动完成
until [ "`docker inspect -f {{.State.Running}} nginx`"=="true" ]; do
    echo "### Wait nginx docker start ..."
    sleep 0.1;
done;

# 生成HTTPS证书
echo "### Gen nginx ssl ..."
docker exec nginx /bin/bash /var/www/ssl/refresh_cert.sh

# 重启nginx
echo "### Restart nginx ..."
docker exec nginx nginx -s reload
```

> `ssl-override.yml` 会覆盖 `docker-compose.yml` 中的环境变量，因此会将环境变量 `ENABLE_SSL` 设置为 `false`，并将 `php` 解析到 `127.0.0.1`，以确保 `nginx` 容器在首次能成功启动。 

而 `refresh_cert.sh` 脚本内容如下：

```bash
#!/bin/bash

dir='/var/www/ssl'
certs_dir="$dir/certs"

mkdir -p $certs_dir
cd $certs_dir

if [ -z "$SSL_DOMAINS" ]; then
    echo "### Domains is empty"
    exit 1
fi

echo "### Starting ssl ..."

openssl genrsa 4096 > account.key
openssl genrsa 4096 > domain.key

domains=`echo "DNS:$SSL_DOMAINS" | sed 's/,/&DNS:/g'`
echo "### Gen domain key, domains: $domains ..."
openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config \
    <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=$domains")) > domain.csr

echo "### Download acme_tiny script ..."
wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O acme_tiny.py

echo "### Gen chained cert ..."
python acme_tiny.py --account-key account.key --csr domain.csr --acme-dir $dir/challenges/ > signed.crt || exit
openssl dhparam -out dhparams.pem 2048
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem
cat signed.crt intermediate.pem > chained.pem

echo "### End ssl ..."
```

其中，`SSL_DOMAINS` 为环境变量文件 `docker.env` 中配置需要支持 HTTPS 的域名。

* 容器启动脚本

在该容器启动后，会执行 `build.sh` 脚本。其内容如下：

```bash
#!/bin/bash

dir="/var/www/ssl"
mkdir -p "$dir/challenges"

# 是否启用HTTPS
if [ "$ENABLE_SSL" = "false" ]; then

    # 修改nginx配置, 不启用HTTPS
    sed -i '/https/d' /etc/nginx/nginx.conf
else

    # 每2个月更新一次, 并重启nginx容器
    ssl_cron="0 0 1 */2 * $dir/refresh_cert.sh && nginx -s reload 2>> /var/log/acme_tiny.log"
    crontab -l | { cat; echo "$ssl_cron"; } | crontab -
fi

# 前台启动
nginx -g "daemon off;"
```

其中需要注意，当不启用 HTTPS 协议时，需要将 Nginx 配置修改为不启用 HTTPS；而启用时，会添加每 2 个月重新生成证书的定时任务。`nginx` 也需要改为前台启动模式，否则容器会因没有前台程序而自动退出。

## 部署

前面的一切都准备就绪后，部署就异常简单了，后续再迁移时，也只需要简单做部署这一步就好了。

* 配置环境变量

```bash
cp docker.example.env docker.env
```

* 获取HTTPS证书

```bash
/bin/bash dockerfiles/nginx/ssl/init_ssl.sh
```

> 注意：如果无需支持HTTPS协议，则跳过此步骤，并将环境变量 `ENABLE_SSL` 修改为 `false`。

* 启动所有容器

```bash
docker-compose up --force-recreate --build -d
```

如果一切顺利，那么运行 `docker ps -a` 命令就能看到已成功启动的容器，如下：

```bash
docker ps -a
CONTAINER ID   IMAGE         COMMAND                  CREATED      STATUS      PORTS                    NAMES
b0307bac08d7   blog_nodejs   "sh /build.sh"           2 days ago   Up 2 days   0.0.0.0:4000->4000/tcp   nodejs
e8ef7a1e9271   blog_nginx    "/docker-entrypoint.…"   2 days ago   Up 2 days   0.0.0.0:80->80/tcp       nginx
af7baad788c5   blog_php      "docker-php-entrypoi…"   2 days ago   Up 2 days   9000/tcp                 php
```

通过 [www.fanhaobai.com](https://www.fanhaobai.com) 域名也可以直接访问到本站了。

> 使用 [webhook-cli](https://github.com/sigoden/webhook) 工具可以支持代码自动部署，详细见 [我的博客发布上线方案 — Hexo](https://www.fanhaobai.com/2018/03/hexo-deploy.html)。