---
title: 使用GoAccess分析Nginx日志
date: 2017-06-17 15:23:46
tags:
- 工具
categories:
- 工具
---

为了查看本站点的健康状况以及用户访问情况，就需要定期的分析服务器的 access 日志。但是由于没有使用日志分析工具，只能使用 cat、awk、sed 等命令做一些简单的日志分析统计，这样分析结果不理想也不全面，方法也极不高效。作为个人站点更适合引入轻量级的日志分析工具，例如 [GoAccess](https://goaccess.io) ，其使用简单且分析效果较好，[见这里](https://www.fanhaobai.com/go-access.html)。

![](https://img.fanhaobai.com/2017/06/go-access/f0652e34-e1ce-46ab-8c0f-b2fef5f36577.png)<!--more-->

## Nginx配置

为了提高 GoAccess 分析准确度，需要配置 `nginx.conf` 的 log_format 项。

```Bash
log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for" "$request_body"';
```

## 安装GoAccess

安装详见 [GoAccess 文档](https://goaccess.io/download)。

```Bash
$ wget http://tar.goaccess.io/goaccess-1.2.tar.gz
$ tar -xzvf goaccess-1.2.tar.gz
$ cd goaccess-1.2/
# --with-openssl项开启openssl，HTTPS时需要
$ ./configure --enable-utf8 --enable-geoip=legacy --with-openssl
$ make
$ make install
```

在 configure 的时候可能会因为缺少一些依赖而失败。例如：

```Bash
checking for GeoIP_new in -lGeoIP... no
configure: error: 
    *** Missing development files for the GeoIP library
```

此时，根据提示安装对应依赖即可。

```Bash
$ yum install GeoIP-devel
# 或者安装全部依赖
$ yum install glib2 glib2-devel GeoIP-devel  ncurses-devel zlib zlib-devel
```

## 配置

安装完成后，默认将配置文件`goaccess.conf`放置于`/usr/local/etc`路径，为了统一管理，使用`mv /usr/local/etc/goaccess.conf /etc/`命令将其移动到`/etc`目录下。

对配置文件做一些主要配置：

```Bash
time-format %H:%M:%S
date-format %d/%b/%Y
log-format %h %^[%d:%t %^] "%r" %s %b "%R" "%u"
```

其中，log-format 与 access.log 的 log_format 格式对应，每个参数以空格或者制表符分割。参数说明如下：

```Bash
%t  匹配time-format格式的时间字段
%d  匹配date-format格式的日期字段
%h  host(客户端ip地址，包括ipv4和ipv6)
%r  来自客户端的请求行
%m  请求的方法
%U  URL路径
%H  请求协议
%s  服务器响应的状态码
%b  服务器返回的内容大小
%R  HTTP请求头的referer字段
%u  用户代理的HTTP请求报头
%D  请求所花费的时间，单位微秒
%T  请求所花费的时间，单位秒
%^  忽略这一字段
```

## 命令

查看 GoAccess 命令参数，如下：

```Bash
$ goaccess -h
# 常用参数
-a --agent-list 启用由主机用户代理的列表。为了更快的解析，不启用该项
-d --with-output-resolver 在HTML/JSON输出中开启IP解析，会使用GeoIP来进行IP解析
-f --log-file 需要分析的日志文件路径
-p --config-file 配置文件路径
-o --output 输出格式，支持html、json、csv
-m --with-mouse 控制面板支持鼠标点击
-q --no-query-string 忽略请求的参数部分
--real-time-html 实时生成HTML报告
--daemonize 守护进程模式，--real-time-html时使用
```

## 控制台模式

```Bash
$ goaccess -a -d -f /data/logs/fanhaobai.com.access.log -p /etc/goaccess.conf
```
![](https://img.fanhaobai.com/2017/06/go-access/f0652e34-e1ce-46ab-8c0f-b2fef5f36577.png)

控制台下的操作方法：

```Bash
F1   主帮助页面
F5   重绘主窗口
q    退出
1-15 跳转到对应编号的模块位置 
o    打开当前模块的详细视图
j    当前模块向下滚动
k    当前模块向上滚动
s    对模块排序
/    在所有模块中搜索匹配
n    查找下一个出现的位置
g    移动到第一个模块顶部
G    移动到最后一个模块底部
```

## HTML模式

```Bash
$ goaccess -a -d -f /data/logs/fanhaobai.com.access.log -p /etc/goaccess.conf -o /data/html/hexo/public/go-access.html
```

![](https://img.fanhaobai.com/2017/06/go-access/cc86d3ce-9287-4151-8a0c-ead3e0dffac5.png)

本站分析出的报表效果，[见这里](https://www.fanhaobai.com/go-access.html)。这个分析报表是通过手动执行命令生成，所以需要实现 GoAccess 自动地创建报表。

### daemonize

GoAccess 已经为我们考虑到这点了，它可以以 daemonize 模式运行，并提供创建实时 HTML 的功能，只需要在启动命令后追加`--real-time-html --daemonize`参数即可。

```Bash
$ goaccess -a -d -f /data/logs/fanhaobai.com.access.log -p /etc/goaccess.conf -o /data/html/hexo/public/go-access.html --real-time-html --daemonize
# 监听端口7890
$ netstat -tunpl | grep "goaccess"
tcp   0   0 0.0.0.0:7890      0.0.0.0:*     LISTEN      21136/goaccess
```

以守护进程启动 GoAccess 后，使用 Websocket 建立长连接，它默认监听 7890 端口，可以通过`--port`参数指定端口号。

>由于我的站点启用了 HTTPS，所以 GoAccess 也需要使用 openssl，在配置文件`goaccess.conf`中配置`ssl-cert`和`ssl-key`项，并确保在安装过程中 configure 时已添加`--with-openssl`项来支持 openssl 。当使用 HTTPS 后 Websocket 通信时也应该使用 wss 协议，需要将`ws-url`项配置为`wss://www.domain.com`。

### crontab

在某些场景下，没有这样的实时性要求，可采用 crontab 机制实现定时更新 HTML 报表。

```Bash
# 每天执行
0 0 1 * * goaccess -a -d -f /data/logs/fanhaobai.com.access.log -p /etc/goaccess.conf -o /data/html/hexo/public/go-access.html 2> /data/logs/go-access.log
```

## 问题

到这里，唯一让我困惑且还未实践的是，当 access 日志被切割后，怎么合理使用 GoAccess 分析日志，`--keep-db-files`这个功能倒是可以尝试，这样就可以只分析新生产的日志文件了。

> 官方文档：https://goaccess.io/man

## 高阶

尽管 GoAccess 很强大，但是它无法制定自定义监控规则，无法满足对站点更细粒度更全面的监控需求。到 2017 年底，本站已经使用 [ELK 日志平台](http://elk.fanhaobai.com) 来分析站点的访问情况和流量分析了，效果见 [ELK 集中式日志平台](https://www.fanhaobai.com/about/#站点导航
)。

![](https://img.fanhaobai.com/2017/12/elk-advanced/b27378ac-e7e8-11e7-80c1-9a214cf093ae.png)

<strong>相关文章 [»]()</strong>

* [ELK集中式日志平台之一 — 平台架构](https://www.fanhaobai.com/2017/12/elk.html) <span>（2017-12-16）</span>
* [ELK集中式日志平台之二 — 部署](https://www.fanhaobai.com/2017/12/elk-install.html) <span>（2017-12-22）</span>
* [ELK集中式日志平台之三 — 进阶](https://www.fanhaobai.com/2017/12/elk-advanced.html) <span>（2017-12-22）</span>
