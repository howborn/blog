---
title: Redis使用管道提升性能
date: 2017-08-31 14:10:35
tags:
- Redis
categories:
- DB
- Redis
---

Redis 的 [管道](https://redis.io/topics/pipelining) （pipelining）是用来打包多条无关命令，减少多个命令分别执行带来的网络交互时间，在一些批量操作数据的场景，使用管道可以显著提升 Redis 的读写性能。

![](/2017/08/redis-pipelining/abc8ae13-9f76-4cd0-902d-a4fbb9fedd4f.png)<!--more-->

## 原理演示

Redis 的管道实质就是命令打包，多次网络交互减少到单次。我们使用 nc 命令来直观感受下 Redis 管道的使用过程：

```Bash
# 安装nc命令
$ yum install nc
# nc打包多个命令
$ (printf "PING\r\nPING\r\nPING\r\n") | nc localhost 6379
+PONG
+PONG
+PONG
```

因此，只要通过管道进行命令打包后，Redis 就可以批量返回命令的执行结果了。

## 管道的应用

首先，构造示例需要的 Hash 用户数据：

```PHP
$keyPrex = 'user:hash:u:';
for ($i=1; $i<=10000; $i++) {
    $redis->hMset($keyPrex.$i, [
        'name'   => name(),       //name()函数生成随机姓名
        'age'    => rand(21, 30),
        'sex'    => rand(0, 1),
        'is_new' => rand(0, 1)
    ]);
}
```

然后，查看导入 Redis 中的数据：

```Redis
127.0.0.1:6379> keys user:hash:u:*
 9997) "user:hash:u:3013"
 9998) "user:hash:u:8971"
 9999) "user:hash:u:4761"
10000) "user:hash:u:1828"

127.0.0.1:6379> HGETALL user:hash:u:1828
1) "name"
2) "ggrg"
3) "age"
4) "23"
5) "sex"
6) "0"
7) "is_new"
8) "1"
```

### 需求

在某个社交活动中，通过一系列筛选逻辑后取得种子用户 uid，然后用这些 uid 去 Hash 获取用户的信息。这种情况下你会怎么来处理呢？

### 不使用管道

一般情况下，在数据量较小时，我们会直接使用 HGETALL 命令遍历地获取用户数据。

```PHP
$start = nowTime();
foreach (range(1, 1000) as $id) {
    $user[] = $redis->hgetAll($keyPrex.$id);
}
echo '时间：', nowTime() - $start, 'ms', PHP_EOL;

时间：39ms
```

执行所用时间：39ms


### 使用管道

因为通过 uid 批量获取用户数据，各个命令并没有依赖关系，所以可以使用 Redis 的管道来优化查询。

```PHP
$start = nowTime();
$redis->multi(Redis::PIPELINE);
foreach (range(1, 1000) as $id) {
    $redis->hgetAll($keyPrex . $id);   //返回资源id相同的socket资源，并未执行命令
}
$user = $redis->exec();
echo '时间：', nowTime() - $start, 'ms', PHP_EOL;

时间：6ms
```

使用管道后，执行时间显著地减少为：6ms

## 总结

在批量获取数据时，尽管使用 Redis 的管道性能会显著提升，但是使用管道时 Redis 会缓存之前命令的结果，最后一并输出给终端，因此所打包的命令不宜太多，否则内存使用会很严重。

在批量操作（查询和写入）数据时，我们应尽量避免多次跟 Redis 的网络交互。这时，可以使用管道实现，也可以 Redis 内嵌 Lua 脚本实现。