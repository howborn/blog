---
title: Iptables限制恶意IP访问
date: 2017-02-10 11:46:33
tags:
- Linux
categories:
- Linux
---

> 原文：https://www.chinasa.net/archives/165.html

限制恶意 IP 访问的方法有很多，一般服务器服务商都会提供相应的策略，但是通过 iptables 实现限制恶意 IP 访问是比较低成本的方案。[该方案主要是限制每分钟，限制同一个 IP，访问同一个  URL，访问次数 **超过指定次数** 的 IP 地址](#)。<!--more-->

**脚本** 执行时，会过滤白名单（管理员 IP 等），会过滤已经 drop 的 IP。

# 目录结构

自动化脚本依赖的目录结构如下：

```
/opt/sh/cc_sh/
|-- cc_iptables.sh            #执行脚本
|-- drop_ip.txt               #每次drop时的IP
|-- ip_White_list.txt         #IP白名单
|-- ip_black_list.txt         #IP黑名单
```

# 创建自动化脚本

自动化脚本`cc_iptables.sh`的内容如下：

```Bash
#/bin/sh
export LANG=C
date=`date "+%d/%b/%Y:%H:%M"`
logs=/opt/nginx/logs/access.log
max_conn=100
white_list="/opt/sh/cc_sh/ip_white_list.txt"
black_list="/opt/sh/cc_sh/ip_black_list.txt"
drop_ip=/opt/sh/cc_sh/drop_ip.txt

grep $date $logs | awk '{print $1,$7}' | sort | uniq -c | sort -rn | awk \
'{if($1>"'"$max_conn"'"){print $2}}'|uniq > $drop_ip

for ip in `cat $drop_ip`
do
    /bin/grep $ip $white_list > /dev/null
    if [ $? != 0 ];then
        /sbin/iptables -vnL | grep $ip > /dev/null
        if [ $? != 0 ];then
            /sbin/iptables -A INPUT -s $ip -p tcp --dport 80 -j DROP
        fi
    fi
done
/sbin/iptables -vnL | grep DROP | awk '{print $8}' > $black_list
```

# 添加计划任务

在 crontab 添加需要执行的计划任务：

```
*/1 * * * *   /opt/sh/cc_sh/cc_iptables.sh
```

注：脚本里非系统命令，要使用绝对路径，否则有可能执行不成功。
