---
title: Linux强制踢出其他登录用户
date: 2016-11-16 08:00:00
tags:
- Linux
categories:
- Linux
---

在某些情况下，需要强制 **踢出** 系统 **其他登录用户**，比如非法用户登录。这里记录以 root 用户强制踢出其他登录用户的过程。<!--more-->

下述操作都是以 root 用户执行。

首先，查看当前用户。

```Bash
$ whoami 
root
```

接着，使用`w`命令查看当前所有登录用户。

```Bash
$ w
USER     TTY      FROM              LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/3    103.233.131.130  09:59    0.00s  0.14s  0.03s sshd: root[priv]
www      pts/4    103.233.131.130  16:23   37:47   0.00s  0.00s -bash
```

这里需要强制踢出 www 用户，先通过上面的 **TTY** 号查看 www 用户的所有进程，注意对`/`符号使用`\`进行转义。

```Bash
$ ps -ef | grep 'pts'
www       7854  7852  0 16:23 ?        00:00:00 sshd: www@pts/4  
www       7855  7854  0 16:23 pts/4    00:00:00 -bash
```

通过进程 PID 杀死 www 用户对应的进程（可以直接杀死 bash 进程），如下：

```Bash
$ kill -9 7855
```

再次查看系统登录用户。

```Bash
$ w
USER     TTY      FROM              LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/3    103.233.131.130  09:59    0.00s  0.14s  0.03s sshd: root[priv]
```

同时可看见 www 用户客户端（Xshell）也已断开连接了。

