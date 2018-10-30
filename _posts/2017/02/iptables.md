---
title: 详解Iptables
date: 2017-02-11 12:02:23
tags:
- Linux
categories:
- Linux
---

> 原文：http://www.cnblogs.com/metoy/p/4320813.html

Iptables 是 Linux 默认的防火墙的管理工具，防火墙在做信息包过滤决定时，有一套遵循和组成的规则，这些规则存储在内核空间的信息包过滤表中，这些规则分别指定了源地址、目的地址、传输协议（如 TCP、UDP、ICMP）和服务类型（如 HTTP、FTP 和 SMTP）等。当数据包与规则匹配时，防火墙就根据规则所定义的方法来处理这些数据包，如放行（accept）、拒绝（reject）和丢弃（drop）等。所以配置防火墙的主要工作就是 **添加**、**修改** 和 **删除** 这些规则。<!--more-->

本文由于介绍 Iptables 的相关内容较多，可直接 [点击这里](https://www.fanhaobai.com/post/iptables.html#toc-83a) 查看 Iptables 常见的使用方法。

# 基础概念

## Iptables与Netfilter关系

Iptables 和 Netfilter 的关系是一个让很多人搞不清的问题，很多人知道 Iptables 却不知道 Netfilter。其实 Iptables 只是 Linux 防火墙的 **管理工具** ，位于`/sbin/iptables`。真正的防火墙是 Netfilter，它是 Linux 内核中实现包过滤的内部结构。

## Iptables的结构

Iptables 的结构：`Iptables -> Tables -> Chains -> Rules`。也即是，Tables 由 Chains 组成，而 Chains 又由 Rules 组成。

![](https://img5.fanhaobai.com/2017/02/iptables/jWoQg8bgQMi_u4I7HHs7lpUX.png)

** 规格表 **

Iptables 具有 Filter、NAT、Mangle、Raw 四种规则表：

1） Filter表

该表的作用为：**过滤数据包**。该表有 3 个规则链，分别为：INPUT、FORWARD、OUTPUT。

2） Nat表

该表的作用为：**用于网络地址转换**。该表有 3 个规则链，分别为：PREROUTING、POSTROUTING、OUTPUT。

3） Mangle表

该表的作用为：**修改数据包的服务类型、TTL、并且可以配置路由实现 QOS 内核模块**。该表有 5 个规则链，分别为：PREROUTING、POSTROUTING、INPUT、OUTPUT、FORWARD。

4） Raw表

该表的作用为：**决定数据包是否被状态跟踪机制处理**。该表有 2 个规则链，分别为：OUTPUT、PREROUTING。

** 规则链 **

* **INPUT** —— [进入]() 的数据包应用此规则链中的策略
* **OUTPUT** —— [外出]() 的数据包应用此规则链中的策略
* **FORWARD** —— [转发]() 数据包时应用此规则链中的策略
* **PREROUTING** —— [对数据包作路由选择前]() 应用此链中的规则
* **POSTROUTING** —— [对数据包作路由选择后]() 应用此链中的规则

# 命令语法

## 基本语法

Iptables 基本语法格式为：**`iptables [-t table] COMMAND chain CRETIRIA -j ACTION`**

命令说明：

```Shell
 -t table：指定操作表，即filter、nat、mangle表
  COMMAND：定义如何对规则进行管理
    chain：指定操作规则的链，当定义策略的时候，是可以省略的
 CRETIRIA：指定匹配标准
-j ACTION：指定如何进行处理
```

## 链管理命令

```Shell
-P：设置默认策略的（设定默认门是关着的还是开着的）
eg：iptables -P INPUT (DROP|ACCEPT)  默认是关的/默认是开的

-F：清空规则链的(注意每个链的管理权限)
eg：iptables -t nat -F 清空nat表的所有链

-N：新建一个链
eg：iptables -N inbound_new

-X：用于删除自定义的空链
eg：使用方法同-N

-E：用来给自定义的链重命名
eg：iptables -E oldname newname

-Z：清空链及链中默认规则的计数器
eg：iptables -Z
```

## 规则管理命令

```Shell
-A：在当前链的最后新增一条规则
-I num：插入为第几条规则
-R num：指定修改第几条规则
-D num：指定删除第几条规则
```

## 查看管理命令

```Shell
-L：列出相关信息，可以附加子命令
```

附加子命令列表：

```Shell
-n：以数字的方式显示ip，如果不加-n，则会将ip反向解析成主机名
-v：显示详细信息
-vv：显示更多详细信息
-vvv：显示全部详细信息
-x：在计数器上显示精确值，不做单位换算
--line-numbers：显示规则的序号，删除前使用查看规则的序号
```

## 匹配命令

1） 通用匹配，源地址和目标地址的匹配

```Shell
-s：指定源地址匹配，这里不能指定主机名称，必须是IP
-d：指定目标地址
-p：指定协议，通常有3种（TCP/UDP/ICMP）
-i eth0：从该网卡流入的数据，流入一般用在INPUT和PREROUTING上
-o eth0：从该网卡流出的数据，流出一般用在OUTPUT和POSTROUTING上
```

2） 扩展匹配

```Shell
-p tcp ：对TCP协议的扩展。
```

一般有以下两种扩展：

```Shell
--dport：指定目标端口，不能指定多个非连续端口
eg：--dport 21：表示指定21端口
eg：--dport 21-23：表示指定21、22、23端口
--sport：指定源端口
```

## 处理操作命令

```Shell
-j：指定规则的处理操作类型
```

常用的 ACTION 为：

```Shell
DROP：直接丢弃
REJECT：明示拒绝
ACCEPT：接受
MASQUERADE：源地址伪装
REDIRECT：重定向，主要用于实现端口重定向
MARK：给防火墙标记
RETURN：返回
```

# 使用实例

## 查看规则

查看指定表的所有规则，且显示规则序号和 ip。默认查看的是 Filter 表（后面操作都是基于该表），如果要查看 NAT 表，可以加上`-t NAT`参数。

```Shell
$ iptables -nvL --line-number                  #查看当前表所有链的信息
$ iptables --line-number -nL INPUT             #查看当前表INPUT链的信息
```

## 添加规则

先查看当前规则：

```Shell
$ iptables --line-number -nL
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination         
1    DROP       tcp  --  123.56.150.61        0.0.0.0/0           

Chain FORWARD (policy ACCEPT)
num  target     prot opt source               destination         
1    DOCKER     all  --  0.0.0.0/0            0.0.0.0/0           
2    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0           ctstate RELATED,ESTABLISHED 
```

添加一条规则到当前规则表中：

```Shell
$ iptables -A INPUT -s 192.168.1.5 -p tcp -j DROP        #追加一条DROP规则到INPUT链中
$ iptables -I INPUT 2 -s 192.168.2.1 -j DROP             #添加一条DROP规则到INPUT链中，且序号为2
```

## 修改规则

查看当前所有规则：

```Shell
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination         
1    DROP       tcp  --  123.56.150.61        0.0.0.0/0           
2    DROP       all  --  192.168.1.5          0.0.0.0/0           
```

将序号为 **2** 的规则修改为 **ACCEPT**：

```Shell
$ iptables -R INPUT 2 -s 192.168.1.5 -j ACCEPT
```

修改后，再次查看所有规则如下：

```Shell
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination         
1    DROP       tcp  --  123.56.150.61        0.0.0.0/0           
2    ACCEPT     all  --  192.168.1.5          0.0.0.0/0       
```

## 删除规则

删除上面通过命令`iptables -I INPUT 2 -s 192.168.2.1 -j DROP`添加的规则：

```Shell
$ iptables -D INPUT -s 192.168.2.1 -j DROP
```

有时候需要删除的规则很长，所以相应的命令很不方便，所以可以使用删除指定序号的规则。以下为删除序号为 **2** 的规则的命令：

```Shell
$ iptables -D INPUT 2
```