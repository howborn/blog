---
title: Linux日常使用技巧集
date: 2018-01-01 22:00:00
tags:
- Linux
categories:
- Linux
---

作为技术人员，Linux 系统可以说是我们使用最多的操作系统，但我们可能并不是很了解它。在这里我将自己日常遇到的 Linux 使用技巧记录下来，方便以后查询使用。

![](https://img.fanhaobai.com/2018/01/linux-skill/2a82ad6b-ab25-409f-858c-22312826ac06.jpg)<!--more-->

## 查看系统版本

在安装环境或者软件时，我们常常需要知道所在操作系统的版本信息，这里列举几种查看内核和发行版本信息的方法，更多见 [查看Linux系统版本](https://www.fanhaobai.com/2016/07/linux-version.html)。

### 内核版本

* uname命令

```Bash
$ uname -a
Linux fhb-6.6 2.6.32-642.13.1.el6.i686
```

* /proc/version文件

```Bash
$ cat /proc/version 
Linux version 2.6.32-642.13.1.el6.i686
```

### 发行版本

* lsb_release命令

```Bash
$ lsb_release -a
LSB Version:	:base-4.0-ia32:base-4.0-noarch:core-4.0-ia32
Distributor ID:	CentOS
Release:	6.8
```

* /etc/issue文件

```Bash
$ cat /etc/redhat-release
CentOS release 6.8 (Final)
```

## Yum更新排除指定软件

有时候我们使用 yum 安装的软件，由于配置向后兼容性等问题，我们并不希望这些软件（filebeat 和 logstash）在使用`update`时，被不经意间被自动更新。这时，可以使用如下方法解决：

* 临时

通过`-x`或`--exclude`参数指定需要排除的包名称，多个包名称使用空格分隔。例如：

```Bash
# --exclude同样
$ yum -x filebeat logstash update
```

* 永久

在 yum 配置文件`/etc/yum.conf`中，追加`exclude`配置项。例如：

```Ini
# 需排序的包名称
exclude=filebeat logstash
```

再次使用`yum update`命令，就不会自动更新指定的软件包了。

```Bash
$ yum update
No Packages marked for Update
```

## 强制踢出其他登录用户

在某些情况下，需要强制踢出系统其他登录用户，比如遇到非法用户登录。查询当前登陆用户：

```Bash
# 当前用户
$ whoami
root
# 当前所有用户
$ ps -ef | grep 'pts'
root      4752  4727  0 00:09 pts/0    00:00:00 su www
www       4755  4752  0 00:09 pts/0    00:00:00 bash
```

剔除非法登陆用户：

```Bash
$ kill -9 4755
```

更多详细说明，见 [Linux强制踢出其他登录用户](https://www.fanhaobai.com/2016/11/out-users.html)。

## Strace调试

在调试程序时，我们会遇到一些系统层面的错误问题，一般都不易发现，这时可以使用 strace 来跟踪系统调用的过程，方便快速定位和解决问题。

```C
$ strace crontab.sh
execve("./crontab.sh", ["./crontab.sh"], [/* 29 vars */]) = 0
brk(0)                                  = 0x106a000
mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f0434160000
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
open("/etc/ld.so.cache", O_RDONLY)      = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=53434, ...}) = 0
mmap(NULL, 53434, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f0434152000
close(3)                                = 0
open("/lib64/libc.so.6", O_RDONLY)      = 3
... ...
```

更多详细说明，见 [错误调试](https://www.fanhaobai.com/2017/07/php-cli-setting.html#错误调试https://www.fanhaobai.com/2016/11/out-users.html)。
