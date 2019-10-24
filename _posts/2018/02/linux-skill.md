---
title: Linux日常使用技巧集
date: 2018-02-04 22:00:00
tags:
- Linux
categories:
- Linux
---

作为技术人员，Linux 系统可以说是我们使用最多的操作系统，但我们可能并不是很了解它。在这里我将自己日常遇到的 Linux 使用技巧记录下来，方便以后查询使用。

![预览图](https://img0.fanhaobai.com/2018/02/linux-skill/2a82ad6b-ab25-409f-858c-22312826ac06.jpg)<!--more-->

## 常用命令

* 统计 IP 连接数

```Shell
$ netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
```

## 操作系统

### 查看系统版本

在安装环境或者软件时，我们常常需要知道所在操作系统的版本信息，这里列举几种查看内核和发行版本信息的方法，更多见 [查看 Linux 系统版本](https://www.fanhaobai.com/2016/07/linux-version.html)。

#### 内核版本

* uname命令

```Shell
$ uname -a
Linux fhb-6.6 2.6.32-642.13.1.el6.i686
```

* /proc/version文件

```Shell
$ cat /proc/version 
Linux version 2.6.32-642.13.1.el6.i686
```

#### 发行版本

* lsb_release命令

```Shell
$ lsb_release -a
LSB Version:	:base-4.0-ia32:base-4.0-noarch:core-4.0-ia32
Distributor ID:	CentOS
Release:	6.8
```

* /etc/issue文件

```Shell
$ cat /etc/redhat-release
CentOS release 6.8 (Final)
```

### 启用Swap分区

在遇到内存容量瓶颈时，我们就可以尝试启用 Swap 分区。使用文件（还可以磁盘分区）作为 Swap 分区时，具体步骤如下：

1、 创建 Swap 分区的文件

```Shell
# bs*count为文件大小
$ dd if=/dev/zero of=/root/swapfile bs=1M count=1024
```

2、 格式化为交换分区文件

```Shell
$ mkswap /root/swapfile
```

3、 启用交换分区

```Shell
$ swapon /root/swapfile
```

4、 开机自启用 Swap 分区

在`/etc/fstab`文件中添加如下内容：

```Shell
/root/swapfile swap swap defaults 0 0
```

最后，查看系统的 Swap 分区信息：

```Shell
$ free -h
       total   used    free   shared  buff/cache   available
Mem:   1.7G    729M    252M   9.2M    714M         763M
Swap:  1.0G    0B      1.0G
```

### 免密码使用sudo

以下两种需求：
1. 开发中经常会使用到 sudo 命令，为了避免频繁输入密码的麻烦；
2. 脚本中使用到 sudo 命令，怎么输入密码？；

这些，都可以通过将用户加入 sudoers 来解决，当然情况 2 也可以使用`echo "passwd"|sudo -S cmd`，从标准输入读取密码。

sudoers 配置文件为`/etc/sudoers`，sudo 命令操作权限配置内容如下：

```bash
# 授权用户/组    主机名=（允许转换至的用户）   NOPASSWD:命令动作
root ALL=(ALL) ALL
```

[授权格式](#) 说明：

* 第一个字段为授权用户或组，例如 root；
* 第二个字段为来源，() 中为允许转换至的用户，= 左边为主机名；
* 第三个字段为命令动作，多个命令以`,`号分割；

因此，我的用户为`fhb`，授权步骤如下：

```bash
# 1. 执行visudo命令，操作的文件就是/etc/sudoers
$ sudo visudo
# 2. 追加内容
fhb ALL=(root) NOPASSWD: /usr/sbin/service,/usr/local/php/bin/php,/usr/bin/vim
# 3. Ctrl+O保存并按Enter
```

然后，使用`sudo service ssh restart`命令测试 OK。

### Yum更新排除指定软件

有时候我们使用 yum 安装的软件，由于配置向后兼容性等问题，我们并不希望这些软件（filebeat 和 logstash）在使用`update`时，被不经意间被自动更新。这时，可以使用如下方法解决：

* 临时

通过`-x`或`--exclude`参数指定需要排除的包名称，多个包名称使用空格分隔。例如：

```Shell
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

```Shell
$ yum update
No Packages marked for Update
```

## ssh

### 设置禁PING

攻击者可能会通过端口扫面工具，而得出目标服务器监听的端口号，从而进行攻击。通过关闭 Linux 服务器的 [ICMP](http://baike.baidu.com/link?url=ovep8ysxoVKDCFTCvBxTtWMan-U-99q5sr3PZOuLPfqkr_eiAvO-g10LlU0lmMTLu7d41JA0UMv87p7Y8KCgpK) 协议服务或者防火墙拦截 ICMP 协议包，可以达到禁用 ping 的目的。

a. 关闭ICMP服务

```Shell
$ echo "1" >/proc/sys/net/ipv4/icmp_echo_ignore_all
```

b. 防火墙拦截

```Shell
$ iptables -A INPUT -p icmp -j DROP
```

检查禁 ping 是否成功：

```Shell
> ping www.fanhaobai.com
请求超时。
请求超时。
```

### 修改SSH监听端口

默认情况下，SSH 监听 **22** 端口，这也使得攻击者可以轻松扫描到目标服务器是否运行 SSH 服务。所以建议将 SSH 端口号更改为大于 1024。

在文件`/etc/ssh/sshd_config`中，增加如下配置：

```Shell
Port 22                # 保留22默认端口，防止端口配置失败，无法连接SSH
Port 10086
```

重启 SSH 服务：

```Shell
$ service sshd restart
$ netstat -tunpl | grep sshd

Proto Recv-Q Send-Q Local Address  Foreign Address  State    PID/Program name
tcp   0      0      0.0.0.0:10086  0.0.0.0:*        LISTEN   2462/sshd   
tcp   0      0      0.0.0.0:22     0.0.0.0:*        LISTEN   2462/sshd
```

通过新端口 10086 连接 SSH，如果连接成功再删除默认端口 22 配置。

如果查看发现 10086 已被 sshd 监听，而仍然无法连接 SSH，则需添加防火墙规则：

```Shell
# -dport指操作端口号
$ iptables -A INPUT -p tcp --dport 10086 -j ACCEPT
# 永久保存iptables规则
$ /etc/rc.d/init.d/iptables save
# 重启iptables
$ /etc/rc.d/init.d/iptables restart
```

### 公钥登录

使用密码登录 SSH，每次登录都需要频繁输入密码，所以比较麻烦，使用 SSH 的公钥登录，可以免去输入密码的步骤。

1、在本地主机上生成自己的公钥

```Shell
$ ssh-keygen
```

执行命令后出现一系列提示，直接回车即可。会在`$HOME/.ssh`目录生成公钥和私钥文件，其中`id_rsa.pub`为你的公钥，`id_rsa`为你的私钥。

2、配置公钥到远程主机

远程主机将用户的公钥保存在`$HOME/.ssh/authorized_keys文件`，所以这里需要将上步生成的 **公钥** 文件`id_rsa.pub`的内容 **追加** 到`authorized_keys`文件中。

如果`authorized_keys`文件不存在，创建即可：

```Shell
$ mkdir ~/.ssh
$ touch ~/.ssh/authorized_keys
```

配置 sshd 服务，配置文件为`/etc/ssh/sshd_config`，将下面内容关闭注释。

```Shell
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

然后，重启 sshd 服务。

```Shell
$ service sshd restart
```

3、免密登录测试

这里通过配置 **识别名** ，连接时只需指定连接识别名即可，简单方便。

在`$HOME/.ssh`目录下创建`config`文件，并作如下配置：

```Shell
Host fhb
HostName www.fanhaobai.com
Port 10086
User fhb
```

使用识别名连接 SSH 登录远程主机，出现如下内容表示公钥登录成功。

```Shell
$ ssh fhb
Last login: Mon Feb 20 17:09:00 2017 from 103.233.131.130

Welcome to aliyun Elastic Compute Service!
```

### 强制踢出其他登录用户

在某些情况下，需要强制踢出系统其他登录用户，比如遇到非法用户登录。查询当前登陆用户：

```Shell
# 当前用户
$ whoami
root
# 当前所有用户
$ ps -ef | grep 'pts'
root      4752  4727  0 00:09 pts/0    00:00:00 su www
www       4755  4752  0 00:09 pts/0    00:00:00 bash
```

剔除非法登陆用户：

```Shell
$ kill -9 4755
```

更多详细说明，见 [Linux 强制踢出其他登录用户](https://www.fanhaobai.com/2016/11/out-users.html)。

### 建立隧道实现端口转发

在可以使用 ssh 情况下，为了能进行线上调试，我们可以使用 ssh 隧道建立端口映射。

例如，线上远程目标机器 ip：10.1.1.123、端口：3303；映射到本地 33031 端口。命令如下：

```Shell
# [主机ip]:[端口]:[主机ip]:[远程目标机器端口] [远程目标机器ip]
ssh -L 127.0.0.1:33031:127.0.0.1:3303 10.1.1.123
```

> 该命令操作后，只能通过`127.0.0.1`访问。若想全网段访问，需要将第一个主机 ip 更改为`0.0.0.0`，同时需要在`/etc/ssh/sshd_config`增加`GatewayPorts yes`的配置项。

## 常用工具

### Strace调试

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

### 彩色的命令行

在脚本或者代码中，有时候需要在控制终端输出醒目的提示信息，以便引起我们的关注。其实，在 Linux 终端下很容易就能搞定，如下：

![彩色的命令行](https://img1.fanhaobai.com/2018/02/linux-skill/7bb99049-49bd-427b-a338-3afff4268fb3.jpg)

实现的源代码，内容为：

```Bash
echo -e "\033[1;30m Hello World. \033[0m [高亮]"
echo -e "\033[0;31m Hello World. \033[0m [关闭属性]"
echo -e "\033[4;32m Hello World. \033[0m [下划线]"
echo -e "\033[5;33m Hello World. \033[0m [闪烁]"
echo -e "\033[7;34m Hello World. \033[0m [反显]"
echo -e "\033[8;35m Hello World. \033[0m [消隐]"
echo -e "\033[0;36;40m Hello World."
echo -e "\033[0;37;41m Hello World."
```

> `\033`是 Esc 键对应的 ASCII 码（27=/033=0x1B），表示后面的内容具有特殊含义，类似表述有`^[`以及`/e`，而`\033[0m`表示清除格式控制。

输出格式的规则，可表示为`\033[特殊格式;前景色;背景色m`，主要分为 [颜色](#) 和 [格式](#) 两类规则。

* 颜色

主要包括 [前景色](#) 和 [背景色](#)，前景色范围为`30~39`，背景色范围为`40~49`（前景色对应颜色值 +10）。前景色颜色代码表如下：

<div><span style="color:black;">黑   = "\033[30m"</span>
<span style="color:red;">红   = "\033[31m"</span>
<span style="color:green;">绿   = "\033[32m"</span>
<span style="color:yellow;">黄   = "\033[33m"</span>
<span style="color:blue;">蓝   = "\033[34m"</span>
<span style="color:purple;">紫   = "\033[35m"</span>
<span style="color:cyan;">青 = "\033[36m"</span>
<span style="color:white;">白   = "\033[37m"</span></div>

* 格式

|  表达式   |     格式     |
| -------- | ------------ |
| \033[0m |  关闭所有属性 |
| \033[1m |    高亮度    |
| \033[4m |    下划线    |
| \033[5m |     闪烁     |
| \033[7m |     反显     |
| \033[8m |     消隐     |

<strong>更新 [»](#)</strong>
* [免密码使用 sudo](#免密码使用sudo)（2018-04-12）
* [彩色的命令行](#彩色的命令行)（2018-08-14）
