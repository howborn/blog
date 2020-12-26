---
title: CentOS6.5安装NodeJS
date: 2016-12-10 17:02:30
tags:
- NodeJS
categories:
- 服务器
- NodeJS
---

由于 NodeJS 需要 gcc4.8+ 版本支持，如果是 CentOS6.5 的系统需要先升级系统 gcc 版本，[升级见这里](https://www.fanhaobai.com/2016/12/upgrade-gcc.html) 。

![](//img2.fanhaobai.com/2016/12/nodejs-install/qd54z6dfa56nAROmP2QyPOhb.jpg)<!--more-->

# 编译前准备

从 [NodeJS官网](https://nodejs.org/en/download) 下载最新的 NodeJS 版本，并解压缩：

```Shell
$ cd /usr/src/
$ wget https://nodejs.org/dist/v6.9.1/node-v6.9.1.tar.gz
$ tar zxvf ./node-v6.9.1.tar.gz
```

# 编译源码

新建一个 NodeJS 安装目录，例如`/usr/local/node`，编译时指定安装路径:

```Shell
$ cd ./node-v6.9.1
$ mkdir /usr/local/node
$ ./configure --prefix=/usr/local/node
```

# 编译安装

编译并安装：

```Shell
$ make && make install
```

# 配置环境变量

NodeJS 安装成功后，需要配置系统的环境变量。

```Shell
$ vim /etc/profile
```

在`export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTCONTROL`的上面增加如下内容，注意不要在 “**=**” 前后添加空格：

```Shell
#set for nodejs
$ export NODE_HOME=/usr/local/node
$ export PATH=$NODE_HOME/bin:$PATH
```

保存并退出，编译 profile 使之生效：

```Shell
$ source /etc/profile
```

查看 NodeJS 版本号，检查是否安装成功：

```Shell
$ node –v
```
