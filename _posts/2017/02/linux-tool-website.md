---
title: 收录日常查询信息的实用站点 — Linux
date: 2017-02-26 18:48:21
tags:
- Linux
categories:
- Linux
---

在使用 Linux 命令行模式下，作为程序员的你怎么查询一些日常信息呢？比如本地 IP 地址、天气情况等。这里收录一些较实用的日常查询信息的站点。

![](https://img.fanhaobai.com/2017/02/linux-tool-website/em5NGzPratjzKRCB6kSvGehY.png)<!--more-->

# 查询天气

通过 [wttr.in](http://wttr.in) 提供的天气查询服务，可以轻松查询及时的天气信息。wttr.in 的官方文档，[见这里](https://github.com/chubin/wttr.in)。

在`bash`中使用`curl`模拟请求**wttr.in**，即可查询到本地最近**3**天的天气信息。如下图所示：
![](https://img.fanhaobai.com/2017/02/linux-tool-website/Gk8bUSZ01LiIgQtbLYPyF4xM.png)

当然，wttr.in 除了根据 IP 查询到本地的天气信息外，也可以查询**自定义城市**的天气信息，只需在查询地址后加上需查询城市名（中国城市使用城市名拼音）即可，格式为：`wttr.in/city`。

查询**成都**的天气信息，命令为：

```Bash
$ curl wttr.in/chengdu
Weather for City: Chengdu, China

               Mist
  _ - _ - _ -  12 °C
   _ - _ - _   ↓ 7 km/h
  _ - _ - _ -  5 km
               0.0 mm
```

上面只是介绍了 wttr.in 的简单使用，更多的使用方法，[见这里](http://wttr.in/:help)。

这里再介绍一个工具 [wego](https://github.com/schachmat/wego)， 它是一个用`GO`语言开发的天气查询终端。

# IP归属地查询

通过 [ip.cn](http://ip.cn/) 提供的 IP 归属地查询服务，可以方便地查询 IP 地址的归属地。

查询本地的 IP 归属地：

```Bash
$ curl ip.cn
当前 IP：123.57.32.54 来自：北京市 阿里云
```

当然也可以查询**指定** IP 的归属地，IP 地址通过`GET`方式传递即可（注意添加上index.php）。例如：

```Bash
$ curl ip.cn/index.php?ip=103.233.131.130
IP：103.233.131.130 来自：北京市 四维同创
```

后面发现其他的日常查询好站点，再继续补充。