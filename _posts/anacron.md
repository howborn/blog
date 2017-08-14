---
title: Anacron理解及探究
date: 2017-04-15 23:02:52
tags:
- Linux
categories:
- Linux
---

> 原文：[团队分享](http://www.soooldier.com/2017/04/01/Anacron%E7%90%86%E8%A7%A3%E5%8F%8A%E6%8E%A2%E7%A9%B6/)

有这样一个需求：**“每天凌晨统计一下前一天的订单量？”**
通常的做法就是写一个计划任务每天凌晨去执行统计脚本。是不是 so easy？如果这么想，那么年轻人，你还是 too young too simple！试想一下，如果机房在 00:10 到 00:20 断电怎么办？<!--more-->

在 linux 中，有三种用于任务调度的工具 *at*, *cron*, *anacron* ；在实际开发中，最常见的就是使用 *cron* 去调度执行业务的程序。但是对于 *at* 和 *anacron* 的使用场景却很少涉猎。其中 *at* 一般只用来处理 “一次” 的任务所以它更少会被用到，本文不会说它，而 *anacron* 却在该场景能解决我们的关键问题。

## Anacron能做什么

手册上提到，*“Anacron 以天为单位周期性地执行命令”* 。单从这里看似乎和 *cron* 的功能一样，只不过 *anacron* 是以天为单位，而 *cron* 最小执行的周期是分钟。其实不然，*cron* 和 *anacron* 是两种完全不相干的任务调度工具（虽然它们可以结合使用）。

- *cron* 是通过 daemon 程序 *crond* 来运行任务；而 *anacron* 则没有任何 daemon 程序，它所对应的 *anacron* 进程运行完毕就退出。
- *cron* 在执行任务时不做任何跟时间相关记录；而 *anacron* 会记录下任务完成的时间，这样就给本应该执行却没有执行的任务再执行的条件和机会。
- *anacron* 本身也可以用 *cron* 去调度。

因此，*anacron* 可以解决前面提到因为机房断电造成任务无法执行的问题。在实际应用中它和 *cron* 相互独立却又互为补充。

## Anacron如何使用

`/etc/anacrontab` 是 *anacron* 的配置文件，在配置 *anacron* 任务的时候主要注意 4 个部分的配置：

- `period in days`执行周期；最小 1 天，也可以 3 天，5 天，一个星期（7 天）乃至一个月（月份不能确定有多少天，所以用`@monthly`代替）。
- `delay in minutes`延迟多长时间执行，以分钟为单位。为了避免多个任务在同一时间执行而造成服务器繁忙，所以应该错峰执行。当然真正延迟的时间还要考虑 *RANDOM_DELAY* 的配置。
- `job-identifier` 任务的唯一标识。它用来创建文件记录任务执行的时间，通常创建在` /var/spool/anacron/ `目录中。
- command 真正执行的命令。

### 订单统计的例子

对于前面提到的订单量统计的问题，则可以这么配置：

```Bash
# /etc/anacrontab: configuration file for anacron
# See anacron(8) and anacrontab(5) for details.
SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
# the maximal random delay added to the base delay of the jobs
RANDOM_DELAY=5
# the jobs will be started during the following hours only
START_HOURS_RANGE=1-24
#period in days   delay in minutes   job-identifier   command
1       5       cron.daily.order.statistic      /usr/local/php/bin/php -f your_script_path/order_statistic.php
```

由于 *anacron* 本身是一个普通的程序，还需 *cron* 去调度执行。

```Bash
# 每个小时去执行anacron
01 * * * * /usr/sbin/anacron
```

### CentOS 6.8 的例子

Linux 中有一个日志处理程序 *logrotate*，它每天运行一次来进行各种日志文件的归档压缩。下面几个文件就能很好地说明日志处理的流程：

- `/etc/cron.d/0hourly`：*cron* 调度，每小时执行一次

  ```Bash
  SHELL=/bin/bash
  PATH=/sbin:/bin:/usr/sbin:/usr/bin
  MAILTO=root
  HOME=/
  01 * * * * root run-parts /etc/cron.hourly

  ```

- `/etc/cron.hourly/0anacron`：触发执行 *anacron*

  ```Bash
  #!/bin/bash
  # Skip excecution unless the date has changed from the previous run
  if test -r /var/spool/anacron/cron.daily; then
      day=`cat /var/spool/anacron/cron.daily`
  fi
  if [ `date +%Y%m%d` = "$day" ]; then
      exit 0;
  fi

  # Skip excecution unless AC powered
  if test -x /usr/bin/on_ac_power; then
      /usr/bin/on_ac_power &> /dev/null
      if test $? -eq 1; then
      exit 0
      fi
  fi
  /usr/sbin/anacron -s
  ```

- `/etc/anacrontab`：执行 `/etc/cron.daily` 目录下的任务

  ```Bash
  # /etc/anacrontab: configuration file for anacron

  # See anacron(8) and anacrontab(5) for details.

  SHELL=/bin/sh
  PATH=/sbin:/bin:/usr/sbin:/usr/bin
  MAILTO=root
  # the maximal random delay added to the base delay of the jobs
  RANDOM_DELAY=45
  # the jobs will be started during the following hours only
  START_HOURS_RANGE=3-22

  #period in days   delay in minutes   job-identifier   command
  1       5       cron.daily              nice run-parts /etc/cron.daily
  7       25      cron.weekly             nice run-parts /etc/cron.weekly
  @monthly 45     cron.monthly            nice run-parts /etc/cron.monthly
  ```

- `/etc/cron.daily/logrotate`：`logrotate` 任务最终被触发

  ```Bash
  #!/bin/sh
  /usr/sbin/logrotate /etc/logrotate.conf
  EXITVALUE=$?
  if [ $EXITVALUE != 0 ]; then
      /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
  fi
  exit 0
  ```

### Anacron是怎做到的

*anacron* 能做到任务 “不错过” 的关键点在于它每执行完一次便记录完成的时间。*anacron* 进程执行任务的时候先通过文件里的上次完成时间和其它的配置判断能否执行，如果能执行则创建一个新的进程执行，当前进程退出，如不能执行则直接退出。详细的过程可通过 `strace -f /usr/sbin/anacron` 看到。

### Anacron如何测试

我们在测试 *anacron* 的时候通常希望忽略配置文件中延迟执行的时间。可以使用 *-n* 参数来实现 `/usr/sbin/anacron -n your_job_identifier`，而 *-f* 参数则可以忽略对 timestamp 文件的检测。
