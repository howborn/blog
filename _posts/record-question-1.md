---
title: 记录——Redis 与网关问题
date: 2017-09-21 13:09:59
tags:
- Redis
categories:
- Redis
---

最近比较忙，要上新的项目，也没时间打理博客了。今天中午抽午睡时间记录下这几天工作上遇到的网关接入和 Redis 操作问题。

<!--more-->

## Redis [漂移](http://www.cnblogs.com/mushroom/archive/2015/08/25/4752962.html)

### 初期方案

有一个类似于抢购的需求，是典型的防止库存超卖场景，于是理所因当地选用了 Redis 方案。只要保证是原子操作，即可防止库存超卖，自然想到使用 Incr/Decr 这类原子操作。

查看 PHP 的 Redis 扩展关于 [Incr](http://redis.io/commands/incr) 方法的说明：

```PHP
/**
 * Increment the number stored at key by one.
 *
 * @param   string $key
 * @return  int    the new value
 * @link    http://redis.io/commands/incr
 *      
 */
public function incr( $key ) {}
```

可见，Incr 方法返回的是 key 操作后的新值，即 ++1 后的值，于是我们写出了如下代码：

```PHP
$num = $redis->incr($key);
if ($num < $max) {
    //入抢购成功队列，异步去执行抢购成功逻辑
} else {
    //不好意思呢，已经被抢完了
}
```

不知道你有没有闻到这段代码的坏味道，在大部分情况下会如你所想地运行，但是特殊场景下会 [出现判断失效]() 的逻辑问题，例如：

1、key 由于某些原因失效了；
2、Incr 操作失败了，不会抛异常并返回 false；

上述两种情况，都会导致`$num < $max`条件成立，进而导致更严重的逻辑问题，最终超卖。

### 问题描述与分析

我们就抢购开始后就遇到了上述的第二种情况，下面描述整个过程。先通过 [Cat](https://github.com/dianping/cat) 监控平台观察到访问量急剧上升，开始担心应用服务坑不住，随后日志平台报警 Incr 操作存在异常几率，再然后就出现超卖情况，紧急情况只能关闭业务开关。是什么原因导致判断条件成立？

通过日志定位到 Incr 操作问题，便 Telnet 连接到线上 Redis 服务，发现了异常情况：

```Bash
# 查看值
GET key
100
# 尝试修改
INCR key
READONLY You can't write against a read only slave
```

可以看出来，该连接的机器目前处于从机状态，不可写操作，所以 Incr 操作返回 false 又并不抛出异常，同时 PHP 不同类型比较会存在隐式转化，所以`false < $num`恒成立，条件判断失效。那是什么原因导致该机器

Redis 高可用方案

* 主备切换
* 集群模式