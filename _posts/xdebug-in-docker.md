---
title: 在Docker中使用Xdebug
date: 2017-09-01 23:23:55
tags:
- PHP
categories:
- 语言
- PHP
---

我们经常会使用 PhpStorm 结合 Xdebug 进行代码断点调试，这样能追踪程序执行流程，方便调试代码和发现潜在问题。博主将开发环境迁入 Docker 后，Xdebug 调试遇到了些问题，所以在这里整理出 Docker 中使用 Xdebug 的方法和注意事项。

![](https://www.fanhaobai.com/2017/09/xdebug-in-docker/07490b33-a2a3-491d-b325-cf8bfb9c9542.gif)<!--more-->

说明：开发和调试环境为本地 Docker 中的 LNMP，IDE 环境为本地 Win10 下的 PhpStorm。这种情况下 Xdebug 属于远程调试模式，IDE 和本地 IP 为 192.168.1.101，Docker 中 LNMP 容器 IP 为 172.17.0.2。

## 问题描述

在 Docker 中安装并配置完 Xdebug ，并设置 PhpStorm 中对应的  Debug 参数后，但是 Debug 并不能正常工作。

此时，`php.ini`中 Xdebug 配置如下：

```PHP
xdebug.idekey = phpstorm
xdebug.remote_enable = on
xdebug.remote_host = *.*.*.*     //本地ip地址
xdebug.remote_connect_back = on
xdebug.remote_port = 9001        //PhpStorm监听本地9001端口
xdebug.remote_handler = dbgp
xdebug.remote_log = /home/tmp/xdebug.log
```

开始收集问题详细表述。首先，观察到 PhpStorm 的 Debug 控制台出现状态：

```Bash
Waiting for incoming connection with ide key ***
```

然后查看 Xdebug 调试日志`xdebug.log`，存在如下错误：

```PHP
I: Checking remote connect back address.
I: Checking header 'HTTP_X_FORWARDED_FOR'.
I: Checking header 'REMOTE_ADDR'.
I: Remote address found, connecting to 172.17.0.1:9001.
W: Creating socket for '172.17.0.1:9001', poll success, but error: Operation now in progress (29).
E: Could not connect to client. :-(
```

## 分析问题

查看这些问题表述，基本上可以定位为 Xdebug 和 PhpStorm 之间的 [网络通信]() 问题，接下来一步步定位具体问题。

### 排查本地9001端口

Win 下执行 `netstat -ant`命令：

```Bash
协议    本地地址       外部地址        状态           卸载状态
TCP  0.0.0.0:9001   0.0.0.0:0     LISTENING       InHost
```

端口 9001 监听正常，然后在容器中使用 telnet 尝试同本地 9001 端口建立 TCP 连接：

```Bash
$ telnet 192.168.1.101 9001

Trying 192.168.1.101...
Connected to 192.168.1.101.
Escape character is '^]'.
```

说明容器同本地 9001 建立 TCP 连接正常，但是 Xdebug 为什么会报连接失败呢？此时，至少可以排除不会是因为 PhpStorm 端配置的问题。

### 排查Xdebug问题

回过头来看看 Xdebug 的错误日志，注意观察到失败时的连接信息：

```Bash
I: Remote address found, connecting to 172.17.0.1:9001.
W: Creating socket for '172.17.0.1:9001', poll success, but error: Operation now in progress (29).
E: Could not connect to client. :-(
```

此时，在容器中使用 tcpdump 截获的数据包如下：

```Bash
$ tcpdump -nnA port 9001
# 尝试建立连接，但是失败了
12:20:34.318080 IP 172.17.0.2.40720 > 172.17.0.1.9001: Flags [S], seq 2365657644, win 29200, options [mss 1460,sackOK,TS val 833443 ecr 0,nop,wscale 7], length 0
E..<..@.@.=...........#)...,......r.XT.........
............
12:20:34.318123 IP 172.17.0.1.9001 > 172.17.0.2.40720: Flags [R.], seq 0, ack 2365657645, win 0, length 0
E..(.]@.@..M........#).........-P....B..
```

可以确定的是， Xdebug 是向 IP 为 172.17.0.1 且端口为 9001 的目标机器尝试建立 TCP 连接，而非正确的 192.168.1.101 本地 IP。到底发生了什么？

首先，为了搞懂 Xdebug 和 PhpStorm 的交互过程，查了 [官方手册](https://xdebug.org/docs/remote) 得知，Xdebug 工作在远程调试模式时，有两种工作方式：

1、IDE 所在机器 IP 确定/单个开发

![](https://www.fanhaobai.com/2017/09/xdebug-in-docker/07490b33-a2a3-491d-b325-cf8bfb9c9542.gif)

图中，由于 IDE 的 IP 和监听 9000 端口都已知，所以 Xdebug 端可以很明确知道 DBGP 交互时 IDE 目标机器信息，所以 Xdebug只需配置 [xdebug.remote_host](https://xdebug.org/docs/all_settings#remote_host)、[xdebug.remote_port](https://xdebug.org/docs/all_settings#remote_port) 即可。

2、IDE 所在机器 IP 未知/团队开发

![](https://www.fanhaobai.com/2017/09/xdebug-in-docker/6d0a816e-54b9-4061-83a2-fd4e8a2f3d8f.gif)

由于 IDE 的 IP 未知或者 IDE 存在多个 ，那么 Xdebug 无法提前预知 DBGP 交互时的目标 IP，所以不能直接配置 xdebug.remote_host 项（remote_host 项可以确定），必须设置[xdebug.remote_connect_back](https://xdebug.org/docs/all_settings#remote_connect_back) 为 On 标识（[会忽略 xdebug.remote_host 项]()）。这时，Xdebug 会优先获取 HTTP_X_FORWARDED_FOR 和 REMOTE_ADDR 一个值作为通信时 IDE 端的目标 IP，通过上述`Xdebug.log`记录可以确认。

```PHP
I: Checking remote connect back address.
I: Checking header 'HTTP_X_FORWARDED_FOR'.
I: Checking header 'REMOTE_ADDR'.
I: Remote address found
```

接下来，可以知道 Xdebug 端是工作在远程调试的模式 2 上，Xdebug 会通过 HTTP_X_FORWARDED_FOR 和 REMOTE_ADDR 项获取目标机 IP。Docker 启动容器时已经做了 80 端口映射，忽略宿主机同 Docker 容器复杂的数据包转发规则，先截取容器 80 端口数据包：

 ```Bash
$ tcpdump -nnA port 80
# 请求信息
13:30:07.017770 IP 172.17.0.1.33976 > 172.17.0.2.80: Flags [P.], seq 1:208, ack 1, win 229, options [nop,nop,TS val 1250713 ecr 1250713], length 207
E....=@.@..............P..	.+.......Y......
........GET /v2/room/list.json HTTP/1.1
Accept: */*
Cache-Control: no-cache
Host: localhost
Connection: Keep-Alive
User-Agent: Apache-HttpClient/4.5.2 (Java/1.8.0_152-release)
Accept-Encoding: gzip,deflate
 ```

可以看出，数据包的源地址为 [172.17.0.1](http://www.infoq.com/cn/articles/docker-network-and-pipework-open-source-explanation-practice/)，并非真正的源地址 192.168.1.101，HTTP 请求头中也无 HTTP_X_FORWARDED_FOR 项。

> 说明：172.17.0.1 实际为 Docker 创建的虚拟网桥 docker0，也是所有容器的默认网关。Docker 网络通信方式默认为 Bridge 模式，通信时宿主机会对数据包进行 SNAT 转换，进而源地址变为 docker0，那么，[怎么在 Docker 里获取客户端真正 IP 呢？](https://github.com/moby/moby/issues/15086)。

### 定位根源

最后，可以确定由于 HTTP_X_FORWARDED_FOR 未定义，因此 Xdebug 会取 REMOTE_ADDR 为 IDE 的源 IP，同时由于 Docker 特殊的网络转发规则，导致 REMOTE_ADDR 变更为网关 IP，所以 Xdebug 同 PhpStorm 进行 DBGP 交互会失败。

## 解决问题

由于 Docker 容器里获取真正客户端 IP 比较复杂，这里使用 Xdebug 的 [远程模式 1]() 明确 IDE 端 IP 来规避源 IP 被修改的情况，最终解决 Xdebug 调试问题。

模式 1 的 Xdebug 主要配置为：

```PHP
//并没有xdebug.remote_connect_back项
xdebug.idekey = phpstorm
xdebug.remote_enable = on
xdebug.remote_host = 192.168.1.101
xdebug.remote_port = 9001
xdebug.remote_handler = dbgp
```

重启 php-fpm，使用`php --ri xdebug`确定无误，使用 PhpStorm 重新进行调试。

再次在容器中 tcpdump 抓取 9001 端口数据包：

```PHP
# 连接的源地址已经正确
14:05:27.379783 IP 172.17.0.2.44668 > 192.168.1.101.9001: Flags [S], seq 3444466556, win 29200, options [mss 1460,sackOK,TS val 1462749 ecr 0,nop,wscale 7], length 0
E..<2.@.@..........e.|#).Nc|......r.nO.........
..Q.........
```

再次使用 PhpStorm 的 REST Client 断点调试 API 时， Debug 控制台如下：

![](https://www.fanhaobai.com/2017/09/xdebug-in-docker/7f7c8948-5e61-4086-b52d-fa9ceab69d3b.png)


## 其他注意事项

* Xdebug 版本和 PHP 版本一致

并不是每个 Xdebug 版本都适配 PHP 每个版本，可以直接使用 [官方工具](https://xdebug.org/wizard.php)，选择合适的 Xdebug 版本。

* 本地文件和远端文件映射关系

![](https://www.fanhaobai.com/2017/09/xdebug-in-docker/cfe7ef04-4552-49c5-9ffb-6131f52afdb9.png)

如上图，在使用 PhpStorm 时进行远程调试时，需要配置本地文件和远端文件的目录映射关系，这样 IDE 才能根据 Xdebug 传递的当前执行文件路径与本地文件做匹配，实现断点调试和单步调试等。
