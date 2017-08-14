---
title: SSH使用的安全技巧
date: 2016-08-16 18:04:23
tags:
- SSH
categories:
- Linux
- CentOS
---

在后端开发过程中，我们经常会通过 [SSH](http://www.ruanyifeng.com/blog/2011/12/ssh_remote_login.html) 远程登录并连接到 **服务器**，以便我们能对服务器进行远程操作。虽说 SSH 是一种加密登录协议， 但是我们在使用 SSH 中还需要注意一些安全技巧。

{% asset_img wUy69HWRKIW0qTiUrzYQhnzR.jpg %}<!--more-->

SSH 服务器的配置文件位置`/etc/ssh/sshd_conf`，下述配置基本上都在配置文件中修改，配置文件修改后需要重新启动 SSH 服务，否则配置不会立即生效。

# 设置禁ping

攻击者可能会通过端口扫面工具，而得出目标服务器监听的端口号，从而进行攻击。通过关闭 Linux 服务器的 [ICMP](http://baike.baidu.com/link?url=ovep8ysxoVKDCFTCvBxTtWMan-U-99q5sr3PZOuLPfqkr_eiAvO-g10LlU0lmMTLu7d41JA0UMv87p7Y8KCgpK) 协议服务或者防火墙拦截 ICMP 协议包，可以达到禁用 ping 的目的。

1） 关闭ICMP服务

```Bash
$ echo "1" >/proc/sys/net/ipv4/icmp_echo_ignore_all
```

2） 防火墙拦截

```Bash
$ iptables -A INPUT -p icmp -j DROP
```

检查禁 ping 是否成功：

```Bash
> ping www.fanhaobai.com
请求超时。
请求超时。
```

# 修改SSH监听端口

默认情况下，SSH 监听 **22** 端口，这也使得攻击者可以轻松扫描到目标服务器是否运行 SSH 服务。所以建议将 SSH 端口号更改为大于 1024。

在文件`/etc/ssh/sshd_config`中，增加如下配置：

```Bash
Port 22                # 保留22默认端口，防止端口配置失败，无法连接SSH
Port 10086
```

重启 SSH 服务：

```Bash
$ service sshd restart
$ netstat -tunpl | grep sshd

Proto Recv-Q Send-Q Local Address  Foreign Address  State    PID/Program name
tcp   0      0      0.0.0.0:10086  0.0.0.0:*        LISTEN   2462/sshd   
tcp   0      0      0.0.0.0:22     0.0.0.0:*        LISTEN   2462/sshd
```

通过新端口 10086 连接 SSH，如果连接成功再删除默认端口 22 配置。

如果查看发现 10086 已被 sshd 监听，而仍然无法连接 SSH，则需添加防火墙规则：

```Bash
# -dport指操作端口号
$ iptables -A INPUT -p tcp --dport 10086 -j ACCEPT
# 永久保存iptables规则
$ /etc/rc.d/init.d/iptables save
# 重启iptables
$ /etc/rc.d/init.d/iptables restart
```

# 仅允许SSH协议版本2

SSH 协议存在两个版本，版本 2 相对于版本 1 更加安全，默认配置只使用协议版本 2。

```Bash
Protocol 2
```

# 公钥登录

使用密码登录 SSH，每次登录都需要频繁输入密码，所以比较麻烦，使用 SSH 的公钥登录，可以免去输入密码的步骤。

1） 在本地主机上生成自己的公钥

```Bash
$ ssh-keygen
```

执行命令后出现一系列提示，直接回车即可。会在`$HOME/.ssh`目录生成公钥和私钥文件，其中`id_rsa.pub`为你的公钥，`id_rsa`为你的私钥。

2） 配置公钥到远程主机

远程主机将用户的公钥保存在`$HOME/.ssh/authorized_keys文件`，所以这里需要将上步生成的 **公钥** 文件`id_rsa.pub`的内容 **追加** 到`authorized_keys`文件中。

如果`authorized_keys`文件不存在，创建即可：

```Bash
$ mkdir ~/.ssh
$ touch ~/.ssh/authorized_keys
```

配置 sshd 服务，配置文件为`/etc/ssh/sshd_config`，将下面内容关闭注释。

```Bash
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

然后，重启 sshd 服务。

```Bash
$ service sshd restart
```

3） 免密登录测试

这里通过配置 **识别名** ，连接时只需指定连接识别名即可，简单方便。

在`$HOME/.ssh`目录下创建`config`文件，并作如下配置：

```Bash
Host fhb
HostName www.fanhaobai.com
Port 10086
User fhb
```

使用识别名连接 SSH 登录远程主机，出现如下内容表示公钥登录成功。

```Bash
$ ssh fhb
Last login: Mon Feb 20 17:09:00 2017 from 103.233.131.130

Welcome to aliyun Elastic Compute Service!
```
