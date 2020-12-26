---
title: 用PHP玩转进程之一 — 基础
date: 2018-08-28 20:30:07
tags:
- 系统设计
categories:
- 语言
- PHP
---

我们工作中接触最多的就是 [进程](https://zh.wikipedia.org/wiki/%E8%A1%8C%E7%A8%8B)，但是我们对它又比较陌生，因为它是业务不需要关心的地方，既有的公有组件和操作系统已经对我们屏蔽了它的复杂性。然后跟它的接触时间一长，我们难免会对它产生好奇：How it works?

![预览图](//img0.fanhaobai.com/2018/08/process-php-basic-knowledge/f6eb7888-6de6-41a4-8d15-4d471825a24e.jpg)<!--more--> 

## 什么是进程

进程是 [程序的实体](#)，是系统进行 [资源分配和调度的基本单位](#)，是操作系统结构的基础。每个进程都有自己唯一标识（PID），每个进程都有父进程，这些父进程也有父进程，所有进程都是`init`进程（PID 为 1）的子进程。

我们来直观感受下它的存在，可以说它是看不见又摸不着。

```Shell
$ pstree -p
init(1)-+-init(3)---bash(4)
        |-nginx(771)-+-nginx(773)
        |            |-nginx(774)
        |            |-nginx(776)
        |            `-nginx(777)
        |-php-fpm(702)-+-php-fpm(707)
                       `-php-fpm(712)
```

## 进程分类

### 前台进程

前台进程具有控制终端，会堵塞控制终端。它的特点是：

* 可以同用户交互，但容易被意外终止；
* 有较高的响应速度，优先级别稍高；

```Shell
$ php server.php start
PHPServer start	  [OK] 

# 堵塞了/_ \
```

通常，在控制终端使用`Ctrl+C`组合键，会导致前台进程终止退出。

### 守护进程

守护进程是一种运行在后台的特殊进程，[因为它不属于任何一个终端，所以不会收到任何终端发来的任何信号](#)。它与前台进程显著的区别是：

* 它没有控制终端，不能直接和用户交互，在后台运行；
* 它不受用户登录和注销的影响，只受开机或关机的影响，可以长期运行；

通常我们编写的程序，都需要在 [后台不终止的长期运行](#) ，此时就可以使用守护进程。当然，我们可以在代码中调用系统函数，或者直接在启动命令后追加`&`操作符，如下：

```Shell
$ nohup php server.php start &
# &使进程脱离控制终端运行
```

> 通常`&`与 nohup 结合使用，忽略 SIGHUP 信号来实现一个守护进程。该方式对业务代码侵入最小，方便且成本低，常用于临时执行任务脚本的场景。

## [进程间通信](https://zh.wikipedia.org/wiki/%E8%A1%8C%E7%A8%8B%E9%96%93%E9%80%9A%E8%A8%8A)（InterProcess Communication）

进程的用户空间是相互独立的，一般而言是不能相互访问。但很多情况下，进程间需要互相通信来进行数据传输、共享数据、通知事件、进程控制等，这就必须通过内核实现进程间通信。

![进程间通信模型](//img1.fanhaobai.com/2018/08/process-php-basic-knowledge/dab56833-15dc-405e-b359-4a4fa0e305bc.jpg)

进程间通信有管道、消息队列、信号、共享内存、套接字等方式，本文只介绍后 3 种。

### [共享内存](https://zh.wikipedia.org/wiki/%E5%85%B1%E4%BA%AB%E5%86%85%E5%AD%98)（Shared Memory）

共享内存是一段被映射到多个进程地址空间的内存，虽然这段共享内存是由一个进程创建，但是多个进程都可以访问。如下图：

![共享内存模型](//img2.fanhaobai.com/2018/08/process-php-basic-knowledge/c18f0a31-dade-49e0-90b3-308b7ce63ef6.jpg)

共享内存是最快的进程间通信方式，但是可能会存在竞争，因此需要加锁。Linux 支持三种共享内存：mmap、Posix、以及 System V。

### [套接字](https://zh.wikipedia.org/wiki/Berkeley%E5%A5%97%E6%8E%A5%E5%AD%97)（Socket）

套接字是一个通信链的句柄，可以用域、端口号、协议类型来表示一个套接字，其中域分为 Internet 网络（IP 地址）和 UNIX 文件（Sock 文件）两种。当域为 Internet 网络时，通信流程如下图：

![套接字模型](//img3.fanhaobai.com/2018/08/process-php-basic-knowledge/f85ea400-6623-44ae-88c4-efc9ef1fa315.jpg)

特别的是，当套接字域为 Internet 网络时，可以实现 [跨主机的进程间通信](#)。因此，若要实现跨主机进行进程间通信，则须选用套接字。

### [信号](https://zh.wikipedia.org/wiki/Unix%E4%BF%A1%E5%8F%B7)（Signal）

信号受事件驱动，是一种异步且最复杂的通信方式，用于通知接受进程有某个事件已经发生，因此常用于事件处理。信号的处理机制，如下图：

![信号模型](//img4.fanhaobai.com/2018/08/process-php-basic-knowledge/0f31694b-b96f-48f2-92f4-56552bded7f4.jpg)

#### 常用的信号值

在 Linux 系统中，可使用`kill -l`命令查看这 62 个信号值。其中常用值如下： 

|  信号名称 |    值   |        说明      | [进程默认行为](#进程的处理方式) |
| -------- | ------ | ------------------ | --------------|
|  SIGHUP |   1    | 终端控制进程结束      |    Terminate    |
|  SIGINT |   2    | 键盘Ctrl+C被按下     |    Terminate     |
|  SIGQUIT |   3    | 键盘Ctrl+/被按下    |        Dump      |
|  SIGKILL |   9    | 无条件结束进程       |     Terminate    |
|  SIGUSR1  |   10   | 用户保留            |    Terminate    |
|  SIGUSR2 |   12   | 用户保留             |    Terminate    |
|  SIGALRM |   14   | 时钟定时信号          |    Terminate    |
|  SIGTERM |   15   | 程序结束             |    Terminate    |
|  SIGCHLD |   16   | 子进程结束           |    Ignore    |

#### 产生信号的方式

实际中，硬件或者软件中断都会触发信号，但这里只列举两种信号产生方式。

* 终端按键

|    按键/命令       |     信号名称      |
| ----------------- | ---------------- |
|     Ctrl+C        |      SIGINT      |
|     Ctrl+\        |     SIGQUIT      |
|     EXIT          |      SIGHUP      |

* 系统调用

通过`kill`系统调用发送信号。例如，在 Shell 中使用`kill -9`发送 SIGKILL 信号。对于`kill`调用，需要注意以下两种特殊情况：

1、 特殊信号

可以发送编号为`0`的信号来 [检测进程是否存活](#)。

```PHP
$pid = 577;
if (posix_kill($pid, 0)) {
    echo "进程存在\n";
} else {
    echo "进程不存在\n";
}
```

2、 特殊 PID

这里的参数`$pid`，根据取值范围不同，含义也不同。具体如下：

* \$pid > 0：向 PID 为 \$pid 的进程发送信号；
* \$pid = 0：向当前进程组所有进程发送信号，比较常用；
* \$pid = -1：向所有进程（除 PID 为 1）发送信号（权限）；

### 进程的处理方式

进程共有 3 种处理信号的方式：

* 默认行为；
* 忽略；
* 捕获并处理—注册信号处理器后，当捕获到信号时，执行对应的处理器；

其中，默认行为进一步可以细分为以下几种：

| 默认处理类型   |       描述       |
|--------------|------------------|
|  Terminate   |  进程被中止(杀死)   |
|    Dump	   |  进程被中止(杀死)，并且输出 [dump](http://hutaow.com/blog/2013/10/25/linux-core-dump) 文件|
|    Ignore	   |  信号被忽略 |
|    Stop      |  进程被停止|

信号的默认行为类型，见 [常用的信号值](#常用的信号值) 默认行为部分。

## 进程间关系

使用`ps -ajx`命令查看所有进程信息，如下：

```Shell
#父PID  PID  组ID 会话ID 终端      时间   名称
PPID   PID  PGID   SID TTY      TIME COMMAND
    0     1     1     1 ?       0:00 /init ro
    1    43    43    43 ?       0:00 /usr/sbin/sshd
   43 11134 11134 11134 ?       0:00 sshd: root@pts/1
11134 11169 11169 11169 pts/1   0:00 -bash
11169 11251 11251 11169 pts/1   0:00 PHPServer: master   
11251 11252 11251 11169 pts/1   0:36 PHPServer: worker   
11251 11253 11251 11169 pts/1   0:42 PHPServer: worker   
```

### 进程组（Process Group）

进程组是一个或多个进程的集合。每个进程除了有一个 PID 之外还有一个进程组 ID（GID），每个进程都属于一个进程组，每个进程都有一个组长进程。

如上图中，1 个`PHPServer: master`主进程和 2 个`PHPServer: worker`子进程，属于同一个进程组`11251`，可以看出主进程是组长进程。

### 会话（Session）

会话是一个或多个进程组的集合，一个会话有对应的控制终端。如上图中，4 个`PHPServer`进程和`-bash`进程同属于一个会话，因为他们在一个`pts/1`的控制终端。

[需要说明的是](#)，当用户退出（Logout）会话以后，系统默认对该会话下的进程进行如下操作：

1. 系统向该会话发出 SIGHUP 信号；
2. 该会话将 SIGHUP 信号发给所有子进程；
3. 子进程收到 SIGHUP 信号后，自动退出；

而对于后台进程，用户在退出时系统默认不会发送 SIGHUP 信号，这是由 Shell 的`huponexit`参数（默认`off`）控制。可通过`shopt -s huponexit`设置成`on`（当前会话有效），此时后台进程会收到 SIGHUP 信号。

## 进程模型

从进程层面来说，程序可以分为单进程和多进程模型。

* 单进程

单进程模型的程序，只有一个进程在运行。他是最基本的进程模型，实现起来比较简单，Redis 就是采用这种进程模型。

* 多进程

![信号模型](//img5.fanhaobai.com/2018/08/process-php-basic-knowledge/80e3b1cf-51d8-4342-a08a-976b3a7b3c8c.png)

为了提高程序的并发处理能力，程序由单进程慢慢演变成了多进程，一 个 Master 进程和多个 Worker 进程是多进程常见的构成形态。可以说，现在大部分程序都是多进程模型，其中 Nginx 是典型的代表。

## 总结

到这里，我们已经对进程有了基础的认识，后续我将用 PHP 一步步实现一个 [PHPServer](https://github.com/fan-haobai/php-server) 应用。

<strong>相关文章 [»](#)</strong>

* [用PHP玩转进程之二 — 多进程PHPServer](https://www.fanhaobai.com/2018/09/process-php-multiprocess-server.html) <span>（2018-09-02）</span>
