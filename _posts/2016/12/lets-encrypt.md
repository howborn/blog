---
title: 启用Let's Encrypt免费的HTTPS证书
date: 2016-12-08 23:52:39
tags:
- TCP/IP
categories:
- 协议
---

> 原文：https://github.com/diafygi/acme-tiny  

为了跟随 HTTPS 浪潮，憧憬了很长时间，终于到现在本站也正式启用了 HTTPS，本文详细记录了本站申请证书的过程及途中所遇到一些的问题。

[Let's Encrypt](https://letsencrypt.org/) 是由互联网安全研究小组（ISRG，一个公益组织）提供的 [数字证书认证](https://zh.wikipedia.org/wiki/%E6%95%B0%E5%AD%97%E8%AF%81%E4%B9%A6%E8%AE%A4%E8%AF%81%E6%9C%BA%E6%9E%84)  服务。主要赞助商包括电子前哨基金会，Mozilla 基金会，Akamai 以及思科。
![](https://img1.fanhaobai.com/2016/12/lets-encrypt/oXIK5oghKOlCTOKMUK5lHtve.png)<!--more-->

Let's Encrypt 目的就是向网站自动签发和管理免费证书，以便加速互联网由 HTTP 过渡到 HTTPS。因此 Let's Encrypt 证书不但免费，申请过程还非常简单，鼓励实现自动化部署。Let's Encrypt 作为安全考虑，每次所申请的证书只有 90 天的有效期，因此自动化部署显得尤为重要。

本站没有使用 Let's Encrypt 官方提供的工具来申请证书，而是采用了 [acme-tiny](https://github.com/diafygi/acme-tiny)  这个小巧易用的开源工具来实现证书申请和安装。

# 创建账号

首先需要创建一个用于存放证书申请过程中的临时文件以及证书文件，例如 ssl ，无特别说明，后续操作都是在该目录下进行。进入该目录，创建一个 [RSA](https://www.google.com.hk/?gfe_rd=cr&ei=F9dLWOj9H4fFoAOgx6KgAg&gws_rd=ssl#safe=strict&q=RSA+%E7%A7%81%E9%92%A5)  私钥用于 Let's Encrypt 标识你的身份。

```Shell
$ openssl genrsa 4096 > account.key
```

# 创建CSR文件

由于 Let's Encrypt 使用的 ACME 协议需要 CSR（Certificate Signing Request，证书签名请求）文件。但在生成 CSR 文件之前需要创建域名私钥（**这个域名私钥一定不能是第一步创建的账户私钥**），下面先创建域名私钥：

```Shell
$ openssl genrsa 4096 > domain.key
```

创建完域名私钥，就可以生成 CSR 文件了，分为两种情况：  

1） 单域名

```Shell
$ openssl req -new -sha256 -key domain.key -subj "/CN=yoursite.com" > domain.csr
```

2） 多域名  

```Shell
$ openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:yoursite.com,DNS:www.yoursite.com,DNS:subdomain.yoursite.com")) > domain.csr
```

在 CSR 中推荐把不带 www 和带 www 的域名都加进去，其他子域名根据需要进行添加即可。如果提示`/etc/ssl/openssl.cnf`文件无法找到，可以使用命令`find / -name openssl.cnf`
找到`openssl.cnf`的路径，需要将上述`/etc/ssl/openssl.cnf`更改为该路径。

# 配置验证服务

Let's Encrypt 会在签发证书时在你的服务器上生成一个随机验证文件，后续的域名所有权验证就是通过这个随机验证文件完成。

首先，需要创建一个用于存放验证文件的目录，且该目录建议一直保留于服务器上，例如：

```Shell
$ mkdir /data/challenges/
```

再配置一个 HTTP 服务，例如 Nginx：

```Nginx
server {
  server_name www.yoursite.com yoursite.com subdomian.yoursite.com;
  location ^~ /.well-known/acme-challenge/ {
    #存放验证文件的目录，需自行更改为对应目录
    alias /data/challenges/;                
    try_files $uri =404;
  }
  location / {
    rewrite ^/(.*)$ https://yoursite.com/$1 permanent;
  }
}
```

该配置会优先查找`/data/challenges/`目录下的文件，否则会重定向到 HTTPS 地址，后续站点服务器配置信息中需要保留这些配置信息。

# 签发证书

首先，获取 acme-tiny 脚本并保存于之前的 ssl 目录下：

```Shell
$ wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py
```

然后，指定账户私钥、CSR 以及验证目录（需自行更改为对应目录），执行 acme-tiny 脚本：

```Shell
$ python acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir /data/challenges/ > ./signed.crt
```

如果一切顺利，那么会在当前目录下生成一个`signed.crt`文件，这个就是 Let's Encrypt 签发的证书文件，需要好好保管呦 （^_^）。

但凡事总有不顺，如果出现如下类似错：

```Shell
ValueError: Wrote file to /data/challenges/oJbvpIhkwkBGBAQUklWJXyC8VbWAdQqlgpwUJkgC1Vg, but couldn't download http://yoursite.com/.well-known/acme-challenge/oJbvpIhkwkBGBAQUklWJXyC8VbWAdQqlgpwUJkgC1Vg
```

可能原因有两种：   

1）你没有添加不带www的域名解析  

先`ping`下不带 www 的域名，如果不能`ping`通，则添加主机记录为`@`的域名解析即可。   

2）你的域名在国外无法解析  

如果存在域名国外无法解析问题，可以暂时使用外国的 DNS 解析服务商来解决，例如 [dns.he.net](https://dns.he.net/) 。 

# 安装证书

拿到从 Let's Encrypt 签发的证书后，还需要下载 Let's Encrypt 的中间证书。配置 HTTPS 证书时既不能漏掉中间证书，也不能直接包含根证书，则需要把中间证书和网站证书进行合并：

```Shell
$ openssl dhparam -out dhparams.pem 2048
$ wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem
$ cat signed.crt intermediate.pem > chained.pem
```

最后，在 Nginx 配置中加入证书配置项：

```Nginx
server {
  listen 443;
  server_name yoursite.com, www.yoursite.com;

  ssl on;
  ssl_certificate /data/ssl/chained.pem;          #根据你的路径更改
  ssl_certificate_key /data/ssl/domain.key;       #根据你的路径更改
  ssl_session_timeout 5m;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
  ssl_session_cache shared:SSL:50m;
  ssl_dhparam /data/ssl/dhparams.pem;            #根据你的路径更改
  ssl_prefer_server_ciphers on;

  ...the rest of your config
}
```

# 配置自动更新

由于 Let's Encrypt  签发的证书只有 90 天有效期，所以证书需要定期的进行更新，推荐使用自动化脚本定期更新。   
首先，在 ssl 目录下创建自动更新脚本`renew_cert.sh`，并赋予执行权限：

```Shell
$ touch ./renew_cert.sh
$ chmod a+x ./renew_cert.sh
```

然后，往`renew_cert.sh`添加如下内容（`/data/challenges/`路径，请对应自行更改）：

```Shell
$ python /data/ssl/acme_tiny.py --account-key /data/ssl/account.key --csr /data/ssl/domain.csr --acme-dir /data/challenges/ > /data/ssl/signed.crt || exit
$ wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > /data/ssl/intermediate.pem
$ cat /data/ssl/signed.crt /data/ssl/intermediate.pem > /data/ssl/chained.pem
$ nginx -s reload
```

最后，`crontab -e`增加定时任务：

```Shell
0 0 1 * * /data/ssl/renew_cert.sh 2>> /data/ssl/acme_tiny.log
```

就这样完成了 Let's Encrypt 证书的自动化部署，证书每个月自动更新，无需你的干预。
