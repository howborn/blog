---
title: 怎么用PHP玩转进程
date: 2018-08-24 20:30:06
tags:
- PHP
- Linux
categories:
- 语言
- PHP
---

可以说，我们工作中接触最多的就是 [进程]()（代码的容器），但是我们往往对它又比较陌生，是因为它是业务不需要关心的地方，既有的公有组件和操作系统已经对我们屏蔽了它的复杂性。然后跟它的接触时间一长，我们难免会对它产生好奇：How it work?

![预览图](https://img0.fanhaobai.com/2018/08/f6eb7888-6de6-41a4-8d15-4d471825a24e.jpg)<!--more--> 

## 进程基础概念

进程是操作系统的一个核心，每个进程都有自己唯一标识，即 PID。同时，每个进程都有父进程，这些父进程也有父进程，所有进程都是`init`进程（PID 为 1）的子进程。

### 进程分类

#### 前台进程

前台进程具有控制终端，会堵塞控制终端。它的特点是：

* 可以同用户交互，但容易被意外终止；
* 有较高的响应速度，优先级别稍高；

```Bash
$ php server.php start
PHPServer start	  [OK] 

# 堵塞了 /_ \
```

通常，在控制终端使用`Ctrl+C`组合键，即可导致前台进程终止退出。

#### 守护进程

守护进程是一种运行在后台的特殊进程，[因为它不属于任何一个终端，所以不会收到任何终端发来的任何信号]()。它与前台进程显著的区别是：

* 它没有控制终端，不能直接和用户交互，在后台运行；
* 它不受用户登录和注销的影响，只受开机或关机的影响，可以长期运行；

通常我们编写的程序，都需要在 [后台不终止的长期运行]() ，此时就可以使用守护进程。当然，我们可以在代码中调用系统函数，或者直接在启动命令后追加`&`操作符，来实现一个守护进程。后者使用如下：

```Bash
$ php server.php start &
# 进程脱离控制终端运行
```

> 通常`&`与 nohup 结合使用，忽略 SIGHUP 信号。该方式对业务代码侵入最小，方便且成本低，常用于临时执行任务脚本的场景。

### 进程间通信——信号（Signal）

信号是进程间通信的一种机制。因此我们可以向特定进程发送特定的信号，来控制进程的特定行为。

#### 常用的信号值

在 Linux 系统中，可使用`kill -l`命令查看 62 个信号值，其中部分常用值如下： 

|  信号名称 |    值   |        说明        |   进程默认行为  |
| -------- | ------ | ------------------ | --------------|
|  SIGHUP |   1    | 终端挂起或控制进程终止信号 |    终止进程    |
|  SIGINT |   2    | 键盘Ctrl+C被按下信号     |    终止进程    |
|  SIGQUIT |   3    | 键盘Ctrl+\被按下信号    | 终止进程并产生core-dump |
|  SIGKILL |   9    | 立即终止进程信号         |    终止进程    |
|  SIGUSR1  |   10   | 用户定义的信号           |    终止进程    |
|  SIGUSR2 |   12   | 用户定义的信号           |    终止进程    |
|  SIGALRM |   14   | 定时器超时信号           |    终止进程    |
|  SIGTERM |   15   | 程序结束信号             |    终止进程    |
|  SIGCHLD |   16   | 子进程结束信号           |    忽略信号    |

#### 产生信号的方式

实际中，硬件或者软件中断都会触发信号，但是这里只列举两种常用的信号产生方式。

* 终端按键

|    按键/命令       |     信号名称      |
| ----------------- | ---------------- |
|     Ctrl+C        |      SIGINT      |
|     Ctrl+\        |     SIGQUIT      |
|     EXIT          |      SIGHUP      |

* 系统调用

通过`kill`系统调用发送信号。例如，在 Shell 中使用`kill -9`发送 SIGKILL 信号；又如，发送编号为`0`的信号来 [检测进程是否存活]()。

```PHP
$pid = 577;
if (posix_kill($pid, 0)) {
    echo "进程存在\n";
} else {
    echo "进程不存在\n";
}
```

#### 进程的处理方式

进程共有 3 种处理信号的方式：

* 默认行为——主要有终止进程、忽略信号、重启或暂停进程，见 [常用的信号值](#常用的信号值) 默认行为部分；
* 忽略；
* 捕获并处理——先安装信号处理器，当捕获到信号时，执行对应的处理器；

### 进程间关系

首先，使用`ps -ajx`命令查看所有进程信息，如下：

```Bash
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

#### 进程组（Process Group）

进程组是一个或多个进程的集合。每个进程除了有一个 PID 之外还有一个进程组 ID（GID），每个进程都属于一个进程组，每个进程都有一个组长进程。

如上图中，1 个`PHPServer: master`主进程和 2 个`PHPServer: worker`子进程，属于同一个进程组`11251`，可以看出主进程还是组长进程。

#### 会话（Session）

会话是一个或多个进程组的集合，一个会话有对应的控制终端。如上图中，4 个`PHPServer`进程和`-bash`进程同属于一个会话，因为他们在一个`pts/1`的控制终端。

[需要说明的是]()，当用户退出（Logout）会话以后，系统默认对该会话下的进程进行如下操作：

1. 系统向该会话发出 SIGHUP 信号；
2. 该会话将 SIGHUP 信号发给所有子进程；
3. 子进程收到 SIGHUP 信号后，自动退出；

而对于后台进程，用户在退出时系统默认不会发送 SIGHUP 信号，这是由 Shell 的`huponexit`参数（默认`off`）控制。可通过`shopt -s huponexit`设置成`on`（当前会话有效），此时后台进程会收到 SIGHUP 信号。

## 代码实现

现在，我们用 PHP 做一些简单的进程控制和管理，采用多进程模型实现一个简单的`PHPServer`，基于它你可以做任何事。

完整的源代码，可前往 [fan-haobai/php-server](https://github.com/fan-haobai/php-server) 获取。接下来，就关键的部分进行说明。

### 守护进程

![守护进程流程](https://img0.fanhaobai.com/2018/08/)

先在该进程中`fork`一个子进程，然后该父进程退出，并设置该子进程为会话组长，此时的子进程就会脱离当前终端的控制，进而实现进程的后台运行。代码如下：

```PHP
protected static function daemonize()
{
    umask(0);
    $pid = pcntl_fork();
    if (-1 === $pid) {
        exit("process fork fail\n");
    } elseif ($pid > 0) {
        exit(0);
    }
    
    // 将当前进程提升为会话leader
    if (-1 === posix_setsid()) {
        exit("process setsid fail\n");
    }

    // 再次fork以避免SVR4这种系统终端再一次获取到进程控制
    $pid = pcntl_fork();
    if (-1 === $pid) {
        exit("process fork fail\n");
    } elseif (0 !== $pid) {
        exit(0);
    }
}
```

> 通常在启动时增加`-d`参数，表示进程使用守护态模式启动。

顺利成为一个守护进程后，其已经脱离了终端控制，所以有必要关闭标准输出和标准错误输出。如下：

```PHP
protected static function resetStdFd()
{
    global $STDERR, $STDOUT;
    //重定向标准输出和错误输出
    @fclose(STDOUT);
    fclose(STDERR);
    $STDOUT = fopen(static::$stdoutFile, 'a');
    $STDERR = fopen(static::$stdoutFile, 'a');
}
```

### PID

为了实现`PHPServer`的重载或停止，我们需要将 master 进程的 PID 保存于 PID 文件php-server.pid`中。代码如下：

```PHP
protected static function saveMasterPid()
{
    // 保存pid以实现重载和停止
    static::$_masterPid = posix_getpid();
    if (false === file_put_contents(static::$pidFile, static::$_masterPid)) {
        exit("can not save pid to" . static::$pidFile . "\n");
    }

    echo "PHPServer start\t \033[32m [OK] \033[0m\n";
}
```

### 信号处理器

因为守护进程一旦脱离了终端控制，就犹如一匹脱缰的野马，任由其奔腾可能会为所欲为，所以我们需要去驯服并监控它。这里用信号来处理，代码如下：

```PHP
protected static function installSignal()
{
    pcntl_signal(SIGINT, array('\PHPServer\Worker', 'signalHandler'), false);
    pcntl_signal(SIGTERM, array('\PHPServer\Worker', 'signalHandler'), false);

    pcntl_signal(SIGUSR1, array('\PHPServer\Worker', 'signalHandler'), false);
    pcntl_signal(SIGQUIT, array('\PHPServer\Worker', 'signalHandler'), false);

    // 忽略信号
    pcntl_signal(SIGUSR2, SIG_IGN, false);
    pcntl_signal(SIGHUP,  SIG_IGN, false);
}

protected static function signalHandler($signal)
{
    switch($signal) {
        case SIGINT:
        case SIGTERM:
            static::stop();
            break;
        case SIGQUIT:
        case SIGUSR1:
            static::reload();
            break;
        default: break;
    }
}
```

其中，SIGINT 和 SIGTERM 信号会触发`stop`操作，即终止所有进程；SIGQUIT 和 SIGUSR1 信号会触发`reload`操作，即重新加载所有 worker 进程；忽略了 SIGUSR2 和 SIGHUP 信号，但是并未忽略 SIGKILL 信号，即所有进程都可以被强制 kill 掉。

### 多进程

为了提高业务处理能力和提高可靠性，`PHPServer`由单进程模型演变为经典的多进程模型。其中 master 进程只负责任务调度和 worker 进程监控，而 worker 进程则负责执行具体的业务逻辑。

![多进程模型](https://img0.fanhaobai.com/2018/08/)

可描述为：首先 master 进程完成初始化，然后通过`fork`系统调用，创建多个 worker 进程，并持续监控和管理。

![多进程流程](https://img0.fanhaobai.com/2018/08/)

实现代码，如下：

```PHP
protected static function forkOneWorker()
{
    $pid = pcntl_fork();

    // 父进程
    if ($pid > 0) {
        static::$_workers[] = $pid;
    } else if ($pid === 0) { // 子进程
        static::setProcessTitle('PHPServer: worker');

        // 子进程会阻塞在这里
        static::run();

        // 子进程退出
        exit(0);
    } else {
        throw new \Exception("fork one worker fail");
    }
}

protected static function forkWorkers()
{
    while(count(static::$_workers) < static::$workerCount) {
        static::forkOneWorker();
    }
}
```

其中，`run()`方法会在 worker 进程中执行具体的业务逻辑。这里使用`while`来模拟调度，实际应该使用事件（Select 等）驱动，`pcntl_signal_dispatch()`函数用来在每次任务执行完成后，捕获信号以执行安装的信号处理器，当然 worker 进程会被阻塞于此方法。

```PHP
public static function run()
{
    // 模拟调度,实际用event实现
    while (1) {
        // 捕获信号
        pcntl_signal_dispatch();

        call_user_func(function() {
            // do something
            usleep(200);
        });
    }
}
```

### 进程管理

在通过 PID 文件能确切地知道 master 进程 PID 情况下，可以借助信号进行进程间通信，实现对 master 和 worker 进程的控制。这里只实现了重载和停止进程，并未实现重启进程，但是其可以由停止进程和启动进程两操作组合而成。

#### 停止

![停止流程](https://img0.fanhaobai.com/2018/08/)

给 master 进程发送 SIGINT 或 SIGTERM 信号，master 进程捕获到该信号并执行信号处理器，调用`stop()`方法，如下：

```PHP
protected static function stop()
{
    // 主进程给所有子进程发送退出信号
    if (static::$_masterPid === posix_getpid()) {
        static::stopAllWorkers();

        if (is_file(static::$pidFile)) {
            @unlink(static::$pidFile);
        }
        exit(0);
    } else { // 子进程退出

        // 退出前可以做一些事
        exit(0);
    }
}
```

若是 master 进程执行该方法，会先调用`stopAllWorkers()`方法，向所有的 worker 进程发送 SIGTERM 信号并等待所有 worker  进程终止退出，再删除 PID 文件并退出。有一种特殊情况，worker 进程退出超时时（僵尸进程），master 进程则会再次发送 SIGKILL 信号强制所有 worker 进程退出。

```PHP
protected static function stopAllWorkers()
{
    $allWorkerPid = static::getAllWorkerPid();
    foreach ($allWorkerPid as $workerPid) {
        posix_kill($workerPid, SIGTERM);
    }

    // 子进程退出异常,强制kill
    usleep(1000);
    if (static::isAlive($allWorkerPid)) {
        foreach ($allWorkerPid as $workerPid) {
            static::forceKill($workerPid);
        }
    }

    // 清空worker实例
    static::$_workers = array();
}
```

由于上述过程，master 进程会发送 SIGTERM 信号给 worker 进程，则 worker 进程也会执行该方法，并会直接退出。

#### 重载

![重载流程](https://img0.fanhaobai.com/2018/08/)

给 master 进程发送 SIGQUIT 或 SIGUSR1 信号，master 进程捕获到该信号并执行信号处理器，调用`reload()`方法。先调用`stopAllWorkers()`方法并等待所有 worker 退出，然后再调用`forkWorkers()`方法重新创建所有 worker 进程。如下：

```PHP
protected static function reload()
{
    static::stopAllWorkers();

    $allWorkPid = static::getAllWorkerPid();
    while (static::isAlive($allWorkPid)) {
        usleep(10);
    }

    static::forkWorkers();
}
```

> `reload()`方法只会在 master 进程中执行。

该过程，因为只是所有 worker 进程退出，并 fork 了新的 worker 进程，所以 master 进程 PID 并不会发生变化。代码发布后，需要使用该操作进行重新加载。

#### worker进程异常退出

由于 worker 进程执行繁重的业务逻辑，所以很有可能会异常崩溃，因此 master 进程需要监控 worker 进程健康状态，并维持一定数量的 worker 进程。

![异常退出处理流程](https://img0.fanhaobai.com/2018/08/)

代码实现，如下：

```PHP
protected static function keepWorkerNumber()
{
    $allWorkerPid = static::getAllWorkerPid();
    foreach ($allWorkerPid as $index => $pid) {
        if (!static::isAlive($pid)) {
            unset(static::$_workers[$index]);
        }
    }

    static::forkWorkers();
}
```

## 总结

我们已经实现了一个简易的 [PHPServer]((https://github.com/fan-haobai/php-server)，模拟了进程的管理与控制。需要说明的是，master 进程可能偶尔会异常地崩溃，为了避免这种情况的发生：

首先，我们不应该给 master 进程分配繁重的任务，它更适合做一些类似于调度和管理性质的工作；
其次，可以使用 [Supervisor](https://www.fanhaobai.com/2017/09/supervisor.html) 等工具来管理我们的程序，当 master 进程异常崩溃时，可以再次尝试被拉起，避免 master 进程异常退出的情况发生。