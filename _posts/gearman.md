---
title: Gearman的安装和使用
date: 2017-08-27 10:42:43
tags:
- Gearman
categories:
- 分布式
---

[Gearman](http://gearman.org/) 是一个分布式任务分发系统，通过程序调用（API，跨语言）分布式地把工作委派给更适合做某项工作的机器，且这些机器可以以并发的、负载均衡的形式来共同完成某项工作。当计算密集型场景时，适合在后台使用 Gearman 异步地运行工作任务。

![](/2017/08/gearman/498077-20170609175022497-2018362409.png)<!--more-->

## 认识Gearman

Gearman 只是一个分布式程序调用框架，其主要由三部分组成，并通过暴露给使用方的 API 来完成任务委派和执行。 

### 组成角色

Gearman 中存在三个重要的角色，分别为 Client、Job Server、Worker。
* Client：任务的发起者（可以是 C、PHP、Java、Perl、MySQL 等）；
* Job Server：任务调度者，负责将 Client 委派的任务转发给相应的 Worker（gearmand 进程管理）；
* Worker：任务的实际执行者（可以是 C、PHP、Java、Perl 等）；

Client、Job Server、Worker 典型的部署方案，如下图：

![](/2017/08/gearman/441bacc1-54d1-4ac8-9aac-c67760ea97ff.png)

那么，Gearman 是如何利用这三者进行任务的调度呢？

![](/2017/08/gearman/cd86c5c9-9b65-47e5-b41c-7344d2896f58.png)

可以看出，在实际使用时，我们只需调用 Gearman 已经实现了 Client 和 Worker 的 API，委派和注册执行的任务，而无需关心任务的分发和机器的负载均衡问题。

### 外部API

到目前为止，Gearman 已经提供了 C、Shell、Prel、 Nodejs、PHP、Python、Java、C#、Go、MySQL 等版本的 Client、Worker API，详细信息见 [这里](http://gearman.org/download/#client--worker-apis)。本文只以 PHP 版为例，列举 Gearman 常用的 API 。

* Client 端常用 [API](http://php.net/manual/zh/class.gearmanclient.php) 列表：

| 功能描述            | 方法（GearmanClient 类中）                     |
| --------------- | ---------------------------------------- |
| 注册一个 Client     | addServer()，单个<br>addServers()，多个        |
| 发起一个 job        | doNormal()，阻塞会等待<br>doBackground()，非阻塞<br>doLow()，低优先级任务<br>doHigh()，高优先级任务 |
| 添加 task（一组 job） | addTask()、addTaskBackground()<br>addTaskHigh()、addTaskHighBackground()<br>addTaskLow()、addTaskLowBackground() |
| 发起 task         | runTasks()                               |
| 获取最新操作的结果       | returnCode()                             |
| 注册事件回调          | setCompleteCallback()、setFailCallback()  |

> 说明：job 是单个任务，每个任务只会在一个 Worker 上执行，而 task 是一组 job，其多个子任务会分配到多个 Worker 上并行执行。

* Worker 端常用 [API](http://php.net/manual/zh/class.gearmanworker.php) 列表：

| 功能描述        | 方法（GearmanWorker 类中）              |
| ----------- | --------------------------------- |
| 注册一个 Worker | addServer()，单个<br>addServers()，多个 |
| 注册处理任务回调    | addFunction()                     |
| 等待和执行任务     | work()                            |
| 获取最新操作的结果   | returnCode()                      |

* Job 端也提供了 [API](http://php.net/manual/zh/class.gearmanjob.php)，其常用列表为：

| 功能描述         | 方法（GearmanJob 类中）                   |
| ------------ | ----------------------------------- |
| 获取任务携带的序列化数据 | workload()<br>workloadSize()，获取数据大小 |
| 向运行的任务发送数据   | sendData()                          |

> 说明：Gearman 各端之间数据交互时，数据需要进行序列化处理。

## 安装Gearman

本文安装 Gearman 需要两步，第一步安装守护程序（gearmand）的 Job，第二步安装 PHP 扩展。

### 安装gearmand

首先，下载 Gearman 守护程序 gearmand 的 [最新源码](https://github.com/gearman/gearmand/releases)，并解压缩源码包：

```Bash
cd /usr/src
$ wget https://github.com/gearman/gearmand/releases/download/1.1.17/gearmand-1.1.17.tar.gz
$ tar zxvf gearmand-1.1.17.tar.gz
```

接着，安装 gearmand 的依赖包，并编译源码安装 gearmand：

```Bash
$ yum install boost-devel gperf libuuid-devel libevent-devel
$ cd ./gearmand-1.1.17.tar.gz
$ ./configure
$ make && make install
# 安装成功信息
Libraries have been installed in:
   /usr/local/lib
   - have your system administrator add LIBDIR to '/etc/ld.so.conf'
```

修改`/etc/ld.so.conf`配置文件，添加 MySQL 动态链接库地址：

```Bash
# /usr/local/mysql/lib为MySQL动态链接库libmysqlclient.so的目录
$ echo "/usr/local/mysql/lib" >>/etc/ld.so.conf
# 使其生效
$ /sbin/ldconfig
```

然后，如果出现如下信息则表示安装 gearmand 成功。

```Bash
# 启动Client和Worker
$ gearman
# 如下信息则表示成功
gearman	Error in usage(No Functions were provided).
Client mode: gearman [options] [<data>]

# 查看gearmand版本
$ gearmand -V
gearmand 1.1.17
```

### 安装PHP扩展

从 PECL 下载最新 [gearman 扩展](http://pecl.php.net/package/gearman)，并解压缩安装：

```Bash
$ cd /usr/src
$ wget http://pecl.php.net/get/gearman-1.1.2.tgz
$ tar zxvf gearman-1.1.2.tgz
$ cd gearman-1.1.2
$ /usr/local/php/bin/phpize
$ ./configure --with-php-config=/usr/local/php/bin/php-config
$ make && make install
# 安装成功后信息
Installing shared extensions:     /usr/local/php/lib/php/extensions/no-debug-non-zts-20131226/
```

然后，配置 php.ini 文件：

```Bash
$ php --ini
Loaded Configuration File:         /usr/local/php/lib/php.ini
$ vim /usr/local/php/lib/php.ini
#增加内容
extension=gearman.so
```

重启 php-fpm 后，出现如下信息则表示安装扩展成功。

```Bash
$ php --info | grep "gearman"
gearman support => enabled
libgearman version => 1.1.17
```

## 运行Gearman

运行 Gearman ，实际上我们需要使用到 Client、 Job、Worker 这三个角色。gearman 端实现了 Client 和  Worker 角色的功能 ，使用 PHP 时以扩展形式存在，gearmand 端则实现了 Job 角色的功能。 

### 启动Job

```Bash
# 先创建日志目录
$ mkdir -p /usr/local/var/log
$ touch /usr/local/var/log/gearmand.log
$ gearmand -d --log-file=/usr/local/var/log/gearmand.log
```

查看启动信息：

```Bash
$ ps -ef | grep gearman
root     6048     1  0 19:56 ?        00:00:00 gearmand -d
# 监听端口
$ netstat -tunpl | grep "gearmand"
tcp  0  0 0.0.0.0:4730  0.0.0.0:*   LISTEN  6048/gearmand
```

gearmand 命令的一些参数说明：

* -b –backlog：监听连接数量
* -d –daemon：后台运行
* -f –file-descriptors：文件描述符的数量
* -j –job-retries：移除不可用 Job 之前运行的次数
* -l –log-file：日志文件存放位置（默认记录最简单日志）
* -L –listen：监听的 IP
* -p –port：指定监听端口
* -q –queue-type：指定持久化队列
* -t –threads：使用的 I/O 线程数量
* -u –user：启动后，切换到指定用户
* --mysql-host：--mysql 系列为 MySQL 持久化连接信息

### 启动Client和Worker

通过 gearman 命令启动 Client 和 Worker 并不是必须的，这里仅仅是为了在命令行下测试工具。

首先，启动一个 Worker，用于列出某个目录的内容：

```Bash
$ gearman -w -f ls -- ls -lh
```

然后，创建一个 Client，用于查找请求的一个作业：

```Bash
$ gearman -f ls < /dev/null
total 4.0K
drwxr-xr-x. 21 www www 4.0K Jun 21 23:52 www
```

## PHP使用Gearman

当启动 Job 服务后，PHP 就可以通过 Gearman 扩展，创建任务和绑定任务处理回调了。PHP 调用 Gearman 的 API 见 [外部 API](#外部API) 部分，更多官方示例见 [这里](http://gearman.org/examples/)。

### 同步

Client 工作在同步阻塞模式，Client 发起任务后会等待至 Worker 执行任务结束。

* Client 端

```PHP
//Client.php
$client= new GearmanClient();
$client->addServer();

$msg = 'Hello World!';
echo "Sending $msg\n";
echo "Success: ", $client->doNormal("reverse", $msg), "\n";
```

* Worker 端

```PHP
//Worker.php
$worker = new GearmanWorker();
$worker->addServer();
$worker->addFunction("reverse", "reverse_fn");
echo "Waiting for job...\n";
while ($worker->work());

function reverse_fn($job) {
    $workload = $job->workload();
    echo "Workload: $workload\n";
    $result = strrev($workload);
    echo "Result: $result\n";
    return $result;
}
```

输出结果为：

```PHP
//Client
Sending Hello World!
Success: !dlroW olleH

//Worker
Waiting for job...
Workload: Hello World!
Result: !dlroW olleH
```
三端的交互流程图，如下：

![](/2017/08/gearman/f960fa25-547c-4003-995a-f08e6b9d60ad.png)

### 异步

异步方式时，Client 端不会产生 IO 阻塞，能实现异步执行，在实际应用中可以结合 fastcgi_finish_request() 函数或者 MQ 来异步使用。

* Client 端

```PHP
$client= new GearmanClient();
$client->addServer();
$client->setDataCallback("reverse_data");

$msg = 'Hello World!';
echo "Sending $msg\n";
$task = $client->addTaskBackground("reverse", $msg);
$msg = 'I am Gearman!';
echo "Sending $msg\n";
$task = $client->addTaskBackground("reverse", $msg);
$client->runTasks();

function reverse_data($task) {
    echo "Data: " . $task->data() . "\n";
}
```

* Worker 端

```PHP
$worker = new GearmanWorker();
$worker->addServer();
$worker->addFunction("reverse", "reverse_fn");
echo "Waiting for job...\n";
while ($worker->work());

function reverse_fn($job)
{
    $workload = $job->workload();
    echo "Workload: $workload\n";
    $result = strrev($workload);
    $job->sendData($result);
    echo "Result: $result\n";
    return $result;
}
```

输出结果为：

```PHP
//Client
Sending Hello World!
Data: !dlroW olleH
//Worker1
Waiting for job...
Workload: Hello World!
Result: !dlroW olleH
//Worker2
Waiting for job...
Workload: I am Gearman!
Result: !namraeG ma I
```

## Gearman的管理工具

Gearman 可以使用 [GearmanManager](https://github.com/brianlmoon/GearmanManager) 作为管理工具，命令行下可以使用 gearadmin 命令来进行简易的管理。

```Bash
$ gearadmin --show-jobs
32 ::7866:86a6:d87f:0%32 - : reserve

$ gearadmin --show-jobs
H:fhb:79	0	1	0
H:fhb:86	0	1	0

$ gearadmin --status
reverse	1	0	0
ls	    0	0	0
```

## 总结

虽然 Gearman 出现的比较早，但是其支持跨语言调用特性，以及负载均衡的方式委派任务，在分布式系统下，可以更加合理高效地利用系统资源。在一些大型的密集型、异步后台系统也已有成功部署的案例（数据抓取，库存数据更新、邮件和短信服务等），另 PHP 借助 Gearman 也能实现多任务处理方案。

> 推荐：[用 Gearman 分发 PHP 应用程序的工作负载](https://www.ibm.com/developerworks/cn/opensource/os-php-gearman/index.html)
