---
title: 怎么用PHP玩转进程之二 — 多进程PHPServer
date: 2018-09-02 16:10:53
tags:
- 系统设计
categories:
- 语言
- PHP
---

经过 [怎么用PHP玩转进程之一 — 基础](https://www.fanhaobai.com/2018/08/process-php-basic-knowledge.html) 的回顾复习，我们已经掌握了进程的基础知识，现在可以尝试用 PHP 做一些简单的进程控制和管理，来加深我们对进程的理解。接下来，我将用多进程模型实现一个简单的`PHPServer`，基于它你可以做任何事。

![预览图](https://img0.fanhaobai.com/2018/09/process-php-multiprocess-server/34f35d33-57b2-41d7-b738-f0c1c712102f.png)

完整的源代码，可前往 [fan-haobai/php-server](https://github.com/fan-haobai/php-server) 获取。

### 总流程

master 和 worker 进程主要控制流程，如下图：

![master控制流程](https://img0.fanhaobai.com/2018/09/process-php-multiprocess-server/)

![worker控制流程](https://img0.fanhaobai.com/2018/09/process-php-multiprocess-server/)

### 守护进程

![守护进程流程](https://img0.fanhaobai.com/2018/09/process-php-multiprocess-server/)

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

其中 master 进程只负责任务调度和 worker 进程监控，而 worker 进程则负责执行具体的业务逻辑。首先 master 进程完成初始化，然后通过`fork`系统调用，创建多个 worker 进程，并持续监控和管理。

![多进程流程](https://img0.fanhaobai.com/2018/09/process-php-multiprocess-server/)

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

```PHP
protected static function monitor()
{
    while (1) {
        // 这两处捕获触发信号,很重要
        pcntl_signal_dispatch();
        // 挂起当前进程的执行直到一个子进程退出或接收到一个信号
        $status = 0;
        $pid = pcntl_wait($status, WUNTRACED);
        pcntl_signal_dispatch();

        if ($pid >= 0) {
            // worker异常退出
            static::keepWorkerNumber();
        }
        // 其他你想监控的
    }
}
```

#### 停止

![停止流程](https://img0.fanhaobai.com/2018/09/process-php-multiprocess-server/)

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

![重载流程](https://img0.fanhaobai.com/2018/09/process-php-multiprocess-server/)

给 master 进程发送 SIGQUIT 或 SIGUSR1 信号，master 进程捕获到该信号并执行信号处理器，调用`reload()`方法。先调用`stopAllWorkers()`方法并等待所有 worker 退出，然后再调用`forkWorkers()`方法重新创建所有 worker 进程。如下：

```PHP
protected static function reload()
{
    // 停止所有worker即可,master会自动fork新worker
    static::stopAllWorkers();
}
```

> `reload()`方法只会在 master 进程中执行，因为 SIGQUIT 和 SIGUSR1 信号不会发送给 worker 进程。

该过程，因为只是所有 worker 进程退出，并 fork 了新的 worker 进程，所以 master 进程 PID 并不会发生变化。代码发布后，需要使用该操作进行重新加载。

#### worker进程异常退出

由于 worker 进程执行繁重的业务逻辑，所以很有可能会异常崩溃，因此 master 进程需要监控 worker 进程健康状态，并维持一定数量的 worker 进程。

![异常退出处理流程](https://img0.fanhaobai.com/2018/09/process-php-multiprocess-server/)

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

我们已经实现了一个简易的多进程 [PHPServer]((https://github.com/fan-haobai/php-server)，模拟了进程的管理与控制。需要说明的是，master 进程可能偶尔会异常地崩溃，为了避免这种情况的发生：

首先，我们不应该给 master 进程分配繁重的任务，它更适合做一些类似于调度和管理性质的工作；
其次，可以使用 [Supervisor](https://www.fanhaobai.com/2017/09/supervisor.html) 等工具来管理我们的程序，当 master 进程异常崩溃时，可以再次尝试被拉起，避免 master 进程异常退出的情况发生。

<strong>相关文章 [»]()</strong>

* [怎么用PHP玩转进程之一 — 基础](https://www.fanhaobai.com/2018/08/process-php-basic-knowledge.html) <span>（2018-08-28）</span>