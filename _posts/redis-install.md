---
title: CentOS源码安装Redis
date: 2016-08-23 00:00:00
tags:
- Redis
categories:
- DB
- Redis
---

在如今互联网日新月异的时代，开发的项目对于应对高并发的要求也越来越高。作为常用的两种内存缓存服务器 Memache 和 Redis，由于 Redis 可持久化和支持多种数据结构的优点，在实际中得到广泛应用。

{% asset_img vz83vwhWqtQckz-ZKarnv_5S.jpg %}<!--more-->

下面我就源码安装 Redis，并记录整个的安装过程。

# 安装前准备

##  下载安装包

从 [Redis官网](http://redis.io/download) 下载最新的稳定版源码包。

```Bash
$ cd /usr/src/
#下载源码包
$ wget http://download.redis.io/releases/redis-3.0.6.tar.gz
```

## 解压

解压缩源码包，得到源码文件。

```Bash
$ tar -zxvf ./redis-3.0.6.tar.gz
$ cd ./redis-3.0.6
```

# 编译安装

## 安装

源码文件中直接存在 Makefile 文件，所以 make 就可以直接安装。

注意：会直接把软件安装到当前目录下的`src`下。

```Bash
$ make
```

## 移动安装位置

我习惯将软件都安装在`/usr/local/`下，所以将 Redis 安装软件移动到`/usr/local/redis`。

```Bash
$ cp -r ./src/* /usr/local/redis
#添加redis服务端软连接
$ ln -s /usr/local/redis/redis-server /usr/bin/redis-server
#添加redis客户端软连接
$ ln -s /usr/local/redis/redis-cli /usr/bin/redis-cli                     
```

# 修改配置

复制默认的配置文件到安装目录下。

```Bash
$ cp ./redis.conf /usr/local/redis/redis.conf
$ vim /usr/local/redis/redis.conf
```

对配置文件，做如下更改：

```Bash
#将守护模式开启
$ daemonize yes
#连接密码
$ requirepass ***                                                      
```

# 启动

## 启动服务端

启动 Redis 服务端，查看安装是否成功。

```Bash
$ redis-server /usr/local/redis/redis.conf
```

查看端口监听情况，`netstat -tupl | 6379`，如下情况表示安装成功：

```Bash
tcp    0    0 *:6379      *:*     LISTEN    28647/redis-server 
```

## 启动客户端

启动客户端，进行简单连接测试。

```Bash
$ redis-cli                                   #连接redis 
```
使用命令`keys * `，查看所有的 key，会显示无权限。需要先进行授权：

```Bash
> auth ***                                    #授权连接  
```

然后设置并查看一个键值对，如下：

```Bash
> set fhb fanhaobai
> get fhb
```

显示 OK，测试正常，安装成功。

## 图形化工具

这里介绍两个 Redis 的图形化管理工具。

* Redis Desktop Manager

{% asset_img bf751f29-f293-49cc-b57d-935edba1d175.png %}

[Redis Desktop Manager](https://redisdesktop.com/) 是一款桌面版 Redis 管理工具。

* phpRedisAdmin

{% asset_img 20339264-ea65-4bf2-b247-f1d085cc66c3.png %}

[phpRedisAdmin](https://github.com/erikdubbelboer/phpRedisAdmin) 是用 PHP 开发的一款 WEB 版 Redis 管理工具，支持权限认证，使用也极为方便。

**更新 [»]()**

* [图形化工具](#图形化工具)<span>（2017-06-24）</span>