---
title: 神秘的40毫秒延迟与TCP_NODELAY
date: 2017-11-29 15:48:52
tags:
- TCP/IP
categories:
- 网络
---

>原文：[神秘的40毫秒延迟与 TCP_NODELAY - Jerry's Blog](http://jerrypeng.me/2013/08/mythical-40ms-delay-and-tcp-nodelay/)。

最近排查 Redis 的 Redis server went away 问题时，发现 Redis 的 PHP 扩展里面特意使用 [setsockopt()]() 函数设置了 sock 套接字的 [TCP_NODELAY](https://en.wikipedia.org/wiki/Nagle%27s_algorithm) 项，用来禁用了 Nagle’s Algorithm 算法，遂后搜索到该文章。
![](https://www.fanhaobai.com/2017/11/40ms-delay-and-tcp-nodelay/d8706486-963b-4f46-ab68-be8390747898.png)<!--more-->
![](https://www.fanhaobai.com/2017/11/40ms-delay-and-tcp-nodelay/d8706486-963b-4f46-ab68-be8390747898.png)

最近的业余时间几乎全部献给 [breeze](https://github.com/moonranger/breeze) 这个多年前挖 下的大坑—— 一个异步 HTTP Server。努力没有白费，项目已经逐渐成型了， 基本的框架已经有了，一个静态 文件模块也已经实现了。

写 HTTP Server，不可免俗地一定要用 ab 跑一下性能，结果一跑不打紧，出现了一个困扰了我好几天的问题：神秘的 40ms 延迟。

## 现象

现象是这样的，首先看我用 ab 不加 -k 选项的结果：

```Bash
$ /usr/sbin/ab  -c 1 -n 10 http://127.0.0.1:8000/styles/shThemeRDark.css
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient).....done

Server Software:        breeze/0.1.0
Server Hostname:        127.0.0.1
Server Port:            8000

Document Path:          /styles/shThemeRDark.css
Document Length:        127 bytes

Concurrency Level:      1
Time taken for tests:   0.001 seconds
Complete requests:      10
Failed requests:        0
Write errors:           0
Total transferred:      2700 bytes
HTML transferred:       1270 bytes
Requests per second:    9578.54 [#/sec] (mean)
Time per request:       0.104 [ms] (mean)
Time per request:       0.104 [ms] (mean, across all concurrent requests)
Transfer rate:          2525.59 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:     0    0   0.0      0       0
Waiting:        0    0   0.0      0       0
Total:          0    0   0.1      0       0

Percentage of the requests served within a certain time (ms)
  50%      0
  66%      0
  75%      0
  80%      0
  90%      0
  95%      0
  98%      0
  99%      0
 100%      0 (longest request)
```

很好，不超过 1ms 的响应时间。但一旦我加上了 -k 选项启用 HTTP Keep-Alive，结果就变成了这样：

```Bash
$ /usr/sbin/ab -k  -c 1 -n 10 http://127.0.0.1:8000/styles/shThemeRDark.css
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient).....done

Server Software:        breeze/0.1.0
Server Hostname:        127.0.0.1
Server Port:            8000

Document Path:          /styles/shThemeRDark.css
Document Length:        127 bytes

Concurrency Level:      1
Time taken for tests:   0.360 seconds
Complete requests:      10
Failed requests:        0
Write errors:           0
Keep-Alive requests:    10
Total transferred:      2750 bytes
HTML transferred:       1270 bytes
Requests per second:    27.75 [#/sec] (mean)
Time per request:       36.041 [ms] (mean)
Time per request:       36.041 [ms] (mean, across all concurrent requests)
Transfer rate:          7.45 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:     1   36  12.4     40      40
Waiting:        0    0   0.2      0       1
Total:          1   36  12.4     40      40

Percentage of the requests served within a certain time (ms)
  50%     40
  66%     40
  75%     40
  80%     40
  90%     40
  95%     40
  98%     40
  99%     40
 100%     40 (longest request)
```

40ms 啊！这可是访问本机上的 Server 啊，才 1 个连接啊！太奇怪了吧！祭出 神器 strace，看看到底是什么情况：

```Bash
15:37:47.493170 epoll_wait(3, {}, 1024, 0) = 0
15:37:47.493210 readv(5, [{"GET /styles/shThemeRDark.css HTT"..., 10111}, {"GET /styles/shThemeRDark.css HTT"..., 129}], 2) = 129
15:37:47.493244 epoll_wait(3, {}, 1024, 0) = 0
15:37:47.493279 write(5, "HTTP/1.0 200 OK\r\nContent-Type: t"..., 148) = 148
15:37:47.493320 write(5, "<html><head><title>Hello world</"..., 127) = 127
15:37:47.493347 epoll_wait(3, {}, 1024, 0) = 0
15:37:47.493370 readv(5, 0x7fff196a6740, 2) = -1 EAGAIN (Resource temporarily unavailable)
15:37:47.493394 epoll_ctl(3, EPOLL_CTL_MOD, 5, {...}) = 0
15:37:47.493417 epoll_wait(3, {?} 0x7fff196a67a0, 1024, 100) = 1
15:37:47.532898 readv(5, [{"GET /styles/shThemeRDark.css HTT"..., 9982}, {"GET /styles/shThemeRDark.css HTT"..., 258}], 2) = 129
15:37:47.533029 epoll_ctl(3, EPOLL_CTL_MOD, 5, {...}) = 0
15:37:47.533116 write(5, "HTTP/1.0 200 OK\r\nContent-Type: t"..., 148) = 148
15:37:47.533194 write(5, "<html><head><title>Hello world</"..., 127) = 127
```

发现是读下一个请求之前的那个 epoll_wait 花了 40ms 才返回。这意味着要 么是 client 等了 40ms 才给我发请求，要么是我上面 write 写入的数据过 了 40ms 才到达 client。前者的可能性几乎没有，ab 作为一个压力测试工具， 是不可能这样做的，那么问题只有可能是之前写入的 response 过了 40ms 才到 达 client。

## 背后的原因

为什么延迟不高不低正好 40ms 呢？果断 Google 一下找到了答案。原来这是 TCP 协议中的 Nagle‘s Algorithm 和 TCP Delayed Acknoledgement 共同起作 用所造成的结果。

Nagle’s Algorithm 是为了提高带宽利用率设计的算法，其做法是合并小的TCP 包为一个，避免了过多的小报文的 TCP 头所浪费的带宽。如果开启了这个算法 （默认），则协议栈会累积数据直到以下两个条件之一满足的时候才真正发送出去：

1. [积累的数据量到达最大的 TCP Segment Size]()
2. [收到了一个 Ack]()

TCP Delayed Acknoledgement 也是为了类似的目的被设计出来的，它的作用就 是延迟 Ack 包的发送，使得协议栈有机会合并多个 Ack，提高网络性能。

如果一个 TCP 连接的一端启用了 Nagle‘s Algorithm，而另一端启用了 TCP Delayed Ack，而发送的数据包又比较小，则可能会出现这样的情况：发送端在等 待接收端对上一个packet 的 Ack 才发送当前的 packet，而接收端则正好延迟了 此 Ack 的发送，那么这个正要被发送的 packet 就会同样被延迟。当然 Delayed Ack 是有个超时机制的，而默认的超时正好就是 40ms。

现代的 TCP/IP 协议栈实现，默认几乎都启用了这两个功能，你可能会想，按我 上面的说法，当协议报文很小的时候，岂不每次都会触发这个延迟问题？事实不 是那样的。仅当协议的交互是发送端连续发送两个 packet，然后立刻 read 的 时候才会出现问题。

## 为什么只有 Write-Write-Read 时才会出问题

维基百科上的有一段伪代码来介绍 Nagle’s Algorithm：

```C
if there is new data to send
   if the window size >= MSS and available data is >= MSS
    send complete MSS segment now
  else
    if there is unconfirmed data still in the pipe
      enqueue data in the buffer until an acknowledge is received
    else
      send data immediately
    end if
  end if
end if
```

可以看到，当待发送的数据比 MSS 小的时候（外层的 else 分支），还要再判断 时候还有未确认的数据。只有当管道里还有未确认数据的时候才会进入缓冲区，等待 Ack。

所以发送端发送的第一个 write 是不会被缓冲起来，而是立刻发送的（进入内层 的else 分支），这时接收端收到对应的数据，但它还期待更多数据才进行处理， 所以不会往回发送数据，因此也没机会把 Ack 给带回去，根据Delayed Ack 机制， 这个 Ack 会被 Hold 住。这时发送端发送第二个包，而队列里还有未确认的数据 包，所以进入了内层 if 的 then 分支，这个 packet 会被缓冲起来。此时，发 送端在等待接收端的 Ack；接收端则在 Delay 这个 Ack，所以都在等待，直到接 收端 Deplayed Ack 超时（40ms），此 Ack 被发送回去，发送端缓冲的这个 packet 才会被真正送到接收端，从而继续下去。

再看我上面的 strace 记录也能发现端倪，因为设计的一些不足，我没能做到把 短小的 HTTP Body 连同 HTTP Headers 一起发送出去，而是分开成两次调用实 现的，之后进入 epoll_wait 等待下一个 Request 被发送过来（相当于阻塞模 型里直接 read）。正好是 write-write-read 的模式。

那么 write-read-write-read 会不会出问题呢？维基百科上的解释是不会：

> “The user-level solution is to avoid write-write-read sequences on sockets. write-read-write-read is fine. write-write-write is fine. But write-write-read is a killer. So, if you can, buffer up your little writes to TCP and send them all at once. Using the standard UNIX I/O package and flushing write before each read usually works.”

我的理解是这样的：因为第一个 write 不会被缓冲，会立刻到达接收端，如果是 write-read-write-read 模式，此时接收端应该已经得到所有需要的数据以进行 下一步处理。接收端此时处理完后发送结果，同时也就可以把上一个packet 的 Ack 可以和数据一起发送回去，不需要 delay，从而不会导致任何问题。

我做了一个简单的试验，注释掉了 HTTP Body 的发送，仅仅发送 Headers， Content-Length 指定为 0。这样就不会有第二个 write，变成了 write-read-write-read 模式。此时再用 ab 测试，果然没有 40ms 的延迟了。

说完了问题，该说解决方案了。

## 解决方案

###  优化协议

连续 write 小数据包，然后 read 其实是一个不好的网络编程模式，这样的连 续 write 其实应该在应用层合并成一次 write。

可惜的是，我的程序貌似不太好做这样的优化，需要打破一些设计，等我有时间 了再好好调整，至于现在嘛，就很屌丝地用下一个解决方法了。

### 开启 TCP_NODELAY

简单地说，这个选项的作用就是禁用 Nagle’s Algorithm，禁止后当然就不会有 它引起的一系列问题了。在 UNIX C 里使用 setsockopt 可以做到：

```C
static void _set_tcp_nodelay(int fd) {
    int enable = 1;
    setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (void*)&enable,sizeof(enable));
}
```

在 Java 里就更简单了，Socket 对象上有一个 setTcpNoDelay 的方法，直接设 置成 true 即可。
据我所知，Nginx 默认是开启了这个选项的，这也给了我一点安慰：既然 Nginx 都这么干了，我就先不忙为了这个问题打破设计了，也默认开启 TCP_NODELAY 吧……
