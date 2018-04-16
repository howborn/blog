---
title: AB压力测试工具
date: 2016-02-17 08:00:00
tags:
- 工具
categories:
- 工具
---

[ab](http://baike.baidu.com/link?url=b4bhuzwBAf5Zyh5lkcs_r_vOQAOINHPzuE8Z9oOvSoVwO4rqYARKLon6QzZmmVqbs2jxKudsBMXnoIQ7w0OdLCnPzaaKFnoMpuUGwnoMxw)（ApacheBench）是一款小巧且使用简单的压测工具，可以提供站点基本的性能指标。ab 一般作为 Apache 服务器的子应用程序出现，而这里将介绍 Linux 下独立安装 ab 的方法以及它的简单使用。

![预览图](https://img.fanhaobai.com/2016/02/ab/c390e541-7bb5-453e-bba5-adc31e9034f2.png)<!--more-->


# 独立安装

CentOS 下独立安装 ab 的命令：

```Bash
$ yum install httpd-tools
```

安装后，查看 ab 版本：

```Bash
$ ab -V
This is ApacheBench, Version 2.3
```

# 基本使用

## 基本命令

ab 使用命令格式为：

**`ab [options][http[s]://]hostname[:port]/path`**

通过`ab -h`命令查看 ab 命令参数，这里只列举 **常用参数**。

```Bash
-n   # 在测试会话中所执行的请求个数
-c   # 一次产生的请求个数（并发数）
-p   # 包含需要POST数据的文件，文件格式：“p1=1&p2=2”
-T   # POST数据所使用的Content-type头信息
-C   # 对请求附加一个Cookie头信息，格式为：name=value，多组值用 “,” 号分隔
-H   # 对请求附加一个Header头信息，格式例如：Accept-Encoding: gzip
```

对我博客主站点`www.fanhaobai.com`进行 100 并发压测，命令如下：

```Bash
$ ab -c 100 -n 100 https://www.fanhaobai.com/
```

## 测试结果

通过上述对`www.fanhaobai.com`的站点压测，得到如下测试结果：

```Ini
Benchmarking www.fanhaobai.com (be patient).....done
# web服务器名称
Server Software:        nginx
# host
Server Hostname:        www.fanhaobai.com
# 监听端口，443（HTTPS）
Server Port:            443
SSL/TLS Protocol:       TLSv1/SSLv3,ECDHE-RSA-AES256-GCM-SHA384,4096,256

# 测试的URI
Document Path:          /
# 响应正文长度
Document Length:        37580 bytes

# 测试的并发数
Concurrency Level:      100
# 整个测试持续的时间
Time taken for tests:   41.491 seconds
# 完成的请求数量
Complete requests:      100
# 失败的请求数量
Failed requests:        0
Write errors:           0
# 整个过程中的网络传输量
Total transferred:      3792684 bytes
# 整个过程中的HTML内容传输量
HTML transferred:       3774201 bytes
# 吞吐率，最重要的指标之一
Requests per second:    2.41 [#/sec] (mean)
# 用户平均请求等待时间，最重要的指标之二
Time per request:       41490.657 [ms] (mean)
# 服务器平均请求处理时间，最重要的指标之三
Time per request:       414.907 [ms] (mean, across all concurrent requests)
# 平均每秒网络上的流量
Transfer rate:          89.27 [Kbytes/sec] received

# 网络上消耗的时间的分解
Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       60 1836 3096.3   1373   29355
Processing:   142 19725 7906.1  19955   38415
Waiting:       89 14829 8400.5  12547   38360
Total:        202 21561 7863.1  21334   41294

# 整个压测中所有请求的响应情况。50% 用户的响应时间小于 21334 毫秒，75% 用户的响应时间小于26106 毫秒，最长响应时间小于 41294 毫秒。
Percentage of the requests served within a certain time (ms)
  50%  21334
  66%  25099
  75%  26106
  80%  26491
  90%  30877
  95%  36737
  98%  41278
  99%  41294
 100%  41294 (longest request)
```

整理一下几个 **比较重要** 的测试 **指标**：

> 1. Requests per second —— 吞吐率
> 2. Time per request ——  用户平均请求等待时间
> 3. Time per request ——  服务器平均请求处理时间

# 总结

ab 只是一款小巧使用简单的压测工具，没有图形化结果且不能监控，只供临时测试使用，商业化应用软件必须使用专业压测工具 [LoadRunner](http://baike.baidu.com/link?url=lJ3RJi0dFKBXNaPAEBvbvwr0dY4Cjd13NV5JuwbsXpZR69gaZGp0cpfYlvuJCDkfvi1wprca9_3q_ipH0P2URP4pvJzkDmrgCGjPuEOITDi)。

