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

可以说，工作中我们接触最多的就是 [进程]()（我们代码的载体），但是我们往往对它又比较陌生，因为它是业务代码不需要关心的地方，既有的公有组件和操作系统已经对我们屏蔽了进程的复杂性，但是跟它的接触时间一长，我们难免会对它产生好奇：How it work?

![预览图](https://img0.fanhaobai.com/2018/08/f6eb7888-6de6-41a4-8d15-4d471825a24e.jpg)<!--more--> 

## 进程基础概念

进程是操作系统的一个核心，每个进程都有自己唯一标识，即 PID。同时，每个进程都有父进程，这些父进程也有父进程，所有进程都是 init 进程的子进程，并且 init 进程的 PID 为 `1`。

### 进程分类

#### 前台进程

前台进程具有控制终端，并会堵塞控制终端。它的特点是：

* 可以同用户交互，但容易被终止；
* 有较高的响应速度，且优先级别稍高。

```Bash
$ php server.php start
PHPServer start	  [OK] 

# 堵塞了 /_ \
```

通常，在控制终端使用`Ctrl+z`组合键，即可导致这些进程终止退出。

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

信号是进程间通信的一种机制。因此我们可以向进程发送特定的信号，来控制进程的行为。

#### 常用的信号值

在 Linux 系统中共有 62 个信号值，可使用`kill -l`命令查看，其中部分常用值如下： 

|  信号名称 |    值   |        说明        |   进程默认行为  |
| -------- | ------ | ------------------ | --------------|
|  SIGHUP |   1    | 终端挂起或控制进程终止信号 |    终止进程    |
|  SIGINT |   2    | 键盘Ctrl+C被按下信号     |    终止进程    |
|  SIGQUIT |   3    | 键盘Ctrl+\被按下信号    |    终止进程并产生core-dumped|
|  SIGKILL |   9    | 立即终止进程信号         |    终止进程    |
| SIGUSR1  |   10   | 用户定义的信号           |    终止进程    |
|  SIGUSR2 |   12   | 用户定义的信号           |    终止进程    |
|  SIGALRM |   14   | 定时器超时信号           |    终止进程    |
|  SIGTERM |   15   | 程序结束信号             |    终止进程    |
|  SIGCHLD |   16   | 子进程结束信号           |    忽略信号    |

#### 产生信号

实际中，硬件或者软件中断都会触发信号，但是这里只列举两种常用的信号产生方式。

* 终端按键

|    按键/命令       |     信号名称      |
| ----------------- | ---------------- |
|     Ctrl+C        |      SIGINT      |
|     Ctrl+\        |     SIGQUIT      |
|     EXIT          |      SIGHUP      |

* 系统调用

通过`kill`系统调用发送信号。例如，在 Shell 中使用`kill -9`发送 SIGKILL 信号；又如，发送编号为`0`的信号来 [检测该进程是否存在]()：

```PHP
$pid = 577;
if (posix_kill($pid, 0)) {
    echo "进程存在\n";
} else {
    echo "进程不存在\n";
}
```

#### 进程的处理方式

对于信号，进程共有 3 种处理方式：

* 默认行为——主要有终止进程、忽略信号、重启或暂停进程，见 [常用的信号值](#常用的信号值) 默认行为部分；
* 忽略；
* 捕获并处理——先注册信号处理器，当捕获到信号时，执行对应的处理器；

### 进程间关系

首先，使用`ps -ajx`命令查看所有进程信息，如下：

```Bash
#父PID  PID  组ID 会话ID 终端  时间   名称
PPID   PID  PGID   SID TTY   TIME COMMAND
    0     1     1     1 ?     0:00 /init ro
    1    43    43    43 ?     0:00 /usr/sbin/sshd
   43 11134 11134 11134 ?     0:00 sshd: root@pts/1
11134 11169 11169 11169 pts/1 0:00 -bash
11169 11251 11251 11169 pts/1 0:00 PHPServer: master   
11251 11252 11251 11169 pts/1 0:36 PHPServer: worker   
11251 11253 11251 11169 pts/1 0:42 PHPServer: worker   
```

#### 进程组（Process Group）

进程组是一个或多个进程的集合。每个进程除了有一个 PID 之外还有一个进程组 ID（GID），每个进程都属于一个进程组，每个进程都有一个组长进程。

如上图中，1 个`PHPServer: master`主进程和 2 个`PHPServer: worker`子进程，属于同一个进程组`11251`，可以看出主进程是组长进程。

#### 会话（Session）

会话是一个或多个进程组的集合，一个会话存在对应的控制终端。如上图中，4 个`PHPServer`进程和`-bash`进程同属于一个会话，因为他们在一个`pts/1`终端控制。

[需要说明的是]()，当用户退出（Logout）会话以后，系统默认对该会话下进程进行如下操作：

1. 系统向该会话发出 SIGHUP 信号；
2. 该会话将 SIGHUP 信号发给所有子进程；
3. 子进程收到 SIGHUP 信号后，自动退出；

而对于后台进程，用户在退出时系统默认不会发送 SIGHUP 信号，这是由 Shell 的`huponexit`参数（默认`off`）控制。可通过`shopt -s huponexit`设置成`on`（当前会话有效），此时后台进程也会收到 SIGHUP 信号。

## 代码实现

现在，我们用 PHP 做一些简单的进程控制和管理，采用多进程模型实现一个简单的`PHPServer`，基于它你可以做任何事。

完整的源代码，可前往 [fan-haobai/php-server](https://github.com/fan-haobai/php-server) 获取。接下来，就关键的部分来进行说明。

### 守护进程

![守护进程流程](https://img0.fanhaobai.com/2018/08/)

实现守护进程的大致思路为：在该进程中`fork`一个子进程，该进程退出，此时的子进程会脱离当前终端的控制，进而实现进程的后台运行。

代码为：

```PHP
/**
 * 守护态运行.
 */
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

> 通常在启动时使用`-d`参数，表示进程使用守护态模式启动。

当顺利成为一个守护进程后，实际已经脱离了终端控制，所以有必要关闭标准输出和标准错误输出。如下：

```PHP
/**
 * 关闭标准输出和错误输出.
 */
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

为了实现`PHPServer`进程的管理，如重载或者停止，我们需要将 master 进程的 PID 保存于 PID 文件中，如`php-server.pid`。代码如下：

```PHP
/**
 * 保存master进程pid以实现stop和reload
 */
protected static function saveMasterPid()
{
    // 保存pid以实现重启和停止
    static::$_masterPid = posix_getpid();
    if (false === file_put_contents(static::$pidFile, static::$_masterPid)) {
        exit("can not save pid to" . static::$pidFile . "\n");
    }

    echo "PHPServer start\t \033[32m [OK] \033[0m\n";
}
```

### 信号处理器

因为守护进程脱离了终端控制，就犹如一匹脱缰的野马，任由其奔跑可能会为所欲为，所以我们需要去驯服并监控它。这其实是一个典型的进程间通信的场景，当然可以借助于信号来完成。

代码如下：

```PHP
/**
 * 安装信号处理器.
 */
protected static function installSignal()
{
    // SIGINT
    pcntl_signal(SIGINT, array('\PHPServer\Worker', 'signalHandler'), false);
    // SIGTERM
    pcntl_signal(SIGTERM, array('\PHPServer\Worker', 'signalHandler'), false);

    // SIGUSR1
    pcntl_signal(SIGUSR1, array('\PHPServer\Worker', 'signalHandler'), false);
    // SIGQUIT
    pcntl_signal(SIGQUIT, array('\PHPServer\Worker', 'signalHandler'), false);

    // 忽略信号
    pcntl_signal(SIGUSR2, SIG_IGN, false);
    pcntl_signal(SIGHUP,  SIG_IGN, false);
    pcntl_signal(SIGPIPE, SIG_IGN, false);
}

/**
 * 信号处理器.
 *
 * @param integer $signal 信号.
 */
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

其中，SIGINT 和 SIGTERM 信号会触发`stop`操作，即终止所有进程；SIGQUIT 和 SIGUSR1 信号会触发`reload`操作，即重新加载子进程，该操作 master 进程 PID 并不会发生变化，因为只是 fork 了新的 worker 进程。

### 多进程

为了提高业务处理能力和提高可靠性，我们的`PHPServer`由单进程模型演变为多进程模型。其中 master 进程只负责任务调度和 worker 进程监控，而 worker 进程负责执行具体的业务逻辑。

![多进程模型](https://img0.fanhaobai.com/2018/08/)

多进程实现流程可描述为：首先，master 进程完成初始化，然后通过`fork`系统调用，创建多个 worker 进程，并持续监控和调度。流程图如下：

![多进程流程](https://img0.fanhaobai.com/2018/08/)

代码为：

```PHP
/**
 * 创建一个worker进程.
 */
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

/**
 * 创建所有worker进程.
 */
protected static function forkWorkers()
{
    while(count(static::$_workers) < static::$workCount) {
        static::forkOneWorker();
    }
}
```

其中，`run()`方法会在 worker 进程中执行具体的业务逻辑。这里使用`while`来模拟调度任务，实际应该使用事件（Select 等）驱动，`pcntl_signal_dispatch()`用来在每次任务执行完成后，捕获信号以执行注册的信号处理器，当然 worker 进程会被阻塞于方法。

实现如下：

```PHP
/**
 * worker进程任务.
 */
public static function run()
{
    static::$status = static::STATUS_RUNNING;

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

在确切知道 master 进程 PID 情况下，可以借助于信号来进行进程间通信，以实现 master 和 worker 进程的控制。

#### 重载

#### 停止

#### worker进程异常退出

由于 worker 进程需要执行繁重的业务逻辑，所以很有可能会因为异常导致崩溃，因此 master 进程需要监控 worker 进程健康状态，并维持一定数量的 worker 进程。

代码如下：

```PHP
/**
 * 维持worker进程数量,防止worker异常退出
 */
protected static function keepWorkerNumber()
{
    $allWorkPid = static::getAllWorkerPid();
    foreach ($allWorkPid as $index => $pid) {
        if (!static::isAlive($pid)) {
            unset(static::$_workers[$index]);
        }
    }

    static::forkWorkers();
}
```

到这里，并未实现进程状态的监控，可以实现为： master 进程通过特定信号获取 worker 进程状态，然后将所有 worker 进程的状态保存至状态文件中，后续只需读取状态文件即可。

## 总结

尽管我们已经实现了一个守护态的 master 进程，但是它偶尔也会不知原因的崩溃，这在生产环境会导致严重的事故。为了避免这种情况的发生：

首先，我们不应该给 master 进程分配繁重的任务，它更适合做一些类似于调度和管理性质的工作；

其次，可以使用 [Supervisor](https://www.fanhaobai.com/2017/09/supervisor.html) 等工具来管理我们的程序，当 master 进程异常崩溃时，可以再次尝试被拉起，避免 master 进程异常退出的情况发生。