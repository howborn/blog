---
title: 查看Linux系统版本
date: 2016-07-08 08:23:00
tags:
- Linux
categories:
- Linux
---

在安装环境或者软件时，我们常常需要知道所在操作系统的版本信息，这里简单记录查看 Linux 系统版本信息的几种方法。<!--more-->

# 内核版本

1） **uname命令**

uname 参数如下：

```Shell
-a, --all		      # 以如下次序输出所有信息
-s, --kernel-name	      # 输出内核名称
-n, --nodename		      # 输出网络节点上的主机名
-r, --kernel-release	      # 输出内核发行号
-v, --kernel-version	      # 输出内核版本
-m, --machine		      # 输出主机的硬件架构名称
-p, --processor		      # 输出处理器类型
-i, --hardware-platform	      # 输出硬件平台
-o, --operating-system	      # 输出操作系统名称
    --help		      # 显示此帮助信息并退出
    --version		      # 显示版本信息并退出
```

故可以使用`uname -a`命令查看内核信息。

```Shell
$ uname -a
Linux fhb-6.6 2.6.32-642.13.1.el6.i686 #1 SMP i686 i686 i386 GNU/Linux
```

2） **/proc/version文件**

直接查看`/proc/version`文件，获取系统版本信息。

```Shell
$ cat /proc/version 
Linux version 2.6.32-642.13.1.el6.i686 (mockbuild@c1bm.rdu2.centos.org) (gcc version 4.4.7 20120313 (Red Hat 4.4.7-17) (GCC) ) #1 SMP
```

# 发行版本

1） **lsb_release命令**

查看发行版本信息如下：

```Shell
$ lsb_release -a
LSB Version:	:base-4.0-ia32:base-4.0-noarch:core-4.0-ia32:core-4.0-noarch:graphics-4.0-ia32:graphics-4.0-noarch:printing-4.0-ia32:printing-4.0-noarch
Distributor ID:	CentOS
Description:	CentOS release 6.8 (Final)
Release:	6.8
Codename:	Final
```

该命令适用于所有的 Linux 发行版本，包括 Redhat、SuSE、Debian 等发行版本。

2） **/etc/issue文件**

直接查看`/etc/issue`文件，获取发行版本信息。

```Shell
$ cat /etc/issue
CentOS release 6.8 (Final)
Kernel \r on an \m
```

3） **/etc/redhat-release文件**

直接查看`/etc/redhat-release`文件，获取发行版本信息。

```Shell
$ cat /etc/redhat-release
CentOS release 6.8 (Final)
```
