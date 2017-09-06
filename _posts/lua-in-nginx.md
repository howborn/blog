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

Nginx 的 [Lua 模块](https://www.nginx.com/resources/wiki/modules/lua/)

## 安装Lua模块

```Bash
$ yum install readline-devel pcre-devel openssl-devel gcc
$ ldconfig
```

安装 [LuaJIT](http://luajit.org/index.html) 环境：

```Bash
$ wget http://luajit.org/download/LuaJIT-2.0.5.tar.gz
$ tar zxvf LuaJIT-2.0.5.tar.gz
$ cd LuaJIT-2.0.5
$ make install
# 安装成功
==== Successfully installed LuaJIT 2.0.5 to /usr/local ====
```

设置 LuaJIT 的 lib、include 环境变量：

```Bash
$ export LUAJIT_LIB=/usr/local/lib
$ export LUAJIT_INC=/usr/local/include/luajit-2.0
```

下载 [ngx_devel_kit](https://github.com/simpl/ngx_devel_kit/tags)：

```Bash
$ wget https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
$ tar zxvf v0.3.0.tar.gz
# 解压缩后为ngx_devel_kit-0.3.0
```

下载 [lua-nginx-module](https://github.com/openresty/lua-nginx-module)：

```Bash
$ wget https://github.com/openresty/lua-nginx-module/archive/v0.10.10.tar.gz
$ tar zxvf v0.10.10.tar.gz
# 解压缩后为lua-nginx-module-0.10.10
```

下载 Nginx 源码解压，编译安装：

```Bash
$ wget http://nginx.org/download/nginx-1.7.8.tar.gz
$ tar zxvf nginx-1.7.8.tar.gz
$ cd nginx-1.7.8
$ ./configure --add-module=/usr/src/lua-nginx-module-0.10.10 --add-module=/usr/src/ngx_devel_kit-0.3.0
$ make
$ make install
```

安装完成后，查看版本：

```Bash
$ nginx -v
# 可能会出现如下错误
nginx: error while loading shared libraries: libluajit-5.1.so.2: cannot open shared object file: No such file or directory
```

上述错误，可使用 ldconfig 命令解决：

```Bash
$ echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
$ ldconfig
```
