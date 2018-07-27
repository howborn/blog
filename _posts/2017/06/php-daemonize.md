---
title: 简易实现一个后台程序
date: 2017-06-15 20:30:06
tags:
- PHP
categories:
- 语言
- PHP
---

在 PHP 中如何实现一个常驻系统的守护进程呢！使其可以脱离终端运行，不直接将其运行结果输出到终端。这里列举两种实现方式。

![](https://img0.fanhaobai.com/2017/06/php-daemonize/72650dd9-11e7-48d2-adb9-f4137e51160f.png)<!--more--> 

## nohup

通过在命令后追加 "&" 操作符，即可忽略所有的挂断（SIGHUP）信号。

```Bash
$ nohup php deamon.php &
```

查看 deamon.php 是否成功被挂起。

```Bash
$ ps -ef | grep "deamon.php"
root  25462 24539  0 21:16 pts/0   00:00:00  php deamon.php
```

## pcntl扩展

### 代码

```PHP
/**
 * daemo运行
 */
function daemonize() {
    global $STDIN, $STDOUT;
    //重定向标准输入和输出
    fclose(STDIN);
    fclose(STDOUT);
    fclose(STDERR);
    $STDIN = fopen('/dev/null', 'r');
    $STDOUT = fopen('./out.log', 'a');

    posix_setsid();
    //fork子进程, 主进程退出
    $pid = pcntl_fork();
    if (-1 == $pid) {
        die('fork faild!');
    } elseif ($pid > 0) {
        exit(0);
    }
}

daemonize();
$count = 0;
while(true) {
    sleep(1);
    $count ++;
    echo $count, PHP_EOL;
}
```

### 运行结果

上述代码，如果不以守护态运行，那么会在终端每隔一秒直接输出秒数。

```Bash
$ php deamon.php
1
2
3
4
...
```

反之以守护进程运行，echo 不会直接输出到终端，而是输出到 out.log 文件中，这是因为已将标准输出重定向到了 out.log 的文件描述符。

```
$ php deamon.php
//终端并未挂起, 查看deamon.php守护进程
$ pstree -a

//查看输出
$ tailf out.log
40
41
42
43
```

### 原理

很简单，在终端运行脚本时，代码中会 fork 一个脱离终端的进程，并退出当前脚本。fork 的进程充当了守护进程的角色。
