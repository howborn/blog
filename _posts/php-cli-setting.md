---
title: PHP定时脚本的那些事
date: 2017-07-10 18:23:16
tags:
- PHP
categories:
- 语言
- PHP
---

在项目中，经常会遇到定时任务的情景，当然这不仅仅只是将 PHP 文件结合 crontab 这么简单。其中有一些我遇到的非 code 层面的问题，在这里列举出来。

{% asset_img 0f15b5f5-2212-4a0a-9af4-e14811ad9234.png %}<!--more-->

示例脚本使用 YII 框架，内容如下：

```Bash
$ vim ./crontab.sh
#!/usr/bin/env bash
# 状态更新
CURRENT_DIR=`dirname $0`
/usr/local/php/bin/php -c /usr/local/php/etc/php_cli.ini -f $CURRENT_DIR/yii user/check
```

## php.ini设置

通常在 web 和 cli 模式时，php 配置需要不一致。例如，disable_functions 项等，cli  模式配置文件为`php_cli.ini`。

```Bash
; 不限制系统函数
disable_functions =
; 脚本最大执行时间
max_execution_time = 60
; 默认时区
date.timezone = Asia/Chongqing
```

## 脚本执行权限

PHP 语言类型的脚本，使用 crontab 进行调度时，会遇到脚本的执行权限问题，可以采取手动`chmod +x crontab.sh`来临时解决，但是当通过部署工具重新发布代码后，需要再次手动添加脚本的可执行权限，不可控因素较多，所以不可取。

脚本初始权限和 crontab 配置信息：

```Bash
$ ll -a
-rw-r--r--. 1 root root  191 Jul 10 17:34 crontab.sh

$ crontab -l
10 0 * * * /mnt/hgfs/Code/ziroom/crontab/cli/crontab.sh > /home/log/cli.log
```

### Git修改文件权限

Git 支持文件权限的保持，所以可以通过如下命令修改文件权限并提交：

```Bash
# path.sh文件增加可执行权限
$ git update-index --chmod=+x crontab.sh
$ git commit -m "access"
$ git push origin feature
```

重新拉取文件获取可执行权限：

```Bash
$ git pull origin feature
# 查看文件权限
$ ll -a
-rwxr-xr-x. 1 root root  191 Jul 10 18:11 crontab.sh
```

### sh命令

在不增加脚本文件可执行权限的情况，可以直接使用`sh`命令解决。

```Bash
# 直接执行
$ sh ./crontab.sh
# crontab
$ crontab -e
10 0 * * * sh /mnt/hgfs/Code/ziroom/crontab/cli/crontab.sh > /home/log/cli.log
```

## 错误调试

调试脚本时，遇到一些系统层面的错误问题，一般都不易发现，这时使用`strace`可以用来查看系统调用的执行，才是解决问题的根本。

```Bash
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

通过`strace`可以查看系统的调用过程， 掌握程序的执行流程，有助于进一步深入理解 PHP 的运行机制。
