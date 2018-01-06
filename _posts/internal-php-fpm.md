---
title: 深入源码剖析PHP-FPM
date: 2017-10-30 15:03:36
tags:
- PHP
categories:
- 语言
- PHP
---

> 原文：https://github.com/pangudashu/php7-internal/blob/master/1/fpm.md

FPM（FastCGI Process Manager）是 PHP FastCGI 运行模式的一个进程管理器，从它的定义可以看出，FPM 的核心功能是进程管理，那么它用来管理什么进程呢？这个问题就需要从 FastCGI 说起了。![](https://img.fanhaobai.com/2017/10/internal-php-fpm/2ed1b400-61ae-cdbe-405a-8353ab28aa74.png)<!--more-->

## 概述

FastCGI 是 Web 服务器（如：Nginx、Apache）和处理程序之间的一种通信协议，它是与 Http 类似的一种应用层通信协议，注意：它只是一种协议！

前面曾一再强调，PHP 只是一个脚本解析器，你可以把它理解为一个普通的函数，输入是 PHP 脚本。输出是执行结果，假如我们想用 PHP 代替 shell，在命令行中执行一个文件，那么就可以写一个程序来嵌入 PHP 解析器，这就是 cli 模式，这种模式下 PHP 就是普通的一个命令工具。接着我们又想：能不能让 PHP 处理 http 请求呢？这时就涉及到了网络处理，PHP 需要接收请求、解析协议，然后处理完成返回请求。在网络应用场景下，PHP 并没有像 Golang 那样实现 http 网络库，而是实现了 FastCGI 协议，然后与 web 服务器配合实现了 http 的处理，web 服务器来处理 http 请求，然后将解析的结果再通过 FastCGI 协议转发给处理程序，处理程序处理完成后将结果返回给 web 服务器，web 服务器再返回给用户，如下图所示。

![](https://img.fanhaobai.com/2017/10/internal-php-fpm/2ed1b400-61ae-cdbe-405a-8353ab28aa74.png)

PHP 实现了 FastCGI 协议的解析，但是并没有具体实现网络处理，一般的处理模型：多进程、多线程，多进程模型通常是主进程只负责管理子进程，而基本的网络事件由各个子进程处理，nginx、fpm 就是这种模式；另一种多线程模型与多进程类似，只是它是线程粒度，通常会由主线程监听、接收请求，然后交由子线程处理，memcached 就是这种模式，有的也是采用多进程那种模式：主线程只负责管理子线程不处理网络事件，各个子线程监听、接收、处理请求，memcached 使用 udp 协议时采用的是这种模式。

## 基本实现

概括来说，fpm 的实现就是创建一个 master 进程，在 master 进程中创建并监听 socket，然后 fork 出多个子进程，这些子进程各自 accept 请求，子进程的处理非常简单，它在启动后阻塞在 accept 上，有请求到达后开始读取请求数据，读取完成后开始处理然后再返回，在这期间是不会接收其它请求的，也就是说 fpm 的子进程同时只能响应一个请求，只有把这个请求处理完成后才会 accept 下一个请求，这一点与 nginx 的事件驱动有很大的区别，nginx 的子进程通过 epoll 管理套接字，如果一个请求数据还未发送完成则会处理下一个请求，即一个进程会同时连接多个请求，它是非阻塞的模型，只处理活跃的套接字。

fpm 的 master 进程与 worker 进程之间不会直接进行通信，master 通过共享内存获取 worker 进程的信息，比如 worker 进程当前状态、已处理请求数等，当 master 进程要杀掉一个 worker 进程时则通过发送信号的方式通知 worker 进程。

fpm 可以同时监听多个端口，每个端口对应一个 worker pool，而每个 pool 下对应多个 worker 进程，类似 nginx 中 server 概念。

![](https://img.fanhaobai.com/2017/10/internal-php-fpm/cf7663c1-850b-43b3-abfa-566fcfc79b29.png)

在 php-fpm.conf 中通过`[pool name]`声明一个 worker pool：

```Bash
[web1]
listen = 127.0.0.1:9000
...

[web2]
listen = 127.0.0.1:9001
...
```

启动 fpm 后查看进程：

```Bash
$ ps -aux|grep fpm
root     27155  0.0  0.1 144704  2720 ?  Ss   15:16   0:00 php-fpm: master process (/usr/local/php7/etc/php-fpm.conf)
nobody   27156  0.0  0.1 144676  2416 ?  S    15:16   0:00 php-fpm: pool web1
nobody   27157  0.0  0.1 144676  2416 ?  S    15:16   0:00 php-fpm: pool web1
nobody   27159  0.0  0.1 144680  2376 ?  S    15:16   0:00 php-fpm: pool web2
nobody   27160  0.0  0.1 144680  2376 ?  S    15:16   0:00 php-fpm: pool web2
```

具体实现上 worker pool 通过`fpm_worker_pool_s`这个结构表示，多个 worker pool 组成一个单链表：

```c
struct fpm_worker_pool_s {
    struct fpm_worker_pool_s *next; //指向下一个worker pool
    struct fpm_worker_pool_config_s *config; //conf配置:pm、max_children、start_servers...
    int listening_socket; //监听的套接字
    ...

    //以下这个值用于master定时检查、记录worker数
    struct fpm_child_s *children; //当前pool的worker链表
    int running_children; //当前pool的worker运行总数
    int idle_spawn_rate;
    int warn_max_children;

    struct fpm_scoreboard_s *scoreboard; //记录worker的运行信息，比如空闲、忙碌worker数
    ...
}
```

## FPM的初始化

接下来看下 fpm 的启动流程，从`main()`函数开始：

```c
//sapi/fpm/fpm/fpm_main.c
int main(int argc, char *argv[])
{
    ...
    //注册SAPI:将全局变量sapi_module设置为cgi_sapi_module
    sapi_startup(&cgi_sapi_module);
    ...
    //执行php_module_starup()
    if (cgi_sapi_module.startup(&cgi_sapi_module) == FAILURE) {
        return FPM_EXIT_SOFTWARE;
    }
    ...
    //初始化
    if(0 > fpm_init(...)){
        ...
    }
    ...
    fpm_is_running = 1;

    fcgi_fd = fpm_run(&max_requests);//后面都是worker进程的操作，master进程不会走到下面
    parent = 0;
    ...
}
```

`fpm_init()`主要有以下几个关键操作：

__(1) fpm_conf_init_main():__ 

解析 php-fpm.conf  配置文件，分配 worker pool 内存结构并保存到全局变量中：fpm_worker_all_pools，各 worker pool 配置解析到`fpm_worker_pool_s->config`中。

__(2)fpm_scoreboard_init_main():__ 

分配用于记录 worker 进程运行信息的共享内存，按照 worker pool 的最大 worker 进程数分配，每个 worker pool 分配一个`fpm_scoreboard_s`结构，pool 下对应的每个 worker 进程分配一个`fpm_scoreboard_proc_s`结构，各结构的对应关系如下图。

![](https://img.fanhaobai.com/2017/10/internal-php-fpm/9d9d0bb5-d970-4536-aa55-0f885648e551.png)

__(3)fpm_signals_init_main():__ 

```c
static int sp[2];

int fpm_signals_init_main()
{
    struct sigaction act;

    //创建一个全双工管道
    if (0 > socketpair(AF_UNIX, SOCK_STREAM, 0, sp)) {
        return -1;
    }
    //注册信号处理handler
    act.sa_handler = sig_handler;
    sigfillset(&act.sa_mask);
    if (0 > sigaction(SIGTERM,  &act, 0) ||
        0 > sigaction(SIGINT,   &act, 0) ||
        0 > sigaction(SIGUSR1,  &act, 0) ||
        0 > sigaction(SIGUSR2,  &act, 0) ||
        0 > sigaction(SIGCHLD,  &act, 0) ||
        0 > sigaction(SIGQUIT,  &act, 0)) {
        return -1;
    }
    return 0;
}
```

这里会通过`socketpair()`创建一个管道，这个管道并不是用于 master 与 worker 进程通信的，它只在 master 进程中使用，具体用途在稍后介绍 event 事件处理时再作说明。另外设置 master 的信号处理 handler，当 master 收到 SIGTERM、SIGINT、SIGUSR1、SIGUSR2、SIGCHLD、SIGQUIT 这些信号时将调用`sig_handler()`处理：

```c
static void sig_handler(int signo)
{
    static const char sig_chars[NSIG + 1] = {
        [SIGTERM] = 'T',
        [SIGINT]  = 'I',
        [SIGUSR1] = '1',
        [SIGUSR2] = '2',
        [SIGQUIT] = 'Q',
        [SIGCHLD] = 'C'
    };
    char s;
    ...
    s = sig_chars[signo];
    //将信号通知写入管道sp[1]端
    write(sp[1], &s, sizeof(s));
    ...
}
```

__(4)fpm_sockets_init_main()__

创建每个 worker pool 的 socket 套接字。

__(5)fpm_event_init_main():__

启动 master 的事件管理，fpm 实现了一个事件管理器用于管理 IO、定时事件，其中 IO 事件通过 kqueue、epoll、poll、select 等管理，定时事件就是定时器，一定时间后触发某个事件。

在`fpm_init()`初始化完成后接下来就是最关键的`fpm_run()`操作了，此环节将 fork 子进程，启动进程管理器，另外 master 进程将不会再返回，只有各 worker 进程会返回，也就是说`fpm_run()`之后的操作均是 worker 进程的。

```c
int fpm_run(int *max_requests)
{
    struct fpm_worker_pool_s *wp;
    for (wp = fpm_worker_all_pools; wp; wp = wp->next) {
        //调用fpm_children_make() fork子进程
        is_parent = fpm_children_create_initial(wp);
        
        if (!is_parent) {
            goto run_child;
        }
    }
    //master进程将进入event循环，不再往下走
    fpm_event_loop(0);

run_child: //只有worker进程会到这里

    *max_requests = fpm_globals.max_requests;
    return fpm_globals.listening_socket; //返回监听的套接字
}
```

在 fork 后 worker 进程返回了监听的套接字继续 main() 后面的处理，而 master 将永远阻塞在`fpm_event_loop()`，接下来分别介绍 master、worker 进程的后续操作。

## 请求处理

`fpm_run()`执行后将 fork 出 worker 进程，worker 进程返回`main()`中继续向下执行，后面的流程就是 worker 进程不断 accept 请求，然后执行 PHP 脚本并返回。整体流程如下：

* __(1)等待请求：__ worker 进程阻塞在 fcgi_accept_request() 等待请求；
* __(2)解析请求：__ fastcgi 请求到达后被 worker 接收，然后开始接收并解析请求数据，直到 request 数据完全到达；
* __(3)请求初始化：__ 执行 php_request_startup()，此阶段会调用每个扩展的：PHP_RINIT_FUNCTION()；
* __(4)编译、执行：__ 由 php_execute_script() 完成 PHP 脚本的编译、执行；
* __(5)关闭请求：__ 请求完成后执行 php_request_shutdown()，此阶段会调用每个扩展的：PHP_RSHUTDOWN_FUNCTION()，然后进入步骤 (1) 等待下一个请求。

```c
int main(int argc, char *argv[])
{
    ...
    fcgi_fd = fpm_run(&max_requests);
    parent = 0;

    //初始化fastcgi请求
    request = fpm_init_request(fcgi_fd);
    
    //worker进程将阻塞在这，等待请求
    while (EXPECTED(fcgi_accept_request(request) >= 0)) {
        SG(server_context) = (void *) request;
        init_request_info();
        
        //请求开始
        if (UNEXPECTED(php_request_startup() == FAILURE)) {
            ...
        }
        ...

        fpm_request_executing();
        //编译、执行PHP脚本
        php_execute_script(&file_handle);
        ...
        //请求结束
        php_request_shutdown((void *) 0);
        ...
    }
    ...
    //worker进程退出
    php_module_shutdown();
    ...
}
```

worker 进程一次请求的处理被划分为 5 个阶段：

* __FPM_REQUEST_ACCEPTING:__ 等待请求阶段
* __FPM_REQUEST_READING_HEADERS:__ 读取 fastcgi 请求 header 阶段
* __FPM_REQUEST_INFO:__ 获取请求信息阶段，此阶段是将请求的 method、query stirng、request uri 等信息保存到各 worker 进程的 fpm_scoreboard_proc_s 结构中，此操作需要加锁，因为 master 进程也会操作此结构
* __FPM_REQUEST_EXECUTING:__ 执行请求阶段
* __FPM_REQUEST_END:__ 没有使用
* __FPM_REQUEST_FINISHED:__ 请求处理完成

worker 处理到各个阶段时将会把当前阶段更新到`fpm_scoreboard_proc_s->request_stage`，master 进程正是通过这个标识判断 worker 进程是否空闲的。

## 进程管理

这一节我们来看下 master 是如何管理 worker 进程的，首先介绍下三种不同的进程管理方式：

* __static:__ 这种方式比较简单，在启动时 master 按照`pm.max_children`配置 fork 出相应数量的 worker 进程，即 worker 进程数是固定不变的；
* __dynamic:__ 动态进程管理，首先在 fpm 启动时按照`pm.start_servers`初始化一定数量的 worker，运行期间如果 master 发现空闲 worker 数低于`pm.min_spare_servers`配置数（表示请求比较多，worker 处理不过来了）则会 fork worker 进程，但总的 worker 数不能超过`pm.max_children`，如果 master 发现空闲 worker 数超过了`pm.max_spare_servers`(表示闲着的 worker 太多了)则会杀掉一些 worker，避免占用过多资源，master 通过这 4 个值来控制 worker 数；
* __ondemand:__ 这种方式一般很少用，在启动时不分配 worker 进程，等到有请求了后再通知 master 进程 fork worker 进程，总的 worker 数不超过`pm.max_children`，处理完成后 worker 进程不会立即退出，当空闲时间超过`pm.process_idle_timeout`后再退出；

前面介绍到在`fpm_run()`中 master 进程将进入`fpm_event_loop()`：

```c
void fpm_event_loop(int err)
{
    //创建一个io read的监听事件，这里监听的就是在fpm_init()阶段中通过socketpair()创建管道sp[0]
    //当sp[0]可读时将回调fpm_got_signal()
    fpm_event_set(&signal_fd_event, fpm_signals_get_fd(), FPM_EV_READ, &fpm_got_signal, NULL);
    fpm_event_add(&signal_fd_event, 0);

    //如果在php-fpm.conf配置了request_terminate_timeout则启动心跳检查
    if (fpm_globals.heartbeat > 0) {
        fpm_pctl_heartbeat(NULL, 0, NULL);
    }
    //定时触发进程管理
    fpm_pctl_perform_idle_server_maintenance_heartbeat(NULL, 0, NULL);
    
    //进入事件循环，master进程将阻塞在此
    while (1) {
        ...
        //等待IO事件
        ret = module->wait(fpm_event_queue_fd, timeout);
        ...
        //检查定时器事件
        ...
    }
}
```

这就是 master 整体的处理，其进程管理主要依赖注册的几个事件，接下来我们详细分析下这几个事件的功能。

__(1)sp[1]管道可读事件：__ 

在`fpm_init()`阶段 master 曾创建了一个全双工的管道：sp，然后在这里创建了一个 sp[0] 可读的事件，当 sp[0] 可读时将交由`fpm_got_signal()`处理，向 sp[1] 写数据时 sp[0] 才会可读，那么什么时机会向 sp[1] 写数据呢？前面已经提到了：当 master 收到注册的那几种信号时会写入 sp[1] 端，这个时候将触发 sp[0] 可读事件。

![](https://img.fanhaobai.com/2017/10/internal-php-fpm/1a1eb0c1-d2f3-4b98-aee6-5603ca924b3c.png)

这个事件是 master 用于处理信号的，我们根据 master 注册的信号逐个看下不同用途：

* __SIGINT/SIGTERM/SIGQUIT:__ 退出 fpm，在 master 收到退出信号后将向所有的 worker 进程发送退出信号，然后 master 退出；
* __SIGUSR1:__ 重新加载日志文件，生产环境中通常会对日志进行切割，切割后会生成一个新的日志文件，如果 fpm 不重新加载将无法继续写入日志，这个时候就需要向 master 发送一个 USR1 的信号；
* __SIGUSR2:__ 重启 fpm，首先 master 也是会向所有的 worker 进程发送退出信号，然后 master 会调用 execvp() 重新启动 fpm ，最后旧的 master 退出；
* __SIGCHLD:__ 这个信号是子进程退出时操作系统发送给父进程的，子进程退出时，内核将子进程置为僵尸状态，这个进程称为僵尸进程，它只保留最小的一些内核数据结构，以便父进程查询子进程的退出状态，只有当父进程调用 wait 或者 waitpid 函数查询子进程退出状态后子进程才告终止， fpm 中当 worker 进程因为异常原因（比如 coredump 了）退出而非 master 主动杀掉时 master 将受到此信号，这个时候父进程将调用 waitpid() 查下子进程的退出，然后检查下是不是需要重新 fork 新的 worker；

具体处理逻辑在`fpm_got_signal()`函数中，这里不再罗列。

__(2)fpm_pctl_perform_idle_server_maintenance_heartbeat():__

这是进程管理实现的主要事件，master 启动了一个定时器，每隔 1s 触发一次，主要用于 dynamic、ondemand 模式下的 worker 管理，master 会定时检查各 worker pool 的 worker 进程数，通过此定时器实现 worker 数量的控制，处理逻辑如下：

```c
static void fpm_pctl_perform_idle_server_maintenance(struct timeval *now)
{
    for (wp = fpm_worker_all_pools; wp; wp = wp->next) {
        struct fpm_child_s *last_idle_child = NULL; //空闲时间最久的worker
        int idle = 0; //空闲worker数
        int active = 0; //忙碌worker数
        
        for (child = wp->children; child; child = child->next) {
            //根据worker进程的fpm_scoreboard_proc_s->request_stage判断
            if (fpm_request_is_idle(child)) {
                //找空闲时间最久的worker
                ...
                idle++;
            }else{
                active++;
            }
        }
        ...
        //ondemand模式
        if (wp->config->pm == PM_STYLE_ONDEMAND) {
            if (!last_idle_child) continue;

            fpm_request_last_activity(last_idle_child, &last);
            fpm_clock_get(&now);
            if (last.tv_sec < now.tv_sec - wp->config->pm_process_idle_timeout) {
                //如果空闲时间最长的worker空闲时间超过了process_idle_timeout则杀掉该worker
                last_idle_child->idle_kill = 1;
                fpm_pctl_kill(last_idle_child->pid, FPM_PCTL_QUIT);
            } 
            continue;
        }
        //dynamic
        if (wp->config->pm != PM_STYLE_DYNAMIC) continue;
        if (idle > wp->config->pm_max_spare_servers && last_idle_child) {
            //空闲worker太多了，杀掉
            last_idle_child->idle_kill = 1;
            fpm_pctl_kill(last_idle_child->pid, FPM_PCTL_QUIT);
            wp->idle_spawn_rate = 1;
            continue;
        }
        if (idle < wp->config->pm_min_spare_servers) {
            //空闲worker太少了，如果总worker数未达到max数则fork
            ...
        }
    }
}
```

__(3)fpm_pctl_heartbeat():__

这个事件是用于限制 worker 处理单个请求最大耗时的，`php-fpm.conf` 中有一个`request_terminate_timeout`的配置项，如果 worker 处理一个请求的总时长超过了这个值那么 master 将会向此 worker 进程发送`kill -TERM`信号杀掉 worker 进程，此配置单位为秒，默认值为 0 表示关闭此机制，另外 fpm 打印的 slow log 也是在这里完成的。

```c
static void fpm_pctl_check_request_timeout(struct timeval *now)
{   
    struct fpm_worker_pool_s *wp;

    for (wp = fpm_worker_all_pools; wp; wp = wp->next) {
        int terminate_timeout = wp->config->request_terminate_timeout;
        int slowlog_timeout = wp->config->request_slowlog_timeout;
        struct fpm_child_s *child;

        if (terminate_timeout || slowlog_timeout) { 
            for (child = wp->children; child; child = child->next) {
                //检查当前当前worker处理的请求是否超时
                fpm_request_check_timed_out(child, now, terminate_timeout, slowlog_timeout);
            }
        }
    }
}
```

除了上面这几个事件外还有一个没有提到，那就是 ondemand 模式下 master 监听的新请求到达的事件，因为 ondemand 模式下 fpm 启动时是不会预创建 worker 的，有请求时才会生成子进程，所以请求到达时需要通知 master 进程，这个事件是在`fpm_children_create_initial()`时注册的，事件处理函数为`fpm_pctl_on_socket_accept()`，具体逻辑这里不再展开，比较容易理解。

到目前为止我们已经把 fpm 的核心实现介绍完了，事实上 fpm 的实现还是比较简单的。
