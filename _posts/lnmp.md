---
title: 安装LNMP开发环境
date: 2016-05-24 22:55:50
tags:
- 工具
categories:
- 工具
---

本文主要介绍 LNMP 开发环境的安装，同时列出了 PhpStorm 的安装过程。源码包统一放置于`/usr/src`，软件统一安装于`/usr/local`。
![预览图](https://img.fanhaobai.com/2016/05/lnmp/5e41724-379c-4729-9c7a-30bd469e520b.jpg)<!--more-->

## CentOS安装 ##

### 安装 ###

前往 CentOS 的 [官方地址](http://mirror.bit.edu.cn/centos/6/isos/x86_64/) 下载  CentOS 6.9 Min 版本镜像文件。

新建虚拟机并安装，但是注意在 **新建虚拟机向导** 设置里，要选择 **稍后安装操作系统**，并在完成虚拟机安装向导后，通过 **编辑虚拟机设置** 指定系统镜像（CD/DVD项）的地址。

安装完成 Min 版后，默认未开启网卡，采用如下方法开启网卡。

```Bash
$ vi /etc/sysconfig/network-scripts/ifcfg-eth0
```
配置信息如下：
```Bash
DEVICE=eth0
HWADDR=00:0C:29:7A:CF:56
TYPE=Ethernet
UUID=216048ec-c974-427e-8b57-5a4c9fe6733e
# 是否开机自启，将no更改为yes
ONBOOT=no
NM_CONTROLLED=yes
BOOTPROTO=dhcp
```
配置后重启重启即可，否则无法连接到网络。

### 配置 ###

1）安装 epel 解决第三方扩展依赖的问题

```Bash
$ yum install epel-release
```

2）更新系统

```Bash
$ yum -y update
```

3）安装必备工具

```Bash
# 查看流量
$ yum -y install iptraf
# 常用工具
$ yum -y install wget curl lrzsz vim unzip zip
# GCC
$ yum -y install gcc gcc-c++
# cmake
$ yum -y install cmake
```

4）同步时钟

```Bash
$ yum -y install ntpdate ntp
$ ntpdate time.windows.com && hwclock -w
```
将以下内容写入计划任务：
```Bash
03 01 * * * /usr/sbin/ntpdate -u time.windows.com  >/var/log/ntpdate.log &
```

5）修改DNS设置

```Bash
$ vim /etc/resolv.conf
# 增加主DNS
nameserver 8.8.8.8
# 增加次DNS
nameserver 8.8.4.4
```

6）修改语言

查看系统语言：
```Bash
# 如果是zh_CN则为中文，是en_US则为英文
$ echo $LANG
# 查看系统语言包
$ locale
# 下载中文语言包
$ yum -y groupinstall chinese-support
```
通过编辑`/etc/sysconfig/i18n`配置文件修改。

7）桌面

为了方便后续开发，在这里安装了 GNOME 桌面。

```Bash
$ yum groupinstall "X Window System"  "Desktop" "Desktop Platform" "Fonts" "Chinese Support [zh]"
# 修改默认启动模式
$ vim /etc/inittab
id:5:initdefault:
```

## PHP ##

### 下载并解压源码 ###

从 [PHP 官方地址](http://php.net/downloads.php)下载源码包。

```Bash
$ cd /usr/src
$ wget http://219.238.7.71/files/1007000009B9E9D0/cn2.php.net/distributions/php-5.6.30.tar.gz
$ tar zxvf php-5.6.30.tar.gz
$ cd php-5.6.30
```

### 安装依赖 ###

可以通过`./configure`脚本检查依赖安装情况。

```Bash
$ yum -y install gd-devel pcre-devel libxml2-devel libjpeg-devel libpng-devel libevent-devel libtool* autoconf* freetype* libstd* gcc44* ncurse* bison* openssl* libcurl* libcurl* libmcrypt*
```

使用 yum 安装 libmcrypt 时可能会找不到安装源，这里提供了 libmcrypt 的源码安装方式。

```Bash
$ wget ftp://mcrypt.hellug.gr/pub/crypto/mcrypt/libmcrypt/libmcrypt-2.5.7.tar.gz
$ tar zxf libmcrypt-2.5.7.tar.gz
$ cd libmcrypt-2.5.7
$ ./configure
$ make && make install
```

###  编译安装 ###

```Bash
./configure --prefix=/usr/local/php \
--with-mysql=mysqlnd \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-iconv-dir \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir \
--enable-xml \
--disable-rpath \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-sysvshm \
--enable-sysvmsg \
--enable-inline-optimization \
--with-curl \
--with-mcrypt \
--enable-mbregex \
--enable-fpm \
--enable-mbstring \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \
--enable-soap \
--enable-ftp \
--without-pear \
--enable-opcache

$ make && make install
```

如果在编译过程中出现如下错误：

```Bash
configure:error:Don't know how to define struct flock on this system,set-enable-opcache=no
```
采用如下办法解决：

```Bash
$ vim /etc/ld.so.conf.d/local.conf
# 文件追加如下内容
/usr/local/lib
# 运行后重新编译PHP即可
$ ldconfig
```

### 配置 ###

1）php.ini

复制并修改`php.ini`配置文件。

```Bash
$ cp ./php.ini-development /usr/local/php/lib/php.ini
```

**开发环境** 建议配置修改为如下：

```Bash
short_open_tag = On
output_buffering = 4096
max_execution_time = 60
# 错误显示和级别
error_reporting = E_ALL
display_errors = On
display_startup_errors = On
log_errors = On
# 把PHP报错记录到syslog中或指定的文件中（注意目录权限）
error_log = syslog
# 设置默认时区
date.timezone = PRC
```

2） php-fpm.conf

复制并修改`php-fpm.conf`配置文件。

```Bash
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
```

建议配置修改为如下：

```Bash
[global]
# 重要，一定要记录notice, 及时发现异常情况
log_level = notice
# 重要，每个子进程能打开的文件描述符数量上限（系统默认是1024），一定要尽量提高
rlimit_files = 60000
[www]
# 重要，设置fpm运行状态查看地址
pm.status_path = /status
# fpm存活状态检测地址
ping.path = /ping
# 用于检测fpm进程是否运行正常
ping.response = pong
# 子进程处理指定的请求数
pm.max_requests = 5000
# 定义慢速日志文件位置
slowlog = var/log/slow.log
# 慢请求时间上下限，超过此值就记录到日志文件中
request_slowlog_timeout = 1s
# 单个脚本运行超时时间，fpm模式下，php.ini中的max_execution_time配置无效，必须指定
request_terminate_timeout = 30s
# 捕获php程序的报错，并发送给客户端(nginx), 如果不配置这项，通过nginx访问时php报错，无法在nginx响应中看到错误内容，只会产生50X错误
catch_workers_output = yes
```

### 系统服务 ###

```Bash
$ cp /usr/src/php-5.6.30/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
$ chmod a+x  /etc/init.d/php-fpm
# 添加到init.d服务中
$ chkconfig --add php-fpm
# 设置服务自动运行
$ chkconfig php-fpm on
```

### 启动 ###

```Bash
$ ln -s /usr/local/php/bin/php /usr/bin/php
$ ln -s /usr/local/php/sbin/php-fpm /usr/bin/php-pfm
# 配置语法检测
$ php-pfm -t
$ service php-fpm start
```

## MySQL ##

### 用户 ###

```Bash
# mysql运行用户
$ groupadd mysql
$ useradd mysql -g mysql -M
$ mkdir -p /usr/local/mysql
$ mkdir -p /usr/local/mysql/data
$ chown -R mysql:mysql /usr/local/mysql
$ vi /etc/profile
# profile追加如下内容
PATH=/usr/local/mysql/bin:/usr/local/mysql/lib:$PATH
export PATH
$ source /etc/profile
```

### 下载并解压源码 ###

从 MySQL 官网下载源码包，解压。

```Bash
$ tar zxvf mysql-5.6.33.tar.gz
$ cd mysql-5.6.33
```

### 安装依赖 ###

```Bash
$ yum -y install ncurses-devel perl ncurses-devel bison-devel
```

### 编译安装 ###

```Bash
cmake \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_USER=mysql \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_ARCHIVE_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=/usr/local/boost \
$ make && make install
```

### 配置 ###

执行初始化：

```Bash
$ cd /usr/local/mysql
$ ./scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
```

修改配置文件：

```Bash
[mysqld]
datadir=/usr/local/mysql/data
socket=/tmp/mysql.sock
character_set_server=utf8
init_connect='SET NAMES utf8'
# 限制为本地访问
bind=127.0.0.1
... ...
[client]
default-character-set=utf8
```

### 系统服务 ###

```Bash
$ cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
$ chkconfig mysqld on
```

### 启动 ###

```Bash
$ service mysqld start
```

### 权限 ###

```Bash
$ mysql -u root
mysql> SET PASSWORD = PASSWORD('**********');
mysql> GRANT ALL PRIVILEGES ON *.* TO root@"127.0.0.1"  WITH GRANT OPTION;
mysql> FLUSH PRIVILEGES;
```

## Nginx ##

### 准备 ###

```Bash
# 用户
$ groupadd www
$ useradd -g www www -s /bin/false -M
# 依赖
$ yum -y install pcre* opensll*
```

### 下载并解压 ###

从 [官网](http://nginx.org/download/nginx-1.7.8.tar.gz) 下载源码包，并解压。

```Bash
$ wget http://nginx.org/download/nginx-1.7.8.tar.gz
$ tar zxvf nginx-1.7.8.tar.gz
$ cd nginx-1.7.8
```

### 编译安装 ###

```Bash
$ ./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module --with-http_spdy_module --with-http_stub_status_module --with-pcre

$ make && make install
```

### 配置 ###

`nginx.conf`文件配置：

```Nginx
user www www;
worker_processes  4;
error_log  logs/error.log  notice;
... ...
http {
  ... ...
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"'
  ... ...
  server {
	listen 80 default;
	server_name _;
	return 403;
  }
  # 各站配置文件
  include     vhost/*.conf;
  ... ...
}
```

各站配置文件：

```Nginx
server {
  listen       80;
  server_name  localhost;
  access_log  logs/host.access.log  main;
  location / {
    root   /home/www;
    index  index.html index.htm;
  }
  error_page   500 502 503 504  /50x.html;
  location = /50x.html {
    root   html;
  }
}
```

### 系统服务 ###

```Bash
$ vi /etc/rc.d/init.d/nginx

# 追加入如下内容
#!/bin/bash
# chkconfig: - 85 15
# description: Nginx is a World Wide Web server.
# processname: nginx
nginx=/usr/local/nginx/sbin/nginx
conf=/usr/local/nginx/conf/nginx.conf
case $1 in
    start)
        echo -n "Starting Nginx"
        $nginx -c $conf
        echo " done"
    ;;
    stop)
        echo -n "Stopping Nginx"
        killall -9 nginx
        echo " done"
    ;;
    test)
        $nginx -t -c $conf
    ;;
    reload)
        echo -n "Reloading Nginx"
        ps auxww | grep nginx | grep master | awk '{print $2}' | xargs kill -HUP
        echo " done"
    ;;
    restart)
        echo -n "Restart Nginx"
        $0 stop
        sleep 1
        $0 start
        echo " done"
    ;;
    show)
        ps -aux|grep nginx
    ;;
    *)
        echo -n "Usage: $0 {start|restart|reload|stop|test|show}"
    ;;
esac
# 保存并退出

$ cd /etc/init.d
$ chmod +x nginx
$ chkconfig --add nginx
$ chkconfig --level 2345 nginx on
$ chkconfig nginx on
```

### 启动 ###

```Bash
# 检测配置
$ service nginx test
$ service nginx start
```

## Phpstorm ##

### 依赖 ###

Phpstorm 运行环境依赖 JAVA，这里使用 yum 安装 JAVA 环境。

```Bash
$ yum -y install java
```

### 下载并解压 ###

从 [phpstorm 官网](https://download.jetbrains.8686c.com/webide/PhpStorm-2017.1.1.tar.gz) 下载最新安装包—— Linux版。

```Bash
$ tar zxvf PhpStorm-10.0.4.tar.gz
$ mv ./PhpStorm-10.0.4 /usr/local/phpstorm
```

### 安装 ###

注意：以下安装操作是从虚拟机终端操作，且确定虚拟机是运行于图形界面模式（init 5），而不是通过 Xshell 端操作。

在虚拟机终端：

```Bash
$ cd /usr/local/phpstorm/bin
$ ./phpstorm.sh
```

随后系统会弹出 phpstorm 的安装界面，正常安装即可。

### 注册 ###

通过 [IDEA注册码](http://idea.qinxi1992.cn/) 即可获取正版注册码。

## 本地代码实时同步开发环境

我是在 Win 下使用 PhpStrom 开发代码，而开发环境为 VM 下的 LNMP。所以怎样实时同步本地代码到开发环境，以便开发和调试呢？采用 VM 提供的 **文件共享** 即可很好的解决这个问题。

关闭虚拟机后，在路径为 **编辑虚拟机设置** >>**选项**>>**共享文件夹** 的面板上配置需共享文件夹路径，即本地代码文件夹，并选中 **总是启用** 选项，启动虚拟机即可。

共享文件夹默认挂载路径为`/mnt/hgfs`，如下：

```Bash
$ cd /mnt/hgfs
$ ls
# 我的本地代码文件夹
Code
```

### 问题

如果配置共享文件夹路径后，默认挂载路径没有共享文件夹，可以试试下面的解决办法：

```Bash
$ cd /usr/src
$ git clone https://github.com/rasa/vmware-tools-patches.git
$ cd vmware-tools-patches
$ ./patched-open-vm-tools.sh
```

**更新 [»]()**

* [已使用 Docker 来部署开发环境](https://hub.docker.com/r/fanhaobai/lnmp/)（2017-08-26）
