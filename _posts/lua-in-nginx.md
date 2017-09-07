---
title: Nginx粘合Lua
date: 2017-09-07 00:25:59
tags:
- Nginx
- Lua
categories:
- 语言
- Lua
---

其实 [OpenResty](http://openresty.org/en/) 和 [Tengine](http://tengine.taobao.org/) 都实现了 将 Lua 嵌入 Nginx。但由于 OpenResty 集成了大量精良的 Lua 库、第三方模块以及大多数的依赖项，可以方便地搭建能够处理超高并发、扩展性极高的动态 Web 应用、Web 服务和动态网关，所以这里选择 OpenResty 提供的 [lua-nginx-module](https://github.com/openresty/lua-nginx-module)  方案。

![](jttps://www.fanhaobai.com/2017/09/lua-in-nginx/63113174-45d7-4a27-8472-d037675c2cbd.jpg)<!--more-->

## 安装Lua模块

lua-nginx-module 依赖于 LuaJIT 和 ngx_devel_kit，LuaJIT 需要安装，ngx_devel_kit 只需下载源码包，在 Nginx 编译时指定 ngx_devel_kit 目录。

### 系统依赖库

首先确保系统已安装如下依赖库。

```Bash
$ yum install readline-devel pcre-devel openssl-devel gcc
```

### 安装LuaJIT

首先，安装 [LuaJIT](http://luajit.org/index.html) 环境，如下所示：

```Bash
$ wget http://luajit.org/download/LuaJIT-2.0.5.tar.gz
$ tar zxvf LuaJIT-2.0.5.tar.gz
$ cd LuaJIT-2.0.5
$ make install
# 安装成功
==== Successfully installed LuaJIT 2.0.5 to /usr/local ====
```

设置 LuaJIT 有关的环境变量。

```Bash
$ export LUAJIT_LIB=/usr/local/lib
$ export LUAJIT_INC=/usr/local/include/luajit-2.0
$ echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
$ ldconfig
```

### 下载相关模块

下载 [ngx_devel_kit](https://github.com/simpl/ngx_devel_kit/tags) 源码包，如下：

```Bash
$ wget https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
$ tar zxvf v0.3.0.tar.gz
# 解压缩后目录名
ngx_devel_kit-0.3.0
```

**接下来**，下载 [lua-nginx-module](https://github.com/openresty/lua-nginx-module) 这个重要模块源码包，为 Nginx 编译作准备。

```Bash
$ wget https://github.com/openresty/lua-nginx-module/archive/v0.10.10.tar.gz
$ tar zxvf v0.10.10.tar.gz
# 解压缩后目录名
lua-nginx-module-0.10.10
```

### 加载Lua模块

Nginx 1.9 版本后可以动态加载模块，但这里由于版本太低只能重新编译安装 Nginx。下载 Nginx 源码包并解压：

```Bash
$ wget http://nginx.org/download/nginx-1.13.5.tar.gz
$ tar zxvf nginx-1.13.5.tar.gz
```

编译并重新安装 Nginx：

```Bash
$ cd nginx-1.13.5
# 增加--add-module=/usr/src/lua-nginx-module-0.10.10 --add-module=/usr/src/ngx_devel_kit-0.3.0
$ ./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_v2_module --with-http_stub_status_module --with-pcre --add-module=/usr/src/lua-nginx-module-0.10.10 --add-module=/usr/src/ngx_devel_kit-0.3.0
$ make
$ make install
# 查看是否安装成功
$ nginx -v
```

## 