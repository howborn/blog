---
title: 本站特性
date: 2016-12-11 13:12:10
---

本站启用了更加安全的 HTTPS 协议，以 Nginx 作为主站的 Web Server。本站的 [博客](https://www.fanhaobai.com) 基于开源的 Hexo 搭建，运行于 NodeJS 环境，本站的 [维基](https://wiki.fanhaobai.com) 运行于 PHP 环境，数据库采用开源的 MySQL，内存缓存服务器采用 Redis 。

# 更新说明

* 2020.12.30：支持 [Docker](https://www.fanhaobai.com/2020/12/hexo-to-docker.html) 自动部署。
* 2018.07.26：图片支持 [img0](//www.fanhaobai.com) 和 [img1](//www.fanhaobai.com) 多域名。
* 2018.07.04：科学使用 [Disqus](https://github.com/fan-haobai/disqus-php-api)。
* 2018.06.22：增加 [二维码服务](https://disqus.fanhaobai.com/qrcode.php?url=https://www.fanhaobai.com)。
* 2018.02.12：兼容迁移 Hexo 之前的文章 [URL](#主站——www-conf)。
* 2017.12.16：搭建 [ELK](https://www.fanhaobai.com/2017/12/elk.html) 集中式日志平台。
* 2017.12.09：Hexo 结合 [Webhook](https://github.com/fan-haobai/webhook) 支持自动发布。
* 2017.09.23：增加使用 [Supervisor](https://www.fanhaobai.com/2017/09/supervisor.html)。
* 2017.09.10：升级 Nginx 并增加 [Lua 模块](https://www.fanhaobai.com/2017/09/lua-in-nginx.html)。
* 2017.09.02：增加使用 [Gearman](https://www.fanhaobai.com/2017/08/gearman.html) 分布式任务系统。
* 2017.08.18：增加使用 RabbitMQ，[见这里](http://mq.fanhaobai.com)。
* 2017.08.12：修改 Nginx [配置](#Nginx配置)。
* 2017.08.11：增加使用 Elasticsearch，[见这里](http://es.fanhaobai.com)。
* 2017.06.17：使用 GoAccess 分析日志，[见这里](https://www.fanhaobai.com/go-access.html)。
* 2017.05.03：启用 Composer [私有镜i像仓库](http://packagist.fanhaobai.com)。
* 2017.04.06：增加 Solr 支持，见 [Solr Admin](http://solr.fanhaobai.com)。
* 2017.03.01：博客迁移到 [Hexo](https://www.fanhaobai.com/2017/03/install-hexo.html)。
* 2017.02.10：将 Nginx 配置增加 [限制恶意IP访问](https://www.fanhaobai.com/2017/02/lock-ip.html)。
* 2017.02.07：增加 Nginx 配置，防止其他 [域名恶意解析](#) 到本服务器。
* 2017.01.20：增加使用 MongoDB，运行于 Docker 环境，[见这里](https://www.fanhaobai.com/2017/01/mongo-docker-install.html)。
* 2017.01.18：增加使用 [Docker](https://www.fanhaobai.com/post/docker-install.html)。
* 2017.01.16：将 Nginx 配置增加 [防盗链](#)。
* 2017.01.14：统一流量入口，Nginx 配置主站域名重定向到 [www.fanhaobai.com](https://www.fanhaobai.com)。
* 2017.01.12：增加使用 [Robots](https://www.fanhaobai.com/2017/01/robots.html)，协议文件 [robots.txt](http://www.fanhaobai.com/robots.txt) ，网站地图文件  [XML格式](http://www.fanhaobai.com/sitemap.xml)。
* 2016.12.13：增加多少评论的用户头像，将 HTTP 代理为 HTTPS， [见这里](https://www.fanhaobai.com/2017/03/install-hexo.html#多说头像HTTPS代理)。
* 2016.12.11：将主站博客迁移到 [FireKylin](https://www.fanhaobai.com/2016/12/firekylin.html)。
* 2016.12.08：增加使用 [HTTPS](https://www.fanhaobai.com/2016/12/firekylin.html)。
* 2016.12.07：增加使用 [NodeJS](https://www.fanhaobai.com/2016/12/nodejs-install.html)。

# 配置信息

## Nginx配置

### 主配置——nginx.conf

```Nginx
user www www;
worker_processes  4;
error_log  /var/log/nginx/error.log;
#worker_rlimit_nofile 655350;

events {
    use epoll;
    worker_connections 2048;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    #日志格式
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" "$request_body"';
    access_log /var/log/nginx/$server_name.access.log main;
    
    index index.html index.php;
    #错误页面
    error_page  404 500 502 503 504 /404.html;
    #关闭错误页面的nginx版本号
    server_tokens off;
    sendfile        on;
    #tcp_nopush      on;
    keepalive_timeout  65;
    client_max_body_size 10m;
    fastcgi_temp_file_write_size 128k;
    fastcgi_intercept_errors on;
    charset utf-8;    
    #开启gzip 
    gzip  on;
    gzip_min_length 1k;
    gzip_buffers 16 64k;
    gzip_http_version 1.1;
    gzip_comp_level 6;
    gzip_types text/plain application/x-javascript text/css application/xml application/json text/javascript application/x-httpd-php image/jpeg image/gif image/png;
    gzip_vary on;
    #https配置,全站同一个证书
    ssl_certificate /var/www/ssl/chained.pem;
    ssl_certificate_key /var/www/ssl/domain.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
    ssl_session_cache shared:SSL:50m;
    ssl_dhparam /var/www/ssl/dhparams.pem;
    ssl_prefer_server_ciphers on;
    resolver                   114.114.114.114 valid=300s;
    resolver_timeout           10s;

    #限流
    limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;

    include        conf.d/*.conf;
    
    #防止恶意解析
}
```

### 共有配置——common

```Nginx
if ($http_user_agent ~ "DNSPod") {
    return 200;
}

#https证书申请使用,不再往下匹配
location ^~ /.well-known/acme-challenge/ {
    alias /var/www/ssl/challenges/;
    try_files $uri = 404;
}

#网站地图地址
location ~ /sitemap|map\.(html|xml)$ {
    expires off;
}

#防止图片盗链,1天的过期时间
location ~ .*\.(jpg|jpeg|gif|png|bmp|swf|fla|flv|mp3|ico|js|css)$ {
    access_log   off;
    expires      1d;

    valid_referers none blocked *.fanhaobai.com server_names ~\.google\. ~\.baidu\.;
    if ($invalid_referer) {
        return  403;
    }
}
```

### 主站——www.conf

```Nginx
server {
    listen 443;
    server_name fanhaobai.com www.fanhaobai.com;
    #https配置
    ssl on;
    root  /var/www/blog/public;

    #fanhaobai.com重定向到www.fanhaobai.com
    if ($host ~ ^fanhaobai.com$) {
        return 301 https://www.fanhaobai.com$request_uri;
    }
    
    #404特殊页面日志排除
    location ~ /404.html {
        if ($request_uri ~* '/(file/upload)|jianshu|hangqing|qinghua|script|lib|pifa|(apple\-touch)|(wp\-login))' {
            access_log           off;
        }
    }

    include conf.d/common;
    include conf.d/rewrite;
}
 
server {
    #https认证使用
    listen 80;
    access_log off;
    server_name fanhaobai.com www.fanhaobai.com;

    include conf.d/common;
    if ($request_uri !~ '(sitemap|map\.html|xml)|(robots\.txt)') {
        #重定向到https
        return    301  https://www.fanhaobai.com$request_uri;
    }
    include conf.d/rewrite;
}
```

### 主站——rewrite

为了兼容迁移 Hexo 之前文章的 URL，增加以下重写规则：

```Nginx
rewrite ^/2017/08/solr-insatll(.*) /2017/08/solr-install$1 permanent;
rewrite ^/2017/11/elk(.*) /2017/12/elk$1 permanent;
rewrite ^/post/upgrade-gcc-4.8(.*) /2016/12/upgrade-gcc$1 permanent;
rewrite ^/post/linux-version(.*) /2016/07/linux-version$1 permanent;
rewrite ^/post/nodejs-install(.*) /2016/12/nodejs-install$1 permanent;
rewrite ^/post/docker-install(.*) /2017/01/docker-install$1 permanent;
rewrite ^/post/firekylin(.*) /2016/12/firekylin$1 permanent;
rewrite ^/post/mongo-docker-install(.*) /2017/01/mongo-docker-install$1 permanent;
rewrite ^/post/iptables(.*) /2017/02/iptables$1 permanent;
rewrite ^/post/ajax-cookie(.*) /2016/12/ajax-cookie$1 permanent;
rewrite ^/post/recover-file(.*) /2016/05/recover-file$1 permanent;
rewrite ^/post/redis-install(.*) /2016/08/redis-install$1 permanent;
rewrite ^/post/robots(.*) /2017/01/robots$1 permanent;
rewrite ^/post/update-sitemap(.*) /2017/01/update-sitemap$1 permanent;
rewrite ^/post/ssh-safely-use(.*) /2016/08/ssh-safely-use$1 permanent;
rewrite ^/post/nginx-error-log(.*) /2017/01/nginx-error-log$1 permanent;
rewrite ^/post/win10-vm-network(.*) /2016/02/win10-vm-network$1 permanent;
rewrite ^/post/lock-ip(.*) /2017/02/lock-ip$1 permanent;
rewrite ^/post/reward(.*) /2017/02/reward$1 permanent;
rewrite ^/post/letsencrypt(.*) /2016/12/lets-encrypt$1 permanent;
rewrite ^/post/linux-tool-website(.*) /2017/02/linux-tool-website$1 permanent;
rewrite ^/rss /atom.xml last;
rewrite ^/map /sitemap.xml last;
```

### 防止域名恶意解析

```Nginx
server {
    listen 80 default_server;
    server_name _;
    #引流到www.fanhaobai.com
    return 302  https://www.fanhaobai.com;
}
```

## 限制恶意IP访问

为了保证站点安全可靠，本站开启了恶意 IP 的访问限制，[详情见这里](https://www.fanhaobai.com/2017/02/lock-ip.html)。

# 站点SEO

## Robots文件

```Shell
User-agent: *
Disallow: /404.html
Disallow: /categories
Sitemap: http://www.fanhaobai.com/map.xml
```

## 站点地图

本站站点地图文件 [XML格式](http://www.fanhaobai.com/sitemap.xml)，并部署为自动更新。

**SEO专题文章 [»](#)**

* [如何向搜索引擎提交链接](https://www.fanhaobai.com/2017/01/push-links.html)<span>（2017-01-17）</span>
* [自动更新站点地图的部署](https://www.fanhaobai.com/2017/01/update-sitemap.html)<span>（2017-01-16）</span>
* [Robots协议的那些事](https://www.fanhaobai.com/2017/01/robots.html)<span>（2017-01-12）</span>
